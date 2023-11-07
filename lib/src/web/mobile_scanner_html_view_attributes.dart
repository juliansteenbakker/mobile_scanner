import 'package:flutter/widgets.dart';

import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';

/// An implementation for [MobileScannerViewAttributes] for the web.
class MobileScannerHtmlViewAttributes implements MobileScannerViewAttributes {
  const MobileScannerHtmlViewAttributes({
    required this.htmlElementViewType,
    required this.hasTorch,
    required this.size,
  });

  @override
  final bool hasTorch;

  /// The [HtmlElementView.viewType] for the underlying [HtmlElementView].
  final String htmlElementViewType;

  @override
  final Size size;
}
