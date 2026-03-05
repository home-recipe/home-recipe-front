import 'package:flutter/material.dart';
import '../screens/login_page.dart';
import '../screens/admin_page.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../constants/app_colors.dart';

class LogoutHelper {
  // 로그아웃 메뉴 표시 (ADMIN이면 페이지 관리 메뉴도 표시)
  static void showLogoutMenu(BuildContext context, GlobalKey accountButtonKey, {bool isAdmin = false}) {
    final RenderBox? renderBox =
        accountButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width - 130,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy + size.height + 50,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      elevation: 12,
      items: [
        // ADMIN인 경우 페이지 관리 메뉴 표시
        if (isAdmin)
          PopupMenuItem(
            padding: EdgeInsets.zero,
            height: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminPage()),
                  );
                },
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.settings,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '페이지 관리',
                        style: TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // 로그아웃 메뉴
        PopupMenuItem(
          padding: EdgeInsets.zero,
          height: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: isAdmin
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    )
                  : BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                handleLogout(context);
              },
              borderRadius: isAdmin
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    )
                  : BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 로그아웃 처리
  static Future<void> handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '👋',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '로그아웃',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text(
              '로그아웃 하시겠어요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 15,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);

                      // 로그아웃 API 호출
                      try {
                        await ApiService.logout();
                      } catch (e) {
                        // 에러가 발생해도 토큰은 삭제하고 로그인 페이지로 이동
                      }

                      // 성공/실패 관계없이 토큰 삭제
                      await TokenService.clearTokens();

                      if (!context.mounted) return;

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
