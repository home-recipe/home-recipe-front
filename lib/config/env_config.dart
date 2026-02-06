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
  static const String _baseUrl = 'http://recook-server.site:8080';

  /// API 기본 URL
  static String get baseUrl => _baseUrl;

  /// OAuth2 Google 로그인 URL
  static String get googleOAuthUrl => '$baseUrl/oauth2/authorization/google';

  /// OAuth2 Kakao 로그인 URL
  static String get kakaoOAuthUrl => '$baseUrl/oauth2/authorization/kakao';

  // ============================================================
  // 디버그 정보
  // ============================================================

  /// 현재 환경 설정 정보 출력 (디버깅용)
  static void printConfig() {
    if (kDebugMode) {
      print('=== EnvConfig ===');
      print('Base URL: $baseUrl');
      print('Google OAuth: $googleOAuthUrl');
      print('Kakao OAuth: $kakaoOAuthUrl');
      print('================');
    }
  }
}
