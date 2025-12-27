import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:flutter/material.dart';

import '../models/api_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/join_request.dart';
import '../models/join_response.dart';
import '../models/refrigerator_response.dart';
import '../models/ingredient_response.dart';
import '../models/recipes_response.dart';
import '../models/recommendations_response.dart';
import 'token_service.dart';
import '../screens/login_page.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 🔑 Web / Mobile 공통 HTTP Client
  static final http.Client _client = kIsWeb
      ? (BrowserClient()..withCredentials = true)
      : http.Client();

  /* ================= 공통 ================= */

  static Future<Map<String, String>> _getHeaders({
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

  static ApiResponse<T> _networkError<T>(String message) {
    return ApiResponse<T>(
      code: -1,
      message: message,
      response: ResponseDetail<T>(
        code: 'NETWORK_ERROR',
        data: null,
      ),
    );
  }

  /* ================= Refresh Token ================= */

/////////Refresh Token 꺼내기/////////
  static Future<ApiResponse<LoginResponse>> refreshToken() async {
    try {
      final refreshTokenValue = await TokenService.getRefreshToken();
      if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
        await _forceLogout();
        return ApiResponse<LoginResponse>(
          code: 401,
          message: 'Refresh token이 없습니다.',
          response: ResponseDetail<LoginResponse>(
            code: 'AUTH_NOT_EXIST_TOKEN',
            data: null,
          ),
        );
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/reissue'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          'refreshToken': refreshTokenValue,
        }),
        encoding: utf8,
      );

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final apiResponse = ApiResponse<LoginResponse>.fromJson(
        json,
        (data) => LoginResponse.fromJson(data),
      );

      // AUTH_REFRESH_EXPIRED_TOKEN 또는 AUTH_REFRESH_INVALID_TOKEN이면 로그아웃 처리
      if (apiResponse.response.code == 'AUTH_REFRESH_EXPIRED_TOKEN' ||
          apiResponse.response.code == 'AUTH_REFRESH_INVALID_TOKEN') {
        await _forceLogout();
        return apiResponse;
      }

      // 새로운 accessToken 저장
      if (response.statusCode == 200 &&
          apiResponse.response.data != null) {
        await TokenService.saveAccessToken(
          apiResponse.response.data!.accessToken,
        );
      }

      return apiResponse;
    } catch (e) {
      return _networkError<LoginResponse>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 공통 응답 처리 ================= */

  /// 응답 코드에 따라 인증 에러를 처리합니다.
  /// 반환값: true면 재시도 가능, false면 재시도 불가 (로그아웃 필요)
  static Future<bool> _handleAuthError<T>(
    ApiResponse<T> apiResponse,
  ) async {
    final responseCode = apiResponse.response.code;

    if (responseCode == 'AUTH_EXPIRED_TOKEN') {
      // Refresh token으로 accessToken 갱신
      final refreshResponse = await refreshToken();
      if (refreshResponse.code == 200 && refreshResponse.response.data != null) {
        // accessToken이 갱신되었으므로 재시도 가능
        return true;
      } else {
        // Refresh token도 만료되었거나 실패한 경우
        await _forceLogout();
        return false;
      }
    } else if (responseCode == 'AUTH_NOT_EXIST_TOKEN') {
      // accessToken이 없으므로 로그아웃 처리
      await _forceLogout();
      return false;
    } else if (responseCode == 'AUTH_INVALID_TOKEN') {
      // Invalid token이므로 로그아웃 처리
      await _forceLogout();
      return false;
    }

    // 다른 에러 코드는 재시도 불가
    return false;
  }

  /// 강제 로그아웃 처리 (refreshToken을 사용하여 로그아웃 요청)
  static Future<void> _forceLogout() async {
    try {
      final refreshTokenValue = await TokenService.getRefreshToken();
      if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
        // refreshToken을 body에 담아서 로그아웃 요청
        await _client.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode({
            'refreshToken': refreshTokenValue,
          }),
          encoding: utf8,
        );
      }
    } catch (e) {
      // 로그아웃 요청 실패해도 토큰은 삭제
    } finally {
      // 토큰 삭제
      await TokenService.clearTokens();
      // 로그인 페이지로 전환
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  /* ================= 로그인 ================= */

  static Future<ApiResponse<LoginResponse>> login(
    LoginRequest request,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: await _getHeaders(includeAuth: false),
        body: jsonEncode(request.toJson()),
        encoding: utf8,
      );

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final apiResponse = ApiResponse<LoginResponse>.fromJson(
        json,
        (data) => LoginResponse.fromJson(data),
      );

      // accessToken과 refreshToken 저장
      if (response.statusCode == 200 &&
          apiResponse.response.data != null) {
        await TokenService.saveAccessToken(
          apiResponse.response.data!.accessToken,
        );
        await TokenService.saveRefreshToken(
          apiResponse.response.data!.refreshToken,
        );
      }

      return apiResponse;
    } catch (e) {
      return _networkError<LoginResponse>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 로그아웃 ================= */

  static Future<ApiResponse<void>> logout() async {
    try {
      // refreshToken을 body에 담아서 로그아웃 요청
      final refreshTokenValue = await TokenService.getRefreshToken();
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'X-Client-Type': kIsWeb ? 'WEB' : 'MOBILE',
      };

      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: headers,
        body: refreshTokenValue != null && refreshTokenValue.isNotEmpty
            ? jsonEncode({
                'refreshToken': refreshTokenValue,
              })
            : null,
        encoding: utf8,
      );

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      await TokenService.clearTokens();

      return ApiResponse<void>(
        code: json['code'] as int,
        message: json['message'] as String,
        response: ResponseDetail<void>(
          code: json['response']['code'] as String,
          data: null,
        ),
      );
    } catch (e) {
      await TokenService.clearTokens();
      return _networkError<void>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 회원가입 ================= */

  static Future<ApiResponse<JoinResponse>> join(
    JoinRequest request,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/user'),
        headers: await _getHeaders(includeAuth: false),
        body: jsonEncode(request.toJson()),
        encoding: utf8,
      );

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      return ApiResponse<JoinResponse>.fromJson(
        json,
        (data) => JoinResponse.fromJson(data),
      );
    } catch (e) {
      return _networkError<JoinResponse>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 이메일 중복 체크 ================= */

  static Future<ApiResponse<void>> checkEmail(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/user/email'),
        headers: await _getHeaders(includeAuth: false),
        body: jsonEncode({'email': email}),
        encoding: utf8,
      );

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      return ApiResponse<void>(
        code: json['code'] as int,
        message: json['message'] as String,
        response: ResponseDetail<void>(
          code: json['response']['code'] as String,
          data: null,
        ),
      );
    } catch (e) {
      return _networkError<void>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 냉장고 조회 ================= */

  static Future<ApiResponse<RefrigeratorResponse>> getRefrigerator() async {
    try {
      var response = await _client.get(
        Uri.parse('$baseUrl/api/refrigerator'),
        headers: await _getHeaders(),
      );

      var json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      var apiResponse = ApiResponse<RefrigeratorResponse>.fromJson(
        json,
        (data) {
          return RefrigeratorResponse.fromJson(data);
        },
      );

      // 인증 에러 처리
      final shouldRetry = await _handleAuthError(apiResponse);
      if (shouldRetry && (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
          apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await _client.get(
          Uri.parse('$baseUrl/api/refrigerator'),
          headers: await _getHeaders(),
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        apiResponse = ApiResponse<RefrigeratorResponse>.fromJson(
          json,
          (data) {
            print('🥕 response.data: $data');
            return RefrigeratorResponse.fromJson(data);
          },
        );
      }

      return apiResponse;
    } catch (e) {
      return _networkError<RefrigeratorResponse>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 재료 삭제 ================= */

  static Future<ApiResponse<void>> deleteIngredient(int ingredientId) async {
    try {
      var response = await _client.delete(
        Uri.parse('$baseUrl/api/refrigerator/ingredient/$ingredientId'),
        headers: await _getHeaders(),
      );

      var json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      var apiResponse = ApiResponse<void>(
        code: json['code'] as int,
        message: json['message'] as String,
        response: ResponseDetail<void>(
          code: json['response']['code'] as String,
          data: null,
        ),
      );

      // 인증 에러 처리
      final shouldRetry = await _handleAuthError(apiResponse);
      if (shouldRetry && (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
          apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await _client.delete(
          Uri.parse('$baseUrl/api/refrigerator/ingredient/$ingredientId'),
          headers: await _getHeaders(),
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        apiResponse = ApiResponse<void>(
          code: json['code'] as int,
          message: json['message'] as String,
          response: ResponseDetail<void>(
            code: json['response']['code'] as String,
            data: null,
          ),
        );
      }

      return apiResponse;
    } catch (e) {
      return _networkError<void>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 재료 검색 ================= */

  static Future<ApiResponse<List<IngredientResponse>>> findIngredientsByName(String name) async {
    try {
      var response = await _client.get(
        Uri.parse('$baseUrl/api/ingredients?name=$name'),
        headers: await _getHeaders(),
      );

      var json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      var responseJson = json['response'] as Map<String, dynamic>;
      
      List<IngredientResponse> ingredients = [];
      if (responseJson['data'] != null && responseJson['data'] is List) {
        ingredients = (responseJson['data'] as List<dynamic>)
            .map((item) => IngredientResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      var apiResponse = ApiResponse<List<IngredientResponse>>(
        code: json['code'] as int,
        message: json['message'] as String,
        response: ResponseDetail<List<IngredientResponse>>(
          code: responseJson['code'] as String,
          data: ingredients,
        ),
      );

      // 인증 에러 처리
      final shouldRetry = await _handleAuthError(apiResponse);
      if (shouldRetry && (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
          apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await _client.get(
          Uri.parse('$baseUrl/api/ingredients?name=$name'),
          headers: await _getHeaders(),
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        responseJson = json['response'] as Map<String, dynamic>;
        ingredients = [];
        if (responseJson['data'] != null && responseJson['data'] is List) {
          ingredients = (responseJson['data'] as List<dynamic>)
              .map((item) => IngredientResponse.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        apiResponse = ApiResponse<List<IngredientResponse>>(
          code: json['code'] as int,
          message: json['message'] as String,
          response: ResponseDetail<List<IngredientResponse>>(
            code: responseJson['code'] as String,
            data: ingredients,
          ),
        );
      }

      return apiResponse;
    } catch (e) {
      return _networkError<List<IngredientResponse>>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 냉장고에 재료 추가 ================= */

  static Future<ApiResponse<void>> addIngredientToRefrigerator(int ingredientId) async {
    try {
      var response = await _client.put(
        Uri.parse('$baseUrl/api/refrigerator/ingredient/$ingredientId'),
        headers: await _getHeaders(),
      );

      var json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      var apiResponse = ApiResponse<void>(
        code: json['code'] as int,
        message: json['message'] as String,
        response: ResponseDetail<void>(
          code: json['response']['code'] as String,
          data: null,
        ),
      );

      // 인증 에러 처리
      final shouldRetry = await _handleAuthError(apiResponse);
      if (shouldRetry && (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
          apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await _client.put(
          Uri.parse('$baseUrl/api/refrigerator/ingredient/$ingredientId'),
          headers: await _getHeaders(),
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        apiResponse = ApiResponse<void>(
          code: json['code'] as int,
          message: json['message'] as String,
          response: ResponseDetail<void>(
            code: json['response']['code'] as String,
            data: null,
          ),
        );
      }

      return apiResponse;
    } catch (e) {
      return _networkError<void>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 재료 생성 ================= */

  static Future<ApiResponse<IngredientResponse>> createIngredient(String category, String name) async {
    try {
      final body = jsonEncode({
        'category': category,
        'name': name,
      });

      var response = await _client.post(
        Uri.parse('$baseUrl/api/ingredients'),
        headers: await _getHeaders(),
        body: body,
        encoding: utf8,
      );

      var json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      var apiResponse = ApiResponse<IngredientResponse>.fromJson(
        json,
        (data) => IngredientResponse.fromJson(data),
      );

      // 인증 에러 처리
      final shouldRetry = await _handleAuthError(apiResponse);
      if (shouldRetry && (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
          apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await _client.post(
          Uri.parse('$baseUrl/api/ingredients'),
          headers: await _getHeaders(),
          body: body,
          encoding: utf8,
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        apiResponse = ApiResponse<IngredientResponse>.fromJson(
          json,
          (data) => IngredientResponse.fromJson(data),
        );
      }

      return apiResponse;
    } catch (e) {
      return _networkError<IngredientResponse>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 레시피 생성 ================= */

  static Future<ApiResponse<RecipesResponse>> createRecipes() async {
    try {
      var response = await _client.post(
        Uri.parse('$baseUrl/api/recipes'),
        headers: await _getHeaders(),
        encoding: utf8,
      );

      var json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      var apiResponse = ApiResponse<RecipesResponse>.fromJson(
        json,
        (data) => RecipesResponse.fromJson(data),
      );

      // 인증 에러 처리
      final shouldRetry = await _handleAuthError(apiResponse);
      if (shouldRetry && (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
          apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await _client.post(
          Uri.parse('$baseUrl/api/recipes'),
          headers: await _getHeaders(),
          encoding: utf8,
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        apiResponse = ApiResponse<RecipesResponse>.fromJson(
          json,
          (data) => RecipesResponse.fromJson(data),
        );
      }

      return apiResponse;
    } catch (e) {
      return _networkError<RecipesResponse>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 레시피 추천 ================= */

  static Future<ApiResponse<RecommendationsResponse>> getRecommendations() async {
    try {
      var response = await _client.post(
        Uri.parse('$baseUrl/api/recommendation'),
        headers: await _getHeaders(),
        encoding: utf8,
      );

      var json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      var apiResponse = ApiResponse<RecommendationsResponse>.fromJson(
        json,
        (data) => RecommendationsResponse.fromJson(data),
      );

      // 인증 에러 처리
      final shouldRetry = await _handleAuthError(apiResponse);
      if (shouldRetry && (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
          apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await _client.post(
          Uri.parse('$baseUrl/api/recommendation'),
          headers: await _getHeaders(),
          encoding: utf8,
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        apiResponse = ApiResponse<RecommendationsResponse>.fromJson(
          json,
          (data) => RecommendationsResponse.fromJson(data),
        );
      }

      return apiResponse;
    } catch (e) {
      return _networkError<RecommendationsResponse>('네트워크 오류가 발생했습니다.');
    }
  }
}