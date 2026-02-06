import 'package:http/http.dart' as http;

/// iOS/Android 플랫폼용 HTTP 클라이언트
http.Client createHttpClient() {
  return http.Client();
}
