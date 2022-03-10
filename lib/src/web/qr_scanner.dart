@JS()
library qrscanner;

import 'package:js/js.dart';

@JS('QrScanner')
external String scanImage(var data);

@JS()
class QrScanner {
  external String get scanImage;
}
