import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/access_token_response.dart';
import '../models/join_request.dart';
import '../models/join_response.dart';
import '../models/user_response.dart';
import '../models/refrigerator_response.dart';
import '../models/ingredient_response.dart';
import '../models/open_api_ingredient_response.dart';
import '../models/recipes_response.dart';
import '../models/recommendations_response.dart';
import '../models/admin_user_response.dart';
import '../models/role.dart';
import 'auth_service.dart';
import 'refrigerator_service.dart';
import 'recipe_service.dart';
import 'recommendation_service.dart';
import 'admin_service.dart';
import 'api_client.dart';

/// API 서비스 통합 클래스
/// 
/// 이 클래스는 하위 서비스들을 통합하여 제공합니다.
/// 각 기능별 서비스를 직접 사용하는 것을 권장합니다:
/// - AuthService: 인증 관련
/// - RefrigeratorService: 냉장고 관련
/// - RecipeService: 레시피 관련
/// - RecommendationService: 추천 관련
/// - AdminService: 관리자 관련

/// 기존 코드와의 호환성을 위한 ApiService 클래스
/// 
/// @deprecated 각 기능별 서비스를 직접 사용하세요.
/// 예: AuthService.login() 대신 ApiService.login() 사용 가능
class ApiService {
  // AuthService 메서드들
  static Future<ApiResponse<LoginResponse>> login(LoginRequest request) =>
      AuthService.login(request);
  
  static Future<ApiResponse<void>> logout() => AuthService.logout();
  
  static Future<ApiResponse<JoinResponse>> join(JoinRequest request) =>
      AuthService.join(request);
  
  static Future<ApiResponse<UserResponse>> getCurrentUser() =>
      AuthService.getCurrentUser();
  
  static Future<ApiResponse<void>> checkEmail(String email) =>
      AuthService.checkEmail(email);
  
  static Future<ApiResponse<AccessTokenResponse>> refreshToken() =>
      AuthService.refreshToken();

  // RefrigeratorService 메서드들
  static Future<ApiResponse<RefrigeratorResponse>> getRefrigerator() =>
      RefrigeratorService.getRefrigerator();
  
  static Future<ApiResponse<void>> deleteIngredient(int ingredientId) =>
      RefrigeratorService.deleteIngredient(ingredientId);
  
  static Future<ApiResponse<void>> addIngredientToRefrigerator(int ingredientId) =>
      RefrigeratorService.addIngredientToRefrigerator(ingredientId);
  
  static Future<ApiResponse<List<OpenApiIngredientResponse>>> findIngredientsFromOpenApi(String name) =>
      RefrigeratorService.findIngredientsFromOpenApi(name);
  
  static Future<ApiResponse<List<IngredientResponse>>> findIngredientsByName(String name) =>
      RefrigeratorService.findIngredientsByName(name);
  
  static Future<ApiResponse<IngredientResponse>> createIngredient(String category, String name) =>
      RefrigeratorService.createIngredient(category, name);

  // RecipeService 메서드들
  static Future<ApiResponse<RecipesResponse>> createRecipes() =>
      RecipeService.createRecipes();

  // RecommendationService 메서드들
  static Future<ApiResponse<RecommendationsResponse>> getRecommendations() =>
      RecommendationService.getRecommendations();

  // AdminService 메서드들
  static Future<ApiResponse<List<AdminUserResponse>>> getAllUsers() =>
      AdminService.getAllUsers();
  
  static Future<ApiResponse<AdminUserResponse>> updateUserRole(int userId, Role role) =>
      AdminService.updateUserRole(userId, role);
  
  static Future<ApiResponse<void>> uploadVideo(dynamic fileData, String fileName) =>
      AdminService.uploadVideo(fileData, fileName);

  // ApiClient의 navigatorKey 접근
  static GlobalKey<NavigatorState> get navigatorKey => ApiClient.navigatorKey;
}
