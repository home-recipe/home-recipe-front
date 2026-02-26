import 'package:flutter/foundation.dart';

/// 환경 설정 관리 클래스
///
/// API 주소 등 환경별로 달라지는 설정을 중앙에서 관리합니다.
/// Release/Debug 모드와 Web/Mobile 플랫폼에 따라 자동으로 적절한 URL이 선택됩니다.
class EnvConfig {
  EnvConfig._();

  // ============================================================
  // 서버 주소 상수 정의
  // ============================================================

  /// 프로덕션 서버 URL (배포 환경)
  static const String _prodBaseUrl = 'https://recook.kr';

  /// 로컬 개발 서버 URL - 웹 (localhost)
  static const String _devWebBaseUrl = 'http://localhost:8080';

  /// 로컬 개발 서버 URL - Android 에뮬레이터 (10.0.2.2는 호스트 머신을 가리킴)
  static const String _devMobileBaseUrl = 'http://10.0.2.2:8080';

  /// OAuth2 서버 URL
  static const String _oauthServerUrl = 'https://recook-server.site';

  // ============================================================
  // 동적 환경 설정
  // ============================================================

  /// API 기본 URL (환경별 자동 전환)
  ///
  /// - Release 모드: 프로덕션 서버 (https://recook.kr)
  /// - Debug 모드 + Web: 로컬 서버 (http://localhost:8080)
  /// - Debug 모드 + Mobile: Android 에뮬레이터용 로컬 서버 (http://10.0.2.2:8080)
  static String get baseUrl {
    if (kReleaseMode) {
      // Release 빌드: 프로덕션 서버 사용
      return _prodBaseUrl;
    } else {
      // Debug 빌드: 플랫폼에 따라 로컬 서버 주소 선택
      return kIsWeb ? _devWebBaseUrl : _devMobileBaseUrl;
    }
  }

  /// OAuth 서버 URL (환경별 자동 전환)
  ///
  /// 현재는 모든 환경에서 동일한 OAuth 서버를 사용하지만,
  /// 향후 개발용 OAuth 서버가 필요할 경우 여기서 분기 처리 가능
  static String get oauthServerUrl => _oauthServerUrl;

  /// 클라이언트 타입 (WEB 또는 MOBILE)
  ///
  /// OAuth 요청 시 state 파라미터로 사용되어 서버가 클라이언트 타입을 식별
  static String get clientType => kIsWeb ? 'WEB' : 'MOBILE';

  // ============================================================
  // OAuth URL 생성
  // ============================================================

  /// OAuth2 Google 로그인 URL 생성
  ///
  /// [codeChallenge]: PKCE 방식의 인증을 위한 코드 챌린지 값
  /// Returns: Google OAuth 인증 요청 URL (state, challenge 파라미터 포함)
  static String googleOAuthUrl(String codeChallenge) =>
      '$oauthServerUrl/oauth2/authorization/google?state=$clientType&challenge=$codeChallenge';

  /// OAuth2 Kakao 로그인 URL 생성
  ///
  /// [codeChallenge]: PKCE 방식의 인증을 위한 코드 챌린지 값
  /// Returns: Kakao OAuth 인증 요청 URL (state, challenge 파라미터 포함)
  static String kakaoOAuthUrl(String codeChallenge) =>
      '$oauthServerUrl/oauth2/authorization/kakao?state=$clientType&challenge=$codeChallenge';

  // ============================================================
  // 디버그 정보
  // ============================================================

  /// 현재 환경 설정 정보 출력 (디버깅용)
  ///
  /// Debug 모드에서만 동작하며, 다음 정보를 콘솔에 출력합니다:
  /// - 빌드 모드 (Release/Debug)
  /// - 플랫폼 (Web/Mobile)
  /// - 사용 중인 API 서버 주소
  /// - OAuth 서버 주소 및 생성된 OAuth URL 예시
  static void printConfig() {
    if (kDebugMode) {
      print('==========================================');
      print('========== EnvConfig 환경 설정 ==========');
      print('==========================================');
      print('빌드 모드: ${kReleaseMode ? "Release" : "Debug"}');
      print('플랫폼: ${kIsWeb ? "Web" : "Mobile"}');
      print('------------------------------------------');
      print('Base URL: $baseUrl');
      print('OAuth Server URL: $oauthServerUrl');
      print('Client Type: $clientType');
      print('------------------------------------------');
      print('Google OAuth: ${googleOAuthUrl("DEBUG_CHALLENGE")}');
      print('Kakao OAuth: ${kakaoOAuthUrl("DEBUG_CHALLENGE")}');
      print('==========================================');
    }
  }
}
