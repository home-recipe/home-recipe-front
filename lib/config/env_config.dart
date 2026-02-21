import 'package:flutter/foundation.dart';

/// 환경 설정 관리 클래스
///
/// API 주소 등 환경별로 달라지는 설정을 중앙에서 관리합니다.
/// 테스트나 배포 환경에 따라 이 파일만 수정하면 됩니다.
class EnvConfig {
  EnvConfig._();

  // ============================================================
  // 서버 주소 설정 (여기만 수정하세요)
  // ============================================================

  /// 백엔드 서버 URL
  /// - 로컬 개발 (웹): http://localhost:8080
  /// - 로컬 개발 (Android 에뮬레이터): http://10.0.2.2:8080
  /// - 로컬 개발 (iOS 시뮬레이터): http://localhost:8080
  /// - 실제 기기: http://컴퓨터의 실제 IP:8080 (예: http://192.168.x.x:8080)
  /// - 배포 환경: https://실제서버도메인
  static const String _baseUrl = 'https://recook.kr';

  /// OAuth2 서버 URL
  static const String _oauthServerUrl = 'https://recook-server.site';

  /// API 기본 URL
  static String get baseUrl => _baseUrl;

  /// 클라이언트 타입 (WEB 또는 MOBILE)
  static String get clientType => kIsWeb ? 'WEB' : 'MOBILE';

  /// OAuth2 Google 로그인 URL (state, challenge 파라미터 포함)
  static String googleOAuthUrl(String codeChallenge) =>
      '$_oauthServerUrl/oauth2/authorization/google?state=$clientType&challenge=$codeChallenge';

  /// OAuth2 Kakao 로그인 URL (state, challenge 파라미터 포함)
  static String kakaoOAuthUrl(String codeChallenge) =>
      '$_oauthServerUrl/oauth2/authorization/kakao?state=$clientType&challenge=$codeChallenge';

  // ============================================================
  // 디버그 정보
  // ============================================================

  /// 현재 환경 설정 정보 출력 (디버깅용)
  static void printConfig() {
    if (kDebugMode) {
      print('=== EnvConfig ===');
      print('Base URL: $baseUrl');
      print('Google OAuth: ${googleOAuthUrl("DEBUG")}');
      print('Kakao OAuth: ${kakaoOAuthUrl("DEBUG")}');
      print('================');
    }
  }
}
