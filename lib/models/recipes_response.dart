enum RecipeDecision {
  COOK,
  DELIVERY;

  static RecipeDecision fromString(String value) {
    return RecipeDecision.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => RecipeDecision.COOK,
    );
  }
}

class RecipesResponse {
  final RecipeDecision decision;
  final String reason;
  final List<RecipeDetail>? recipes;

  RecipesResponse({
    required this.decision,
    required this.reason,
    this.recipes,
  });

  factory RecipesResponse.fromJson(Map<String, dynamic> json) {
    return RecipesResponse(
      decision: RecipeDecision.fromString(json['decision'] as String? ?? 'COOK'),
      reason: json['reason'] as String? ?? '',
      recipes: json['recipes'] != null
          ? (json['recipes'] as List<dynamic>)
              .map((item) => RecipeDetail.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'decision': decision.name,
      'reason': reason,
      'recipes': recipes?.map((recipe) => recipe.toJson()).toList(),
    };
  }
}

class RecipeDetail {
  final String recipeName;
  final List<String> ingredients;
  final List<String> steps;

  RecipeDetail({
    required this.recipeName,
    required this.ingredients,
    required this.steps,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      recipeName: json['recipeName'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipeName': recipeName,
      'ingredients': ingredients,
      'steps': steps,
    };
  }
}


