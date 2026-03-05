import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../models/ingredient_category.dart';
import '../models/ingredient_response.dart';
import 'my_page/my_page_controller.dart';
import '../constants/app_colors.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => MyPageState();
}

class MyPageState extends State<MyPage> {
  final MyPageController _controller = MyPageController();

  // 사용자 role
  String? _userRole;
  bool _isCheckingRole = false;
  
  Future<void> _loadRefrigerator() async {
    await _controller.loadRefrigerator();
  }

  List<IngredientResponse> get _currentCategoryIngredients => _controller.currentCategoryIngredients;
  
  @override
  void initState() {
    super.initState();

    _controller.loadRefrigerator();
    //컨트롤러의 상태가 바뀔때마다 화면을 다시 그리도록 설정
    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    // 사용자 role 확인
    _checkUserRole();
  }
  
  Future<void> _checkUserRole() async {
    setState(() {
      _isCheckingRole = true;
    });
    
    // 저장된 role 확인
    final role = await TokenService.getUserRole();
    
    if (role != null) {
      setState(() {
        _userRole = role;
        _isCheckingRole = false;
      });
    } else {
      // role이 없으면 API로 사용자 정보 조회
      try {
        final response = await ApiService.getCurrentUser();
        if (response.code == 200 && response.response.data != null) {
          setState(() {
            _userRole = response.response.data!.role;
            _isCheckingRole = false;
          });
        } else {
          setState(() {
            _isCheckingRole = false;
          });
        }
      } catch (e) {
        setState(() {
          _isCheckingRole = false;
        });
      }
    }
  }
  
  bool get _isAdmin => _userRole == 'ADMIN';

  @override
  void dispose() {
    _controller.dispose(); // 메모리 해제
    super.dispose();
  }
  
  // 외부에서 호출하던 refreshData도 간단해짐
  void refreshData() => _controller.loadRefrigerator();

