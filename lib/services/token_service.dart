import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_web.dart' if (dart.library.io) 'storage_stub.dart';

class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // AccessToken 저장
  static Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      // 웹: localStorage 사용
      await StorageWeb.setItem(_accessTokenKey, token);
    } else {
      // iOS: Keychain, Android: Keystore 사용
      await _secureStorage.write(key: _accessTokenKey, value: token);
    }
  }

  // AccessToken 불러오기
  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      // 웹: localStorage에서 읽기
      return await StorageWeb.getItem(_accessTokenKey);
    } else {
      // iOS: Keychain, Android: Keystore에서 읽기
      return await _secureStorage.read(key: _accessTokenKey);
    }
  }

  // AccessToken 삭제
  static Future<void> deleteAccessToken() async {
    if (kIsWeb) {
      // 웹: localStorage에서 삭제
      await StorageWeb.removeItem(_accessTokenKey);
    } else {
      // iOS: Keychain, Android: Keystore에서 삭제
      await _secureStorage.delete(key: _accessTokenKey);
    }
  }

  // RefreshToken 저장
  static Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      // 웹: localStorage 사용 (쿠키 아님)
      await StorageWeb.setItem(_refreshTokenKey, token);
    } else {
      // iOS: Keychain, Android: Keystore 사용
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    }
  }

  // RefreshToken 불러오기
  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      // 웹: localStorage에서 읽기
      return await StorageWeb.getItem(_refreshTokenKey);
    } else {
      // iOS: Keychain, Android: Keystore에서 읽기
      return await _secureStorage.read(key: _refreshTokenKey);
    }
  }

  // RefreshToken 삭제
  static Future<void> deleteRefreshToken() async {
    if (kIsWeb) {
      // 웹: localStorage에서 삭제
      await StorageWeb.removeItem(_refreshTokenKey);
    } else {
      // iOS: Keychain, Android: Keystore에서 삭제
      await _secureStorage.delete(key: _refreshTokenKey);
    }
  }

  // User Role 저장
  static Future<void> saveUserRole(String role) async {
    if (kIsWeb) {
      // 웹: localStorage 사용
      await StorageWeb.setItem(_userRoleKey, role);
    } else {
      // iOS: Keychain, Android: Keystore 사용
      await _secureStorage.write(key: _userRoleKey, value: role);
    }
  }

  // User Role 불러오기
  static Future<String?> getUserRole() async {
    if (kIsWeb) {
      // 웹: localStorage에서 읽기
      return await StorageWeb.getItem(_userRoleKey);
    } else {
      // iOS: Keychain, Android: Keystore에서 읽기
      return await _secureStorage.read(key: _userRoleKey);
    }
  }

  // User Role 삭제
  static Future<void> deleteUserRole() async {
    if (kIsWeb) {
      // 웹: localStorage에서 삭제
      await StorageWeb.removeItem(_userRoleKey);
    } else {
      // iOS: Keychain, Android: Keystore에서 삭제
      await _secureStorage.delete(key: _userRoleKey);
    }
  }

  // 로그아웃 (모든 토큰 삭제)
  static Future<void> clearTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUserRole();
  }
}

