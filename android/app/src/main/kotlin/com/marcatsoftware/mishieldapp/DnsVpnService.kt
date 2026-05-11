package com.marcatsoftware.mishieldapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * DNS-only local VPN (same idea as MiShield MAUI). Routes system DNS to the given resolvers;
 * app traffic is excluded via [VpnService.Builder.addDisallowedApplication].
 */
class DnsVpnService : VpnService() {

    private val lock = Any()
    private var tunInterface: ParcelFileDescriptor? = null
    private var running = false

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val primary = intent.getStringExtra(EXTRA_PRIMARY_DNS) ?: ""
                val secondary = intent.getStringExtra(EXTRA_SECONDARY_DNS) ?: ""
                startForeground(NOTIFICATION_ID, buildNotification())
                Thread { startTunnel(primary, secondary) }.start()
                return START_STICKY
            }
            ACTION_STOP -> {
                stopTunnel()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopTunnel()
        super.onDestroy()
    }

    private fun startTunnel(primaryDns: String, secondaryDns: String) {
        synchronized(lock) {
            stopTunnelInternal()
            running = true
        }
        isActive = false
        try {
            val builder = Builder()
                .setSession(SESSION_NAME)
                .addAddress(TUN_ADDRESS, TUN_PREFIX)
                .addDnsServer(primaryDns)
            if (secondaryDns.isNotBlank()) {
                builder.addDnsServer(secondaryDns)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.setMetered(false)
            }
            try {
                builder.addDisallowedApplication(packageName)
            } catch (e: Exception) {
                Log.w(TAG, "addDisallowedApplication failed: ${e.message}")
            }
            tunInterface = builder.establish()
            if (tunInterface == null) {
                Log.e(TAG, "establish() returned null")
                synchronized(lock) { running = false }
                isActive = false
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return
            }
            isActive = true
            Log.i(TAG, "VPN established primary=$primaryDns secondary=$secondaryDns")
        } catch (e: Exception) {
            Log.e(TAG, "startTunnel error", e)
            synchronized(lock) { running = false }
            isActive = false
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun stopTunnel() {
        synchronized(lock) { stopTunnelInternal() }
    }

    private fun stopTunnelInternal() {
        running = false
        isActive = false
        try {
            tunInterface?.close()
        } catch (e: Exception) {
            Log.w(TAG, "close tun: ${e.message}")
        }
        tunInterface = null
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
        val pending = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("MiShield")
            .setContentText("DNS protection is on")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setContentIntent(pending)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val ch = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            )
            mgr.createNotificationChannel(ch)
        }
    }

    companion object {
        private const val TAG = "DnsVpnService"
        const val ACTION_START = "com.marcatsoftware.mishieldapp.START_DNS_VPN"
        const val ACTION_STOP = "com.marcatsoftware.mishieldapp.STOP_DNS_VPN"
        private const val EXTRA_PRIMARY_DNS = "primary_dns"
        private const val EXTRA_SECONDARY_DNS = "secondary_dns"
        private const val CHANNEL_ID = "mishield_dns_vpn"
        private const val CHANNEL_NAME = "MiShield DNS"
        private const val NOTIFICATION_ID = 42
        private const val SESSION_NAME = "MiShield DNS"
        private const val TUN_ADDRESS = "192.168.50.1"
        private const val TUN_PREFIX = 24

        @Volatile
        var isActive: Boolean = false

        fun start(context: Context, primaryDns: String, secondaryDns: String) {
            val intent = Intent(context, DnsVpnService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_PRIMARY_DNS, primaryDns)
                putExtra(EXTRA_SECONDARY_DNS, secondaryDns)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, DnsVpnService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }
}
