/// 영어 레시피 이름과 재료를 한글로 변환하는 유틸리티
class TranslationHelper {
  // 재료 이름 영어 -> 한글 변환 맵
  static final Map<String, String> _ingredientMap = {
    // 채소
    'carrot': '당근',
    'onion': '양파',
    'garlic': '마늘',
    'potato': '감자',
    'tomato': '토마토',
    'cucumber': '오이',
    'lettuce': '상추',
    'cabbage': '양배추',
    'spinach': '시금치',
    'broccoli': '브로콜리',
    'mushroom': '버섯',
    'pepper': '고추',
    'bell pepper': '피망',
    'zucchini': '호박',
    'eggplant': '가지',
    'radish': '무',
    'celery': '셀러리',
    'corn': '옥수수',
    
    // 과일
    'apple': '사과',
    'banana': '바나나',
    'orange': '오렌지',
    'strawberry': '딸기',
    'grape': '포도',
    'watermelon': '수박',
    'melon': '멜론',
    'peach': '복숭아',
    'pear': '배',
    'kiwi': '키위',
    
    // 육류
    'beef': '소고기',
    'pork': '돼지고기',
    'chicken': '닭고기',
    'chicken breast': '닭가슴살',
    'chicken thigh': '닭다리살',
    'bacon': '베이컨',
    'ham': '햄',
    'sausage': '소시지',
    'ground beef': '다진 소고기',
    'ground pork': '다진 돼지고기',
    
    // 해산물
    'fish': '생선',
    'salmon': '연어',
    'tuna': '참치',
    'shrimp': '새우',
    'squid': '오징어',
    'octopus': '문어',
    'crab': '게',
    'clam': '조개',
    'mussel': '홍합',
    
    // 곡물
    'rice': '쌀',
    'noodle': '면',
    'pasta': '파스타',
    'spaghetti': '스파게티',
    'bread': '빵',
    'flour': '밀가루',
    'wheat': '밀',
    
    // 유제품
    'milk': '우유',
    'cheese': '치즈',
    'butter': '버터',
    'yogurt': '요구르트',
    'cream': '크림',
    'egg': '계란',
    'eggs': '계란',
    
    // 소스/양념
    'salt': '소금',
    'pepper': '후추',
    'sugar': '설탕',
    'soy sauce': '간장',
    'vinegar': '식초',
    'oil': '식용유',
    'olive oil': '올리브유',
    'sesame oil': '참기름',
    'garlic': '마늘',
    'ginger': '생강',
    'soybean paste': '된장',
    'red pepper paste': '고추장',
    'ketchup': '케첩',
    'mayonnaise': '마요네즈',
    'mustard': '겨자',
    
    // 기타
    'tofu': '두부',
    'bean sprout': '콩나물',
    'seaweed': '김',
    'nori': '김',
    'sesame': '깨',
    'sesame seed': '깨',
  };

  // 레시피 이름 영어 -> 한글 변환 맵
  static final Map<String, String> _recipeMap = {
    'fried rice': '볶음밥',
    'kimchi fried rice': '김치볶음밥',
    'egg fried rice': '계란볶음밥',
    'stir-fried': '볶음',
    'stir fry': '볶음',
    'fried': '튀김',
    'grilled': '구이',
    'roasted': '구운',
    'steamed': '찜',
    'boiled': '삶은',
    'soup': '국',
    'stew': '찌개',
    'curry': '카레',
    'pasta': '파스타',
    'spaghetti': '스파게티',
    'salad': '샐러드',
    'sandwich': '샌드위치',
    'pizza': '피자',
    'burger': '버거',
    'omelet': '오믈렛',
    'scrambled eggs': '스크램블 에그',
    'pancake': '팬케이크',
    'chicken': '닭고기',
    'beef': '소고기',
    'pork': '돼지고기',
    'fish': '생선',
    'vegetable': '야채',
    'vegetables': '야채',
    'noodle': '면',
    'noodles': '면',
    'rice': '밥',
    'soup': '국',
    'stew': '찌개',
    'japchae': '잡채',
    'bibimbap': '비빔밥',
    'bulgogi': '불고기',
    'galbi': '갈비',
    'samgyeopsal': '삼겹살',
    'kimchi': '김치',
    'kimchi jjigae': '김치찌개',
    'doenjang jjigae': '된장찌개',
    'soondubu jjigae': '순두부찌개',
  };

  /// 재료 이름을 한글로 변환
  static String translateIngredient(String englishName) {
    // 소문자로 변환하여 비교
    final lowerName = englishName.toLowerCase().trim();
    
    // 정확히 일치하는 경우
    if (_ingredientMap.containsKey(lowerName)) {
      return _ingredientMap[lowerName]!;
    }
    
    // 부분 일치 검색 (예: "carrot"이 "carrots"에 포함되는 경우)
    for (final entry in _ingredientMap.entries) {
      if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
        return entry.value;
      }
    }
    
    // 변환할 수 없으면 원본 반환
    return englishName;
  }

  /// 레시피 이름을 한글로 변환
  static String translateRecipeName(String englishName) {
    // 소문자로 변환하여 비교
    final lowerName = englishName.toLowerCase().trim();
    
    // 정확히 일치하는 경우
    if (_recipeMap.containsKey(lowerName)) {
      return _recipeMap[lowerName]!;
    }
    
    // 부분 일치 검색 (여러 키워드 조합)
    String translated = englishName;
    for (final entry in _recipeMap.entries) {
      if (lowerName.contains(entry.key)) {
        translated = translated.replaceAll(
          RegExp(entry.key, caseSensitive: false),
          entry.value,
        );
      }
    }
    
    // 변환이 일어났으면 변환된 값 반환, 아니면 원본 반환
    return translated != englishName ? translated : englishName;
  }
}
