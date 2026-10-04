// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class StorageHelper {
  static String? getString(String key) {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  static void setString(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }
}
