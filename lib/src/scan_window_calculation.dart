import 'dart:math';

import 'package:flutter/rendering.dart';

/// Calculate the scan window rectangle relative to the texture size.
///
/// The [scanWindow] rectangle will be relative and scaled to [widgetSize], not [textureSize].
/// Depending on the given [fit], the [scanWindow] can partially overlap the [textureSize],
/// or not at all.
///
/// Due to using [BoxFit] the content will always be centered on its parent,
/// which enables converting the rectangle to be relative to the texture.
///
/// Because the size of the actual texture and the size of the texture in widget-space
/// can be different, calculate the size of the scan window in percentages,
/// rather than pixels.
///
/// Returns a [Rect] that represents the position and size of the scan window in the texture.
Rect calculateScanWindowRelativeToTextureInPercentage(
  BoxFit fit,
  Rect scanWindow, {
  required Size textureSize,
  required Size widgetSize,
}) {
  // Convert the texture size to a size in widget-space, with the box fit applied.
  final fittedTextureSize = applyBoxFit(fit, textureSize, widgetSize);

  // Get the correct scaling values depending on the given BoxFit mode
  double sx = fittedTextureSize.destination.width / textureSize.width;
  double sy = fittedTextureSize.destination.height / textureSize.height;

  switch (fit) {
    case BoxFit.fill:
      // No-op, just use sx and sy.
      break;
    case BoxFit.contain:
      final s = min(sx, sy);
      sx = s;
      sy = s;
    case BoxFit.cover:
      final s = max(sx, sy);
      sx = s;
      sy = s;
    case BoxFit.fitWidth:
      sy = sx;
    case BoxFit.fitHeight:
      sx = sy;
    case BoxFit.none:
      sx = 1.0;
      sy = 1.0;
    case BoxFit.scaleDown:
      final s = min(sx, sy);
      sx = s;
      sy = s;
  }

  // Fit the texture size to the widget rectangle given by the scaling values above.
  final textureWindow = Alignment.center.inscribe(
    Size(textureSize.width * sx, textureSize.height * sy),
    Rect.fromLTWH(0, 0, widgetSize.width, widgetSize.height),
  );

  // Transform the scan window from widget coordinates to texture coordinates.
  final scanWindowInTexSpace = Rect.fromLTRB(
    (1 / sx) * (scanWindow.left - textureWindow.left),
    (1 / sy) * (scanWindow.top - textureWindow.top),
    (1 / sx) * (scanWindow.right - textureWindow.left),
    (1 / sy) * (scanWindow.bottom - textureWindow.top),
  );

  // Clip the scan window in texture coordinates with the texture bounds.
  // This prevents percentages outside the range [0; 1].
  final clippedScanWndInTexSpace = scanWindowInTexSpace.intersect(
    Rect.fromLTWH(0, 0, textureSize.width, textureSize.height),
  );

  // Compute relative rectangle coordinates,
  // with respect to the texture size, i.e. scan image.
  final percentageLeft = clippedScanWndInTexSpace.left / textureSize.width;
  final percentageTop = clippedScanWndInTexSpace.top / textureSize.height;
  final percentageRight = clippedScanWndInTexSpace.right / textureSize.width;
  final percentageBottom = clippedScanWndInTexSpace.bottom / textureSize.height;

  // This rectangle can be used to cut out a rectangle of the scan image.
  return Rect.fromLTRB(
    percentageLeft,
    percentageTop,
    percentageRight,
    percentageBottom,
  );
}
