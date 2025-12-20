import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

import '../models/api_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/join_request.dart';
import '../models/join_response.dart';
import '../models/refrigerator_response.dart';
import '../models/ingredient_response.dart';
import 'token_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

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

      // accessToken만 클라이언트가 관리
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

  /* ================= 로그아웃 ================= */

  static Future<ApiResponse<void>> logout() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: await _getHeaders(),
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
      final response = await _client.get(
        Uri.parse('$baseUrl/api/refrigerator'),
        headers: await _getHeaders(),
      );

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      // return ApiResponse<RefrigeratorResponse>.fromJson(
      //   json,
      //   (data) => RefrigeratorResponse.fromJson(data),
      // );
        return ApiResponse<RefrigeratorResponse>.fromJson(
        json,
        (data) {
          print('🥕 response.data: $data');
          return RefrigeratorResponse.fromJson(data);
        },
      );
    } catch (e) {
      return _networkError<RefrigeratorResponse>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 재료 삭제 ================= */

  static Future<ApiResponse<void>> deleteIngredient(int ingredientId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/refrigerator/ingredient/$ingredientId'),
        headers: await _getHeaders(),
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

  /* ================= 재료 검색 ================= */

  static Future<ApiResponse<List<IngredientResponse>>> findIngredientsByName(String name) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/ingredients?name=$name'),
        headers: await _getHeaders(),
      );

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final responseJson = json['response'] as Map<String, dynamic>;
      
      List<IngredientResponse> ingredients = [];
      if (responseJson['data'] != null && responseJson['data'] is List) {
        ingredients = (responseJson['data'] as List<dynamic>)
            .map((item) => IngredientResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return ApiResponse<List<IngredientResponse>>(
        code: json['code'] as int,
        message: json['message'] as String,
        response: ResponseDetail<List<IngredientResponse>>(
          code: responseJson['code'] as String,
          data: ingredients,
        ),
      );
    } catch (e) {
      return _networkError<List<IngredientResponse>>('네트워크 오류가 발생했습니다.');
    }
  }

  /* ================= 냉장고에 재료 추가 ================= */

  static Future<ApiResponse<void>> addIngredientToRefrigerator(int ingredientId) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/api/refrigerator/ingredient/$ingredientId'),
        headers: await _getHeaders(),
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

  /* ================= 재료 생성 ================= */

  static Future<ApiResponse<IngredientResponse>> createIngredient(String category, String name) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/ingredients'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'category': category,
          'name': name,
        }),
        encoding: utf8,
      );

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      return ApiResponse<IngredientResponse>.fromJson(
        json,
        (data) => IngredientResponse.fromJson(data),
      );
    } catch (e) {
      return _networkError<IngredientResponse>('네트워크 오류가 발생했습니다.');
    }
  }
}