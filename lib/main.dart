import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/login_page.dart';
import 'screens/login_callback_page.dart';
import 'screens/main_navigation.dart';
import 'services/api_service.dart';
import 'services/deep_link_service.dart';
import 'utils/url_helper.dart' as url_helper;
import 'utils/web_utils.dart';
import 'constants/app_colors.dart';

void main() async {
  //Flutter가 위젯을 그릴 준비가 될 때까지 대기
  WidgetsFlutterBinding.ensureInitialized();

  //URL에서 지저분한 해시를 제거
  // URL에서 # 제거 (예: /#/login-callback → /login-callback)
  usePathUrlStrategy();

  // 모바일에서 딥 링크 서비스 초기화
  if (!kIsWeb) {
    await DeepLinkService.instance.init();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REC::OOK',
      //BuildContext 없이도 어디서든 화면 이동 가능하도록 키 설정
      navigatorKey: ApiService.navigatorKey,
      // High-Saturation & Vibrant 테마: 새로운 오렌지 컬러를 기본 색상으로 설정
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryOrange),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateInitialRoutes: (String initialRoute) {
        // 웹일 경우, 서버가 리다이렉트 시킨 URL 경로를 직접 읽어옴(OAuth2 토큰 유실 방지)
        if (kIsWeb) {
          final path = url_helper.getCurrentPath();
          if (path == '/login-callback' || path.startsWith('/login-callback')) {
            return [
              MaterialPageRoute(builder: (_) => const LoginCallbackPage()),
            ];
          }
        } else {
          // 모바일: 딥 링크로 앱이 시작된 경우 확인
          final initialLink = DeepLinkService.instance.initialLink;
          if (initialLink != null && DeepLinkService.isLoginCallback(initialLink)) {
            return [
              MaterialPageRoute(
                builder: (_) => LoginCallbackPage(initialUri: initialLink),
              ),
            ];
          }
        }
        // 기본 진입: MainNavigation (홈 탭)
        return [
          MaterialPageRoute(builder: (_) => const FontPreloadWrapper(child: MainNavigation(initialIndex: 0))),
        ];
      },
      routes: {
        '/': (context) => const FontPreloadWrapper(child: MainNavigation(initialIndex: 0)),
        '/login-callback': (context) => const LoginCallbackPage(),
        '/login': (context) => const LoginPage(),
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
      'NanumGothicCoding-Regular'
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
