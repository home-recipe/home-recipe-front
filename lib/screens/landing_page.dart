import 'package:flutter/material.dart';
import '../widgets/landing/hero_section.dart';

/// 서비스 소개 랜딩 페이지
/// 앱의 홈 탭에 표시되는 첫 화면
class LandingPage extends StatelessWidget {
  final VoidCallback? onMyPressed;
  final VoidCallback? onRecommendPressed;

  const LandingPage({
    super.key,
    this.onMyPressed,
    this.onRecommendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: HeroSection(),
    );
  }
}
