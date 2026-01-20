import 'package:flutter/material.dart';
import '../screens/login_page.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

class LogoutHelper {
  // 로그아웃 메뉴 표시
  static void showLogoutMenu(BuildContext context, GlobalKey accountButtonKey) {
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
        borderRadius: BorderRadius.circular(14),
      ),
      color: Colors.white,
      elevation: 8,
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          height: 0,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              handleLogout(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 14, color: Color(0xFF2C2C2C)),
                  SizedBox(width: 10),
                  Text(
                    '로그아웃',
                    style: TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                      fontSize: 14,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ],
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
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '로그아웃',
            style: TextStyle(
              fontFamily: 'NanumGothicCoding-Regular',
              letterSpacing: 0.5,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2C2C),
            ),
          ),
          content: const Text(
            '로그아웃 하시겠습니까?',
            style: TextStyle(
              fontFamily: 'NanumGothicCoding-Regular',
              letterSpacing: 0.5,
              fontSize: 14,
              color: Color(0xFF2C2C2C),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // 로그아웃 API 호출
                try {
                  await ApiService.logout();
                } catch (e) {
                  // 에러가 발생해도 토큰은 삭제하고 로그인 페이지로 이동
                  await TokenService.clearTokens();
                }

                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 14,
                  color: Color(0xFFE07A5F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

