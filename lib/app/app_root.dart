import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../config/remote_app_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../features/home/home_page.dart';
import '../services/remote_app_config_service.dart';
import '../services/version_gate.dart';
import '../widgets/mishield_brand_mark.dart';
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
    var version = '0.0.0';
    RemoteAppConfig? remote;

    try {
      final info = await PackageInfo.fromPlatform();
      version = VersionGate.normalize(info.version);
    } on Object catch (e, st) {
      debugPrint('MiShield: PackageInfo failed: $e\n$st');
      version = '1.0.0';
    }

    try {
      remote = await RemoteAppConfigService().fetch();
    } on Object catch (e, st) {
      debugPrint('MiShield: remote config failed: $e\n$st');
      remote = null;
    }

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

    var showAds = resolved.showAds;
    if (showAds) {
      try {
        await MobileAds.instance.initialize();
      } on Object catch (e, st) {
        debugPrint('MiShield: MobileAds.initialize failed: $e\n$st');
        showAds = false;
      }
    }

    if (!mounted) return;
    setState(() {
      _config = ResolvedAppConfig(
        primaryDns: resolved.primaryDns,
        secondaryDns: resolved.secondaryDns,
        showAds: showAds,
        remote: resolved.remote,
      );
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
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MishieldBrandMark(logoSize: 120),
                  SizedBox(height: 36),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ],
              ),
            ),
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
