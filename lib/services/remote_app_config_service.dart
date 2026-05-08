import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../config/remote_app_config.dart';

class RemoteAppConfigService {
  RemoteAppConfigService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Returns `null` if the URL is invalid, unreachable, or body is not JSON.
  Future<RemoteAppConfig?> fetch() async {
    final uri = Uri.tryParse(AppConfig.remoteConfigUrl);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return null;
    }
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final map = jsonDecode(res.body);
      if (map is! Map<String, dynamic>) return null;
      return RemoteAppConfig.fromJson(map);
    } on Object {
      return null;
    }
  }
}
