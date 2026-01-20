import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 텍스트 스타일
class AppTextStyles {
  // 기본 폰트 설정
  static const String fontFamily = 'NanumGothicCoding-Regular';
  static const double letterSpacing = 0.5;
  
  // 제목 스타일
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2C2C2C),
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Color(0xFF2C2C2C),
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Color(0xFF2C2C2C),
  );
  
  // 본문 스타일
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF2C2C2C),
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF2C2C2C),
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF2C2C2C),
  );
  
  // 버튼 스타일
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  // Private constructor to prevent instantiation
  AppTextStyles._();
}
