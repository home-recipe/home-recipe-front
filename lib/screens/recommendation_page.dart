import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/logout_helper.dart';
import '../utils/profile_image_helper.dart';
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
  
  // 사용 가능한 비디오 파일 목록 (파일명만 지정, 확장자 제외)
  // 숫자나 영어 파일명 모두 가능 (예: '1', 'cooking', 'recipe_video' 등)
  static const List<String> _availableVideos = ['1', '3', '4', '5', '6'];
  
  // 프로필 사진 (한 번 선택 후 고정)
  String? _selectedProfileImage;

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 랜덤하게 프로필 사진 선택 (비동기)
    _loadRandomProfileImage();
    
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }
  
  /// 프로필 이미지를 사용자별로 고정된 이미지로 로드
  Future<void> _loadRandomProfileImage() async {
    final image = await ProfileImageHelper.getUserProfileImage();
    if (mounted) {
      setState(() {
        _selectedProfileImage = image;
      });
    }
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
    if (_availableVideos.isEmpty) {
      // 사용 가능한 비디오가 없으면 로딩만 표시
      setState(() {
        _isVideoInitializing = false;
      });
      return;
    }

    final random = Random();
    // 최대 3번까지 재시도
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      // 매번 랜덤하게 비디오 선택
      final videoFileName = _availableVideos[random.nextInt(_availableVideos.length)];
      
      try {
        setState(() {
          _isVideoInitializing = true;
        });

        // 기존 컨트롤러 완전히 정리
        if (_videoController != null) {
          try {
            _videoController!.pause();
            _videoController!.removeListener(_videoListener);
            _videoController!.removeListener(_onVideoEnd);
            await _videoController!.dispose();
          } catch (e) {
            print('비디오 컨트롤러 정리 중 오류: $e');
          }
          _videoController = null;
        }
        _videoListenerAdded = false;
        
        if (kIsWeb) {
          // 웹: 네트워크 URL 사용 (asset 경로를 웹 경로로 변환)
          final videoUrl = '/assets/videos/$videoFileName.mp4';
          _videoController = VideoPlayerController.network(videoUrl);
        } else {
          // 모바일: asset 비디오 사용
          final videoPath = 'assets/videos/$videoFileName.mp4';
          _videoController = VideoPlayerController.asset(videoPath);
        }
        
        await _videoController!.initialize();
        _videoController!.setLooping(false); // 반복하지 않음
        
        // 리스너 추가 (초기화 후에만)
        _videoController!.addListener(_videoListener);
        _videoController!.addListener(_onVideoEnd);
        _videoListenerAdded = true;
        
        _videoController!.play();
        
        if (mounted) {
          setState(() {
            _isVideoInitializing = false;
          });
        }
        // 성공하면 루프 종료
        return;
      } catch (e) {
        // 비디오 초기화 실패 시 기존 컨트롤러 정리
        if (_videoController != null) {
          try {
            _videoController!.pause();
            _videoController!.removeListener(_videoListener);
            _videoController!.removeListener(_onVideoEnd);
            await _videoController!.dispose();
          } catch (e) {
            print('비디오 컨트롤러 정리 중 오류: $e');
          }
          _videoController = null;
        }
        _videoListenerAdded = false;
        
        retryCount++;
        if (retryCount < maxRetries) {
          print('비디오 $videoFileName.mp4 초기화 실패, 다른 비디오로 재시도...');
          // 다음 반복에서 다른 비디오 시도
          continue;
        } else {
          // 모든 재시도 실패
          if (mounted) {
            setState(() {
              _isVideoInitializing = false;
            });
          }
          print('비디오 초기화 실패 (모든 재시도 실패): $e');
          return;
        }
      }
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
        _videoController!.value.isInitialized &&
        _videoController!.value.position >= _videoController!.value.duration &&
        _videoController!.value.duration > Duration.zero) {
      // 리스너 제거 후 랜덤 비디오로 전환
      _videoController!.removeListener(_onVideoEnd);
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
    if (_videoController != null) {
      try {
        _videoController!.pause();
        _videoController!.removeListener(_videoListener);
        _videoController!.removeListener(_onVideoEnd);
        await _videoController!.dispose();
      } catch (e) {
        print('비디오 컨트롤러 정리 중 오류: $e');
      }
      _videoController = null;
    }
    _videoListenerAdded = false;

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
                            width: 48,
                            height: 48,
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
                            child: ClipOval(
                              child: _selectedProfileImage != null
                                  ? Image.asset(
                                      _selectedProfileImage!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.account_circle,
                                          size: 48,
                                          color: Color(0xFF2C2C2C),
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.account_circle,
                                      size: 48,
                                      color: Color(0xFF2C2C2C),
                                    ),
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
                final aspectRatio = _videoController!.value.aspectRatio;
                final maxWidth = 500.0;
                final maxHeight = 500.0;
                
                // 비디오의 실제 aspect ratio를 사용하되, 최대 크기 제한
                double videoWidth = screenWidth * 0.7;
                double videoHeight = videoWidth / aspectRatio;
                
                // 최대 크기 제한 적용
                if (videoWidth > maxWidth) {
                  videoWidth = maxWidth;
                  videoHeight = videoWidth / aspectRatio;
                }
                if (videoHeight > maxHeight) {
                  videoHeight = maxHeight;
                  videoWidth = videoHeight * aspectRatio;
                }
                
                return Container(
                  width: videoWidth,
                  height: videoHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF2EFEB).withValues(alpha: 0.9),
                        const Color(0xFFE8E0D6).withValues(alpha: 0.9),
                      ],
                    ),
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
                    child: SizedBox(
                      width: videoWidth,
                      height: videoHeight,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
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


