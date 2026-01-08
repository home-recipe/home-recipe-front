import 'ingredient_response.dart';

class OpenApiIngredientResponse {
  final String name;
  final Source source;

  OpenApiIngredientResponse({
    required this.name,
    required this.source,
  });

  factory OpenApiIngredientResponse.fromJson(Map<String, dynamic> json) {
    return OpenApiIngredientResponse(
      name: json['name'] as String,
      source: Source.fromString(json['source'] as String? ?? 'OPEN_API'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source.name,
    };
  }
}
