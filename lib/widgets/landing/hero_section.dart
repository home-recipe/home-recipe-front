import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// 랜딩 페이지 Hero 섹션 위젯
/// 배경 이미지 슬라이더와 슬로건을 표시
/// 반응형: 모바일/태블릿/웹 화면 크기에 맞게 자동 조절
class HeroSection extends StatefulWidget {
  const HeroSection({
    super.key,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin {
  // 배경 이미지 경로 목록
  static final List<String> _backgroundImages = [
    kIsWeb ? 'front/1.png' : 'assets/front/1.png',
    kIsWeb ? 'front/2.png' : 'assets/front/2.png',
    kIsWeb ? 'front/3.png' : 'assets/front/3.png',
  ];

  late AnimationController _controller;
  late Animation<double> _sloganAnimation;
  late Animation<double> _subtitleAnimation;

  // 이미지 슬라이더 관련
  int _currentImageIndex = 0;
  Timer? _imageTimer;

  @override
  void initState() {
    super.initState();

    // 텍스트 애니메이션 컨트롤러 (1초 동안 실행)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 0.0~0.4s: 슬로건 슬라이드업 + 페이드인
    _sloganAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // 0.2~0.6s: 부제목 페이드인
    _subtitleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    ));

    // 텍스트 애니메이션 시작
    _controller.forward();

    // 이미지 자동 전환 타이머 (6초마다)
    _imageTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _changeImage();
    });
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 이미지 전환 (cross-fade 효과)
  void _changeImage() {
    if (!mounted) return;
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 반응형 브레이크포인트
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth <= 900;

    // 화면 크기에 비례한 폰트 크기 (clamp로 최소/최대 제한)
    final sloganFontSize = (screenWidth * 0.045).clamp(20.0, 36.0);
    final subtitleFontSize = (screenWidth * 0.028).clamp(13.0, 18.0);

    // 화면 크기에 비례한 패딩
    final horizontalPadding = isMobile ? 20.0 : 24.0;
    final topPadding = isMobile ? 24.0 : (isTablet ? 40.0 : 80.0);
    final bottomPadding = isMobile ? 24.0 : (isTablet ? 40.0 : 80.0);

    return SizedBox.expand(
      child: Stack(
        children: [
          // 배경 이미지 레이어 (최하단) - 부드러운 cross-fade
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: Image.asset(
                _backgroundImages[_currentImageIndex],
                key: ValueKey<int>(_currentImageIndex),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
            ),
          ),

          // 어두운 오버레이 (중간)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // 텍스트 콘텐츠 (최상단)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding,
                bottom: bottomPadding,
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 슬로건 애니메이션
                  FadeTransition(
                    opacity: _sloganAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
                      )),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '당신의 냉장고가\n레시피가 됩니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: sloganFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'NanumGothicCoding-Regular',
                            letterSpacing: 0.5,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.7),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // 부제목 애니메이션
                  FadeTransition(
                    opacity: _subtitleAnimation,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'AI가 추천하는 나만의 맞춤 레시피',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.white.withOpacity(0.95),
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.3,
                          height: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
