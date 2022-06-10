// // This is here because dart doesn't seem to support this properly
// // https://stackoverflow.com/questions/61161135/adding-support-for-navigator-mediadevices-getusermedia-to-dart

// ignore_for_file: always_specify_types, strict_raw_type

@JS('navigator.mediaDevices')
library media_devices;

import 'package:js/js.dart';

@JS('getUserMedia')
external Future<dynamic> getUserMedia(UserMediaOptions constraints);

@JS()
@anonymous
class UserMediaOptions {
  external factory UserMediaOptions({VideoOptions? video});
  external VideoOptions get video;
}

@JS()
@anonymous
class VideoOptions {
  external factory VideoOptions({
    String? facingMode,
    DeviceIdOptions? deviceId,
    Map? width,
    Map? height,
  });
  external String get facingMode;
  // external DeviceIdOptions get deviceId;
  external Map get width;
  external Map get height;
}

@JS()
@anonymous
class DeviceIdOptions {
  external factory DeviceIdOptions({String? exact});
  external String get exact;
}
