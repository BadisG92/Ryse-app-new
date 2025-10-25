import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'ui/custom_button.dart';
import 'ui/onboarding_widgets.dart';
import 'ui/onboarding_models.dart';
import 'ui/numeric_text_field.dart';
import 'caloric_breakdown_bottom_sheet.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';

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
    'targetWeight': '', // Nouveau champ pour le poids objectif
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
  List<String> get _loadingMessages {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    return [
      'loading_nutritional_analysis'.tr(languageCode),
      'loading_activity_level'.tr(languageCode),
      'loading_metabolism'.tr(languageCode),
      'loading_adjustment'.tr(languageCode),
      'loading_macronutrients'.tr(languageCode),
      'loading_preferences'.tr(languageCode),
      'loading_plan_ready'.tr(languageCode)
    ];
  }
  String _currentLoadingMessage = '';

  // Ajout des variables pour les macronutriments modifiables
  double proteinPercentage = 0.30; // 30% par défaut
  double carbsPercentage = 0.40;   // 40% par défaut
  double fatPercentage = 0.30;     // 30% par défaut
  int customCalories = 0;
  bool hasCustomMacros = false;

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
    _currentLoadingMessage = _loadingMessages.isNotEmpty ? _loadingMessages[0] : '';
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
    
    // Initialiser le poids objectif au poids actuel par défaut
    userData['targetWeight'] = userData['weight'];
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
    _currentLoadingMessage = _loadingMessages.isNotEmpty ? _loadingMessages[0] : '';
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

  List<Map<String, dynamic>> getSteps(BuildContext context) {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    return [
      {
        'title': '',
        'subtitle': '',
        'content': const WelcomeStep(), // FACTORISÉ
      },
      {
        'title': 'onboarding_choose_gender'.tr(languageCode),
        'subtitle': 'onboarding_calibrate_plan'.tr(languageCode),
        'content': _buildGenderStep(), // NOUVEAU
      },
      {
        'title': 'onboarding_when_born'.tr(languageCode),
        'subtitle': 'onboarding_calibrate_plan'.tr(languageCode),
        'content': _buildBirthDateStep(), // NOUVEAU
      },
      {
        'title': 'onboarding_height_weight'.tr(languageCode),
        'subtitle': 'onboarding_calibrate_plan'.tr(languageCode),
        'content': _buildHeightWeightStep(), // NOUVEAU
      },
      {
        'title': 'onboarding_activity_level'.tr(languageCode),
        'subtitle': 'onboarding_adjust_energy'.tr(languageCode),
        'content': _buildActivityStep(), // INTÉGRÉ
      },
      {
        'title': 'onboarding_goal'.tr(languageCode),
        'subtitle': 'onboarding_personalize_experience'.tr(languageCode),
        'content': _buildGoalStep(), // INTÉGRÉ
      },
      {
        'title': 'onboarding_obstacles'.tr(languageCode),
        'subtitle': 'onboarding_personalize_experience'.tr(languageCode),
        'content': _buildObstaclesStep(), // INTÉGRÉ
      },
      {
        'title': 'onboarding_dietary_restrictions'.tr(languageCode),
        'subtitle': 'onboarding_personalize_experience'.tr(languageCode),
        'content': _buildRestrictionsStep(), // INTÉGRÉ
      },
    ];
  }

  // Page Genre - Style moderne unifié avec SelectableCard
  Widget _buildGenderStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          
          // Option Homme
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SelectableCard(
              title: 'male'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
              icon: LucideIcons.mars,
              isSelected: userData['gender'] == 'Homme',
              onTap: () => setState(() => userData['gender'] = 'Homme'),
            ),
          ),
          
          // Option Femme
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SelectableCard(
              title: 'female'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
              icon: LucideIcons.venus,
              isSelected: userData['gender'] == 'Femme',
              onTap: () => setState(() => userData['gender'] = 'Femme'),
            ),
          ),
          
          // Option Autre
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SelectableCard(
              title: 'other'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
              icon: LucideIcons.users,
              isSelected: userData['gender'] == 'Autre',
              onTap: () => setState(() => userData['gender'] = 'Autre'),
            ),
          ),
        
        const SizedBox(height: 80),
        ],
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
                  items: _getMonthsList(),
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
                      'onboarding_height_label'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
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
                      'onboarding_weight_label'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
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
  List<String> _getMonthsList() {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    
    if (languageCode == 'fr') {
      return [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
    } else {
      return [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
    }
  }

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
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final activities = [
      {
        'key': 'low',
        'title': 'onboarding_low_activity'.tr(languageCode),
        'description': 'onboarding_low_activity_desc'.tr(languageCode),
        'icon': LucideIcons.house,
      },
      {
        'key': 'moderate',
        'title': 'onboarding_moderate_activity'.tr(languageCode),
        'description': 'onboarding_moderate_activity_desc'.tr(languageCode),
        'icon': LucideIcons.bike,
      },
      {
        'key': 'high',
        'title': 'onboarding_high_activity'.tr(languageCode),
        'description': 'onboarding_high_activity_desc'.tr(languageCode),
        'icon': LucideIcons.dumbbell,
      },
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  // INTÉGRÉ - Logique spécifique pour les objectifs
  Widget _buildGoalStep() {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final goals = [
      {
        'key': 'lose',
        'title': 'onboarding_lose_weight'.tr(languageCode),
        'description': 'onboarding_lose_weight_desc'.tr(languageCode),
        'icon': LucideIcons.trendingDown,
      },
      {
        'key': 'maintain',
        'title': 'onboarding_maintain_weight'.tr(languageCode),
        'description': 'onboarding_maintain_weight_desc'.tr(languageCode),
        'icon': LucideIcons.target,
      },
      {
        'key': 'gain',
        'title': 'onboarding_gain_weight'.tr(languageCode),
        'description': 'onboarding_gain_weight_desc'.tr(languageCode),
        'icon': LucideIcons.trendingUp,
      },
    ];

    // Déterminer si on doit afficher le champ poids objectif
    bool showTargetWeight = userData['goal'] == 'lose' || userData['goal'] == 'gain';

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                  onTap: () => setState(() {
                    userData['goal'] = goal['key'];
                    // Reset target weight if switching to maintain
                    if (goal['key'] == 'maintain') {
                      userData['targetWeight'] = userData['weight'];
                    }
                  }),
                ),
              ),
            ).toList(),
            
            // Champ poids objectif conditionnel
            if (showTargetWeight) ...[
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'target_weight'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData['goal'] == 'lose' 
                        ? 'target_weight_question_lose'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)
                        : 'target_weight_question_gain'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: NumericTextField(
                            controller: TextEditingController(text: userData['targetWeight']?.toString() ?? ''),
                            allowDecimals: true,
                            onChanged: (value) => userData['targetWeight'] = value,
                            decoration: InputDecoration(
                              hintText: 'Ex: 70',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          userData['isMetric'] ? 'kg' : 'lbs',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // INTÉGRÉ - Logique multi-sélection pour obstacles
  Widget _buildObstaclesStep() {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final obstacles = [
      {'title': 'onboarding_lack_of_time'.tr(languageCode), 'icon': LucideIcons.clock},
      {'title': 'onboarding_lack_of_motivation'.tr(languageCode), 'icon': LucideIcons.battery},
      {'title': 'onboarding_fatigue'.tr(languageCode), 'icon': LucideIcons.moon},
      {'title': 'onboarding_lack_of_knowledge'.tr(languageCode), 'icon': LucideIcons.bookOpen},
      {'title': 'onboarding_other_priorities'.tr(languageCode), 'icon': LucideIcons.calendar},
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20), // Réduit de 60 à 20
          ...obstacles.map((obstacle) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableCard(
                title: obstacle['title'] as String,
                icon: obstacle['icon'] as IconData,
                isSelected: (userData['obstacles'] as List<String>).contains(obstacle['title'] as String),
                onTap: () {
                  setState(() {
                    final currentObstacles = userData['obstacles'] as List<String>;
                    final obstacleTitle = obstacle['title'] as String;
                    if (currentObstacles.contains(obstacleTitle)) {
                      currentObstacles.remove(obstacleTitle);
                    } else {
                      currentObstacles.add(obstacleTitle);
                    }
                  });
                },
              ),
            ),
          ).toList(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // INTÉGRÉ - Logique multi-sélection pour restrictions
  Widget _buildRestrictionsStep() {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final restrictions = [
      {'title': 'classic'.tr(languageCode), 'icon': LucideIcons.utensils},
      {'title': 'vegetarian'.tr(languageCode), 'icon': LucideIcons.leaf},
      {'title': 'vegan'.tr(languageCode), 'icon': LucideIcons.sprout},
      {'title': 'pescetarian'.tr(languageCode), 'icon': LucideIcons.fish},
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20), // Réduit de 100 à 20
          ...restrictions.map((restriction) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableCard(
                title: restriction['title'] as String,
                icon: restriction['icon'] as IconData,
                isSelected: (userData['restrictions'] as List<String>).contains(restriction['title'] as String),
                onTap: () {
                  setState(() {
                    final currentRestrictions = userData['restrictions'] as List<String>;
                    final restrictionTitle = restriction['title'] as String;
                    if (currentRestrictions.contains(restrictionTitle)) {
                      currentRestrictions.remove(restrictionTitle);
                    } else {
                      currentRestrictions.add(restrictionTitle);
                    }
                  });
                },
              ),
            ),
          ).toList(),
          const SizedBox(height: 100),
        ],
      ),
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
        return (userData['obstacles'] as List<String>).isNotEmpty; // Obstacles obligatoires
      case 7:
        return (userData['restrictions'] as List<String>).isNotEmpty; // Restrictions obligatoires
      default:
        return false;
    }
  }

  // INTÉGRÉ - Navigation et workflow spécifique
  void nextStep() {
    if (currentStep < 7) { // 8 étapes au total (0-7)
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
    final supabase = Supabase.instance.client;
    final profile = UserProfile.fromMap(userData);
    
    // Utilise les calculs factorisés
    final calories = MetabolicCalculations.calculateDailyGoal(profile);
    final macros = MetabolicCalculations.calculateMacros(profile);
    final bmr = MetabolicCalculations.calculateBMR(profile);
    
    try {
      // Construire la date de naissance
      final birthDate = '${userData['birthYear']}-${userData['birthMonth'].toString().padLeft(2, '0')}-${userData['birthDay'].toString().padLeft(2, '0')}';
      
      // Déterminer le poids objectif
      final targetWeight = userData['targetWeight']?.isNotEmpty == true
          ? double.tryParse(userData['targetWeight']) ?? double.tryParse(userData['weight'] ?? '0')
          : double.tryParse(userData['weight'] ?? '0');

      // Sauvegarder en base de données Supabase
      await supabase.from('users').update({
        'gender': userData['gender'],
        'birth_date': birthDate,
        'age': int.tryParse(userData['age'] ?? '0'),
        'height': double.tryParse(userData['height'] ?? '0'),
        'weight': double.tryParse(userData['weight'] ?? '0'),
        'target_weight': targetWeight, // Nouveau champ
        'is_metric': userData['isMetric'] ?? true,
        'activity_level': userData['activity'],
        'fitness_goal': userData['goal'],
        'obstacles': userData['obstacles'],
        'dietary_restrictions': userData['restrictions'],
        'daily_calories': calories,
        'daily_protein': macros['protein'],
        'daily_carbs': macros['carbs'],
        'daily_fat': macros['fat'],
        'bmr': bmr,
        'is_onboarded': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', supabase.auth.currentUser!.id);
      
      // Créer une entrée dans l'historique pour marquer le poids initial de l'onboarding
      final weight = double.tryParse(userData['weight'] ?? '0') ?? 0.0;
      if (weight > 0) {
        await supabase.from('user_profile_history').insert({
          'user_id': supabase.auth.currentUser!.id,
          'gender': userData['gender'],
          'birth_date': birthDate,
          'age': int.tryParse(userData['age'] ?? '0'),
          'height': double.tryParse(userData['height'] ?? '0'),
          'weight': weight,
          'activity_level': userData['activity'],
          'fitness_goal': userData['goal'],
          'dietary_restrictions': userData['restrictions'],
          'daily_calories': calories,
          'daily_protein': macros['protein'],
          'daily_carbs': macros['carbs'],
          'daily_fat': macros['fat'],
          'bmr': bmr,
          'valid_from': DateTime.now().toIso8601String(),
          'is_current': true,
          'change_source': 'onboarding_completion',
          'weight_modified': true, // Marquer comme pesée intentionnelle
        });
      }
      
      // Aussi sauvegarder en local pour la compatibilité
      await prefs.setInt('daily_calories', calories);
      await prefs.setInt('daily_protein', macros['protein']!);
      await prefs.setInt('daily_carbs', macros['carbs']!);
      await prefs.setInt('daily_fat', macros['fat']!);
      await prefs.setBool('onboarding_completed', true);
      
      debugPrint('✅ Données d\'onboarding sauvegardées avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
      // En cas d'erreur, sauvegarder au moins en local
      await prefs.setInt('daily_calories', calories);
      await prefs.setInt('daily_protein', macros['protein']!);
      await prefs.setInt('daily_carbs', macros['carbs']!);
      await prefs.setInt('daily_fat', macros['fat']!);
      await prefs.setBool('onboarding_completed', true);
    }
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
    final steps = getSteps(context);
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
        title: Consumer<LocalizationService>(
          builder: (context, locService, _) => Text(
            '${'step'.tr(locService.currentLanguageCode)} ${currentStep + 1} ${'on'.tr(locService.currentLanguageCode)} ${steps.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Boutons de changement de langue
          Consumer<LocalizationService>(
            builder: (context, locService, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => locService.setLanguage('fr'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: locService.isFrench ? const Color(0xFF0B132B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0B132B)),
                    ),
                    child: Text(
                      'FR',
                      style: TextStyle(
                        color: locService.isFrench ? Colors.white : const Color(0xFF0B132B),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => locService.setLanguage('en'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: locService.isEnglish ? const Color(0xFF0B132B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0B132B)),
                    ),
                    child: Text(
                      'EN',
                      style: TextStyle(
                        color: locService.isEnglish ? Colors.white : const Color(0xFF0B132B),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
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
          text: currentStep == steps.length - 1 
            ? 'finish'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)
            : 'continue'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
          onPressed: canProceed() ? nextStep : null,
          icon: currentStep == steps.length - 1 
            ? const Icon(LucideIcons.check, color: Colors.white) 
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
    final baseCalories = MetabolicCalculations.calculateDailyGoal(profile);
    
    // Initialiser les pourcentages si ce n'est pas encore fait
    if (!hasCustomMacros) {
      _initializeMacroPercentages(profile.goal);
      customCalories = baseCalories;
      hasCustomMacros = true;
    }
    
    // Utiliser les calories personnalisées ou les calories de base
    final calories = customCalories > 0 ? customCalories : baseCalories;
    final macros = _calculateCustomMacros(calories);
    
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'congratulations'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'your_plan_ready'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
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
                _buildMacronutrientsCard(macros, calories),

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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.rocket,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Consumer<LocalizationService>(
                            builder: (context, locService, _) => Text(
                              'start_journey'.tr(locService.currentLanguageCode),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
          
          Text(
            'daily_goal'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
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
              Text(
                'calculated_specially'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
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
                      LucideIcons.circleHelp,
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
  Widget _buildMacronutrientsCard(Map<String, int> macros, int calories) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      LucideIcons.activity,
                      size: 16,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Macronutriments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (hasCustomMacros && (proteinPercentage != 0.30 || carbsPercentage != 0.40 || fatPercentage != 0.30))
                        Text(
                          'Personnalisé',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF0B132B).withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showMacroEditModal(context, calories),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.pencil,
                      size: 16,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Protéines
          _buildAnimatedMacroRow(
            name: 'proteins'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
            value: macros['protein']!,
            unit: 'g',
            color: const Color(0xFF0B132B),
            icon: LucideIcons.zap,
          ),
          
          const SizedBox(height: 10),
          
          // Glucides
          _buildAnimatedMacroRow(
            name: 'carbs'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
            value: macros['carbs']!,
            unit: 'g',
            color: const Color(0xFF1C2951),
            icon: LucideIcons.wheat,
          ),
          
          const SizedBox(height: 10),
          
          // Lipides
          _buildAnimatedMacroRow(
            name: 'fats'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
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

  // Nouvelle méthode pour initialiser les pourcentages par défaut selon l'objectif
  void _initializeMacroPercentages(String goal) {
    switch (goal) {
      case 'lose':
        proteinPercentage = 0.35;
        carbsPercentage = 0.30;
        fatPercentage = 0.35;
        break;
      case 'gain':
        proteinPercentage = 0.25;
        carbsPercentage = 0.50;
        fatPercentage = 0.25;
        break;
      case 'maintain':
      default:
        proteinPercentage = 0.30;
        carbsPercentage = 0.40;
        fatPercentage = 0.30;
        break;
    }
  }

  // Calcule les macros personnalisés en fonction des pourcentages et calories
  Map<String, int> _calculateCustomMacros(int calories) {
    return {
      'protein': ((calories * proteinPercentage) / 4).round(),
      'carbs': ((calories * carbsPercentage) / 4).round(),
      'fat': ((calories * fatPercentage) / 9).round(),
    };
  }

  // Vérifie que la somme des pourcentages = 100%
  bool _isValidMacroDistribution() {
    final sum = proteinPercentage + carbsPercentage + fatPercentage;
    return (sum - 1.0).abs() < 0.01; // Tolérance de 1%
  }

  // Normalise les pourcentages pour qu'ils totalisent 100%
  void _normalizeMacroPercentages() {
    final sum = proteinPercentage + carbsPercentage + fatPercentage;
    if (sum > 0) {
      proteinPercentage = proteinPercentage / sum;
      carbsPercentage = carbsPercentage / sum;
      fatPercentage = fatPercentage / sum;
    }
  }

  // Détermine quel preset correspond aux valeurs actuelles
  String _getCurrentPreset() {
    const tolerance = 0.02; // Tolérance de 2%
    
    // Équilibré (30-40-30)
    if ((proteinPercentage - 0.30).abs() < tolerance &&
        (carbsPercentage - 0.40).abs() < tolerance &&
        (fatPercentage - 0.30).abs() < tolerance) {
      return 'equilibre';
    }
    
    // Perte (35-30-35)
    if ((proteinPercentage - 0.35).abs() < tolerance &&
        (carbsPercentage - 0.30).abs() < tolerance &&
        (fatPercentage - 0.35).abs() < tolerance) {
      return 'perte';
    }
    
    // Prise (25-50-25)
    if ((proteinPercentage - 0.25).abs() < tolerance &&
        (carbsPercentage - 0.50).abs() < tolerance &&
        (fatPercentage - 0.25).abs() < tolerance) {
      return 'prise';
    }
    
    return ''; // Aucun preset correspondant
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

  // Modal d'édition des macronutriments
  void _showMacroEditModal(BuildContext context, int baseCalories) {
    // Variables temporaires pour les modifications
    double tempProtein = proteinPercentage;
    double tempCarbs = carbsPercentage;
    double tempFat = fatPercentage;
    int tempCalories = customCalories;
    String selectedPreset = _getCurrentPreset(); // Déterminer le preset actuel
    
    final TextEditingController caloriesController = TextEditingController(
      text: tempCalories.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, __) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                // Calculer les grammes en temps réel
                Map<String, int> tempMacros = {
                  'protein': ((tempCalories * tempProtein) / 4).round(),
                  'carbs': ((tempCalories * tempCarbs) / 4).round(),
                  'fat': ((tempCalories * tempFat) / 9).round(),
                };

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                // Poignée
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // En-tête
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Modifier les macronutriments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              LucideIcons.x,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Calories
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                                             Row(
                                 children: [
                                   const Icon(
                                     LucideIcons.target,
                                     size: 16,
                                     color: Color(0xFF0B132B),
                                   ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'daily_calorie_goal'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              NumericTextField(
                                controller: caloriesController,
                                allowDecimals: false,
                                minValue: 1,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0B132B),
                                ),
                                decoration: InputDecoration(
                                  suffixText: 'kcal',
                                  suffixStyle: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0B132B),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                onChanged: (value) {
                                  final newCalories = int.tryParse(value) ?? tempCalories;
                                  if (newCalories > 0) {
                                    setModalState(() {
                                      tempCalories = newCalories;
                                      // Ne pas réinitialiser le preset pour les calories
                                      // car cela n'affecte pas la répartition des macros
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${'recommended'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)} $baseCalories kcal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section Répartition
                        Text(
                          'macronutrient_distribution'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                                                 // Protéines
                         _buildMacroSlider(
                           name: 'proteins'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                           icon: LucideIcons.zap,
                           color: const Color(0xFF0B132B),
                           percentage: tempProtein,
                           grams: tempMacros['protein']!,
                           onChanged: (value) {
                             setModalState(() {
                               tempProtein = value;
                               selectedPreset = ''; // Réinitialiser le preset
                               // Auto-ajuster les autres pour garder 100%
                               final remaining = 1.0 - value;
                               final ratio = remaining / (tempCarbs + tempFat);
                               if (ratio > 0) {
                                 tempCarbs = tempCarbs * ratio;
                                 tempFat = tempFat * ratio;
                               }
                             });
                           },
                         ),

                        const SizedBox(height: 16),

                        // Glucides
                        _buildMacroSlider(
                          name: 'carbs'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                          icon: LucideIcons.wheat,
                          color: const Color(0xFF1C2951),
                          percentage: tempCarbs,
                          grams: tempMacros['carbs']!,
                          onChanged: (value) {
                            setModalState(() {
                              tempCarbs = value;
                              selectedPreset = ''; // Réinitialiser le preset
                              // Auto-ajuster les autres pour garder 100%
                              final remaining = 1.0 - value;
                              final ratio = remaining / (tempProtein + tempFat);
                              if (ratio > 0) {
                                tempProtein = tempProtein * ratio;
                                tempFat = tempFat * ratio;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Lipides
                        _buildMacroSlider(
                          name: 'fats'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                          icon: LucideIcons.droplets,
                          color: const Color(0xFF64748B),
                          percentage: tempFat,
                          grams: tempMacros['fat']!,
                          onChanged: (value) {
                            setModalState(() {
                              tempFat = value;
                              selectedPreset = ''; // Réinitialiser le preset
                              // Auto-ajuster les autres pour garder 100%
                              final remaining = 1.0 - value;
                              final ratio = remaining / (tempProtein + tempCarbs);
                              if (ratio > 0) {
                                tempProtein = tempProtein * ratio;
                                tempCarbs = tempCarbs * ratio;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // Presets rapides
                        Text(
                          'predefined_distributions'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildPresetButton(
                                'balanced'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                                '30-40-30',
                                () {
                                  setModalState(() {
                                    tempProtein = 0.30;
                                    tempCarbs = 0.40;
                                    tempFat = 0.30;
                                    selectedPreset = 'equilibre';
                                  });
                                },
                                isSelected: selectedPreset == 'equilibre',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPresetButton(
                                'weight_loss'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                                '35-30-35',
                                () {
                                  setModalState(() {
                                    tempProtein = 0.35;
                                    tempCarbs = 0.30;
                                    tempFat = 0.35;
                                    selectedPreset = 'perte';
                                  });
                                },
                                isSelected: selectedPreset == 'perte',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPresetButton(
                                'weight_gain'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                                '25-50-25',
                                () {
                                  setModalState(() {
                                    tempProtein = 0.25;
                                    tempCarbs = 0.50;
                                    tempFat = 0.25;
                                    selectedPreset = 'prise';
                                  });
                                },
                                isSelected: selectedPreset == 'prise',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Boutons d'action
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'cancel'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              proteinPercentage = tempProtein;
                              carbsPercentage = tempCarbs;
                              fatPercentage = tempFat;
                              customCalories = tempCalories;
                              hasCustomMacros = true;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B132B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'apply'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Widget pour les sliders de macronutriments
  Widget _buildMacroSlider({
    required String name,
    required IconData icon,
    required Color color,
    required double percentage,
    required int grams,
    required Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
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
                '${(percentage * 100).round()}% • ${grams}g',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: percentage,
              min: 0.05,
              max: 0.70,
              divisions: 65,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour les boutons de presets
  Widget _buildPresetButton(String title, String ratio, VoidCallback onTap, {bool isSelected = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF0B132B).withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF0B132B)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected 
                      ? const Color(0xFF0B132B)
                      : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ratio,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected 
                      ? const Color(0xFF0B132B).withOpacity(0.8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
