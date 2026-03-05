import 'dart:async';
import 'package:flutter/material.dart';

/// 랜딩 페이지 Hero 섹션 위젯
/// 배경 이미지 슬라이더와 슬로건을 표시
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
  static const List<String> _backgroundImages = [
    'assets/front/1.png',
    'assets/front/2.png',
    'assets/front/3.png',
  ];

  late AnimationController _controller;
  late Animation<double> _sloganAnimation;
  late Animation<double> _subtitleAnimation;

  // 이미지 슬라이더 관련
  int _currentImageIndex = 0;
  Timer? _imageTimer;
  double _imageOpacity = 1.0;

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

    // 이미지 자동 전환 타이머 (4초마다)
    _imageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
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
      _imageOpacity = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
        _imageOpacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return SizedBox(
      width: double.infinity,
      height: isWide ? 550 : 400,
      child: Stack(
        children: [
          // 배경 이미지 레이어 (최하단)
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: _imageOpacity,
              curve: Curves.easeInOut,
              child: Image.asset(
                _backgroundImages[_currentImageIndex],
                fit: BoxFit.cover,
              ),
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
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isWide ? 80 : 60,
                horizontal: 24,
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
                      child: Text(
                        '당신의 냉장고가 레시피가 됩니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isWide ? 32 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          height: 1.3,
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
                  const SizedBox(height: 16),

                  // 부제목 애니메이션
                  FadeTransition(
                    opacity: _subtitleAnimation,
                    child: Text(
                      'AI가 추천하는 나만의 맞춤 레시피',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWide ? 18 : 16,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
