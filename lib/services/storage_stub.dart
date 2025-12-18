// 스텁 파일 (모바일/데스크톱에서 조건부 import를 위한 기본 구현)
// 실제로는 kIsWeb으로 분기하므로 이 클래스는 사용되지 않습니다
class StorageWeb {
  static Future<void> setItem(String key, String value) async {
    throw UnimplementedError('StorageWeb stub should not be used on mobile/desktop');
  }

  static Future<String?> getItem(String key) async {
    throw UnimplementedError('StorageWeb stub should not be used on mobile/desktop');
  }

  static Future<void> removeItem(String key) async {
    throw UnimplementedError('StorageWeb stub should not be used on mobile/desktop');
  }
}

