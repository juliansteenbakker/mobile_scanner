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
@staticInterop
class JSMap<K extends JSAny, V extends JSAny> {
  external factory JSMap();
}

extension JSMapExtension<K extends JSAny, V extends JSAny> on JSMap<K, V> {
  external V? get(K key);
  external JSVoid set(K key, V? value);
}
