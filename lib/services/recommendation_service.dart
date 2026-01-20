import '../models/api_response.dart';
import '../models/recommendations_response.dart';
import 'api_client.dart';

/// 레시피 추천 관련 API 서비스
class RecommendationService {
  /// 레시피 추천 받기
  static Future<ApiResponse<RecommendationsResponse>> getRecommendations() async {
    return await ApiClient.post<RecommendationsResponse>(
      '/api/recommendation',
      (data) => RecommendationsResponse.fromJson(data),
    );
  }
}
