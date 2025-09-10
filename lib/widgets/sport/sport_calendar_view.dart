import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../components/ui/custom_card.dart';
import '../../services/sport_dashboard_service.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';

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
  Map<String, Map<String, dynamic>> _sportData = {};
  Map<String, dynamic> _monthStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    setState(() {
      _loading = true;
    });

    try {
      final data = await SportDashboardService.getMonthSportData(selectedMonth);
      setState(() {
        _sportData = Map<String, Map<String, dynamic>>.from(data['monthData'] ?? {});
        _monthStats = data['stats'] ?? {};
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      debugPrint('❌ Error loading calendar data: $e');
    }
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    });
    _loadMonthData();
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    });
    _loadMonthData();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime currentDate = DateTime.now();
    
    if (_loading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
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
      child: Consumer<LocalizationService>(
        builder: (context, locService, _) => SingleChildScrollView(
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
            SportMonthStats(monthStats: Map<String, int>.from(_monthStats)),
            
            const SizedBox(height: 16),
            
            // Légende
            const SportCalendarLegend(),
            
            const SizedBox(height: 16),
            
            // Calendrier
            SportCalendarGrid(
              sportData: _sportData, 
              currentDate: currentDate,
              selectedMonth: selectedMonth,
              onPreviousMonth: _previousMonth,
              onNextMonth: _nextMonth,
            ),
          ],
        ),
      ),
    ),
    );
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
        Consumer<LocalizationService>(
          builder: (context, locService, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sport_calendar_title'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'sport_calendar_subtitle'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
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
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => Row(
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
                    Text(
                      'sport_active_days'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
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
                    Text(
                      'sport_muscle_training'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
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
                    Text(
                      'sport_cardio'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
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
      ),
    );
  }
}

class SportCalendarLegend extends StatelessWidget {
  const SportCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sport_legend'.tr(locService.currentLanguageCode),
                style: const TextStyle(
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
                        Flexible(
                          child: Text(
                            'sport_muscle_training'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
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
                        Flexible(
                          child: Text(
                            'sport_cardio'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
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
                        Flexible(
                          child: Text(
                            'sport_rest'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
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

  String _getMonthName(int month, String languageCode) {
    const monthKeys = [
      '', 'month_january', 'month_february', 'month_march', 'month_april', 'month_may', 'month_june',
      'month_july', 'month_august', 'month_september', 'month_october', 'month_november', 'month_december'
    ];
    return monthKeys[month].tr(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => CustomCard(
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
                    '${_getMonthName(selectedMonth.month, locService.currentLanguageCode)} ${selectedMonth.year}',
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
                children: ['day_mon', 'day_tue', 'day_wed', 'day_thu', 'day_fri', 'day_sat', 'day_sun'].map((dayKey) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        dayKey.tr(locService.currentLanguageCode),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF1F5F9),
                  border: isCurrentDay 
                      ? Border.all(color: const Color(0xFF1C2951), width: 2)
                      : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Text(
                    dayDate.day.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrentMonth 
                          ? const Color(0xFF64748B)
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
    const double size = 40.0;
    
    if (activities.isEmpty) {
      // Jour de repos - Taille fixe et centré
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF1F5F9),
          border: isCurrentDay 
              ? Border.all(color: const Color(0xFF1C2951), width: 2)
              : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            dayNumber.toString(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } else if (activities.contains('musculation') && activities.contains('cardio')) {
      // Les deux activités - Taille fixe
      return CombinedActivityIcon(
        size: size,
        dayNumber: dayNumber,
        isCurrentDay: isCurrentDay,
      );
    } else if (activities.contains('musculation')) {
      // Musculation seulement - Taille fixe
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
          ),
          border: isCurrentDay 
              ? Border.all(color: const Color(0xFF1C2951), width: 2)
              : null,
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
      // Cardio seulement - Taille fixe
      return Container(
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
          border: isCurrentDay 
              ? Border.all(color: const Color(0xFF1C2951), width: 2)
              : null,
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
  final bool isCurrentDay;

  const CombinedActivityIcon({
    super.key,
    required this.size,
    this.dayNumber,
    this.isCurrentDay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isCurrentDay 
            ? Border.all(color: const Color(0xFF1C2951), width: 2)
            : null,
      ),
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
                alignment: Alignment(-0.2, -0.2),
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
                alignment: Alignment(0.2, 0.2),
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
