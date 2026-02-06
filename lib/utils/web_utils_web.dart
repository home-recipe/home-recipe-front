import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// 웹에서 로딩 화면 제거
void removeLoadingScreen() {
  try {
    // 타임아웃 해제
    final timeout = _getLoadingTimeout();
    if (timeout != null) {
      web.window.clearTimeout(timeout);
    }
    // 로딩 화면 제거 함수 호출
    _callRemoveLoadingScreen();
  } catch (e) {
    // 에러 무시 - 이미 제거되었거나 함수가 없을 수 있음
  }
}

/// 폰트 로딩 완료 대기
Future<void> waitForFontsReady() async {
  try {
    await web.document.fonts.ready.toDart;
  } catch (e) {
    // document.fonts API 미지원 시 무시
  }
}

@JS('removeLoadingScreen')
external void _callRemoveLoadingScreen();

@JS('_loadingTimeout')
external int? _getLoadingTimeout();
