import 'package:flutter/material.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final GlobalKey _accountButtonKey = GlobalKey();
  
  // 카테고리 목록
  final List<String> _categories = [
    '채소',
    '과일',
    '육류',
    '해산물',
    '유제품/계란',
    '가공식품',
    '소스/양념',
    '냉동식품',
    '기타',
  ];
  
  int _currentCategoryIndex = 0; // 기본값: 채소 (0번 인덱스)
  
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

  void _showLogoutMenu(BuildContext context) {
    final RenderBox? renderBox = _accountButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width - 130, // 오른쪽 정렬
        offset.dy + size.height + 4, // 아래로
        offset.dx + size.width,
        offset.dy + size.height + 4 + 50,
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
              Navigator.pop(context); // 메뉴 닫기
              _handleLogout(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            '로그아웃',
            style: TextStyle(
              fontFamily: 'GowunBatang',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            '로그아웃 하시겠습니까?',
            style: TextStyle(
              fontFamily: 'GowunBatang',
              fontSize: 16,
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
                Navigator.pop(context); // 다이얼로그 닫기
                
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
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
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
                                  _categories[_currentCategoryIndex],
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
                              // 빈 그리드 공간 (재료가 없을 때)
                              SizedBox(
                                height: 400,
                                child: Center(
                                  child: Text(
                                    '재료를 추가해주세요',
                                    style: TextStyle(
                                      fontFamily: 'GowunBatang',
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // 재료 추가하기 버튼
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // 재료 추가 기능 (추후 구현)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('재료 추가 기능은 곧 추가될 예정입니다')),
                                    );
                                  },
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

