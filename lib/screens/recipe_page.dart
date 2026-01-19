import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/logout_helper.dart';
import '../utils/profile_image_helper.dart';
import '../services/api_service.dart';
import '../models/recipes_response.dart';

enum RecipePageState {
  initial, // 초기 화면
  loading, // 로딩 중
  loaded, // 레시피 로드 완료
}

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> with TickerProviderStateMixin {
  final GlobalKey _accountButtonKey = GlobalKey();
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
  
  // 사용 가능한 비디오 파일 목록 (파일명만 지정, 확장자 제외)
  // 숫자나 영어 파일명 모두 가능 (예: '1', 'cooking', 'recipe_video' 등)
  static const List<String> _availableVideos = ['1', '3', '4', '5', '6', '7', '8'];
  
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
    _recipePageController.dispose();
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
      body: Stack(
        children: [
          // 배경 이미지 (로딩 중이 아닐 때만 표시)
          if (_pageState != RecipePageState.loading)
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/homeimage2.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // 로딩 중일 때 검은색 배경
          if (_pageState == RecipePageState.loading)
            Container(
              color: Colors.black,
            ),

          // 오버레이 (로딩 중이 아닐 때만 표시)
          if (_pageState != RecipePageState.loading)
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
              Icons.restaurant_menu,
              size: 64,
              color: Color(0xFFDEAE71),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _createRecipes,
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
              '레시피 만들기',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
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
                          Icons.restaurant,
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
                opacity: 0.7 + (_pulseController.value * 0.3),
                child: const Text(
                  '맛있는 레시피를 만들고 있어요...',
                  style: TextStyle(
                    fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
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
              color: Color(0xFF2C2C2C),
            ),
            const SizedBox(height: 16),
            const Text(
              '결과를 불러올 수 없습니다',
              style: TextStyle(
                fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                fontSize: 18,
                color: Color(0xFF2C2C2C),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDEAE71),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _pageState = RecipePageState.initial;
                      _decision = null;
                      _reason = '';
                      _recipes = [];
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text(
                    '다시 만들기',
                    style: TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
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
            const SizedBox(height: 24),
            // DELIVERY 카드
            Container(
              padding: const EdgeInsets.all(24),
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
                  // 배달 아이콘 헤더
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEAE71).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          size: 32,
                          color: Color(0xFFDEAE71),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '배달 추천',
                          style: TextStyle(
                            fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
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
                      color: Color(0xFF2C2C2C),
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
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽: 제목과 네비게이션 버튼
                Row(
                  children: [
                    Text(
                      _recipes.isEmpty 
                          ? '레시피 추천'
                          : '${_recipes.length}개의 레시피',
                      style: const TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    // 네비게이션 버튼 (레시피가 2개 이상일 때만 표시)
                    if (_recipes.length > 1) ...[
                      const SizedBox(width: 16),
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
                                  ? const Color(0xFFDEAE71)
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                              boxShadow: _currentRecipeIndex > 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
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
                      const SizedBox(width: 8),
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
                                  ? const Color(0xFFDEAE71)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                  ? const Color(0xFFDEAE71)
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                              boxShadow: _currentRecipeIndex < _recipes.length - 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
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
                // 오른쪽: 다시 만들기 버튼
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _pageState = RecipePageState.initial;
                      _decision = null;
                      _reason = '';
                      _recipes = [];
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text(
                    '다시 만들기',
                    style: TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
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
          // reason 표시 (COOK인 경우)
          if (_reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xCCF2EFEB),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 24,
                      color: Color(0xFFDEAE71),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _reason,
                        style: const TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                          fontSize: 16,
                          color: Color(0xFF2C2C2C),
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
                        color: Color(0xFF2C2C2C),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '레시피가 없습니다',
                        style: TextStyle(
                          fontFamily: 'NanumGothicCoding-Regular',
                    letterSpacing: 0.5,
                          fontSize: 18,
                          color: Color(0xFF2C2C2C),
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
    );
  }

  // ------------------------------
  // 레시피 카드 위젯
  // ------------------------------
  Widget _buildRecipeCard(RecipeDetail recipe, int index) {
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
                        fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
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
                    recipe.recipeName,
                    style: const TextStyle(
                      fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
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
                        fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 왼쪽 칸
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: recipe.ingredients.asMap().entries.where((entry) => entry.key % 2 == 0).map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                                letterSpacing: 0.5,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C2C2C),
                              ),
                              textAlign: TextAlign.left,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 오른쪽 칸
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: recipe.ingredients.asMap().entries.where((entry) => entry.key % 2 == 1).map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontFamily: 'NanumGothicCoding-Regular',
                                letterSpacing: 0.5,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C2C2C),
                              ),
                              textAlign: TextAlign.left,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 조리 단계 섹션
                const Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 20,
                      color: Color(0xFFDEAE71),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '조리 단계',
                      style: TextStyle(
                        fontFamily: 'NanumGothicCoding-Regular',
                  letterSpacing: 0.5,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2C2C),
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
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEAE71),
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
                              color: Color(0xFF2C2C2C),
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
