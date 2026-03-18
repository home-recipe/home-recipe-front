// Wasm 호환: dart:html 대신 package:web 사용
import 'package:web/web.dart' as web;

// 역할 : 웹 브라우저의 실제 기능(DOM, Window)에 접근
// 브라우저 주소창의 URL을 읽어오기 위해 window 객체가 필요
String getFullUrl() {
  return web.window.location.href;
}

void redirectTo(String url) {
  web.window.location.href = url;
}

/// 웹에서 현재 경로 반환 (OAuth 콜백 라우팅용)
String getCurrentPath() {
  return web.window.location.pathname;
}
