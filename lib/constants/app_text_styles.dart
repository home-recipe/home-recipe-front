import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 전체에서 사용하는 텍스트 스타일
/// High-Saturation & Vibrant 테마의 컬러 시스템 적용
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
    color: AppColors.textDark,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
  
  // 본문 스타일
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
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
