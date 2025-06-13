import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/ui/custom_card.dart';

class SportCalendarView extends StatefulWidget {
  final VoidCallback onBack;

  const SportCalendarView({
    super.key,
    required this.onBack,
  });

  @override
  State<SportCalendarView> createState() => _SportCalendarViewState();
}

class _SportCalendarViewState extends State<SportCalendarView> {
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime currentDate = DateTime.now();
    
    // Génération des données pour le mois sélectionné
    final Map<String, Map<String, dynamic>> sportData = _generateMonthData(selectedMonth);

    // Calcul des stats du mois sélectionné
    final monthStats = _calculateMonthStats(sportData, selectedMonth);
    
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
            // Header avec navigation
            SportCalendarHeader(
              onBack: widget.onBack,
            ),
            
            const SizedBox(height: 20),
            
            // Stats du mois
            SportMonthStats(monthStats: monthStats),
            
            const SizedBox(height: 16),
            
            // Légende
            const SportCalendarLegend(),
            
            const SizedBox(height: 16),
            
            // Calendrier
            SportCalendarGrid(
              sportData: sportData, 
              currentDate: currentDate,
              selectedMonth: selectedMonth,
              onPreviousMonth: _previousMonth,
              onNextMonth: _nextMonth,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _generateMonthData(DateTime month) {
    // Génération de données fictives pour le mois sélectionné
    final Map<String, Map<String, dynamic>> data = {};
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey = "${month.year}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
      
      // Pattern pour générer des données variées
      if (day % 7 == 0 || day % 7 == 6) { // Weekend - repos
        data[dateKey] = {"activities": [], "completed": false};
      } else if (day % 3 == 0) { // Tous les 3 jours - cardio + musculation
        data[dateKey] = {"activities": ["musculation", "cardio"], "completed": true};
      } else if (day % 2 == 0) { // Jours pairs - musculation
        data[dateKey] = {"activities": ["musculation"], "completed": true};
      } else if (day % 5 == 1) { // Certains jours - cardio
        data[dateKey] = {"activities": ["cardio"], "completed": true};
      } else { // Autres jours - repos
        data[dateKey] = {"activities": [], "completed": false};
      }
    }
    
    return data;
  }

  Map<String, int> _calculateMonthStats(Map<String, Map<String, dynamic>> sportData, DateTime month) {
    final monthEntries = sportData.entries.where((entry) {
      final date = DateTime.parse(entry.key);
      return date.month == month.month && date.year == month.year;
    }).toList();
    
    final total = monthEntries.length;
    final activeDays = monthEntries.where((entry) => (entry.value['activities'] as List).isNotEmpty).length;
    final musculationDays = monthEntries.where((entry) => (entry.value['activities'] as List).contains('musculation')).length;
    final cardioDays = monthEntries.where((entry) => (entry.value['activities'] as List).contains('cardio')).length;
    final bothDays = monthEntries.where((entry) {
      final activities = entry.value['activities'] as List;
      return activities.contains('musculation') && activities.contains('cardio');
    }).length;
    
    return {
      'activeDays': activeDays,
      'musculationDays': musculationDays,
      'cardioDays': cardioDays,
      'bothDays': bothDays,
      'successRate': total > 0 ? ((activeDays / total) * 100).round() : 0,
    };
  }
}

class SportCalendarHeader extends StatelessWidget {
  final VoidCallback onBack;

