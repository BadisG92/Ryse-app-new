import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';
import '../models/nutrition_models.dart';
import '../widgets/nutrition/meal_card.dart';
import '../widgets/nutrition/calendar_view.dart';
import '../bottom_sheets/add_food_bottom_sheet.dart';
import '../bottom_sheets/add_meal_bottom_sheet.dart';
import '../bottom_sheets/manual_entry_bottom_sheet.dart';
import '../bottom_sheets/food_details_bottom_sheet.dart';

class NutritionJournal extends StatefulWidget {
  const NutritionJournal({super.key});

  @override
  State<NutritionJournal> createState() => _NutritionJournalState();
}

class _NutritionJournalState extends State<NutritionJournal> {
  bool showCalendar = false;

  final List<Meal> meals = [
    Meal(
      time: "08:30",
      name: "Petit-déjeuner",
      items: [
        FoodItem(name: "Avoine avec fruits", calories: 320, portion: "1 bol"),
        FoodItem(name: "Café noir", calories: 5, portion: "1 tasse"),
      ],
    ),
    Meal(
      time: "13:00",
      name: "Déjeuner",
      items: [
        FoodItem(name: "Salade de quinoa", calories: 450, portion: "1 assiette"),
        FoodItem(name: "Saumon grillé", calories: 280, portion: "150g"),
      ],
    ),
    Meal(
      time: "16:00",
      name: "Collation",
      items: [
        FoodItem(name: "Pomme", calories: 80, portion: "1 moyenne"),
        FoodItem(name: "Amandes", calories: 160, portion: "30g"),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (showCalendar) {
      return CalendarView(
        onBack: () => setState(() => showCalendar = false),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header avec date et calendrier
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // Résumé du jour
          _buildDaySummary(),
          
          const SizedBox(height: 24),
          
          // Liste des repas
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                ...meals.map((meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MealCard(
                    meal: meal,
                    onAddFood: () => AddFoodBottomSheet.show(context, _showManualEntryBottomSheet),
                  ),
                )),
                
                const SizedBox(height: 16),
                
                // Ajouter un repas
                GestureDetector(
                  onTap: () => AddMealBottomSheet.show(context, () => AddFoodBottomSheet.show(context, _showManualEntryBottomSheet)),
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              LucideIcons.chevronLeft,
              size: 20,
              color: Color(0xFF888888),
            ),
          ),
        ),
        
        Column(
          children: [
            const Text(
              'Aujourd\'hui',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B132B),
              ),
            ),
            const Text(
              'Mercredi 15 janvier',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => showCalendar = true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                child: const Icon(
                  LucideIcons.calendar,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaySummary() {
    // Données caloriques
    const int currentCalories = 1295;
    const int targetCalories = 2500;
    final double progressPercentage = (currentCalories / targetCalories) * 100;
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Ligne de titre avec icône
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.flame,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
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
                    text: '$currentCalories kcal',
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
                child: LinearProgressIndicator(
                  value: (currentCalories / targetCalories).clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0B132B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }













  Widget _buildCalendarGrid(Map<String, Map<String, dynamic>> nutritionData, DateTime currentDate) {
    final List<String> dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final List<String> monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    
    final days = _getDaysInMonth(currentDate);
    
    return CustomCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(0.9),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Navigation mois
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {}, // TODO: Implémenter navigation mois précédent
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
                Text(
                  '${monthNames[currentDate.month - 1]} ${currentDate.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                GestureDetector(
                  onTap: () {}, // TODO: Implémenter navigation mois suivant
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Jours de la semaine
            Row(
              children: dayNames.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
              )).toList(),
            ),
            
            const SizedBox(height: 8),
            
            // Grille du calendrier
            ...List.generate(6, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final index = weekIndex * 7 + dayIndex;
                    if (index >= days.length) return const Expanded(child: SizedBox());
                    
                    final day = days[index];
                    final data = _getNutritionData(nutritionData, day.date);
                    final isToday = _isSameDay(day.date, DateTime.now());
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onDayTap(day.date),
                        child: Container(
                          height: 36,
                          margin: const EdgeInsets.all(2),
                          decoration: _getDayDecoration(day, data, isToday),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.date.day}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _getDayTextColor(day, data, isToday),
                                ),
                              ),
                              if (data != null && day.isCurrentMonth)
                                Text(
                                  '${data['calories']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getDayTextColor(day, data, isToday).withOpacity(0.8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Méthodes utilitaires
  Map<String, int> _calculateMonthStats(Map<String, Map<String, dynamic>> nutritionData, DateTime currentDate) {
    final monthEntries = nutritionData.entries.where((entry) {
      final date = DateTime.parse(entry.key);
      return date.month == currentDate.month && date.year == currentDate.year;
    }).toList();
    
    final total = monthEntries.length;
    final achieved = monthEntries.where((entry) => entry.value['achieved'] == true).length;
    final totalCalories = monthEntries.fold(0, (sum, entry) => sum + (entry.value['calories'] as int));
    
    return {
      'successRate': total > 0 ? ((achieved / total) * 100).round() : 0,
      'achieved': achieved,
      'avgCalories': total > 0 ? (totalCalories / total).round() : 0,
    };
  }

  List<({DateTime date, bool isCurrentMonth})> _getDaysInMonth(DateTime date) {
    final year = date.year;
    final month = date.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    // Ajustement pour commencer la semaine au lundi (lundi = 0, dimanche = 6)
    final startingDayOfWeek = (firstDay.weekday - 1) % 7;

    final List<({DateTime date, bool isCurrentMonth})> days = [];

    // Jours du mois précédent
    for (int i = startingDayOfWeek - 1; i >= 0; i--) {
      final prevDate = DateTime(year, month, -i);
      days.add((date: prevDate, isCurrentMonth: false));
    }

    // Jours du mois actuel
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDateInMonth = DateTime(year, month, day);
      days.add((date: currentDateInMonth, isCurrentMonth: true));
    }

    // Jours du mois suivant pour compléter 6 semaines (42 jours)
    while (days.length < 42) {
      final nextDate = DateTime(year, month + 1, days.length - startingDayOfWeek - daysInMonth + 1);
      days.add((date: nextDate, isCurrentMonth: false));
    }

    return days;
  }

  Map<String, dynamic>? _getNutritionData(Map<String, Map<String, dynamic>> nutritionData, DateTime date) {
    final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return nutritionData[dateStr];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  BoxDecoration _getDayDecoration(({DateTime date, bool isCurrentMonth}) day, Map<String, dynamic>? data, bool isToday) {
    if (!day.isCurrentMonth) {
      return const BoxDecoration();
    }

    Color backgroundColor;
    Color? borderColor;

    if (data == null) {
      backgroundColor = const Color(0xFFF8F8F8);
    } else if (data['achieved'] == true) {
      backgroundColor = const Color(0xFF0B132B);
    } else {
      backgroundColor = const Color(0xFFFFE5E5);
    }

    // Bordure spéciale pour le jour actuel
    if (isToday) {
      borderColor = const Color(0xFF1C2951);
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
    );
  }

  Color _getDayTextColor(({DateTime date, bool isCurrentMonth}) day, Map<String, dynamic>? data, bool isToday) {
    if (!day.isCurrentMonth) {
      return const Color(0xFFCCCCCC);
    }

    if (data == null) {
      return isToday ? const Color(0xFF0B132B) : const Color(0xFF888888);
    }

    if (data['achieved'] == true) {
      return Colors.white;
    } else {
      return const Color(0xFF888888);
    }
  }

  void _onDayTap(DateTime date) {
    // TODO: Implémenter la navigation vers le journal du jour sélectionné
    // Ici on pourrait:
    // 1. Revenir à la vue journal avec la date sélectionnée
    // 2. Mettre à jour l'état pour afficher les données de ce jour
    // 3. Naviguer vers une nouvelle page avec les détails du jour
    
    print('Jour sélectionné: ${date.day}/${date.month}/${date.year}');
    
    // Exemple de ce qu'on pourrait faire plus tard:
    // setState(() {
    //   showCalendar = false;
    //   selectedDate = date;
    // });
    
    // Ou navigation vers une page détaillée:
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => NutritionJournalDay(date: date)
    // ));
  }







  void _showManualEntryBottomSheet() {
    ManualEntryBottomSheet.show(context, _showFoodDetailsBottomSheet);
  }



  void _showFoodDetailsBottomSheet(String name, int calories, int baseWeight) {
    FoodDetailsBottomSheet.show(context, name, calories, baseWeight);
  }
}

 