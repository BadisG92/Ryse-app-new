import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/create_custom_food_bottom_sheet.dart';
import '../design/design.dart';
import '../models/nutrition_models.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../types/database_types.dart';

class ManualFoodSearchBottomSheet extends StatefulWidget {
  final Function(FoodItem foodItem) onFoodCreated;
  final bool isFromDashboard;
  final ScrollController? scrollController;
  final String? mealName;
  final String? mealId;

  const ManualFoodSearchBottomSheet({
    super.key,
    required this.onFoodCreated,
    this.isFromDashboard = false,
    this.scrollController,
    this.mealName,
    this.mealId,
  });

  static void show(
    BuildContext context, {
    required Function(FoodItem foodItem) onFoodCreated,
    bool isFromDashboard = false,
    String? mealName,
    String? mealId,
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
          mealName: mealName,
          mealId: mealId,
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
      
      debugPrint('🔄 Aliments fréquents récupérés: ${frequentFoods.length}');
      for (final food in frequentFoods) {
        debugPrint('   - ${food.getLocalizedName(locService.currentLanguageCode)} (isCustom: ${food.isCustom}, origin: ${food.origin})');
      }
      
      return frequentFoods;
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des aliments fréquents: $e');
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
      debugPrint('🔍 Mode RECHERCHE - Query: "$_searchQuery", ${_filteredFoods.length} résultats');
      return _filteredFoods; // Résultats de recherche
    } else if (_showingFrequentFoods) {
      debugPrint('⭐ Mode FREQUENTS - ${_frequentFoods.length} aliments fréquents');
      return _frequentFoods; // Aliments fréquents
    } else {
      debugPrint('📭 Mode VIDE - Aucun aliment à afficher');
      return []; // Liste vide par défaut
    }
  }

