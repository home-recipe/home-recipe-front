import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

/// Deep Link 서비스
///
/// 앱 링크 및 딥 링크를 처리합니다.
/// - Custom Scheme: recook://login-callback?code=xxx
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService _instance = DeepLinkService._();
  static DeepLinkService get instance => _instance;

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// 딥 링크 이벤트 스트림
  final StreamController<Uri> _deepLinkController = StreamController<Uri>.broadcast();
  Stream<Uri> get deepLinkStream => _deepLinkController.stream;

  /// 초기 딥 링크 (앱이 딥 링크로 시작된 경우)
  Uri? _initialLink;
  Uri? get initialLink => _initialLink;

  /// 딥 링크 서비스 초기화
  Future<void> init() async {
    // 웹에서는 딥 링크 처리 불필요 (URL에서 직접 파싱)
    if (kIsWeb) return;

    _appLinks = AppLinks();

    // 앱이 딥 링크로 시작된 경우 초기 링크 가져오기
    try {
      _initialLink = await _appLinks!.getInitialLink();
      if (_initialLink != null) {
        debugPrint('DeepLinkService: Initial link received: $_initialLink');
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error getting initial link: $e');
    }

    // 앱이 실행 중일 때 들어오는 딥 링크 수신
    _linkSubscription = _appLinks!.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('DeepLinkService: Link received: $uri');
        _deepLinkController.add(uri);
      },
      onError: (error) {
        debugPrint('DeepLinkService: Error receiving link: $error');
      },
    );
  }

  /// 딥 링크가 로그인 콜백인지 확인
  static bool isLoginCallback(Uri uri) {
    // Custom scheme: recook://login-callback
    final path = uri.path.isEmpty ? uri.host : uri.path;
    return path == 'login-callback' ||
           path == '/login-callback' ||
           uri.toString().contains('login-callback');
  }

  /// URI에서 authorization code 추출
  static String? extractCode(Uri uri) {
    return uri.queryParameters['code'];
  }

  /// 서비스 정리
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}
