import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../config/remote_app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/home/home_page.dart';
import '../services/remote_app_config_service.dart';
import '../services/version_gate.dart';
import 'update_required_page.dart';

/// Boots the app: fetches remote JSON, enforces minimum version, initializes ads if enabled.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  _BootPhase _phase = _BootPhase.loading;
  ResolvedAppConfig? _config;
  String _appVersion = '0.0.0';

  @override
  void initState() {
    super.initState();
    _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    final info = await PackageInfo.fromPlatform();
    final remote = await RemoteAppConfigService().fetch();
    final version = VersionGate.normalize(info.version);

    if (!mounted) return;

    if (VersionGate.mustBlock(version, remote)) {
      setState(() {
        _appVersion = version;
        _phase = _BootPhase.blocked;
      });
      return;
    }

    final resolved = ResolvedAppConfig(
      primaryDns: _pickDns(remote?.primaryDns, AppConfig.defaultPrimaryDns),
      secondaryDns: _pickDns(remote?.secondaryDns, AppConfig.defaultSecondaryDns),
      showAds: remote?.showAds ?? false,
      remote: remote,
    );

    if (resolved.showAds) {
      await MobileAds.instance.initialize();
    }

    if (!mounted) return;
    setState(() {
      _config = resolved;
      _phase = _BootPhase.ready;
    });
  }

  static String _pickDns(String? fromRemote, String fallback) {
    final t = fromRemote?.trim();
    if (t == null || t.isEmpty) return fallback;
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final theme = buildMiShieldTheme();

    switch (_phase) {
      case _BootPhase.loading:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      case _BootPhase.blocked:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: UpdateRequiredPage(installedVersion: _appVersion),
        );
      case _BootPhase.ready:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: HomePage(config: _config!),
        );
    }
  }
}

enum _BootPhase { loading, blocked, ready }
