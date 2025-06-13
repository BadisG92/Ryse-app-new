import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/ui/custom_card.dart';

class CalendarView extends StatelessWidget {
  final VoidCallback onBack;

  const CalendarView({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
            CalendarHeader(onBack: onBack),
            
            const SizedBox(height: 20),
            
            // Stats du mois
            MonthStats(monthStats: monthStats),
            
            const SizedBox(height: 16),
            
            // Légende
            const CalendarLegend(),
            
            const SizedBox(height: 16),
            
            // Calendrier
            CalendarGrid(nutritionData: nutritionData, currentDate: currentDate),
          ],
        ),
      ),
    );
  }

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
}

class CalendarHeader extends StatelessWidget {
  final VoidCallback onBack;

  const CalendarHeader({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
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
}

class MonthStats extends StatelessWidget {
  final Map<String, int> monthStats;

  const MonthStats({
    super.key,
    required this.monthStats,
  });

  @override
  Widget build(BuildContext context) {
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
                    '${monthStats['successRate']}%',
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
                    '${monthStats['achieved']}',
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
                    '${monthStats['avgCalories']}',
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
}

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class CalendarGrid extends StatelessWidget {
  final Map<String, Map<String, dynamic>> nutritionData;
  final DateTime currentDate;

  const CalendarGrid({
    super.key,
    required this.nutritionData,
    required this.currentDate,
  });

  @override
  Widget build(BuildContext context) {
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
    print('Jour sélectionné: ${date.day}/${date.month}/${date.year}');
  }
} 
