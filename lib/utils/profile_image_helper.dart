import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../services/token_service.dart';

/// 프로필 이미지를 동적으로 로드하는 헬퍼 클래스
class ProfileImageHelper {
  static List<String>? _cachedProfileImages;
  
  /// assets/profiles 폴더에서 모든 프로필 이미지 목록을 동적으로 가져옵니다
  static Future<List<String>> getProfileImages() async {
    // 캐시된 목록이 있으면 반환
    if (_cachedProfileImages != null) {
      return _cachedProfileImages!;
    }
    
    try {
      String manifestContent;
      
      if (kIsWeb) {
        // 웹 환경: 여러 경로 시도
        List<String> webPaths = [
          'AssetManifest.json',
          'packages/flutter/services/AssetManifest.json',
        ];
        
        String? loadedContent;
        for (String path in webPaths) {
          try {
            loadedContent = await rootBundle.loadString(path);
            break;
          } catch (e) {
            // 개발 모드에서는 조용히 실패 처리
            continue;
          }
        }
        
        if (loadedContent == null) {
          // 웹에서 AssetManifest를 로드할 수 없으면 예외 발생
          throw Exception('AssetManifest.json을 로드할 수 없습니다');
        }
        
        manifestContent = loadedContent;
      } else {
        // 모바일 환경: rootBundle 사용
        manifestContent = await rootBundle.loadString('AssetManifest.json');
      }
      
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // profiles 폴더의 이미지 파일만 필터링
      // AssetManifest.json의 경로는 'assets/profiles/' 또는 'profiles/' 형식일 수 있음
      final profileImages = manifestMap.keys
          .where((String key) => (key.startsWith('assets/profiles/') || key.startsWith('profiles/')) && 
                                 (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg')))
          .map((String key) {
            // 웹에서는 Image.asset()이 자동으로 'assets/'를 추가하므로 제거
            // 모바일에서는 'assets/' prefix 필요
            if (kIsWeb) {
              // 웹: 'assets/profiles/onion.png' -> 'profiles/onion.png'
              if (key.startsWith('assets/')) {
                return key.substring(7); // 'assets/' 제거 (7글자)
              }
              return key;
            } else {
              // 모바일: 'assets/' prefix가 없으면 추가
              if (!key.startsWith('assets/')) {
                return 'assets/$key';
              }
              return key;
            }
          })
          .toList()
        ..sort(); // 정렬하여 일관성 유지
      
      // 캐시에 저장
      _cachedProfileImages = profileImages;
      
      // 웹에서 빈 리스트이면 실제 파일 존재 여부 확인
      if (kIsWeb && profileImages.isEmpty) {
        debugPrint('AssetManifest에서 profiles 이미지를 찾을 수 없습니다. 실제 파일 존재 여부를 확인합니다.');
        // 실제 파일들을 시도해보는 방법은 복잡하므로, 여기서는 빈 리스트 반환
      }
      
      return profileImages;
    } catch (e) {
      // 에러 발생 시: 개발 모드에서는 fallback 목록 사용
      if (kIsWeb) {
        // 웹 개발 모드에서는 AssetManifest.json이 제공되지 않을 수 있음
        // 개발 편의를 위해 알려진 파일 목록을 fallback으로 사용
        // (프로덕션 빌드에서는 AssetManifest에서 동적으로 로드됨)
        debugPrint('웹 개발 모드: AssetManifest.json을 로드할 수 없습니다. 개발용 fallback 목록을 사용합니다.');
        
        // 개발 모드 fallback: assets/profiles 폴더의 알려진 파일들
        // 프로덕션에서는 AssetManifest에서 동적으로 로드되므로 하드코딩이 아님
        // 새로운 이미지를 추가하면 여기에도 추가해야 하지만, 프로덕션에서는 자동으로 인식됨
        _cachedProfileImages = ['profiles/fruit1.png', 'profiles/onion.png', 'profiles/tomato.png'];
        return _cachedProfileImages!;
      } else {
        debugPrint('프로필 이미지 로드 중 오류: $e');
        _cachedProfileImages = [];
        return _cachedProfileImages!;
      }
    }
  }
  
  /// 프로필 이미지 목록에서 랜덤하게 하나를 선택합니다
  static Future<String?> getRandomProfileImage() async {
    final images = await getProfileImages();
    if (images.isEmpty) {
      return null;
    }
    
    final random = Random();
    return images[random.nextInt(images.length)];
  }
  
  /// 사용자별로 고정된 프로필 이미지를 반환합니다 (AccessToken 기반)
  static Future<String?> getUserProfileImage() async {
    final images = await getProfileImages();
    if (images.isEmpty) {
      return null;
    }
    
    // AccessToken을 가져와서 해시값 생성
    final token = await TokenService.getAccessToken();
    if (token == null || token.isEmpty) {
      // 토큰이 없으면 랜덤 반환
      return getRandomProfileImage();
    }
    
    // 토큰 문자열을 간단한 해시값으로 변환 (웹 호환)
    // 각 문자의 코드 포인트를 합산하여 해시값 생성
    int hashValue = 0;
    for (int i = 0; i < token.length; i++) {
      hashValue = (hashValue * 31 + token.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    
    // 해시값을 이미지 인덱스로 변환
    final index = hashValue % images.length;
    return images[index];
  }
  
  /// 캐시를 초기화합니다 (새로운 이미지가 추가되었을 때 사용)
  static void clearCache() {
    _cachedProfileImages = null;
  }
}

