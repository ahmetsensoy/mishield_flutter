import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// MARCAT wordmark (asset) for splash and loading states.
class MishieldBrandMark extends StatelessWidget {
  const MishieldBrandMark({
    super.key,
    this.logoSize = 112,
    this.showWordmark = false,
  });

  final double logoSize;
  final bool showWordmark;

  static const String _asset = 'assets/branding/marcat_splash_logo.png';

  /// Intrinsic width/height of [_asset] (px). Update if the splash asset changes.
  static const double _assetAspect = 856 / 162;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            var maxW = constraints.maxWidth;
            if (!maxW.isFinite || maxW <= 0) {
              maxW = MediaQuery.sizeOf(context).width;
            }
            maxW *= 0.92;

            final targetBarHeight = logoSize;
            var barWidth = targetBarHeight * _assetAspect;
            if (barWidth > maxW) {
              barWidth = maxW;
            }
            final barHeight = barWidth / _assetAspect;

            return SizedBox(
              width: barWidth,
              height: barHeight,
              child: Image.asset(
                _asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('MiShield: logo asset failed to load: $error');
                  return Icon(
                    Icons.shield_rounded,
                    size: targetBarHeight * 0.85,
                    color: AppColors.accent,
                  );
                },
              ),
            );
          },
        ),
        if (showWordmark) ...[
          SizedBox(height: logoSize * 0.12),
          Text('MARCAT', style: textStyle),
        ],
      ],
    );
  }
}
