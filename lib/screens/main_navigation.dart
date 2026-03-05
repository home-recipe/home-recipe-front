import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'recipe_page.dart';
import 'my_page.dart';
import 'recommendation_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import '../constants/app_colors.dart';
import '../services/token_service.dart';
import '../widgets/auth_guard_dialog.dart';
import '../widgets/recook_logo.dart';
import '../utils/logout_helper.dart';

/// 메인 네비게이션 화면
/// 상단 AppBar 탭 방식으로 변경
class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  late final ValueNotifier<int> _tabNotifier;
  final GlobalKey<MyPageState> _myPageKey = GlobalKey<MyPageState>();

  // 로그인 상태 추적
  bool _isLoggedIn = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabNotifier = ValueNotifier<int>(_currentIndex);
    _checkLoginStatus();
    // 초기 라우트 검증 (URL 직접 접근 방지)
    _validateInitialRoute();
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  /// 로그인 상태 확인
  Future<void> _checkLoginStatus() async {
    final token = await TokenService.getAccessToken();
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _isCheckingAuth = false;
    });
  }

  /// 초기 라우트 검증 (URL 직접 접근 방지)
  Future<void> _validateInitialRoute() async {
    // 로그인 상태 확인이 완료될 때까지 대기
    while (_isCheckingAuth) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // 보호된 탭(index > 0)에 비로그인 상태로 접근 시도한 경우
    if (_currentIndex > 0 && !_isLoggedIn) {
      // Auth 다이얼로그 표시
      if (mounted) {
        await showAuthRequiredDialog(context);
        // 다이얼로그 닫힌 후 홈 탭으로 리다이렉션
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });
          _tabNotifier.value = 0;
        }
      }
    }
  }

  /// 탭 전환 처리
  void _onTabTapped(int index) {
    // 홈 탭(index 0)은 항상 접근 가능
    if (index == 0) {
      setState(() {
        _currentIndex = index;
      });
      _tabNotifier.value = index;
      return;
    }

    // My/레시피/추천 탭은 로그인 필요
    if (!_isLoggedIn) {
      // 로그인 필요 다이얼로그 표시
      showAuthRequiredDialog(context).then((_) {
        // 다이얼로그 닫힌 후 로그인 상태 재확인
        _checkLoginStatus();
      });
      return;
    }

    // 로그인 상태이면 정상 탭 전환
    setState(() {
      _currentIndex = index;
    });
    _tabNotifier.value = index;

    // My 탭을 클릭하면 데이터 새로고침
    if (index == 1 && _myPageKey.currentState != null) {
      _myPageKey.currentState!.refreshData();
    }
  }

  /// 로그아웃 처리
  Future<void> _handleLogout() async {
    await LogoutHelper.handleLogout(context);
    // 로그아웃 후 로그인 상태 재확인
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    // 로그인 확인 중
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _buildAppBar(isWide),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // index 0: 홈 (랜딩 페이지)
          LandingPage(
            onMyPressed: () => _onTabTapped(1),
            onRecommendPressed: () => _onTabTapped(3),
          ),
          // index 1: My (재료 관리)
          MyPage(key: _myPageKey),
          // index 2: 레시피 (레시피 만들기)
          RecipePage(tabNotifier: _tabNotifier, tabIndex: 2),
          // index 3: 추천 (추천 레시피)
          RecommendationPage(tabNotifier: _tabNotifier, tabIndex: 3),
        ],
      ),
    );
  }

  /// 상단 AppBar 생성
  PreferredSizeWidget _buildAppBar(bool isWide) {
    return AppBar(
      backgroundColor: AppColors.backgroundWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 70,
      // 하단 경계선
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.grey.shade200,
          height: 1,
        ),
      ),
      // 좌측: 로고 (클릭 시 홈 탭으로 이동)
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: RecookLogo(
            fontSize: 24,
            outlineWidth: 1.5,
            letterSpacing: 0.3,
            onTap: () => _onTabTapped(0),  // 홈 탭으로 이동
          ),
        ),
      ),
      leadingWidth: 140,
      // 중앙: 탭 버튼들
      title: isWide ? _buildTabButtons() : null,
      centerTitle: true,
      // 우측: 로그인/프로필 버튼
      actions: [
        if (isWide) ..._buildAuthActions(),
        const SizedBox(width: 16),
      ],
    );
  }

  /// 탭 버튼들 생성 (중앙)
  Widget _buildTabButtons() {
    final tabs = [
      {'label': '홈', 'index': 0},
      {'label': 'My', 'index': 1},
      {'label': '레시피', 'index': 2},
      {'label': '추천', 'index': 3},
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tabs.map((tab) {
        final index = tab['index'] as int;
        final isSelected = _currentIndex == index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton(
            onPressed: () => _onTabTapped(index),
            style: TextButton.styleFrom(
              foregroundColor: isSelected
                  ? AppColors.primaryOrange
                  : AppColors.textGrey,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: Text(
              tab['label'] as String,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 인증 관련 액션 버튼들 (우측)
  List<Widget> _buildAuthActions() {
    if (_isLoggedIn) {
      // 로그인 상태: 프로필 아이콘 + 메뉴
      return [
        PopupMenuButton<String>(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: AppColors.textGrey),
                  SizedBox(width: 12),
                  Text(
                    '로그아웃',
                    style: TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                      letterSpacing: 0.3,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ];
    } else {
      // 비로그인 상태: 로그인/회원가입 버튼
      return [
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            ).then((_) {
              // 로그인 페이지에서 돌아온 후 상태 확인
              _checkLoginStatus();
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textGrey,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          child: const Text(
            '로그인',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'NanumGothicCoding-Regular',
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SignUpPage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          child: const Text(
            '회원가입',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'NanumGothicCoding-Regular',
              letterSpacing: 0.3,
            ),
          ),
        ),
      ];
    }
  }
}
