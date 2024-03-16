import 'dart:js_interop';

/// A static interop stub for the `Map` class.
///
/// This stub is here because the `js_types` from the Dart SDK do not yet provide a `Map` equivalent:
/// https://github.com/dart-lang/sdk/issues/54365
///
/// See also: https://github.com/dart-lang/sdk/issues/54365#issuecomment-1856995463
///
/// Object literals can be made using [jsify].
@JS('Map')
extension type JSMap<K extends JSAny, V extends JSAny>._(JSObject _)
    implements JSObject {
  external factory JSMap();

  external V? get(K key);
  external JSVoid set(K key, V? value);
}
