import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final bg = img.ColorRgba8(255, 255, 255, 255);
  final green = img.ColorRgba8(22, 163, 74, 255);
  final gray = img.ColorRgba8(107, 114, 128, 255);

  final image = img.Image(width: size, height: size);
  img.fill(image, color: bg);

  final cx = (size / 2).round();
  final cy = (size * 0.42).round();
  final r = (size * 0.22).round();

  _drawRing(image, cx: cx, cy: cy, r: r, thickness: 48, color: green);

  _drawArc(
    image,
    cx: cx,
    cy: cy - (r * 0.32).round(),
    r: (r * 0.55).round(),
    startRad: math.pi,
    endRad: 2 * math.pi,
    thickness: 44,
    color: gray,
  );

  _drawLine(
    image,
    x0: cx,
    y0: cy - (r * 0.86).round(),
    x1: cx,
    y1: cy - (r * 1.35).round(),
    thickness: 44,
    color: gray,
  );

  _drawArc(
    image,
    cx: cx + (r * 0.55).round(),
    cy: cy - (r * 1.35).round(),
    r: (r * 0.42).round(),
    startRad: math.pi,
    endRad: 2 * math.pi,
    thickness: 44,
    color: gray,
  );

  _drawArc(
    image,
    cx: cx,
    cy: cy + (r * 0.62).round(),
    r: (r * 0.95).round(),
    startRad: math.pi * 1.12,
    endRad: math.pi * 1.84,
    thickness: 38,
    color: green,
    alpha: 0.9,
  );

  final outDir = Directory('assets/logo');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final outFile = File('assets/logo/ghasele_logo.png');
  outFile.writeAsBytesSync(img.encodePng(image, level: 6));
}

void _drawRing(
  img.Image image, {
  required int cx,
  required int cy,
  required int r,
  required int thickness,
  required img.Color color,
}) {
  final outer = r;
  final inner = math.max(0, r - thickness);

  for (var y = cy - outer; y <= cy + outer; y++) {
    for (var x = cx - outer; x <= cx + outer; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final d2 = dx * dx + dy * dy;
      if (d2 <= outer * outer && d2 >= inner * inner) {
        image.setPixel(x, y, color);
      }
    }
  }
}

void _drawLine(
  img.Image image, {
  required int x0,
  required int y0,
  required int x1,
  required int y1,
  required int thickness,
  required img.Color color,
}) {
  final steps = math.max((x1 - x0).abs(), (y1 - y0).abs());
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = (x0 + (x1 - x0) * t).round();
    final y = (y0 + (y1 - y0) * t).round();
    _drawDot(image, x: x, y: y, radius: thickness ~/ 2, color: color);
  }
}

void _drawArc(
  img.Image image, {
  required int cx,
  required int cy,
  required int r,
  required double startRad,
  required double endRad,
  required int thickness,
  required img.Color color,
  double alpha = 1.0,
}) {
  final a = (alpha.clamp(0.0, 1.0) * 255).round();
  final rgba = img.ColorRgba8(color.r.toInt(), color.g.toInt(), color.b.toInt(), a);

  final length = (r * (endRad - startRad)).abs();
  final steps = math.max(60, length.round());

  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final ang = startRad + (endRad - startRad) * t;
    final x = (cx + math.cos(ang) * r).round();
    final y = (cy + math.sin(ang) * r).round();
    _drawDot(image, x: x, y: y, radius: thickness ~/ 2, color: rgba);
  }
}

void _drawDot(
  img.Image image, {
  required int x,
  required int y,
  required int radius,
  required img.Color color,
}) {
  for (var yy = y - radius; yy <= y + radius; yy++) {
    for (var xx = x - radius; xx <= x + radius; xx++) {
      final dx = xx - x;
      final dy = yy - y;
      if (dx * dx + dy * dy <= radius * radius) {
        image.setPixel(xx, yy, color);
      }
    }
  }
}