  /// Ouvre la création d'un aliment, en fermant d'abord la recherche pour ne
  /// pas empiler deux feuilles.
  Future<void> _createFood() async {
    RyzeFeedback.select();
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!navigator.mounted) return;
    showModalBottomSheet(
      context: navigator.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, __) => CreateCustomFoodBottomSheet(onFoodSelected: widget.onFoodCreated),
      ),
    );
  }

  /// Rien à montrer : soit on n'a pas encore tapé, soit la base ne connaît pas
  /// ce mot. Dans le second cas, créer l'aliment est la seule suite utile, donc
  /// c'est ce qu'on propose.
  Widget _emptyState(String lang) {
    final searching = _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.vw(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(searching ? LucideIcons.searchX : LucideIcons.search, size: context.vw(9.2), color: RyzeColors.mute2),
            SizedBox(height: context.vw(3.6)),
            Text(
              searching
                  ? 'no_food_found'.tr(lang).replaceAll('{query}', _searchQuery)
                  : 'type_to_search'.tr(lang),
              textAlign: TextAlign.center,
              style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.mute),
            ),
            if (searching) ...[
              SizedBox(height: context.vw(5.1)),
              Pressable(
                onTap: _createFood,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.vw(5.1), vertical: context.vw(3.1)),
                  decoration: BoxDecoration(
                    color: RyzeColors.ink,
                    borderRadius: BorderRadius.circular(RyzeRadius.pill),
                    boxShadow: RyzeShadow.soft,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: context.vw(4.1), color: RyzeColors.surf),
                      SizedBox(width: context.vw(2.1)),
                      Text(
                        'create_food'.tr(lang),
                        style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.surf),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final foods = _getCurrentDisplayFoods();
    final gutter = context.vw(5.1);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: context.vh(92)),
      child: Container(
        decoration: BoxDecoration(
          color: RyzeColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg)),
        ),
        child: Column(
          children: [
            SizedBox(height: context.vw(2.6)),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
            ),
            SizedBox(height: context.vw(4.1)),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'search_food'.tr(lang),
                      style: RyzeText.body(context, 5.1, weight: FontWeight.w600),
                    ),
                  ),
                  Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: context.vw(9.2),
                      height: context.vw(9.2),
                      decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle),
                      child: Icon(LucideIcons.x, size: context.vw(4.6), color: RyzeColors.mute),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.vw(3.6)),

            // Le champ mène : il est ouvert dès l'arrivée et se vide d'un geste.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Container(
                decoration: BoxDecoration(
                  color: RyzeColors.surf,
                  borderRadius: BorderRadius.circular(RyzeRadius.pill),
                  border: Border.all(color: RyzeColors.line),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  style: RyzeText.body(context, 3.9),
                  cursorColor: RyzeColors.ink,
                  decoration: InputDecoration(
                    hintText: 'search_food_placeholder'.tr(lang),
                    hintStyle: RyzeText.body(context, 3.9, color: RyzeColors.mute2),
                    prefixIcon: Icon(LucideIcons.search, color: RyzeColors.mute, size: context.vw(4.6)),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : Pressable(
                            onTap: () {
                              RyzeFeedback.tap();
                              _searchController.clear();
                            },
                            child: Icon(LucideIcons.x, color: RyzeColors.mute, size: context.vw(4.6)),
                          ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.6)),
                  ),
                ),
              ),
            ),

            if (_showingFrequentFoods && _frequentFoods.isNotEmpty) ...[
              SizedBox(height: context.vw(4.1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'frequently_used_foods'.tr(lang),
                    style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute),
                  ),
                ),
              ),
            ],
            SizedBox(height: context.vw(2.6)),

            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2))
                  : foods.isEmpty
                      ? _emptyState(lang)
                      : ListView.separated(
                          controller: widget.scrollController,
                          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, context.vw(6)),
                          itemCount: foods.length + 1,
                          separatorBuilder: (_, __) => SizedBox(height: context.vw(2.1)),
                          itemBuilder: (_, i) {
                            if (i == foods.length) {
                              // La création se range après les résultats : elle
                              // reste à portée sans prendre leur place.
                              return Padding(
                                padding: EdgeInsets.only(top: context.vw(2.1)),
                                child: _CreateRow(lang: lang, onTap: _createFood),
                              );
                            }
                            final food = foods[i];
                            final unit = food.getLocalizedUnit(lang);
                            final quantity = food.referenceQuantity;
                            return _FoodRow(
                              name: food.getLocalizedName(lang),
                              calories: food.calories,
                              per: unit != null && quantity != null
                                  ? '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1)} $unit'
                                  : '100 g',
                              custom: food.isCustom,
                              onTap: () {
                                RyzeFeedback.select();
                                Navigator.pop(context);
                                _showFoodDetailsBottomSheet(food);
                              },
                            );
                          },
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
      // l'unité dans la langue de l'utilisateur, pas toujours en français
      referenceUnit: food.getLocalizedUnit(locService.currentLanguageCode),
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
          debugPrint('🎯 DEBUG - Nutella ajouté au journal:');
          debugPrint('   - food.isCustom: ${food.isCustom}');
          debugPrint('   - food.origin: "${food.origin}"');
          debugPrint('   - finalFoodItem.isCustom: ${finalFoodItem.isCustom}');
          debugPrint('   - finalFoodItem.isScanned: ${finalFoodItem.isScanned}');
          debugPrint('   - finalFoodItem.shouldShowCustomIcon: ${finalFoodItem.shouldShowCustomIcon}');
          debugPrint('   - finalFoodItem.displayIcon: ${finalFoodItem.displayIcon}');
        }
        // Appeler le callback pour ajouter l'aliment ; l'affichage du popup est géré dans
        // EditableFoodDetailsBottomSheet pour garantir un context valide avant la fermeture.
        widget.onFoodCreated(finalFoodItem);
      },
    );
  }
} 

/// Un aliment de la liste : son nom, ce qu'il pèse, ses calories.
class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.name,
    required this.calories,
    required this.per,
    required this.custom,
    required this.onTap,
  });

  final String name;
  final int calories;
  final String per;
  final bool custom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
                        ),
                      ),
                      if (custom) ...[
                        SizedBox(width: context.vw(1.5)),
                        Icon(LucideIcons.bookmark, size: context.vw(3.3), color: RyzeColors.mute2),
                      ],
                    ],
                  ),
                  SizedBox(height: context.vw(0.5)),
                  Text(per, style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                ],
              ),
            ),
            SizedBox(width: context.vw(3.1)),
            Text.rich(
              TextSpan(
                style: RyzeText.body(context, 3.9, weight: FontWeight.w600).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                children: [
                  TextSpan(text: '$calories'),
                  TextSpan(text: ' kcal', style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La sortie de secours quand la base ne connaît pas ce qu'on mange.
class _CreateRow extends StatelessWidget {
  const _CreateRow({required this.lang, required this.onTap});

  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.idle),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.plus, size: context.vw(4.6), color: RyzeColors.ink),
            SizedBox(width: context.vw(3.1)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('create_food'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                  Text(
                    'create_custom_food_desc'.tr(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: RyzeColors.mute2),
          ],
        ),
      ),
    );
  }
}
