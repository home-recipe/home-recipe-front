import 'package:flutter/material.dart';
import 'recipe_page.dart';
import 'my_page.dart';
import 'recommendation_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigation({
    super.key,
    this.initialIndex = 2,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  late final List<Widget> _pages;
  final GlobalKey<MyPageState> _myPageKey = GlobalKey<MyPageState>();
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const RecommendationPage(), // Store (추천 레시피) - 인덱스 0
      const RecipePage(), // Cook (레시피 만들기) - 인덱스 1
      MyPage(key: _myPageKey), // My (재료 관리) - 인덱스 2
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // My 탭을 클릭하면 데이터 새로고침
    if (index == 2 && _myPageKey.currentState != null) {
      _myPageKey.currentState!.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFE07A5F),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'NanumGothicCoding-Regular',
            letterSpacing: 0.5,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'NanumGothicCoding-Regular',
            letterSpacing: 0.5,
            fontSize: 12,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.store, 0),
              label: '추천',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.restaurant, 1),
              label: '레시피',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.kitchen, 2),
              label: 'My',
            ),
          ],
        ),
      ),
    );
  }

  // 네비게이션 아이콘 위젯 (마우스 호버 효과 포함)
  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    final isHovered = _hoveredIndex == index;
    
    Color iconColor;
    if (isSelected) {
      iconColor = const Color(0xFFE07A5F);
    } else if (isHovered) {
      iconColor = const Color(0xFF81B29A);
    } else {
      iconColor = Colors.grey.shade600;
    }
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Icon(
        icon,
        color: iconColor,
      ),
    );
  }
}

