import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
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
import '../services/optimistic_update_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import 'ui/custom_snackbar.dart';
import '../bottom_sheets/add_meal_bottom_sheet.dart';
import 'coach_ryze_nutrition_button.dart';
import '../services/workout_service.dart';

class NutritionJournalHybrid extends StatefulWidget {
  const NutritionJournalHybrid({super.key});

  @override
  State<NutritionJournalHybrid> createState() => _NutritionJournalHybridState();
}

class _NutritionJournalHybridState extends State<NutritionJournalHybrid> {
  bool showCalendar = false;
  bool _isPreloadingCalendar = false; // NOUVEAU: Pour pré-charger avant d'afficher
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

  /// OPTIMISATION: Ouvre le calendrier instantanément
  void _openCalendar() {
    // Afficher le calendrier immédiatement
    // CalendarView gérera son propre chargement en arrière-plan
    setState(() => showCalendar = true);
  }

  void _addFoodToSelectedMeal(FoodItem foodItem) async {
    final user = AuthService().currentUser;
    if (user == null) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      CustomSnackbarService.showError(
        context,
        'must_be_connected_add_food'.tr(locService.currentLanguageCode),
      );
      return;
    }

    String? targetMealName;
    
    // OPTIMISATION: Mise à jour optimiste immédiate
    await OptimisticUpdateService.updateCaloriesOptimistic(foodItem.calories.toDouble());
    
