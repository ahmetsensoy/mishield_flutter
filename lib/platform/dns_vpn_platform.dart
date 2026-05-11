import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DnsVpnPlatform {
  DnsVpnPlatform._();

  static const MethodChannel _channel = MethodChannel('com.marcatsoftware.mishieldapp/dns_vpn');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> prepareVpn() async {
    if (!isSupported) return false;
    final ok = await _channel.invokeMethod<bool>('prepareVpn');
    return ok ?? false;
  }

  static Future<void> startVpn({
    required String primaryDns,
    required String secondaryDns,
  }) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('startVpn', <String, String>{
      'primaryDns': primaryDns,
      'secondaryDns': secondaryDns,
    });
  }

  static Future<void> stopVpn() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('stopVpn');
  }

  static Future<bool> isVpnRunning() async {
    if (!isSupported) return false;
    final v = await _channel.invokeMethod<bool>('isVpnRunning');
    return v ?? false;
  }
}
