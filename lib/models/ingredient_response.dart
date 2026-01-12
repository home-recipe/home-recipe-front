enum Source {
  DATABASE,
  OPEN_API;

  static Source fromString(String value) {
    return Source.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => Source.DATABASE,
    );
  }
}

class IngredientResponse {
  final int? id; // Long 타입, nullable
  final String? category; // 서버에서 받은 그대로 (VEGETABLE, FRUIT 등), nullable
  final String name;
  final Source source;

  IngredientResponse({
    this.id,
    this.category,
    required this.name,
    required this.source,
  });

  factory IngredientResponse.fromJson(Map<String, dynamic> json) {
    return IngredientResponse(
      id: json['id'] as int?,
      category: json['category'] as String?,
      name: json['name'] as String,
      source: Source.fromString(json['source'] as String? ?? 'DATABASE'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'source': source.name,
    };
  }
}

