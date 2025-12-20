import 'ingredient_response.dart';

class RefrigeratorResponse {
  final List<IngredientResponse> myRefrigerator;

  RefrigeratorResponse({
    required this.myRefrigerator,
  });

  factory RefrigeratorResponse.fromJson(Map<String, dynamic> json) {
    return RefrigeratorResponse(
      myRefrigerator: (json['myRefrigerator'] as List<dynamic>)
          .map((item) => IngredientResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'myRefrigerator': myRefrigerator.map((item) => item.toJson()).toList(),
    };
  }
}

