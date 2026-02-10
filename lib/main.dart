import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/login_page.dart';
import 'screens/login_callback_page.dart';
import 'screens/main_navigation.dart';
import 'screens/my_page.dart';
import 'screens/recipe_page.dart';
import 'services/api_service.dart';
import 'utils/web_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // URL에서 # 제거 (예: /#/login-callback → /login-callback)
  usePathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '냉장고 프로젝트',
      navigatorKey: ApiService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const FontPreloadWrapper(child: LoginPage()),
        '/login-callback': (context) => const LoginCallbackPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 폰트 프리로딩을 처리하는 래퍼 위젯
class FontPreloadWrapper extends StatefulWidget {
  final Widget child;

  const FontPreloadWrapper({super.key, required this.child});

  @override
  State<FontPreloadWrapper> createState() => _FontPreloadWrapperState();
}

class _FontPreloadWrapperState extends State<FontPreloadWrapper> {
  bool _fontsLoaded = false;

  @override
  void initState() {
    super.initState();
    _preloadFonts();
  }

  Future<void> _preloadFonts() async {
    // 브라우저 폰트 API 대기 (웹 전용)
    await waitForFontsReady();

    // 각 폰트로 텍스트를 렌더링하여 폰트 로드를 트리거
    final fontFamilies = [
      'DoHyeon',
      'Cafe24Danjunghae',
      'Cafe24PROSlimFit',
      'GowunBatang',
      'Jua',
      'NanumBrushScript',
      'NanumMyeongjo',
      'NanumGothicCoding-Regular',
    ];

    for (final family in fontFamilies) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontFamily: family),
      )..addText('가나다라마바사아자차카타파하 ABC abc 123 !@# 🍳🥗🍕🍔');

      final paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));
    }

    // 첫 프레임 렌더링 대기
    await Future.delayed(const Duration(milliseconds: 100));

    // 추가 프레임 대기하여 폰트 렌더링 안정화
    for (int i = 0; i < 3; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }

    if (mounted) {
      setState(() {
        _fontsLoaded = true;
      });

      // 로딩 화면 제거 (웹 전용)
      removeLoadingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 폰트가 로드되지 않았어도 child를 렌더링
    // HTML 로딩 화면이 위에 표시되므로 사용자에게는 보이지 않음
    return widget.child;
  }
}
