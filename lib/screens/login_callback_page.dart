import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/deep_link_service.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';
import '../utils/url_helper.dart';
import '../constants/app_colors.dart';

/// OAuth2 로그인 콜백 페이지 (PKCE 방식)
///
/// 서버로부터 authorization code만 URL 파라미터로 수신하고,
/// code + code_verifier를 서버에 전송하여 토큰을 JSON으로 교환한다.
/// - 웹(WEB): refreshToken은 서버가 HttpOnly 쿠키로 세팅
/// - 앱(MOBILE): accessToken + refreshToken 모두 Secure Storage에 저장
class LoginCallbackPage extends StatefulWidget {
  /// 앱이 딥 링크로 시작된 경우의 초기 URI
  final Uri? initialUri;

  const LoginCallbackPage({super.key, this.initialUri});

  @override
  State<LoginCallbackPage> createState() => _LoginCallbackPageState();
}

class _LoginCallbackPageState extends State<LoginCallbackPage> {
  bool _isProcessing = true;
  String? _errorMessage;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _processCallback() async {
    try {
      Uri? uri;

      if (kIsWeb) {
        // 웹 브라우저의 주소 가져오기
        final currentUrl = getFullUrl();
        if (currentUrl.isEmpty) {
          throw Exception('URL 정보를 가져올 수 없습니다.');
        }
        uri = Uri.parse(currentUrl);
        debugPrint('Web Browser URL: $currentUrl');
      } else {
        // 모바일: 딥 링크에서 URI 가져오기
        if (widget.initialUri != null) {
          // 앱이 딥 링크로 시작된 경우
          uri = widget.initialUri;
          debugPrint('Mobile Deep Link (initial): $uri');
        } else {
          // 앱이 이미 실행 중일 때 딥 링크가 들어온 경우 - 스트림에서 대기
          debugPrint('Mobile: Waiting for deep link...');
          final completer = Completer<Uri>();

          _deepLinkSubscription = DeepLinkService.instance.deepLinkStream.listen(
            (Uri incomingUri) {
              if (DeepLinkService.isLoginCallback(incomingUri) && !completer.isCompleted) {
                completer.complete(incomingUri);
              }
            },
          );

          // 10초 타임아웃
          uri = await completer.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('딥 링크 대기 시간이 초과되었습니다.'),
          );
          debugPrint('Mobile Deep Link (stream): $uri');
        }
      }

      if (uri == null) {
        throw Exception('URL 정보를 가져올 수 없습니다.');
      }

      final code = uri.queryParameters['code'];
      // 구버전 서버가 accessToken을 URL에 직접 노출하는 경우 감지 (보안 위험)
      final legacyAccessToken = uri.queryParameters['accessToken'];

      debugPrint('OAuth Callback - URI: ${uri.toString()}');
      debugPrint('OAuth Callback - Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      debugPrint('OAuth Callback - code: ${code != null ? "exists" : "null"}');

      // 구버전 로직 감지: accessToken이 URL에 직접 노출된 경우
      if (legacyAccessToken != null && legacyAccessToken.isNotEmpty) {
        debugPrint('⚠️ 보안 경고: 서버가 구버전 로직(URL에 accessToken 노출)으로 동작 중입니다.');
        debugPrint('⚠️ 서버의 OAuth 핸들러를 PKCE 방식으로 업데이트해야 합니다.');
        debugPrint('⚠️ 서버가 redirect 시 ?code=xxx 형태로 authorization code만 전달해야 합니다.');
        setState(() {
          _isProcessing = false;
          _errorMessage = '서버가 구버전 인증 방식으로 응답했습니다.\n'
              '서버의 OAuth 핸들러를 PKCE 방식으로 업데이트해주세요.\n'
              '(accessToken이 URL에 직접 노출되어 보안 위험이 있습니다)';
        });
        return;
      }

      if (code == null || code.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = '인증 코드를 받지 못했습니다.\n'
              '서버가 authorization code를 반환하는지 확인해주세요.';
        });
        return;
      }

      // authorization code → 토큰 교환
      await AuthService.exchangeCodeForTokens(code);

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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
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
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _goToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
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