  // 재료 추가 다이얼로그
  Future<void> _showAddIngredientDialog(BuildContext context) async {
    final TextEditingController searchController = TextEditingController();
    List<IngredientResponse> searchResults = [];
    bool isSearching = false;
    bool hasSearched = false; // 검색을 한 번이라도 했는지 여부
    Set<int> selectedIngredientIds = {}; // 선택된 재료 ID들
    Set<int> existingIngredientIds = {}; // 이미 냉장고에 있는 재료 ID들

    // 현재 냉장고에 있는 재료 ID 목록 가져오기
    try {
      final refrigeratorResponse = await ApiService.getRefrigerator();
      if (refrigeratorResponse.code == 200 && 
          refrigeratorResponse.response.data != null) {
        existingIngredientIds = refrigeratorResponse.response.data!.myRefrigerator
            .where((ingredient) => ingredient.id != null)
            .map((ingredient) => ingredient.id!)
            .toSet();
      }
    } catch (e) {
      debugPrint('냉장고 조회 오류: $e');
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🥬',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '재료 추가',
                    style: TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                      letterSpacing: 0.5,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 500,
                  minWidth: 0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 재료 검색 입력 필드
                      TextField(
                        controller: searchController,
                        style: const TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '재료 이름을 입력하세요',
                          hintStyle: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  color: Colors.grey.shade400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryGreen,
                              width: 2.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (value) async {
                          if (value.trim().isEmpty) return;
                          setState(() {
                            isSearching = true;
                            selectedIngredientIds.clear(); // 새 검색 시 선택 상태 초기화
                          });
                          await _searchIngredients(context, value.trim(), setState, (results) {
                            setState(() {
                              searchResults = results;
                              isSearching = false;
                              hasSearched = true;
                            });
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // 조회 버튼
                      ElevatedButton(
                        onPressed: isSearching
                            ? null
                            : () async {
                                if (searchController.text.trim().isEmpty) return;
                                setState(() {
                                  isSearching = true;
                                  selectedIngredientIds.clear(); // 새 검색 시 선택 상태 초기화
                                });
                                await _searchIngredients(
                                  context,
                                  searchController.text.trim(),
                                  setState,
                                  (results) {
                                    setState(() {
                                      searchResults = results;
                                      isSearching = false;
                                      hasSearched = true;
                                    });
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: isSearching
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '조회',
                                style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // 검색 결과 영역
                      if (hasSearched)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (searchResults.isNotEmpty) ...[
                                  // 검색 결과 헤더
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        size: 18,
                                        color: AppColors.primaryGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${searchResults.length}개의 재료를 찾았어요',
                                        style: const TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // 검색 결과 목록
                                  ...searchResults.map((ingredient) {
                                    final isSelected = ingredient.id != null && selectedIngredientIds.contains(ingredient.id);
                                    final isDatabase = ingredient.source == Source.DATABASE;
                                    final isExisting = ingredient.id != null && existingIngredientIds.contains(ingredient.id);
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: isExisting
                                            ? Colors.grey.shade50
                                            : (isSelected 
                                                ? AppColors.primaryGreen.withOpacity(0.1)
                                            : Colors.white),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isExisting
                                              ? Colors.grey.shade300
                                              : (isSelected
                                                  ? AppColors.primaryGreen
                                                  : AppColors.primaryGreen.withOpacity(0.3)),
                                          width: isSelected ? 2 : 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: isExisting
                                              ? null // 이미 있는 재료는 클릭 불가
                                              : () {
                                                  if (isDatabase && ingredient.id != null) {
                                                    // DATABASE 재료는 선택/해제만
                                                    setState(() {
                                                      if (isSelected) {
                                                        selectedIngredientIds.remove(ingredient.id);
                                                      } else {
                                                        selectedIngredientIds.add(ingredient.id!);
                                                      }
                                                    });
                                                  } else {
                                                    // OPEN_API 재료는 기존처럼 바로 추가 확인 다이얼로그
                                                    Navigator.pop(context);
                                                    _showAddConfirmDialog(context, ingredient);
                                                  }
                                                },
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            child: Row(
                                              children: [
                                                // DATABASE 재료는 체크박스, OPEN_API 재료는 아이콘
                                                if (isDatabase) ...[
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isExisting
                                                            ? Colors.grey.shade300
                                                            : (isSelected
                                                                ? AppColors.primaryGreen
                                                                : Colors.grey.shade400),
                                                        width: 2,
                                                      ),
                                                      color: isExisting
                                                          ? Colors.grey.shade200
                                                          : (isSelected
                                                              ? AppColors.primaryGreen
                                                              : Colors.transparent),
                                                    ),
                                                    child: isSelected && !isExisting
                                                        ? const Icon(
                                                            Icons.check,
                                                            size: 16,
                                                            color: Colors.white,
                                                          )
                                                        : (isExisting
                                                            ? const Icon(
                                                                Icons.block,
                                                                size: 16,
                                                                color: Colors.grey,
                                                              )
                                                            : null),
                                                  ),
                                                ] else ...[
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: isExisting
                                                          ? Colors.grey.shade200
                                                          : AppColors.primaryGreen.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      isExisting ? Icons.block : Icons.restaurant,
                                                      size: 20,
                                                      color: isExisting
                                                          ? Colors.grey
                                                          : AppColors.primaryGreen,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        ingredient.name,
                                                        style: TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          fontSize: 15,
                                                            fontWeight: FontWeight.w600,
                                                            color: isExisting
                                                                ? Colors.grey.shade600
                                                                : AppColors.textDark,
                                                        ),
                                                      ),
                                                      if (isExisting) ...[
                                                        const SizedBox(height: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey.shade200,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Text(
                                                            '이미 저장된 재료',
                                                            style: TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          fontSize: 11,
                                                              color: Colors.grey,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                if (isDatabase)
                                                  const SizedBox(width: 8)
                                                else if (!isExisting)
                                                  const Icon(
                                                    Icons.chevron_right,
                                                    size: 20,
                                                    color: AppColors.primaryGreen,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ] else ...[
                                  // 검색 결과 없음
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          '검색 결과가 없어요',
                                          style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '다른 검색어로 시도해보세요',
                                          style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                // 저장 버튼 (선택된 재료가 있을 때만 활성화)
                if (selectedIngredientIds.isNotEmpty)
                  ElevatedButton(
                    onPressed: () async {
                      // 선택된 재료들 중 DATABASE source이고 이미 존재하지 않는 것만 필터링
                      final selectedIngredients = searchResults
                          .where((ingredient) => 
                              ingredient.id != null &&
                              selectedIngredientIds.contains(ingredient.id) &&
                              ingredient.source == Source.DATABASE &&
                              !existingIngredientIds.contains(ingredient.id)) // 이미 있는 재료 제외
                          .toList();
                      
                      if (selectedIngredients.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              '저장할 재료를 선택해주세요',
                              style: TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                                letterSpacing: 0.5,
                                fontSize: 14,
                              ),
                            ),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        return;
                      }
                      
                      // 확인 다이얼로그 표시
                      final confirmed = await _showSaveMultipleIngredientsDialog(context, selectedIngredients);
                      if (!confirmed) {
                        return; // 취소하면 저장하지 않음
                      }
                      
                      // 선택된 재료들을 한 번에 추가
                      int successCount = 0;
                      int failCount = 0;
                      
                      for (final ingredient in selectedIngredients) {
                        if (ingredient.id == null) {
                          failCount++;
                          continue;
                        }
                        try {
                          final response = await ApiService.addIngredientToRefrigerator(ingredient.id!);
                          if (response.code == 200) {
                            successCount++;
                            // 성공한 재료는 existingIngredientIds에 추가하여 중복 방지
                            existingIngredientIds.add(ingredient.id!);
                          } else {
                            failCount++;
                          }
                        } catch (e) {
                          failCount++;
                        }
                      }
                      
                      // 냉장고 목록 새로고침
                      await _loadRefrigerator();
                      
                      // 첫 번째 성공한 재료의 카테고리로 이동
                      if (successCount > 0 && selectedIngredients.isNotEmpty) {
                        final firstIngredient = selectedIngredients.first;
                        if (firstIngredient.category != null) {
                          final categoryIndex = IngredientCategory.values.indexOf(firstIngredient.category!);
                          if (categoryIndex != -1) {
                            _controller.selectCategory(categoryIndex);
                          }
                        }
                      }
                      
                      if (!context.mounted) return;
                      
                      // 결과 메시지 표시
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            failCount > 0
                                ? '$successCount개 재료가 추가되었습니다. ($failCount개 실패)'
                                : '$successCount개 재료가 추가되었습니다!',
                            style: const TextStyle(
                              fontFamily: 'NanumGothicCoding-Regular',
                              letterSpacing: 0.5,
                              fontSize: 14,
                            ),
                          ),
                          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      '저장 (${selectedIngredientIds.length})',
                      style: const TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: const Text(
                    '닫기',
                    style: TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                      letterSpacing: 0.5,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 재료 검색
  Future<void> _searchIngredients(
    BuildContext context,
    String name,
    StateSetter setState,
    Function(List<IngredientResponse>) onResult,
  ) async {
    try {
      // /api/ingredients GET 요청에 name 파라미터로 통일된 요청
      final response = await ApiService.findIngredientsByName(name);

      if (!context.mounted) return;

      if (response.code == 200 && 
          response.response.data != null &&
          response.response.data!.isNotEmpty) {
        setState(() {
          onResult(response.response.data!);
        });
      } else {
        setState(() {
          onResult([]);
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.code == -1 
                    ? '네트워크 오류가 발생했습니다' 
                    : (response.response.data == null || response.response.data!.isEmpty
                        ? '검색 결과가 없어요'
                        : response.message),
                style: const TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      setState(() {
        onResult([]);
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '재료 검색 중 오류가 발생했습니다: $e',
              style: const TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 여러 재료 저장 확인 다이얼로그
  Future<bool> _showSaveMultipleIngredientsDialog(
    BuildContext context,
    List<IngredientResponse> ingredients,
  ) async {
    final ingredientNames = ingredients.map((e) => e.name).join(', ');
    
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '💾',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '재료 저장',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Text(
            '[$ingredientNames] 재료를 저장하시겠어요?',
            style: const TextStyle(
              fontFamily: 'NanumGothicCoding-Regular',
              letterSpacing: 0.5,
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ) ?? false;
  }

  // 재료 추가 확인 다이얼로그
  Future<void> _showAddConfirmDialog(BuildContext context, IngredientResponse ingredient) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '➕',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '재료 추가',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Text(
            '${ingredient.name} 냉장고에 추가하시겠어요?',
            style: const TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addIngredientToRefrigerator(context, ingredient);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 카테고리 선택 팝업 (OPEN_API 재료용)
  Future<void> _showCategorySelectionDialog(BuildContext context, IngredientResponse ingredient) async {
    String? selectedCategory;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🎉',
                      style: TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      '재료 공여 완료!',
                      style: const TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryOrange.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              '✨',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '이제 이 재료의 카테고리를 지정해주세요',
                              style: const TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                                letterSpacing: 0.3,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              '💡',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '선택한 카테고리는 모든 사용자에게 반영돼요',
                              style: const TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                                letterSpacing: 0.3,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...IngredientCategory.values.map((category) {
                      final isSelected = selectedCategory == category;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryGreen.withOpacity(0.15)
                                    : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : AppColors.primaryGreen.withOpacity(0.3),
                                  width: isSelected ? 2 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryGreen.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primaryGreen
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      IngredientCategory.toDisplayName(category),
                                      style: TextStyle(
                                        fontFamily: 'NanumGothicCoding-Regular',
                                        letterSpacing: 0.5,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontFamily: 'NanumGothicCoding-Regular',
                            letterSpacing: 0.5,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedCategory == null
                            ? null
                            : () {
                                Navigator.pop(context);
                                _addIngredientToRefrigeratorWithCategory(
                                  context,
                                  ingredient,
                                  selectedCategory!,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontFamily: 'NanumGothicCoding-Regular',
                            letterSpacing: 0.5,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 카테고리와 함께 재료 추가 (OPEN_API 재료용)
  Future<void> _addIngredientToRefrigeratorWithCategory(
    BuildContext context,
    IngredientResponse ingredient,
    String category,
  ) async {
    try {
      // Open API 재료는 먼저 재료를 생성해야 함
      final createResponse = await ApiService.createIngredient(category, ingredient.name);

      if (!mounted) return;

      // 201 응답이 오면 재료 공여 성공
      if (createResponse.code == 201 && createResponse.response.data != null && createResponse.response.data!.id != null) {
        // 재료 생성 성공 후 냉장고에 추가
        final addResponse = await ApiService.addIngredientToRefrigerator(
          createResponse.response.data!.id!,
        );

        if (!mounted) return;

        if (addResponse.code == 200) {
          // 성공 시 냉장고 목록 새로고침하여 화면에 반영
          await _loadRefrigerator();

          // 해당 카테고리로 이동하여 사용자가 바로 볼 수 있게 함
          final categoryIndex = IngredientCategory.values.indexOf(category);
          if (categoryIndex != -1) {
            _controller.selectCategory(categoryIndex);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '재료 공여가 완료되었습니다',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                addResponse.message,
                style: const TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              createResponse.message,
              style: const TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '재료 추가 중 오류가 발생했습니다: $e',
            style: const TextStyle(
              fontFamily: 'NanumGothicCoding-Regular',
              letterSpacing: 0.5,
              fontSize: 14,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // 냉장고에 재료 추가
  Future<void> _addIngredientToRefrigerator(BuildContext context, IngredientResponse ingredient) async {
    // 재료의 source를 확인
    if (ingredient.source == Source.OPEN_API) {
      // OPEN_API면 카테고리 선택 팝업 표시
      await _showCategorySelectionDialog(context, ingredient);
      return;
    }

    // DATABASE면 그대로 진행
      if (ingredient.id == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '재료 ID가 없습니다',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    
    try {
      final response = await ApiService.addIngredientToRefrigerator(ingredient.id!);

      if (!mounted) return;

      if (response.code == 200) {
        // 성공 시 냉장고 목록 새로고침
        await _loadRefrigerator();
        
        // 해당 카테고리로 이동하여 사용자가 바로 볼 수 있게 함
        if (ingredient.category != null) {
          final categoryIndex = IngredientCategory.values.indexOf(ingredient.category!);
          if (categoryIndex != -1) {
            _controller.selectCategory(categoryIndex);
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '재료가 추가되었습니다',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message,
              style: const TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '재료 추가 중 오류가 발생했습니다: $e',
            style: const TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // 재료 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog(BuildContext context, IngredientResponse ingredient) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🗑️',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '재료 삭제',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Text(
            '${ingredient.name} 삭제하시겠어요?',
            style: const TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteIngredient(context, ingredient);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 재료 삭제
  Future<void> _deleteIngredient(BuildContext context, IngredientResponse ingredient) async {
    if (ingredient.id == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('재료 ID가 없습니다', style: TextStyle(fontFamily: 'NanumGothicCoding-Regular', letterSpacing: 0.5)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    try {
      bool success = await _controller.deleteIngredient(ingredient.id!);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('재료가 삭제되었습니다', style: TextStyle(fontFamily: 'NanumGothicCoding-Regular', letterSpacing: 0.5)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('삭제에 실패했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('삭제 중 오류: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 40 : 20,
            vertical: 20,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 회색 박스의 전체 가로 길이 (padding 포함)
              final grayBoxWidth = constraints.maxWidth;
              return Column(
                children: [
                  const SizedBox(height: 20),
                  _buildCategoryNavigation(grayBoxWidth),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: AppColors.primaryOrange.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              SizedBox(
                                height: 280,
                                // (수정) _isLoading -> _controller.isLoading
                                child: _controller.isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                        ),
                                      )
                                    : _currentCategoryIngredients.isEmpty
                                        ? Center(
                                            child: Text(
                                              '재료를 추가해주세요',
                                              style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          )
                                        : kIsWeb
                                            ? SizedBox(
                                                height: 280,
                                                child: GridView.builder(
                                                  physics: const AlwaysScrollableScrollPhysics(),
                                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 4, // 웹: 4칸
                                                    crossAxisSpacing: 12,
                                                    mainAxisSpacing: 8,
                                                    childAspectRatio: 5.0, // 카드를 더 작게
                                                  ),
                                                  itemCount: _currentCategoryIngredients.length,
                                                  itemBuilder: (context, index) {
                                                    final ingredient = _currentCategoryIngredients[index];
                                                    return MouseRegion(
                                                      cursor: SystemMouseCursors.click,
                                                      child: GestureDetector(
                                                        onTap: () => _showDeleteConfirmDialog(context, ingredient),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 6,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(
                                                              color: AppColors.primaryGreen.withOpacity(0.3),
                                                              width: 1.5,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: AppColors.primaryGreen.withOpacity(0.1),
                                                                blurRadius: 3,
                                                                offset: const Offset(0, 1),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              ingredient.name,
                                                              style: const TextStyle(
                                                                fontFamily: 'NanumGothicCoding-Regular',
                                                                letterSpacing: 0.5,
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: AppColors.textDark,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : SizedBox(
                                                height: 280,
                                                child: GridView.builder(
                                                  physics: const AlwaysScrollableScrollPhysics(),
                                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2, // 모바일: 2칸
                                                    crossAxisSpacing: 12,
                                                    mainAxisSpacing: 8,
                                                    childAspectRatio: 3.5, // 카드 높이 확보
                                                  ),
                                                  itemCount: _currentCategoryIngredients.length,
                                                  itemBuilder: (context, index) {
                                                    final ingredient = _currentCategoryIngredients[index];
                                                    return MouseRegion(
                                                      cursor: SystemMouseCursors.click,
                                                      child: GestureDetector(
                                                        onTap: () => _showDeleteConfirmDialog(context, ingredient),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 8,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(
                                                              color: AppColors.primaryGreen.withOpacity(0.3),
                                                              width: 1.5,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: AppColors.primaryGreen.withOpacity(0.1),
                                                                blurRadius: 3,
                                                                offset: const Offset(0, 1),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              ingredient.name,
                                                              style: const TextStyle(
                                                                fontFamily: 'NanumGothicCoding-Regular',
                                                                letterSpacing: 0.5,
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: AppColors.textDark,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => _showAddIngredientDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryOrange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    '재료 추가하기',
                                    style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  //카테고리 네비게이션 부분을 별도 함수로 추출 
  Widget _buildCategoryNavigation(double availableWidth) {
    final allCategories = IngredientCategory.values;
    final isWeb = MediaQuery.of(context).size.width > 600;
    
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, right: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 카테고리 버튼들의 예상 너비 계산 (모바일/웹 차별화)
          final actualWidth = constraints.maxWidth;
          // _buildCategoryButton의 실제 패딩 (horizontal * 2) + border width (1.5 * 2)
          final buttonPadding = isWeb ? 35.0 : 27.0; // 16*2+3 또는 12*2+3
          final buttonSpacing = 8.0;
          final moreButtonWidth = isWeb ? 80.0 : 65.0; // 더보기 버튼 예상 너비
          final moreButtonSpacing = 8.0;
          
          // TextPainter를 사용하여 각 카테고리 버튼의 실제 너비 계산
          final textStyle = TextStyle(
            fontFamily: 'NanumGothicCoding-Regular',
            letterSpacing: 0.5,
            fontSize: isWeb ? 16 : 13, // 모바일 글씨 크기 소폭 축소
            fontWeight: FontWeight.w600,
          );
          
          // 전체 카테고리 버튼 너비
          final allButtonWidth = _measureTextWidth('전체', textStyle) + buttonPadding;
          
          // 각 카테고리 버튼의 너비 계산
          final categoryWidths = <double>[];
          for (final category in allCategories) {
            final label = IngredientCategory.toDisplayName(category);
            final width = _measureTextWidth(label, textStyle) + buttonPadding;
            categoryWidths.add(width);
          }
          
          // 사용 가능한 너비에서 더보기 버튼 공간 확보
          double usedWidth = allButtonWidth + buttonSpacing;
          final visibleIndices = <int>[];
          
          for (int i = 0; i < categoryWidths.length; i++) {
            final neededWidth = categoryWidths[i] + buttonSpacing;
            // 더보기 버튼이 필요한지 확인
            final totalWithMoreButton = usedWidth + neededWidth + moreButtonSpacing + moreButtonWidth;
            final totalWithoutMoreButton = usedWidth + neededWidth;
            
            // 실제 사용 가능한 너비(actualWidth)를 기준으로 계산하여 Overflow 방지
            if (i == categoryWidths.length - 1 && totalWithoutMoreButton <= actualWidth) {
              // 마지막 카테고리이고 더보기 버튼 없이 들어갈 수 있으면 추가
              usedWidth += neededWidth;
              visibleIndices.add(i);
            } else if (totalWithMoreButton <= actualWidth) {
              // 더보기 버튼을 포함해서 들어갈 수 있으면 추가
              usedWidth += neededWidth;
              visibleIndices.add(i);
            } else {
              // 더보기 버튼이 필요한 경우
              break;
            }
          }
          
          final visibleCategories = visibleIndices.map((i) => allCategories[i]).toList();
          final hiddenCategories = allCategories
              .asMap()
              .entries
              .where((entry) => !visibleIndices.contains(entry.key))
              .map((entry) => entry.value)
              .toList();
          
          final hasMoreButton = hiddenCategories.isNotEmpty;
          
          return Row(
            children: [
              // 카테고리 버튼들
              Expanded(
                child: Row(
                  children: [
                    // 전체 카테고리 버튼
                    _buildCategoryButton(
                      '전체',
                      _controller.currentCategoryIndex == -1,
                      () => _controller.selectCategory(-1),
                    ),
                    const SizedBox(width: 8),
                    // 각 카테고리 버튼
                    ...visibleCategories.asMap().entries.map((entry) {
                      final categoryIndex = allCategories.indexOf(entry.value);
                      final category = entry.value;
                      final isSelected = _controller.currentCategoryIndex == categoryIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryButton(
                          IngredientCategory.toDisplayName(category),
                          isSelected,
                          () => _controller.selectCategory(categoryIndex),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // 더보기 버튼
              if (hasMoreButton)
                _buildMoreButton(context, hiddenCategories, allCategories),
            ],
          );
        },
      ),
    );
  }
  
  // 텍스트 너비 측정 헬퍼 함수
  double _measureTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.size.width;
  }

  // 카테고리 버튼 위젯
  Widget _buildCategoryButton(String label, bool isSelected, VoidCallback onTap) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 16 : 12, 
            vertical: isWeb ? 10 : 8
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryGreen 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primaryGreen 
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: isWeb ? 16 : 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected 
                  ? Colors.white 
                  : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  // 더보기 버튼
  Widget _buildMoreButton(BuildContext context, List<String> hiddenCategories, List<String> allCategories) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showMoreCategoriesDialog(context, hiddenCategories, allCategories),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.textDark.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.more_vert,
              size: 20,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  // 더보
  void _showMoreCategoriesDialog(BuildContext context, List<String> hiddenCategories, List<String> allCategories) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '📂',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '카테고리 선택',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: hiddenCategories.map((category) {
                final categoryIndex = allCategories.indexOf(category);
                final isSelected = _controller.currentCategoryIndex == categoryIndex;
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 120) / 3,
                  child: _buildSmallCategoryButton(
                    IngredientCategory.toDisplayName(category),
                    isSelected,
                    () {
                      _controller.selectCategory(categoryIndex);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              '닫기',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 작은 카테고리 버튼 (더보기 다이얼로그용)
  Widget _buildSmallCategoryButton(String label, bool isSelected, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryGreen 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primaryGreen 
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected 
                    ? Colors.white 
                    : AppColors.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

}

