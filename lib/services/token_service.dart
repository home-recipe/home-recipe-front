import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// 웹에서만 사용하는 import (조건부)
import 'storage_web.dart' if (dart.library.io) 'storage_stub.dart';

class TokenService {
  static const String _accessTokenKey = 'access_token';

  // AccessToken 저장
  static Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      // 웹: 브라우저 localStorage 사용
      await StorageWeb.setItem(_accessTokenKey, token);
    } else {
      // 모바일/태블릿: SharedPreferences 사용
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    }
  }

  // AccessToken 불러오기
  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      // 웹: 브라우저 localStorage 사용
      return await StorageWeb.getItem(_accessTokenKey);
    } else {
      // 모바일/태블릿: SharedPreferences 사용
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
  }

  // AccessToken 삭제
  static Future<void> deleteAccessToken() async {
    if (kIsWeb) {
      // 웹: 브라우저 localStorage 사용
      await StorageWeb.removeItem(_accessTokenKey);
    } else {
      // 모바일/태블릿: SharedPreferences 사용
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
    }
  }

  // 로그아웃 (모든 토큰 삭제)
  static Future<void> clearTokens() async {
    await deleteAccessToken();
  }
}

