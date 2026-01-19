import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'main_navigation.dart';
import '../models/login_request.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

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
      // role은 이미 ApiService.login()에서 LoginResponse로부터 저장됨
      if (response.code == 200) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 2)),
          (_) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      debugPrint('로그인 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 타이틀 - REC::OOK 스타일
                _buildRecookTitle(),
                const SizedBox(height: 80),

                // 로그인 폼 컨테이너 - 적당한 크기로 중앙 배치
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: DefaultTextStyle(
                        style: const TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C2C2C),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(28.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF81B29A).withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFFE07A5F).withValues(alpha: 0.1),
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
                              const SizedBox(height: 32),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _handleSignUp,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF81B29A),
                                      textStyle: const TextStyle(
                                        fontFamily: 'NanumGothicCoding-Regular',
                                        letterSpacing: 0.5,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('회원가입'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE07A5F),
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontFamily: 'NanumGothicCoding-Regular',
                                        letterSpacing: 0.5,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 36,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 3,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text('로그인'),
                                  ),
                                ],
                              ),
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
  Widget _buildRecookTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // REC::
        _buildStyledText('REC::', const Color(0xFFE07A5F)),
        // OOK
        _buildStyledText('OOK', const Color(0xFF81B29A)),
      ],
    );
  }

  // 스타일이 적용된 텍스트 위젯 (outline 포함)
  Widget _buildStyledText(String text, Color fillColor) {
    const outlineColor = Color(0xFF8B4513); // Rust brown outline
    const fontSize = 60.0;
    const outlineWidth = 3.0;
    
    return Stack(
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
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: outlineColor,
                letterSpacing: 1.0,
                fontFamily: 'Arial',
              ),
            ),
          );
        }),
        // Main text (앞에 그려짐)
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: fillColor,
            letterSpacing: 1.0,
            fontFamily: 'Arial',
          ),
        ),
      ],
    );
  }

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
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
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
            color: Color(0xFF2C2C2C),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF81B29A), size: 22),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF81B29A),
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

