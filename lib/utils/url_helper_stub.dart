//공통 인터페이스
//웹, 앱도 아닌 기본상태 
//컴파일러가 안드로이드용으로 빌드할 때 dart:html 대신 이 파일 읽어서 에러 내지 않게 방어

//현재 페이지의 전체 URL을 가져오는 함수 정의
String getFullUrl() {
  //모바일에서는 브라우저의 window 개념이 없으므로 빈 값 반환
  return '';
}

void redirectTo(String url) {
  throw UnsupportedError('redirectTo is only supported on web');
}

String getCurrentPath() => '/';
