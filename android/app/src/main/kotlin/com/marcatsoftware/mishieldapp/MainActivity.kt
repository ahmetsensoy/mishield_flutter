package com.marcatsoftware.mishieldapp

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import androidx.activity.result.ActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private var vpnPermissionResult: MethodChannel.Result? = null

    private val vpnPrepareLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { activityResult: ActivityResult ->
            val ok = activityResult.resultCode == Activity.RESULT_OK
            vpnPermissionResult?.success(ok)
            vpnPermissionResult = null
        }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent == null) {
                        result.success(true)
                    } else {
                        vpnPermissionResult = result
                        vpnPrepareLauncher.launch(intent)
                    }
                }
                "startVpn" -> {
                    val primary = call.argument<String>("primaryDns") ?: ""
                    val secondary = call.argument<String>("secondaryDns") ?: ""
                    if (primary.isBlank()) {
                        result.error("bad_args", "primaryDns required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        DnsVpnService.start(this, primary, secondary)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("start_failed", e.message, null)
                    }
                }
                "stopVpn" -> {
                    try {
                        DnsVpnService.stop(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("stop_failed", e.message, null)
                    }
                }
                "isVpnRunning" -> {
                    result.success(DnsVpnService.isActive)
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val CHANNEL = "com.marcatsoftware.mishieldapp/dns_vpn"
    }
}
