import '../models/api_response.dart';
import '../models/recipes_response.dart';
import 'api_client.dart';

/// 레시피 관련 API 서비스
class RecipeService {
  /// 레시피 생성
  static Future<ApiResponse<RecipesResponse>> createRecipes() async {
    return await ApiClient.post<RecipesResponse>(
      '/api/recipes',
      (data) => RecipesResponse.fromJson(data),
    );
  }
}
