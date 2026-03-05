import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// 가치 제안 카드 위젯
/// 아이콘, 제목, 설명, CTA 버튼으로 구성
class ValueCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  const ValueCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  State<ValueCard> createState() => _ValueCardState();
}

class _ValueCardState extends State<ValueCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // hover 시 살짝 위로 올라가는 효과
        transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          // hover 시 그림자 강화
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.iconColor.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _isHovered ? 24 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 (원형 배경 안에)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 32,
                color: widget.iconColor,
              ),
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // CTA 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: widget.iconColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  widget.buttonLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
