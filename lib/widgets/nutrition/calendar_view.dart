import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/ui/custom_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
class CalendarView extends StatefulWidget {
  final VoidCallback onBack;
  final Function(DateTime)? onDateSelected;
  final DateTime selectedDate;

  const CalendarView({
    super.key,
    required this.onBack,
    this.onDateSelected,
    required this.selectedDate,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime currentMonth = DateTime.now();
  Map<String, Map<String, dynamic>> _cachedNutritionData = {};
  Map<String, int> _cachedMonthStats = {'successRate': 0, 'achieved': 0, 'avgCalories': 0};
  bool _isLoading = true;
  int? _userTargetCalories;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadNutritionDataForMonth(currentMonth);
  }

  Future<void> _loadNutritionDataForMonth(DateTime month) async {
    if (!mounted) return;
    
    try {
      // Obtenir l'utilisateur actuel
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ Aucun utilisateur connecté');
        return;
      }

      // Récupérer l'objectif calorique de l'utilisateur une seule fois
      if (_userTargetCalories == null) {
        final userResponse = await Supabase.instance.client
            .from('users')
            .select('daily_calories')
            .eq('id', user.id)
            .single();
        _userTargetCalories = userResponse['daily_calories'] as int? ?? 2000;
        debugPrint('🎯 Objectif calorique utilisateur: $_userTargetCalories');
      }

      // Calculer les dates de début et fin du mois
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      debugPrint('📅 Recherche des données pour: ${startOfMonth.toString()} - ${endOfMonth.toString()}');

      // Récupérer les entrées alimentaires du mois
      final response = await Supabase.instance.client
          .from('food_entries')
          .select('consumed_at, calories')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfMonth.toIso8601String())
          .lte('consumed_at', endOfMonth.toIso8601String());

      debugPrint('📊 Nombre d\'entrées trouvées: ${response.length}');

      // Grouper les calories par jour
      final Map<String, int> dailyCalories = {};
      for (final entry in response) {
        final date = DateTime.parse(entry['consumed_at']).toLocal();
        final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final calories = entry['calories'] as int? ?? 0;
        dailyCalories[dateStr] = (dailyCalories[dateStr] ?? 0) + calories;
        debugPrint('🍽️ $dateStr: ${dailyCalories[dateStr]} calories');
      }

      // Construire les données nutritionnelles
      final Map<String, Map<String, dynamic>> nutritionData = {};
      dailyCalories.forEach((dateStr, calories) {
        nutritionData[dateStr] = {
          'calories': calories,
          'target': _userTargetCalories!,
          'achieved': calories >= (_userTargetCalories! * 0.9), // 90% de l'objectif = réussi
        };
      });

      // Calculer les statistiques du mois
      int achievedDays = 0;
      int totalCalories = 0;
      int daysWithData = dailyCalories.length;

      nutritionData.forEach((date, data) {
        if (data['achieved'] == true) achievedDays++;
        totalCalories += data['calories'] as int;
      });

      final successRate = daysWithData > 0 ? ((achievedDays / daysWithData) * 100).round() : 0;
      final avgCalories = daysWithData > 0 ? (totalCalories / daysWithData).round() : 0;

      debugPrint('📈 Stats calculées - Taux: $successRate%, Jours réussis: $achievedDays, Moyenne: $avgCalories kcal');

      if (mounted) {
        setState(() {
          _cachedNutritionData = nutritionData;
          _cachedMonthStats = {
            'successRate': successRate,
            'achieved': achievedDays,
            'avgCalories': avgCalories,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des données nutritionnelles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeMonth(bool next) async {
    setState(() {
      currentMonth = DateTime(
        currentMonth.year, 
        currentMonth.month + (next ? 1 : -1)
      );
    });
    
    // Charger les données du nouveau mois sans afficher le loader
    await _loadNutritionDataForMonth(currentMonth);
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMISATION: Afficher immédiatement, loader inline pendant chargement
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
          // Header avec navigation (non-sticky)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
          children: [
            GestureDetector(
                  onTap: widget.onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                ),
                child: const Icon(
                      LucideIcons.arrowLeft,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
            const SizedBox(width: 16),
                Consumer<LocalizationService>(
                  builder: (context, localizationService, child) {
                    return Text(
                      'nutrition_calendar'.tr(localizationService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Page scrollable avec tout le contenu
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + kBottomNavigationBarHeight),
              child: Column(
                children: [
                  // Stats du mois - avec loader inline si chargement
                  _isLoading
                    ? Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          color: Color(0xFF0B132B),
                        ),
                      )
                    : MonthStats(monthStats: _cachedMonthStats),

                  const SizedBox(height: 16),
                  
                  // Bloc calendrier unifié avec légende intégrée
                  CustomCard(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.9),
                  ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Header du mois dans le calendrier
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
                              // Flèche précédent
            GestureDetector(
                                onTap: () {
                                  _changeMonth(false);
                                },
              child: Container(
                                  padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF0B132B).withOpacity(0.1),
                ),
                child: const Icon(
                  LucideIcons.chevronLeft,
                  size: 16,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
                              
                              // Mois centré
                              Consumer<LocalizationService>(
                                builder: (context, localizationService, child) {
                                  return Text(
                                    _getMonthName(currentMonth, localizationService.currentLanguageCode),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  );
                                },
                              ),
                              
                              // Flèche suivant
            GestureDetector(
                                onTap: () {
                                  _changeMonth(true);
                                },
              child: Container(
                                  padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF0B132B).withOpacity(0.1),
                ),
                child: const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
          ],
        ),
                          
                          const SizedBox(height: 16),
                          
                          // Grille du calendrier
                          CalendarGrid(
                            nutritionData: _cachedNutritionData,
                            currentMonth: currentMonth,
                            selectedDate: widget.selectedDate,
                            onDateSelected: widget.onDateSelected,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Légende intégrée dans le bloc
                          const CalendarLegend(),
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

  String _getMonthName(DateTime date, String languageCode) {
    final monthNames = languageCode == 'en' 
        ? ['January', 'February', 'March', 'April', 'May', 'June',
           'July', 'August', 'September', 'October', 'November', 'December']
        : ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
           'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    
    return '${monthNames[date.month - 1]} ${date.year}';
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
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Consumer<LocalizationService>(
          builder: (context, localizationService, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildKpi(
                  value: '${monthStats['successRate']}%',
                  label: 'goals_achieved'.tr(localizationService.currentLanguageCode).replaceAll(' ', '\n'),
                  context: context,
                ),
                _buildKpi(
                  value: '${monthStats['achieved']}',
                  label: 'successful_days'.tr(localizationService.currentLanguageCode).replaceAll(' ', '\n'),
                  context: context,
                ),
                _buildKpi(
                  value: '${monthStats['avgCalories']}',
                  label: 'average_calories'.tr(localizationService.currentLanguageCode).replaceAll(' ', '\n'),
                  context: context,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpi({required String value, required String label, required BuildContext context}) {
    // Calculer la taille de police dynamiquement selon la longueur du nombre
    double fontSize = 18;
    if (value.length >= 6) {
      fontSize = 12; // Très grands nombres (6+ chiffres)
    } else if (value.length >= 5) {
      fontSize = 14; // Grands nombres (5 chiffres)
    } else if (value.length >= 4) {
      fontSize = 16; // Nombres moyens (4 chiffres)
    }

    return Expanded(
      child: Container(
        height: 80, // Hauteur fixe pour aligner tous les KPI
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B132B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Titre
        Consumer<LocalizationService>(
          builder: (context, localizationService, child) {
            return Text(
              'daily_calorie_goal_reached'.tr(localizationService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        // Gradient avec pourcentages
        Row(
          children: [
            // 0%
            const Text(
              '0%',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Carrés du gradient
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Niveau 0 - Gris (0%)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Niveau 1 - 25%
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
              ),
            ),
                  // Niveau 2 - 50%
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Niveau 3 - 75%
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
              ),
            ),
                  // Niveau 4 - 100%
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 100%
            const Text(
              '100%',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CalendarGrid extends StatelessWidget {
  final Map<String, Map<String, dynamic>> nutritionData;
  final DateTime currentMonth;
  final DateTime selectedDate;
  final Function(DateTime)? onDateSelected;

  const CalendarGrid({
    super.key,
    required this.nutritionData,
    required this.currentMonth,
    required this.selectedDate,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> dayNames = [
      'mon_short',
      'tue_short',
      'wed_short',
      'thu_short',
      'fri_short',
      'sat_short',
      'sun_short'
    ];
    final days = _getDaysInMonth(currentMonth);

    // Taille fixe de 40x40 pour garantir des cases carrées visibles sur tous les écrans (même style que calendrier sportif)
    const double cellSize = 40.0;

    return Column(
          children: [
            // Jours de la semaine
            Consumer<LocalizationService>(
              builder: (context, localizationService, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: dayNames.map((dayKey) => SizedBox(
                    width: cellSize,
                    child: Center(
                      child: Text(
                        dayKey.tr(localizationService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                  )).toList(),
                );
              },
            ),

            const SizedBox(height: 8),

            // Grille du calendrier
            ...List.generate(6, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (dayIndex) {
                    final index = weekIndex * 7 + dayIndex;
                    if (index >= days.length) return const SizedBox(width: cellSize);

                    final day = days[index];
                    final data = _getNutritionData(nutritionData, day.date);
                    final isToday = _isSameDay(day.date, DateTime.now());
                    final isSelected = _isSameDay(day.date, selectedDate);

                    return GestureDetector(
                      onTap: () => _onDayTap(day.date),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        margin: const EdgeInsets.all(1),
                        decoration: _getDayDecoration(day, data, isToday, isSelected),
                        child: Center(
                          child: Text(
                            '${day.date.day}',
                            style: TextStyle(
                              fontSize: isToday ? 14 : 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: _getDayTextColor(day, data, isToday, isSelected),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
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

  BoxDecoration _getDayDecoration(({DateTime date, bool isCurrentMonth}) day, Map<String, dynamic>? data, bool isToday, bool isSelected) {
    if (!day.isCurrentMonth) {
      return const BoxDecoration();
    }

    Color backgroundColor;
    Color? borderColor;

    if (isSelected) {
      // Le jour sélectionné garde une bordure distinctive
      borderColor = const Color(0xFF1C2951);
    }

    // Bordure spéciale pour le jour actuel
    if (isToday && !isSelected) {
      borderColor = const Color(0xFF1C2951);
    }

    // Debug: Afficher les données reçues
    final dateStr = "${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}";
    
    // Vérifier si c'est un jour futur (après aujourd'hui)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentDay = DateTime(day.date.year, day.date.month, day.date.day);
    final isFutureDay = currentDay.isAfter(today);
    
    // Si c'est un jour futur, fond blanc transparent
    if (isFutureDay) {
      backgroundColor = Colors.white.withOpacity(0.1);
    } else {
      // Calcul du niveau de couleur basé sur le pourcentage d'objectif pour les jours passés/actuels
      if (data == null || data['calories'] == null || data['target'] == null) {
        // Pas de données - gris clair
        backgroundColor = const Color(0xFFE5E7EB);
        if (day.date.day <= 5) { // Debug seulement pour les 5 premiers jours
          debugPrint('🔍 $dateStr: Pas de données -> Gris');
        }
      } else {
        final calories = data['calories'] as int;
        final targetCalories = data['target'] as int;

        if (targetCalories <= 0) {
          backgroundColor = const Color(0xFFE5E7EB);
          debugPrint('🔍 $dateStr: Target=0 -> Gris');
        } else {
          final percentage = (calories / targetCalories * 100).round();

          // Niveau de couleur basé sur le pourcentage
          if (percentage == 0) {
            backgroundColor = const Color(0xFFE5E7EB); // Gris - 0%
            debugPrint('🔍 $dateStr: $calories/$targetCalories (0%) -> Gris');
          } else if (percentage <= 25) {
            backgroundColor = const Color(0xFF0B132B).withOpacity(0.2); // Bleu très clair - 1-25%
            debugPrint('🔍 $dateStr: $calories/$targetCalories ($percentage%) -> Bleu 20%');
          } else if (percentage <= 50) {
            backgroundColor = const Color(0xFF0B132B).withOpacity(0.4); // Bleu clair - 26-50%
            debugPrint('🔍 $dateStr: $calories/$targetCalories ($percentage%) -> Bleu 40%');
          } else if (percentage <= 75) {
            backgroundColor = const Color(0xFF0B132B).withOpacity(0.6); // Bleu moyen - 51-75%
            debugPrint('🔍 $dateStr: $calories/$targetCalories ($percentage%) -> Bleu 60%');
          } else if (percentage <= 99) {
            backgroundColor = const Color(0xFF0B132B).withOpacity(0.8); // Bleu foncé - 76-99%
            debugPrint('🔍 $dateStr: $calories/$targetCalories ($percentage%) -> Bleu 80%');
          } else {
            backgroundColor = const Color(0xFF0B132B); // Bleu complet - 100%+
            debugPrint('🔍 $dateStr: $calories/$targetCalories ($percentage%) -> Bleu 100%');
          }
        }
      }
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
    );
  }

  Color _getDayTextColor(({DateTime date, bool isCurrentMonth}) day, Map<String, dynamic>? data, bool isToday, bool isSelected) {
    if (!day.isCurrentMonth) {
      return const Color(0xFFCCCCCC);
    }

    // Calcul de la couleur de texte basé sur l'intensité du fond
    if (data == null || data['calories'] == null || data['target'] == null) {
      // Pas de données - fond gris clair, texte foncé
      return const Color(0xFF374151);
    } else {
      final calories = data['calories'] as int;
      final targetCalories = data['target'] as int;
      
      if (targetCalories <= 0) {
        return const Color(0xFF374151);
      } else {
        final percentage = (calories / targetCalories * 100).round();
        
        // Couleur de texte selon l'intensité du fond
        if (percentage == 0) {
          return const Color(0xFF374151); // Fond gris - texte foncé
        } else if (percentage <= 25) {
          return const Color(0xFF374151); // Fond bleu très clair - texte foncé
        } else if (percentage <= 50) {
          return const Color(0xFF374151); // Fond bleu clair - texte foncé
        } else if (percentage <= 75) {
          return Colors.white; // Fond bleu moyen - texte blanc
        } else if (percentage <= 99) {
          return Colors.white; // Fond bleu foncé - texte blanc
        } else {
          return Colors.white; // Fond bleu complet - texte blanc
        }
      }
    }
  }

  void _onDayTap(DateTime date) {
    if (onDateSelected != null) {
      onDateSelected!(date);
    }
  }
} 

