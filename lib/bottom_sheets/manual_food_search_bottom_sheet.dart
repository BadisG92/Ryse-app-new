import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/create_custom_food_bottom_sheet.dart';
import '../models/nutrition_models.dart';
import '../components/ui/nutrition_widgets.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
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
      // Charger les aliments normaux
      final foods = await DatabaseService.getFoods(language: 'fr');
      
      // Charger les aliments personnalisés de l'utilisateur
      List<Food> customFoods = [];
      final user = AuthService().currentUser;
      if (user != null) {
        customFoods = await DatabaseService.getCustomFoods(user.id, language: 'fr');
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
      final frequentFoods = await DatabaseService.getFrequentlyUsedFoods(
        user.id, 
        language: 'fr', 
        limit: 20
      );
      
      print('🔄 Aliments fréquents récupérés: ${frequentFoods.length}');
      for (final food in frequentFoods) {
        print('   - ${food.getLocalizedName('fr')} (isCustom: ${food.isCustom}, origin: ${food.origin})');
      }
      
      return frequentFoods;
    } catch (e) {
      print('❌ Erreur lors du chargement des aliments fréquents: $e');
      return [];
    }
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
        // Mode recherche : filtrer tous les aliments
        _showingFrequentFoods = false;
        _filteredFoods = _allFoods.where((food) {
          final name = food.getLocalizedName('fr').toLowerCase();
          return name.contains(query);
        }).take(20).toList(); // Limiter à 20 résultats de recherche
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

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'Aucun aliment trouvé pour "$_searchQuery"';
    } else if (_frequentFoods.isEmpty) {
      return 'Tapez pour rechercher un aliment\nou créez votre propre aliment personnalisé';
    } else {
      return 'Aucun aliment disponible';
    }
  }

  Widget _buildEmptyState() {
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
            _getEmptyStateMessage(),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty && _frequentFoods.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Commencez à ajouter des aliments à vos repas\npour voir vos suggestions ici',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayFoods = _getCurrentDisplayFoods();
    
    return Container(
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
                const Expanded(
                  child: Text(
                    'Rechercher un aliment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
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
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un aliment...',
                hintStyle: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
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
                    builder: (context) => CreateCustomFoodBottomSheet(
                      onFoodSelected: widget.onFoodCreated,
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Créer un aliment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0B132B),
                            ),
                          ),
                          Text(
                            'Créez votre propre aliment personnalisé',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.trendingUp,
                    size: 16,
                    color: Color(0xFF0B132B),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Aliments fréquemment utilisés',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ],
              ),
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
                              // Debug: Afficher les informations de l'aliment (focus sur Nutella)
                              if (food.isCustom && food.getLocalizedName('fr').toLowerCase().contains('nutella')) {
                                print('🎯 DEBUG - Nutella trouvé dans la liste:');
                                print('   - isCustom: ${food.isCustom}');
                                print('   - origin: ${food.origin}');
                                print('   - barcode: ${food.barcode}');
                              }
                              
                              return FoodSuggestionWidget(
                                name: food.getLocalizedName('fr'),
                                calories: food.calories,
                                per: food.getLocalizedUnit('fr') != null && food.referenceQuantity != null 
                                    ? '${food.referenceQuantity!.toStringAsFixed(food.referenceQuantity!.truncateToDouble() == food.referenceQuantity ? 0 : 1)} ${food.getLocalizedUnit('fr')}'
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
    );
  }

  void _showFoodDetailsBottomSheet(Food food) {
    // Utiliser la quantité de référence de l'aliment si disponible
    final defaultQuantity = food.referenceQuantity ?? 100.0;
    
    EditableFoodDetailsBottomSheet.show(
      context,
      id: food.id,
      name: food.getLocalizedName('fr'),
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
        if (food.getLocalizedName('fr').toLowerCase().contains('nutella')) {
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
