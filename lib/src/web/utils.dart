import 'dart:async';
import 'dart:html' as html;
import 'dart:js' show context, JsObject;

import 'package:mobile_scanner/src/web/base.dart';

Future<void> loadScript(JsLibrary library) async {
  dynamic amd;
  dynamic define;
  // ignore: avoid_dynamic_calls
  if (library.usesRequireJs && context['define']?['amd'] != null) {
    // In dev, requireJs is loaded in. Disable it here.
    // see https://github.com/dart-lang/sdk/issues/33979
    define = JsObject.fromBrowserObject(context['define'] as Object);
    // ignore: avoid_dynamic_calls
    amd = define['amd'];
    // ignore: avoid_dynamic_calls
    define['amd'] = false;
  }
  try {
    await loadScriptUsingScriptTag(library.url);
  } finally {
    if (amd != null) {
      // Re-enable requireJs
      // ignore: avoid_dynamic_calls
      define['amd'] = amd;
    }
  }
}

Future<void> loadScriptUsingScriptTag(String url) {
  final script = html.ScriptElement()
    ..async = true
    ..defer = false
    ..crossOrigin = 'anonymous'
    ..type = 'text/javascript'
    // ignore: unsafe_html
    ..src = url;

  html.document.head!.append(script);

  return script.onLoad.first;
}

/// Injects JS [libraries]
///
/// Returns a [Future] that resolves when all of the `script` tags `onLoad` events trigger.
Future<void> injectJSLibraries(List<JsLibrary> libraries) {
  final List<Future<void>> loading = [];

  for (final library in libraries) {
    final future = loadScript(library);
    loading.add(future);
  }

  return Future.wait(loading);
}
