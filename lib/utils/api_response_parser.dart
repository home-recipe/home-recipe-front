import '../models/api_response.dart';

/// API 응답 파싱 유틸리티
class ApiResponseParser {
  /// 리스트 타입 응답 파싱 (응답 구조가 다른 경우)
  /// 
  /// ApiClient.get이 반환하는 ApiResponse<Map<String, dynamic>>에서
  /// 실제 리스트 데이터를 추출합니다.
  /// 
  /// 응답 구조:
  /// {
  ///   "code": 200,
  ///   "message": "...",
  ///   "response": {
  ///     "code": "...",
  ///     "data": [...]  <- 여기서 리스트 추출
  ///   }
  /// }
  static ApiResponse<List<T>> parseListResponse<T>({
    required ApiResponse<Map<String, dynamic>> response,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    if (response.code == 200 && response.response.data != null) {
      // response.response.data는 이미 최종 응답 데이터
      // 구조: { "code": "...", "data": [...] }
      final responseData = response.response.data!;
      
      List<T> items = [];
      if (responseData['data'] != null && responseData['data'] is List) {
        items = (responseData['data'] as List<dynamic>)
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return ApiResponse<List<T>>(
        code: response.code,
        message: response.message,
        response: ResponseDetail<List<T>>(
          code: responseData['code'] as String? ?? response.response.code,
          data: items,
        ),
      );
    }

    return ApiResponse<List<T>>(
      code: response.code,
      message: response.message,
      response: ResponseDetail<List<T>>(
        code: response.response.code,
        data: [],
      ),
    );
  }
}
