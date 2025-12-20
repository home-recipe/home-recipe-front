class IngredientResponse {
  final int id; // Long 타입
  final String category; // 서버에서 받은 그대로 (VEGETABLE, FRUIT 등)
  final String name;

  IngredientResponse({
    required this.id,
    required this.category,
    required this.name,
  });

  factory IngredientResponse.fromJson(Map<String, dynamic> json) {
    return IngredientResponse(
      id: json['id'] as int,
      category: json['category'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
    };
  }
}

