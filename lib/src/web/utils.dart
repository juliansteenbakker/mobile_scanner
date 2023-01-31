import 'dart:async';
import 'dart:html' as html;
import 'dart:js' show context;

import 'package:js/js.dart';
import 'package:mobile_scanner/src/web/base.dart';

Future<void> loadScript(JsLibrary library) async {
  // ignore: avoid_dynamic_calls
  if (library.usesRequireJs && context['define']?['amd'] != null) {
    // see https://github.com/dart-lang/sdk/issues/33979
    return loadScriptUsingRequireJS(library.contextName, library.url);
  } else {
    return loadScriptUsingScriptTag(library.url);
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

Future<void> loadScriptUsingRequireJS(String packageName, String url) {
  final Completer completer = Completer();
  final String eventName = '_${packageName}Loaded';

  context.callMethod(
    'addEventListener',
    [eventName, allowInterop((_) => completer.complete())],
  );

  final script = html.ScriptElement()
    ..type = 'text/javascript'
    ..async = false
    ..defer = false
    ..text = '''
        require(["$url"], (package) => {
          window.$packageName = package;
          const event = new Event("$eventName");
          dispatchEvent(event);
        })
        ''';

  html.document.head!.append(script);

  return completer.future;
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
