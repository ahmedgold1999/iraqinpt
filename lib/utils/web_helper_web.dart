// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void removeWebLoader() {
  try {
    js.context.callMethod('removeLoader');
  } catch (e) {
    // ignore: avoid_print
    print('Web loader removal failed: $e');
  }
}
