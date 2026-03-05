import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// 기능 소개 카드 위젯
/// 아이콘 + 제목 + 설명으로 구성
class FeatureCard extends StatefulWidget {
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
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          // 호버 시 그림자 강화
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AppColors.primaryOrange.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _isHovered ? 24 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
          // 하단 레드 포인트 라인
          border: Border(
            bottom: BorderSide(
              color: _isHovered
                  ? AppColors.primaryOrange
                  : AppColors.primaryOrange.withOpacity(0.3),
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
                widget.icon,
                size: 28,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 20),

            // 제목
            Text(
              widget.title,
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
              widget.description,
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
      ),
    );
  }
}
