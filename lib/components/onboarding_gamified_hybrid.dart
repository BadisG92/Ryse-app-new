import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'ui/custom_button.dart';
import 'ui/onboarding_widgets.dart';
import 'ui/onboarding_models.dart';

class OnboardingGamifiedHybrid extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingGamifiedHybrid({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingGamifiedHybrid> createState() => _OnboardingGamifiedHybridState();
}

class _OnboardingGamifiedHybridState extends State<OnboardingGamifiedHybrid> 
    with TickerProviderStateMixin {
  int currentStep = 0;
  bool isLoading = false;
  bool showResults = false;
  
  // User data - INTÉGRÉ (état complexe, tight coupling)
  Map<String, dynamic> userData = {
    'gender': '',
    'age': '',
    'weight': '',
    'height': '',
    'activity': '',
    'goal': '',
    'obstacles': <String>[],
    'restrictions': <String>[],
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // INTÉGRÉ - Logique de chargement spécifique
  Timer? _loadingTextTimer;
  int _loadingTextIndex = 0;
  final List<String> _loadingMessages = [
    'Analyse de vos besoins nutritionnels...',
    'Prise en compte de votre niveau d\'activité...',
    'Calcul de votre métabolisme de base...',
    'Ajustement selon votre objectif principal...',
    'Personnalisation de vos apports en macronutriments...',
    'Vérification de vos préférences et restrictions...',
    'Votre plan est presque prêt !'
  ];
  String _currentLoadingMessage = 'Préparation de votre coaching personnalisé...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _currentLoadingMessage = _loadingMessages[0];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingTextTimer?.cancel();
    super.dispose();
  }

  // INTÉGRÉ - Logique de navigation spécifique
  void _startLoadingAnimation() {
    _loadingTextIndex = 0;
    _currentLoadingMessage = _loadingMessages[0];
    _loadingTextTimer?.cancel();
    _loadingTextTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _loadingTextIndex = (_loadingTextIndex + 1) % _loadingMessages.length;
          _currentLoadingMessage = _loadingMessages[_loadingTextIndex];
        });
      }
      if (_loadingTextIndex == _loadingMessages.length - 1) {
        timer.cancel();
      }
    });
  }

  // FACTORISÉ - Utilisations des modèles pour les calculs
  UserProfile get userProfile => UserProfile.fromMap(userData);

  List<Map<String, dynamic>> get steps => [
    {
      'title': 'Bienvenue dans Ryze IA',
      'subtitle': 'Votre coach nutrition personnalisé',
      'content': const WelcomeStep(), // FACTORISÉ
    },
    {
      'title': 'Parlez-nous de vous',
      'subtitle': 'Pour calculer vos besoins précis',
      'content': _buildPersonalInfoStep(), // HYBRIDE
    },
    {
      'title': 'Votre niveau d\'activité',
      'subtitle': 'Pour ajuster vos besoins énergétiques',
      'content': _buildActivityStep(), // INTÉGRÉ
    },
    {
      'title': 'Votre objectif',
      'subtitle': 'Pour personnaliser votre plan',
      'content': _buildGoalStep(), // INTÉGRÉ
    },
    {
      'title': 'Qu\'est-ce qui t\'empêche de garder une routine ?',
      'subtitle': 'Identifions tes défis pour mieux t\'accompagner',
      'content': _buildObstaclesStep(), // INTÉGRÉ
    },
    {
      'title': 'Vos restrictions alimentaires',
      'subtitle': 'Pour adapter votre plan nutrition',
      'content': _buildRestrictionsStep(), // INTÉGRÉ
    },
  ];

  // HYBRIDE - Utilise widgets factorisés avec logique intégrée
  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gender selection - Utilise SelectableCard factorisé
        const Text(
          'Genre',
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
              child: SelectableCard(
                title: 'Homme',
                icon: LucideIcons.user,
                isSelected: userData['gender'] == 'Homme',
                onTap: () => setState(() => userData['gender'] = 'Homme'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableCard(
                title: 'Femme',
                icon: LucideIcons.user,
                isSelected: userData['gender'] == 'Femme',
                onTap: () => setState(() => userData['gender'] = 'Femme'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Inputs numériques - Utilise MobileNumberInput factorisé
        MobileNumberInput(
          label: 'Âge',
          unit: 'années',
          value: userData['age'],
          onChanged: (value) => setState(() => userData['age'] = value),
          icon: LucideIcons.cake,
        ),
        
        const SizedBox(height: 20),
        
        MobileNumberInput(
          label: 'Poids',
          unit: 'kg',
          value: userData['weight'],
          onChanged: (value) => setState(() => userData['weight'] = value),
          icon: LucideIcons.scale,
        ),
        
        const SizedBox(height: 20),
        
        MobileNumberInput(
          label: 'Taille',
          unit: 'cm',
          value: userData['height'],
          onChanged: (value) => setState(() => userData['height'] = value),
          icon: LucideIcons.ruler,
        ),
      ],
    );
  }

  // INTÉGRÉ - Logique spécifique pour les activités
  Widget _buildActivityStep() {
    final activities = [
      {
        'key': 'sedentary',
        'title': 'Sédentaire',
        'description': 'Peu ou pas d\'exercice',
        'icon': LucideIcons.home,
      },
      {
        'key': 'light',
        'title': 'Activité légère',
        'description': '1-3 jours par semaine',
        'icon': LucideIcons.walk,
      },
      {
        'key': 'moderate',
        'title': 'Modérément actif',
        'description': '3-5 jours par semaine',
        'icon': LucideIcons.bike,
      },
      {
        'key': 'very',
        'title': 'Très actif',
        'description': '6-7 jours par semaine',
        'icon': LucideIcons.dumbbell,
      },
      {
        'key': 'extra',
        'title': 'Extrêmement actif',
        'description': 'Sport intense quotidien',
        'icon': LucideIcons.flame,
      },
    ];

    return Column(
      children: activities.map((activity) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableCard(
            title: activity['title'] as String,
            description: activity['description'] as String,
            icon: activity['icon'] as IconData,
            isSelected: userData['activity'] == activity['key'],
            onTap: () => setState(() => userData['activity'] = activity['key']),
          ),
        ),
      ).toList(),
    );
  }

  // INTÉGRÉ - Logique spécifique pour les objectifs
  Widget _buildGoalStep() {
    final goals = [
      {
        'key': 'lose',
        'title': 'Perdre du poids',
        'description': 'Déficit calorique contrôlé',
        'icon': LucideIcons.trendingDown,
      },
      {
        'key': 'maintain',
        'title': 'Maintenir mon poids',
        'description': 'Équilibre énergétique',
        'icon': LucideIcons.target,
      },
      {
        'key': 'gain',
        'title': 'Prendre du poids',
        'description': 'Surplus calorique maîtrisé',
        'icon': LucideIcons.trendingUp,
      },
    ];

    return Column(
      children: goals.map((goal) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableCard(
            title: goal['title'] as String,
            description: goal['description'] as String,
            icon: goal['icon'] as IconData,
            isSelected: userData['goal'] == goal['key'],
            onTap: () => setState(() => userData['goal'] = goal['key']),
          ),
        ),
      ).toList(),
    );
  }

  // INTÉGRÉ - Logique multi-sélection pour obstacles
  Widget _buildObstaclesStep() {
    final obstacles = [
      'Manque de temps',
      'Manque de motivation',
      'Environnement social',
      'Stress',
      'Fatigue',
      'Coût',
      'Manque de connaissances',
      'Autres priorités',
    ];

    return Column(
      children: obstacles.map((obstacle) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableCard(
            title: obstacle,
            isSelected: (userData['obstacles'] as List<String>).contains(obstacle),
            onTap: () {
              setState(() {
                final currentObstacles = userData['obstacles'] as List<String>;
                if (currentObstacles.contains(obstacle)) {
                  currentObstacles.remove(obstacle);
                } else {
                  currentObstacles.add(obstacle);
                }
              });
            },
          ),
        ),
      ).toList(),
    );
  }

  // INTÉGRÉ - Logique multi-sélection pour restrictions
  Widget _buildRestrictionsStep() {
    final restrictions = [
      'Végétarien',
      'Végétalien',
      'Sans gluten',
      'Sans lactose',
      'Halal',
      'Casher',
      'Allergies alimentaires',
      'Autres restrictions',
    ];

    return Column(
      children: restrictions.map((restriction) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableCard(
            title: restriction,
            isSelected: (userData['restrictions'] as List<String>).contains(restriction),
            onTap: () {
              setState(() {
                final currentRestrictions = userData['restrictions'] as List<String>;
                if (currentRestrictions.contains(restriction)) {
                  currentRestrictions.remove(restriction);
                } else {
                  currentRestrictions.add(restriction);
                }
              });
            },
          ),
        ),
      ).toList(),
    );
  }

  // INTÉGRÉ - Logique de validation spécifique
  bool canProceed() {
    switch (currentStep) {
      case 0:
        return true; // Welcome step
      case 1:
        return userData['gender'].isNotEmpty &&
               userData['age'].isNotEmpty &&
               userData['weight'].isNotEmpty &&
               userData['height'].isNotEmpty;
      case 2:
        return userData['activity'].isNotEmpty;
      case 3:
        return userData['goal'].isNotEmpty;
      case 4:
        return true; // Obstacles are optional
      case 5:
        return true; // Restrictions are optional
      default:
        return false;
    }
  }

  // INTÉGRÉ - Navigation et workflow spécifique
  void nextStep() {
    if (currentStep < steps.length - 1) {
      setState(() {
        currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      // Dernière étape - démarrer le chargement
      setState(() {
        isLoading = true;
      });
      _startLoadingAnimation();
      
      // Simuler le traitement
      Timer(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            isLoading = false;
            showResults = true;
          });
        }
      });
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = UserProfile.fromMap(userData);
    
    // Utilise les calculs factorisés
    final calories = MetabolicCalculations.calculateDailyGoal(profile);
    final macros = MetabolicCalculations.calculateMacros(profile);
    
    await prefs.setInt('daily_calories', calories);
    await prefs.setInt('daily_protein', macros['protein']!);
    await prefs.setInt('daily_carbs', macros['carbs']!);
    await prefs.setInt('daily_fat', macros['fat']!);
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  Widget build(BuildContext context) {
    if (showResults) {
      return _buildResultsScreen(); // HYBRIDE
    }

    if (isLoading) {
      return Scaffold(
        body: LoadingStep(currentMessage: _currentLoadingMessage), // FACTORISÉ
      );
    }

    return _buildStepScreen(); // INTÉGRÉ
  }

  // INTÉGRÉ - Logique de navigation complexe
  Widget _buildStepScreen() {
    final currentStepData = steps[currentStep];
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: currentStep > 0
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    currentStep--;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
              )
            : null,
        title: Text(
          'Étape ${currentStep + 1} sur ${steps.length}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentStepData['title'] as String,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B132B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentStepData['subtitle'] as String,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnimation,
              child: currentStepData['content'] as Widget,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: CustomButton(
          text: currentStep == steps.length - 1 ? 'Créer mon plan personnalisé' : 'Continuer',
          onPressed: canProceed() ? nextStep : null,
          icon: currentStep == steps.length - 1 
            ? const Icon(LucideIcons.checkCircle, color: Colors.white) 
            : const Icon(LucideIcons.arrowRight, color: Colors.white),
          isPrimary: canProceed(),
          isDisabled: !canProceed(),
        ),
      ),
    );
  }

  // HYBRIDE - Utilise widgets factorisés + calculs modélisés
  Widget _buildResultsScreen() {
    final profile = UserProfile.fromMap(userData);
    final calories = MetabolicCalculations.calculateDailyGoal(profile);
    final macros = MetabolicCalculations.calculateMacros(profile);
    final bmr = MetabolicCalculations.calculateBMR(profile);
    final totalNeeds = MetabolicCalculations.calculateTotalNeeds(profile);

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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header engageant
                Container(
                  width: double.infinity,
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.target, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            '$calories',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'kcal/jour',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Votre objectif calorique quotidien',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Macros - Utilise composants factorisés
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Répartition des macronutriments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      MacroRow(label: 'Protéines', value: '${macros['protein']}g', color: const Color(0xFF0B132B)),
                      const SizedBox(height: 16),
                      MacroRow(label: 'Glucides', value: '${macros['carbs']}g', color: const Color(0xFF1C2951)),
                      const SizedBox(height: 16),
                      MacroRow(label: 'Lipides', value: '${macros['fat']}g', color: const Color(0xFF64748B)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Détails métaboliques - Utilise composants factorisés
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Détails de vos besoins',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      DetailRow(label: 'Métabolisme de base', value: '${bmr.round()} kcal'),
                      const SizedBox(height: 12),
                      DetailRow(label: 'Besoins totaux', value: '${totalNeeds.round()} kcal'),
                      const SizedBox(height: 12),
                      DetailRow(label: 'Objectif quotidien', value: '$calories kcal', isHighlight: true),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton final
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B132B).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await _saveUserData();
                        widget.onComplete();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.trophy,
                            size: 24,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Commencer mon parcours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 