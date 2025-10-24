/// Model for AI analysis results from Google Vision API
class AIAnalysisResult {
  final bool success;
  final String? error;
  final List<DetectedFood> detectedFoods;
  final double processingTime;
  final String? mealName; // Nom généré par l'IA pour le plat

  AIAnalysisResult({
    required this.success,
    this.error,
    required this.detectedFoods,
    required this.processingTime,
    this.mealName,
  });

  factory AIAnalysisResult.success({
    required List<DetectedFood> detectedFoods,
    required double processingTime,
    String? mealName,
  }) {
    return AIAnalysisResult(
      success: true,
      detectedFoods: detectedFoods,
      processingTime: processingTime,
      mealName: mealName,
    );
  }

  factory AIAnalysisResult.error({
    required String error,
    required double processingTime,
  }) {
    return AIAnalysisResult(
      success: false,
      error: error,
      detectedFoods: [],
      processingTime: processingTime,
    );
  }
}

/// Model for detected food items
class DetectedFood {
  final String name;
  final double confidence;
  final double estimatedQuantity; // En grammes ou ml
  final NutritionEstimate nutrition; // En grammes de macros
  final FoodCategory category;
  final bool isLiquid; // Pour afficher ml au lieu de g

  DetectedFood({
    required this.name,
    required this.confidence,
    required this.estimatedQuantity,
    required this.nutrition,
    required this.category,
    this.isLiquid = false,
  });

  /// Calculer les calories selon la formule de l'app: (protéines * 4) + (glucides * 4) + (lipides * 9)
  int get calories => ((nutrition.proteins * 4) + (nutrition.carbs * 4) + (nutrition.fats * 9)).round();

  factory DetectedFood.fromVisionLabel({
    required String label,
    required double confidence,
    String cultureContext = 'International cuisine and standard portion sizes',
  }) {
    final category = _determineFoodCategory(label);
    // Use smart estimation that considers visual cues and cultural context
    final quantity = _estimateVisualQuantity(label, category, cultureContext);
    final nutrition = _estimateNutrition(quantity, category);

    return DetectedFood(
      name: _formatFoodName(label),
      confidence: confidence,
      estimatedQuantity: quantity,
      nutrition: nutrition,
      category: category,
    );
  }
  
  /// Create from AI response with custom portions (when AI provides them)
  factory DetectedFood.fromAIResponse({
    required String name,
    required double confidence,
    required double portionGrams,
    required double proteins,
    required double carbs,
    required double fats,
    bool isLiquid = false,
  }) {
    final category = _determineFoodCategory(name);

    return DetectedFood(
      name: _formatFoodName(name),
      confidence: confidence,
      estimatedQuantity: portionGrams,
      nutrition: NutritionEstimate(
        proteins: proteins,
        carbs: carbs,
        fats: fats,
      ),
      isLiquid: isLiquid,
      category: category,
    );
  }

  static FoodCategory _determineFoodCategory(String label) {
    final lowerLabel = label.toLowerCase();
    
    if (_vegetables.any((v) => lowerLabel.contains(v))) {
      return FoodCategory.vegetable;
    } else if (_fruits.any((f) => lowerLabel.contains(f))) {
      return FoodCategory.fruit;
    } else if (_proteins.any((p) => lowerLabel.contains(p))) {
      return FoodCategory.protein;
    } else if (_grains.any((g) => lowerLabel.contains(g))) {
      return FoodCategory.grain;
    } else if (_dairy.any((d) => lowerLabel.contains(d))) {
      return FoodCategory.dairy;
    } else if (_beverages.any((b) => lowerLabel.contains(b))) {
      return FoodCategory.beverage;
    } else {
      return FoodCategory.mixed;
    }
  }


