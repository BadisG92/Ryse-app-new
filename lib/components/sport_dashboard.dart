import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';

class SportDashboard extends StatefulWidget {
  const SportDashboard({super.key});

  @override
  State<SportDashboard> createState() => _SportDashboardState();
}

class _SportDashboardState extends State<SportDashboard>
    with TickerProviderStateMixin {
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
    {"date": "L", "hasWorkout": true, "type": "musculation"},
    {"date": "M", "hasWorkout": false, "type": null},
    {"date": "M", "hasWorkout": true, "type": "cardio"},
    {"date": "J", "hasWorkout": true, "type": "musculation"},
    {"date": "V", "hasWorkout": false, "type": null},
    {"date": "S", "hasWorkout": true, "type": "cardio"},
    {"date": "D", "hasWorkout": false, "type": null},
  ];

  @override
  Widget build(BuildContext context) {
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
            
            const SizedBox(height: 16),
            
            // 6. Bloc "Historique complet"
            _buildCalendarAccess(),
            
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
                      LucideIcons.calendar,
                      size: 16,
                      color: Color(0xFF0B132B),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Séances récentes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Ouvrir la page de calendrier des entraînements
                  },
                  icon: const Icon(LucideIcons.calendar),
                  iconSize: 18,
                  padding: const EdgeInsets.all(8),
                  color: const Color(0xFF64748B),
                  tooltip: 'Voir le calendrier',
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: day['hasWorkout']
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: day['type'] == 'musculation'
                                    ? [const Color(0xFF0B132B), const Color(0xFF1C2951)]
                                    : [const Color(0xFF0B132B).withOpacity(0.7), const Color(0xFF1C2951).withOpacity(0.7)],
                              )
                            : null,
                        color: day['hasWorkout'] ? null : const Color(0xFFF1F5F9),
                        border: day['hasWorkout'] ? null : Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: day['hasWorkout']
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0B132B).withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: day['hasWorkout']
                          ? Center(
                              child: Icon(
                                day['type'] == 'musculation' ? LucideIcons.dumbbell : LucideIcons.activity,
                                size: 14,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ],
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Légende
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: const Color(0xFF0B132B),
                      child: const Icon(LucideIcons.dumbbell, size: 8, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Musculation',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: const Color(0xFF1C2951),
                      child: const Icon(LucideIcons.activity, size: 8, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Cardio',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
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
                fontSize: 14,
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
                fontSize: 14,
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
                      onTap: () {},
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
                    fontSize: 14,
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

  Widget _buildCalendarAccess() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0B132B).withOpacity(0.1),
                    const Color(0xFF1C2951).withOpacity(0.1),
                  ],
                ),
              ),
              child: const Icon(
                LucideIcons.calendar,
                size: 20,
                color: Color(0xFF0B132B),
              ),
            ),
            
            const SizedBox(width: 12),
            
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique complet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'Voir tous vos entraînements',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF0B132B).withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: Color(0xFF0B132B),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Voir calendrier',
                      style: TextStyle(
                        fontSize: 12,
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
    );
  }
} 