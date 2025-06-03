import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'ui/custom_card.dart';
import 'ui/custom_button.dart';
import 'ui/custom_badge.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with TickerProviderStateMixin {
  int streak = 7;
  int todayScore = 0;
  bool isPremium = false;
  int photosUsed = 2;
  
  // Données de l'onboarding
  int dailyCalories = 2500;
  int currentCalories = 1247;
  
  late AnimationController _scoreAnimationController;
  late Timer _scoreTimer;

  @override
  void initState() {
    super.initState();
    _loadOnboardingData();
    _initializeAnimations();
    _startScoreAnimation();
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
    _scoreTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (todayScore < 85) {
        setState(() {
          todayScore = min(todayScore + 1, 85);
        });
      } else {
        timer.cancel();
      }
    });
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
    
    // Recalculer les calories si les données sont disponibles
    if (gender.isNotEmpty && age > 0 && weight > 0 && height > 0 && activity.isNotEmpty) {
      final calculatedCalories = _calculateDailyGoal(gender, age, weight, height, activity, goal);
      if (calculatedCalories > 0) {
        setState(() {
          dailyCalories = calculatedCalories;
        });
      }
    }
  }

  int _calculateDailyGoal(String gender, int age, double weight, double height, String activity, String goal) {
    // Calcul BMR (Mifflin-St Jeor)
    double bmr;
    if (gender == 'Homme') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // Facteur d'activité
    final activityFactors = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'very': 1.725,
      'extra': 1.9,
    };

    final tdee = bmr * (activityFactors[activity] ?? 1.2);

    // Ajustement selon l'objectif
    switch (goal) {
      case 'lose':
        return (tdee - 500).round();
      case 'lose_fast':
        return (tdee - 750).round();
      case 'maintain':
        return tdee.round();
      case 'gain':
        return (tdee + 300).round();
      default:
        return tdee.round();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          child: Column(
            children: [
              const SizedBox(height: 40), // Safe area
              
              // Header Gamifié avec charte graphique
              _buildHeader(),
              
              const SizedBox(height: 16),
              
              // Quick Actions Gamifiées avec charte
              _buildQuickActions(),
              
              const SizedBox(height: 16),
              
              // Progression Visuelle Addictive
              _buildDailyGoals(),
              
              const SizedBox(height: 16),
              
              // Aperçu Nutrition & Sport
              _buildNutritionSportPreview(),
              
              const SizedBox(height: 16),
              
              // Social Proof & FOMO
              _buildCommunityStats(),
              
              const SizedBox(height: 16),
              
              // CTA Premium ou Insights IA
              if (isPremium) _buildPremiumInsights() else _buildPremiumCTA(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B132B),
            Color(0xFF1C2951),
            Color(0xFF0B132B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern background
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: DotPatternPainter(),
              ),
            ),
          ),
          
          // Premium button
          if (!isPremium)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => setState(() => isPremium = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.crown, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Main content
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.flame, size: 24, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              streak.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'jours',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        CustomBadge(
                          text: 'Série en cours !',
                          backgroundColor: Colors.white.withOpacity(0.1),
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Greeting
                    const Text(
                      'Salut Rihab !',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    Text(
                      '+250 XP aujourd\'hui',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Score circulaire
              _buildCircularScore(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularScore() {
    return Container(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Background circle
          CustomPaint(
            size: const Size(80, 80),
            painter: CircularProgressPainter(
              progress: 0,
              strokeWidth: 6,
              backgroundColor: Colors.white.withOpacity(0.2),
              progressColor: Colors.transparent,
            ),
          ),
          // Progress circle
          CustomPaint(
            size: const Size(80, 80),
            painter: CircularProgressPainter(
              progress: todayScore / 100,
              strokeWidth: 6,
              backgroundColor: Colors.transparent,
              progressColor: Colors.white.withOpacity(0.9),
            ),
          ),
          // Score text
          Center(
            child: Text(
              todayScore.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return CustomCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions - Ligne horizontale scrollable - Hauteur et taille des boutons augmentées
          SizedBox(
            height: 150, // Hauteur augmentée pour des boutons plus grands
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: [
                // Scanner repas
                _buildActionButton(
                  label: 'Scanner un repas', // Libellé mis à jour
                  icon: (!isPremium && photosUsed >= 3) ? LucideIcons.lock : LucideIcons.camera,
                  isDisabled: !isPremium && photosUsed >= 3,
                  reward: (!isPremium && photosUsed >= 3) ? null : '+5',
                  isPremiumRequired: !isPremium && photosUsed >= 3,
                  onTap: () {
                    if (!isPremium && photosUsed < 3) {
                      setState(() => photosUsed++);
                    }
                  },
                ),
                
                const SizedBox(width: 16), // Espacement augmenté
                
                // Ajouter un plat
                _buildActionButton(
                  label: 'Ajouter un plat', // Libellé mis à jour
                  icon: LucideIcons.utensils, // Icône changée pour des couverts
                  reward: '+3',
                  onTap: () {},
                ),
                
                const SizedBox(width: 16), // Espacement augmenté
                
                // Faire du sport
                _buildActionButton(
                  label: 'Faire du sport', // Libellé mis à jour
                  icon: LucideIcons.dumbbell,
                  reward: '+10',
                  onTap: () {},
                ),
                
                const SizedBox(width: 16), // Espacement augmenté
                
                // Boire de l'eau
                _buildActionButton(
                  label: 'Boire de l\'eau', // Libellé mis à jour
                  icon: LucideIcons.droplets,
                  reward: '+2',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    bool isDisabled = false,
    String? reward,
    bool isPremiumRequired = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: SizedBox(
        width: 100, 
        height: 150, 
        child: Stack(
          clipBehavior: Clip.none, 
          children: [
            // Corps principal du bouton
            Container(
              margin: const EdgeInsets.only(top: 15), 
              width: double.infinity, 
              height: double.infinity, 
              decoration: BoxDecoration(
                gradient: isDisabled 
                    ? null 
                    : LinearGradient(
                        colors: [
                          const Color(0xFF0B132B).withOpacity(0.03),
                          const Color(0xFF1C2951).withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isDisabled ? const Color(0xFFE2E8F0) : Colors.white, 
                borderRadius: BorderRadius.circular(20), 
                boxShadow: isDisabled ? [] : [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0), 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    const SizedBox(height: 5), 
                    // Icône
                    Container(
                      width: 40, 
                      height: 40, 
                      decoration: BoxDecoration(
                        gradient: isDisabled 
                            ? null 
                            : const LinearGradient(
                                colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                              ),
                        color: isDisabled ? const Color(0xFFCBD5E1) : null,
                        borderRadius: BorderRadius.circular(12), 
                      ),
                      child: Icon(
                        icon,
                        size: 20, 
                        color: isDisabled ? const Color(0xFF64748B) : Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8), 
                    
                    // Texte
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(), 

                    // Indicateur Premium (si nécessaire)
                    if (isPremiumRequired)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0), 
                        child: CustomBadge(
                          text: 'Premium',
                          backgroundColor: const Color(0xFF0B132B).withOpacity(0.05),
                          textColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        ),
                      )
                    else
                      const SizedBox(height: 18), 
                  ],
                ),
              ),
            ),

            // Badge XP utilisant CustomBadge pour cohérence
            if (reward != null && !isDisabled)
              Positioned(
                top: 0,
                right: 8, // Ajusté pour CustomBadge
                child: CustomBadge(
                  text: '$reward XP',
                  backgroundColor: const Color(0xFFF0F0F0), // Fond gris clair solide
                  textColor: const Color(0xFF0B132B), // Texte bleu foncé (comme avant)
                  // Le CustomBadge a un padding par défaut, si besoin d'ajuster :
                  // padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoals() {
    final goals = [
      {'label': 'Prendre 3 repas', 'progress': 66, 'completed': false, 'xp': 20},
      {'label': 'Boire 2L d\'eau', 'progress': 100, 'completed': true, 'xp': 15},
      {'label': 'Scanner 1 repas', 'progress': 100, 'completed': true, 'xp': 25},
      {'label': 'Faire du sport', 'progress': 0, 'completed': false, 'xp': 30, 'premium': true},
    ];

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Objectifs du jour',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.trophy, size: 16, color: Color(0xFF0B132B)),
                    const SizedBox(width: 4),
                    const Text(
                      '2/4 complétés',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Goals list
            ...goals.map((goal) => _buildGoalItem(goal)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(Map<String, dynamic> goal) {
    final isCompleted = goal['completed'] as bool;
    final isPremiumGoal = goal['premium'] == true;
    final progress = goal['progress'] as int;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    goal['label'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (isPremiumGoal && !isPremium) ...[
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.crown, size: 12, color: Color(0xFF0B132B)),
                  ],
                ],
              ),
              Row(
                children: [
                  if (isCompleted)
                    CustomBadge(
                      text: '+${goal['xp']} XP',
                      backgroundColor: const Color(0xFF0B132B).withOpacity(0.1),
                      textColor: const Color(0xFF0B132B),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [const Color(0xFF0B132B), const Color(0xFF1C2951)]
                        : isPremiumGoal && !isPremium
                            ? [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]
                            : [const Color(0xFF0B132B).withOpacity(0.8), const Color(0xFF1C2951).withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSportPreview() {
    return Row(
      children: [
        // Nutrition card
        Expanded(
          child: CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: const Icon(LucideIcons.apple, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Nutrition',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildStatRow('Calories', '${currentCalories.toString()} kcal'),
                  const SizedBox(height: 4),
                  _buildStatRow('Eau', '1.2L'),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Sport card
        Expanded(
          child: CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0B132B).withOpacity(0.8), 
                              const Color(0xFF1C2951).withOpacity(0.8)
                            ],
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                        ),
                        child: const Icon(LucideIcons.dumbbell, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sport',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildStatRow('Calories', '342 kcal'),
                  const SizedBox(height: 4),
                  _buildStatRow('Séances', '1 / 3'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityStats() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(LucideIcons.users, size: 20, color: Color(0xFF0B132B)),
                const SizedBox(width: 12),
                const Text(
                  'Communauté',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildStatRow('Utilisateurs actifs aujourd\'hui', '12,847'),
            const SizedBox(height: 8),
            _buildStatRow('Objectifs atteints cette semaine', '89,234'),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Voir le classement',
              icon: const Icon(LucideIcons.trophy, size: 16, color: Colors.white),
              width: double.infinity,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCTA() {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0B132B).withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.crown, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Débloquez votre potentiel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Photos illimitées + Coach IA personnel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPremiumFeature('∞', 'Photos'),
                _buildPremiumFeature('24/7', 'Coach IA'),
                _buildPremiumFeature('0', 'Publicités'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Essayer 7 jours gratuits',
              icon: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
              width: double.infinity,
              onPressed: () => setState(() => isPremium = true),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Puis 15€/mois • Annulable à tout moment',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B132B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumInsights() {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach IA Personnel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                CustomBadge(
                  text: 'Premium',
                  backgroundColor: const Color(0xFF0B132B).withOpacity(0.1),
                  textColor: const Color(0xFF0B132B),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🎯 Analyse personnalisée : Votre métabolisme est optimal entre 14h-16h. C\'est le moment idéal pour votre collation protéinée !',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Voir mes analytics avancés',
              icon: const Icon(LucideIcons.trendingUp, size: 16, color: Colors.white),
              width: double.infinity,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    if (backgroundColor != Colors.transparent) {
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, backgroundPaint);
    }

    // Progress arc
    if (progressColor != Colors.transparent && progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for dot pattern
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x + 30, y + 30), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 