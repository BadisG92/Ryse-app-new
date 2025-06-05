import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/custom_card.dart';
import 'ui/sport_dashboard_models.dart';
import 'ui/sport_dashboard_widgets.dart';

class SportDashboard extends StatefulWidget {
  const SportDashboard({super.key});

  @override
  State<SportDashboard> createState() => _SportDashboardState();
}

class _SportDashboardState extends State<SportDashboard>
    with TickerProviderStateMixin {
  
  // Contrôleurs d'animation
  late AnimationController _caloriesController;
  late Animation<int> _caloriesAnimation;
  
  // État du profil sport
  SportProfile _profile = SportDashboardData.profile;
  
  @override
  void initState() {
    super.initState();
    
    // Animation des calories principales
    _caloriesController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _caloriesAnimation = IntTween(
      begin: 0,
      end: _profile.weeklyCalories,
    ).animate(CurvedAnimation(
      parent: _caloriesController,
      curve: Curves.easeOutCubic,
    ));
    
    // Démarrer les animations
    _caloriesController.forward();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _caloriesAnimation,
        builder: (context, child) {
          return _buildBody();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Sport',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // En-tête avec statut et calories principales
          SportSectionBuilder.buildCaloriesSection(
            _profile,
            _caloriesAnimation.value,
          ),
          
          const SizedBox(height: 16),
          
          // Activités quotidiennes
          SportSectionBuilder.buildActivitiesSection(
            SportDashboardData.dailyActivities,
          ),
          
          const SizedBox(height: 16),
          
          // Séances récentes avec calendrier
          SportSectionBuilder.buildRecentSection(
            SportDashboardData.recentWorkouts,
            SportDashboardData.activityDays,
          ),
          
          const SizedBox(height: 16),
          
          // Progression hebdomadaire
          SportSectionBuilder.buildProgressSection(_profile),
          
          const SizedBox(height: 16),
          
          // Actions rapides sport
          SportSectionBuilder.buildQuickActionsSection(
            SportDashboardData.quickActions,
          ),
          
          const SizedBox(height: 16),
          
          // Accès au calendrier complet
          SportSectionBuilder.buildCalendarSection(() {
            _navigateToCalendar();
          }),
          
          const SizedBox(height: 16),
          
          // Section de motivation avec streak
          SportMotivationSection(profile: _profile),
          
          // Espace en bas pour éviter que le contenu soit coupé
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Navigation vers le calendrier complet
  void _navigateToCalendar() {
    HapticFeedback.lightImpact();
    
    // TODO: Implémenter la navigation vers le calendrier sport
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCalendarBottomSheet(),
    );
  }

  // Bottom sheet du calendrier (garde l'intégration)
  Widget _buildCalendarBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle pour fermer
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // En-tête
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Calendrier des entraînements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          
          // Contenu du calendrier
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Calendrier placeholder
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 48,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Calendrier interactif',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'Voir l\'historique complet de vos entraînements',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Statistiques rapides
                  Row(
                    children: [
                      Expanded(
                        child: CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  '${_profile.weeklyWorkouts}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                                const Text(
                                  'Cette semaine',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  '${_profile.weeklyStreak}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                                const Text(
                                  'Sem. consécutives',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 