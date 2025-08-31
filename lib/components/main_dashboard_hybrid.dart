import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import 'dart:math';
import 'ui/dashboard_models.dart';
import 'ui/custom_card.dart';
import 'ui/custom_button.dart';
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
              
              // Header compact et focalisé
              CompactDashboardHeader(
                profile: userProfile!.copyWith(todayScore: animatedScore),
                onPremiumTap: _onPremiumTap,
              ),
              
              const SizedBox(height: 20),
              
              // Résumé quotidien avec tendances
              DailyOverviewCard(
                profile: userProfile!,
                goals: dailyGoals.isNotEmpty ? dailyGoals : DashboardData.dailyGoals,
              ),
              
              const SizedBox(height: 20),
              
              // Actions essentielles uniquement (4 max)
              EssentialActionsSection(
                actions: DashboardData.getEssentialActions(userProfile!),
              ),
              
              const SizedBox(height: 20),
              
              // Progrès détaillé et motivationnel
              DetailedProgressSection(
                goals: dailyGoals.isNotEmpty ? dailyGoals : DashboardData.dailyGoals,
                profile: userProfile!,
              ),
              
              const SizedBox(height: 20),
              
              // Insights personnalisés et conseils IA
              PersonalizedInsightsSection(
                profile: userProfile!,
                isPremium: userProfile!.isPremium,
                onUpgrade: _onPremiumUpgrade,
                onViewAnalytics: _onViewAnalytics,
              ),
              
              const SizedBox(height: 20),
              
              // Motivation et streak (placement optimal)
              MotivationSection(
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

  // Event handlers - gardés intégrés pour la logique spécifique
  void _onPremiumTap() {
    if (userProfile != null) {
    setState(() {
        userProfile = userProfile!.copyWith(isPremium: true);
    });
    }
  }

  void _onPremiumUpgrade() {
    if (userProfile != null) {
    setState(() {
        userProfile = userProfile!.copyWith(isPremium: true);
    });
    }
    
    // TODO: Intégrer avec la logique de paiement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bienvenue dans Ryze Premium ! 🎉')),
    );
  }


  void _onViewAnalytics() {
    // TODO: Ouvrir les analytics avancés
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouverture des analytics avancés')),
    );
  }
}

