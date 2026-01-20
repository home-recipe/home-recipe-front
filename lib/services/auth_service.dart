import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import '../models/api_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/access_token_response.dart';
import '../models/join_request.dart';
import '../models/join_response.dart';
import '../models/user_response.dart';
import 'token_service.dart';
import 'api_client.dart';
import '../screens/login_page.dart';
import 'package:flutter/material.dart';

/// 인증 관련 API 서비스
class AuthService {
  /// 로그인
  static Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await ApiClient.post<LoginResponse>(
        '/api/auth/login',
        (data) => LoginResponse.fromJson(data),
        body: request.toJson(),
        includeAuth: false,
      );

      // accessToken, refreshToken, role 저장
      if (response.code == 200 && response.response.data != null) {
        await TokenService.saveAccessToken(
          response.response.data!.accessToken,
        );
        await TokenService.saveRefreshToken(
          response.response.data!.refreshToken,
        );
        await TokenService.saveUserRole(
          response.response.data!.role.toJson(),
        );
      }

      return response;
    } catch (e) {
      return ApiClient.networkError<LoginResponse>('네트워크 오류가 발생했습니다.');
    }
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
  static Future<ApiResponse<AccessTokenResponse>> refreshToken() async {
    try {
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

      // Authorization Bearer 헤더에 refreshToken 넣기
      final response = await ApiClient.client.post(
        Uri.parse('${ApiClient.baseUrl}/api/auth/reissue'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'X-Client-Type': kIsWeb ? 'WEB' : 'MOBILE',
          'Authorization': 'Bearer $refreshTokenValue',
        },
        encoding: utf8,
      );

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
