import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../models/recipes_response.dart';
import '../constants/app_colors.dart';

enum RecipePageState {
  initial, // 초기 화면
  loading, // 로딩 중
  loaded, // 레시피 로드 완료
}

class RecipePage extends StatefulWidget {
  final ValueNotifier<int>? tabNotifier;
  final int tabIndex;

  const RecipePage({super.key, this.tabNotifier, this.tabIndex = 1});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> with TickerProviderStateMixin {
  RecipePageState _pageState = RecipePageState.initial;
  RecipeDecision? _decision;
  String _reason = '';
  List<RecipeDetail> _recipes = [];
  late AnimationController _loadingController;
  late AnimationController _pulseController;
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;
  int _currentVideoIndex = 0;
  bool _videoListenerAdded = false;
  int _currentRecipeIndex = 0;
  final PageController _recipePageController = PageController();

  // 초기 화면용 비디오 컨트롤러
  VideoPlayerController? _initialVideoController;
  bool _isInitialVideoInitializing = false;

  // 사용 가능한 비디오 파일 목록 (파일명만 지정, 확장자 제외)
  // 숫자나 영어 파일명 모두 가능 (예: '1', 'cooking', 'recipe_video' 등)
  static const List<String> _availableVideos = ['1', '3', '4', '5', '6', '7', '8'];

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

    // 탭 변경 리스너 등록
    widget.tabNotifier?.addListener(_onTabChanged);

    // 현재 탭이 이 페이지일 때만 비디오 초기화
    if (widget.tabNotifier == null || widget.tabNotifier!.value == widget.tabIndex) {
      _initializeInitialVideo();
    }
  }

  void _onTabChanged() {
    if (widget.tabNotifier?.value == widget.tabIndex) {
      // 이 탭이 보일 때 비디오 초기화
      if (_initialVideoController == null || !_initialVideoController!.value.isInitialized) {
        _initializeInitialVideo();
      }
    } else {
      // 다른 탭으로 이동 시 비디오 해제
      _disposeInitialVideo();
    }
  }

