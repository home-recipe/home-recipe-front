import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'recipe_page.dart';
import 'my_page.dart';
import 'recommendation_page.dart';
import 'bookmark_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import '../constants/app_colors.dart';
import '../services/token_service.dart';
import '../widgets/auth_guard_dialog.dart';
import '../widgets/recook_logo.dart';
import '../utils/logout_helper.dart';

/// 메인 네비게이션 화면
/// 모든 탭에 동일한 AppBar 적용
/// 모바일: BottomNavigationBar, 태블릿/웹: 상단 탭 버튼
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

  // 탭 목록 (5개: 홈, My, 레시피, 추천, 보관함)
  static const List<Map<String, dynamic>> _tabs = [
    {'label': '홈', 'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'index': 0},
    {'label': 'My', 'icon': Icons.person_outline, 'activeIcon': Icons.person, 'index': 1},
    {'label': '레시피', 'icon': Icons.restaurant_menu_outlined, 'activeIcon': Icons.restaurant_menu, 'index': 2},
    {'label': '추천', 'icon': Icons.auto_awesome_outlined, 'activeIcon': Icons.auto_awesome, 'index': 3},
    {'label': '보관함', 'icon': Icons.bookmark_outline, 'activeIcon': Icons.bookmark, 'index': 4},
  ];

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

    // My/레시피/추천/보관 탭은 로그인 필요
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
    // 반응형 브레이크포인트: 모바일 < 600, 태블릿 600~900, 웹/데스크톱 > 900
    final isWide = screenWidth > 900;
    final isMobile = screenWidth < 600;

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
      appBar: _buildAppBar(isWide, isMobile),
      body: SafeArea(
        top: false, // AppBar가 이미 SafeArea 처리
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // index 0: 홈
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
            // index 4: 보관함
            const BookmarkPage(),
          ],
        ),
      ),
      // 모바일: 하단 네비게이션 바
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
    );
  }

  /// 모바일용 BottomNavigationBar
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.backgroundWhite,
          selectedItemColor: AppColors.primaryOrange,
          unselectedItemColor: AppColors.textGrey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'NanumGothicCoding-Regular',
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'NanumGothicCoding-Regular',
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: _tabs.map((tab) {
            return BottomNavigationBarItem(
              icon: Icon(tab['icon'] as IconData),
              activeIcon: Icon(tab['activeIcon'] as IconData),
              label: tab['label'] as String,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 상단 AppBar 생성 (모든 탭 공통)
  PreferredSizeWidget _buildAppBar(bool isWide, bool isMobile) {
    // 모바일: 컴팩트 AppBar (높이 56)
    // 태블릿/웹: 넓은 AppBar (높이 70)
    final toolbarHeight = isMobile ? 56.0 : 70.0;
    final logoFontSize = isMobile ? 22.0 : 30.0;
    final logoOutlineWidth = isMobile ? 1.0 : 1.5;
    final leadingWidth = isMobile ? 120.0 : 160.0;

    return AppBar(
      backgroundColor: AppColors.backgroundWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
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
        padding: EdgeInsets.only(left: isMobile ? 12 : 16),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: RecookLogo(
              fontSize: logoFontSize,
              outlineWidth: logoOutlineWidth,
              letterSpacing: 0.3,
              onTap: () => _onTabTapped(0),
            ),
          ),
        ),
      ),
      leadingWidth: leadingWidth,
      // 중앙: 탭 버튼들 (넓은 화면에서만)
      title: isWide ? _buildTabButtons() : null,
      centerTitle: true,
      // 우측: 로그인/프로필 버튼
      actions: [
        if (isWide) ..._buildAuthActions(),
        // 모바일: 프로필 아이콘만 표시
        if (isMobile && _isLoggedIn)
          _buildMobileProfileButton(),
        if (isMobile && !_isLoggedIn)
          _buildMobileLoginButton(),
        SizedBox(width: isMobile ? 8 : 16),
      ],
    );
  }

  /// 모바일 프로필 버튼 (컴팩트)
  Widget _buildMobileProfileButton() {
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          kIsWeb ? 'profiles/tomato.png' : 'assets/profiles/tomato.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primaryOrange,
              size: 18,
            ),
          ),
        ),
      ),
      offset: const Offset(0, 45),
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
    );
  }

  /// 모바일 로그인 버튼 (컴팩트)
  Widget _buildMobileLoginButton() {
    return IconButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        ).then((_) {
          _checkLoginStatus();
        });
      },
      icon: const Icon(
        Icons.login,
        color: AppColors.primaryOrange,
        size: 22,
      ),
      tooltip: '로그인',
    );
  }

  /// 탭 버튼들 생성 (중앙, 넓은 화면용 - 검은색 텍스트)
  Widget _buildTabButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _tabs.map((tab) {
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

  /// 인증 관련 액션 버튼들 (우측, 넓은 화면용)
  List<Widget> _buildAuthActions() {
    if (_isLoggedIn) {
      // 로그인 상태: 프로필 아이콘 + 메뉴
      return [
        PopupMenuButton<String>(
          icon: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              kIsWeb ? 'profiles/tomato.png' : 'assets/profiles/tomato.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
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
