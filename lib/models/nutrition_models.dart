import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Meal {
  final String time;
  final String name;
  final List<FoodItem> items;

  Meal({
    required this.time,
    required this.name,
    required this.items,
  });
  
  void addItem(FoodItem item) {
    items.add(item);
  }
}

class FoodItem {
  final String? id;
  final String name;
  final int calories;
  final double proteins;
  final double carbs;
  final double fats;
  final String portion;
  final bool isModified;
  final bool hasModifiedMacros;
  final bool isCustom;
  final bool isRecipe;
  final bool isScanned; // Nouvel attribut pour les produits scannés
  final String? referenceUnitFr;
  final String? referenceUnitEn;
  final double? referenceQuantity;

  FoodItem({
    this.id,
    required this.name,
    required this.calories,
    this.proteins = 0.0,
    this.carbs = 0.0,
    this.fats = 0.0,
    required this.portion,
    this.isModified = false,
    this.hasModifiedMacros = false,
    this.isCustom = false,
    this.isRecipe = false,
    this.isScanned = false,
    this.referenceUnitFr,
    this.referenceUnitEn,
    this.referenceQuantity,
  });

  FoodItem copyWith({
    String? id,
    String? name,
    int? calories,
    double? proteins,
    double? carbs,
    double? fats,
    String? portion,
    bool? isModified,
    bool? hasModifiedMacros,
    bool? isCustom,
    bool? isRecipe,
    bool? isScanned,
    String? referenceUnitFr,
    String? referenceUnitEn,
    double? referenceQuantity,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      portion: portion ?? this.portion,
      isModified: isModified ?? this.isModified,
      hasModifiedMacros: hasModifiedMacros ?? this.hasModifiedMacros,
      isCustom: isCustom ?? this.isCustom,
      isRecipe: isRecipe ?? this.isRecipe,
      isScanned: isScanned ?? this.isScanned,
      referenceUnitFr: referenceUnitFr ?? this.referenceUnitFr,
      referenceUnitEn: referenceUnitEn ?? this.referenceUnitEn,
      referenceQuantity: referenceQuantity ?? this.referenceQuantity,
    );
  }

  String? getLocalizedUnit(String language) {
    return language == 'fr' ? referenceUnitFr : referenceUnitEn;
  }
  
  // Détermine si une icône doit être affichée selon les nouvelles règles
  bool get shouldShowCustomIcon {
    // Règle 1: Aliment scanné (dans custom_foods ou non) → icône scan
    if (isScanned) return true;
    
    // Règle 2: Custom food avec origin='manual' → icône user
    if (isCustom && !isScanned) return true;
    
    // Règle 3: Aliment de base avec macros modifiés → icône user
    if (!isCustom && hasModifiedMacros) return true;
    
    // Règle 4: Recette avec ingrédient modifié → icône user
    if (isRecipe && hasModifiedMacros) return true;
    
    return false;
  }
  
  // Détermine quelle icône afficher selon les nouvelles règles
  IconData get displayIcon {
    // Règle 1: Aliment scanné → icône scan (peu importe s'il est custom ou non)
    if (isScanned) return LucideIcons.scan;
    
    // Toutes les autres règles → icône user
    return LucideIcons.user;
  }
} 
