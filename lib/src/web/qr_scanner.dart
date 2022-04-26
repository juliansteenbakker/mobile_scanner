@JS()
library qrscanner;

import 'package:js/js.dart';

@JS('QrScanner')
external String scanImage(dynamic data);

@JS()
class QrScanner {
  external String get scanImage;
}
