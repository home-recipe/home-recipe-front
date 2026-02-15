import 'dart:html' as html;

// 역할 : 웹 브라우저의 실제 기능(DOM, Window)에 접근
// 브라우저 주소창의 URL을 읽어오기 위해 window 객체가 필요
String getFullUrl() {
  return html.window.location.href;
}

void redirectTo(String url) {
  html.window.location.href = url;
}

/// 웹에서 현재 경로 반환 (OAuth 콜백 라우팅용)
String getCurrentPath() {
  return html.window.location.pathname ?? '/'; 
}
