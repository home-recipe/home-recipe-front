import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/landing/hero_section.dart';
import '../widgets/landing/feature_card.dart';
import '../widgets/landing/animated_section.dart';
import '../widgets/landing/value_proposition_section.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Container(
      color: AppColors.backgroundWhite,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section - 메인 배너 영역 (배경 이미지 슬라이더)
            const HeroSection(),

            const SizedBox(height: 40),

            // Value Proposition Section - My/추천 기능 소개 카드
            ValuePropositionSection(
              onMyPressed: onMyPressed ?? () {},
              onRecommendPressed: onRecommendPressed ?? () {},
            ),

            // Feature Section - 핵심 기능 소개
            _buildFeatureSection(isWide),

            // Footer Section - 간단한 서비스 정보
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  /// 핵심 기능 소개 섹션
  Widget _buildFeatureSection(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isWide ? 80 : 60,
        horizontal: 24,
      ),
      color: AppColors.backgroundLight,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // 섹션 제목
              AnimatedSection(
                delay: const Duration(milliseconds: 100),
                child: Column(
                  children: [
                    Text(
                      '이런 기능들을 제공해요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWide ? 32 : 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'REC::OOK이 제공하는 편리한 기능들을 살펴보세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWide ? 16 : 14,
                        color: AppColors.textGrey,
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isWide ? 56 : 40),

              // 기능 카드들 (그리드 레이아웃)
              _buildFeatureGrid(isWide),
            ],
          ),
        ),
      ),
    );
  }

  /// 기능 카드 그리드
  Widget _buildFeatureGrid(bool isWide) {
    final features = [
      {
        'icon': Icons.kitchen,
        'title': '재료 기반 레시피 추천',
        'description': '냉장고 속 재료만 입력하면 만들 수 있는 레시피를 즉시 추천해드려요',
        'delay': 200,
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'AI 맞춤 추천',
        'description': 'AI가 당신의 취향을 학습하여 딱 맞는 레시피를 추천합니다',
        'delay': 400,
      },
      {
        'icon': Icons.bookmark,
        'title': '나만의 레시피 저장',
        'description': '좋아하는 레시피를 저장하고 관리하여 언제든 다시 찾아보세요',
        'delay': 600,
      },
    ];

    if (isWide) {
      // 웹: 3열 그리드
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: features
            .map((feature) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AnimatedSection(
                      delay: Duration(milliseconds: feature['delay'] as int),
                      child: FeatureCard(
                        icon: feature['icon'] as IconData,
                        title: feature['title'] as String,
                        description: feature['description'] as String,
                      ),
                    ),
                  ),
                ))
            .toList(),
      );
    } else {
      // 모바일: 1열 리스트
      return Column(
        children: features
            .map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AnimatedSection(
                    delay: Duration(milliseconds: feature['delay'] as int),
                    child: FeatureCard(
                      icon: feature['icon'] as IconData,
                      title: feature['title'] as String,
                      description: feature['description'] as String,
                    ),
                  ),
                ))
            .toList(),
      );
    }
  }

  /// 푸터 섹션
  Widget _buildFooterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 24,
      ),
      color: AppColors.backgroundWhite,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // 서비스 설명
              Text(
                'REC::OOK',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '냉장고 속 재료로 만드는 맞춤 레시피 추천 서비스',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),

              // 저작권 정보
              Text(
                '© 2026 REC::OOK. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey.withOpacity(0.7),
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
