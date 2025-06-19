class OpenFoodFactsProduct {
  final String? productName;
  final String? brands;
  final String? quantity;
  final String? imageUrl;
  final Nutriments? nutriments;
  final int status;
  final String? statusVerbose;
  final String? barcode; // Code-barres du produit

  OpenFoodFactsProduct({
    this.productName,
    this.brands,
    this.quantity,
    this.imageUrl,
    this.nutriments,
    required this.status,
    this.statusVerbose,
    this.barcode,
  });

  factory OpenFoodFactsProduct.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    
    return OpenFoodFactsProduct(
      status: json['status'] ?? 0,
      statusVerbose: json['status_verbose'],
      productName: product?['product_name'] ?? product?['product_name_fr'],
      brands: product?['brands'],
      quantity: product?['quantity'],
      imageUrl: product?['image_url'] ?? product?['image_front_url'],
      nutriments: product?['nutriments'] != null 
          ? Nutriments.fromJson(product!['nutriments'] as Map<String, dynamic>)
          : null,
    );
  }

  // Get default quantity value (try to parse from quantity string, fallback to 100)
  double get defaultQuantity {
    if (quantity == null) return 100.0;
    
    // Extract numeric value from quantity string (e.g., "170g", "41,5 g e" -> 41.5)
    // Handle both comma and dot as decimal separators
    final RegExp regExp = RegExp(r'(\d+(?:[,\.]\d+)?)');
    final match = regExp.firstMatch(quantity!);
    if (match != null) {
      String numberStr = match.group(1)!;
      // Replace comma with dot for parsing
      numberStr = numberStr.replaceAll(',', '.');
      return double.tryParse(numberStr) ?? 100.0;
    }
    
    return 100.0;
  }

  // Get unit from quantity (e.g., "170g" -> "g", "41,5 g e" -> "g")
  String get unit {
    if (quantity == null) return 'g';
    
    // Remove the numeric part (including decimal) and extract the first word as unit
    // Handle both comma and dot as decimal separators
    final RegExp regExp = RegExp(r'\d+(?:[,\.]\d+)?\s*(\w+)');
    final match = regExp.firstMatch(quantity!);
    if (match != null && match.group(1)!.isNotEmpty) {
      return match.group(1)!.trim();
    }
    
    // Fallback: if no clear unit found, try to extract first alphabetic sequence
    final RegExp fallbackRegExp = RegExp(r'[a-zA-Z]+');
    final fallbackMatch = fallbackRegExp.firstMatch(quantity!);
    if (fallbackMatch != null) {
      return fallbackMatch.group(0)!.trim();
    }
    
    return 'g';
  }
}

class Nutriments {
  final double? energyKcal100g;
  final double? energyKcalServing;
  final double? proteins100g;
  final double? proteinsServing;
  final double? carbohydrates100g;
  final double? carbohydratesServing;
  final double? fat100g;
  final double? fatServing;

  Nutriments({
    this.energyKcal100g,
    this.energyKcalServing,
    this.proteins100g,
    this.proteinsServing,
    this.carbohydrates100g,
    this.carbohydratesServing,
    this.fat100g,
    this.fatServing,
  });

  factory Nutriments.fromJson(Map<String, dynamic> json) {
    return Nutriments(
      energyKcal100g: _parseDouble(json['energy-kcal_100g']),
      energyKcalServing: _parseDouble(json['energy-kcal_serving']),
      proteins100g: _parseDouble(json['proteins_100g']),
      proteinsServing: _parseDouble(json['proteins_serving']),
      carbohydrates100g: _parseDouble(json['carbohydrates_100g']),
      carbohydratesServing: _parseDouble(json['carbohydrates_serving']),
      fat100g: _parseDouble(json['fat_100g']),
      fatServing: _parseDouble(json['fat_serving']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Get calories per 100g (prefer 100g value, fallback to serving)
  double get caloriesPer100g {
    return energyKcal100g ?? energyKcalServing ?? 0.0;
  }

  // Get proteins per 100g
  double get proteinsPer100g {
    return proteins100g ?? proteinsServing ?? 0.0;
  }

  // Get carbohydrates per 100g
  double get carbohydratesPer100g {
    return carbohydrates100g ?? carbohydratesServing ?? 0.0;
  }

  // Get fat per 100g
  double get fatPer100g {
    return fat100g ?? fatServing ?? 0.0;
  }
} 