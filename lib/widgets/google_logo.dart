import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Google's four-colour "G", drawn as vectors.
///
/// Painted rather than loaded from an asset so the button always renders correctly - a missing
/// [Image.asset] falls back to a placeholder icon, which reads as broken next to a polished
/// sign-in button. If `assets/logo/google-logo.png` is added later, prefer it: this is a faithful
/// reconstruction, but Google's brand guidelines ask for their supplied artwork.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  /// Ring thickness as a fraction of the overall diameter. Matches the proportion of the real
  /// mark - noticeably thinner than it looks by eye, and the counter closes up if this grows.
  static const _strokeRatio = 0.20;

  static double _rad(double degrees) => degrees * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = math.min(size.width, size.height);
    final centre = Offset(size.width / 2, size.height / 2);

    final stroke = diameter * _strokeRatio;
    final radius = (diameter - stroke) / 2; // centre-line of the ring
    final outer = radius + stroke / 2;
    final half = stroke / 2; // half the bar's height

    // Angle at which the bar's edges meet the outer circle. Deriving it rather than hardcoding is
    // what makes the bar sit flush against the blue and green arcs at any size.
    final theta = math.asin(half / outer) * 180 / math.pi;

    // Contiguous arcs, clockwise from 3 o'clock, leaving the bar's opening on the right.
    const blueStart = 300.0;
    final blueSweep = (360 - theta) - blueStart;
    final greenStart = theta;
    const greenSweep = 90.0;
    final yellowStart = greenStart + greenSweep;
    const yellowSweep = 88.0;
    final redStart = yellowStart + yellowSweep;
    final redSweep = blueStart - redStart;

    final rect = Rect.fromCircle(center: centre, radius: radius);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    void sweep(Color colour, double startDeg, double sweepDeg) {
      canvas.drawArc(rect, _rad(startDeg), _rad(sweepDeg), false, arc..color = colour);
    }

    sweep(_red, redStart, redSweep);
    sweep(_blue, blueStart, blueSweep);
    sweep(_green, greenStart, greenSweep);
    sweep(_yellow, yellowStart, yellowSweep);

    // The crossbar. Its right edge stops on the circle rather than at the full radius, otherwise
    // the corners poke out past the ring as a visible nub.
    final flushX = math.sqrt(outer * outer - half * half);
    final barLeft = centre.dx - stroke * 0.10;
    canvas.drawRect(
      Rect.fromLTRB(barLeft, centre.dy - half, centre.dx + flushX, centre.dy + half),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
