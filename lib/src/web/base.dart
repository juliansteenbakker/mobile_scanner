import 'dart:html';

abstract class WebBarcodeReaderBase {
  Stream<String?> detectBarcodeContinuously(VideoElement video);
}
