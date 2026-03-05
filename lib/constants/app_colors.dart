import 'dart:ui';

/// 앱 전체에서 사용하는 색상 상수
/// High-Saturation & Vibrant 테마 적용
class AppColors {
  // Primary Colors - 높은 채도의 생생한 컬러
  /// 메인 레드 컬러 (#f21d1d) - 버튼, 강조 요소에 사용
  static const primaryOrange = Color(0xFFF21D1D);

  /// 메인 그린 컬러 (#19E619) - 성공, 아이콘, 보조 강조에 사용
  static const primaryGreen = Color(0xFF19E619);

  // Accent Colors - 추가 강조 컬러
  /// 액센트 옐로우 (Material Yellow A700) - 배지, 하이라이트에 사용
  static const accentYellow = Color(0xFFFFEA00);

  /// 액센트 핑크 (Material Red A400) - 알림, 중요 강조에 사용
  static const accentPink = Color(0xFFFF1744);

  // Text Colors - 가독성을 위한 텍스트 컬러
  /// 진한 텍스트 (Material Grey 900) - 제목, 본문 텍스트에 사용
  static const textDark = Color(0xFF212121);

  /// 중간 톤 텍스트 (Material Grey 700) - 보조 텍스트, 설명에 사용
  static const textGrey = Color(0xFF616161);

  // Background Colors - 깔끔한 배경
  /// 순백 배경 - 카드, 컨테이너 배경에 사용
  static const backgroundWhite = Color(0xFFFFFFFF);

  /// 밝은 배경 (Material Grey 50) - 기본 화면 배경에 사용
  static const backgroundLight = Color(0xFFF5F5F5);

  /// 베이지 배경 - 특정 섹션 배경에 사용 (기존 유지)
  static const backgroundBeige = Color(0xFFF2EFEB);

  // Logo & Outline Colors - 로고 및 테두리 컬러
  /// 로고 아웃라인 (Blue Grey 900) - 선명한 대비를 위한 진한 컬러
  static const logoOutline = Color(0xFF263238);

  // Shadow Colors - 그림자 효과
  /// 기본 그림자 - 카드 및 요소에 사용
  static const shadowLight = Color(0x1A000000);

  // Gradient Colors - 그라데이션 효과용
  /// Red 그라데이션 시작색 (REC:: 부분)
  static const gradientOrangeStart = primaryOrange; // #F21D1D

  /// Red 그라데이션 종료색 (REC:: 부분) - 밝은 레드
  static const gradientOrangeEnd = Color(0xFFFF4444); // #FF4444

  /// Green 그라데이션 시작색 (OOK 부분)
  static const gradientGreenStart = primaryGreen; // #19E619

  /// Green 그라데이션 종료색 (OOK 부분) - Material Green A700
  static const gradientGreenEnd = Color(0xFF00BFA5);

  // Private constructor to prevent instantiation
  AppColors._();
}
