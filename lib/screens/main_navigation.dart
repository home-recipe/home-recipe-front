import 'package:flutter/material.dart';
import 'recipe_page.dart';
import 'my_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigation({
    super.key,
    this.initialIndex = 1, // 기본값: Cook (레시피)
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const RecipePage(), // Store (추천 레시피) - 인덱스 0
      const RecipePage(), // Cook (레시피 만들기) - 인덱스 1
      const MyPage(), // My (재료 관리) - 인덱스 2
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFDEAE71),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'GowunBatang',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'GowunBatang',
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: '추천',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: '레시피',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'My',
          ),
        ],
      ),
    );
  }
}

