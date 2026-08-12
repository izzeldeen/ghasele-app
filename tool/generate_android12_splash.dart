import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Pads the brand logo so Android 12+'s circular splash mask cannot clip it.
///
/// The platform draws `windowSplashScreenAnimatedIcon` into a 288dp box but
/// only reveals a 192dp circle at its centre - two thirds of the canvas. Any
/// artwork drawn edge-to-edge therefore loses its top, left and right. We scale
/// the logo so its full bounding box is *inscribed* in that circle (diagonal
/// <= the circle's diameter, not just its width) and centre it on a
/// transparent canvas of the size flutter_native_splash expects.
void main() {
  // flutter_native_splash's documented geometry for an icon with no icon
  // background: a 1152px canvas whose safe area is a 768px circle.
  const canvas = 1152;
  const safeCircle = 768;

  const sourcePath = 'assets/logo/logo-trans.png';
  const outputPath = 'assets/logo/logo-splash-android12.png';

  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Source logo not found: $sourcePath');
    exitCode = 1;
    return;
  }

  final decoded = img.decodePng(sourceFile.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not decode $sourcePath as PNG.');
    exitCode = 1;
    return;
  }

  // Drop any transparent margin the source already carries, so the padding we
  // add is measured against the real artwork rather than empty pixels.
  final art = img.trim(decoded, mode: img.TrimMode.transparent);

  final diagonal = math.sqrt(art.width * art.width + art.height * art.height);
  final scale = safeCircle / diagonal;
  final targetWidth = (art.width * scale).round();
  final targetHeight = (art.height * scale).round();

  final resized = img.copyResize(
    art,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.cubic,
  );

  final padded = img.Image(width: canvas, height: canvas, numChannels: 4);
  img.compositeImage(
    padded,
    resized,
    dstX: (canvas - targetWidth) ~/ 2,
    dstY: (canvas - targetHeight) ~/ 2,
  );

  File(outputPath).writeAsBytesSync(img.encodePng(padded, level: 6));

  stdout
    ..writeln('source     ${decoded.width}x${decoded.height}  $sourcePath')
    ..writeln('trimmed    ${art.width}x${art.height}')
    ..writeln('scaled     ${targetWidth}x$targetHeight  (${(scale * 100).toStringAsFixed(1)}%)')
    ..writeln('canvas     ${canvas}x$canvas, safe circle ${safeCircle}px')
    ..writeln('wrote      $outputPath');
}
