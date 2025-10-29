import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import 'ui/custom_card.dart';
import '../screens/cardio_tracking_screen.dart';
import '../screens/hiit_session_screen.dart';
import '../screens/manual_cardio_entry_screen.dart';
import '../models/cardio_session_models.dart';
import '../models/hiit_models.dart';

import '../services/sport_dashboard_service.dart';
import '../services/cardio_service.dart';
import 'ui/cardio_models.dart';
import 'ui/chunked_progress_bar.dart';
import '../widgets/sport/sport_calendar_view.dart';
import 'shared/workout_actions.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';
import '../services/global_state_manager.dart';
import '../services/tutorial_service.dart'; // Tutorial système
import 'package:shared_preferences/shared_preferences.dart';

class SportDashboard extends StatefulWidget {
  final VoidCallback? onOpenCalendar;

  const SportDashboard({super.key, this.onOpenCalendar});

  @override
  State<SportDashboard> createState() => SportDashboardState();
}

class SportDashboardState extends State<SportDashboard> with TickerProviderStateMixin, GlobalStateListener<SportDashboard> {
  bool showCalendar = false;

  void openCalendar() {
    setState(() {
      showCalendar = true;
    });
  }

  /// Méthode appelée par GlobalStateListener quand les données changent
  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    debugPrint('🔄 SportDashboard: GlobalState mis à jour, rechargement des données...');
    _loadDashboardData();
  }
  SportDashboardData? _dashboardData;

  // Animation des calories
  int animatedCalories = 0;
  final List<Timer> _timers = [];
  Timer? _caloriesTimer;

  // ScrollController pour contrôler le scroll du tutorial
  final ScrollController _scrollController = ScrollController();

  // Tutorial GlobalKeys pour les éléments du dashboard
  final GlobalKey _caloriesCardKey = GlobalKey();
  final GlobalKey _sessionsCardKey = GlobalKey();
  final GlobalKey _splitCardKey = GlobalKey();
  final GlobalKey _quickActionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // OPTIMISATION: Chargement instantané depuis GlobalStateManager + cache
    _loadInitialDataSync();

    // Enrichissement en arrière-plan (non-bloquant)
    _loadDashboardData();

    // NE PAS lancer le tutorial automatiquement ici
    // Il sera lancé par la Section Sport après le welcome screen
  }

  /// Affiche le tutorial du Dashboard Sport
  /// Méthode publique appelée par la Section Sport après le welcome screen
  Future<void> showDashboardTutorial({
    required GlobalKey dashboardTabKey,
    required GlobalKey cardioTabKey,
    required GlobalKey musculationTabKey,
  }) async {
    // Vérifier si déjà complété (en mode debug, toujours afficher)
    const debugMode = false; // Mode production : tutoriels une seule fois
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('sport_dashboard_tutorial_completed') ?? false;
      if (completed) {
        debugPrint('ℹ️ Tutorial Dashboard Sport déjà complété');
        return;
      }
    }

    final locService = LocalizationService.instance;
    final languageCode = locService.currentLanguageCode;

    // Reset le scroll en haut pour avoir un état constant
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    // Attendre que le scroll soit bien à 0 et que tout soit rendu
    await Future.delayed(const Duration(milliseconds: 100));

    // Force un rebuild pour s'assurer que tout est stable
    if (mounted) {
      setState(() {});
    }

    // Délai supplémentaire pour garantir que tout est rendu
    await Future.delayed(const Duration(milliseconds: 500));

    // Lancer le tutorial avec les 3 onglets + 4 éléments du dashboard
    await TutorialService().showSportDashboardTutorial(
      context: context,
      caloriesKey: _caloriesCardKey,
      sessionsKey: _sessionsCardKey,
      splitKey: _splitCardKey,
      quickActionsKey: _quickActionsKey,
      dashboardTabKey: dashboardTabKey,
      cardioTabKey: cardioTabKey,
      musculationTabKey: musculationTabKey,
      languageCode: languageCode,
    );

    // Marquer comme complété
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sport_dashboard_tutorial_completed', true);
    }
    debugPrint('✅ Tutorial Dashboard Sport terminé');
  }

  /// Force le rafraîchissement des données
  void refreshDashboard() {
    _loadDashboardData();
  }

  /// NOUVEAU: Chargement synchrone instantané depuis GlobalStateManager
  void _loadInitialDataSync() {
    final globalState = GlobalStateManager.instance;

    // Créer des données de base depuis GlobalStateManager pour affichage immédiat
    final basicData = SportDashboardData(
      totalCalories: 0, // Sera enrichi par _loadDashboardData
      totalSessions: globalState.workoutCompleted ? 1 : 0,
      totalDurationMinutes: 0,
      cardioCalories: 0,
      musculationCalories: 0,
      targetWeeklyCalories: 2500,
      totalTodaySessions: globalState.workoutCompleted ? 1 : 0,
      recentSessions: [],
      streak: globalState.currentStreak,
    );

    setState(() {
      _dashboardData = basicData;
      animatedCalories = 0;
    });

    // Démarrer l'animation des calories (partira de 0)
    _startCaloriesAnimation();

    debugPrint('⚡ Sport Dashboard chargé INSTANTANÉMENT depuis GlobalStateManager');
  }

  /// Charge les données du dashboard depuis Supabase (enrichissement en arrière-plan)
  Future<void> _loadDashboardData() async {
    try {
      // OPTIMISATION: Utiliser le cache (5 min) pour chargement instantané
      // L'invalidation se fait uniquement lors du refresh manuel ou après workout

      final data = await SportDashboardService.getDashboardData();
      setState(() {
        _dashboardData = data;
      });

      // Redémarrer l'animation des calories avec les nouvelles données
      _startCaloriesAnimation();

      debugPrint('✅ Sport Dashboard enrichi depuis Supabase (avec cache)');
    } catch (e) {
      debugPrint('❌ Erreur chargement dashboard: $e');
      // En cas d'erreur, on garde les données de GlobalStateManager
    }
  }

  void _startCaloriesAnimation() {
    if (_dashboardData == null) return;

    // OPTIMISATION: Annuler l'animation précédente
    _caloriesTimer?.cancel();

    // Animation des calories - 1000ms avec easeOutExpo
    const duration = 1000; // 1 seconde
    const tickTime = 20; // 20ms

    final startValue = animatedCalories; // Commencer depuis la valeur actuelle
    final targetValue = _dashboardData!.totalCalories;
    final delta = targetValue - startValue;

    _caloriesTimer = Timer.periodic(const Duration(milliseconds: tickTime), (timer) {
      final elapsed = timer.tick * tickTime;
      final progress = (elapsed / duration).clamp(0.0, 1.0);
      final easedProgress = Curves.easeOutExpo.transform(progress);
      final currentValue = (startValue + (delta * easedProgress)).round();

      if (mounted) {
        setState(() => animatedCalories = currentValue);
      }

      if (progress >= 1.0) {
        timer.cancel();
        if (mounted) {
          setState(() => animatedCalories = targetValue);
        }
      }
    });
    _timers.add(_caloriesTimer!);
  }





  @override
  void dispose() {
    for (var timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCaloriesWithUnit(int calories) {
    final caloriesText = calories.toString();
    
    // Calculer la taille de police dynamiquement selon la longueur du nombre
    double fontSize = 32;
    if (caloriesText.length >= 5) {
      fontSize = 22; // Très grands nombres (5+ chiffres)
    } else if (caloriesText.length >= 4) {
      fontSize = 26; // Grands nombres (4 chiffres)
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caloriesText,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 3),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            'kcal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showCalendar) {
      return SportCalendarView(
        onBack: () => setState(() => showCalendar = false),
      );
    }

    return Consumer<LocalizationService>(
      builder: (context, locService, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Bloc calories (objectif / brûlées / progression)
            // OPTIMISATION: Affichage immédiat sans condition de loading
            if (_dashboardData != null)
              Container(
                key: _caloriesCardKey, // GlobalKey pour tutorial
                child: _buildWeeklyCalories(_dashboardData!, locService),
              ),

            const SizedBox(height: 16),

            // 2. Bloc "Progression" (ex-Résumé de la semaine)
            Container(
              key: _sessionsCardKey, // GlobalKey pour tutorial
              child: _buildWeeklySummary(locService),
            ),

            const SizedBox(height: 16),

            // 3. Bloc "Activité du jour"
            _buildDailyActivities(locService),

            const SizedBox(height: 16),

            // 4. Bloc "Séances récentes"
            _buildRecentWorkouts(locService),

            const SizedBox(height: 16),

            // 5. Bloc "Démarrer une activité"
            Container(
              key: _quickActionsKey, // GlobalKey pour tutorial
              child: _buildQuickStart(locService),
            ),
            
            // Padding bottom pour éviter la coupure
            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildWeeklyCalories(SportDashboardData data, LocalizationService locService) {
    // Calculs pour les nouveaux KPIs
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1 = Lundi, 7 = Dimanche
    final dailyAverage = dayOfWeek > 0 ? (data.totalCalories / dayOfWeek).round() : 0;
    
    final completedChunks = (data.totalCalories / 500).floor();
    final remainder = data.totalCalories % 500;
    final kcalToNext = remainder == 0 ? (data.totalCalories == 0 ? 500 : 0) : 500 - remainder;

    return CustomCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Cercle principal avec compteur (même style qu'avant)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Effet de flou en arrière-plan
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B132B).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Cercle principal
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCaloriesWithUnit(animatedCalories),
                          const SizedBox(height: 4),
                          Text(
                            'sport_burned'.tr(locService.currentLanguageCode),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Statistiques en 3 colonnes avec alignement parfait
              Row(
                children: [
                  // KPI gauche
                  Expanded(
                    child: _buildCaloriesStat('sport_average_per_day'.tr(locService.currentLanguageCode), dailyAverage, const Color(0xFF0B132B)),
                  ),
                  // KPI central (aligné avec le cercle)
                  Expanded(
                    child: _buildCaloriesStat('sport_milestones_reached'.tr(locService.currentLanguageCode), completedChunks, const Color(0xFF1C2951)),
                  ),
                  // KPI droite
                  Expanded(
                    child: _buildCaloriesStat('sport_sessions'.tr(locService.currentLanguageCode), data.totalSessions, const Color(0xFF888888)),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barre de progression par paliers (même taille et position)
              Container(
                width: double.infinity,
                height: 12,
                child: ChunkedProgressBar(
                  currentKcal: data.totalCalories,
                  chunkSize: 500,
                  height: 12,
                  borderRadius: 6,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Texte sous la barre (même style)
              Text(
                kcalToNext > 0 
                    ? 'sport_kcal_to_next_milestone'.tr(locService.currentLanguageCode).replaceAll('{kcal}', kcalToNext.toString())
                    : 'sport_milestone_reached'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesStat(String label, int value, Color color) {
    return Column(
      children: [
        // Container avec hauteur fixe pour aligner les valeurs
        SizedBox(
          height: 32, // Hauteur fixe pour 2 lignes de texte
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Permet 2 lignes maximum
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }



  Widget _buildRecentWorkouts(LocalizationService locService) {
    if (_dashboardData == null) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    LucideIcons.activity,
                    size: 20,
                    color: Color(0xFF0B132B),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Séances récentes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    // Récupérer les données des séances récentes depuis le cache
    final recentWorkouts = SportDashboardService.getCachedRecentWorkouts();
    final recentDays = recentWorkouts['recentDays'] as List<dynamic>? ?? [];

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.activity,
                      size: 20,
                      color: Color(0xFF0B132B),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'sport_recent_sessions'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _openSportCalendar,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.calendar,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Grille des 7 jours avec vraies données
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: recentDays.map<Widget>((day) {
                return Column(
                  children: [
                    Text(
                      day['date'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDashboardSportIcon(
                      day['activities'] != null 
                        ? List<String>.from(day['activities']) 
                        : <String>[],
                      cardioTypes: day['cardioTypes'] != null 
                        ? List<String>.from(day['cardioTypes'])
                        : <String>[],
                    ),
                  ],
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Légende format carré comme nutrition
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Musculation - Format carré comme nutrition
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
                        child: const Icon(
                          LucideIcons.dumbbell,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'sport_muscle_training'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 11,
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
                        width: 16,
                        height: 16,
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
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'sport_cardio'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 11,
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
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'sport_rest_day'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
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
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary(LocalizationService locService) {
    if (_dashboardData == null) {
      return const CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final data = _dashboardData!;
    
    // Formatage du temps total (en minutes -> heures et minutes)
    final totalMinutes = data.totalDurationMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final timeText = hours > 0 
        ? '${hours}h ${minutes}min'
        : '${minutes}min';

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'sport_progress'.tr(locService.currentLanguageCode),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          data.totalSessions.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                        Text(
                          'sport_sessions_this_week'.tr(locService.currentLanguageCode),
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.flame,
                              size: 16,
                              color: Color(0xFF0B132B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.streak.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B132B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'sport_consecutive_weeks'.tr(locService.currentLanguageCode),
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'sport_total_time_week'.tr(locService.currentLanguageCode),
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
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

  Widget _buildQuickStart(LocalizationService locService) {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': LucideIcons.activity,
        'label': 'sport_cardio'.tr(locService.currentLanguageCode),
        'colors': [const Color(0xFF0B132B).withOpacity(0.8), const Color(0xFF1C2951).withOpacity(0.8)]
      },
      {
        'icon': LucideIcons.dumbbell,
        'label': 'sport_muscle_training'.tr(locService.currentLanguageCode),
        'colors': [const Color(0xFF0B132B), const Color(0xFF1C2951)]
      },
    ];

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'sport_start_activity'.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: actions.map((action) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: action == actions.last ? 0 : 16,
                    ),
                    child: GestureDetector(
                      onTap: () => _showActivityBottomSheet(action['label']),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: action['colors'],
                                ),
                              ),
                              child: Icon(
                                action['icon'],
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              action['label'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyActivities(LocalizationService locService) {
    if (_dashboardData == null) {
    return CustomCard(
      key: _splitCardKey, // GlobalKey pour tutorial
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.trendingUp,
                  size: 16,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 8),
                Text(
                  'sport_todays_activities'.tr(locService.currentLanguageCode),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    // Récupérer les données du jour depuis SportDashboardService
    final dailyActivities = SportDashboardService.getCachedDailyActivities();
    final cardioSessions = dailyActivities['cardioSessions'] as List<dynamic>? ?? [];
    final musculationSessions = dailyActivities['musculationSessions'] as List<dynamic>? ?? [];
    
    // Si aucune activité aujourd'hui
    if (cardioSessions.isEmpty && musculationSessions.isEmpty) {
      return CustomCard(
        key: _splitCardKey, // GlobalKey pour tutorial
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                  Icon(
                    LucideIcons.trendingUp,
                    size: 16,
                    color: Color(0xFF0B132B),
                        ),
                        SizedBox(width: 8),
                        Text(
                    'Activités du jour',
                          style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),
              Text(
                'sport_no_activity_today'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 14,
                  color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
        ),
      );
    }

    return CustomCard(
      key: _splitCardKey, // GlobalKey pour tutorial
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.trendingUp,
                  size: 16,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 8),
                Text(
                  'sport_todays_activities'.tr(locService.currentLanguageCode),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Liste des activités
            Column(
              children: [
                // Séances musculation
                ...musculationSessions.map((session) => _buildActivityItem(
                  iconData: LucideIcons.dumbbell,
                  name: session['session_name'] ?? 'Musculation',
                  duration: _formatDuration(session['duration_minutes'] ?? 0),
                  calories: session['calories_burned'] ?? 0,
                )),
                
                // Séances cardio
                ...cardioSessions.map((session) => _buildActivityItem(
                  iconData: _getCardioIcon(session['activity_type'] ?? ''),
                  name: session['activity_title'] ?? 'Cardio',
                  duration: _formatDurationSeconds(session['duration_seconds'] ?? 0),
                  calories: session['calories'] ?? 0,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData iconData,
    required String name,
    required String duration,
    required int calories,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
                  children: [
          // Icône activité
          Icon(
            iconData,
            size: 20,
            color: const Color(0xFF0B132B),
          ),
          
          const SizedBox(width: 12),
          
          // Nom activité
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                    ),
          
          // Durée en gras
                        Text(
            duration,
            style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),
          
          // Séparateur
          const Text(
            ' · ',
                          style: TextStyle(
              fontSize: 14,
                            color: Color(0xFF888888),
                          ),
                        ),
          
          // Kcal en gris clair
          Text(
            '${calories} kcal',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
                  ),
                ),
              ],
      ),
    );
  }

  IconData _getCardioIcon(String activityType) {
    // Utilise toujours la même icône pour le cardio
    return LucideIcons.activity;
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h${remainingMinutes.toString().padLeft(2, '0')}';
      }
    }
  }

  String _formatDurationSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    return _formatDuration(minutes);
  }



  // Méthodes pour les bottom sheets des activités
  void _showActivityBottomSheet(String activityType) {
    if (activityType == 'Musculation') {
      WorkoutActions.showMusculationBottomSheet(context);
    } else if (activityType == 'Cardio') {
      _showCardioBottomSheet();
    }
  }

  void _openSportCalendar() {
    setState(() => showCalendar = true);
  }



  void _showCardioBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CardioSelectionBottomSheet(),
    );
  }







  void _showHIITOptions() {
    // Ici on peut implémenter les options HIIT ou aller directement au HIIT
    _startHIITSession();
  }

  void _startCardioSession(String cardioType) {
    // Déterminer le type d'activité et les paramètres
    String activityType;
    String activityTitle;
    
    switch (cardioType) {
      case 'Vélo':
        activityType = 'bike';
        activityTitle = 'Vélo';
        break;
      case 'Marche':
        activityType = 'walking';
        activityTitle = 'Marche';
        break;
      case 'Course':
        activityType = 'running';
        activityTitle = 'Course';
        break;
      default:
        activityType = 'running';
        activityTitle = cardioType;
    }
    
    // Afficher les options d'objectif pour l'activité sélectionnée
    _showCardioObjectiveOptions(activityType, activityTitle);
  }

  void _startHIITSession() {
    // Afficher les options HIIT prédéfinies
    _showHIITWorkoutOptions();
  }

  void _showCardioObjectiveOptions(String activityType, String activityTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                activityTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Choisissez votre objectif',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Options d'objectif
              Column(
                children: [
                  _buildObjectiveOption(
                    icon: LucideIcons.timer,
                    title: 'Séance libre',
                    subtitle: 'Pas d\'objectif spécifique',
                    onTap: () => _startCardioTracking(activityType, activityTitle, 'Séance libre', null),
                  ),
                  const SizedBox(height: 12),
                                     _buildObjectiveOption(
                     icon: LucideIcons.clock,
                     title: 'Objectif temps',
                     subtitle: '30 minutes',
                     onTap: () => _startCardioTracking(
                       activityType, 
                       activityTitle, 
                       'Objectif temps', 
                       CardioObjective(
                         type: 'duration',
                         activityType: activityType,
                         formatTitle: 'Objectif temps',
                         targetDuration: const Duration(minutes: 30),
                       ),
                     ),
                   ),
                   const SizedBox(height: 12),
                   _buildObjectiveOption(
                     icon: LucideIcons.mapPin,
                     title: 'Objectif distance',
                     subtitle: '5 km',
                     onTap: () => _startCardioTracking(
                       activityType, 
                       activityTitle, 
                       'Objectif distance', 
                       CardioObjective(
                         type: 'distance',
                         activityType: activityType,
                         formatTitle: 'Objectif distance',
                         targetDistance: 5.0,
                       ),
                     ),
                   ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
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
    );
  }

  void _startCardioTracking(String activityType, String activityTitle, String formatTitle, CardioObjective? objective) {
    Navigator.pop(context); // Fermer le bottom sheet
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardioTrackingScreen(
          activityType: activityType,
          activityTitle: activityTitle,
          formatTitle: formatTitle,
          objective: objective,
        ),
      ),
    );
  }

  void _showHIITWorkoutOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'HIIT',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Choisissez votre workout HIIT',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Liste des workouts HIIT prédéfinis
              Column(
                children: HiitWorkouts.predefinedWorkouts.map((workout) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildHIITWorkoutOption(workout),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHIITWorkoutOption(HiitWorkout workout) {
    return GestureDetector(
      onTap: () => _startHIITWorkout(workout),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.zap, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    workout.description,
                    style: const TextStyle(
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
    );
  }

  void _startHIITWorkout(HiitWorkout workout) {
    Navigator.pop(context); // Fermer le bottom sheet
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiitSessionScreen(
          workout: workout,
          isFromCustomConfig: false,
        ),
      ),
    );
  }

  Widget _buildDashboardSportIcon(List<String> activities, {List<String> cardioTypes = const []}) {
    const size = 32.0;
    
    if (activities.isEmpty) {
      // Jour de repos
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
      );
    } else if (activities.contains('musculation') && activities.contains('cardio')) {
      // Les deux activités - Icône combinée
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Partie musculation (haut-gauche)
            ClipPath(
              clipper: _UpperLeftClipper(),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF0B132B),
                ),
                child: const Align(
                  alignment: Alignment(-0.3, -0.3),
                  child: Icon(
                    LucideIcons.dumbbell,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Partie cardio (bas-droite)
            ClipPath(
              clipper: _LowerRightClipper(),
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
                child: Align(
                  alignment: const Alignment(0.3, 0.3),
                  child: Icon(
                    _getCardioIcon(cardioTypes.isNotEmpty ? cardioTypes.first : 'running'),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (activities.contains('musculation')) {
      // Musculation seulement
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            LucideIcons.dumbbell,
            size: 14,
            color: Colors.white,
          ),
        ),
      );
    } else if (activities.contains('cardio')) {
      // Cardio seulement
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _getCardioIcon(cardioTypes.isNotEmpty ? cardioTypes.first : 'running'),
            size: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(); // Fallback
  }
}

// Widget pour la sélection d'activités cardio (connecté à Supabase)
class _CardioSelectionBottomSheet extends StatefulWidget {
  @override
  State<_CardioSelectionBottomSheet> createState() => _CardioSelectionBottomSheetState();
}

class _CardioSelectionBottomSheetState extends State<_CardioSelectionBottomSheet> {
  List<CardioActivityType> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await CardioService.getCardioActivities(language: LocalizationService.instance.currentLanguageCode);
      setState(() {
        _activities = activities;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Cardio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Choisissez votre activité cardio',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_activities.isEmpty)
              const Center(
                child: Text(
                  'Aucune activité disponible',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: _activities.map((activity) {
                  return _buildCardioOption(
                    icon: _getIconFromName(activity.iconName),
                    title: activity.name,
                    onTap: () => _handleCardioSelection(activity.activityKey, activity.name),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Convertit le nom d'icône en IconData
  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'activity':
        return LucideIcons.activity;
      case 'bike':
        return LucideIcons.bike;
      case 'footprints':
        return LucideIcons.footprints;
      case 'flame':
        return LucideIcons.flame;
      default:
        return LucideIcons.activity;
    }
  }

  Widget _buildCardioOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0B132B).withOpacity(0.8), 
                    const Color(0xFF1C2951).withOpacity(0.8)
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleCardioSelection(String activityKey, String activityTitle) {
    Navigator.pop(context);
    // Naviguer vers la section cardio avec l'activité sélectionnée
    _navigateToCardioSection(activityKey, activityTitle);
  }

  void _navigateToCardioSection(String activityKey, String activityTitle) {
    // Utiliser la même logique que dans sport_cardio_hybrid.dart
    _showActivityFormatsModal(activityKey, activityTitle);
  }

  void _showActivityFormatsModal(String activityType, String activityTitle) {
    // Importer la logique depuis sport_cardio_hybrid.dart
    final formats = _getActivityFormats(activityType);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivityFormatsModal(
        activityTitle: activityTitle,
        activityType: activityType,
        formats: formats,
      ),
    );
  }

  List<ActivityFormat> _getActivityFormats(String activityType) {
    final locService = LocalizationService.instance;
    return CardioData.getLocalizedActivityFormats(locService.currentLanguageCode)[activityType] ?? [];
  }
}

// Widget pour afficher les formats d'activité cardio
class _ActivityFormatsModal extends StatelessWidget {
  final String activityTitle;
  final String activityType;
  final List<ActivityFormat> formats;

  const _ActivityFormatsModal({
    required this.activityTitle,
    required this.activityType,
    required this.formats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              activityTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Choisissez votre format',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Liste des formats
            ...formats.map((format) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFormatOption(
                context,
                icon: format.icon,
                title: format.title,
                description: format.description,
                onTap: () => _handleFormatSelection(context, format),
              ),
            )).toList(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
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
                    description,
                    style: const TextStyle(
                      fontSize: 14,
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

  void _handleFormatSelection(BuildContext context, ActivityFormat format) {
    Navigator.pop(context);
    
    // Gestion spéciale pour HIIT
    if (activityType == 'hiit') {
      _handleHiitSelection(context, format);
    } else if (format.configurable) {
      _showConfigurationModal(context, format);
    } else {
      _showRecordingChoiceModal(context, format);
    }
  }

  void _handleHiitSelection(BuildContext context, ActivityFormat format) {
    if (format.configurable && format.configType == 'hiit') {
      // HIIT personnalisé - pour l'instant, on lance un HIIT par défaut
      _startHiitWorkout(context, 'beginner');
    } else {
      // HIIT prédéfini
      String workoutType;
      switch (format.title) {
        case 'HIIT débutant':
          workoutType = 'beginner';
          break;
        case 'HIIT intense':
          workoutType = 'intense';
          break;
        case 'Tabata':
          workoutType = 'tabata';
          break;
        default:
          workoutType = 'beginner';
      }
      _startHiitWorkout(context, workoutType);
    }
  }

  void _startHiitWorkout(BuildContext context, String workoutType) {
    HiitWorkout workout;
    
    switch (workoutType) {
      case 'beginner':
        workout = const HiitWorkout(
          id: 'hiit_beginner',
          title: 'HIIT débutant',
          description: '15 min - 30s effort / 30s repos',
          workDuration: 30,
          restDuration: 30,
          totalDuration: 15,
          totalRounds: 15,
        );
        break;
      case 'intense':
        workout = const HiitWorkout(
          id: 'hiit_intense',
          title: 'HIIT intense',
          description: '20 min - 45s effort / 15s repos',
          workDuration: 45,
          restDuration: 15,
          totalDuration: 20,
          totalRounds: 20,
        );
        break;
      case 'tabata':
        workout = const HiitWorkout(
          id: 'tabata',
          title: 'Tabata',
          description: '4 min - 20s effort / 10s repos',
          workDuration: 20,
          restDuration: 10,
          totalDuration: 4,
          totalRounds: 8,
        );
        break;
      default:
        workout = const HiitWorkout(
          id: 'hiit_beginner',
          title: 'HIIT débutant',
          description: '15 min - 30s effort / 30s repos',
          workDuration: 30,
          restDuration: 30,
          totalDuration: 15,
          totalRounds: 15,
        );
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiitSessionScreen(workout: workout),
      ),
    );
  }

  void _showConfigurationModal(BuildContext context, ActivityFormat format) {
    // Pour l'instant, on lance directement avec des valeurs par défaut
    if (format.configType == 'distance') {
      _startTracking(context, format.title, targetDistance: 5.0);
    } else if (format.configType == 'duration') {
      _startTracking(context, format.title, targetDurationMinutes: 30);
    }
  }

  void _showRecordingChoiceModal(BuildContext context, ActivityFormat format) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                format.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton Tracker
              if (format.trackable)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startTracking(context, format.title);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'cardio_track_my_session'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              
              if (format.trackable)
                const SizedBox(height: 12),
              
              // Bouton Déclarer
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openManualEntry(context, format.title);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0B132B)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      'cardio_declare_my_session'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _startTracking(BuildContext context, String formatTitle, {double? targetDistance, int? targetDurationMinutes}) {
    CardioObjective? objective;
    
    if (targetDistance != null) {
      objective = CardioObjective(
        type: 'distance',
        targetDistance: targetDistance,
        activityType: activityType,
        formatTitle: formatTitle,
      );
    } else if (targetDurationMinutes != null) {
      objective = CardioObjective(
        type: 'duration',
        targetDuration: Duration(minutes: targetDurationMinutes),
        activityType: activityType,
        formatTitle: formatTitle,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardioTrackingScreen(
          activityType: activityType,
          activityTitle: activityTitle,
          formatTitle: formatTitle,
          objective: objective,
        ),
      ),
    );
  }

  void _openManualEntry(BuildContext context, String formatTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualCardioEntryScreen(
          activityType: activityType,
          activityTitle: activityTitle,
          formatTitle: formatTitle,
        ),
      ),
    );
  }
}

// Clippers pour les icônes combinées dans le dashboard
class _UpperLeftClipper extends CustomClipper<Path> {
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

class _LowerRightClipper extends CustomClipper<Path> {
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
