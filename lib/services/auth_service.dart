import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/access_token_response.dart';
import '../models/join_request.dart';
import '../models/join_response.dart';
import '../models/user_response.dart';
import 'token_service.dart';
import 'api_client.dart';
import 'pkce_service.dart';
import '../screens/login_page.dart';
import 'package:flutter/material.dart';

/// 인증 관련 API 서비스
class AuthService {
  /// 일반 email/pw 로그인
  ///
  /// 서버가 JSON으로 토큰을 직접 응답:
  /// - 웹: accessToken만 저장 (refreshToken은 서버가 HttpOnly 쿠키로 세팅)
  /// - 앱: accessToken + refreshToken 모두 저장
  static Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await ApiClient.post<LoginResponse>(
        '/api/auth/login',
        (data) => LoginResponse.fromJson(data),
        body: request.toJson(),
        includeAuth: false,
      );

      if (response.code == 200 && response.response.data != null) {
        final data = response.response.data!;
        await TokenService.saveAccessToken(data.accessToken);

        // 앱: refreshToken도 저장 (웹은 HttpOnly 쿠키로 이미 세팅됨)
        if (!kIsWeb && data.refreshToken != null && data.refreshToken!.isNotEmpty) {
          await TokenService.saveRefreshToken(data.refreshToken!);
        }

        await TokenService.saveUserRole("USER");
      } else {
        throw Exception(response.message);
      }

      return response;
    } catch (e) {
      return ApiClient.networkError<LoginResponse>('네트워크 오류가 발생했습니다.');
    }
  }

  /// 소셜 로그인 전용: OAuth2 PKCE authorization code를 서버에 보내 토큰 교환
  static Future<void> exchangeCodeForTokens(String code) async {
    final verifier = await PkceService.getCodeVerifier();
    if (verifier == null || verifier.isEmpty) {
      throw Exception('code_verifier가 존재하지 않습니다.');
    }

    final response = await ApiClient.client.post(
      Uri.parse('${ApiClient.baseUrl}/api/auth/token'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'X-Client-Type': kIsWeb ? 'WEB' : 'MOBILE',
      },
      body: jsonEncode({
        'code': code,
        'code_verifier': verifier,
      }),
      encoding: utf8,
    );

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message = json['message'] ?? '토큰 교환에 실패했습니다.';
      throw Exception(message);
    }

    final data = json['response']?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('토큰 응답 데이터가 없습니다.');
    }

    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('accessToken이 응답에 포함되지 않았습니다.');
    }

    await TokenService.saveAccessToken(accessToken);

    if (!kIsWeb) {
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('refreshToken이 응답에 포함되지 않았습니다.');
      }
      await TokenService.saveRefreshToken(refreshToken);
    }

    await PkceService.deleteCodeVerifier();
    await TokenService.saveUserRole("USER");
  }

  /// 로그아웃
  static Future<ApiResponse<void>> logout() async {
    try {
      final refreshTokenValue = await TokenService.getRefreshToken();
      final headers = await ApiClient.getHeaders();

      final response = await ApiClient.post<void>(
        '/api/auth/logout',
        (_) => null,
        body: refreshTokenValue != null && refreshTokenValue.isNotEmpty
            ? {'refreshToken': refreshTokenValue}
            : null,
      );

      await TokenService.clearTokens();
      return response;
    } catch (e) {
      await TokenService.clearTokens();
      return ApiClient.networkError<void>('네트워크 오류가 발생했습니다.');
    }
  }

  /// Refresh Token으로 Access Token 재발급
  ///
  /// 플랫폼별 처리:
  /// - 웹(WEB): refreshToken이 HttpOnly 쿠키로 자동 전송됨 (withCredentials: true)
  /// - 앱(MOBILE): refreshToken을 Authorization 헤더에 포함하여 전송
  static Future<ApiResponse<AccessTokenResponse>> refreshToken() async {
    try {
      final http.Response response;

      if (kIsWeb) {
        // 웹: 쿠키가 자동으로 전송됨 (withCredentials: true)
        response = await ApiClient.client.post(
          Uri.parse('${ApiClient.baseUrl}/api/auth/reissue'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'X-Client-Type': 'WEB',
          },
          encoding: utf8,
        );
      } else {
        // 모바일: refreshToken을 secure storage에서 가져와서 헤더로 전송
        final refreshTokenValue = await TokenService.getRefreshToken();
        if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
          await _forceLogout();
          return ApiResponse<AccessTokenResponse>(
            code: 401,
            message: 'Refresh token이 없습니다.',
            response: ResponseDetail<AccessTokenResponse>(
              code: 'AUTH_NOT_EXIST_TOKEN',
              data: null,
            ),
          );
        }

        response = await ApiClient.client.post(
          Uri.parse('${ApiClient.baseUrl}/api/auth/reissue'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'X-Client-Type': 'MOBILE',
            'Authorization': 'Bearer $refreshTokenValue',
          },
          encoding: utf8,
        );
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final apiResponse = ApiResponse<AccessTokenResponse>.fromJson(
        json,
        (data) => AccessTokenResponse.fromJson(data),
      );

      // reissue에서도 AUTH_EXPIRED_TOKEN이면 로그아웃 처리
      if (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN') {
        await _forceLogout();
        return apiResponse;
      }

      // 새로운 accessToken 저장
      if (response.statusCode == 200 && apiResponse.response.data != null) {
        await TokenService.saveAccessToken(
          apiResponse.response.data!.accessToken,
        );
      }

      return apiResponse;
    } catch (e) {
      return ApiClient.networkError<AccessTokenResponse>('네트워크 오류가 발생했습니다.');
    }
  }

  /// 강제 로그아웃
  static Future<void> _forceLogout() async {
    try {
      final refreshTokenValue = await TokenService.getRefreshToken();
      if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
        final headers = await ApiClient.getHeaders();
        await ApiClient.client.post(
          Uri.parse('${ApiClient.baseUrl}/api/auth/logout'),
          headers: headers,
          body: jsonEncode({'refreshToken': refreshTokenValue}),
          encoding: utf8,
        );
      }
    } catch (e) {
      // 로그아웃 요청 실패해도 토큰은 삭제
    } finally {
      await TokenService.clearTokens();
      ApiClient.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  /// 회원가입
  static Future<ApiResponse<JoinResponse>> join(JoinRequest request) async {
    return await ApiClient.post<JoinResponse>(
      '/api/user',
      (data) => JoinResponse.fromJson(data),
      body: request.toJson(),
      includeAuth: false,
    );
  }

  /// 현재 사용자 정보 조회
  static Future<ApiResponse<UserResponse>> getCurrentUser() async {
    final response = await ApiClient.get<UserResponse>(
      '/api/user/me',
      (data) => UserResponse.fromJson(data),
    );

    // 사용자 정보 조회 성공 시 role 저장
    if (response.code == 200 && response.response.data != null) {
      await TokenService.saveUserRole(response.response.data!.role);
    }

    return response;
  }

  /// 이메일 중복 체크
  static Future<ApiResponse<void>> checkEmail(String email) async {
    return await ApiClient.post<void>(
      '/api/user/email',
      (_) => null,
      body: {'email': email},
      includeAuth: false,
    );
  }
}
