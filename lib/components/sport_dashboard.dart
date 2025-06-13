import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'ui/custom_card.dart';
import '../screens/cardio_tracking_screen.dart';
import '../screens/hiit_session_screen.dart';
import '../models/cardio_session_models.dart';
import '../models/hiit_models.dart';
import '../services/workout_service.dart';
import '../widgets/sport/sport_calendar_view.dart';
import 'shared/workout_actions.dart';

class SportDashboard extends StatefulWidget {
  const SportDashboard({super.key});

  @override
  State<SportDashboard> createState() => _SportDashboardState();
}

class _SportDashboardState extends State<SportDashboard>
    with TickerProviderStateMixin {
  bool showCalendar = false;
  int weeklyCalories = 0;
  int dailyStreak = 7; // Streak en jours pour le bandeau du haut
  int weeklyStreak = 3; // Streak en semaines pour le résumé
  late AnimationController _animationController;
  late Animation<int> _caloriesAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _caloriesAnimation = IntTween(
      begin: 0,
      end: 1260,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _caloriesAnimation.addListener(() {
      setState(() {
        weeklyCalories = _caloriesAnimation.value;
      });
    });

    // Démarrer l'animation après 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Données pour le calendrier compact (7 derniers jours)
  final List<Map<String, dynamic>> recentWorkouts = [
    {"date": "L", "hasWorkout": true, "activities": ["musculation"]},
    {"date": "M", "hasWorkout": false, "activities": []},
    {"date": "M", "hasWorkout": true, "activities": ["cardio"]},
    {"date": "J", "hasWorkout": true, "activities": ["musculation", "cardio"]}, // Jour combiné
    {"date": "V", "hasWorkout": false, "activities": []},
    {"date": "S", "hasWorkout": true, "activities": ["cardio"]},
    {"date": "D", "hasWorkout": false, "activities": []},
  ];

  @override
  Widget build(BuildContext context) {
    if (showCalendar) {
      return SportCalendarView(
        onBack: () => setState(() => showCalendar = false),
      );
    }

    const int targetWeeklyCalories = 2000;
    final int avgDailyCalories = (weeklyCalories / 7).round();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [            
            // 1. Bloc calories (objectif / brûlées / progression)
            _buildWeeklyCalories(targetWeeklyCalories, avgDailyCalories),
            
            const SizedBox(height: 16),
            
            // 2. Bloc "Activité du jour"
            _buildDailyActivities(),
            
            const SizedBox(height: 16),
            
            // 3. Bloc "Séances récentes"
            _buildRecentWorkouts(),
            
            const SizedBox(height: 16),
            
            // 4. Bloc "Résumé de la semaine"
            _buildWeeklySummary(),
            
            const SizedBox(height: 16),
            
            // 5. Bloc "Démarrer une activité"
            _buildQuickStart(),
            
            // Padding bottom pour éviter la coupure
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCalories(int targetWeeklyCalories, int avgDailyCalories) {
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
              // Cercle principal avec compteur animé
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
                          Text(
                            weeklyCalories.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'kcal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Statistiques en 3 colonnes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCaloriesStat('Kcal brûlées', weeklyCalories, const Color(0xFF0B132B)),
                  _buildCaloriesStat('Objectif hebdo', targetWeeklyCalories, const Color(0xFF1C2951)),
                  _buildCaloriesStat('Moyenne/jour', avgDailyCalories, const Color(0xFF888888)),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barre de progression principale
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (weeklyCalories / targetWeeklyCalories).clamp(0.0, 1.0),
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B132B)),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '${((weeklyCalories / targetWeeklyCalories) * 100).round()}% de l\'objectif hebdo atteint',
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
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
        ),
      ],
    );
  }

  Widget _buildRecentWorkouts() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                GestureDetector(
                  onTap: _openSportCalendar,
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
            
            // Grille des 7 jours
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: recentWorkouts.map((day) {
                return Column(
                  children: [
                    Text(
                      day['date'],
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
                        : <String>[]
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
                      const Flexible(
                        child: Text(
                          'Musculation',
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
                      const Flexible(
                        child: Text(
                          'Cardio',
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
                      const Flexible(
                        child: Text(
                          'Repos',
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
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progression',
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
                    child: const Column(
                      children: [
                        Text(
                          '4/5',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                        Text(
                          'Séances cette semaine',
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
                              weeklyStreak.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B132B),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Semaines consécutives',
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Temps total cette semaine',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '4h 35min',
                    style: TextStyle(
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

  Widget _buildQuickStart() {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': LucideIcons.dumbbell,
        'label': 'Musculation',
        'colors': [const Color(0xFF0B132B), const Color(0xFF1C2951)]
      },
      {
        'icon': LucideIcons.activity,
        'label': 'Cardio',
        'colors': [const Color(0xFF0B132B).withOpacity(0.8), const Color(0xFF1C2951).withOpacity(0.8)]
      },
    ];

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Démarrer une activité',
              style: TextStyle(
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

  Widget _buildDailyActivities() {
    return CustomCard(
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
            
            // Musculation
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: Color(0xFF0B132B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Musculation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          '1h 15min',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                        Text(
                          ' • 280 kcal',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B132B)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cardio
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: const Color(0xFF0B132B).withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Course',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          '20min',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                        Text(
                          ' • 62 kcal',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                      value: 0.75,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF0B132B).withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
              
              // Grille 2x2 avec les 4 options cardio
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCardioOption(
                          icon: LucideIcons.bike,
                          title: 'Vélo',
                          onTap: () => _handleCardioSelection('Vélo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCardioOption(
                          icon: LucideIcons.footprints,
                          title: 'Marche',
                          onTap: () => _handleCardioSelection('Marche'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCardioOption(
                          icon: LucideIcons.zap,
                          title: 'Course',
                          onTap: () => _handleCardioSelection('Course'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCardioOption(
                          icon: LucideIcons.timer,
                          title: 'HIIT',
                          onTap: () => _handleCardioSelection('HIIT'),
                        ),
                      ),
                    ],
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
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
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  // Méthodes de navigation pour cardio
  void _handleCardioSelection(String cardioType) {
    Navigator.pop(context); // Fermer le bottom sheet
    
    if (cardioType == 'HIIT') {
      _showHIITOptions();
    } else {
      // Pour les autres types de cardio, aller directement à l'écran de tracking
      _startCardioSession(cardioType);
    }
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

  Widget _buildDashboardSportIcon(List<String> activities) {
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
                child: const Align(
                  alignment: Alignment(0.3, 0.3),
                  child: Icon(
                    LucideIcons.activity,
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
        child: const Center(
          child: Icon(
            LucideIcons.activity,
            size: 14,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(); // Fallback
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
