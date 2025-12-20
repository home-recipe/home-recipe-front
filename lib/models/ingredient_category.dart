// 서버 enum 값을 한글로 변환하는 유틸리티
class IngredientCategory {
  // 서버 enum 값 -> 한글 이름 변환
  static String toDisplayName(String category) {
    switch (category.toUpperCase()) {
      case 'VEGETABLE':
        return '채소';
      case 'FRUIT':
        return '과일';
      case 'MEAT':
        return '육류';
      case 'FISH':
        return '해산물';
      case 'GRAIN':
        return '곡물';
      case 'SPICE':
        return '소스/양념';
      case 'ETC':
        return '기타';
      default:
        return '기타';
    }
  }

  // 서버에서 사용하는 모든 카테고리 목록
  static const List<String> values = [
    'VEGETABLE',
    'FRUIT',
    'MEAT',
    'FISH',
    'GRAIN',
    'SPICE',
    'ETC',
  ];
}


