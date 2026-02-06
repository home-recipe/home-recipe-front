import 'package:flutter/foundation.dart';
import 'web_utils_stub.dart'
    if (dart.library.js_interop) 'web_utils_web.dart' as impl;

/// 웹에서 로딩 화면 제거
void removeLoadingScreen() {
  if (kIsWeb) {
    impl.removeLoadingScreen();
  }
}

/// 폰트 프리로딩 완료까지 대기
Future<void> waitForFontsReady() async {
  if (kIsWeb) {
    await impl.waitForFontsReady();
  }
}
