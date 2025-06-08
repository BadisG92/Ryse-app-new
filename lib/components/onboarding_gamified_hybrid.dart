import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'ui/custom_button.dart';
import 'ui/onboarding_widgets.dart';
import 'ui/onboarding_models.dart';
import 'caloric_breakdown_bottom_sheet.dart';

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
    'birthMonth': '',
    'birthDay': '',
    'birthYear': '',
    'isMetric': true,
    'activity': '',
    'goal': '',
    'obstacles': <String>[],
    'restrictions': <String>[],
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _caloriesAnimationController;
  late Animation<int> _caloriesAnimation;

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
    _caloriesAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Pré-remplir les valeurs par défaut
    _initializeDefaultValues();
    
    _animationController.forward();
    _currentLoadingMessage = _loadingMessages[0];
  }

  void _initializeDefaultValues() {
    // Valeurs par défaut pour la date de naissance (24 ans - né en 2000)
    userData['birthMonth'] = '1'; // Janvier
    userData['birthDay'] = '1'; // 1er
    userData['birthYear'] = '2000'; // 24 ans
    userData['age'] = '24';
    
    // Valeurs par défaut pour taille et poids (métrique par défaut)
    userData['height'] = '170'; // 170 cm
    userData['weight'] = '70'; // 70 kg
    userData['isMetric'] = true;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _caloriesAnimationController.dispose();
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
      'title': 'Choisissez votre genre',
      'subtitle': 'Cela sera utilisé pour calibrer votre plan personnalisé',
      'content': _buildGenderStep(), // NOUVEAU
    },
    {
      'title': 'Quand êtes-vous né',
      'subtitle': 'Cela sera utilisé pour calibrer votre plan personnalisé',
      'content': _buildBirthDateStep(), // NOUVEAU
    },
    {
      'title': 'Taille & poids',
      'subtitle': 'Cela sera utilisé pour calibrer votre plan personnalisé',
      'content': _buildHeightWeightStep(), // NOUVEAU
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

  // Page Genre - Style moderne comme dans les images
  Widget _buildGenderStep() {
    return Column(
      children: [
        const SizedBox(height: 80),
        
        // Option Homme
        _buildGenderOption(
          title: 'Homme',
          isSelected: userData['gender'] == 'Homme',
          onTap: () => setState(() => userData['gender'] = 'Homme'),
        ),
        
        const SizedBox(height: 16),
        
        // Option Femme
        _buildGenderOption(
          title: 'Femme',
          isSelected: userData['gender'] == 'Femme',
          onTap: () => setState(() => userData['gender'] = 'Femme'),
        ),
        
        const SizedBox(height: 16),
        
        // Option Autre
        _buildGenderOption(
          title: 'Autre',
          isSelected: userData['gender'] == 'Autre',
          onTap: () => setState(() => userData['gender'] = 'Autre'),
        ),
        
        const SizedBox(height: 80),
      ],
    );
  }

  // Widget pour options de genre
  Widget _buildGenderOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Page Date de naissance avec roues de sélection
  Widget _buildBirthDateStep() {
    return Column(
      children: [
        const SizedBox(height: 60),
        
        Container(
          height: 250,
          child: Row(
            children: [
              // Sélecteur de mois
              Expanded(
                child: _buildWheelPicker(
                  items: [
                    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
                    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
                  ],
                  selectedIndex: userData['birthMonth'].isNotEmpty 
                      ? int.parse(userData['birthMonth']) - 1 
                      : 0,
                  onSelectedItemChanged: (index) {
                    setState(() => userData['birthMonth'] = (index + 1).toString());
                  },
                ),
              ),
              
              // Sélecteur de jour
              Expanded(
                child: _buildWheelPicker(
                  items: List.generate(31, (index) => (index + 1).toString()),
                  selectedIndex: userData['birthDay'].isNotEmpty 
                      ? int.parse(userData['birthDay']) - 1 
                      : 0,
                  onSelectedItemChanged: (index) {
                    setState(() => userData['birthDay'] = (index + 1).toString());
                  },
                ),
              ),
              
              // Sélecteur d'année
              Expanded(
                child: _buildWheelPicker(
                  items: List.generate(100, (index) => (2024 - index).toString()),
                  selectedIndex: userData['birthYear'].isNotEmpty 
                      ? 2024 - int.parse(userData['birthYear']) 
                      : 24,
                  onSelectedItemChanged: (index) {
                    setState(() => userData['birthYear'] = (2024 - index).toString());
                    // Calculer l'âge
                    final age = 2024 - (2024 - index);
                    userData['age'] = age.toString();
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 60),
      ],
    );
  }

  // Page Taille & Poids avec toggle et roues
  Widget _buildHeightWeightStep() {
    return Column(
      children: [
        const SizedBox(height: 40),
        
        // Toggle Impérial/Métrique
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => userData['isMetric'] = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: userData['isMetric'] == false ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: userData['isMetric'] == false ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        'Impérial',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: userData['isMetric'] == false ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => userData['isMetric'] = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: userData['isMetric'] == true ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: userData['isMetric'] == true ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        'Métrique',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: userData['isMetric'] == true ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Sélecteurs de taille et poids
        Container(
          height: 200,
          child: Row(
            children: [
              // Sélecteur de taille
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Hauteur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _buildHeightPicker(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 40),
              
              // Sélecteur de poids
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Poids',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _buildWeightPicker(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 60),
      ],
    );
  }

  // Méthodes utilitaires pour les wheel pickers
  Widget _buildWheelPicker({
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    return CupertinoPicker(
      itemExtent: 40,
      scrollController: FixedExtentScrollController(initialItem: selectedIndex),
      onSelectedItemChanged: onSelectedItemChanged,
      children: items.map((item) => 
        Center(
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildHeightPicker() {
    final isMetric = userData['isMetric'] ?? true;
    final items = isMetric 
        ? List.generate(151, (index) => '${index + 100} cm')  // 100-250 cm
        : List.generate(48, (index) => '${(index + 48) ~/ 12}\'${(index + 48) % 12}"'); // 4'0" - 7'11"
    
    final currentHeight = userData['height'].isEmpty ? (isMetric ? '170' : '68') : userData['height'];
    final selectedIndex = isMetric 
        ? int.parse(currentHeight) - 100
        : int.parse(currentHeight) - 48;

    return _buildWheelPicker(
      items: items,
      selectedIndex: selectedIndex.clamp(0, items.length - 1),
      onSelectedItemChanged: (index) {
        final newHeight = isMetric 
            ? (index + 100).toString()
            : (index + 48).toString();
        setState(() => userData['height'] = newHeight);
      },
    );
  }

  Widget _buildWeightPicker() {
    final isMetric = userData['isMetric'] ?? true;
    final items = isMetric 
        ? List.generate(271, (index) => '${index + 30} kg')  // 30-300 kg
        : List.generate(440, (index) => '${index + 66} lbs'); // 66-505 lbs
    
    final currentWeight = userData['weight'].isEmpty ? (isMetric ? '70' : '154') : userData['weight'];
    final selectedIndex = isMetric 
        ? int.parse(currentWeight) - 30
        : int.parse(currentWeight) - 66;

    return _buildWheelPicker(
      items: items,
      selectedIndex: selectedIndex.clamp(0, items.length - 1),
      onSelectedItemChanged: (index) {
        final newWeight = isMetric 
            ? (index + 30).toString()
            : (index + 66).toString();
        setState(() => userData['weight'] = newWeight);
      },
    );
  }

  // INTÉGRÉ - Logique spécifique pour les activités
  Widget _buildActivityStep() {
    final activities = [
      {
        'key': 'low',
        'title': 'Peu actif',
        'description': '0-2 jours par semaine',
        'icon': LucideIcons.home,
      },
      {
        'key': 'moderate',
        'title': 'Modérément actif',
        'description': '3-5 jours par semaine',
        'icon': LucideIcons.bike,
      },
      {
        'key': 'high',
        'title': 'Très actif',
        'description': '6+ jours par semaine',
        'icon': LucideIcons.dumbbell,
      },
    ];

    return Column(
      children: [
        const SizedBox(height: 80),
        ...activities.map((activity) => 
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
        const SizedBox(height: 80),
      ],
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
      children: [
        const SizedBox(height: 80),
        ...goals.map((goal) => 
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
        const SizedBox(height: 80),
      ],
    );
  }

  // INTÉGRÉ - Logique multi-sélection pour obstacles
  Widget _buildObstaclesStep() {
    final obstacles = [
      'Manque de temps',
      'Manque de motivation',
      'Fatigue',
      'Manque de connaissances',
      'Autres priorités',
    ];

    return Column(
      children: [
        const SizedBox(height: 60),
        ...obstacles.map((obstacle) => 
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
        const SizedBox(height: 60),
      ],
    );
  }

  // INTÉGRÉ - Logique multi-sélection pour restrictions
  Widget _buildRestrictionsStep() {
    final restrictions = [
      'Classique',
      'Végétarien',
      'Végétalien',
      'Pescetarien',
    ];

    return Column(
      children: [
        const SizedBox(height: 100),
        ...restrictions.map((restriction) => 
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
        const SizedBox(height: 100),
      ],
    );
  }

  // INTÉGRÉ - Logique de validation spécifique
  bool canProceed() {
    switch (currentStep) {
      case 0:
        return true; // Welcome step
      case 1:
        return userData['gender'].isNotEmpty; // Genre
      case 2:
        return true; // Date de naissance - activé par défaut
      case 3:
        return true; // Taille & Poids - activé par défaut  
      case 4:
        return userData['activity'].isNotEmpty; // Activité
      case 5:
        return userData['goal'].isNotEmpty; // Objectif
      case 6:
        return true; // Obstacles are optional
      case 7:
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
          // Démarrer l'animation des calories
          _startCaloriesAnimation();
        }
      });
    }
  }

  void _startCaloriesAnimation() {
    final profile = UserProfile.fromMap(userData);
    final finalCalories = MetabolicCalculations.calculateDailyGoal(profile);
    
    _caloriesAnimation = IntTween(begin: 0, end: finalCalories).animate(
      CurvedAnimation(parent: _caloriesAnimationController, curve: Curves.easeOutCubic),
    );
    
    _caloriesAnimationController.forward();
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

  // HYBRIDE - Écran de résultats avec composants de l'app principale
  Widget _buildResultsScreen() {
    final profile = UserProfile.fromMap(userData);
    final bmr = MetabolicCalculations.calculateBMR(profile);
    final totalNeeds = MetabolicCalculations.calculateTotalNeeds(profile);
    final calories = MetabolicCalculations.calculateDailyGoal(profile);
    final macros = MetabolicCalculations.calculateMacros(profile);
    
    // Calcul des ajustements pour l'explication
    final activityMultiplier = _getActivityMultiplier(profile.activity);
    final goalAdjustment = _getGoalAdjustment(profile.goal);

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
                // En-tête de félicitations - Réduit
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B132B),
                        Color(0xFF1C2951),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B132B).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Félicitations !',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Votre plan est prêt',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Carte principale calories - Style de l'app
                _buildMainCaloriesCard(calories, bmr, totalNeeds, activityMultiplier, goalAdjustment),

                const SizedBox(height: 16),

                // Macronutriments - Style de l'app
                _buildMacronutrientsCard(macros),

                const SizedBox(height: 20),

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
                            LucideIcons.rocket,
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

  // Carte principale des calories - Style identique à l'app
  Widget _buildMainCaloriesCard(int calories, double bmr, double totalNeeds, double activityMultiplier, int goalAdjustment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B132B).withOpacity(0.05),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cercle principal avec animation (style app)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Effet de flou en arrière-plan
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B132B).withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
                // Cercle principal
                Container(
                  width: 85,
                  height: 85,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _caloriesAnimation,
                        builder: (context, child) {
                          return Text(
                            _caloriesAnimation.value.toString(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          );
                        },
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
          
          const Text(
            'Votre objectif quotidien',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Calculé spécialement pour vous',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showCaloricBreakdownBottomSheet(
                      context: context,
                      bmr: bmr,
                      activityFactor: activityMultiplier,
                      objectiveDelta: goalAdjustment.toDouble(),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.helpCircle,
                      color: Color(0xFF0B132B),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }




  // Macronutriments - Style de l'app (Compact)
  Widget _buildMacronutrientsCard(Map<String, int> macros) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: const Color(0xFF0B132B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.pieChart,
                  size: 16,
                  color: Color(0xFF0B132B),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Macronutriments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Protéines
          _buildAnimatedMacroRow(
            name: 'Protéines',
            value: macros['protein']!,
            unit: 'g',
            color: const Color(0xFF0B132B),
            icon: LucideIcons.zap,
          ),
          
          const SizedBox(height: 10),
          
          // Glucides
          _buildAnimatedMacroRow(
            name: 'Glucides',
            value: macros['carbs']!,
            unit: 'g',
            color: const Color(0xFF1C2951),
            icon: LucideIcons.wheat,
          ),
          
          const SizedBox(height: 10),
          
          // Lipides
          _buildAnimatedMacroRow(
            name: 'Lipides',
            value: macros['fat']!,
            unit: 'g',
            color: const Color(0xFF64748B),
            icon: LucideIcons.droplets,
          ),
        ],
      ),
    );
  }

  // Ligne de macro animée - Style app (Compact)
  Widget _buildAnimatedMacroRow({
    required String name,
    required int value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            Text(
              '$value$unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        // Barre de progression complète (100% pour l'onboarding)
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: 1.0, // Toujours pleine à l'onboarding
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  // Helpers pour les calculs
  double _getActivityMultiplier(String activity) {
    final multipliers = {
      'low': 1.2,      // 0-2 jours
      'moderate': 1.55, // 3-5 jours
      'high': 1.8,     // 6+ jours
    };
    return multipliers[activity] ?? 1.2;
  }

  int _getGoalAdjustment(String goal) {
    switch (goal) {
      case 'lose':
        return -500;
      case 'gain':
        return 300;
      case 'maintain':
      default:
        return 0;
    }
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case 'lose':
        return LucideIcons.trendingDown;
      case 'gain':
        return LucideIcons.trendingUp;
      case 'maintain':
      default:
        return LucideIcons.target;
    }
  }
} 