import 'dart:html' as html;

/// 웹에서 현재 페이지를 지정된 URL로 리다이렉션
void redirectTo(String url) {
  html.window.location.href = url;
}
