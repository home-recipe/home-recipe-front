import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'value_card.dart';

/// 가치 제안 섹션 위젯
/// My 레시피와 추천 레시피 기능을 소개하는 2개의 카드 표시
class ValuePropositionSection extends StatelessWidget {
  final VoidCallback onMyPressed;
  final VoidCallback onRecommendPressed;

  const ValuePropositionSection({
    super.key,
    required this.onMyPressed,
    required this.onRecommendPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isWide ? 80 : 60,
        horizontal: isWide ? 60 : 24,
      ),
      decoration: BoxDecoration(
        // 미묘한 그라데이션 배경
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundWhite,
            AppColors.backgroundLight.withOpacity(0.3),
            AppColors.backgroundWhite,
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // 섹션 제목
              Text(
                'REC::OOK만의 특별한 기능',
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
                '냉장고 재료로 바로 만들 수 있는 레시피를 경험하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWide ? 16 : 14,
                  color: AppColors.textGrey,
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: isWide ? 56 : 40),

              // 카드들 (반응형 레이아웃)
              if (isWide)
                // 웹: 2열 Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildMyCard()),
                    const SizedBox(width: 32),
                    Expanded(child: _buildRecommendCard()),
                  ],
                )
              else
                // 모바일: 1열 Column
                Column(
                  children: [
                    _buildMyCard(),
                    const SizedBox(height: 20),
                    _buildRecommendCard(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// My 카드 생성
  Widget _buildMyCard() {
    return ValueCard(
      icon: Icons.kitchen,
      iconColor: AppColors.primaryGreen,
      title: '우리집 냉장고 재료로',
      description: '지금 우리 집 냉장고에 있는 재료만으로 바로 만들 수 있는 레시피를 확인하세요.',
      buttonLabel: 'My 레시피 보기',
      onPressed: onMyPressed,
    );
  }

  /// 추천 카드 생성
  Widget _buildRecommendCard() {
    return ValueCard(
      icon: Icons.auto_awesome,
      iconColor: AppColors.primaryOrange,
      title: '최소 재료 추가로 즐기는',
      description: '현재 재료에서 최소한의 추가로 즐길 수 있는 최고의 요리를 추천해 드려요.',
      buttonLabel: '추천 레시피 보기',
      onPressed: onRecommendPressed,
    );
  }
}
