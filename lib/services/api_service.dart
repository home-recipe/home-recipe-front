import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/join_request.dart';
import '../models/join_response.dart';
import '../models/api_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import 'token_service.dart';

class ApiService {
  // TODO: 실제 백엔드 URL로 변경 필요
  static const String baseUrl = 'http://localhost:8080'; // 또는 실제 백엔드 URL

  // 공통 헤더 생성 (Authorization 포함)
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };

    if (includeAuth) {
      final accessToken = await TokenService.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      } else {
        // 디버깅: 토큰이 없을 때 로그 출력
        print('Warning: AccessToken이 없어 Authorization 헤더를 추가할 수 없습니다.');
      }
    }

    return headers;
  }

  // code 필드 파싱 헬퍼
  static String? _parseCode(dynamic codeValue) {
    if (codeValue == null) return null;
    if (codeValue is String) return codeValue;
    if (codeValue is int) return codeValue.toString();
    return codeValue.toString();
  }

  // 로그인
  static Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');
      final headers = await _getHeaders(includeAuth: false);
      final response = await http.post(
        url,
        headers: headers,
        encoding: utf8,
        body: jsonEncode(request.toJson()),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final response = responseData['response'] as Map<String, dynamic>?;
        final data = response?['data'] as Map<String, dynamic>?;
        
        if (data != null) {
          try {
            final loginResponse = LoginResponse.fromJson(data);
            // AccessToken을 로컬스토리지에 저장
            if (loginResponse.accessToken.isNotEmpty) {
              await TokenService.saveAccessToken(loginResponse.accessToken);
            }
            // refreshToken은 백엔드에서 Set-Cookie 헤더로 설정되므로 자동으로 저장됨
            
            final apiResponse = ApiResponse<LoginResponse>.fromJson(
              responseData,
              (json) => LoginResponse.fromJson(json),
            );  
            return apiResponse;
          } catch (e) {
            // JSON 파싱 오류
            return ApiResponse<LoginResponse>(
              success: false,
              message: '응답 데이터 파싱 오류: ${e.toString()}'
            );
          }
        } else {
          // data가 null이거나 success가 false인 경우
          return ApiResponse<LoginResponse>(
            success: false,
            message: responseData['message'] as String?,
            code: responseData['code'] as int?
          );
        }
      }

      // 에러 응답
      final errorMessage = responseData['message'] as String?;
      return ApiResponse<LoginResponse>(
        success: false,
        message: errorMessage ?? '로그인에 실패했습니다',
        code: responseData['code'] as int?
      );
    } catch (e) {
      return ApiResponse<LoginResponse>(
        success: false,
        message: '네트워크 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 로그아웃
  static Future<ApiResponse<void>> logout() async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/logout');
      final headers = await _getHeaders(includeAuth: true);
      
      // 디버깅: 헤더 확인
      print('Logout request headers: $headers');
      
      final response = await http.post(
        url,
        headers: headers,
        encoding: utf8,
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // 성공 응답
        final isSuccess = responseData['success'] as bool? ?? true;
        
        // 로그아웃 성공 시 토큰 삭제
        if (isSuccess) {
          await TokenService.clearTokens();
        }
        
        return ApiResponse<void>(
          success: isSuccess,
          message: responseData['message'] as String?,
          code: _parseCode(responseData['code']),
          statusCode: response.statusCode,
        );
      } else {
        // 에러 응답
        final errorMessage = responseData['message'] as String?;
        return ApiResponse<void>(
          success: false,
          message: errorMessage ?? '로그아웃에 실패했습니다',
          code: _parseCode(responseData['code']),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // 네트워크 에러 등 - 에러가 발생해도 토큰은 삭제
      await TokenService.clearTokens();
      return ApiResponse<void>(
        success: false,
        message: '네트워크 오류가 발생했습니다: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<JoinResponse>> join(JoinRequest request) async {
    try {
      final url = Uri.parse('$baseUrl/api/user');
      final headers = await _getHeaders(includeAuth: false);
      final response = await http.post(
        url,
        headers: headers,
        encoding: utf8,
        body: jsonEncode(request.toJson()),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        // 성공 응답
        final data = responseData['data'] as Map<String, dynamic>?;
        // 백엔드 응답의 success 필드 확인, 없으면 상태 코드로 판단
        final isSuccess = responseData['success'] as bool? ?? true;
        return ApiResponse<JoinResponse>(
          success: isSuccess,
          data: data != null ? JoinResponse.fromJson(data) : null,
          message: responseData['message'] as String?,
          code: _parseCode(responseData['code']),
          statusCode: response.statusCode,
        );
      } else {
        // 에러 응답
        final errorMessage = responseData['message'] as String?;
        
        // 백엔드 에러 메시지 파싱
        String displayMessage = '회원가입에 실패했습니다';
        if (errorMessage != null) {
          displayMessage = errorMessage;
        } else if (responseData['errors'] != null) {
          // validation 에러 처리
          final errors = responseData['errors'] as List<dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            displayMessage = errors.first.toString();
          }
        }
        
        return ApiResponse<JoinResponse>(
          success: false,
          message: displayMessage,
          code: _parseCode(responseData['code']),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // 네트워크 에러 등
      return ApiResponse<JoinResponse>(
        success: false,
        message: '네트워크 오류가 발생했습니다: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<void>> checkEmail(String email) async {
    try {
      final url = Uri.parse('$baseUrl/api/user/email');
      final headers = await _getHeaders(includeAuth: false);
      final response = await http.post(
        url,
        headers: headers,
        encoding: utf8,
        body: jsonEncode({'email': email}),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // 성공 응답 (이메일 사용 가능)
        return ApiResponse<void>(
          success: true,
          message: responseData['message'] as String?,
          code: _parseCode(responseData['code']),
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 409) {
        // 409: 이메일 중복
        final errorMessage = responseData['message'] as String?;
        
        return ApiResponse<void>(
          success: false,
          message: errorMessage ?? '이미 가입된 이메일입니다.',
          code: _parseCode(responseData['code']),
          statusCode: response.statusCode,
        );
      } else {
        // 기타 에러 응답
        final errorMessage = responseData['message'] as String?;
        
        return ApiResponse<void>(
          success: false,
          message: errorMessage ?? '오류가 발생했습니다',
          code: _parseCode(responseData['code']),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // 네트워크 에러 등
      return ApiResponse<void>(
        success: false,
        message: '네트워크 오류가 발생했습니다: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