    // Fermer le bottom sheet immédiatement pour feedback instantané
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (_selectedMealIndex != null && _selectedMealIndex! < meals.length) {
      // Cas normal : ajouter à un repas existant avec son meal_id
      final selectedMeal = meals[_selectedMealIndex!];
      targetMealName = selectedMeal.name;
      
      // Feedback visuel instantané
      CustomSnackbarService.showSuccess(
        context,
        '${foodItem.name} ajouté au $targetMealName',
      );
      
      // Ajout en base (non-bloquant)
      FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: selectedMeal.name,
        foodItem: foodItem,
        consumedAt: selectedDate,
        mealId: selectedMeal.id,
      ).then((success) {
        if (!success) {
          // Rollback si erreur
          OptimisticUpdateService.rollback();
          if (mounted) {
            CustomSnackbarService.showError(context, 'Erreur lors de l\'ajout de l\'aliment');
          }
        }
        // ✅ OPTIMISATION: Ne pas recharger ici, le stream listener s'en charge automatiquement
      });
      
    } else if (_pendingMealType != null && _pendingMealId != null) {
      // Cas nouveau repas : utiliser l'ID pré-généré
      targetMealName = _pendingMealId;
      
      // Feedback visuel instantané
      CustomSnackbarService.showSuccess(
        context,
        '${foodItem.name} ajouté au $targetMealName',
      );
      
      // Ajout en base (non-bloquant)
      FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: _pendingMealType!,
        foodItem: foodItem,
        consumedAt: selectedDate,
        mealId: _pendingMealId!,
      ).then((success) {
        if (!success) {
          // Rollback si erreur
          OptimisticUpdateService.rollback();
          if (mounted) {
            CustomSnackbarService.showError(context, 'Erreur lors de l\'ajout de l\'aliment');
          }
        }
        // ✅ OPTIMISATION: Ne pas recharger ici, le stream listener s'en charge automatiquement
      });
      
    } else {
      // Cas où aucun repas n'est sélectionné (ex: ajout direct de recette)
      _showMealSelectionForFood(foodItem);
      return;
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
        SnackBar(
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
          SnackBar(
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
  String _formatDate(DateTime date, String languageCode) {
    final weekDays = languageCode == 'en' 
        ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        : ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    
    final months = languageCode == 'en' 
        ? ['January', 'February', 'March', 'April', 'May', 'June',
           'July', 'August', 'September', 'October', 'November', 'December']
        : ['janvier', 'février', 'mars', 'avril', 'mai', 'juin',
           'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    
    final weekDay = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    
    return '$weekDay ${date.day} $month ${date.year}';
  }
  // Obtenir le titre de la date (Aujourd'hui, Hier, ou la date)
  String _getDateTitle(DateTime date, String languageCode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'today'.tr(languageCode);
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'yesterday'.tr(languageCode);
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return 'tomorrow'.tr(languageCode);
    } else {
      return _formatDate(date, languageCode);
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
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
                          // ✅ OPTIMISATION: Ne pas recharger ici, le stream listener s'en charge automatiquement

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
                              SnackBar(
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
                Text(
                  'Ou créer un nouveau repas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Options pour créer un nouveau repas avec traduction
              Consumer<LocalizationService>(
                builder: (context, locService, child) {
                  final mealTypes = [
                    ('breakfast', 'breakfast'.tr(locService.currentLanguageCode)),
                    ('lunch', 'lunch'.tr(locService.currentLanguageCode)),
                    ('snack', 'snack'.tr(locService.currentLanguageCode)),
                    ('dinner', 'dinner'.tr(locService.currentLanguageCode)),
                  ];
                  
                  return Column(
                    children: mealTypes.map((mealData) {
                      final mealKey = mealData.$1;
                      final mealType = mealData.$2;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MealOptionWidget(
                          icon: _getMealIcon(mealType),
                          title: '${"new_meal_type".tr(locService.currentLanguageCode)} $mealType',
                          subtitle: 'create_new_meal_block'.tr(locService.currentLanguageCode),
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
                            // ✅ OPTIMISATION: Ne pas recharger ici, le stream listener s'en charge automatiquement

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
                                SnackBar(
                                  content: Text('Erreur lors de la création du repas'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
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
                    }).toList(),
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
                          Text(
                            'no_meals_recorded'.tr(LocalizationService.instance.currentLanguageCode),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'add_first_meal_message'.tr(LocalizationService.instance.currentLanguageCode),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.plus,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'add_meal'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
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
                                Consumer<LocalizationService>(
                                  builder: (context, localizationService, child) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getDateTitle(selectedDate, localizationService.currentLanguageCode),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        Text(
                                          _formatDate(selectedDate, localizationService.currentLanguageCode),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color(0xFF1A1A1A).withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                GestureDetector(
                                  onTap: _openCalendar, // OPTIMISATION: Pré-charge avant d'afficher
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _isPreloadingCalendar
                                        ? const Color(0xFF1C2951) // Feedback visuel pendant préchargement
                                        : const Color(0xFF0B132B),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _isPreloadingCalendar
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
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

                      // Coach Ryze Nutrition Button
                      FutureBuilder<Map<String, dynamic>>(
                        future: _getWorkoutInfo(),
                        builder: (context, snapshot) {
                          final user = AuthService().currentUser;
                          if (user == null) return const SizedBox.shrink();

                          final workoutInfo = snapshot.data ?? {
                            'hasWorkout': false,
                            'workoutType': null,
                            'caloriesBurned': null,
                            'workoutTime': null,
                          };

                          // Calculer les totaux pour la journée
                          int totalCalories = 0;
                          double totalProteins = 0.0;
                          double totalCarbs = 0.0;
                          double totalFats = 0.0;

                          for (final meal in meals) {
                            for (final item in meal.items) {
                              totalCalories += item.calories;
                              totalProteins += item.proteins;
                              totalCarbs += item.carbs;
                              totalFats += item.fats;
                            }
                          }

                          final calorieTarget = user.dailyCalories ?? 2500;
                          final macroTargets = _getMacroTargets(calorieTarget);

                          return CoachRyzeNutritionButton(
                            userId: user.id,
                            date: selectedDate,
                            todayMeals: meals,
                            calorieTarget: calorieTarget,
                            proteinTarget: macroTargets['protein']!,
                            carbsTarget: macroTargets['carbs']!,
                            fatsTarget: macroTargets['fats']!,
                            waterIntake: 0, // TODO: Intégrer water intake si disponible
                            hasWorkoutToday: workoutInfo['hasWorkout'] as bool,
                            workoutType: workoutInfo['workoutType'] as String?,
                            caloriesBurned: workoutInfo['caloriesBurned'] as int?,
                            workoutTime: workoutInfo['workoutTime'] as DateTime?,
                          );
                        },
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
                                  // ✅ OPTIMISATION: Ne pas recharger ici, le stream listener s'en charge automatiquement
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'add_meal'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
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
                Consumer<LocalizationService>(
                  builder: (context, localizationService, child) {
                    return Text(
                      'calorie_summary'.tr(localizationService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ligne de texte principale avec style bicolore
            Consumer<LocalizationService>(
              builder: (context, locService, child) => RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$totalCalories kcal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    TextSpan(
                      text: ' / $targetCalories ${"kcal_consumed".tr(locService.currentLanguageCode)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
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
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => _buildSimpleMacroIndicator(
                    'proteins'.tr(locService.currentLanguageCode),
                    '${totalProteins.toStringAsFixed(0)}g',
                  ),
                ),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => _buildSimpleMacroIndicator(
                    'carbs'.tr(locService.currentLanguageCode),
                    '${totalCarbs.toStringAsFixed(0)}g',
                  ),
                ),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => _buildSimpleMacroIndicator(
                    'lipids'.tr(locService.currentLanguageCode),
                    '${totalFats.toStringAsFixed(0)}g',
                  ),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// Récupérer les informations de workout pour la date sélectionnée
  Future<Map<String, dynamic>> _getWorkoutInfo() async {
    // Pour l'instant, retourner false (pas de workout)
    // TODO: Implémenter la récupération des workouts depuis Supabase
    return {
      'hasWorkout': false,
      'workoutType': null,
      'caloriesBurned': null,
      'workoutTime': null,
    };
  }

  /// Calculer les objectifs macros basés sur l'utilisateur
  Map<String, double> _getMacroTargets(int calorieTarget) {
    // Répartition standard : 30% protéines, 40% glucides, 30% lipides
    final proteinCalories = calorieTarget * 0.30;
    final carbsCalories = calorieTarget * 0.40;
    final fatsCalories = calorieTarget * 0.30;

    return {
      'protein': proteinCalories / 4, // 4 kcal par gramme
      'carbs': carbsCalories / 4,     // 4 kcal par gramme
      'fats': fatsCalories / 9,       // 9 kcal par gramme
    };
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
              Consumer<LocalizationService>(
                builder: (context, localizationService, child) {
                  return Text(
                    'add_food'.tr(localizationService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              Text(
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
                title: 'manual_entry'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                subtitle: 'search_add_manually'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                onTap: () {
                  Navigator.pop(context);
                  _showManualEntryBottomSheet();
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.camera,
                title: 'Scanner avec l\'IA',
                subtitle: 'take_photo_of_dish'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                onTap: () {
                  Navigator.pop(context);
                  // ✅ Navigation directe avec informations du repas sélectionné
                  String? mealName;
                  String? mealId;
                  
                  if (_selectedMealIndex != null && _selectedMealIndex! < meals.length) {
                    final selectedMeal = meals[_selectedMealIndex!];
                    mealName = selectedMeal.name;
                    mealId = selectedMeal.id;
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AIScannerScreen(
                        isFromDashboard: false,
                        mealName: mealName,
                        mealId: mealId,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.scan,
                title: 'barcode'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                subtitle: 'scan_barcode_subtitle'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarcodeScannerScreen(
                        isFromDashboard: false,
                        onFoodScanned: (food) => _addFoodToSelectedMeal(food), // Passer le callback
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.chefHat,
                title: 'my_recipes'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                subtitle: 'choose_saved_recipes'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
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
