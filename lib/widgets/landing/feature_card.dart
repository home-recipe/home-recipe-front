import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// 기능 소개 카드 위젯
/// 아이콘 + 제목 + 설명으로 구성
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryOrange.withOpacity(0.3),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 28,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 20),

          // 제목
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontFamily: 'NanumGothicCoding-Regular',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // 설명
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.6,
              fontFamily: 'NanumGothicCoding-Regular',
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
