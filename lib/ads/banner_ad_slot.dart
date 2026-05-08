import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

/// Bottom banner slot; shows nothing when [enabled] is false.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key, required this.enabled});

  final bool enabled;

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didUpdateWidget(covariant BannerAdSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _ad?.dispose();
      _ad = null;
      _loaded = false;
    }
    if (!oldWidget.enabled && widget.enabled) {
      _load();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  void _load() {
    if (!widget.enabled) return;
    final unitId = kDebugMode ? AppConfig.testBannerAdUnitId : AppConfig.releaseBannerAdUnitId;
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: unitId,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
      request: const AdRequest(),
    );
    _ad?.dispose();
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _ad == null) return const SizedBox.shrink();
    if (!_loaded) {
      return SizedBox(
        height: AdSize.banner.height.toDouble(),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
