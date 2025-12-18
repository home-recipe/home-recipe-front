class ApiResponse<T> {
  final int code;
  final String message;
  final ResponseDetail<T?> response;

  ApiResponse({
    required this.code,
    required this.message,
    required this.response
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final responseJson = json['response'] as Map<String, dynamic>;

    return ApiResponse<T>(
      code: json['code'],
      message: json['message'],
      response: ResponseDetail<T?>(
        code: responseJson['code'],
        data: responseJson['data'] != null 
          ? fromJsonT(responseJson['data']) 
          : null
      ),
    );
  }
}




