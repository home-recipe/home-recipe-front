import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/ingredient_category.dart';
import '../models/ingredient_response.dart';
import '../utils/logout_helper.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => MyPageState();
}

class MyPageState extends State<MyPage> {

  final GlobalKey _accountButtonKey = GlobalKey();
  
  // 카테고리 목록 (서버 enum 값 그대로)
  final List<String> _categories = IngredientCategory.values;
  
  int _currentCategoryIndex = 0; // 기본값: 채소 (0번 인덱스)
  
  // 냉장고 재료 목록
  List<IngredientResponse> _ingredients = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadRefrigerator();
  }
  
  // 외부에서 호출할 수 있는 새로고침 메서드
  void refreshData() {
    _loadRefrigerator();
  }
  
  // 냉장고 데이터 로드
  Future<void> _loadRefrigerator() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await ApiService.getRefrigerator();
      
      if (!mounted) return;
      
      if (response.code == 200 && response.response.data != null) {
        setState(() {
          _ingredients = response.response.data!.myRefrigerator;
          _isLoading = false;
        });
      } else {
        setState(() {
          _ingredients = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ingredients = [];
        _isLoading = false;
      });
      debugPrint('냉장고 조회 오류: $e');
    }
  }
  
  // 현재 선택된 카테고리의 재료만 필터링
  List<IngredientResponse> get _currentCategoryIngredients {
    final currentCategory = _categories[_currentCategoryIndex];
    return _ingredients
        .where((ingredient) => ingredient.category == currentCategory)
        .toList();
  }
  
  void _moveToPreviousCategory() {
    setState(() {
      _currentCategoryIndex = (_currentCategoryIndex - 1 + _categories.length) % _categories.length;
    });
  }
  
  void _moveToNextCategory() {
    setState(() {
      _currentCategoryIndex = (_currentCategoryIndex + 1) % _categories.length;
    });
  }

  // 재료 추가 다이얼로그
  Future<void> _showAddIngredientDialog(BuildContext context) async {
    final TextEditingController searchController = TextEditingController();
    List<IngredientResponse> searchResults = [];
    bool isSearching = false;
    bool hasSearched = false; // 검색을 한 번이라도 했는지 여부

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '재료 추가',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2C2C),
                ),
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
                          fontFamily: 'GowunBatang',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '재료 이름을 입력하세요',
                          hintStyle: TextStyle(
                            fontFamily: 'GowunBatang',
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
                              color: Color(0xFFDEAE71),
                              width: 2,
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
                          backgroundColor: const Color(0xFFDEAE71),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                  fontFamily: 'GowunBatang',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      // 직접 생성하기 버튼
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCreateIngredientDialog(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDEAE71),
                          side: const BorderSide(
                            color: Color(0xFFDEAE71),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '직접 생성하기',
                          style: TextStyle(
                            fontFamily: 'GowunBatang',
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
                                        color: Color(0xFFDEAE71),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${searchResults.length}개의 재료를 찾았어요',
                                        style: const TextStyle(
                                          fontFamily: 'GowunBatang',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C2C2C),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // 검색 결과 목록
                                  ...searchResults.map((ingredient) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFDEAE71).withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                            _showAddConfirmDialog(context, ingredient);
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDEAE71).withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.restaurant,
                                                    size: 20,
                                                    color: Color(0xFFDEAE71),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    ingredient.name,
                                                    style: const TextStyle(
                                                      fontFamily: 'GowunBatang',
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF2C2C2C),
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.chevron_right,
                                                  size: 20,
                                                  color: Color(0xFFDEAE71),
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
                                            fontFamily: 'GowunBatang',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2C2C2C),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '재료를 직접 등록할 수 있어요!',
                                          style: TextStyle(
                                            fontFamily: 'GowunBatang',
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '닫기',
                    style: TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 14,
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
      final response = await ApiService.findIngredientsByName(name);

      if (!context.mounted) return;

      if (response.code == 200 && response.response.data != null) {
        setState(() {
          onResult(response.response.data!);
        });
      } else {
        setState(() {
          onResult([]);
        });
        // 다이얼로그 내부에서는 ScaffoldMessenger 대신 직접 메시지 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message,
                style: const TextStyle(
                  fontFamily: 'GowunBatang',
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
      // 다이얼로그 내부에서는 ScaffoldMessenger 대신 직접 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '재료 검색 중 오류가 발생했습니다: $e',
              style: const TextStyle(
                fontFamily: 'GowunBatang',
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

  // 재료 추가 확인 다이얼로그
  Future<void> _showAddConfirmDialog(BuildContext context, IngredientResponse ingredient) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '재료 추가',
            style: TextStyle(
              fontFamily: 'GowunBatang',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          content: Text(
            '${ingredient.name} 냉장고에 추가하시겠어요?',
            style: const TextStyle(
              fontFamily: 'GowunBatang',
              fontSize: 16,
              color: Color(0xFF2C2C2C),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _addIngredientToRefrigerator(context, ingredient);
              },
              child: const Text(
                '확인',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 14,
                  color: Color(0xFFDEAE71),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 재료 직접 생성 다이얼로그
  Future<void> _showCreateIngredientDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    String? selectedCategory;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '재료 직접 생성',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 카테고리 선택
                    const Text(
                      '음식 카테고리',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFDEAE71),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      hint: const Text(
                        '카테고리를 선택하세요',
                        style: TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 14,
                        ),
                      ),
                      items: IngredientCategory.values.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            IngredientCategory.toDisplayName(category),
                            style: const TextStyle(
                              fontFamily: 'GowunBatang',
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // 재료명 입력
                    const Text(
                      '재료명',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 14,
                      ),
                      onChanged: (value) {
                        setState(() {
                          // 텍스트 변경 시 버튼 활성화 상태 업데이트
                        });
                      },
                      decoration: InputDecoration(
                        hintText: '재료 이름을 입력하세요',
                        hintStyle: TextStyle(
                          fontFamily: 'GowunBatang',
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
                            color: Color(0xFFDEAE71),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: TextButton(
                    onPressed: selectedCategory == null || nameController.text.trim().isEmpty
                        ? null
                        : () async {
                            final category = selectedCategory!;
                            final name = nameController.text.trim();
                            Navigator.pop(context);
                            await _createAndAddIngredient(
                              context,
                              category,
                              name,
                            );
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: selectedCategory == null || nameController.text.trim().isEmpty
                          ? Colors.grey
                          : const Color(0xFFDEAE71),
                    ),
                    child: const Text(
                      '생성',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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

  // 재료 생성 후 냉장고에 추가
  Future<void> _createAndAddIngredient(
    BuildContext context,
    String category,
    String name,
  ) async {
    try {
      debugPrint('재료 생성 시작: category=$category, name=$name');
      
      // 1. 재료 생성
      final createResponse = await ApiService.createIngredient(category, name);

      debugPrint('재료 생성 응답: code=${createResponse.code}, message=${createResponse.message}');

      if (!mounted) return;

      if (createResponse.code != 201 || createResponse.response.data == null) {
        debugPrint('재료 생성 실패: code=${createResponse.code}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                createResponse.message,
                style: const TextStyle(
                  fontFamily: 'GowunBatang',
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
        return;
      }

      final createdIngredient = createResponse.response.data!;
      debugPrint('재료 생성 성공: id=${createdIngredient.id}');

      // 2. 냉장고에 추가
      final addResponse = await ApiService.addIngredientToRefrigerator(createdIngredient.id);

      debugPrint('냉장고 추가 응답: code=${addResponse.code}, message=${addResponse.message}');

      if (!mounted) return;

      if (addResponse.code == 200) {
        // 성공 시 냉장고 목록 새로고침
        await _loadRefrigerator();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '재료가 생성되고 냉장고에 추가되었습니다',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                addResponse.message,
                style: const TextStyle(
                  fontFamily: 'GowunBatang',
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
    } catch (e, stackTrace) {
      debugPrint('재료 생성 중 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '재료 생성 중 오류가 발생했습니다: $e',
            style: const TextStyle(
              fontFamily: 'GowunBatang',
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
    try {
      final response = await ApiService.addIngredientToRefrigerator(ingredient.id);

      if (!mounted) return;

      if (response.code == 200) {
        // 성공 시 냉장고 목록 새로고침
        await _loadRefrigerator();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '재료가 추가되었습니다',
              style: TextStyle(
                fontFamily: 'GowunBatang',
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        // 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message,
              style: const TextStyle(
                fontFamily: 'GowunBatang',
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
              fontFamily: 'GowunBatang',
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '재료 삭제',
            style: TextStyle(
              fontFamily: 'GowunBatang',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          content: Text(
            '${ingredient.name} 삭제하시겠어요?',
            style: const TextStyle(
              fontFamily: 'GowunBatang',
              fontSize: 16,
              color: Color(0xFF2C2C2C),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteIngredient(context, ingredient);
              },
              child: const Text(
                '확인',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 14,
                  color: Color(0xFFDEAE71),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 재료 삭제
  Future<void> _deleteIngredient(BuildContext context, IngredientResponse ingredient) async {
    try {
      final response = await ApiService.deleteIngredient(ingredient.id);

      if (!mounted) return;

      if (response.code == 200) {
        // 성공 시 재료 목록에서 제거
        setState(() {
          _ingredients.removeWhere((item) => item.id == ingredient.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '재료가 삭제되었습니다',
              style: TextStyle(
                fontFamily: 'GowunBatang',
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        // 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message,
              style: const TextStyle(
                fontFamily: 'GowunBatang',
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
            '재료 삭제 중 오류가 발생했습니다: $e',
            style: const TextStyle(
              fontFamily: 'GowunBatang',
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/homeimage2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 배경 이미지 위에 오버레이 추가 (가독성 향상)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          // 메인 컨텐츠
          SafeArea(
            child: Column(
              children: [
                // 상단 앱바 (계정 아이콘)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          key: _accountButtonKey,
                          onTap: () => LogoutHelper.showLogoutMenu(context, _accountButtonKey),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_circle,
                              size: 32,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // 카테고리 네비게이션 (그리드 바깥)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Row(
                            children: [
                              // 카테고리 이름 (중앙 정렬을 위한 공간)
                              SizedBox(
                                width: 100, // 고정 너비로 화살표 위치 고정
                                child: Text(
                                  IngredientCategory.toDisplayName(_categories[_currentCategoryIndex]),
                                  style: const TextStyle(
                                    fontFamily: 'GowunBatang',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 이전 카테고리 버튼
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _moveToPreviousCategory,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left,
                                      size: 20,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 다음 카테고리 버튼
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _moveToNextCategory,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 반투명 카드 컨테이너 (그리드 공간)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xCCF2EFEB),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 재료 목록 표시 (모든 카테고리에서 동일한 높이로 고정)
                              SizedBox(
                                height: 280, // 고정 높이 (채소보다 살짝 작게)
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDEAE71)),
                                        ),
                                      )
                                    : _currentCategoryIngredients.isEmpty
                                        ? Center(
                                            child: Text(
                                              '재료를 추가해주세요',
                                              style: TextStyle(
                                                fontFamily: 'GowunBatang',
                                                fontSize: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          )
                                        : GridView.builder(
                                            shrinkWrap: false,
                                            physics: const AlwaysScrollableScrollPhysics(),
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 7, // 가로 7개
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 2.5, // 가로가 더 긴 형태로 조정
                                            ),
                                            itemCount: _currentCategoryIngredients.length,
                                            itemBuilder: (context, index) {
                                              final ingredient = _currentCategoryIngredients[index];
                                              return MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () => _showDeleteConfirmDialog(context, ingredient),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: const Color(0xFFDEAE71).withValues(alpha: 0.4),
                                                        width: 1.5,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withValues(alpha: 0.05),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                        child: Text(
                                                          ingredient.name,
                                                          style: const TextStyle(
                                                            fontFamily: 'GowunBatang',
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF2C2C2C),
                                                          ),
                                                          textAlign: TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                              ),
                              const SizedBox(height: 20),
                              // 재료 추가하기 버튼
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => _showAddIngredientDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDEAE71),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        '재료 추가하기',
                                        style: TextStyle(
                                          fontFamily: 'GowunBatang',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

