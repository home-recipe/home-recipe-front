import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/ingredient_category.dart';
import '../models/ingredient_response.dart';
import '../utils/logout_helper.dart';
import '../utils/profile_image_helper.dart';
import 'my_page/my_page_controller.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => MyPageState();
}

class MyPageState extends State<MyPage> {
  final MyPageController _controller = MyPageController();
  final GlobalKey _accountButtonKey = GlobalKey();
  
  // 프로필 사진 (한 번 선택 후 고정)
  String? _selectedProfileImage;
  
  Future<void> _loadRefrigerator() async {
    await _controller.loadRefrigerator();
  }

  List<IngredientResponse> get _currentCategoryIngredients => _controller.currentCategoryIngredients;
  
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 랜덤하게 프로필 사진 선택 (비동기)
    _loadRandomProfileImage();
    
    _controller.loadRefrigerator();
    //컨트롤러의 상태가 바뀔때마다 화면을 다시 그리도록 설정 
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }
  
  /// 프로필 이미지를 사용자별로 고정된 이미지로 로드
  Future<void> _loadRandomProfileImage() async {
    final image = await ProfileImageHelper.getUserProfileImage();
    if (mounted) {
      setState(() {
        _selectedProfileImage = image;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // 메모리 해제
    super.dispose();
  }
  
  // 외부에서 호출하던 refreshData도 간단해짐
  void refreshData() => _controller.loadRefrigerator();

// --- 추가된 헬퍼 메서드 ---
//오른쪽위에 사람계정, 누르면 로그아웃 메뉴 나옴
  Widget _buildHeader() {
    return Padding(
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _selectedProfileImage != null
                      ? Image.asset(
                          _selectedProfileImage!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 48,
                              color: Color(0xFF2C2C2C),
                            );
                          },
                        )
                      : const Icon(
                          Icons.account_circle,
                          size: 48,
                          color: Color(0xFF2C2C2C),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                                          '다른 검색어로 시도해보세요',
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
      bool success = await _controller.deleteIngredient(ingredient.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('재료가 삭제되었습니다', style: TextStyle(fontFamily: 'GowunBatang')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('삭제 중 오류: $e');
    }
  }


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/homeimage2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.4),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(), // 상단 계정 아이콘
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildCategoryNavigation(),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xCCF2EFEB),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
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
                                              crossAxisCount: 7,
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 2.5,
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
                                                      color: Colors.white.withOpacity(0.9),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: const Color(0xFFDEAE71).withOpacity(0.4),
                                                        width: 1.5,
                                                      ),
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
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => _showAddIngredientDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDEAE71),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '재료 추가하기',
                                    style: TextStyle(
                                      fontFamily: 'GowunBatang',
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
  //카테고리 네비게이션 부분을 별도 함수로 추출 
  Widget _buildCategoryNavigation() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child : Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              IngredientCategory.toDisplayName(_controller.currentCategory),
              style: const TextStyle(
                fontFamily: 'GowunBatang',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ),
          const SizedBox(width: 12),
          //이전 버튼
          _buildArrowButton(
            icon: Icons.chevron_left,
            onTap: _controller.previousCategory,
          ),
          const SizedBox(width: 8),
          //다음 버튼
          _buildArrowButton(
            icon: Icons.chevron_right,
            onTap: _controller.nextCategory,
          ),
        ],
      ),
    );
  }

  //화살표 버튼 디자인도 별도 함수로 추출
  Widget _buildArrowButton({required IconData icon, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2C2C2C)),
        ),
      ),
    );
  }
}

