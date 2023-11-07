import 'package:flutter/widgets.dart';

import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';

/// An implementation for [MobileScannerViewAttributes] for platforms that provide a [Texture].
class MobileScannerTextureViewAttributes
    implements MobileScannerViewAttributes {
  const MobileScannerTextureViewAttributes({
    required this.textureId,
    required this.hasTorch,
    required this.size,
  });

  /// The id of the [Texture].
  final int textureId;

  @override
  final bool hasTorch;

  @override
  final Size size;
}