  void _disposeInitialVideo() {
    if (_initialVideoController != null) {
      _initialVideoController!.pause();
      _initialVideoController!.dispose();
      _initialVideoController = null;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    widget.tabNotifier?.removeListener(_onTabChanged);
    _loadingController.dispose();
    _pulseController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.removeListener(_onVideoEnd);
    _videoController?.dispose();
    _initialVideoController?.dispose();
    _recipePageController.dispose();
    super.dispose();
  }
  
  // ------------------------------
  // 초기 화면 비디오 초기화 함수
  // ------------------------------
  Future<void> _initializeInitialVideo() async {
    // 기존 컨트롤러 정리
    if (_initialVideoController != null) {
      try {
        await _initialVideoController!.pause();
        await _initialVideoController!.dispose();
      } catch (e) {
        print('초기 비디오 컨트롤러 정리 중 오류: $e');
      }
      _initialVideoController = null;
    }

    try {
      setState(() {
        _isInitialVideoInitializing = true;
      });

      if (kIsWeb) {
        final videoUrl = '/assets/logos/recipes.mp4';
        _initialVideoController = VideoPlayerController.network(videoUrl);
      } else {
        final videoPath = 'assets/logos/recipes.mp4';
        _initialVideoController = VideoPlayerController.asset(videoPath);
      }

      await _initialVideoController!.initialize();
      _initialVideoController!.setVolume(0.0);
      _initialVideoController!.setLooping(true);
      _initialVideoController!.play();

      if (mounted) {
        setState(() {
          _isInitialVideoInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialVideoInitializing = false;
        });
      }
      print('초기 화면 비디오 초기화 실패: $e');
    }
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

    final random = math.Random();
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
        _videoController!.setVolume(0.0); // 영상 소리 제거
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
  // 레시피 생성 함수
  // ------------------------------
  Future<void> _createRecipes() async {
    setState(() {
      _pageState = RecipePageState.loading;
    });

    // 비디오 초기화 (비동기로 실행하되 기다리지 않음 - 병렬 처리)
    _initializeVideo();

    final response = await ApiService.createRecipes();

    // 비디오 정리
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    if (response.code == 201 && response.response.data != null) {
      setState(() {
        _decision = response.response.data!.decision;
        _reason = response.response.data!.reason;
        _recipes = response.response.data!.recipes ?? [];
        _pageState = RecipePageState.loaded;
        _currentRecipeIndex = 0;
      });
      // PageController를 첫 페이지로 리셋 (다음 프레임에서 실행)
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _recipePageController.hasClients) {
            _recipePageController.jumpToPage(0);
          }
        });
      }
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
          _pageState = RecipePageState.initial;
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
      backgroundColor: _pageState == RecipePageState.loading ? Colors.black : Colors.white,
      body: SafeArea(
        child: _buildContent(context),
      ),
    );
  }


  // ------------------------------
  // 화면 상태에 따라 다른 UI 표시
  // ------------------------------
  Widget _buildContent(BuildContext context) {
    switch (_pageState) {
      case RecipePageState.initial:
        return _buildInitialScreen(context);
      case RecipePageState.loading:
        return _buildLoadingScreen(context);
      case RecipePageState.loaded:
        return _buildRecipesList(context);
    }
  }

  // ------------------------------
  // 초기 화면: 레시피 만들기 버튼만
  // ------------------------------
  Widget _buildInitialScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 비디오 또는 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                width: 80,
                height: 80,
                color: Colors.white,
                child: _initialVideoController != null &&
                    _initialVideoController!.value.isInitialized &&
                    !_isInitialVideoInitializing
                    ? Transform.scale(
                        scale: 2.0,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _initialVideoController!.value.aspectRatio > 0
                                ? _initialVideoController!.value.aspectRatio
                                : 1.0,
                            child: VideoPlayer(_initialVideoController!),
                          ),
                        ),
                      )
                    : _isInitialVideoInitializing
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.restaurant,
                            size: 48,
                            color: AppColors.primaryOrange,
                          ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _createRecipes,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
            child: const Text(
              '레시피 만들기',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                letterSpacing: 0.5,
                fontSize: 16,
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
              // 디버깅: 현재 상태 출력
              final isWeb = kIsWeb;
              final hasController = _videoController != null;
              final isInitialized = _videoController?.value.isInitialized ?? false;
              print('로딩 화면 렌더링: kIsWeb=$isWeb, hasController=$hasController, isInitialized=$isInitialized');
              
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
                        AppColors.backgroundBeige.withOpacity(0.9),
                        const Color(0xFFE8E0D6).withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 64,
                          color: AppColors.primaryOrange,
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
                opacity: 0.85 + (_pulseController.value * 0.15),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'AI 요리사가 냉장고를 관찰중입니다',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'NanumGothicCoding-Regular',
                            letterSpacing: 0.5,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '영상 에피타이저 먼저 내어드립니다 🍿',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'NanumGothicCoding-Regular',
                            letterSpacing: 0.5,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryOrange,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // 레시피 리스트 화면
  // ------------------------------
  Widget _buildRecipesList(BuildContext context) {
    if (_decision == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 64,
              color: AppColors.textDark,
            ),
            const SizedBox(height: 16),
            const Text(
              '결과를 불러올 수 없습니다',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                fontSize: 18,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _pageState = RecipePageState.initial;
                  _decision = null;
                  _reason = '';
                  _recipes = [];
                });
                // 비디오 다시 초기화
                _initializeInitialVideo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: const Text(
                '다시 만들기',
                style: TextStyle(
                  fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // DELIVERY인 경우: reason만 표시
    if (_decision == RecipeDecision.DELIVERY) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '추천 결과',
                  style: TextStyle(
                    fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _pageState = RecipePageState.initial;
                        _decision = null;
                        _reason = '';
                        _recipes = [];
                      });
                      // 비디오 다시 초기화
                      _initializeInitialVideo();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '다시 만들기',
                        style: TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // DELIVERY 카드
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xCCF2EFEB),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 배달 아이콘 헤더
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          size: 32,
                          color: AppColors.accentYellow,
                        ),
                        SizedBox(width: 12),
                        Text(
                          '배달 추천',
                          style: TextStyle(
                            fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // reason 표시
                  Text(
                    _reason,
                    style: const TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                      fontSize: 18,
                      color: AppColors.textDark,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // COOK인 경우: reason과 recipes 모두 표시
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽: 제목과 네비게이션 버튼
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _recipes.isEmpty 
                              ? '레시피 추천'
                              : '${_recipes.length}개의 레시피',
                          style: const TextStyle(
                            fontFamily: 'NanumGothicCoding-Regular',
                            letterSpacing: 0.5,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 네비게이션 버튼 (레시피가 2개 이상일 때만 표시)
                      if (_recipes.length > 1) ...[
                        const SizedBox(width: 12),
                        // 이전 버튼
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _currentRecipeIndex > 0
                                ? () {
                                    _recipePageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _currentRecipeIndex > 0
                                    ? AppColors.primaryOrange
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                                boxShadow: _currentRecipeIndex > 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                color: _currentRecipeIndex > 0
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 페이지 인디케이터
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            _recipes.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentRecipeIndex == index
                                    ? AppColors.primaryOrange
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 다음 버튼
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _currentRecipeIndex < _recipes.length - 1
                                ? () {
                                    _recipePageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _currentRecipeIndex < _recipes.length - 1
                                    ? AppColors.primaryOrange
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                                boxShadow: _currentRecipeIndex < _recipes.length - 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: _currentRecipeIndex < _recipes.length - 1
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 오른쪽: 다시 만들기 버튼
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _pageState = RecipePageState.initial;
                        _decision = null;
                        _reason = '';
                        _recipes = [];
                      });
                      // 비디오 다시 초기화
                      _initializeInitialVideo();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '다시 만들기',
                        style: TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // reason 표시 (COOK인 경우)
          if (_reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 24,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _reason,
                        style: const TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                          fontSize: 16,
                          color: AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 레시피 리스트
          _recipes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: AppColors.textDark,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '레시피가 없습니다',
                        style: TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                          fontSize: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                )
              : _recipes.length == 1
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildRecipeCard(_recipes[0], 0),
                    )
                  : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: PageView.builder(
                        controller: _recipePageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentRecipeIndex = index;
                          });
                        },
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildRecipeCard(_recipes[index], index),
                          );
                        },
                      ),
                    ),
        ],
          ),
        ),
      ),
    );
  }

  // 이미지 없거나 로드 실패 시 기본 이미지
  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.backgroundBeige,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 48,
            color: AppColors.primaryOrange,
          ),
          SizedBox(height: 8),
          Text(
            '이미지를 불러올 수 없습니다',
            style: TextStyle(
              fontFamily: 'NanumGothicCoding-Regular',
              fontSize: 13,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // 레시피 카드 위젯
  // ------------------------------
  Widget _buildRecipeCard(RecipeDetail recipe, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 레시피 이미지 + 레시피 이름 (오버레이)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final imageWidth = maxWidth > 600 ? 600.0 : maxWidth;
                return Center(
                  child: SizedBox(
                    width: imageWidth,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 이미지
                          if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                            Image.network(
                              recipe.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: AppColors.backgroundBeige,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryOrange,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _buildFallbackImage();
                              },
                            )
                          else
                            _buildFallbackImage(),
                          // 하단 그라데이션 + 레시피 이름
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 32, 16, 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                ),
                              ),
                              child: Text(
                                recipe.recipeName,
                                style: const TextStyle(
                                  fontFamily: 'NanumGothicCoding-Regular',
                                  letterSpacing: 0.5,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 번호 배지
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'NanumGothicCoding-Regular',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '재료',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recipe.ingredients.map((ingredient) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        ingredient,
                        style: const TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                          letterSpacing: 0.5,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // 조리 단계 섹션
                const Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 20,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '조리 단계',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                        letterSpacing: 0.5,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recipe.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                              fontSize: 16,
                              color: AppColors.textDark,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
