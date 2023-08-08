import 'package:flutter/rendering.dart';

/// the [scanWindow] rect will be relative and scaled to the [widgetSize] not the texture. so it is possible,
/// depending on the [fit], for the [scanWindow] to partially or not at all overlap the [textureSize]
///
/// since when using a [BoxFit] the content will always be centered on its parent. we can convert the rect
/// to be relative to the texture.
///
/// since the textures size and the actuall image (on the texture size) might not be the same, we also need to
/// calculate the scanWindow in terms of percentages of the texture, not pixels.
Rect calculateScanWindowRelativeToTextureInPercentage(
  BoxFit fit,
  Rect scanWindow,
  Size textureSize,
  Size widgetSize,
) {
  double fittedTextureWidth;
  double fittedTextureHeight;

  switch (fit) {
    case BoxFit.contain:
      final widthRatio = widgetSize.width / textureSize.width;
      final heightRatio = widgetSize.height / textureSize.height;
      final scale = widthRatio < heightRatio ? widthRatio : heightRatio;
      fittedTextureWidth = textureSize.width * scale;
      fittedTextureHeight = textureSize.height * scale;
      break;

    case BoxFit.cover:
      final widthRatio = widgetSize.width / textureSize.width;
      final heightRatio = widgetSize.height / textureSize.height;
      final scale = widthRatio > heightRatio ? widthRatio : heightRatio;
      fittedTextureWidth = textureSize.width * scale;
      fittedTextureHeight = textureSize.height * scale;
      break;

    case BoxFit.fill:
      fittedTextureWidth = widgetSize.width;
      fittedTextureHeight = widgetSize.height;
      break;

    case BoxFit.fitHeight:
      final ratio = widgetSize.height / textureSize.height;
      fittedTextureWidth = textureSize.width * ratio;
      fittedTextureHeight = widgetSize.height;
      break;

    case BoxFit.fitWidth:
      final ratio = widgetSize.width / textureSize.width;
      fittedTextureWidth = widgetSize.width;
      fittedTextureHeight = textureSize.height * ratio;
      break;

    case BoxFit.none:
    case BoxFit.scaleDown:
      fittedTextureWidth = textureSize.width;
      fittedTextureHeight = textureSize.height;
      break;
  }

  final offsetX = (widgetSize.width - fittedTextureWidth) / 2;
  final offsetY = (widgetSize.height - fittedTextureHeight) / 2;

  final left = (scanWindow.left - offsetX) / fittedTextureWidth;
  final top = (scanWindow.top - offsetY) / fittedTextureHeight;
  final right = (scanWindow.right - offsetX) / fittedTextureWidth;
  final bottom = (scanWindow.bottom - offsetY) / fittedTextureHeight;

  return Rect.fromLTRB(left, top, right, bottom);
}
