import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/admin_user_response.dart';
import '../models/role.dart';
import 'api_client.dart';
import 'token_service.dart';
import '../utils/api_response_parser.dart';

/// 관리자 관련 API 서비스
class AdminService {
  /// 모든 사용자 조회
  static Future<ApiResponse<List<AdminUserResponse>>> getAllUsers() async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/api/admin/users',
        (data) => data,
      );

      return ApiResponseParser.parseListResponse<AdminUserResponse>(
        response: response,
        fromJson: (data) => AdminUserResponse.fromJson(data),
      );
    } catch (e) {
      return ApiClient.networkError<List<AdminUserResponse>>('네트워크 오류가 발생했습니다.');
    }
  }

  /// 사용자 권한 변경
  static Future<ApiResponse<AdminUserResponse>> updateUserRole(
    int userId,
    Role role,
  ) async {
    return await ApiClient.put<AdminUserResponse>(
      '/api/admin/role',
      (data) => AdminUserResponse.fromJson(data),
      body: {
        'id': userId,
        'role': role.toJson(),
      },
    );
  }

  /// 동영상 업로드
  static Future<ApiResponse<void>> uploadVideo(dynamic fileData, String fileName) async {
    try {
      final token = await TokenService.getAccessToken();
      final headers = await ApiClient.getHeaders();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}/api/videos/video'),
      );

      request.headers.addAll(headers);
      
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileData as List<int>,
            filename: fileName,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            (fileData as File).path,
            filename: fileName,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      var json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      var apiResponse = ApiResponse<void>(
        code: json['code'] as int,
        message: json['message'] as String,
        response: ResponseDetail<void>(
          code: json['response']['code'] as String,
          data: null,
        ),
      );

      // 인증 에러 처리
      final shouldRetry = await ApiClient.handleAuthError(apiResponse);
      if (shouldRetry && 
          (apiResponse.response.code == 'AUTH_EXPIRED_TOKEN' || 
           apiResponse.response.code == 'AUTH_NOT_EXIST_TOKEN')) {
        // 재시도
        final newToken = await TokenService.getAccessToken();
        final newHeaders = await ApiClient.getHeaders();
        
        request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiClient.baseUrl}/api/videos/video'),
        );
        request.headers.addAll(newHeaders);
        
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              fileData as List<int>,
              filename: fileName,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              (fileData as File).path,
              filename: fileName,
            ),
          );
        }

        streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
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
      return ApiClient.networkError<void>('네트워크 오류가 발생했습니다.');
    }
  }
}
