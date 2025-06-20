import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'ui/dashboard_models.dart';
import 'ui/dashboard_cards.dart';
import 'ui/dashboard_widgets.dart';
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
              
              // Header Gamifié avec charte graphique
              DashboardHeader(
                      profile: userProfile!.copyWith(todayScore: animatedScore),
                onPremiumTap: _onPremiumTap,
              ),
              
              const SizedBox(height: 16),
              
              // Quick Actions Gamifiées avec charte
              QuickActionsSection(
                      actions: DashboardData.getQuickActions(userProfile!),
              ),
              
              const SizedBox(height: 16),
              
                    // Progression Visuelle Addictive - Utilise les données dynamiques
              DailyGoalsSection(
                      goals: dailyGoals.isNotEmpty ? dailyGoals : DashboardData.dailyGoals,
                      isPremium: userProfile!.isPremium,
              ),
              
              const SizedBox(height: 16),
              
                    // Aperçu Nutrition & Sport - Utilise les données dynamiques
              ModulesPreviewSection(
                      modules: modulePreviews.isNotEmpty ? modulePreviews : DashboardData.modulePreviews,
                onModuleTap: _onModuleTap,
              ),
              
              const SizedBox(height: 16),
              
              // Social Proof & FOMO
              CommunityStatsSection(
                stats: DashboardData.communityStats,
              ),
              
              const SizedBox(height: 16),
              
              // CTA Premium ou Insights IA
                    if (userProfile!.isPremium)
                PremiumInsightsSection(
                  onViewAnalytics: _onViewAnalytics,
                )
              else
                PremiumCTASection(
                  onUpgrade: _onPremiumUpgrade,
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

  void _onModuleTap(String moduleTitle) {
    // TODO: Navigation vers les modules spécifiques
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigation vers $moduleTitle')),
    );
  }

  void _onViewAnalytics() {
    // TODO: Ouvrir les analytics avancés
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouverture des analytics avancés')),
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
