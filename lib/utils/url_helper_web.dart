import 'dart:html' as html;

/// 웹에서 현재 페이지를 지정된 URL로 리다이렉션
void redirectTo(String url) {
  html.window.location.href = url;
}

/// 웹에서 현재 경로 반환 (OAuth 콜백 라우팅용)
String getCurrentPath() {
  return html.window.location.pathname ?? '/'; 
}
