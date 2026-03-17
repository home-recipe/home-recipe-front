import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_recipe_front/screens/login_callback_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'signup_page.dart';
import 'main_navigation.dart';
import '../models/login_request.dart';
import '../services/api_service.dart';
import '../services/pkce_service.dart';
import '../config/env_config.dart';
import '../utils/url_helper.dart' as url_helper;
import '../constants/app_colors.dart';


//LoginPage는 상태를 가질 수 있는 화면 위젯이고,
//실제 상태관리와 UI 갱신은 _LoginPageState가 담당한다.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  //부모클래스의 메서드를 내가 재정의 하겠다.
  //상태는 _LoginPageState가 관리함으로 정의
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _idFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  //회원가입 버튼 클릭 시 회원가입 페이지로 이동
  void _handleSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  //로그인 버튼 클릭 시 로그인 요청 처리
  Future<void> _handleLogin() async {
    if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    // 로딩 중이면 중복 요청 방지
    if (_isLoading) {
      return;
    }

    //State상태가 바뀌었으니 UI 다시 그리라고 알리는 함수
    setState(() {
      _isLoading = true;
    });

    try {
      final request = LoginRequest(
        email: _idController.text.trim(),
        password: _passwordController.text,
      );

      final response = await ApiService.login(request);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // HTTP 상태 코드가 200이면 성공
      if (response.code == 200) {
        // 로그인 성공 후 MainNavigation으로 이동 (홈 탭)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 0)),
          (_) => false,
        );
      } else {
        // 로그인 실패 시 에러 메시지 표시
        final errorMessage = response.message.isNotEmpty 
            ? response.message 
            : '로그인에 실패했습니다. 다시 시도해주세요.';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      
      debugPrint('로그인 오류: $e');
      
      // 예외 발생 시 사용자에게 알림
      final errorMessage = e.toString().contains('Exception') 
          ? e.toString().replaceAll('Exception: ', '')
          : '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      // Vibrant 테마: 배경색을 앱 컬러로 통일
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 타이틀 - REC::OOK 스타일 (클릭 시 새로고침)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    child: _buildRecookTitle(),
                  ),
                ),
                const SizedBox(height: 40),

                // 로그인 폼 컨테이너 - 적당한 크기로 중앙 배치
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: DefaultTextStyle(
                        // 기본 텍스트 스타일: Vibrant 테마의 진한 텍스트 컬러 사용
                        style: const TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(28.0),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(24),
                            // Vibrant 테마: Green과 Orange 그림자로 깊이감 표현
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: AppColors.primaryOrange.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: _idController,
                                focusNode: _idFocusNode,
                                label: '이메일',
                                hintText: '이메일을 입력하세요',
                                icon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) {
                                  FocusScope.of(context)
                                      .requestFocus(_passwordFocusNode);
                                },
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                label: '비밀번호',
                                hintText: '비밀번호를 입력하세요',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleLogin(),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // 회원가입 버튼: Vibrant 테마의 그린 컬러 사용
                                  TextButton(
                                    onPressed: _handleSignUp,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primaryGreen,
                                      textStyle: const TextStyle(
                                        fontFamily: 'NanumGothicCoding-Regular',
                                        letterSpacing: 0.3,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('회원가입'),
                                  ),
                                  // 로그인 버튼: Vibrant 테마의 오렌지 컬러 사용
                                  TextButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primaryOrange,
                                      textStyle: const TextStyle(
                                        fontFamily: 'NanumGothicCoding-Regular',
                                        letterSpacing: 0.3,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 14,
                                            width: 14,
                                            // 로딩 인디케이터: 오렌지 컬러
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                                            ),
                                          )
                                        : const Text('로그인'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              // 구분선
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '또는',
                                      style: TextStyle(
                                        fontFamily: 'NanumGothicCoding-Regular',
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // 소셜 로그인 버튼들
                              _buildGoogleLoginButton(),
                              const SizedBox(height: 12),
                              _buildKakaoLoginButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // REC::OOK 스타일 타이틀 위젯
  // Vibrant 테마: 그라데이션 효과가 적용된 로고 사용
  // FittedBox로 감싸서 모바일에서 overflow 방지
  Widget _buildRecookTitle() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // REC:: - Orange → Pink 그라데이션
          _buildStyledText(
            'REC::',
            useGradient: true,
            gradientColors: const [
              AppColors.gradientOrangeStart,
              AppColors.gradientOrangeEnd,
            ],
          ),
          // OOK - Green 그라데이션
          _buildStyledText(
            'OOK',
            useGradient: true,
            gradientColors: const [
              AppColors.gradientGreenStart,
              AppColors.gradientGreenEnd,
            ],
          ),
        ],
      ),
    );
  }

  // 스타일이 적용된 텍스트 위젯 (outline 및 그라데이션 포함)
  Widget _buildStyledText(
    String text, {
    Color? fillColor,
    bool useGradient = false,
    List<Color>? gradientColors,
  }) {
    // Vibrant 테마: 로고 아웃라인을 선명한 Blue Grey 900으로 변경
    const outlineColor = AppColors.logoOutline;
    const fontSize = 60.0;
    const outlineWidth = 3.0;
    const padding = outlineWidth + 2.0; // 테두리 여유 공간 확보

    return Padding(
      padding: const EdgeInsets.all(padding),
      child: Stack(
        clipBehavior: Clip.none, // 테두리가 잘리지 않도록 설정
        children: [
          // Outline (뒤에 그려짐) - 여러 방향으로 offset하여 outline 효과 생성
          ...List.generate(8, (index) {
            final angle = (index * 2 * math.pi) / 8;
            final offsetX = outlineWidth * math.cos(angle);
            final offsetY = outlineWidth * math.sin(angle);
            return Positioned(
              left: offsetX,
              top: offsetY,
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: outlineColor,
                  letterSpacing: 1.0,
                  fontFamily: 'Arial',
                ),
              ),
            );
          }),
          // Main text (앞에 그려짐) - 그라데이션 또는 단색
          useGradient && gradientColors != null && gradientColors.length >= 2
              ? ShaderMask(
                  // 그라데이션 효과 적용
                  shaderCallback: (bounds) => LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white, // ShaderMask를 위한 베이스 컬러
                      letterSpacing: 1.0,
                      fontFamily: 'Arial',
                    ),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: fillColor ?? AppColors.primaryOrange,
                    letterSpacing: 1.0,
                    fontFamily: 'Arial',
                  ),
                ),
        ],
      ),
    );
  }

  // OAuth2 로그인 처리 (PKCE 적용)
  Future<void> _handleOAuthLogin(String provider) async {
    // PKCE: code_verifier 생성 → code_challenge 생성 → verifier 저장
    final codeVerifier = PkceService.generateCodeVerifier();
    final codeChallenge = PkceService.generateCodeChallenge(codeVerifier);
    await PkceService.saveCodeVerifier(codeVerifier);

    final String url;
    if (provider == 'google') {
      url = EnvConfig.googleOAuthUrl(codeChallenge);
    } else if (provider == 'kakao') {
      url = EnvConfig.kakaoOAuthUrl(codeChallenge);
    } else {
      return;
    }

    // 웹에서는 redirectTo() 후 콘솔이 초기화되므로 debugPrint 사용
    debugPrint("=======================================");
    debugPrint("🔥 OAuth 요청 URL: $url");
    debugPrint("🔑 생성된 Challenge: $codeChallenge");
    debugPrint("🔒 code_verifier 저장 완료");
    debugPrint("📌 서버는 redirect 시 ?code=xxx 형태로 authorization code만 반환해야 함");
    debugPrint("📌 서버가 ?accessToken=ey... 형태로 반환하면 구버전 로직이므로 서버 수정 필요");
    debugPrint("=======================================");
    
    try {
      if(kIsWeb) {
        url_helper.redirectTo(url);
        return;
      }

      final uri = Uri.parse(url);
      if(await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if(mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LoginCallbackPage(),
            ),
          );
        } else {
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
              content: Text('브라우저를 열 수 없습니다.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('OAuth2 로그인 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('로그인 페이지를 열 수 없습니다.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // 구글 로그인 버튼
  // 구글 브랜드 컬러는 변경하지 않음 (브랜드 가이드라인 준수)
  Widget _buildGoogleLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: () => _handleOAuthLogin('google'),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.backgroundWhite,
          side: BorderSide(color: Colors.grey.shade300, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 구글 로고 - 브랜드 컬러 유지
            Text(
              'G',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.0,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [
                      Color(0xFF4285F4), // Google Blue
                      Color(0xFFEA4335), // Google Red
                      Color(0xFFFBBC05), // Google Yellow
                      Color(0xFF34A853), // Google Green
                    ],
                    stops: [0.0, 0.33, 0.66, 1.0],
                  ).createShader(const Rect.fromLTWH(0, 0, 18, 18)),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Google로 계속하기',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.3,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카카오 로그인 버튼
  // 카카오 브랜드 컬러는 변경하지 않음 (브랜드 가이드라인 준수)
  Widget _buildKakaoLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () => _handleOAuthLogin('kakao'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500), // 카카오 노란색 (브랜드 컬러 유지)
          foregroundColor: const Color(0xFF191919), // 카카오 검정색 (브랜드 컬러 유지)
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 카카오 말풍선 아이콘
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CustomPaint(
                  painter: KakaoIconPainter(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '카카오로 계속하기',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.3,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191919),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 텍스트 필드 위젯
  // Vibrant 테마: 새로운 컬러 시스템 적용
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨: 진한 텍스트 컬러 사용
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            // 아이콘: Vibrant 그린 컬러 사용
            prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 22),
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            // 포커스 시: Vibrant 그린 컬러로 테두리 강조
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryGreen,
                width: 2.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// 카카오 말풍선 아이콘 페인터
class KakaoIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3C1E1E)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();

    // 말풍선 본체 (둥근 사각형 느낌의 타원)
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.6),
        Radius.circular(w * 0.35),
      ),
    );

    // 말풍선 꼬리 (왼쪽 아래)
    final tailPath = Path();
    tailPath.moveTo(w * 0.25, h * 0.6);
    tailPath.lineTo(w * 0.15, h * 0.85);
    tailPath.lineTo(w * 0.45, h * 0.65);
    tailPath.close();

    path.addPath(tailPath, Offset.zero);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

