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
          // 로그인 폼
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 앱 타이틀
                    const Text(
                      '냉장고 프로젝트',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        fontSize: 50,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2C2C),
                        shadows: [
                          Shadow(
                            color: Colors.white,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
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
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: const Color(0xCCF2EFEB),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
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
                                      textStyle: const TextStyle(
                                        fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: const Text('회원가입'),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDEAE71),
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
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
        ],
      ),
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
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
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
              fontSize: 16,
            ),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2C2C2C),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

