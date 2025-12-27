import 'package:flutter/material.dart';
import '../utils/logout_helper.dart';
import '../services/api_service.dart';
import '../models/recipes_response.dart';

enum RecipePageState {
  initial, // 초기 화면
  loading, // 로딩 중
  loaded, // 레시피 로드 완료
}

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> with TickerProviderStateMixin {
  final GlobalKey _accountButtonKey = GlobalKey();
  RecipePageState _pageState = RecipePageState.initial;
  RecipeDecision? _decision;
  String _reason = '';
  List<RecipeDetail> _recipes = [];
  late AnimationController _loadingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ------------------------------
  // 레시피 생성 함수
  // ------------------------------
  Future<void> _createRecipes() async {
    setState(() {
      _pageState = RecipePageState.loading;
    });

    final response = await ApiService.createRecipes();

    if (response.code == 201 && response.response.data != null) {
      setState(() {
        _decision = response.response.data!.decision;
        _reason = response.response.data!.reason;
        _recipes = response.response.data!.recipes ?? [];
        _pageState = RecipePageState.loaded;
      });
    } else {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _pageState = RecipePageState.initial;
        });
      }
    }
  }

  // ------------------------------
  // UI 시작
  // ------------------------------
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

          // 오버레이
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

          SafeArea(
            child: Column(
              children: [
                // 상단 계정 아이콘
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
                  child: _buildContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // 화면 상태에 따라 다른 UI 표시
  // ------------------------------
  Widget _buildContent(BuildContext context) {
    switch (_pageState) {
      case RecipePageState.initial:
        return _buildInitialScreen(context);
      case RecipePageState.loading:
        return _buildLoadingScreen(context);
      case RecipePageState.loaded:
        return _buildRecipesList(context);
    }
  }

  // ------------------------------
  // 초기 화면: 레시피 만들기 버튼만
  // ------------------------------
  Widget _buildInitialScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Color(0xFFDEAE71),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _createRecipes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDEAE71),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 3,
            ),
            child: const Text(
              '레시피 만들기',
              style: TextStyle(
                fontFamily: 'GowunBatang',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // 로딩 화면: 재미있는 애니메이션
  // ------------------------------
  Widget _buildLoadingScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 회전하는 요리 아이콘들
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingController.value * 2 * 3.14159,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    size: 64,
                    color: Color(0xFFDEAE71),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // 펄스 애니메이션 텍스트
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.5 + (_pulseController.value * 0.5),
                child: const Text(
                  '맛있는 레시피를 만들고 있어요...',
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // 로딩 인디케이터
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDEAE71)),
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // 레시피 리스트 화면
  // ------------------------------
  Widget _buildRecipesList(BuildContext context) {
    if (_decision == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 64,
              color: Color(0xFF2C2C2C),
            ),
            const SizedBox(height: 16),
            const Text(
              '결과를 불러올 수 없습니다',
              style: TextStyle(
                fontFamily: 'GowunBatang',
                fontSize: 18,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _pageState = RecipePageState.initial;
                  _decision = null;
                  _reason = '';
                  _recipes = [];
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDEAE71),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '다시 만들기',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // DELIVERY인 경우: reason만 표시
    if (_decision == RecipeDecision.DELIVERY) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '추천 결과',
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _pageState = RecipePageState.initial;
                      _decision = null;
                      _reason = '';
                      _recipes = [];
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text(
                    '다시 만들기',
                    style: TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: const Color(0xFF2C2C2C),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // DELIVERY 카드
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
                  // 배달 아이콘 헤더
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEAE71).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          size: 32,
                          color: Color(0xFFDEAE71),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '배달 추천',
                          style: TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // reason 표시
                  Text(
                    _reason,
                    style: const TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 18,
                      color: Color(0xFF2C2C2C),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // COOK인 경우: reason과 recipes 모두 표시
    return Column(
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _recipes.isEmpty 
                    ? '레시피 추천'
                    : '${_recipes.length}개의 레시피',
                style: const TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _pageState = RecipePageState.initial;
                    _decision = null;
                    _reason = '';
                    _recipes = [];
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  '다시 만들기',
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: const Color(0xFF2C2C2C),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // reason 표시 (COOK인 경우)
        if (_reason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xCCF2EFEB),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 24,
                    color: Color(0xFFDEAE71),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _reason,
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 16,
                        color: Color(0xFF2C2C2C),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // 레시피 리스트
        Expanded(
          child: _recipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Color(0xFF2C2C2C),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '레시피가 없습니다',
                        style: TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 18,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    return _buildRecipeCard(_recipes[index], index);
                  },
                ),
        ),
      ],
    );
  }

  // ------------------------------
  // 레시피 카드 위젯
  // ------------------------------
  Widget _buildRecipeCard(RecipeDetail recipe, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          // 레시피 이름 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDEAE71).withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEAE71),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    recipe.recipeName,
                    style: const TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 레시피 내용
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 재료 섹션
                const Row(
                  children: [
                    Icon(
                      Icons.shopping_basket,
                      size: 20,
                      color: Color(0xFFDEAE71),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '재료',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recipe.ingredients.map((ingredient) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDEAE71).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        ingredient,
                        style: const TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 14,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // 조리 단계 섹션
                const Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 20,
                      color: Color(0xFFDEAE71),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '조리 단계',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recipe.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEAE71),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontFamily: 'GowunBatang',
                              fontSize: 16,
                              color: Color(0xFF2C2C2C),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
