// 웹용 스토리지 구현 (브라우저 localStorage 사용)
// Wasm 호환: dart:html 대신 package:web 사용
import 'package:web/web.dart' as web;

class StorageWeb {
  static Future<void> setItem(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }

  static Future<String?> getItem(String key) async {
    return web.window.localStorage.getItem(key);
  }

  static Future<void> removeItem(String key) async {
    web.window.localStorage.removeItem(key);
  }
}
