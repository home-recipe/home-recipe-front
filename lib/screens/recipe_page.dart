import 'package:flutter/material.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

class RecipePage extends StatefulWidget {
  final String? recipeName;
  final List<String>? ingredients;
  final List<String>? steps;
  final String? imagePath; // null이면 초기 화면 모드

  const RecipePage({
    super.key,
    this.recipeName,
    this.ingredients,
    this.steps,
    this.imagePath,
  });

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final GlobalKey _accountButtonKey = GlobalKey();

  // ------------------------------
  // 로그아웃 메뉴
  // ------------------------------
  void _showLogoutMenu(BuildContext context) {
    final RenderBox? renderBox =
    _accountButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width - 130,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy + size.height + 50,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          height: 0,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 14, color: Color(0xFF2C2C2C)),
                  SizedBox(width: 10),
                  Text(
                    '로그아웃',
                    style: TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 14,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            '로그아웃',
            style: TextStyle(
              fontFamily: 'GowunBatang',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '로그아웃 하시겠습니까?',
            style: TextStyle(
              fontFamily: 'GowunBatang',
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // 로그아웃 API 호출
                try {
                  await ApiService.logout();
                } catch (e) {
                  // 에러가 발생해도 토큰은 삭제하고 로그인 페이지로 이동
                  await TokenService.clearTokens();
                }
                
                // 로그인 페이지로 이동 (모든 페이지 스택 제거)
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                }
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  color: Color(0xFFDEAE71),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
                          onTap: () => _showLogoutMenu(context),
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
  // 초기화면 OR 레시피화면 선택
  // ------------------------------
  Widget _buildContent(BuildContext context) {
    if (widget.recipeName == null) {
      return _buildInitialScreen(context);
    } else {
      return _buildRecipeDetail(context);
    }
  }

  // ------------------------------
  // 초기 화면: 레시피 만들기 버튼만
  // ------------------------------
  Widget _buildInitialScreen(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          // TODO: GPT API 호출해서 레시피 생성하는 자리
          // 예시로 더미 데이터 전달
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipePage(
                recipeName: "토마토 계란 볶음",
                ingredients: ["토마토", "계란", "파"],
                steps: ["토마토 자르기", "계란 볶기", "파 넣고 마무리"],
                imagePath: "assets/tomato.jpg",
              ),
            ),
          );
        },
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
    );
  }

  // ------------------------------
  // 레시피 내용 화면
  // ------------------------------
  Widget _buildRecipeDetail(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              widget.imagePath!,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),

          // 반투명 카드
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
                Text(
                  widget.recipeName!,
                  style: const TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  '재료',
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                ...widget.ingredients!.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $item',
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  '조리 단계',
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                ...widget.steps!.asMap().entries.map(
                      (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      '${entry.key + 1}. ${entry.value}',
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 16,
                      ),
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
