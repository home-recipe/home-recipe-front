import 'package:http/http.dart' as http;

/// 스텁 구현 - 조건부 import의 기본값
http.Client createHttpClient() =>
    throw UnsupportedError('Cannot create a HTTP client without dart:html or dart:io');
