class RecommendationsResponse {
  final List<RecommendationDetail> recommendations;

  RecommendationsResponse({
    required this.recommendations,
  });

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationsResponse(
      recommendations: json['recommendations'] != null
          ? (json['recommendations'] as List<dynamic>)
              .map((item) => RecommendationDetail.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations.map((rec) => rec.toJson()).toList(),
    };
  }
}

class RecommendationDetail {
  final String recipeName;
  final List<String> ingredients;

  RecommendationDetail({
    required this.recipeName,
    required this.ingredients,
  });

  factory RecommendationDetail.fromJson(Map<String, dynamic> json) {
    return RecommendationDetail(
      recipeName: json['recipeName'] as String? ?? '',
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List<dynamic>)
              .map((item) => item as String)
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipeName': recipeName,
      'ingredients': ingredients,
    };
  }
}