// Header compact remplaçant l'ancien header volumineux
class CompactDashboardHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onPremiumTap;

  const CompactDashboardHeader({
    super.key,
    required this.profile,
    this.onPremiumTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.greetingMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.flame, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '${profile.streak} jours',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      profile.xpText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Score circulaire compact
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profile.todayScore.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'pts',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!profile.isPremium) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onPremiumTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.crown, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Résumé quotidien avec KPI essentiels
class DailyOverviewCard extends StatelessWidget {
  final UserProfile profile;
  final List<DailyGoal> goals;

  const DailyOverviewCard({
    super.key,
    required this.profile,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    final completedGoals = goals.where((g) => g.completed).length;
    final caloriesProgress = profile.caloriesProgress.clamp(0.0, 1.0);
    final remainingCalories = profile.remainingCalories;
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aujourd\'hui en un coup d\'œil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            
            // Métriques principales en grille 2x2
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: LucideIcons.target,
                    title: 'Objectifs',
                    value: '$completedGoals/${goals.length}',
                    subtitle: completedGoals >= 3 ? 'Excellent !' : 'En cours',
                    color: completedGoals >= 3 ? const Color(0xFF22C55E) : const Color(0xFF0B132B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    icon: LucideIcons.flame,
                    title: 'Calories',
                    value: '${profile.currentCalories}',
                    subtitle: remainingCalories > 0 ? '-$remainingCalories kcal' : 'Objectif atteint',
                    color: const Color(0xFF0B132B),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// Actions essentielles (4 maximum)
class EssentialActionsSection extends StatelessWidget {
  final List<QuickAction> actions;

  const EssentialActionsSection({
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
            Row(
              children: actions.take(4).map((action) => 
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: actions.indexOf(action) < 3 ? 12 : 0,
                    ),
                    child: _buildEssentialAction(context, action),
                  ),
                )
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssentialAction(BuildContext context, QuickAction action) {
    return GestureDetector(
      onTap: () => _handleEssentialAction(context, action),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: action.isDisabled 
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
          color: action.isDisabled ? const Color(0xFFF1F5F9) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              action.icon,
              size: 24,
              color: action.isDisabled ? const Color(0xFF64748B) : Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: action.isDisabled ? const Color(0xFF64748B) : Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleEssentialAction(BuildContext context, QuickAction action) {
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
    }
  }
}

// Progrès détaillé avec tendances
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

// Insights personnalisés
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
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.03),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? LucideIcons.sparkles : LucideIcons.lightbulb,
                  size: 20,
                  color: const Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                Text(
                  isPremium ? 'Conseils personnalisés' : 'Conseil du jour',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                if (isPremium)
                  CustomBadge(
                    text: 'IA',
                    backgroundColor: const Color(0xFF0B132B).withOpacity(0.1),
                    textColor: const Color(0xFF0B132B),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPremium 
                    ? _getPremiumInsight(profile)
                    : _getBasicInsight(profile),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (isPremium)
              CustomButton(
                text: 'Voir analytics détaillés',
                icon: Icon(LucideIcons.trendingUp, size: 16, color: Colors.white),
                width: double.infinity,
                onPressed: onViewAnalytics,
              )
            else
              CustomButton(
                text: 'Débloquer Coach IA',
                icon: Icon(LucideIcons.crown, size: 16, color: Colors.white),
                width: double.infinity,
                onPressed: onUpgrade,
              ),
          ],
        ),
      ),
    );
  }

  String _getPremiumInsight(UserProfile profile) {
    final caloriesProgress = (profile.caloriesProgress * 100).round();
    if (caloriesProgress < 50) {
      return '🎯 Vous êtes en dessous de vos objectifs caloriques. Je recommande une collation riche en protéines vers 16h pour optimiser votre métabolisme.';
    } else if (caloriesProgress > 110) {
      return '⚡ Excellent ! Vous dépassez vos objectifs. Pensez à augmenter votre activité physique pour maintenir l\'équilibre.';
    } else {
      return '✨ Progression parfaite ! Votre rythme alimentaire est optimal. Continuez ainsi pour atteindre vos objectifs.';
    }
  }

  String _getBasicInsight(UserProfile profile) {
    final hour = DateTime.now().hour;
    if (hour < 10) {
      return '🌅 Bon matin ! Un petit-déjeuner riche en protéines vous donnera l\'énergie nécessaire pour la journée.';
    } else if (hour < 16) {
      return '☀️ Pensez à vous hydrater régulièrement et à prendre une pause active de 5 minutes.';
    } else {
      return '🌆 Le soir approche, privilégiez un dîner léger pour bien récupérer cette nuit.';
    }
  }
}

// Section motivation finale
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
    final isGreatDay = completedGoals >= totalGoals * 0.75;
    
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isGreatDay 
                ? [const Color(0xFF22C55E).withOpacity(0.05), Colors.transparent]
                : [const Color(0xFF0B132B).withOpacity(0.05), Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isGreatDay ? const Color(0xFF22C55E) : const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isGreatDay ? LucideIcons.trophy : LucideIcons.target,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGreatDay 
                        ? 'Journée exceptionnelle !'
                        : 'Continuez vos efforts !',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isGreatDay ? const Color(0xFF22C55E) : const Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isGreatDay
                        ? 'Vous excellez dans vos habitudes, gardez cette énergie !'
                        : 'Chaque petit pas compte, vous êtes sur la bonne voie.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Streak badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.flame, size: 16, color: Color(0xFF0B132B)),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.streak}',
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
