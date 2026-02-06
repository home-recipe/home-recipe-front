import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

/// 웹 플랫폼용 HTTP 클라이언트
http.Client createHttpClient() {
  return BrowserClient()..withCredentials = true;
}
