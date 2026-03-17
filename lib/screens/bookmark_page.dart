import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 보관 탭 Placeholder 페이지
class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 64,
            color: AppColors.textGrey,
          ),
          SizedBox(height: 16),
          Text(
            '보관 기능 준비 중',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
              fontFamily: 'NanumGothicCoding-Regular',
            ),
          ),
          SizedBox(height: 8),
          Text(
            '곧 만나보실 수 있습니다!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              fontFamily: 'NanumGothicCoding-Regular',
            ),
          ),
        ],
      ),
    );
  }
}
