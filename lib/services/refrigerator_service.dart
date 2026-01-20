import 'dart:convert';
import '../models/api_response.dart';
import '../models/refrigerator_response.dart';
import '../models/ingredient_response.dart';
import '../models/open_api_ingredient_response.dart';
import 'api_client.dart';
import '../utils/api_response_parser.dart';

/// 냉장고 관련 API 서비스
class RefrigeratorService {
  /// 냉장고 조회
  static Future<ApiResponse<RefrigeratorResponse>> getRefrigerator() async {
    return await ApiClient.get<RefrigeratorResponse>(
      '/api/refrigerator',
      (data) => RefrigeratorResponse.fromJson(data),
    );
  }

  /// 재료 삭제
  static Future<ApiResponse<void>> deleteIngredient(int ingredientId) async {
    return await ApiClient.delete<void>(
      '/api/refrigerator/ingredient/$ingredientId',
      null, // void 타입이므로 fromJson은 null
    );
  }

  /// 재료 추가
  static Future<ApiResponse<void>> addIngredientToRefrigerator(int ingredientId) async {
    try {
      final client = ApiClient.client;
      var response = await client.put(
        Uri.parse('${ApiClient.baseUrl}/api/refrigerator/ingredient/$ingredientId'),
        headers: await ApiClient.getHeaders(),
        encoding: utf8,
      );

      var json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      
      // 응답 구조: { "code": 200, "message": "...", "response": { "code": "...", "data": true } }
      final responseJson = json['response'] as Map<String, dynamic>;
      
      var apiResponse = ApiResponse<void>(
        code: json['code'] as int,
        message: json['message'] as String,
        response: ResponseDetail<void>(
          code: responseJson['code'] as String,
          data: null,
        ),
      );

      // 인증 에러 처리
      final shouldRetry = await ApiClient.handleAuthError(apiResponse);
      if (shouldRetry && 
          (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
           apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await client.put(
          Uri.parse('${ApiClient.baseUrl}/api/refrigerator/ingredient/$ingredientId'),
          headers: await ApiClient.getHeaders(),
          encoding: utf8,
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final retryResponseJson = json['response'] as Map<String, dynamic>;
        apiResponse = ApiResponse<void>(
          code: json['code'] as int,
          message: json['message'] as String,
          response: ResponseDetail<void>(
            code: retryResponseJson['code'] as String,
            data: null,
          ),
        );
      }

      return apiResponse;
    } catch (e) {
      return ApiClient.networkError<void>('네트워크 오류가 발생했습니다.');
    }
  }

  /// Open API에서 재료 검색
  static Future<ApiResponse<List<OpenApiIngredientResponse>>> findIngredientsFromOpenApi(
    String name,
  ) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/api/ingredients/external?name=${Uri.encodeComponent(name)}',
        (data) => data,
      );

      return ApiResponseParser.parseListResponse<OpenApiIngredientResponse>(
        response: response,
        fromJson: (data) => OpenApiIngredientResponse.fromJson(data),
      );
    } catch (e) {
      return ApiClient.networkError<List<OpenApiIngredientResponse>>('네트워크 오류가 발생했습니다.');
    }
  }

  /// 내부 DB에서 재료 검색
  static Future<ApiResponse<List<IngredientResponse>>> findIngredientsByName(String name) async {
    try {
      final client = ApiClient.client;
      var response = await client.get(
        Uri.parse('${ApiClient.baseUrl}/api/ingredients?name=${Uri.encodeComponent(name)}'),
        headers: await ApiClient.getHeaders(),
      );

      var json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      
      // 응답 구조: { "code": 200, "message": "...", "response": { "code": "...", "data": [...] } }
      final responseJson = json['response'] as Map<String, dynamic>;
      final dataList = responseJson['data'] as List<dynamic>?;
      
      List<IngredientResponse> ingredients = [];
      if (dataList != null) {
        ingredients = dataList
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
      final shouldRetry = await ApiClient.handleAuthError(apiResponse);
      if (shouldRetry && 
          (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
           apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        response = await client.get(
          Uri.parse('${ApiClient.baseUrl}/api/ingredients?name=${Uri.encodeComponent(name)}'),
          headers: await ApiClient.getHeaders(),
        );
        json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final retryResponseJson = json['response'] as Map<String, dynamic>;
        final retryDataList = retryResponseJson['data'] as List<dynamic>?;
        
        ingredients = [];
        if (retryDataList != null) {
          ingredients = retryDataList
              .map((item) => IngredientResponse.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        apiResponse = ApiResponse<List<IngredientResponse>>(
          code: json['code'] as int,
          message: json['message'] as String,
          response: ResponseDetail<List<IngredientResponse>>(
            code: retryResponseJson['code'] as String,
            data: ingredients,
          ),
        );
      }

      return apiResponse;
    } catch (e) {
      return ApiClient.networkError<List<IngredientResponse>>('네트워크 오류가 발생했습니다.');
    }
  }

  /// 재료 생성
  static Future<ApiResponse<IngredientResponse>> createIngredient(
    String category,
    String name,
  ) async {
    return await ApiClient.post<IngredientResponse>(
      '/api/ingredients',
      (data) => IngredientResponse.fromJson(data),
      body: {
        'category': category,
        'name': name,
      },
    );
  }
}
