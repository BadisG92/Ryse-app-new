import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';
import '../screens/manual_food_entry_screen.dart';

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
      return _buildCalendarView();
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
                  child: _buildMealCard(meal),
                )),
                
                const SizedBox(height: 16),
                
                // Ajouter un repas
                _buildAddMealButton(),
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

  Widget _buildMealCard(Meal meal) {
    int totalCalories = meal.items.fold(0, (sum, item) => sum + item.calories);
    
    return CustomCard(
      child: Column(
        children: [
          // Header du repas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFF8F8F8),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      meal.time,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$totalCalories kcal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des aliments
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...meal.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFoodItem(item),
                )),
                
                const SizedBox(height: 8),
                
                // Bouton ajouter un aliment
                GestureDetector(
                  onTap: () => _showAddFoodBottomSheet(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: Color(0xFF0B132B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ajouter un aliment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0B132B),
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

  Widget _buildFoodItem(FoodItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                item.portion,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Text(
              '${item.calories} kcal',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B132B),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  LucideIcons.moreHorizontal,
                  size: 16,
                  color: Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddMealButton() {
    return GestureDetector(
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
    );
  }

  Widget _buildCalendarView() {
    final DateTime currentDate = DateTime.now();
    
    // Données fictives pour l'exemple (comme dans le TSX)
    final Map<String, Map<String, dynamic>> nutritionData = {
      "2024-01-01": {"calories": 2100, "target": 2500, "achieved": false},
      "2024-01-02": {"calories": 2450, "target": 2500, "achieved": true},
      "2024-01-03": {"calories": 2600, "target": 2500, "achieved": true},
      "2024-01-04": {"calories": 1800, "target": 2500, "achieved": false},
      "2024-01-05": {"calories": 2520, "target": 2500, "achieved": true},
      "2024-01-06": {"calories": 2300, "target": 2500, "achieved": false},
      "2024-01-07": {"calories": 2480, "target": 2500, "achieved": true},
      "2024-01-08": {"calories": 2550, "target": 2500, "achieved": true},
      "2024-01-09": {"calories": 2200, "target": 2500, "achieved": false},
      "2024-01-10": {"calories": 2650, "target": 2500, "achieved": true},
      "2024-01-11": {"calories": 2400, "target": 2500, "achieved": false},
      "2024-01-12": {"calories": 2580, "target": 2500, "achieved": true},
      "2024-01-13": {"calories": 2490, "target": 2500, "achieved": true},
      "2024-01-14": {"calories": 2350, "target": 2500, "achieved": false},
      "2024-01-15": {"calories": 1295, "target": 2500, "achieved": false}, // Jour actuel
    };

    // Calcul des stats du mois
    final monthStats = _calculateMonthStats(nutritionData, currentDate);
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header
            _buildCalendarHeader(),
            
            const SizedBox(height: 20),
            
            // Stats du mois
            _buildMonthStats(monthStats),
            
            const SizedBox(height: 16),
            
            // Légende
            _buildLegend(),
            
            const SizedBox(height: 16),
            
            // Calendrier
            _buildCalendarGrid(nutritionData, currentDate),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => showCalendar = false),
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Calendrier nutritionnel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            Text(
              'Suivi de vos objectifs caloriques',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
              ),
            ),
            ],
          ),
      ],
    );
  }

  Widget _buildMonthStats(Map<String, int> stats) {
    return Row(
      children: [
        // Objectifs atteints
        Expanded(
          child: CustomCard(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withOpacity(0.9),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    '${stats['successRate']}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const Text(
                    'Objectifs atteints',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
          
        // Jours réussis
        Expanded(
          child: CustomCard(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withOpacity(0.9),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    '${stats['achieved']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const Text(
                    'Jours réussis',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Kcal moyenne
          Expanded(
            child: CustomCard(
              child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withOpacity(0.9),
              ),
              padding: const EdgeInsets.all(12),
                  child: Column(
                children: [
                  Text(
                    '${stats['avgCalories']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const Text(
                    'kcal moyenne',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return CustomCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(0.9),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Objectif atteint
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                    children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Objectif atteint',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                      overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            // Objectif non atteint
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5E5),
                      border: Border.all(color: const Color(0xFFFF9999)),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Non atteint',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                      overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
              ),
            ),
            // Pas de données
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      border: Border.all(color: const Color(0xFFCCCCCC)),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Pas de données',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
              
              // Options
              _buildFoodOption(
                icon: LucideIcons.edit3,
                title: 'Saisie manuelle',
                subtitle: 'Rechercher et ajouter manuellement',
                onTap: () {
                  final parentContext = this.context;
                  Navigator.pop(context);
                  // Ouvrir le second bottom sheet pour la saisie manuelle
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _showManualEntryBottomSheet();
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildFoodOption(
                icon: LucideIcons.camera,
                title: 'Scanner avec l\'IA',
                subtitle: 'Prenez une photo de votre plat',
                onTap: () {
                  final parentContext = this.context;
                  Navigator.pop(context);
                  // Ouvrir la page scanner IA
                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (context) => const AIScannerScreen(),
                      ),
                    );
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildFoodOption(
                icon: LucideIcons.scan,
                title: 'Code-barres',
                subtitle: 'Scanner le code-barres du produit',
                onTap: () {
                  final parentContext = this.context;
                  Navigator.pop(context);
                  // Ouvrir la page scanner code-barres
                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (context) => const BarcodeScannerScreen(),
                      ),
                    );
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildFoodOption(
                icon: LucideIcons.chefHat,
                title: 'Mes recettes',
                subtitle: 'Choisir parmi vos recettes sauvegardées',
                onTap: () {
                  final parentContext = this.context;
                  Navigator.pop(context);
                  // Ouvrir la page sélection de recettes
                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (context) => const SelectRecipeScreen(),
                      ),
                    );
                  });
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
                'Ajouter un repas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Quel type de repas souhaitez-vous ajouter ?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Types de repas
              _buildMealOption(
                icon: LucideIcons.sunrise,
                title: 'Petit-déjeuner',
                subtitle: 'Commencez bien votre journée',
                onTap: () {
                  Navigator.pop(context);
                  // Ouvrir le bottom sheet d'ajout d'aliment après sélection du repas
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _showAddFoodBottomSheet();
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildMealOption(
                icon: LucideIcons.sun,
                title: 'Déjeuner',
                subtitle: 'Votre repas principal de midi',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _showAddFoodBottomSheet();
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildMealOption(
                icon: LucideIcons.sunset,
                title: 'Dîner',
                subtitle: 'Terminez la journée en beauté',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _showAddFoodBottomSheet();
                  });
                },
              ),
              
              const SizedBox(width: 12),
              
              _buildMealOption(
                icon: LucideIcons.milk,
                title: 'Collation',
                subtitle: 'Une petite pause gourmande',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _showAddFoodBottomSheet();
                  });
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
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
                
                // Header
                Row(
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
                
                const SizedBox(height: 20),
                
                // Champ de recherche
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: TextField(
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
                    onChanged: (value) {
                      // TODO: Implémenter la recherche avec suggestions
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Bouton "Ajouter manuellement"
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final parentContext = this.context;
                      Navigator.pop(context);
                      // TODO: Ouvrir l'écran d'ajout manuel
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Navigator.push(
                          parentContext,
                          MaterialPageRoute(
                            builder: (context) => const ManualFoodEntryScreen(),
                          ),
                        );
                      });
                    },
                    icon: const Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: Color(0xFF0B132B),
                    ),
                    label: const Text(
                      'Ajouter un aliment manuellement',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: Color(0xFF0B132B),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                // Liste des suggestions
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      // Suggestions d'aliments (mockées pour l'instant)
                      _buildFoodSuggestion(
                        name: 'Pomme rouge',
                        calories: 52,
                        per: '100g',
                        onTap: () => _showFoodDetailsBottomSheet('Pomme rouge', 52, 100),
                      ),
                      _buildFoodSuggestion(
                        name: 'Banane',
                        calories: 89,
                        per: '100g',
                        onTap: () => _showFoodDetailsBottomSheet('Banane', 89, 100),
                      ),
                      _buildFoodSuggestion(
                        name: 'Riz blanc cuit',
                        calories: 130,
                        per: '100g',
                        onTap: () => _showFoodDetailsBottomSheet('Riz blanc cuit', 130, 100),
                      ),
                      _buildFoodSuggestion(
                        name: 'Poulet grillé',
                        calories: 165,
                        per: '100g',
                        onTap: () => _showFoodDetailsBottomSheet('Poulet grillé', 165, 100),
                      ),
                      _buildFoodSuggestion(
                        name: 'Brocolis cuits',
                        calories: 35,
                        per: '100g',
                        onTap: () => _showFoodDetailsBottomSheet('Brocolis cuits', 35, 100),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodSuggestion({
    required String name,
    required int calories,
    required String per,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$calories kcal / $per',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodDetailsBottomSheet(String name, int calories, int baseWeight) {
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
              
              // Header
              Row(
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
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Informations nutritionnelles
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          '$calories kcal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Protéines',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '${(calories * 0.1 / 4).toStringAsFixed(1)}g',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Glucides',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '${(calories * 0.6 / 4).toStringAsFixed(1)}g',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lipides',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '${(calories * 0.3 / 9).toStringAsFixed(1)}g',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Quantité
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: '100',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'grammes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton d'ajout
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Fermer les détails
                    Navigator.pop(context); // Fermer la recherche
                    // TODO: Ajouter l'aliment au repas
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name ajouté au repas'),
                        backgroundColor: const Color(0xFF0B132B),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ajouter au repas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Meal {
  final String time;
  final String name;
  final List<FoodItem> items;

  Meal({
    required this.time,
    required this.name,
    required this.items,
  });
}

class FoodItem {
  final String name;
  final int calories;
  final String portion;

  FoodItem({
    required this.name,
    required this.calories,
    required this.portion,
  });
} 