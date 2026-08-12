import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';

/// Cleanyjo splash screen.
///
/// Mirrors the brand banner: a soft white field on the left, the signature
/// green crescent sweeping in from the bottom-right, and drifting bubbles -
/// with the Cleanyjo logo centred on top.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _intro;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Slow, continuously looping motion for the bubbles and crescent.
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // One-shot entrance for the logo and tagline.
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _intro.forward();
    _navigateNext();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      (token != null && token.isNotEmpty) ? '/main' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Base wash. The centre stays pure white so the transparent logo
          // blends in seamlessly; the green tint only appears out at the
          // corners.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Colors.white, Colors.white, AppTheme.brandGreenSurface],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Brand crescent + drifting bubbles.
          AnimatedBuilder(
            animation: _ambient,
            builder: (context, _) => CustomPaint(
              painter: _BrandBackdropPainter(progress: _ambient.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Image.asset(
                        'assets/logo/logo-trans.png',
                        width: 280,
                        fit: BoxFit.contain,
                        // Decoding the full 1024x1024 source here competed with
                        // the entrance animation on the very first frames.
                        cacheWidth: 896,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline, straight from the brand banner.
                FadeTransition(
                  opacity: _taglineFade,
                  child: Column(
                    children: [
                      Text(
                        'Fresh Clothes, Better Every Day',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: AppTheme.brandSlate),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'خدمة غسيل احترافية من باب بيتك لباب بيتك',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.neutral500),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Loading indicator
                FadeTransition(
                  opacity: _taglineFade,
                  child: const _BubbleLoader(),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three bubbles that rise and fade in sequence - a laundry-native loader.
class _BubbleLoader extends StatefulWidget {
  const _BubbleLoader();

  @override
  State<_BubbleLoader> createState() => _BubbleLoaderState();
}

class _BubbleLoaderState extends State<_BubbleLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          // Stagger each bubble by a third of the cycle.
          final t = (_controller.value - (i * 0.2)) % 1.0;
          final lift = math.sin(t * math.pi);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Transform.translate(
              offset: Offset(0, -8 * lift),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandGreen
                      .withOpacity(0.35 + (0.65 * lift)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Paints the Cleanyjo crescent and a field of slow-drifting bubbles.
class _BrandBackdropPainter extends CustomPainter {
  const _BrandBackdropPainter({required this.progress});

  /// 0..1, loops continuously.
  final double progress;

  // Relative positions/sizes so the layout holds on any screen.
  static const _bubbles = <({double dx, double dy, double r, double phase})>[
    // Kept out toward the edges so none sit mid-bubble under the logo.
    (dx: 0.10, dy: 0.14, r: 26.0, phase: 0.0),
    (dx: 0.88, dy: 0.10, r: 16.0, phase: 0.35),
    (dx: 0.91, dy: 0.72, r: 30.0, phase: 0.6),
    (dx: 0.07, dy: 0.78, r: 20.0, phase: 0.15),
    (dx: 0.78, dy: 0.90, r: 13.0, phase: 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(progress * 2 * math.pi);

    // Large green crescent anchored off the bottom-right corner, echoing the
    // circular green panel in the brand banner.
    final crescent = Paint()..color = AppTheme.brandGreen.withOpacity(0.10);
    canvas.drawCircle(
      Offset(size.width * 1.05, size.height * 0.92 + (10 * wave)),
      size.width * 0.72,
      crescent,
    );

    // Softer slate arc top-left for balance.
    final slateArc = Paint()..color = AppTheme.brandSlate.withOpacity(0.045);
    canvas.drawCircle(
      Offset(-size.width * 0.18, size.height * 0.08 - (12 * wave)),
      size.width * 0.48,
      slateArc,
    );

    // Drifting bubbles.
    for (final b in _bubbles) {
      final t = (progress + b.phase) % 1.0;
      final drift = math.sin(t * 2 * math.pi);
      final center = Offset(
        size.width * b.dx + (6 * drift),
        size.height * b.dy - (14 * drift),
      );

      canvas.drawCircle(
        center,
        b.r,
        Paint()..color = AppTheme.brandGreen.withOpacity(0.13),
      );
      // Highlight dot, mimicking the glossy bubbles in the logo.
      canvas.drawCircle(
        center.translate(-b.r * 0.28, -b.r * 0.28),
        b.r * 0.22,
        Paint()..color = Colors.white.withOpacity(0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_BrandBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
