import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/logout_helper.dart';
import '../services/api_service.dart';
import '../models/recommendations_response.dart';

enum RecommendationPageState {
  initial, // 초기 화면
  loading, // 로딩 중
  loaded, // 추천 레시피 로드 완료
}

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> with TickerProviderStateMixin {
  final GlobalKey _accountButtonKey = GlobalKey();
  RecommendationPageState _pageState = RecommendationPageState.initial;
  List<RecommendationDetail> _recommendations = [];
  late AnimationController _loadingController;
  late AnimationController _pulseController;
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;
  int _currentVideoIndex = 0;
  bool _videoListenerAdded = false;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pulseController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.removeListener(_onVideoEnd);
    _videoController?.dispose();
    super.dispose();
  }

  // ------------------------------
  // 비디오 초기화 함수
  // ------------------------------
  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isVideoInitializing = true;
      });

      // 순차적으로 비디오 선택 (1.mp4 ~ 6.mp4)
      final videoNumber = (_currentVideoIndex % 6) + 1;
      
      _videoController?.removeListener(_videoListener);
      _videoController?.removeListener(_onVideoEnd);
      _videoController?.dispose();
      _videoListenerAdded = false;
      
      if (kIsWeb) {
        // 웹: 네트워크 URL 사용 (asset 경로를 웹 경로로 변환)
        final videoUrl = '/assets/videos/$videoNumber.mp4';
        _videoController = VideoPlayerController.network(videoUrl);
      } else {
        // 모바일: asset 비디오 사용
        final videoPath = 'assets/videos/$videoNumber.mp4';
        _videoController = VideoPlayerController.asset(videoPath);
      }
      
      // 비디오 컨트롤러에 리스너 추가 (한 번만)
      if (!_videoListenerAdded) {
        _videoController!.addListener(_videoListener);
        _videoListenerAdded = true;
      }
      
      await _videoController!.initialize();
      _videoController!.setLooping(false); // 반복하지 않음
      
      // 비디오가 끝나면 다음 비디오로 자동 전환
      _videoController!.addListener(_onVideoEnd);
      
      _videoController!.play();
      
      if (mounted) {
        setState(() {
          _isVideoInitializing = false;
        });
      }
    } catch (e) {
      // 비디오 초기화 실패 시 기존 컨트롤러 정리
      _videoController?.removeListener(_videoListener);
      _videoController?.removeListener(_onVideoEnd);
      _videoController?.dispose();
      _videoController = null;
      _videoListenerAdded = false;
      if (mounted) {
        setState(() {
          _isVideoInitializing = false;
        });
      }
      // 에러는 조용히 처리 (비디오 없이 진행)
      print('비디오 초기화 실패: $e');
    }
  }

  // 비디오 리스너 (초기화 완료 시 한 번만 호출)
  void _videoListener() {
    if (_videoController != null && 
        _videoController!.value.isInitialized && 
        mounted && 
        _isVideoInitializing) {
      setState(() {
        _isVideoInitializing = false;
      });
    }
  }

  // 비디오 종료 시 다음 비디오로 전환
  void _onVideoEnd() {
    if (_videoController != null && 
        _videoController!.value.position >= _videoController!.value.duration &&
        _videoController!.value.duration > Duration.zero) {
      // 다음 비디오로 전환
      _currentVideoIndex++;
      _initializeVideo();
    }
  }

  // ------------------------------
  // 추천 레시피 생성 함수
  // ------------------------------
  Future<void> _getRecommendations() async {
    setState(() {
      _pageState = RecommendationPageState.loading;
    });

    // 비디오 초기화 (비동기로 실행하되 기다리지 않음 - 병렬 처리)
    _initializeVideo();

    final response = await ApiService.getRecommendations();

    // 비디오 정리
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    if (response.code == 201 && response.response.data != null) {
      setState(() {
        _recommendations = response.response.data!.recommendations;
        _pageState = RecommendationPageState.loaded;
      });
    } else {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _pageState = RecommendationPageState.initial;
        });
      }
    }
  }

  // ------------------------------
  // UI 시작
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/homeimage2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 오버레이
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 상단 계정 아이콘
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          key: _accountButtonKey,
                          onTap: () => LogoutHelper.showLogoutMenu(context, _accountButtonKey),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_circle,
                              size: 32,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _buildContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // 화면 상태에 따라 다른 UI 표시
  // ------------------------------
  Widget _buildContent(BuildContext context) {
    switch (_pageState) {
      case RecommendationPageState.initial:
        return _buildInitialScreen(context);
      case RecommendationPageState.loading:
        return _buildLoadingScreen(context);
      case RecommendationPageState.loaded:
        return _buildRecommendationsList(context);
    }
  }

  // ------------------------------
  // 초기 화면: 레시피 추천받기 버튼만
  // ------------------------------
  Widget _buildInitialScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 64,
              color: Color(0xFFDEAE71),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _getRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDEAE71),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 3,
            ),
            child: const Text(
              '레시피 추천받기',
              style: TextStyle(
                fontFamily: 'GowunBatang',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // 로딩 화면: 비디오 재생 (모바일) 또는 애니메이션 (웹)
  // ------------------------------
  Widget _buildLoadingScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 비디오가 초기화되면 비디오 재생, 아니면 회전 아이콘
          Builder(
            builder: (context) {
              if (_videoController != null && _videoController!.value.isInitialized) {
                // 비디오 플레이어 (웹/모바일 모두) - 크게 표시
                final screenWidth = MediaQuery.of(context).size.width;
                final videoWidth = screenWidth * 0.7; // 화면 너비의 70%
                final videoHeight = videoWidth * (_videoController!.value.aspectRatio > 0 
                    ? 1 / _videoController!.value.aspectRatio 
                    : 1);
                
                return Container(
                  width: videoWidth,
                  height: videoHeight,
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 500,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                );
              } else {
                // 비디오 로딩 중 또는 초기화 실패 시 회전 아이콘
                return AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _loadingController.value * 2 * 3.14159,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: Color(0xFFDEAE71),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
          const SizedBox(height: 40),
          // 펄스 애니메이션 텍스트
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.5 + (_pulseController.value * 0.5),
                child: const Text(
                  '맛있는 레시피를 추천하고 있어요...',
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // 로딩 인디케이터
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDEAE71)),
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // 추천 레시피 리스트 화면
  // ------------------------------
  Widget _buildRecommendationsList(BuildContext context) {
    return Column(
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _recommendations.isEmpty 
                    ? '추천 레시피'
                    : '${_recommendations.length}개의 추천 레시피',
                style: const TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _pageState = RecommendationPageState.initial;
                    _recommendations = [];
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  '다시 추천받기',
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: const Color(0xFF2C2C2C),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 추천 레시피 리스트
        Expanded(
          child: _recommendations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Color(0xFF2C2C2C),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '추천 레시피가 없습니다',
                        style: TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 18,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    return _buildRecommendationCard(_recommendations[index], index);
                  },
                ),
        ),
      ],
    );
  }

  // ------------------------------
  // 추천 레시피 카드 위젯
  // ------------------------------
  Widget _buildRecommendationCard(RecommendationDetail recommendation, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xCCF2EFEB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 레시피 이름 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDEAE71).withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEAE71),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    recommendation.recipeName,
                    style: const TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 레시피 내용
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 재료 섹션
                const Row(
                  children: [
                    Icon(
                      Icons.shopping_basket,
                      size: 20,
                      color: Color(0xFFDEAE71),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '재료',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recommendation.ingredients.map((ingredient) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDEAE71).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        ingredient,
                        style: const TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 14,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


