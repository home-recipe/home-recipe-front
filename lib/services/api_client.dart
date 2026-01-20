import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import '../models/api_response.dart';
import 'token_service.dart';
import '../screens/login_page.dart';
import 'auth_service.dart';

/// 공통 API 클라이언트
/// 인증 에러 처리, 재시도 로직 등을 통합 관리
class ApiClient {
  static const String baseUrl = 'http://localhost:8080';
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Web / Mobile 공통 HTTP Client
  static http.Client get client => kIsWeb
      ? (BrowserClient()..withCredentials = true)
      : http.Client();

  /// 공통 헤더 생성
  static Future<Map<String, String>> getHeaders({
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'X-Client-Type': kIsWeb ? 'WEB' : 'MOBILE',
    };

    if (includeAuth) {
      final token = await TokenService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// 네트워크 에러 응답 생성
  static ApiResponse<T> networkError<T>(String message) {
    return ApiResponse<T>(
      code: -1,
      message: message,
      response: ResponseDetail<T>(
        code: 'NETWORK_ERROR',
        data: null,
      ),
    );
  }

  /// 인증 에러 처리
  static Future<bool> handleAuthError<T>(ApiResponse<T> apiResponse) async {
    final responseCode = apiResponse.response.code;

    if (responseCode == 'AUTH_EXPIRED_TOKEN') {
      final refreshResponse = await AuthService.refreshToken();
      if (refreshResponse.code == 200 && refreshResponse.response.data != null) {
        return true; // 재시도 가능
      }
      return false; // 이미 refreshToken()에서 _forceLogout() 호출됨
    } else if (responseCode == 'AUTH_NOT_EXIST_TOKEN' || 
               responseCode == 'AUTH_INVALID_TOKEN') {
      await _forceLogout();
      return false;
    }

    return false;
  }

  /// 강제 로그아웃 처리
  static Future<void> _forceLogout() async {
    try {
      final refreshTokenValue = await TokenService.getRefreshToken();
      if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
        final headers = await getHeaders();
        await client.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: headers,
          body: jsonEncode({
            'refreshToken': refreshTokenValue,
          }),
          encoding: utf8,
        );
      }
    } catch (e) {
      // 로그아웃 요청 실패해도 토큰은 삭제
    } finally {
      await TokenService.clearTokens();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  /// GET 요청 실행 (인증 에러 처리 및 재시도 포함)
  static Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      var response = await client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(),
      );

      var json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      var apiResponse = ApiResponse<T>.fromJson(json, fromJson);

      // 인증 에러 처리
      final shouldRetry = await handleAuthError(apiResponse);
      if (shouldRetry && 
          (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
           apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await client.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: await getHeaders(),
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        apiResponse = ApiResponse<T>.fromJson(json, fromJson);
      }

      return apiResponse;
    } catch (e) {
      return networkError<T>('네트워크 오류가 발생했습니다.');
    }
  }

  /// POST 요청 실행 (인증 에러 처리 및 재시도 포함)
  static Future<ApiResponse<T>> post<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      var response = await client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(includeAuth: includeAuth),
        body: body != null ? jsonEncode(body) : null,
        encoding: utf8,
      );

      var json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      var apiResponse = ApiResponse<T>.fromJson(json, fromJson);

      // 인증 에러 처리 (인증이 필요한 경우만)
      if (includeAuth) {
        final shouldRetry = await handleAuthError(apiResponse);
        if (shouldRetry && 
            (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
             apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
          // 재시도
          response = await client.post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await getHeaders(includeAuth: includeAuth),
            body: body != null ? jsonEncode(body) : null,
            encoding: utf8,
          );
          json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          apiResponse = ApiResponse<T>.fromJson(json, fromJson);
        }
      }

      return apiResponse;
    } catch (e) {
      return networkError<T>('네트워크 오류가 발생했습니다.');
    }
  }

  /// PUT 요청 실행 (인증 에러 처리 및 재시도 포함)
  static Future<ApiResponse<T>> put<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? body,
  }) async {
    try {
      var response = await client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(),
        body: body != null ? jsonEncode(body) : null,
        encoding: utf8,
      );

      var json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      var apiResponse = ApiResponse<T>.fromJson(json, fromJson);

      // 인증 에러 처리
      final shouldRetry = await handleAuthError(apiResponse);
      if (shouldRetry && 
          (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
           apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await client.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: await getHeaders(),
          body: body != null ? jsonEncode(body) : null,
          encoding: utf8,
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        apiResponse = ApiResponse<T>.fromJson(json, fromJson);
      }

      return apiResponse;
    } catch (e) {
      return networkError<T>('네트워크 오류가 발생했습니다.');
    }
  }

  /// DELETE 요청 실행 (인증 에러 처리 및 재시도 포함)
  static Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T? Function(Map<String, dynamic>)? fromJson,
  ) async {
    try {
      var response = await client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(),
      );

      var json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      
      // fromJson이 null이면 void 타입으로 간주
      ApiResponse<T> apiResponse;
      if (fromJson == null) {
        // void 타입인 경우
        apiResponse = ApiResponse<T>(
          code: json['code'] as int,
          message: json['message'] as String,
          response: ResponseDetail<T>(
            code: json['response']['code'] as String,
            data: null,
          ),
        );
      } else {
        // fromJson을 non-nullable로 변환
        final nonNullFromJson = (Map<String, dynamic> data) => fromJson(data) as T;
        apiResponse = ApiResponse<T>.fromJson(json, nonNullFromJson);
      }

      // 인증 에러 처리
      final shouldRetry = await handleAuthError(apiResponse);
      if (shouldRetry && 
          (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
           apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await client.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: await getHeaders(),
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (fromJson == null) {
          apiResponse = ApiResponse<T>(
            code: json['code'] as int,
            message: json['message'] as String,
            response: ResponseDetail<T>(
              code: json['response']['code'] as String,
              data: null,
            ),
          );
        } else {
          // fromJson을 non-nullable로 변환
          final nonNullFromJson = (Map<String, dynamic> data) => fromJson(data) as T;
          apiResponse = ApiResponse<T>.fromJson(json, nonNullFromJson);
        }
      }

      return apiResponse;
    } catch (e) {
      return networkError<T>('네트워크 오류가 발생했습니다.');
    }
  }
}
