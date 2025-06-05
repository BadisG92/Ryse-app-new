import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/custom_button.dart';
import 'dart:async';

class OnboardingGamified extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingGamified({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingGamified> createState() => _OnboardingGamifiedState();
}

class _OnboardingGamifiedState extends State<OnboardingGamified> 
    with TickerProviderStateMixin {
  int currentStep = 0;
  bool isLoading = false;
  bool showResults = false;
  
  // User data
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

  // Pour le texte dynamique de l'écran de chargement
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
    _loadingTextTimer?.cancel(); // Annuler le timer
    super.dispose();
  }

  void _startLoadingAnimation() {
    _loadingTextIndex = 0;
    _currentLoadingMessage = _loadingMessages[0];
    _loadingTextTimer?.cancel(); // S'assurer qu'un ancien timer est annulé
    _loadingTextTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) { // Vérifier si le widget est toujours monté
        setState(() {
          _loadingTextIndex = (_loadingTextIndex + 1) % _loadingMessages.length;
          _currentLoadingMessage = _loadingMessages[_loadingTextIndex];
        });
      }
      if (_loadingTextIndex == _loadingMessages.length - 1) {
        timer.cancel(); // Arrêter après le dernier message
      }
    });
  }

  // NOUVEAU WIDGET POUR LES CARTES DE SÉLECTION AMÉLIORÉES
  Widget _buildSelectableCard({
    required String title,
    IconData? icon,
    String? description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B132B).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0B132B) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, size: 28, color: isSelected ? const Color(0xFF0B132B) : const Color(0xFF64748B)),
            if (icon != null)
              const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF0B132B) : const Color(0xFF1A1A1A),
                    ),
                  ),
                  if (description != null && description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? const Color(0xFF0B132B).withOpacity(0.8) : const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const SizedBox(width: 12),
            if (isSelected)
              const Icon(LucideIcons.checkCircle, color: Color(0xFF0B132B), size: 20),
          ],
        ),
      ),
    );
  }

  int calculateDailyGoal() {
    if (userData['gender'].isEmpty || 
        userData['age'].isEmpty || 
        userData['weight'].isEmpty || 
        userData['height'].isEmpty || 
        userData['activity'].isEmpty) {
      return 0;
    }

    final age = int.tryParse(userData['age']) ?? 0;
    final weight = double.tryParse(userData['weight']) ?? 0;
    final height = double.tryParse(userData['height']) ?? 0;

    // Calcul BMR (Mifflin-St Jeor)
    double bmr;
    if (userData['gender'] == 'Homme') {
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

    final tdee = bmr * (activityFactors[userData['activity']] ?? 1.2);

    // Ajustement selon l'objectif
    switch (userData['goal']) {
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

  Map<String, int> calculateMacros() {
    final calories = calculateDailyGoal();
    if (calories == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};

    // Calculs basés sur les recommandations nutritionnelles
    final protein = ((calories * 0.25) / 4).round(); // 25% des calories, 4 kcal/g
    final fat = ((calories * 0.3) / 9).round(); // 30% des calories, 9 kcal/g
    final carbs = ((calories * 0.45) / 4).round(); // 45% des calories, 4 kcal/g

    return {'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  bool canProceed() {
    switch (currentStep) {
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
        return true; // Obstacles step is optional
      case 5:
        return true; // Restrictions step is optional
      default:
        return true;
    }
  }

  Future<void> nextStep() async {
    if (currentStep < steps.length - 1) { // Modifié pour refléter le nombre réel d'étapes configurables
      _animationController.reset();
      setState(() {
        currentStep++;
      });
      _animationController.forward();
    } else {
      // Start loading
      setState(() {
        isLoading = true;
      });
      _startLoadingAnimation(); // Démarrer l'animation de texte ici
      
      // Simulate AI processing time
      // Ajustez la durée totale pour qu'elle corresponde approximativement au temps des messages
      await Future.delayed(Duration(milliseconds: _loadingMessages.length * 2500 + 500)); 
      
      _loadingTextTimer?.cancel(); // S'assurer que le timer est arrêté
      // Show results page
      if (mounted) { // Vérifier avant de modifier l'état
          setState(() {
            isLoading = false;
            showResults = true;
          });
      }
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Sauvegarder les données de l'onboarding
    await prefs.setString('gender', userData['gender']);
    
    if (userData['age'].isNotEmpty) {
      await prefs.setInt('age', int.tryParse(userData['age']) ?? 0);
    }
    
    if (userData['weight'].isNotEmpty) {
      await prefs.setDouble('weight', double.tryParse(userData['weight']) ?? 0);
    }
    
    if (userData['height'].isNotEmpty) {
      await prefs.setDouble('height', double.tryParse(userData['height']) ?? 0);
    }
    
    await prefs.setString('activity', userData['activity']);
    await prefs.setString('goal', userData['goal']);
    
    // Sauvegarder les listes
    final obstacles = userData['obstacles'] as List<String>;
    await prefs.setStringList('obstacles', obstacles);
    
    final restrictions = userData['restrictions'] as List<String>;
    await prefs.setStringList('restrictions', restrictions);
  }

  List<Map<String, dynamic>> get steps => [
    {
      'title': 'Bienvenue dans Ryze IA',
      'subtitle': 'Votre coach nutrition personnalisé',
      'content': _buildWelcomeStep(),
    },
    {
      'title': 'Parlez-nous de vous',
      'subtitle': 'Pour calculer vos besoins précis',
      'content': _buildPersonalInfoStep(),
    },
    {
      'title': 'Votre niveau d\'activité',
      'subtitle': 'Pour ajuster vos besoins énergétiques',
      'content': _buildActivityStep(),
    },
    {
      'title': 'Votre objectif',
      'subtitle': 'Pour personnaliser votre plan',
      'content': _buildGoalStep(),
    },
    {
      'title': 'Qu\'est-ce qui t\'empêche de garder une routine ?',
      'subtitle': 'Identifions tes défis pour mieux t\'accompagner',
      'content': _buildObstaclesStep(),
    },
    {
      'title': 'Vos restrictions alimentaires',
      'subtitle': 'Pour adapter votre plan nutrition',
      'content': _buildRestrictionsStep(),
    },
  ];

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        // Remplacement de Lottie par une icône stylisée
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140, // Taille ajustée pour un effet visuel
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0B132B).withOpacity(0.1),
                    const Color(0xFF1C2951).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.brain, // Icône pour Ryze IA
                size: 48,
                color: Colors.white,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Stats grid
        Row(
          children: [
            Expanded(child: _buildStatCard('94%', 'Succès')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('2.1M', 'Utilisateurs')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('4.9★', 'Note App')),
          ],
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'En 5 minutes, créons votre plan nutrition personnalisé basé sur vos besoins réels',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gender selection
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
              child: _buildSelectableCard(
                title: 'Homme',
                icon: LucideIcons.user,
                isSelected: userData['gender'] == 'Homme',
                onTap: () => setState(() => userData['gender'] = 'Homme'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSelectableCard(
                title: 'Femme',
                icon: LucideIcons.user,
                isSelected: userData['gender'] == 'Femme',
                onTap: () => setState(() => userData['gender'] = 'Femme'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Age input - Mobile friendly
        _buildMobileNumberInput(
          'Âge',
          'années',
          userData['age'],
          (value) => setState(() => userData['age'] = value),
          LucideIcons.cake,
        ),
        
        const SizedBox(height: 20),
        
        // Weight input - Mobile friendly
        _buildMobileNumberInput(
          'Poids',
          'kg',
          userData['weight'],
          (value) => setState(() => userData['weight'] = value),
          LucideIcons.scale,
        ),
        
        const SizedBox(height: 20),
        
        // Height input - Mobile friendly
        _buildMobileNumberInput(
          'Taille',
          'cm',
          userData['height'],
          (value) => setState(() => userData['height'] = value),
          LucideIcons.ruler,
        ),
      ],
    );
  }

  Widget _buildActivityStep() {
    final activities = [
      {
        'id': 'sedentary',
        'label': 'Sédentaire',
        'desc': 'Peu ou pas d\'exercice',
        'icon': LucideIcons.user,
      },
      {
        'id': 'light',
        'label': 'Légèrement actif',
        'desc': 'Exercice léger 1-3 jours/semaine',
        'icon': LucideIcons.target,
      },
      {
        'id': 'moderate',
        'label': 'Modérément actif',
        'desc': 'Exercice modéré 3-5 jours/semaine',
        'icon': LucideIcons.activity,
      },
      {
        'id': 'very',
        'label': 'Très actif',
        'desc': 'Exercice intense 6-7 jours/semaine',
        'icon': LucideIcons.zap,
      },
      {
        'id': 'extra',
        'label': 'Extrêmement actif',
        'desc': 'Exercice très intense + travail physique',
        'icon': LucideIcons.trophy,
      },
    ];

    return Column(
      children: activities.map((activity) {
        final isSelected = userData['activity'] == activity['id'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildSelectableCard(
            title: activity['label'] as String,
            icon: activity['icon'] as IconData,
            description: activity['desc'] as String,
            isSelected: isSelected,
            onTap: () => setState(() => userData['activity'] = activity['id']),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalStep() {
    final goals = [
      {
        'id': 'lose',
        'label': 'Perdre du poids',
        'desc': 'Déficit calorique de 500 kcal/jour',
        'icon': LucideIcons.trendingDown,
        'deficit': '-500 kcal',
        'rate': '~0.5kg/semaine',
      },
      {
        'id': 'lose_fast',
        'label': 'Perdre rapidement',
        'desc': 'Déficit calorique de 750 kcal/jour',
        'icon': LucideIcons.zap,
        'deficit': '-750 kcal',
        'rate': '~0.75kg/semaine',
      },
      {
        'id': 'maintain',
        'label': 'Maintenir mon poids',
        'desc': 'Équilibre énergétique parfait',
        'icon': LucideIcons.target,
        'deficit': '0 kcal',
        'rate': 'Stabilité',
      },
      {
        'id': 'gain',
        'label': 'Prendre du poids',
        'desc': 'Surplus calorique de 300 kcal/jour',
        'icon': LucideIcons.trendingUp,
        'deficit': '+300 kcal',
        'rate': '~0.3kg/semaine',
      },
    ];

    return Column(
      children: goals.map((goal) {
        final isSelected = userData['goal'] == goal['id'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildSelectableCard(
            title: goal['label'] as String,
            icon: goal['icon'] as IconData,
            description: goal['desc'] as String?,
            isSelected: isSelected,
            onTap: () => setState(() => userData['goal'] = goal['id'] as String),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildObstaclesStep() {
    final obstacles = [
      'Manque de temps',
      'Je ne sais pas quoi manger',
      'Je perds vite le rythme',
      'Manque de motivation',
      'Aucun de ces problèmes',
      'Je ne sais pas',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionne tous les obstacles qui te concernent',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        
        ...obstacles.map((obstacle) {
          final isSelected = (userData['obstacles'] as List<String>).contains(obstacle);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildSelectableCard(
              title: obstacle,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  final currentObstacles = userData['obstacles'] as List<String>;
                  if (isSelected) {
                    currentObstacles.remove(obstacle);
                  } else {
                    currentObstacles.add(obstacle);
                  }
                });
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRestrictionsStep() {
    final restrictions = [
      'Végétarien',
      'Végan',
      'Sans gluten',
      'Sans lactose',
      'Paléo',
      'Cétogène',
      'Halal',
      'Casher',
      'Sans noix',
      'Diabétique',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez vos restrictions (optionnel)',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: restrictions.map((restriction) {
            final isSelected = (userData['restrictions'] as List<String>).contains(restriction);
            return _buildSelectableCard(
              title: restriction,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  final currentRestrictions = userData['restrictions'] as List<String>;
                  if (isSelected) {
                    currentRestrictions.remove(restriction);
                  } else {
                    currentRestrictions.add(restriction);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMobileNumberInput(String label, String unit, String value, Function(String) onChanged, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: '0',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                    suffixText: unit,
                    suffixStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }
    if (showResults) {
      return _buildResultsScreen();
    }

    final currentStepData = steps[currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fond général
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: currentStep > 0
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
                onPressed: () {
                  _animationController.reset();
                  setState(() => currentStep--);
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
            // Envelopper le contenu de l'étape avec FadeTransition
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
          icon: currentStep == steps.length - 1 ? const Icon(LucideIcons.checkCircle, color: Colors.white) : const Icon(LucideIcons.arrowRight, color: Colors.white),
          isPrimary: canProceed(),
          isDisabled: !canProceed(),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Remplacement de Lottie par une icône stylisée
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B132B).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.cpu, // Icône pour l'analyse
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  '🧠 Ryze IA prépare votre plan...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    _currentLoadingMessage, // Texte dynamique
                    key: ValueKey<String>(_currentLoadingMessage), // Clé pour l'AnimatedSwitcher
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                LinearProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B132B)),
                  backgroundColor: const Color(0xFF0B132B).withOpacity(0.2),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Personnalisation en cours...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final calories = calculateDailyGoal();
    final macros = calculateMacros();
    final bmr = _calculateBMR();
    final totalNeeds = _calculateTotalNeeds();

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
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Votre plan personnalisé',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Basé sur vos besoins nutritionnels',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Calories principales - Mise en avant
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0B132B).withOpacity(0.1),
                                  const Color(0xFF1C2951).withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF0B132B),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  calories.toString(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'kcal/jour',
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
                      const SizedBox(height: 16),
                      const Text(
                        'Votre objectif calorique quotidien',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Macronutriments
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
                      
                      _buildMacroRow('Protéines', '${macros['protein']}g', const Color(0xFF0B132B)),
                      const SizedBox(height: 16),
                      _buildMacroRow('Glucides', '${macros['carbs']}g', const Color(0xFF1C2951)),
                      const SizedBox(height: 16),
                      _buildMacroRow('Lipides', '${macros['fat']}g', const Color(0xFF64748B)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Détails métaboliques
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
                      
                      _buildDetailRow('Métabolisme de base', '$bmr kcal'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Besoins totaux', '$totalNeeds kcal'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Objectif quotidien', '$calories kcal', isHighlight: true),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton final engageant
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

  double _calculateBMR() {
    if (userData['gender'].isEmpty || 
        userData['age'].isEmpty || 
        userData['weight'].isEmpty || 
        userData['height'].isEmpty) {
      return 0;
    }

    final age = int.tryParse(userData['age']) ?? 0;
    final weight = double.tryParse(userData['weight']) ?? 0;
    final height = double.tryParse(userData['height']) ?? 0;

    // Calcul BMR (Mifflin-St Jeor)
    if (userData['gender'] == 'Homme') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  double _calculateTotalNeeds() {
    final bmr = _calculateBMR();
    if (bmr == 0 || userData['activity'].isEmpty) return 0;

    // Facteur d'activité
    final activityFactors = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'very': 1.725,
      'extra': 1.9,
    };

    return bmr * (activityFactors[userData['activity']] ?? 1.2);
  }

  Widget _buildMacroRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF0B132B) : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
} 