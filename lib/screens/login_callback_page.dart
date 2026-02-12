import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/token_service.dart';
import 'main_navigation.dart';

/// OAuth2 로그인 콜백 페이지
///
/// 플랫폼별 처리:
/// - 웹(WEB): accessToken만 URL 파라미터로 받음. refreshToken은 HttpOnly 쿠키로 자동 관리
/// - 앱(MOBILE): accessToken, refreshToken 모두 URL 파라미터로 받아서 secure storage에 저장
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
      debugPrint('OAuth Callback - Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      debugPrint('OAuth Callback - accessToken: ${accessToken != null ? "exists" : "null"}');
      debugPrint('OAuth Callback - refreshToken: ${refreshToken != null ? "exists" : "null"}');

      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = '로그인 정보를 받지 못했습니다.';
        });
        return;
      }

      // accessToken 저장 (공통)
      await TokenService.saveAccessToken(accessToken);

      // refreshToken 처리 (플랫폼별 분기)
      if (kIsWeb) {
        // 웹: refreshToken은 HttpOnly 쿠키로 관리됨
        // 쿠키는 브라우저가 자동으로 API 요청에 포함시킴 (withCredentials: true)
        debugPrint('OAuth Callback - Web: refreshToken managed by HttpOnly cookie');
      } else {
        // 모바일: refreshToken을 URL 파라미터에서 추출하여 secure storage에 저장
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await TokenService.saveRefreshToken(refreshToken);
          debugPrint('OAuth Callback - Mobile: refreshToken saved to secure storage');
        } else {
          // 모바일인데 refreshToken이 없으면 에러
          setState(() {
            _isProcessing = false;
            _errorMessage = '로그인 정보가 불완전합니다.';
          });
          return;
        }
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
