import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
      // AssetManifest에서 모든 asset 목록 가져오기
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // profiles 폴더의 이미지 파일만 필터링
      final profileImages = manifestMap.keys
          .where((String key) => key.startsWith('profiles/') && 
                                 (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg')))
          .toList()
        ..sort(); // 정렬하여 일관성 유지
      
      // 캐시에 저장
      _cachedProfileImages = profileImages;
      
      return profileImages;
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환
      debugPrint('프로필 이미지 로드 중 오류: $e');
      return [];
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
  
  /// 캐시를 초기화합니다 (새로운 이미지가 추가되었을 때 사용)
  static void clearCache() {
    _cachedProfileImages = null;
  }
}

