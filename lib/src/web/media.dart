// This is here because dart doesn't seem to support this properly
// https://stackoverflow.com/questions/61161135/adding-support-for-navigator-mediadevices-getusermedia-to-dart

@JS('navigator.mediaDevices')
library media_devices;

import 'package:js/js.dart';

@JS('getUserMedia')
external Future<dynamic> getUserMedia(UserMediaOptions constraints);

@JS()
@anonymous
class UserMediaOptions {
  external VideoOptions get video;

  external factory UserMediaOptions({VideoOptions? video});
}

@JS()
@anonymous
class VideoOptions {
  external String get facingMode;
  // external DeviceIdOptions get deviceId;

  external factory VideoOptions(
      {String? facingMode, DeviceIdOptions? deviceId});
}

@JS()
@anonymous
class DeviceIdOptions {
  external String get exact;

  external factory DeviceIdOptions({String? exact});
}
