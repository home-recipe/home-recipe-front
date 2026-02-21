import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_web.dart' if (dart.library.io) 'storage_stub.dart';

class PkceService {
  static const String _codeVerifierKey = 'pkce_code_verifier';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 128자 무작위 code_verifier 생성
  static String generateCodeVerifier() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// code_verifier를 SHA-256 해싱 후 base64url 인코딩하여 code_challenge 생성
  static String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// code_verifier 저장
  static Future<void> saveCodeVerifier(String verifier) async {
    if (kIsWeb) {
      await StorageWeb.setItem(_codeVerifierKey, verifier);
    } else {
      await _secureStorage.write(key: _codeVerifierKey, value: verifier);
    }
  }

  /// 저장된 code_verifier 조회
  static Future<String?> getCodeVerifier() async {
    if (kIsWeb) {
      return await StorageWeb.getItem(_codeVerifierKey);
    } else {
      return await _secureStorage.read(key: _codeVerifierKey);
    }
  }

  /// 사용 후 code_verifier 삭제
  static Future<void> deleteCodeVerifier() async {
    if (kIsWeb) {
      await StorageWeb.removeItem(_codeVerifierKey);
    } else {
      await _secureStorage.delete(key: _codeVerifierKey);
    }
  }
}