  /// Estimate quantity based on visual cues and cultural context
  static double _estimateVisualQuantity(
    String label, 
    FoodCategory category, 
    String cultureContext,
  ) {
    // This is a fallback estimation for when AI doesn't provide portions
    // In practice, we want the AI to analyze visual cues like:
    // - Plate size relative to food
    // - Food volume and density  
    // - Comparison to common objects for scale
    // - Typical serving presentations
    
    final lowerLabel = label.toLowerCase();
    
    // Smart estimation considering visual presentation
    if (lowerLabel.contains('salade') || lowerLabel.contains('lettuce')) {
      return _adjustForCulture(80.0, cultureContext); // Base: side salad
    } else if (lowerLabel.contains('tomate') || lowerLabel.contains('tomato')) {
      return _adjustForCulture(100.0, cultureContext); // Base: 1 medium tomato
    } else if (lowerLabel.contains('pomme') || lowerLabel.contains('apple')) {
      return _adjustForCulture(150.0, cultureContext); // Base: 1 medium apple
    } else if (lowerLabel.contains('banane') || lowerLabel.contains('banana')) {
      return _adjustForCulture(120.0, cultureContext); // Base: 1 medium banana
    } else if (lowerLabel.contains('riz') || lowerLabel.contains('rice')) {
      return _adjustForCulture(100.0, cultureContext); // Base: cooked rice portion
    } else if (lowerLabel.contains('pâtes') || lowerLabel.contains('pasta')) {
      return _adjustForCulture(100.0, cultureContext); // Base: cooked pasta portion
    } else if (lowerLabel.contains('pain') || lowerLabel.contains('bread')) {
      return _adjustForCulture(40.0, cultureContext); // Base: 2 slices
    } else if (lowerLabel.contains('fromage') || lowerLabel.contains('cheese')) {
      return _adjustForCulture(30.0, cultureContext); // Base: cheese portion
    }
    
    // Category-based estimation with cultural adjustments
    switch (category) {
      case FoodCategory.vegetable:
        return _adjustForCulture(100.0, cultureContext);
      case FoodCategory.fruit:
        return _adjustForCulture(130.0, cultureContext);
      case FoodCategory.protein:
        return _adjustForCulture(120.0, cultureContext);
      case FoodCategory.grain:
        return _adjustForCulture(100.0, cultureContext);
      case FoodCategory.dairy:
        return _adjustForCulture(125.0, cultureContext);
      case FoodCategory.beverage:
        return _adjustForCulture(200.0, cultureContext);
      case FoodCategory.mixed:
        return _adjustForCulture(150.0, cultureContext);
    }
  }
  
  /// Adjust base portion for cultural differences
  static double _adjustForCulture(double basePortion, String cultureContext) {
    // Adjust portions based on cultural context
    if (cultureContext.contains('American')) {
      return basePortion * 1.3; // American portions tend to be larger
    } else if (cultureContext.contains('Japanese')) {
      return basePortion * 0.8; // Japanese portions tend to be smaller
    } else if (cultureContext.contains('Italian') && cultureContext.contains('pasta')) {
      return basePortion * 1.2; // Italians serve more pasta
    } else if (cultureContext.contains('Indian')) {
      return basePortion * 0.9; // Smaller individual portions, but multiple dishes
    }
    // Default: no adjustment for most cultures
    return basePortion;
  }

  static NutritionEstimate _estimateNutrition(double quantityGrams, FoodCategory category) {
    // Macronutriments pour 100g, puis ajustés à la quantité réelle
    double proteinsPer100g, carbsPer100g, fatsPer100g;
    
    switch (category) {
      case FoodCategory.vegetable:
        proteinsPer100g = 2.0;  // 2g protéines pour 100g légumes
        carbsPer100g = 4.0;     // 4g glucides pour 100g légumes
        fatsPer100g = 0.2;      // 0.2g lipides pour 100g légumes
        break;
      case FoodCategory.fruit:
        proteinsPer100g = 0.8;  // 0.8g protéines pour 100g fruits
        carbsPer100g = 12.0;    // 12g glucides pour 100g fruits
        fatsPer100g = 0.3;      // 0.3g lipides pour 100g fruits
        break;
      case FoodCategory.protein:
        proteinsPer100g = 25.0; // 25g protéines pour 100g viande/poisson
        carbsPer100g = 0.0;     // 0g glucides pour 100g viande/poisson
        fatsPer100g = 8.0;      // 8g lipides pour 100g viande/poisson
        break;
      case FoodCategory.grain:
        proteinsPer100g = 8.0;  // 8g protéines pour 100g féculents cuits
        carbsPer100g = 25.0;    // 25g glucides pour 100g féculents cuits
        fatsPer100g = 1.0;      // 1g lipides pour 100g féculents cuits
        break;
      case FoodCategory.dairy:
        proteinsPer100g = 8.0;  // 8g protéines pour 100g produits laitiers
        carbsPer100g = 5.0;     // 5g glucides pour 100g produits laitiers
        fatsPer100g = 6.0;      // 6g lipides pour 100g produits laitiers
        break;
      case FoodCategory.beverage:
        proteinsPer100g = 0.5;  // 0.5g protéines pour 100ml boissons
        carbsPer100g = 8.0;     // 8g glucides pour 100ml boissons
        fatsPer100g = 0.1;      // 0.1g lipides pour 100ml boissons
        break;
      case FoodCategory.mixed:
        proteinsPer100g = 12.0; // 12g protéines pour 100g plat mixte
        carbsPer100g = 15.0;    // 15g glucides pour 100g plat mixte
        fatsPer100g = 8.0;      // 8g lipides pour 100g plat mixte
        break;
    }

    // Ajuster à la quantité réelle
    final factor = quantityGrams / 100.0;
    return NutritionEstimate(
      proteins: (proteinsPer100g * factor * 10).round() / 10.0, // Arrondi à 0.1g
      carbs: (carbsPer100g * factor * 10).round() / 10.0,
      fats: (fatsPer100g * factor * 10).round() / 10.0,
    );
  }

