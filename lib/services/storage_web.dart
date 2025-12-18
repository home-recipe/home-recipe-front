// 웹용 스토리지 구현 (브라우저 localStorage 사용)
import 'dart:html' as html;

class StorageWeb {
  static Future<void> setItem(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  static Future<String?> getItem(String key) async {
    return html.window.localStorage[key];
  }

  static Future<void> removeItem(String key) async {
    html.window.localStorage.remove(key);
  }
}

