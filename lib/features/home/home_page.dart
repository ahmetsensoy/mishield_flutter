import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../ads/banner_ad_slot.dart';
import '../../config/remote_app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../platform/dns_vpn_platform.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.config});

  final ResolvedAppConfig config;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _protectionOn = false;
  bool _busy = false;
  late final AnimationController _ringController;
  late final AnimationController _starsController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _starsController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncVpnState());
  }

  @override
  void dispose() {
    _ringController.dispose();
    _starsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _syncVpnState() async {
    if (!DnsVpnPlatform.isSupported) return;
    final on = await DnsVpnPlatform.isVpnRunning();
    if (mounted) setState(() => _protectionOn = on);
  }

  Future<void> _toggleProtection() async {
    if (_busy) return;

    if (!DnsVpnPlatform.isSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DNS protection is only available on Android.')),
      );
      return;
    }

    await HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
    setState(() => _busy = true);
    try {
      if (_protectionOn) {
        await DnsVpnPlatform.stopVpn();
        if (mounted) setState(() => _protectionOn = false);
        await HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
        return;
      }

      final notif = await Permission.notification.request();
      if (!notif.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission is recommended for the foreground service.')),
        );
      }

      final prepared = await DnsVpnPlatform.prepareVpn();
      if (!prepared) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('VPN / DNS permission was not granted.')),
          );
        }
        return;
      }

      await DnsVpnPlatform.startVpn(
        primaryDns: widget.config.primaryDns,
        secondaryDns: widget.config.secondaryDns,
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final on = await DnsVpnPlatform.isVpnRunning();
      if (mounted) {
        setState(() => _protectionOn = on);
        if (on) {
          await HapticFeedback.mediumImpact();
          SystemSound.play(SystemSoundType.click);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not start DNS session. Check your connection and try again.')),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message ?? e.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MiShield')),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          _protectionOn ? 'Active' : 'Activate',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _protectionOn ? AppColors.activeGreen : Colors.white,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: Center(
                            child: SizedBox(
                              width: 280,
                              height: 280,
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _ringController,
                                  _starsController,
                                  _pulseController,
                                ]),
                                builder: (context, child) {
                                  final t = _ringController.value * 360;
                                  final s = _starsController.value;
                                  final p = _pulseController.value;
                                  final ringBoost = _protectionOn ? (0.88 + 0.12 * p) : (_busy ? (0.94 + 0.06 * math.sin(s * math.pi * 4)) : 1.0);
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      if (_protectionOn)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    AppColors.activeGreen.withValues(alpha: 0.14),
                                                    Colors.transparent,
                                                  ],
                                                  stops: const [0.0, 0.72],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      _ring(size: 260, opacity: 0.12 * ringBoost, rotation: t),
                                      _ring(size: 210, opacity: 0.18 * ringBoost, rotation: -t * 0.75),
                                      _ring(size: 165, opacity: 0.28 * ringBoost, rotation: t * 0.5),
                                      _ring(size: 110, opacity: 0.45 * ringBoost, rotation: -t * 0.35),
                                      CustomPaint(
                                        size: const Size(280, 280),
                                        painter: _DownBeamPainter(
                                          phase: s,
                                          pulse: p,
                                          active: _protectionOn,
                                          busy: _busy,
                                        ),
                                      ),
                                      ..._starParticles(s),
                                      _centerCore(s, p),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _featureRow(context, _protectionOn, _pulseController.value),
                        const SizedBox(height: 16),
                        Text(
                          _protectionOn
                              ? 'System DNS queries are routed through your shield servers.'
                              : 'Protection is off. Tap Activate and allow the connection prompt.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _protectionOn ? AppColors.activeGreen : Colors.white70,
                              ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _toggleProtection,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(300, 56),
                            backgroundColor: _protectionOn ? AppColors.accentDanger : AppColors.accent,
                            elevation: _busy ? 2 : (_protectionOn ? 6 : 4),
                            shadowColor: (_protectionOn ? AppColors.activeGreen : AppColors.accent)
                                .withValues(alpha: 0.45),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_protectionOn ? 'Deactivate' : 'Activate'),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'MiShield',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BannerAdSlot(enabled: widget.config.showAds),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerCore(double s, double p) {
    final busyPulse = _busy ? 1.0 + 0.12 * math.sin(s * math.pi * 6) : 1.0;
    final onPulse = _protectionOn ? 1.0 + 0.08 * p : 1.0;
    final scale = (_busy ? busyPulse : onPulse).clamp(0.85, 1.22);
    final Color coreColor = _protectionOn ? AppColors.accent : Colors.white;
    final List<BoxShadow> shadows = _protectionOn
        ? [
            BoxShadow(
              color: AppColors.activeGreen.withValues(alpha: 0.55),
              blurRadius: 18 + 8 * p,
              spreadRadius: 1.5,
            ),
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.25),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ]
        : _busy
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  blurRadius: 14 + 6 * math.sin(s * math.pi * 4),
                  spreadRadius: 0,
                ),
              ]
            : [];

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: coreColor,
          shape: BoxShape.circle,
          boxShadow: shadows,
        ),
      ),
    );
  }

  Widget _ring({required double size, required double opacity, required double rotation}) {
    return Transform.rotate(
      angle: rotation * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: opacity.clamp(0.04, 1.0)), width: 2),
        ),
      ),
    );
  }

  static const double _radCenter = 140;

  List<Widget> _starParticles(double s) {
    const count = 20;
    final speed = _protectionOn ? 1.55 : (_busy ? 1.25 : 1.0);
    final list = <Widget>[];
    for (var i = 0; i < count; i++) {
      final golden = i * 0.618033988749895 * math.pi * 2;
      final wobble = math.sin(s * math.pi * 2 * 2 * speed + i * 0.7) * 16;
      final rBase = 36 + (i % 6) * 17.0;
      final r = (rBase + wobble).clamp(26.0, 124.0);
      final angle = golden + s * math.pi * 2 * (1.15 + (i % 4) * 0.18) * speed;
      final x = _radCenter + math.cos(angle) * r;
      final y = _radCenter + math.sin(angle) * r;
      final twinkle = 0.28 + 0.62 * (0.5 + 0.5 * math.sin(s * math.pi * 4 * speed + i * 1.13));
      final isStar = i % 3 != 1;
      final size = isStar ? (11.0 + (i % 4) * 2.8) : (5.0 + (i % 3) * 1.6);
      list.add(
        Positioned(
          left: x - size * 0.5,
          top: y - size * 0.5,
          child: IgnorePointer(
            child: Opacity(
              opacity: twinkle.clamp(0.18, 1.0),
              child: Text(
                isStar ? '✦' : '•',
                style: TextStyle(
                  fontSize: size,
                  color: isStar ? Colors.white : const Color(0xFFB3E5FC),
                  height: 1,
                  shadows: _protectionOn && isStar
                      ? [
                          Shadow(
                            color: AppColors.accessBlue.withValues(alpha: 0.55),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
    return list;
  }

  Widget _featureRow(BuildContext context, bool active, double pulse) {
    Widget chip(int index, String emoji, String label, Color border) {
      final accent = active && index == 1;
      final scale = accent ? 1.0 + 0.06 * pulse : 1.0;
      return Expanded(
        child: Column(
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: accent ? AppColors.accessBlue : border,
                    width: accent ? 2.5 : 2,
                  ),
                  boxShadow: accent
                      ? [
                          BoxShadow(
                            color: AppColors.accessBlue.withValues(alpha: 0.35 + 0.2 * pulse),
                            blurRadius: 10 + 6 * pulse,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return Row(
      children: [
        chip(0, '🚫', 'Ads', AppColors.accentDanger),
        chip(1, '➡️', 'Access', AppColors.accessBlue),
        chip(2, '🛡️', 'DNS', AppColors.activeGreen),
      ],
    );
  }
}

/// Soft “energy” line from the core toward the feature row (down).
class _DownBeamPainter extends CustomPainter {
  _DownBeamPainter({
    required this.phase,
    required this.pulse,
    required this.active,
    required this.busy,
  });

  final double phase;
  final double pulse;
  final bool active;
  final bool busy;

  @override
  void paint(Canvas canvas, Size size) {
    if (!active && !busy) return;
    final center = Offset(size.width / 2, size.height / 2);
    final end = Offset(size.width / 2, size.height * 0.93);
    final flow = 0.35 + 0.4 * (0.5 + 0.5 * math.sin(phase * math.pi * 2));
    final p = active ? (0.45 + 0.35 * pulse) * flow : flow * 0.55;

    final glow = Paint()
      ..color = AppColors.accessBlue.withValues(alpha: p * 0.55)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(center, end, glow);

    final core = Paint()
      ..color = Colors.white.withValues(alpha: p * 0.65)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, end, core);
  }

  @override
  bool shouldRepaint(covariant _DownBeamPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.pulse != pulse ||
      oldDelegate.active != active ||
      oldDelegate.busy != busy;
}
