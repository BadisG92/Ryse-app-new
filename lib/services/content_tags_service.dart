import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/app_config.dart';
import 'recipe_service.dart';
import 'localization_service.dart';

class ContentTagsService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  /// Vérifie que content_tags contient des tags de recettes
  static Future<bool> checkRecipeTagsExist() async {
    try {
      print('🔍 ContentTagsService: Vérification des tags de recettes dans content_tags...');
      
      final response = await _supabase
          .from('content_tags')
          .select('id')
          .eq('app part', 'recettes')
          .limit(1);

      bool hasRecipeTags = response.isNotEmpty;
      
      if (hasRecipeTags) {
        print('✅ Tags de recettes trouvés dans content_tags');
      } else {
        print('⚠️ Aucun tag de recette trouvé dans content_tags');
      }
      
      return hasRecipeTags;
    } catch (e) {
      print('❌ Erreur lors de la vérification des tags: $e');
      return false;
    }
  }

  /// Organise les tags par catégories intelligentes multilingues
  static Map<String, Set<String>> _organizeTagsByCategory(Set<String> allTags) {
    Map<String, Set<String>> organized = {
      'type_alimentation': <String>{}, // Régime alimentaire
      'moment_consommation': <String>{}, // Moment de consommation  
      'type_plat': <String>{}, // Type de plat
      'duree': <String>{}, // Durée de préparation
      'difficulte': <String>{}, // Difficulté
      'calories': <String>{}, // Niveau calorique
      'autres': <String>{}, // Autres
    };

    for (final tag in allTags) {
      final lowerTag = tag.toLowerCase();
      
      // Type d'alimentation (régime)
      if (_isRegimeTag(lowerTag)) {
        organized['type_alimentation']!.add(tag);
      }
      // Moment de consommation
      else if (_isMomentTag(lowerTag)) {
        organized['moment_consommation']!.add(tag);
      }
      // Type de plat
      else if (_isTypeTag(lowerTag)) {
        organized['type_plat']!.add(tag);
      }
      // Durée
      else if (_isTimeTag(lowerTag)) {
        organized['duree']!.add(tag);
      }
      // Difficulté
      else if (_isDifficultyTag(lowerTag)) {
        organized['difficulte']!.add(tag);
      }
      // Calories (détection par mots-clés)
      else if (_isCalorieTag(lowerTag)) {
        organized['calories']!.add(tag);
      }
      // Autres
      else {
        organized['autres']!.add(tag);
      }
    }

    // Supprimer les catégories vides
    organized.removeWhere((key, value) => value.isEmpty);
    
    // Afficher les résultats pour debug
    for (final category in organized.keys) {
      print('📂 ${_getCategoryDisplayName(category)}: ${organized[category]!.length} tags');
      print('   ${organized[category]!.take(5).toList()}...');
    }
    
    return organized;
  }

  /// Retourne le nom d'affichage d'une catégorie
  static String _getCategoryDisplayName(String categoryKey) {
    switch (categoryKey) {
      case 'type_alimentation': return 'Type d\'alimentation';
      case 'moment_consommation': return 'Moment de consommation';
      case 'type_plat': return 'Type de plat';
      case 'duree': return 'Durée';
      case 'difficulte': return 'Difficulté';
      case 'calories': return 'Calories';
      case 'autres': return 'Autres';
      default: return categoryKey;
    }
  }

  /// Vérifie si un tag concerne le moment de consommation
  static bool _isMomentTag(String tag) {
    const momentKeywords = [
      'petit-déjeuner', 'breakfast', 'petit déjeuner', 'matin',
      'déjeuner', 'lunch', 'midi', 
      'collation', 'snack', 'goûter', 'encas',
      'dîner', 'dinner', 'soir', 'souper',
      'apéritif', 'apéro', 'brunch'
    ];
    return momentKeywords.any((keyword) => tag.contains(keyword));
  }

  /// Vérifie si un tag concerne le régime alimentaire
  static bool _isRegimeTag(String tag) {
    const regimeKeywords = [
      'végétarien', 'vegetarian', 'veggie',
      'végan', 'vegan', 'végétalien',
      'sans gluten', 'gluten', 'gluten-free',
      'keto', 'cétogène', 'low carb',
      'paléo', 'paleo', 'paleolithic',
      'méditerranéen', 'mediterranean',
      'bio', 'organic', 'naturel',
      'halal', 'casher', 'kosher',
      'sans lactose', 'lactose-free'
    ];
    return regimeKeywords.any((keyword) => tag.contains(keyword));
  }

  /// Vérifie si un tag concerne le type de plat
  static bool _isTypeTag(String tag) {
    const typeKeywords = [
      'entrée', 'starter', 'appetizer',
      'plat principal', 'main course', 'plat',
      'dessert', 'desserts',
      'boisson', 'drink', 'cocktail', 'smoothie',
      'salade', 'salad',
      'soupe', 'soup', 'potage',
      'pâtes', 'pasta',
      'pizza', 'burger', 'sandwich', 'wrap'
    ];
    return typeKeywords.any((keyword) => tag.contains(keyword));
  }

  /// Vérifie si un tag concerne la difficulté
  static bool _isDifficultyTag(String tag) {
    const difficultyKeywords = [
      'facile', 'easy', 'simple',
      'moyen', 'medium', 'intermédiaire',
      'difficile', 'hard', 'complexe', 'avancé'
    ];
    return difficultyKeywords.any((keyword) => tag.contains(keyword));
  }

  /// Vérifie si un tag concerne le temps de préparation
  static bool _isTimeTag(String tag) {
    const timeKeywords = [
      'rapide', 'quick', 'express',
      '5 min', '10 min', '15 min', '30 min',
      'lent', 'slow', 'mijoté',
      'préparation', 'prep', 'cuisson'
    ];
    return timeKeywords.any((keyword) => tag.contains(keyword));
  }

  /// Vérifie si un tag concerne les calories
  static bool _isCalorieTag(String tag) {
    const calorieKeywords = [
      'léger', 'light', 'faible calorie',
      'riche', 'lourd', 'high calorie',
      'diététique', 'diet', 'minceur',
      'kcal', 'calorie', 'énergétique'
    ];
    return calorieKeywords.any((keyword) => tag.contains(keyword));
  }

  /// Insère un tag multilingue dans content_tags s'il n'existe pas déjà
  static Future<void> _insertTagIfNotExists(String tagName, String category) async {
    try {
      // Vérifier si le tag existe déjà (vérifier dans name_fr et name_en)
      final existing = await _supabase
          .from('content_tags')
          .select('id')
          .or('name_fr.eq.$tagName,name_en.eq.$tagName')
          .eq('category', category)
          .maybeSingle();

      if (existing == null) {
        // Déterminer si c'est français ou anglais
        bool isFrench = _isFrenchTag(tagName);
        
        // Insérer le nouveau tag multilingue
        await _supabase
            .from('content_tags')
            .insert({
              'name_fr': isFrench ? tagName : null,
              'name_en': isFrench ? null : tagName,
              'category': category,
              'app part': 'recettes',
              // Pas de couleur comme demandé
            });
        print('✅ Tag ajouté: $tagName ($category) [${isFrench ? 'FR' : 'EN'}]');
      } else {
        print('⚪ Tag existe déjà: $tagName');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'insertion du tag "$tagName": $e');
    }
  }

  /// Détermine si un tag est en français
  static bool _isFrenchTag(String tag) {
    const frenchIndicators = [
      'é', 'è', 'à', 'ç', 'ù', 'ê', 'â', 'î', 'ô', 'û', 'ë', 'ï', 'ÿ',
      'végétarien', 'végan', 'déjeuner', 'dîner', 'collation', 'goûter',
      'rapide', 'facile', 'difficile', 'léger', 'riche'
    ];
    return frenchIndicators.any((indicator) => tag.toLowerCase().contains(indicator));
  }

  /// Récupère tous les tags organisés depuis content_tags pour les filtres
  static Future<Map<String, List<String>>> getOrganizedTagsForFilters() async {
    try {
      final locService = LocalizationService.instance;
      final language = locService.currentLanguageCode;
      print('🔍 Récupération des tags depuis content_tags (langue: $language)...');
      
      // Sélectionner les colonnes selon la langue
      final suffix = locService.getColumnSuffix();
      final nameColumn = 'name$suffix';
      final categoryColumn = 'category$suffix';
      
      final response = await _supabase
          .from('content_tags')
          .select('$nameColumn, $categoryColumn, name_fr, name_en, category_fr, category_en')
          .eq('app part', 'recettes');

      print('🔍 Données brutes récupérées: ${response.length} tags');
      if (response.isNotEmpty) {
        print('🔍 Premier tag exemple: ${response[0]}');
      }
      
      Map<String, List<String>> organizedTags = {};
      
      for (var tagData in response) {
        // Récupérer le nom et la catégorie selon la langue avec fallback automatique
        final tagName = locService.getTextFromColumns(tagData['name_fr'], tagData['name_en']);
        final categoryName = locService.getTextFromColumns(tagData['category_fr'], tagData['category_en']);
        
        // Ajouter le tag à sa catégorie
        if (tagName != null && tagName.isNotEmpty && categoryName != null && categoryName.isNotEmpty) {
          if (!organizedTags.containsKey(categoryName)) {
            organizedTags[categoryName] = [];
          }
          organizedTags[categoryName]!.add(tagName);
          print('   + Tag ajouté: "$tagName" dans catégorie "$categoryName"');
        }
      }

      print('✅ ${organizedTags.keys.length} catégories trouvées avec ${organizedTags.values.fold(0, (sum, list) => sum + list.length)} tags total');
      for (final category in organizedTags.keys) {
        print('   - $category: ${organizedTags[category]!.length} tags');
      }

      return organizedTags;
    } catch (e) {
      print('❌ Erreur lors de la récupération des tags organisés: $e');
      return {};
    }
  }
}