import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/create_custom_food_bottom_sheet.dart';
import '../models/nutrition_models.dart';
import '../components/ui/nutrition_widgets.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../types/database_types.dart';

class ManualFoodSearchBottomSheet extends StatefulWidget {
  final Function(FoodItem foodItem) onFoodCreated;
  final bool isFromDashboard;
  final ScrollController? scrollController;

  const ManualFoodSearchBottomSheet({
    super.key,
    required this.onFoodCreated,
    this.isFromDashboard = false,
    this.scrollController,
  });

  static void show(
    BuildContext context, {
    required Function(FoodItem foodItem) onFoodCreated,
    bool isFromDashboard = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ManualFoodSearchBottomSheet(
          onFoodCreated: onFoodCreated,
          isFromDashboard: isFromDashboard,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<ManualFoodSearchBottomSheet> createState() => _ManualFoodSearchBottomSheetState();
}

class _ManualFoodSearchBottomSheetState extends State<ManualFoodSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Food> _allFoods = [];
  List<Food> _filteredFoods = [];
  List<Food> _frequentFoods = []; // Aliments fréquemment utilisés
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showingFrequentFoods = false;

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    try {
      // Charger les aliments normaux avec la langue actuelle
      final locService = LocalizationService.instance;
      final currentLanguage = locService.currentLanguageCode;
      final foods = await DatabaseService.getFoods(language: currentLanguage);
      
      // Charger les aliments personnalisés de l'utilisateur
      List<Food> customFoods = [];
      final user = AuthService().currentUser;
      if (user != null) {
        customFoods = await DatabaseService.getCustomFoods(user.id, language: currentLanguage);
      }
      
      // Combiner les deux listes (aliments personnalisés en premier)
      final allFoods = [...customFoods, ...foods];
      
      // Charger les aliments fréquents pour cet utilisateur
      final frequentFoods = await _loadFrequentFoods();
      
      setState(() {
        _allFoods = allFoods;
        _frequentFoods = frequentFoods;
        // Au début : liste vide jusqu'à ce que l'utilisateur tape ou qu'on ait des fréquents
        _filteredFoods = [];
        _isLoading = false;
        _showingFrequentFoods = frequentFoods.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _filteredFoods = [];
        _frequentFoods = [];
        _showingFrequentFoods = false;
      });
    }
  }

  Future<List<Food>> _loadFrequentFoods() async {
    try {
      final user = AuthService().currentUser;
      if (user == null) return [];
      
      // Utiliser la nouvelle méthode du DatabaseService pour récupérer les aliments fréquents
      final locService = LocalizationService.instance;
      final frequentFoods = await DatabaseService.getFrequentlyUsedFoods(
        user.id, 
        language: locService.currentLanguageCode, 
        limit: 20
      );
      
      print('🔄 Aliments fréquents récupérés: ${frequentFoods.length}');
      for (final food in frequentFoods) {
        print('   - ${food.getLocalizedName(locService.currentLanguageCode)} (isCustom: ${food.isCustom}, origin: ${food.origin})');
      }
      
      return frequentFoods;
    } catch (e) {
      print('❌ Erreur lors du chargement des aliments fréquents: $e');
      return [];
    }
  }

  // Fonction pour normaliser le texte (enlever accents, œ -> oe, etc.)
  String _normalizeText(String text) {
    // Tableau de correspondance des caractères accentués
    const Map<String, String> accentsMap = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ÿ': 'y', 'ý': 'y',
      'ñ': 'n',
      'ç': 'c',
      'œ': 'oe', 'æ': 'ae',
      'À': 'a', 'Á': 'a', 'Â': 'a', 'Ä': 'a', 'Ã': 'a', 'Å': 'a',
      'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e',
      'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
      'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Ö': 'o', 'Õ': 'o',
      'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
      'Ÿ': 'y', 'Ý': 'y',
      'Ñ': 'n',
      'Ç': 'c',
      'Œ': 'oe', 'Æ': 'ae',
    };

    String normalized = text.toLowerCase();
    accentsMap.forEach((accented, normal) {
      normalized = normalized.replaceAll(accented, normal);
    });

    return normalized;
  }

