import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/ingredient_response.dart';
import '../../models/ingredient_category.dart';

class MyPageController extends ChangeNotifier {
    // 언더바 변수 : 클래스 내부에서만 수정가능한 변수
  List<IngredientResponse> _ingredients = [];
  bool _isLoading = false;
  int _currentCategoryIndex = 0;
  final List<String> _categories = IngredientCategory.values;

  // Getter들 (UI에서 데이를 읽어갈 수 있는 통로)
  List<IngredientResponse> get ingredients => _ingredients;
  bool get isLoading => _isLoading;
  int get currentCategoryIndex => _currentCategoryIndex;
  String get currentCategory => _categories[_currentCategoryIndex];

  // 현재 카테고리에 맞는 재료 필터링 로직
  //전체 재료(_ingredients) 중에서 현재 선택된 카테고리에 해당하는 재료만 쏙쏙 골라내는 필터 역할
  //where 함수를 사용하여 조건에 맞는 데이터만 리스트로 다시 만듬
  List<IngredientResponse> get currentCategoryIngredients {
    return _ingredients
        .where((item) => item.category == currentCategory)
        .toList();
  }

  // 1. 데이터 로드 로직
  Future<void> loadRefrigerator() async {
    _isLoading = true;
    notifyListeners(); // 상태 변경 알림 (화면 새로고침)

    try {
      final response = await ApiService.getRefrigerator();
      if (response.code == 200 && response.response.data != null) {
        _ingredients = response.response.data!.myRefrigerator;
      } else {
        _ingredients = [];
      }
    } catch (e) {
      _ingredients = [];
      debugPrint('냉장고 조회 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. 삭제 로직
  Future<bool> deleteIngredient(int id) async {
    try {
      final response = await ApiService.deleteIngredient(id);
      if (response.code == 200) {
        _ingredients.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('삭제 오류: $e');
    }
    return false;
  }

  // 3. 카테고리 이동 로직
  void nextCategory() {
    _currentCategoryIndex = (_currentCategoryIndex + 1) % _categories.length;
    notifyListeners();
  }

  void previousCategory() {
    _currentCategoryIndex = (_currentCategoryIndex - 1 + _categories.length) % _categories.length;
    notifyListeners();
  }
}