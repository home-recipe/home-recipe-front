import 'package:flutter/material.dart';
import '../services/token_service.dart';
import 'main_navigation.dart';

/// OAuth2 로그인 콜백 페이지
/// 서버에서 https://recook.kr/login-callback?accessToken=xxx&refreshToken=xxx 형태로 리다이렉트하면
/// 이 페이지에서 토큰을 파싱하여 저장하고 메인 화면으로 이동합니다.
class LoginCallbackPage extends StatefulWidget {
  const LoginCallbackPage({super.key});

  @override
  State<LoginCallbackPage> createState() => _LoginCallbackPageState();
}

class _LoginCallbackPageState extends State<LoginCallbackPage> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  Future<void> _processCallback() async {
    try {
      // 현재 URL에서 쿼리 파라미터 추출
      final uri = Uri.base;
      final accessToken = uri.queryParameters['accessToken'];
      final refreshToken = uri.queryParameters['refreshToken'];

      debugPrint('OAuth Callback - URI: ${uri.toString()}');
      debugPrint('OAuth Callback - accessToken: ${accessToken != null ? "exists" : "null"}');
      debugPrint('OAuth Callback - refreshToken: ${refreshToken != null ? "exists" : "null"}');

      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = '로그인 정보를 받지 못했습니다.';
        });
        return;
      }

      // 토큰 저장
      await TokenService.saveAccessToken(accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await TokenService.saveRefreshToken(refreshToken);
      }

      // 기본 사용자 역할 저장 (서버에서 role도 전달한다면 추가 가능)
      await TokenService.saveUserRole('USER');

      if (!mounted) return;

      // 메인 화면으로 이동 (뒤로가기 방지)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 2)),
        (_) => false,
      );
    } catch (e) {
      debugPrint('OAuth Callback Error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = '로그인 처리 중 오류가 발생했습니다.';
        });
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81B29A)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '로그인 처리 중...',
                    style: TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage ?? '오류가 발생했습니다.',
                    style: const TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                      fontSize: 16,
                      color: Color(0xFF2C2C2C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _goToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81B29A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '로그인 화면으로 돌아가기',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
