import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../screens/main_navigation.dart';

/// REC::OOK 로고 위젯
/// 클릭 시 My 화면으로 이동
class RecookLogo extends StatelessWidget {
  final double fontSize;
  final double outlineWidth;
  final double letterSpacing;

  const RecookLogo({
    super.key,
    this.fontSize = 32.0,
    this.outlineWidth = 2.0,
    this.letterSpacing = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainNavigation(initialIndex: 2),
            ),
            (route) => false,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StyledLogoText(
              text: 'REC::',
              fillColor: const Color(0xFFE07A5F),
              fontSize: fontSize,
              outlineWidth: outlineWidth,
              letterSpacing: letterSpacing,
            ),
            _StyledLogoText(
              text: 'OOK',
              fillColor: const Color(0xFF81B29A),
              fontSize: fontSize,
              outlineWidth: outlineWidth,
              letterSpacing: letterSpacing,
            ),
          ],
        ),
      ),
    );
  }
}

/// 스타일이 적용된 로고 텍스트 위젯 (outline 포함)
class _StyledLogoText extends StatelessWidget {
  final String text;
  final Color fillColor;
  final double fontSize;
  final double outlineWidth;
  final double letterSpacing;

  const _StyledLogoText({
    required this.text,
    required this.fillColor,
    required this.fontSize,
    required this.outlineWidth,
    required this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    const outlineColor = Color(0xFF8B4513);

    return Stack(
      children: [
        // Outline
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
        // Main text
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: fillColor,
            letterSpacing: letterSpacing,
            fontFamily: 'Arial',
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

/// 로그인 페이지용 큰 타이틀 로고
class RecookTitle extends StatelessWidget {
  const RecookTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StyledLogoText(
          text: 'REC::',
          fillColor: const Color(0xFFE07A5F),
          fontSize: 60.0,
          outlineWidth: 3.0,
          letterSpacing: 1.0,
        ),
        _StyledLogoText(
          text: 'OOK',
          fillColor: const Color(0xFF81B29A),
          fontSize: 60.0,
          outlineWidth: 3.0,
          letterSpacing: 1.0,
        ),
      ],
    );
  }
}
