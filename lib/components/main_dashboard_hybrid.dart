import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import 'dart:math';
import 'ui/dashboard_models.dart';
import 'ui/custom_card.dart';
import 'ui/custom_badge.dart';
import '../services/dashboard_service.dart';

class MainDashboardHybrid extends StatefulWidget {
  const MainDashboardHybrid({super.key});

  @override
  State<MainDashboardHybrid> createState() => _MainDashboardHybridState();
}

class _MainDashboardHybridState extends State<MainDashboardHybrid>
    with TickerProviderStateMixin {
  
  // State variables
  UserProfile? userProfile;
  List<DailyGoal> dailyGoals = [];
  List<ModulePreview> modulePreviews = [];
  late AnimationController _scoreAnimationController;
  late Timer _scoreTimer;
  int animatedScore = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    _scoreTimer.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _startScoreAnimation() {
    final targetScore = userProfile?.todayScore ?? 85;
    _scoreTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (animatedScore < targetScore) {
        setState(() {
          animatedScore = min(animatedScore + 1, targetScore);
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Charger toutes les données en parallèle
      final futures = await Future.wait([
        DashboardService.getUserProfile(),
        DashboardService.getDailyGoals(),
        DashboardService.getModulePreviews(),
      ]);

      final loadedProfile = futures[0] as UserProfile?;
      final loadedGoals = futures[1] as List<DailyGoal>;
      final loadedPreviews = futures[2] as List<ModulePreview>;

      setState(() {
        userProfile = loadedProfile;
        dailyGoals = loadedGoals;
        modulePreviews = loadedPreviews;
        isLoading = false;
      });

      // Démarrer l'animation du score après chargement
      if (userProfile != null) {
        _startScoreAnimation();
      }

      // Charger aussi les données d'onboarding si nécessaire
      await _loadOnboardingData();
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        isLoading = false;
        // Utiliser les données par défaut en cas d'erreur
        userProfile = DashboardData.userProfile;
        dailyGoals = DashboardData.dailyGoals;
        modulePreviews = DashboardData.modulePreviews;
      });
    }
  }

  Future<void> _loadOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Récupérer les données de l'onboarding si disponibles
    final gender = prefs.getString('gender') ?? '';
    final age = prefs.getInt('age') ?? 0;
    final weight = prefs.getDouble('weight') ?? 0;
    final height = prefs.getDouble('height') ?? 0;
    final activity = prefs.getString('activity') ?? '';
    final goal = prefs.getString('goal') ?? '';
    
    // Recalculer les calories si les données sont disponibles et si le profil n'est pas encore chargé
    if (userProfile != null && gender.isNotEmpty && age > 0 && weight > 0 && height > 0 && activity.isNotEmpty) {
      final calculatedCalories = MetabolicCalculator.calculateDailyGoal(
        gender, age, weight, height, activity, goal
      );
      
      if (calculatedCalories > 0 && calculatedCalories != userProfile!.dailyCalories) {
        setState(() {
          userProfile = UserProfile(
            name: userProfile!.name,
            streak: userProfile!.streak,
            todayScore: userProfile!.todayScore,
            todayXP: userProfile!.todayXP,
            isPremium: userProfile!.isPremium,
            photosUsed: userProfile!.photosUsed,
            dailyCalories: calculatedCalories,
            currentCalories: userProfile!.currentCalories,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0B132B),
              ),
            )
          : userProfile == null
            ? const Center(
                child: Text(
                  'Erreur lors du chargement du profil',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshDashboardData,
                color: const Color(0xFF0B132B),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          child: Column(
            children: [
              const SizedBox(height: 40), // Safe area
              
              // Header gamifié dynamique
              GamifiedDashboardHeader(
                profile: userProfile!.copyWith(todayScore: animatedScore),
              ),
              
              const SizedBox(height: 16),
              
              // Vue d'ensemble Nutrition + Sport
              NutritionSportOverview(
                profile: userProfile!,
                goals: dailyGoals.isNotEmpty ? dailyGoals : DashboardData.dailyGoals,
              ),
              
              const SizedBox(height: 16),
              
              // Actions rapides gamifiées (5 actions avec pesée)
              GamifiedActionsSection(
                actions: DashboardData.getGamifiedActions(userProfile!),
              ),
              
              const SizedBox(height: 16),
              
              // Progression compacte mais engageante (comme l'ancien)
              CompactProgressSection(
                goals: dailyGoals.isNotEmpty ? dailyGoals : DashboardData.dailyGoals,
                profile: userProfile!,
              ),
              
              const SizedBox(height: 16),
              
              // Coach intégré + motivation
              IntegratedCoachSection(
                profile: userProfile!,
                completedGoals: dailyGoals.where((g) => g.completed).length,
                totalGoals: dailyGoals.length,
              ),
              
              const SizedBox(height: 16),
              
              // Badge de réussite du jour
              DailyAchievementBadge(
                profile: userProfile!,
                completedGoals: dailyGoals.where((g) => g.completed).length,
                totalGoals: dailyGoals.length,
              ),
            ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Actualiser les données du dashboard
  Future<void> _refreshDashboardData() async {
    await _loadDashboardData();
  }

  // Event handlers simplifiés - plus de Premium à gérer


}

// Header gamifié et dynamique
class GamifiedDashboardHeader extends StatelessWidget {
  final UserProfile profile;

  const GamifiedDashboardHeader({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer l'état du jour pour les couleurs dynamiques
    final isGreatDay = profile.todayScore >= 80;
    final streakColor = profile.streak >= 7 ? const Color(0xFFFFD700) : Colors.white;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isGreatDay 
              ? [const Color(0xFF0B132B), const Color(0xFF1C2951), const Color(0xFF2D4A6B)]
              : [const Color(0xFF0B132B), const Color(0xFF1C2951)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Salutation + Score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.greetingMessage,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGreatDay ? 'Journée exceptionnelle ! ✨' : 'C\'est parti pour une belle journée !',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Score circulaire animé
              Container(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    // Background circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),
                    // Score
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profile.todayScore.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'points',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bottom row: Streak + XP avec style gamifié
          Row(
            children: [
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: streakColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.flame, size: 16, color: streakColor),
                    const SizedBox(width: 6),
                    Text(
                      '${profile.streak} jours',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: streakColor,
                      ),
                    ),
                    if (profile.streak >= 7) ...[
                      const SizedBox(width: 4),
                      Text(
                        '🔥',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              
              const Spacer(),
              
              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '+${profile.todayXP} XP',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Vue d'ensemble Nutrition + Sport
class NutritionSportOverview extends StatelessWidget {
  final UserProfile profile;
  final List<DailyGoal> goals;

  const NutritionSportOverview({
    super.key,
    required this.profile,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    final completedGoals = goals.where((g) => g.completed).length;
    final caloriesProgress = profile.caloriesProgress.clamp(0.0, 1.0);
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition & Sport aujourd\'hui',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            
            // Métriques principales en grille 2x2 (Nutrition + Sport)
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: LucideIcons.utensils,
                    title: 'Nutrition',
                    value: '${profile.currentCalories}',
                    subtitle: '/${profile.dailyCalories} kcal',
                    color: const Color(0xFF0B132B),
                    progress: caloriesProgress,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    icon: LucideIcons.dumbbell,
                    title: 'Sport',
                    value: '342', // TODO: Vraies données sport
                    subtitle: 'kcal brûlées',
                    color: const Color(0xFF0B132B),
                    progress: 0.6, // TODO: Vrai progrès sport
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: LucideIcons.droplets,
                    title: 'Hydratation',
                    value: '1.2L', // TODO: Vraies données
                    subtitle: '/2.0L',
                    color: const Color(0xFF0B132B),
                    progress: 0.6,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    icon: LucideIcons.target,
                    title: 'Objectifs',
                    value: '$completedGoals/${goals.length}',
                    subtitle: completedGoals >= 3 ? 'Top ! 🔥' : 'En cours',
                    color: completedGoals >= 3 ? const Color(0xFF22C55E) : const Color(0xFF0B132B),
                    progress: completedGoals / goals.length,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Barre de progression calories avec style nutrition
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0B132B).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progression calorique',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '${(caloriesProgress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: caloriesProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
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

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    double? progress,
  }) {
    final hasProgress = progress != null;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (hasProgress) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Actions rapides gamifiées (5 actions avec pesée)
class GamifiedActionsSection extends StatelessWidget {
  final List<QuickAction> actions;

  const GamifiedActionsSection({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            // Grille 2x3 pour 5 actions uniformes
            Column(
              children: [
                // Première ligne : 3 actions
                Row(
                  children: actions.take(3).map((action) => 
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: actions.indexOf(action) < 2 ? 8 : 0,
                        ),
                        child: _buildGamifiedAction(context, action),
                      ),
                    )
                  ).toList(),
                ),
                const SizedBox(height: 8),
                // Deuxième ligne : 2 actions centrées
                Row(
                  children: [
                    Expanded(flex: 1, child: Container()),
                    ...actions.skip(3).take(2).map((action) => 
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: actions.indexOf(action) < actions.length - 1 ? 8 : 0,
                          ),
                          child: _buildGamifiedAction(context, action),
                        ),
                      )
                    ).toList(),
                    Expanded(flex: 1, child: Container()),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamifiedAction(BuildContext context, QuickAction action) {
    return GestureDetector(
      onTap: () => _handleGamifiedAction(context, action),
      child: Container(
        height: 80, // Taille fixe pour uniformité
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: action.isDisabled 
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: action.isDisabled ? const Color(0xFFF1F5F9) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: action.isDisabled ? null : [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              size: 24,
              color: action.isDisabled ? const Color(0xFF64748B) : Colors.white,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                action.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: action.isDisabled ? const Color(0xFF64748B) : Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGamifiedAction(BuildContext context, QuickAction action) {
    if (action.isDisabled || action.isPremiumRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité disponible avec Premium'),
          backgroundColor: Color(0xFF0B132B),
        ),
      );
      return;
    }

    switch (action.id) {
      case 'add_meal':
        // TODO: Ouvrir sélection de repas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajout de repas'),
            backgroundColor: Color(0xFF0B132B),
          ),
        );
        break;
      case 'add_water':
        // TODO: Ouvrir ajout d'eau
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajout d\'hydratation'),
            backgroundColor: Color(0xFF0B132B),
          ),
        );
        break;
      case 'take_photo':
        // TODO: Ouvrir scanner IA
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scanner d\'aliments'),
            backgroundColor: Color(0xFF0B132B),
          ),
        );
        break;
      case 'workout':
        // TODO: Ouvrir sélection d'entraînement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Démarrage d\'entraînement'),
            backgroundColor: Color(0xFF0B132B),
          ),
        );
        break;
      case 'weight_tracking':
        // TODO: Ouvrir saisie de poids
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement du poids'),
            backgroundColor: Color(0xFF0B132B),
          ),
        );
        break;
    }
  }
}

// Progression compacte mais engageante (style ancien amélioré)
class CompactProgressSection extends StatelessWidget {
  final List<DailyGoal> goals;
  final UserProfile profile;

  const CompactProgressSection({
    super.key,
    required this.goals,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final completedGoals = goals.where((g) => g.completed).length;
    final totalGoals = goals.length;
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header avec progression globale
            Row(
              children: [
                Icon(
                  LucideIcons.target,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Objectifs du jour',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: completedGoals >= 3 
                        ? const Color(0xFF22C55E).withOpacity(0.1)
                        : const Color(0xFF0B132B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedGoals/$totalGoals',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: completedGoals >= 3 
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF0B132B),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Liste compacte des objectifs
            ...goals.map((goal) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCompactGoalItem(goal),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactGoalItem(DailyGoal goal) {
    final isCompleted = goal.completed;
    
    return Row(
      children: [
        // Icône de statut
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isCompleted 
                ? const Color(0xFF22C55E)
                : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: isCompleted 
              ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
              : null,
        ),
        
        const SizedBox(width: 12),
        
        // Texte de l'objectif
        Expanded(
          child: Text(
            goal.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isCompleted 
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF64748B),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        
        // Badge XP ou progression
        if (isCompleted)
          CustomBadge(
            text: '+${goal.xp} XP',
            backgroundColor: const Color(0xFF22C55E).withOpacity(0.1),
            textColor: const Color(0xFF22C55E),
          )
        else
          Text(
            goal.progressText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
      ],
    );
  }
}

// Coach intégré (sans Premium)
class IntegratedCoachSection extends StatelessWidget {
  final UserProfile profile;
  final int completedGoals;
  final int totalGoals;

  const IntegratedCoachSection({
    super.key,
    required this.profile,
    required this.completedGoals,
    required this.totalGoals,
  });

  @override
  Widget build(BuildContext context) {
    final coachMessage = _getCoachMessage(profile, completedGoals, totalGoals);
    final coachEmoji = _getCoachEmoji(completedGoals, totalGoals);
    
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.03),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar du coach avec animation
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  coachEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Message du coach
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coach Ryze',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coachMessage,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.3,
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

  String _getCoachMessage(UserProfile profile, int completed, int total) {
    final completionRate = completed / total;
    final hour = DateTime.now().hour;
    
    if (completionRate >= 0.75) {
      return "Excellent ! Tu es sur une lancée fantastique aujourd'hui. Continue comme ça ! 🔥";
    } else if (completionRate >= 0.5) {
      return "Bon rythme ! Tu es à mi-parcours de tes objectifs. Encore un petit effort !";
    } else if (hour < 12) {
      return "La journée commence bien ! Prends un bon petit-déjeuner pour avoir de l'énergie.";
    } else if (hour < 17) {
      return "C'est le moment parfait pour se remettre sur les rails. Que dirais-tu d'une pause active ?";
    } else {
      return "Pas de stress ! Même les petites actions comptent. Demain sera un nouveau jour !";
    }
  }

  String _getCoachEmoji(int completed, int total) {
    final completionRate = completed / total;
    if (completionRate >= 0.75) return "🏆";
    if (completionRate >= 0.5) return "💪";
    if (completionRate >= 0.25) return "👍";
    return "🎯";
  }
}

// Badge de réussite du jour
class DailyAchievementBadge extends StatelessWidget {
  final UserProfile profile;
  final int completedGoals;
  final int totalGoals;

  const DailyAchievementBadge({
    super.key,
    required this.profile,
    required this.completedGoals,
    required this.totalGoals,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = _getTodayAchievement(profile, completedGoals, totalGoals);
    if (achievement == null) return Container();
    
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              achievement['color'].withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: achievement['color'].withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Badge d'achievement
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: achievement['color'],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: achievement['color'].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  achievement['emoji'],
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Texte d'achievement
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: achievement['color'],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bonus XP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: achievement['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${achievement['xp']} XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: achievement['color'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getTodayAchievement(UserProfile profile, int completed, int total) {
    final completionRate = completed / total;
    final streak = profile.streak;
    final caloriesProgress = profile.caloriesProgress;
    
    // Achievement parfait
    if (completed == total) {
      return {
        'title': 'Jour Parfait !',
        'description': 'Tous les objectifs atteints !',
        'emoji': '🏆',
        'color': const Color(0xFFFFD700),
        'xp': 100,
      };
    }
    
    // Achievement streak
    if (streak >= 7 && completionRate >= 0.75) {
      return {
        'title': 'Série de Feu !',
        'description': '$streak jours consécutifs !',
        'emoji': '🔥',
        'color': const Color(0xFFFF6B35),
        'xp': 75,
      };
    }
    
    // Achievement calories
    if (caloriesProgress >= 0.9 && caloriesProgress <= 1.1) {
      return {
        'title': 'Équilibre Parfait',
        'description': 'Objectif calorique maîtrisé !',
        'emoji': '⚖️',
        'color': const Color(0xFF22C55E),
        'xp': 50,
      };
    }
    
    // Achievement progression
    if (completionRate >= 0.75) {
      return {
        'title': 'Belle Progression !',
        'description': 'Tu es sur la bonne voie !',
        'emoji': '💪',
        'color': const Color(0xFF0B132B),
        'xp': 25,
      };
    }
    
    return null;
  }
}

// Section détaillée supprimée - remplacée par CompactProgressSection
class DetailedProgressSection extends StatelessWidget {
  final List<DailyGoal> goals;
  final UserProfile profile;

  const DetailedProgressSection({
    super.key,
    required this.goals,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Progression détaillée',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...goals.map((goal) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDetailedGoalItem(goal),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedGoalItem(DailyGoal goal) {
    final isCompleted = goal.completed;
    final progress = goal.progressPercent;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted 
            ? const Color(0xFF22C55E).withOpacity(0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? const Color(0xFF22C55E).withOpacity(0.2)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? LucideIcons.check : LucideIcons.target,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.progressText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                CustomBadge(
                  text: '+${goal.xp} XP',
                  backgroundColor: const Color(0xFF22C55E).withOpacity(0.1),
                  textColor: const Color(0xFF22C55E),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Section détaillée supprimée car remplacée par CompactProgressSection
// Cette classe est conservée pour éviter les erreurs de compilation
class PersonalizedInsightsSection extends StatelessWidget {
  final UserProfile profile;
  final bool isPremium;
  final VoidCallback? onUpgrade;
  final VoidCallback? onViewAnalytics;

  const PersonalizedInsightsSection({
    super.key,
    required this.profile,
    required this.isPremium,
    this.onUpgrade,
    this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    // Section supprimée - fonctionnalité intégrée dans IntegratedCoachSection
    return Container();
  }

}

// Section motivation supprimée car remplacée par IntegratedCoachSection et DailyAchievementBadge
// Cette classe est conservée pour éviter les erreurs de compilation
class MotivationSection extends StatelessWidget {
  final UserProfile profile;
  final int completedGoals;
  final int totalGoals;

  const MotivationSection({
    super.key,
    required this.profile,
    required this.completedGoals,
    required this.totalGoals,
  });

  @override
  Widget build(BuildContext context) {
    // Section supprimée - fonctionnalité intégrée dans IntegratedCoachSection et DailyAchievementBadge
    return Container();
  }
}

// Extension pour faciliter la copie du UserProfile
extension UserProfileCopyWith on UserProfile {
  UserProfile copyWith({
    String? name,
    int? streak,
    int? todayScore,
    int? todayXP,
    bool? isPremium,
    int? photosUsed,
    int? dailyCalories,
    int? currentCalories,
  }) {
    return UserProfile(
      name: name ?? this.name,
      streak: streak ?? this.streak,
      todayScore: todayScore ?? this.todayScore,
      todayXP: todayXP ?? this.todayXP,
      isPremium: isPremium ?? this.isPremium,
      photosUsed: photosUsed ?? this.photosUsed,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      currentCalories: currentCalories ?? this.currentCalories,
    );
  }
} 
