/// API 공통 응답
class ApiResponse<T> {
  final int code;                
  final String message;          
  final ResponseDetail<T?> response;

  ApiResponse({
    required this.code,
    required this.message,
    required this.response,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final responseJson = json['response'] as Map<String, dynamic>;

    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String,
      response: ResponseDetail<T?>(
        code: responseJson['code'] as String,
        data: responseJson['data'] != null
            ? fromJsonT(responseJson['data'] as Map<String, dynamic>)
            : null,
      ),
    );
  }
}

class ResponseDetail<T> {
  final String code;   
  final T? data;

  ResponseDetail({
    required this.code,
    this.data,
  });
}