  const SportCalendarHeader({
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
              'Calendrier sportif',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              'Suivi de vos activités sportives',
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

class SportMonthStats extends StatelessWidget {
  final Map<String, int> monthStats;

  const SportMonthStats({
    super.key,
    required this.monthStats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Jours actifs
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
                    '${monthStats['activeDays']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const Text(
                    'Jours actifs',
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
          
        // Musculation
        Expanded(
          child: CustomCard(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withOpacity(0.9),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    '${monthStats['musculationDays']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const Text(
                    'Musculation',
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
        
        // Cardio
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
                    '${monthStats['cardioDays']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C2951),
                    ),
                  ),
                  const Text(
                    'Cardio',
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

class SportCalendarLegend extends StatelessWidget {
  const SportCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Légende',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Musculation - Format carré comme nutrition
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: const Icon(
                          LucideIcons.dumbbell,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Musculation',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Cardio - Format carré comme nutrition
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0B132B).withOpacity(0.7), 
                              const Color(0xFF1C2951).withOpacity(0.7)
                            ],
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                        ),
                        child: const Icon(
                          LucideIcons.activity,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Cardio',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Repos - Format carré comme nutrition
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Repos',
                          style: TextStyle(
                            fontSize: 13,
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
          ],
        ),
      ),
    );
  }
}

class SportCalendarGrid extends StatelessWidget {
  final Map<String, Map<String, dynamic>> sportData;
  final DateTime currentDate;
  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const SportCalendarGrid({
    super.key,
    required this.sportData,
    required this.currentDate,
    required this.selectedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  String _getMonthName(int month) {
    const monthNames = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return monthNames[month];
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation mois/année centrée comme dans le calendrier nutritionnel
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onPreviousMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: onNextMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // En-têtes des jours de la semaine
            Row(
              children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) {
                return Expanded(
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
                );
              }).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Grille du calendrier avec jours précédents/suivants
            ..._buildCalendarWeeks(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCalendarWeeks() {
    final DateTime firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final DateTime lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final int firstWeekday = firstDayOfMonth.weekday; // 1 = lundi, 7 = dimanche
    
    // Calculer les jours à afficher du mois précédent
    final DateTime lastDayOfPreviousMonth = DateTime(selectedMonth.year, selectedMonth.month, 0);
    final List<DateTime> daysToShow = [];
    
    // Ajouter les jours du mois précédent si nécessaire
    for (int i = firstWeekday - 1; i > 0; i--) {
      daysToShow.add(DateTime(lastDayOfPreviousMonth.year, lastDayOfPreviousMonth.month, lastDayOfPreviousMonth.day - i + 1));
    }
    
    // Ajouter tous les jours du mois actuel
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      daysToShow.add(DateTime(selectedMonth.year, selectedMonth.month, day));
    }
    
    // Ajouter les jours du mois suivant pour compléter la grille
    final int remainingCells = 42 - daysToShow.length; // 6 semaines × 7 jours
    for (int day = 1; day <= remainingCells; day++) {
      daysToShow.add(DateTime(selectedMonth.year, selectedMonth.month + 1, day));
    }
    
    // Créer les semaines
    final List<Widget> weeks = [];
    for (int weekIndex = 0; weekIndex < 6; weekIndex++) {
      final List<Widget> weekDays = [];
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final int index = weekIndex * 7 + dayIndex;
        if (index < daysToShow.length) {
          final DateTime dayDate = daysToShow[index];
          weekDays.add(_buildDayCell(dayDate));
        }
      }
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: weekDays),
        ),
      );
    }
    
    return weeks;
  }

  Widget _buildDayCell(DateTime dayDate) {
    final bool isCurrentMonth = dayDate.month == selectedMonth.month;
    final bool isCurrentDay = dayDate.year == currentDate.year && 
                             dayDate.month == currentDate.month && 
                             dayDate.day == currentDate.day;
    
    final String dateKey = "${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}";
    final Map<String, dynamic>? dayData = sportData[dateKey];
    
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(1),
        child: dayData != null && isCurrentMonth
            ? SportDayIcon(
                activities: List<String>.from(dayData['activities']),
                dayNumber: dayDate.day,
                isCurrentDay: isCurrentDay,
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isCurrentMonth ? Colors.transparent : Colors.transparent,
                  border: isCurrentDay 
                      ? Border.all(color: const Color(0xFF0B132B), width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    dayDate.day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: isCurrentMonth 
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFBBBBBB), // Grisé pour les autres mois
                      fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class SportDayIcon extends StatelessWidget {
  final List<String> activities;
  final int dayNumber;
  final bool isCurrentDay;

  const SportDayIcon({
    super.key,
    required this.activities,
    required this.dayNumber,
    required this.isCurrentDay,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      // Jour de repos - Identique au dashboard
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            dayNumber.toString(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
    } else if (activities.contains('musculation') && activities.contains('cardio')) {
      // Les deux activités - Taille maximale pour correspondre aux autres
      return CombinedActivityIcon(
        size: 40, // Augmenté de 38 à 40
        dayNumber: dayNumber,
      );
    } else if (activities.contains('musculation')) {
      // Musculation seulement avec gradient comme dans le dashboard
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                LucideIcons.dumbbell,
                size: 14,
                color: Colors.white,
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Text(
                dayNumber.toString(),
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (activities.contains('cardio')) {
      // Cardio seulement avec gradient comme dans le dashboard
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B132B).withOpacity(0.7), 
              const Color(0xFF1C2951).withOpacity(0.7)
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                LucideIcons.activity,
                size: 14,
                color: Colors.white,
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Text(
                dayNumber.toString(),
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(); // Fallback
  }
}

class CombinedActivityIcon extends StatelessWidget {
  final double size;
  final int? dayNumber;

  const CombinedActivityIcon({
    super.key,
    required this.size,
    this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Partie musculation (haut-gauche) - Couleur légende
          ClipPath(
            clipper: UpperLeftClipper(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF0B132B), // Couleur de la légende musculation
              ),
              child: const Align(
                alignment: Alignment(-0.3, -0.3),
                child: Icon(
                  LucideIcons.dumbbell,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Partie cardio (bas-droite) - Couleur avec gradient comme dashboard
          ClipPath(
            clipper: LowerRightClipper(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0B132B).withOpacity(0.7), 
                    const Color(0xFF1C2951).withOpacity(0.7)
                  ],
                ),
              ),
              child: const Align(
                alignment: Alignment(0.3, 0.3),
                child: Icon(
                  LucideIcons.activity,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Numéro du jour
          if (dayNumber != null)
            Positioned(
              bottom: 2,
              right: 2,
              child: Text(
                dayNumber.toString(),
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class UpperLeftClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LowerRightClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
} 