  // Fonction pour vérifier si tous les mots de la requête sont présents dans le nom
  bool _matchesSearchQuery(String foodName, String query) {
    // Normaliser le nom de l'aliment et la requête
    final normalizedFoodName = _normalizeText(foodName);
    final normalizedQuery = _normalizeText(query);

    // Si la requête complète est contenue, c'est un match parfait
    if (normalizedFoodName.contains(normalizedQuery)) {
      return true;
    }

    // Sinon, vérifier que tous les mots de la requête sont présents
    // Diviser la requête en mots (séparés par espaces)
    final queryWords = normalizedQuery.split(RegExp(r'\s+'));

    // Vérifier que chaque mot de la requête est présent dans le nom
    for (final word in queryWords) {
      if (word.isNotEmpty && !normalizedFoodName.contains(word)) {
        return false;
      }
    }

    return true;
  }

  // Fonction pour calculer le score de pertinence d'un résultat
  int _calculateRelevanceScore(String foodName, String query) {
    final normalizedFoodName = _normalizeText(foodName).toLowerCase();
    final normalizedQuery = _normalizeText(query).toLowerCase();

    // Score max si correspondance exacte
    if (normalizedFoodName == normalizedQuery) {
      return 1000;
    }

    // Score élevé si le nom commence par la requête
    if (normalizedFoodName.startsWith(normalizedQuery)) {
      return 900;
    }

    // Score moyen si la requête complète est contenue
    if (normalizedFoodName.contains(normalizedQuery)) {
      return 800;
    }

    // Pour les recherches multi-mots, donner un score basé sur l'ordre et la proximité
    final queryWords = normalizedQuery.split(RegExp(r'\s+'));
    int score = 0;
    int lastIndex = -1;

    for (final word in queryWords) {
      if (word.isNotEmpty) {
        final index = normalizedFoodName.indexOf(word);
        if (index != -1) {
          score += 100; // Point de base pour chaque mot trouvé

          // Bonus si le mot est au début
          if (index == 0) {
            score += 50;
          }

          // Bonus si les mots sont dans l'ordre
          if (lastIndex != -1 && index > lastIndex) {
            score += 25;
          }

          lastIndex = index;
        }
      }
    }

    return score;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;

      if (query.isEmpty) {
        // Retour à l'état initial : afficher les fréquents ou rien
        _filteredFoods = [];
        _showingFrequentFoods = _frequentFoods.isNotEmpty;
      } else {
        // Mode recherche : filtrer et trier tous les aliments avec la nouvelle logique
        _showingFrequentFoods = false;

        // Filtrer les aliments qui correspondent
        final matchingFoods = _allFoods.where((food) {
          final locService = LocalizationService.instance;
          final name = food.getLocalizedName(locService.currentLanguageCode);
          return _matchesSearchQuery(name, query);
        }).toList();

        // Trier par score de pertinence (du plus pertinent au moins pertinent)
        matchingFoods.sort((a, b) {
          final locService = LocalizationService.instance;
          final scoreA = _calculateRelevanceScore(
            a.getLocalizedName(locService.currentLanguageCode),
            query,
          );
          final scoreB = _calculateRelevanceScore(
            b.getLocalizedName(locService.currentLanguageCode),
            query,
          );
          return scoreB.compareTo(scoreA); // Ordre décroissant
        });

        // Limiter à 100 résultats pour la performance
        _filteredFoods = matchingFoods.take(100).toList();
      }
    });
  }

  List<Food> _getCurrentDisplayFoods() {
    if (_searchQuery.isNotEmpty) {
      print('🔍 Mode RECHERCHE - Query: "$_searchQuery", ${_filteredFoods.length} résultats');
      return _filteredFoods; // Résultats de recherche
    } else if (_showingFrequentFoods) {
      print('⭐ Mode FREQUENTS - ${_frequentFoods.length} aliments fréquents');
      return _frequentFoods; // Aliments fréquents
    } else {
      print('📭 Mode VIDE - Aucun aliment à afficher');
      return []; // Liste vide par défaut
    }
  }

  String _getEmptyStateMessage(String languageCode) {
    if (_searchQuery.isNotEmpty) {
      return 'no_food_found'.tr(languageCode).replaceAll('{query}', _searchQuery);
    } else if (_frequentFoods.isEmpty) {
      return 'type_to_search'.tr(languageCode);
    } else {
      return 'no_food_available'.tr(languageCode);
    }
  }

  Widget _buildEmptyState() {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, _) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isNotEmpty ? LucideIcons.search : LucideIcons.type,
                size: 48,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyStateMessage(localizationService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isEmpty && _frequentFoods.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'start_adding_foods'.tr(localizationService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayFoods = _getCurrentDisplayFoods();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, localizationService, _) {
                      return Text(
                        'search_food'.tr(localizationService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Consumer<LocalizationService>(
              builder: (context, localizationService, _) {
                return TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'search_food_placeholder'.tr(localizationService.currentLanguageCode),
                    hintStyle: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Option "Créer un aliment"
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 100));
                if (context.mounted) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.9,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      expand: false,
                      builder: (_, __) => CreateCustomFoodBottomSheet(
                        onFoodSelected: widget.onFoodCreated,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0B132B).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<LocalizationService>(
                        builder: (context, localizationService, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'create_food'.tr(localizationService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Text(
                                'create_custom_food_desc'.tr(localizationService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
      
          // Section titre pour les aliments fréquents
          if (_showingFrequentFoods && _frequentFoods.isNotEmpty) ...[
            Consumer<LocalizationService>(
              builder: (context, localizationService, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.trendingUp,
                        size: 16,
                        color: Color(0xFF0B132B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'frequently_used_foods'.tr(localizationService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          
          // Contenu principal scrollable
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0B132B),
                    ),
                  )
                : displayFoods.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            ...displayFoods.map((food) {
                              final locService = LocalizationService.instance;
                              
                              return FoodSuggestionWidget(
                                name: food.getLocalizedName(locService.currentLanguageCode),
                                calories: food.calories,
                                per: food.getLocalizedUnit(locService.currentLanguageCode) != null && food.referenceQuantity != null 
                                    ? '${food.referenceQuantity!.toStringAsFixed(food.referenceQuantity!.truncateToDouble() == food.referenceQuantity ? 0 : 1)} ${food.getLocalizedUnit(locService.currentLanguageCode)}'
                                    : '100 g',
                                isCustom: food.isCustom,
                                origin: food.origin, // Transmettre l'origine pour l'affichage
                                hasModifiedMacros: false, // Les aliments dans la recherche ne sont pas modifiés
                                isRecipe: false, // Ce ne sont pas des recettes
                                onTap: () {
                                  Navigator.pop(context);
                                  _showFoodDetailsBottomSheet(food);
                                },
                              );
                            }),
                            const SizedBox(height: 20), // Espace en bas pour le défilement
                          ],
                        ),
                      ),
          ),
        ],
      ),
        ),
    );
  }

  void _showFoodDetailsBottomSheet(Food food) {
    // Utiliser la quantité de référence de l'aliment si disponible
    final defaultQuantity = food.referenceQuantity ?? 100.0;
    
    final locService = LocalizationService.instance;
    EditableFoodDetailsBottomSheet.show(
      context,
      id: food.id,
      name: food.getLocalizedName(locService.currentLanguageCode),
      calories: food.calories,
      proteins: food.proteins,
      glucides: food.carbs,
      lipides: food.fats,
      quantity: defaultQuantity,
      isModified: false,
      isCustomFood: food.isCustom,
      referenceUnit: food.getLocalizedUnit('fr'),
      onFoodAdded: (foodItem) {
        // Marquer les propriétés de l'aliment dans le résultat
        // Selon les nouvelles règles : 
        // - Aliment de base de données → isCustom = food.isCustom (garder la valeur originale)
        // - L'icône apparaîtra seulement si hasModifiedMacros = true
        final finalFoodItem = foodItem.copyWith(
          id: food.id,
          isCustom: food.isCustom, // Garder la valeur originale
          isRecipe: false, // Ce n'est pas une recette
          isScanned: food.isCustom && food.origin?.toLowerCase().trim() == 'barcode', // Scanné si custom + origin barcode
          referenceUnitFr: food.referenceUnitFr,
          referenceUnitEn: food.referenceUnitEn,
          referenceQuantity: food.referenceQuantity,
        );
        
        // Debug: Vérifier les propriétés pour Nutella
        if (food.getLocalizedName(LocalizationService.instance.currentLanguageCode).toLowerCase().contains('nutella')) {
          print('🎯 DEBUG - Nutella ajouté au journal:');
          print('   - food.isCustom: ${food.isCustom}');
          print('   - food.origin: "${food.origin}"');
          print('   - finalFoodItem.isCustom: ${finalFoodItem.isCustom}');
          print('   - finalFoodItem.isScanned: ${finalFoodItem.isScanned}');
          print('   - finalFoodItem.shouldShowCustomIcon: ${finalFoodItem.shouldShowCustomIcon}');
          print('   - finalFoodItem.displayIcon: ${finalFoodItem.displayIcon}');
        }
            
        // Toujours utiliser le callback - le flux dashboard est maintenant géré en amont
        widget.onFoodCreated(finalFoodItem);
      },
    );
  }
} 