  static String _formatFoodName(String label) {
    // Capitalize first letter and format nicely
    return label.toLowerCase().split(' ')
        .map((word) => word.isEmpty ? word : 
             word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Food category keywords
  static const _vegetables = [
    'broccoli', 'carrot', 'spinach', 'lettuce', 'tomato', 'onion', 'pepper',
    'cucumber', 'celery', 'cauliflower', 'cabbage', 'peas', 'beans', 'corn'
  ];

  static const _fruits = [
    'apple', 'banana', 'orange', 'berry', 'grape', 'lemon', 'lime', 'cherry',
    'peach', 'pear', 'plum', 'strawberry', 'blueberry', 'raspberry', 'kiwi'
  ];

  static const _proteins = [
    'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'egg', 'tofu',
    'turkey', 'duck', 'lamb', 'shrimp', 'crab', 'lobster', 'meat'
  ];

  static const _grains = [
    'rice', 'pasta', 'bread', 'cereal', 'oats', 'quinoa', 'wheat', 'barley',
    'noodles', 'couscous', 'bulgur', 'millet'
  ];

  static const _dairy = [
    'milk', 'cheese', 'yogurt', 'butter', 'cream', 'ice cream'
  ];

  static const _beverages = [
    'juice', 'soda', 'coffee', 'tea', 'water', 'wine', 'beer', 'smoothie'
  ];
}

/// Nutrition estimates for detected food
class NutritionEstimate {
  final double proteins;
  final double carbs;
  final double fats;

  NutritionEstimate({
    required this.proteins,
    required this.carbs,
    required this.fats,
  });
}

/// Food categories for better nutrition estimation
enum FoodCategory {
  vegetable,
  fruit,
  protein,
  grain,
  dairy,
  beverage,
  mixed,
}

/// Google Vision API response models
class GoogleVisionResponse {
  final List<GoogleVisionAnnotation> labelAnnotations;
  final List<GoogleVisionAnnotation> localizedObjectAnnotations;
  final GoogleVisionError? error;

  GoogleVisionResponse({
    required this.labelAnnotations,
    required this.localizedObjectAnnotations,
    this.error,
  });

  factory GoogleVisionResponse.fromJson(Map<String, dynamic> json) {
    return GoogleVisionResponse(
      labelAnnotations: (json['labelAnnotations'] as List<dynamic>? ?? [])
          .map((item) => GoogleVisionAnnotation.fromJson(item))
          .toList(),
      localizedObjectAnnotations: (json['localizedObjectAnnotations'] as List<dynamic>? ?? [])
          .map((item) => GoogleVisionAnnotation.fromJson(item))
          .toList(),
      error: json['error'] != null 
          ? GoogleVisionError.fromJson(json['error'])
          : null,
    );
  }
}

class GoogleVisionAnnotation {
  final String description;
  final double score;

  GoogleVisionAnnotation({
    required this.description,
    required this.score,
  });

  factory GoogleVisionAnnotation.fromJson(Map<String, dynamic> json) {
    return GoogleVisionAnnotation(
      description: json['description'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GoogleVisionError {
  final String message;
  final int code;

  GoogleVisionError({
    required this.message,
    required this.code,
  });

  factory GoogleVisionError.fromJson(Map<String, dynamic> json) {
    return GoogleVisionError(
      message: json['message'] ?? '',
      code: json['code'] ?? 0,
    );
  }
}