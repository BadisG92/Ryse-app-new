import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'ui/custom_card.dart';
import '../models/nutrition_models.dart';
import '../widgets/nutrition/meal_card.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../widgets/nutrition/calendar_view.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';
import '../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../services/food_entries_service.dart';
import '../services/auth_service.dart';
import '../bottom_sheets/add_meal_bottom_sheet.dart';

class NutritionJournalHybrid extends StatefulWidget {
  const NutritionJournalHybrid({super.key});

  @override
  State<NutritionJournalHybrid> createState() => _NutritionJournalHybridState();
}

class _NutritionJournalHybridState extends State<NutritionJournalHybrid> {
  bool showCalendar = false;
  int? _selectedMealIndex; // Pour savoir à quel repas ajouter l'aliment
  String? _pendingMealType; // Type de repas en attente d'ajout d'aliment
  String? _pendingMealId; // ID pré-généré pour le nouveau repas
  List<Meal> meals = []; // Données chargées depuis Supabase
  DateTime selectedDate = DateTime.now(); // Date sélectionnée pour le journal
  bool isLoading = true;
  late StreamSubscription _nutritionUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadMealsForDate(selectedDate);
    _setupNutritionUpdateListener();
  }

  @override
  void dispose() {
    _nutritionUpdateSubscription.cancel();
    super.dispose();
  }

  // Écouter les mises à jour nutritionnelles en temps réel
  void _setupNutritionUpdateListener() {
    _nutritionUpdateSubscription = FoodEntriesService.nutritionUpdates.listen((update) {
      final updateUserId = update['user_id'] as String?;
      final updateDate = update['date'] as DateTime?;
      final currentUser = AuthService().currentUser;
      
      // Recharger seulement si c'est pour l'utilisateur actuel et la date sélectionnée
      if (currentUser != null && 
          updateUserId == currentUser.id && 
          updateDate != null &&
          _isSameDay(updateDate, selectedDate)) {
        
        debugPrint('🔔 Rechargement automatique des données nutritionnelles');
        _loadMealsForDate(selectedDate);
      }
    });
  }

  // Vérifier si deux dates sont le même jour
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Charger les repas pour une date donnée
  Future<void> _loadMealsForDate(DateTime date) async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final loadedMeals = await FoodEntriesService.getFoodEntriesForDate(user.id, date);
        setState(() {
          meals = loadedMeals;
          selectedDate = date;
          isLoading = false;
        });
      } else {
        setState(() {
          meals = []; // Ne pas charger les repas par défaut si l'utilisateur n'est pas connecté
          selectedDate = date;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des repas: $e');
      setState(() {
        meals = []; // Ne pas charger les repas par défaut en cas d'erreur
        selectedDate = date;
        isLoading = false;
      });
    }
  }

  void _addFoodToSelectedMeal(FoodItem foodItem) async {
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour ajouter un aliment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? targetMealName;
    bool success = false;
    
    if (_selectedMealIndex != null && _selectedMealIndex! < meals.length) {
      // Cas normal : ajouter à un repas existant avec son meal_id
      final selectedMeal = meals[_selectedMealIndex!];
      targetMealName = selectedMeal.name;
      success = await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: selectedMeal.name,
        foodItem: foodItem,
        consumedAt: selectedDate,
        mealId: selectedMeal.id, // Utiliser l'ID du repas existant
      );
    } else if (_pendingMealType != null && _pendingMealId != null) {
      // Cas nouveau repas : utiliser l'ID pré-généré
      targetMealName = _pendingMealId;
      success = await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: _pendingMealType!,
        foodItem: foodItem,
        consumedAt: selectedDate,
        mealId: _pendingMealId, // Utiliser l'ID pré-généré
      );
    } else {
      // Cas où aucun repas n'est sélectionné (ex: ajout direct de recette)
      _showMealSelectionForFood(foodItem);
      return;
    }

    if (success) {
      // Recharger les données depuis Supabase pour avoir les vrais IDs
      await _loadMealsForDate(selectedDate);
      
      // Fermer le bottom sheet s'il y en a un
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Afficher le message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${foodItem.name} ajouté au $targetMealName'),
            backgroundColor: const Color(0xFF0B132B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout de l\'aliment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    // Réinitialiser les sélections
    _selectedMealIndex = null;
    _pendingMealType = null;
    _pendingMealId = null;
  }

  // Gérer la sélection d'un nouveau type de repas avec pré-génération d'ID
  Future<void> _selectNewMealType(String mealType) async {
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour ajouter un repas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pré-générer l'ID du repas
    final mealId = await FoodEntriesService.generateMealId(
      userId: user.id,
      mealName: mealType,
      forDate: selectedDate,
    );

    if (mealId != null) {
      setState(() {
        _pendingMealType = mealType;
        _pendingMealId = mealId;
        _selectedMealIndex = null; // Reset selection existante
      });

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nouveau repas "$mealId" prêt, ajoutez vos aliments !'),
            backgroundColor: const Color(0xFF0B132B),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Erreur lors de la génération de l'ID
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création du repas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Obtenir l'icône appropriée pour un type de repas
  IconData _getMealIcon(String mealName) {
    final mealLower = mealName.toLowerCase();
    if (mealLower.contains('petit') || mealLower.contains('breakfast')) {
      return LucideIcons.sunrise;
    } else if (mealLower.contains('déjeuner') || mealLower.contains('lunch')) {
      return LucideIcons.sun;
    } else if (mealLower.contains('collation') || mealLower.contains('snack')) {
      return LucideIcons.milk;
    } else if (mealLower.contains('dîner') || mealLower.contains('dinner')) {
      return LucideIcons.sunset;
    } else {
      return LucideIcons.utensils; // Icône par défaut
    }
  }

  // Formater la date pour l'affichage
  String _formatDate(DateTime date) {
    const List<String> daysOfWeek = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    const List<String> months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];

    final dayName = daysOfWeek[date.weekday - 1];
    final monthName = months[date.month - 1];
    
    return '$dayName ${date.day} $monthName ${date.year}';
  }

  // Obtenir le titre de la date (Aujourd'hui, Hier, ou la date)
  String _getDateTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Aujourd\'hui';
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return 'Demain';
    } else {
      return _formatDate(date);
    }
  }
  
  void _showMealSelectionForFood(FoodItem foodItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Titre
              Text(
                'Ajouter "${foodItem.name}" à un repas',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Choisissez le repas auquel ajouter cet aliment',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Liste des repas existants (seulement ceux qui ont des aliments)
              ...meals.where((meal) => meal.items.isNotEmpty).map((meal) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MealOptionWidget(
                    icon: _getMealIcon(meal.name),
                    title: meal.name,
                    subtitle: '${meal.time} • ${meal.items.length} aliment${meal.items.length > 1 ? 's' : ''}',
                    onTap: () async {
                      Navigator.pop(context);
                      
                      // Ajouter au repas existant via Supabase
                      final user = AuthService().currentUser;
                      if (user != null) {
                        final success = await FoodEntriesService.addFoodEntry(
                          userId: user.id,
                          mealName: meal.name,
                          foodItem: foodItem,
                          consumedAt: selectedDate,
                          mealId: meal.id, // Ajouter au bloc existant
                        );

                        if (success) {
                          // Recharger les données
                          await _loadMealsForDate(selectedDate);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${foodItem.name} ajouté au ${meal.name}'),
                                backgroundColor: const Color(0xFF0B132B),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur lors de l\'ajout'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                );
              }),
              
              // Divider si il y a des repas existants
              if (meals.any((meal) => meal.items.isNotEmpty)) ...[
                const Divider(height: 32),
                const Text(
                  'Ou créer un nouveau repas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Options pour créer un nouveau repas
              ...['Petit-déjeuner', 'Déjeuner', 'Collation', 'Dîner'].map((mealType) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MealOptionWidget(
                    icon: _getMealIcon(mealType),
                    title: 'Nouveau $mealType',
                    subtitle: 'Créer un nouveau bloc de repas',
                    onTap: () async {
                      Navigator.pop(context);
                      
                      // Utiliser notre nouvelle logique de pré-génération d'ID
                      final user = AuthService().currentUser;
                      if (user != null) {
                        final mealId = await FoodEntriesService.generateMealId(
                          userId: user.id,
                          mealName: mealType,
                          forDate: selectedDate,
                        );

                        if (mealId != null) {
                          // Ajouter l'aliment au nouveau repas avec l'ID pré-généré
                          final success = await FoodEntriesService.addFoodEntry(
                            userId: user.id,
                            mealName: mealType,
                            foodItem: foodItem,
                            consumedAt: selectedDate,
                            mealId: mealId,
                          );

                          if (success) {
                            // Recharger les données
                            await _loadMealsForDate(selectedDate);
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${foodItem.name} ajouté à un nouveau $mealId'),
                                  backgroundColor: const Color(0xFF0B132B),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erreur lors de la création du repas'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur lors de la génération de l\'ID du repas'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                );
              }),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFoodEntries = meals.any((meal) => meal.items.isNotEmpty);

    if (showCalendar) {
      return CalendarView(
        onBack: () => setState(() => showCalendar = false),
        selectedDate: selectedDate,
        onDateSelected: (DateTime newDate) {
          setState(() {
            selectedDate = newDate;
            showCalendar = false;
          });
          // Recharger les données pour la nouvelle date
          _loadMealsForDate(newDate);
        },
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: Column(
        children: [
          // Header supprimé fixe (désormais dans scroll)
          const SizedBox.shrink(),
          
          // Liste des repas (scrollable)
          Expanded(
            child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0B132B),
                  ),
                )
              : !hasFoodEntries
                ? // Message informatif quand aucun repas n'est enregistré
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.utensils,
                            size: 48,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun repas enregistré',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ajoutez votre premier repas pour commencer à suivre votre nutrition.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => _showAddMealBottomSheet(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B132B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.plus,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ajouter un repas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 140), // Ajout de padding bottom pour éviter la barre de navigation
                  child: Column(
                    children: [
                      // Header (date + résumé) désormais scrollable
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getDateTitle(selectedDate),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(selectedDate),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF1A1A1A).withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => showCalendar = true),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B132B),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      LucideIcons.expand,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDaySummary(),
                          ],
                        ),
                      ),
                      // Repas existants
                        ...meals
                            .where((meal) => meal.items.isNotEmpty)
                            .map((meal) {
                          final originalIndex = meals.indexOf(meal);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: MealCard(
                            meal: meal,
                            onAddFood: () {
                                  _selectedMealIndex = originalIndex;
                              _showAddFoodBottomSheet();
                            },
                                onFoodRemoved: () {
                                  // Recharger les repas après suppression
                                  _loadMealsForDate(selectedDate);
                                },
                          ),
                        );
                      }),
                  
                  // Ajouter un repas
                  GestureDetector(
                    onTap: () => _showAddMealBottomSheet(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B132B).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Ajouter un repas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                    ],
                  ),
                ),
                ),
        ],
      ),
    );
  }

  Widget _buildDaySummary() {
    // Calculer les totaux nutritionnels réels du jour
    int totalCalories = 0;
    double totalProteins = 0.0;
    double totalCarbs = 0.0;
    double totalFats = 0.0;
    
    // Additionner tous les aliments de tous les repas
    for (final meal in meals) {
      for (final item in meal.items) {
        totalCalories += item.calories;
        totalProteins += item.proteins;
        totalCarbs += item.carbs;
        totalFats += item.fats;
      }
    }
    
    // Récupérer l'objectif calorique depuis l'utilisateur
    final user = AuthService().currentUser;
    final int targetCalories = user?.dailyCalories ?? 2500; // Valeur par défaut si non définie
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Ligne de titre avec icône
            Row(
              children: [
                const Icon(
                  LucideIcons.flame,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Bilan calorique',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ligne de texte principale avec style bicolore
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$totalCalories kcal',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  TextSpan(
                    text: ' / $targetCalories kcal consommées',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Barre de progression
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: totalCalories > 0 ? (totalCalories / targetCalories).clamp(0.0, 1.0) : 0.0,
                  ),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutExpo,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0B132B),
                  ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Indicateurs de macronutriments simplifiés (sans icônes ni objectifs)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSimpleMacroIndicator(
                  'Protéines',
                  '${totalProteins.toStringAsFixed(0)}g',
                ),
                _buildSimpleMacroIndicator(
                  'Glucides',
                  '${totalCarbs.toStringAsFixed(0)}g',
                ),
                _buildSimpleMacroIndicator(
                  'Lipides',
                  '${totalFats.toStringAsFixed(0)}g',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMacroIndicator(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  // ===== BOTTOM SHEETS INTÉGRÉS =====
  // ✅ Évite les problèmes de contexte en gardant les bottom sheets ici
  // ✅ Utilise les widgets factorés pour la cohérence et la réutilisabilité
  
  void _showAddFoodBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Titre
              const Text(
                'Ajouter un aliment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Choisissez comment vous souhaitez ajouter votre aliment',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // ✅ Utilise les widgets factorés
              FoodOptionWidget(
                icon: LucideIcons.pencil,
                title: 'Saisie manuelle',
                subtitle: 'Rechercher et ajouter manuellement',
                onTap: () {
                  Navigator.pop(context);
                  _showManualEntryBottomSheet();
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.camera,
                title: 'Scanner avec l\'IA',
                subtitle: 'Prenez une photo de votre plat',
                onTap: () {
                  Navigator.pop(context);
                  // ✅ Navigation directe sans problème de contexte
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIScannerScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.scan,
                title: 'Code-barres',
                subtitle: 'Scanner le code-barres du produit',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarcodeScannerScreen(
                        isFromDashboard: false,
                        onFoodScanned: _addFoodToSelectedMeal, // Passer le callback
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.chefHat,
                title: 'Mes recettes',
                subtitle: 'Choisir parmi vos recettes sauvegardées',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectRecipeScreen(
                        isFromDashboard: false,
                        onRecipeSelected: _addFoodToSelectedMeal, // Passer le callback
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMealBottomSheet() {
    AddMealBottomSheet.show(
      context,
      (String mealType) async {
        // Utiliser la méthode de sélection avec pré-génération d'ID
        await _selectNewMealType(mealType);
        
        // Ouvrir ensuite le bottom sheet d'ajout d'aliment
        Future.delayed(const Duration(milliseconds: 300), () {
          _showAddFoodBottomSheet();
        });
      },
    );
  }

  void _showManualEntryBottomSheet() {
    ManualFoodSearchBottomSheet.show(
      context,
      onFoodCreated: _addFoodToSelectedMeal,
    );
  }
}
