import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// REC::OOK 로고 위젯
/// onTap 콜백이 제공되면 클릭 가능한 로고가 됨
/// High-Saturation & Vibrant 테마: 그라데이션 효과 적용
class RecookLogo extends StatelessWidget {
  final double fontSize;
  final double outlineWidth;
  final double letterSpacing;
  final VoidCallback? onTap;  // 선택적 탭 콜백

  const RecookLogo({
    super.key,
    this.fontSize = 32.0,
    this.outlineWidth = 2.0,
    this.letterSpacing = 0.5,
    this.onTap,  // 선택적 파라미터
  });

  @override
  Widget build(BuildContext context) {
    // 로고 Row 위젯
    final logoRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // REC:: 부분 - Orange → Pink 그라데이션
        _StyledLogoText(
          text: 'REC::',
          useGradient: true,
          gradientColors: const [
            AppColors.gradientOrangeStart, // #FC5603
            AppColors.gradientOrangeEnd,   // #FF1744
          ],
          fontSize: fontSize,
          outlineWidth: outlineWidth,
          letterSpacing: letterSpacing,
        ),
        // OOK 부분 - Green 그라데이션
        _StyledLogoText(
          text: 'OOK',
          useGradient: true,
          gradientColors: const [
            AppColors.gradientGreenStart, // #19E619
            AppColors.gradientGreenEnd,   // #00BFA5
          ],
          fontSize: fontSize,
          outlineWidth: outlineWidth,
          letterSpacing: letterSpacing,
        ),
      ],
    );

    // onTap이 제공된 경우에만 클릭 가능하게 래핑
    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: logoRow,
        ),
      );
    }

    // onTap이 없으면 로고만 반환
    return logoRow;
  }
}

/// 스타일이 적용된 로고 텍스트 위젯 (outline 및 그라데이션 포함)
/// useGradient=true일 경우 그라데이션 효과 적용
class _StyledLogoText extends StatelessWidget {
  final String text;
  final Color? fillColor; // 단색일 때 사용
  final bool useGradient; // 그라데이션 사용 여부
  final List<Color>? gradientColors; // 그라데이션 컬러 리스트
  final double fontSize;
  final double outlineWidth;
  final double letterSpacing;

  const _StyledLogoText({
    required this.text,
    this.fillColor,
    this.useGradient = false,
    this.gradientColors,
    required this.fontSize,
    required this.outlineWidth,
    required this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    // 로고 아웃라인 컬러 - 선명한 대비를 위해 Blue Grey 900 사용
    const outlineColor = AppColors.logoOutline; // #263238
    final padding = outlineWidth + 2.0; // 테두리 여유 공간 확보

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Stack(
        clipBehavior: Clip.none, // 테두리가 잘리지 않도록 설정
        children: [
          // Outline - 8방향으로 offset하여 테두리 효과 생성
          ...List.generate(8, (index) {
            final angle = (index * 2 * math.pi) / 8;
            final offsetX = outlineWidth * math.cos(angle);
            final offsetY = outlineWidth * math.sin(angle);
            return Positioned(
              left: offsetX,
              top: offsetY,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: outlineColor,
                  letterSpacing: letterSpacing,
                  fontFamily: 'Arial',
                  height: 1.0,
                ),
              ),
            );
          }),
          // Main text - 그라데이션 또는 단색
          useGradient && gradientColors != null && gradientColors!.length >= 2
              ? ShaderMask(
                  // 그라데이션 효과 적용
                  shaderCallback: (bounds) => LinearGradient(
                    colors: gradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white, // ShaderMask를 위한 베이스 컬러
                      letterSpacing: letterSpacing,
                      fontFamily: 'Arial',
                      height: 1.0,
                    ),
                  ),
                )
              : Text(
                  // 단색 텍스트
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: fillColor ?? AppColors.primaryOrange,
                    letterSpacing: letterSpacing,
                    fontFamily: 'Arial',
                    height: 1.0,
                  ),
                ),
        ],
      ),
    );
  }
}

/// 로그인 페이지용 큰 타이틀 로고
/// High-Saturation & Vibrant 테마: 그라데이션 효과 적용
class RecookTitle extends StatelessWidget {
  const RecookTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // REC:: 부분 - Orange → Pink 그라데이션
        _StyledLogoText(
          text: 'REC::',
          useGradient: true,
          gradientColors: const [
            AppColors.gradientOrangeStart, // #FF5722
            AppColors.gradientOrangeEnd,   // #FF1744
          ],
          fontSize: 60.0,
          outlineWidth: 3.0,
          letterSpacing: 1.0,
        ),
        // OOK 부분 - Green 그라데이션
        _StyledLogoText(
          text: 'OOK',
          useGradient: true,
          gradientColors: const [
            AppColors.gradientGreenStart, // #00E676
            AppColors.gradientGreenEnd,   // #00BFA5
          ],
          fontSize: 60.0,
          outlineWidth: 3.0,
          letterSpacing: 1.0,
        ),
      ],
    );
  }
}
