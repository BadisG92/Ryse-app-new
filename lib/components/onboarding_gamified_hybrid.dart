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
import '../services/global_state_manager.dart';
import '../services/fast_cache_service.dart';
import '../services/dashboard_service.dart';
import '../services/unit_service.dart';
import '../services/paywall_service.dart';
import '../screens/paywall_screen.dart';
import 'package:provider/provider.dart';
import 'main_app.dart';

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
  int currentStep = 0; // 5 étapes au total (0-4)
  bool isLoading = false;
  bool showResults = false;
  bool showGoodKarma1 = false; // Après Step 1
  bool showGoodKarma2 = false; // Après Step 3
  
  // User data - INTÉGRÉ (état complexe, tight coupling)
  Map<String, dynamic> userData = {
    'gender': '',
    'age': null,          // ← null pour forcer la saisie
    'weight': null,       // ← null pour forcer la saisie
    'height': null,       // ← null pour forcer la saisie
    'birthMonth': '',
    'birthDay': '',
    'birthYear': '',
    'isMetric': true,
    'activity': '',
    'goal': '',
    'targetWeight': null, // ← null pour forcer la saisie (si requis)
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
    final isFrench = languageCode == 'fr';
    return [
      isFrench ? 'Analyse de ton profil...' : 'Analyzing your profile...',
      isFrench ? 'Calcul de tes besoins nutritionnels...' : 'Calculating your nutritional needs...',
      isFrench ? 'Création de ton plan personnalisé...' : 'Creating your personalized plan...',
    ];
  }
  String _currentLoadingMessage = '';

  // Ajout des variables pour les macronutriments modifiables
  double proteinPercentage = 0.30; // 30% par défaut
  double carbsPercentage = 0.40;   // 40% par défaut
  double fatPercentage = 0.30;     // 30% par défaut
  int customCalories = 0;
  bool hasCustomMacros = false;

  // TextEditingControllers persistants pour éviter la perte de focus
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;

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

    // Initialiser les contrôleurs de texte
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _targetWeightController = TextEditingController();

    // Pré-remplir les valeurs par défaut
    _initializeDefaultValues();

    _animationController.forward();
    _currentLoadingMessage = _loadingMessages.isNotEmpty ? _loadingMessages[0] : '';
  }

  void _initializeDefaultValues() {
    // Initialiser uniquement isMetric (pas de pré-remplissage des champs visibles)
    userData['isMetric'] = true;

    // birthMonth, birthDay, birthYear, age, height, weight, targetWeight
    // restent null pour forcer l'utilisateur à les renseigner
  }

  @override
  void dispose() {
    _animationController.dispose();
    _caloriesAnimationController.dispose();
    _loadingTextTimer?.cancel();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  // INTÉGRÉ - Logique de navigation spécifique
  void _startLoadingAnimation() {
    _loadingTextIndex = 0;
    _currentLoadingMessage = _loadingMessages.isNotEmpty ? _loadingMessages[0] : '';
    _loadingTextTimer?.cancel();
    _loadingTextTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
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
    final isFrench = languageCode == 'fr';

    return [
      // Step 0: Genre + Âge (fusionné)
      {
        'title': isFrench ? 'Parle-moi un peu de toi' : 'Tell me a bit about yourself',
        'subtitle': isFrench ? 'Pour personnaliser tes conseils' : 'To personalize your advice',
        'content': _buildGenderAndAgeStep(),
      },
      // Step 1: Objectif SEULEMENT (séparé des restrictions)
      {
        'title': isFrench ? 'Quel est ton objectif ?' : 'What\'s your goal?',
        'subtitle': isFrench ? 'Que veux-tu accomplir en priorité ?' : 'What do you want to achieve as a priority?',
        'content': _buildGoalStep(),
      },
      // Step 2: Taille + Poids + Target Weight (conditionnel)
      {
        'title': isFrench ? 'Dis-moi ta taille et ton poids' : 'Tell me your height and weight',
        'subtitle': isFrench ? 'Pour calculer tes besoins précis' : 'To calculate your precise needs',
        'content': _buildHeightWeightAndTargetStep(),
      },
      // Step 3: Fréquence d'entraînement
      {
        'title': isFrench ? 'Actuellement, tu fais du sport combien de fois par semaine ?' : 'How many times per week do you currently work out?',
        'subtitle': '',
        'content': _buildActivityStep(),
      },
      // Step 4: Restrictions alimentaires (remplace Obstacles)
      {
        'title': isFrench ? 'As-tu des préférences alimentaires ?' : 'Do you have any dietary preferences?',
        'subtitle': isFrench ? 'Allergies, régimes spéciaux, etc.' : 'Allergies, special diets, etc.',
        'content': _buildRestrictionsStep(),
      },
    ];
  }

  // Step 0: Genre + Âge (fusionné avec affichage compact)
  Widget _buildGenderAndAgeStep() {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final hasSelectedGender = userData['gender'].isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            // Section Genre
            Text(
              isFrench ? 'Tu es...' : 'You are...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // Si genre PAS sélectionné → Afficher toutes les options
            if (!hasSelectedGender) ...[
              _buildGenderOption('Homme', LucideIcons.mars, languageCode),
              const SizedBox(height: 12),
              _buildGenderOption('Femme', LucideIcons.venus, languageCode),
            ],

            // Si genre sélectionné → Afficher CHIP COMPACT + option de modification
            if (hasSelectedGender) ...[
              _buildCompactGenderChip(languageCode, isFrench),

              const SizedBox(height: 32),

              // Section Âge (apparaît après sélection du genre)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFrench ? 'Quel âge as-tu ?' : 'How old are you?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: 120,
                      child: TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B132B),
                        ),
                        decoration: InputDecoration(
                          hintText: '24',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B).withOpacity(0.4),
                          ),
                          suffixText: isFrench ? 'ans' : 'years',
                          suffixStyle: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              userData['age'] = null; // ← Mettre null si vide
                            } else {
                              final age = int.tryParse(value);
                              if (age != null && age >= 13 && age <= 100) {
                                userData['age'] = value;
                                // Calculer une date de naissance approximative
                                final year = 2025 - age;
                                userData['birthYear'] = year.toString();
                                userData['birthMonth'] = '1';
                                userData['birthDay'] = '1';
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // Widget option de genre (version complète)
  Widget _buildGenderOption(String genderKey, IconData icon, String languageCode) {
    final isSelected = userData['gender'] == genderKey;
    final isFrench = languageCode == 'fr';

    String label;
    if (genderKey == 'Homme') {
      label = isFrench ? 'Homme' : 'Male';
    } else if (genderKey == 'Femme') {
      label = isFrench ? 'Femme' : 'Female';
    } else {
      label = isFrench ? 'Autre' : 'Other';
    }

    return SelectableCard(
      title: label,
      icon: icon,
      isSelected: isSelected,
      onTap: () => setState(() => userData['gender'] = genderKey),
    );
  }

  // Widget chip compact pour le genre sélectionné
  Widget _buildCompactGenderChip(String languageCode, bool isFrench) {
    String label;
    IconData icon;

    if (userData['gender'] == 'Homme') {
      label = isFrench ? 'Homme' : 'Male';
      icon = LucideIcons.mars;
    } else if (userData['gender'] == 'Femme') {
      label = isFrench ? 'Femme' : 'Female';
      icon = LucideIcons.venus;
    } else {
      label = isFrench ? 'Autre' : 'Other';
      icon = LucideIcons.users;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0B132B).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => setState(() => userData['gender'] = ''),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Text(
                isFrench ? 'Modifier' : 'Change',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B132B).withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Objectif SEULEMENT (simplifié, pas de compact chip)
  Widget _buildGoalStep() {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final isFrench = languageCode == 'fr';

    final goals = [
      {
        'key': 'lose',
        'title': isFrench ? 'Perdre du poids' : 'Lose weight',
        'description': isFrench ? 'Brûler de la graisse' : 'Burn fat',
        'icon': LucideIcons.trendingDown,
      },
      {
        'key': 'maintain',
        'title': isFrench ? 'Maintenir mon poids' : 'Maintain weight',
        'description': isFrench ? 'Rester stable' : 'Stay stable',
        'icon': LucideIcons.target,
      },
      {
        'key': 'gain',
        'title': isFrench ? 'Prendre du poids' : 'Gain weight',
        'description': isFrench ? 'Construire du muscle' : 'Build muscle',
        'icon': LucideIcons.trendingUp,
      },
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            // Afficher toutes les options d'objectif
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

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // Helper methods pour le Height Picker impérial
  String _getHeightImperialFormatted() {
    if (userData['height'] == null) return '5\' 7"'; // Placeholder grisé
    final totalInches = int.tryParse(userData['height'].toString()) ?? 0;
    if (totalInches == 0) return '5\' 7"'; // Placeholder si invalide
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return '$feet\' $inches"';
  }

  // Helper pour savoir si c'est juste un placeholder
  bool _isHeightPlaceholder() {
    return userData['height'] == null;
  }

  void _showHeightPicker(BuildContext context) {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final isFrench = languageCode == 'fr';

    // Générer toutes les hauteurs de 4'0" à 7'0" (48 à 84 inches)
    final heights = <String>[];
    final heightsInInches = <int>[];
    for (int feet = 4; feet <= 7; feet++) {
      for (int inches = 0; inches < 12; inches++) {
        final totalInches = feet * 12 + inches;
        if (totalInches > 84) break; // Arrêter à 7'0"
        heights.add('$feet\' $inches"');
        heightsInInches.add(totalInches);
      }
    }

    // Trouver l'index actuel
    final currentHeight = int.tryParse(userData['height'] ?? '67') ?? 67;
    int initialIndex = heightsInInches.indexOf(currentHeight);
    if (initialIndex == -1) initialIndex = heightsInInches.indexOf(67); // Défaut 5'7"

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 300,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isFrench ? 'Annuler' : 'Cancel',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    isFrench ? 'Taille' : 'Height',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isFrench ? 'OK' : 'Done',
                      style: const TextStyle(
                        color: Color(0xFF0B132B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Picker
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: initialIndex),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    userData['height'] = heightsInInches[index].toString();
                  });
                },
                children: heights.map((height) => Center(
                  child: Text(
                    height,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget chip compact pour l'objectif sélectionné
  Widget _buildCompactGoalChip(String languageCode, bool isFrench, List<Map<String, dynamic>> goals) {
    final selectedGoal = goals.firstWhere((g) => g['key'] == userData['goal']);
    final label = selectedGoal['title'] as String;
    final icon = selectedGoal['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0B132B).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => setState(() {
              userData['goal'] = '';
              (userData['restrictions'] as List<String>).clear(); // Reset restrictions aussi
            }),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Text(
                isFrench ? 'Modifier' : 'Change',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B132B).withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Taille + Poids + Target Weight (fusionné avec target conditionnel)
  Widget _buildHeightWeightAndTargetStep() {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final isFrench = languageCode == 'fr';
    bool showTargetWeight = userData['goal'] == 'lose' || userData['goal'] == 'gain';

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Toggle Impérial/Métrique avec conversion automatique
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
                      onTap: () {
                        setState(() {
                          if (userData['isMetric'] == true) {
                            // Conversion Métrique → Impérial (seulement si valeurs existent)
                            if (userData['height'] != null) {
                              final heightCm = double.tryParse(userData['height'].toString()) ?? 0;
                              if (heightCm > 0) {
                                userData['height'] = (heightCm / 2.54).round().toString(); // cm → inches
                                _heightController.text = userData['height'].toString();
                              }
                            }

                            if (userData['weight'] != null) {
                              final weightKg = double.tryParse(userData['weight'].toString()) ?? 0;
                              if (weightKg > 0) {
                                userData['weight'] = (weightKg * 2.20462).toStringAsFixed(1); // kg → lbs
                                _weightController.text = userData['weight'].toString();
                              }
                            }

                            if (userData['targetWeight'] != null) {
                              final targetKg = double.tryParse(userData['targetWeight'].toString()) ?? 0;
                              if (targetKg > 0) {
                                userData['targetWeight'] = (targetKg * 2.20462).toStringAsFixed(1);
                                _targetWeightController.text = userData['targetWeight'].toString();
                              }
                            }

                            userData['isMetric'] = false;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: userData['isMetric'] == false ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: userData['isMetric'] == false
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            isFrench ? 'Impérial' : 'Imperial',
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
                      onTap: () {
                        setState(() {
                          if (userData['isMetric'] == false) {
                            // Conversion Impérial → Métrique (seulement si valeurs existent)
                            if (userData['height'] != null) {
                              final heightIn = double.tryParse(userData['height'].toString()) ?? 0;
                              if (heightIn > 0) {
                                userData['height'] = (heightIn * 2.54).round().toString(); // inches → cm
                                _heightController.text = userData['height'].toString();
                              }
                            }

                            if (userData['weight'] != null) {
                              final weightLbs = double.tryParse(userData['weight'].toString()) ?? 0;
                              if (weightLbs > 0) {
                                userData['weight'] = (weightLbs / 2.20462).toStringAsFixed(1); // lbs → kg
                                _weightController.text = userData['weight'].toString();
                              }
                            }

                            if (userData['targetWeight'] != null) {
                              final targetLbs = double.tryParse(userData['targetWeight'].toString()) ?? 0;
                              if (targetLbs > 0) {
                                userData['targetWeight'] = (targetLbs / 2.20462).toStringAsFixed(1);
                                _targetWeightController.text = userData['targetWeight'].toString();
                              }
                            }

                            userData['isMetric'] = true;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: userData['isMetric'] == true ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: userData['isMetric'] == true
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            isFrench ? 'Métrique' : 'Metric',
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

            const SizedBox(height: 24),

            // Champs taille et poids
            if (userData['isMetric']) ...[
              // Mode MÉTRIQUE : cm et kg
              Row(
                children: [
                  // Champ Taille (cm)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFrench ? 'Taille' : 'Height',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B132B),
                          ),
                          decoration: InputDecoration(
                            hintText: '170',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B).withOpacity(0.4),
                            ),
                            suffixText: 'cm',
                            suffixStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) => setState(() {
                            userData['height'] = value.isEmpty ? null : value;
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Champ Poids (kg)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFrench ? 'Poids' : 'Weight',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B132B),
                          ),
                          decoration: InputDecoration(
                            hintText: '70',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B).withOpacity(0.4),
                            ),
                            suffixText: 'kg',
                            suffixStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) => setState(() {
                            userData['weight'] = value.isEmpty ? null : value;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Mode IMPÉRIAL : Wheel Picker pour taille (format "5' 7"") + TextField pour poids
              Row(
                children: [
                  // Champ Taille (Wheel Picker avec format "5' 7"")
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFrench ? 'Taille' : 'Height',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showHeightPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getHeightImperialFormatted(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _isHeightPlaceholder()
                                        ? Color(0xFF64748B).withOpacity(0.4)
                                        : const Color(0xFF0B132B),
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevronDown,
                                  size: 20,
                                  color: Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Champ Poids (lbs)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFrench ? 'Poids' : 'Weight',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B132B),
                          ),
                          decoration: InputDecoration(
                            hintText: '154',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B).withOpacity(0.4),
                            ),
                            suffixText: 'lbs',
                            suffixStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) => setState(() {
                            userData['weight'] = value.isEmpty ? null : value;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Champ poids objectif conditionnel
            if (showTargetWeight) ...[
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFrench ? 'Poids objectif' : 'Target weight',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetWeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B132B),
                    ),
                    decoration: InputDecoration(
                      hintText: userData['goal'] == 'lose'
                          ? (userData['isMetric'] ? '65' : '143')
                          : (userData['isMetric'] ? '75' : '165'),
                      hintStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B).withOpacity(0.4),
                      ),
                      suffixText: userData['isMetric'] ? 'kg' : 'lbs',
                      suffixStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) => setState(() {
                      userData['targetWeight'] = value.isEmpty ? null : value;
                    }),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Page Date de naissance avec roues de sélection (ancienne méthode, peut être supprimée)
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

  // Step 3: Fréquence d'entraînement (avec tutoiement)
  Widget _buildActivityStep() {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final isFrench = languageCode == 'fr';

    final activities = [
      {
        'key': 'low',
        'title': isFrench ? 'Rarement' : 'Rarely',
        'description': '',
        'icon': LucideIcons.house,
      },
      {
        'key': 'light',
        'title': isFrench ? 'Quelques fois' : 'A few times',
        'description': '',
        'icon': LucideIcons.footprints,
      },
      {
        'key': 'moderate',
        'title': isFrench ? 'Régulièrement' : 'Regularly',
        'description': '',
        'icon': LucideIcons.bike,
      },
      {
        'key': 'high',
        'title': isFrench ? 'Très souvent' : 'Very often',
        'description': '',
        'icon': LucideIcons.dumbbell,
      },
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
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

  // Step 4: Obstacles (avec tutoiement et empathie)
  Widget _buildObstaclesStep() {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final isFrench = languageCode == 'fr';

    final obstacles = [
      {'title': isFrench ? 'Manque de temps' : 'Lack of time', 'icon': LucideIcons.clock},
      {'title': isFrench ? 'Manque de motivation' : 'Lack of motivation', 'icon': LucideIcons.battery},
      {'title': isFrench ? 'Fatigue' : 'Fatigue', 'icon': LucideIcons.moon},
      {'title': isFrench ? 'Manque de connaissances' : 'Lack of knowledge', 'icon': LucideIcons.bookOpen},
      {'title': isFrench ? 'Autres priorités' : 'Other priorities', 'icon': LucideIcons.calendar},
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
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

  // Afficher Good Karma bottom sheet avec animation
  void _showGoodKarmaBottomSheet(int karmaNumber) {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final isFrench = languageCode == 'fr';

    String message;
    String pandaImage;

    if (karmaNumber == 1) {
      // Après Step 2 (Restrictions)
      message = isFrench ? 'Super ! Je commence à voir ton profil...' : 'Great! I\'m starting to see your profile...';
      pandaImage = 'assets/images/coach_ryze_karma_1.png';
    } else {
      // Après Step 4 (Activité)
      message = isFrench ? 'Parfait ! Plus qu\'une question...' : 'Perfect! Just one more question...';
      pandaImage = 'assets/images/coach_ryze_karma_2.png';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Bulle + nom Coach Ryze à GAUCHE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nom "Coach Ryze" au-dessus de la bulle
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 6),
                        child: Text(
                          'Coach Ryze',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Bulle de message avec gradient
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B132B).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Panda animé à DROITE
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 180,
                        height: 180,
                        child: Image.asset(
                          pandaImage,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bouton "Continuer"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (karmaNumber == 1) {
                      showGoodKarma1 = false;
                    } else {
                      showGoodKarma2 = false;
                    }
                    currentStep++;
                  });
                  _animationController.reset();
                  _animationController.forward();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Logique de validation pour les 5 étapes
  bool canProceed() {
    switch (currentStep) {
      case 0:
        // Step 0: Genre + Âge - doit avoir sélectionné le genre ET rempli l'âge
        final age = userData['age'];
        return userData['gender'].isNotEmpty &&
               age != null &&
               age.toString().isNotEmpty &&
               (int.tryParse(age.toString()) ?? 0) >= 13;
      case 1:
        // Step 1: Objectif SEULEMENT - doit avoir sélectionné l'objectif
        return userData['goal'].isNotEmpty;
      case 2:
        // Step 2: Taille + Poids requis, Target Weight optionnel (si objectif = lose/gain)
        final height = userData['height'];
        final weight = userData['weight'];

        final hasHeight = height != null &&
                          height.toString().isNotEmpty &&
                          (double.tryParse(height.toString()) ?? 0) > 0;
        final hasWeight = weight != null &&
                          weight.toString().isNotEmpty &&
                          (double.tryParse(weight.toString()) ?? 0) > 0;

        // Si objectif = perdre/prendre, vérifier aussi le poids objectif
        if (userData['goal'] == 'lose' || userData['goal'] == 'gain') {
          final targetWeight = userData['targetWeight'];
          final hasTargetWeight = targetWeight != null &&
                                  targetWeight.toString().isNotEmpty &&
                                  (double.tryParse(targetWeight.toString()) ?? 0) > 0;
          return hasHeight && hasWeight && hasTargetWeight;
        }

        return hasHeight && hasWeight;
      case 3:
        // Step 3: Fréquence d'entraînement - doit avoir sélectionné l'activité
        return userData['activity'].isNotEmpty;
      case 4:
        // Step 4: Restrictions alimentaires - doit avoir sélectionné au moins une restriction
        return (userData['restrictions'] as List<String>).isNotEmpty;
      default:
        return false;
    }
  }

  // Navigation et workflow - 5 étapes + Good Karma bottom sheets
  void nextStep() {
    // Step 1 complété (Objectif) → Afficher Good Karma 1 (bottom sheet)
    if (currentStep == 1 && !showGoodKarma1) {
      setState(() {
        showGoodKarma1 = true;
      });
      _showGoodKarmaBottomSheet(1);
      return;
    }

    // Step 3 complété (Activité) → Afficher Good Karma 2 (bottom sheet)
    if (currentStep == 3 && !showGoodKarma2) {
      setState(() {
        showGoodKarma2 = true;
      });
      _showGoodKarmaBottomSheet(2);
      return;
    }

    // Navigation normale entre les steps
    if (currentStep < 4) { // 5 étapes au total (0-4)
      setState(() {
        currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      // Dernière étape (Step 4 - Restrictions) - démarrer le chargement
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

    debugPrint('🔍 Début de sauvegarde des données d\'onboarding');
    debugPrint('userData complet: $userData');
    debugPrint('Calories calculées: $calories');
    debugPrint('BMR calculée: $bmr');
    debugPrint('Macros calculées: $macros');

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté - impossible de sauvegarder');
      }

      // Construire la date de naissance
      final birthDate = '${userData['birthYear']}-${userData['birthMonth'].toString().padLeft(2, '0')}-${userData['birthDay'].toString().padLeft(2, '0')}';
      debugPrint('Date de naissance construite: $birthDate');

      // Convertir en métrique si l'utilisateur est en impérial
      // La base de données stocke TOUJOURS en métrique (kg, cm)
      final bool isMetric = userData['isMetric'] ?? true;

      double heightValue = double.tryParse(userData['height'] ?? '0') ?? 0;
      double weightValue = double.tryParse(userData['weight'] ?? '0') ?? 0;
      double targetWeightValue = userData['targetWeight']?.isNotEmpty == true
          ? double.tryParse(userData['targetWeight']) ?? weightValue
          : weightValue;

      if (!isMetric) {
        // Convertir inches → cm et lbs → kg
        heightValue = heightValue * 2.54;
        weightValue = weightValue / 2.20462;
        targetWeightValue = targetWeightValue / 2.20462;
        debugPrint('🔄 Conversion impérial → métrique pour stockage');
        debugPrint('  Taille: ${userData['height']} in → ${heightValue.toStringAsFixed(1)} cm');
        debugPrint('  Poids: ${userData['weight']} lbs → ${weightValue.toStringAsFixed(1)} kg');
      }

      debugPrint('Poids objectif (en kg): ${targetWeightValue.toStringAsFixed(1)}');

      // Préparer les données à sauvegarder (TOUJOURS en métrique)
      final updateData = {
        'gender': userData['gender'],
        'birth_date': birthDate,
        'age': int.tryParse(userData['age'] ?? '0'),
        'height': heightValue,
        'weight': weightValue,
        'target_weight': targetWeightValue,
        'is_metric': isMetric,
        'activity_level': userData['activity'],
        'fitness_goal': userData['goal'],
        'dietary_restrictions': userData['restrictions'],
        'daily_calories': calories,
        'daily_protein': macros['protein'],
        'daily_carbs': macros['carbs'],
        'daily_fat': macros['fat'],
        'bmr': bmr,
        'is_onboarded': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('Données à sauvegarder dans Supabase:');
      updateData.forEach((key, value) {
        debugPrint('  $key: $value');
      });

      // Sauvegarder en base de données Supabase
      final response = await supabase
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select();

      debugPrint('✅ Réponse Supabase UPDATE: $response');

      // Créer une entrée dans l'historique pour marquer le poids initial de l'onboarding
      // Utiliser weightValue qui est déjà converti en kg
      if (weightValue > 0) {
        debugPrint('Création de l\'entrée dans user_profile_history...');

        // Vérifier s'il existe déjà un profil current pour cet utilisateur
        final existingProfile = await supabase
            .from('user_profile_history')
            .select('id')
            .eq('user_id', userId)
            .eq('is_current', true)
            .maybeSingle();

        if (existingProfile != null) {
          // Mettre à jour le profil existant au lieu d'en créer un nouveau
          debugPrint('🔄 Profil current existant trouvé, mise à jour...');
          final historyResponse = await supabase
              .from('user_profile_history')
              .update({
                'gender': userData['gender'],
                'birth_date': birthDate,
                'age': int.tryParse(userData['age'] ?? '0'),
                'height': heightValue,
                'weight': weightValue,
                'activity_level': userData['activity'],
                'fitness_goal': userData['goal'],
                'dietary_restrictions': userData['restrictions'],
                'daily_calories': calories,
                'daily_protein': macros['protein'],
                'daily_carbs': macros['carbs'],
                'daily_fat': macros['fat'],
                'bmr': bmr,
                'valid_from': DateTime.now().toIso8601String(),
                'change_source': 'onboarding_completion',
                'weight_modified': true,
              })
              .eq('id', existingProfile['id'])
              .select();
          debugPrint('✅ Réponse Supabase UPDATE history: $historyResponse');
        } else {
          // Créer un nouveau profil current
          debugPrint('➕ Aucun profil current, création...');
          final historyResponse = await supabase.from('user_profile_history').insert({
            'user_id': userId,
            'gender': userData['gender'],
            'birth_date': birthDate,
            'age': int.tryParse(userData['age'] ?? '0'),
            'height': heightValue,
            'weight': weightValue,
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
            'weight_modified': true,
          }).select();
          debugPrint('✅ Réponse Supabase INSERT history: $historyResponse');
        }
      }

      // Aussi sauvegarder en local pour la compatibilité
      await prefs.setInt('daily_calories', calories);
      await prefs.setInt('daily_protein', macros['protein']!);
      await prefs.setInt('daily_carbs', macros['carbs']!);
      await prefs.setInt('daily_fat', macros['fat']!);
      await prefs.setBool('onboarding_completed', true);

      // IMPORTANT: Sauvegarder la préférence d'unité pour UnitService
      await prefs.setString('measurement_unit', isMetric ? 'Métrique' : 'Impérial');
      // Synchroniser UnitService immédiatement
      await UnitService.instance.setImperial(!isMetric);
      debugPrint('📏 Préférence d\'unité sauvegardée: ${isMetric ? "Métrique" : "Impérial"}');

      debugPrint('✅ ✅ ✅ Données d\'onboarding sauvegardées avec SUCCÈS dans Supabase et localement');
    } catch (e, stackTrace) {
      debugPrint('❌ ❌ ❌ ERREUR CRITIQUE lors de la sauvegarde: $e');
      debugPrint('Stack trace: $stackTrace');

      // En cas d'erreur, sauvegarder au moins en local
      try {
        await prefs.setInt('daily_calories', calories);
        await prefs.setInt('daily_protein', macros['protein']!);
        await prefs.setInt('daily_carbs', macros['carbs']!);
        await prefs.setInt('daily_fat', macros['fat']!);
        await prefs.setBool('onboarding_completed', true);
        debugPrint('⚠️ Sauvegarde locale de secours effectuée');
      } catch (localError) {
        debugPrint('❌ Impossible de sauvegarder même en local: $localError');
      }

      // Relancer l'erreur pour que l'utilisateur sache qu'il y a un problème
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher les résultats finaux
    if (showResults) {
      return _buildResultsScreen();
    }

    // Afficher l'écran de chargement
    if (isLoading) {
      return Scaffold(
        body: LoadingStep(currentMessage: _currentLoadingMessage),
      );
    }

    // Afficher l'étape normale (Good Karma sont maintenant des bottom sheets)
    return _buildStepScreen();
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(steps.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentStep == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentStep == index
                    ? const Color(0xFF0B132B)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
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
        child: Consumer<LocalizationService>(
          builder: (context, locService, _) {
            final isFrench = locService.currentLanguageCode == 'fr';
            return CustomButton(
              text: currentStep == steps.length - 1
                  ? (isFrench ? 'Terminer' : 'Finish')
                  : (isFrench ? 'Continuer' : 'Continue'),
              onPressed: canProceed() ? nextStep : null,
              icon: currentStep == steps.length - 1
                  ? const Icon(LucideIcons.check, color: Colors.white)
                  : const Icon(LucideIcons.arrowRight, color: Colors.white),
              isPrimary: canProceed(),
              isDisabled: !canProceed(),
            );
          },
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
    final goalAdjustment = _getGoalAdjustment(profile.goal, tdee: totalNeeds);

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
                // En-tête Coach Ryze avec panda félicitations
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Bulle + nom Coach Ryze à GAUCHE (augmenté en largeur)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nom "Coach Ryze" au-dessus de la bulle
                            const Padding(
                              padding: EdgeInsets.only(left: 8, bottom: 6),
                              child: Text(
                                'Coach Ryze',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // Bulle de message avec gradient
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0B132B).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Consumer<LocalizationService>(
                                builder: (context, locService, _) {
                                  final isFrench = locService.currentLanguageCode == 'fr';
                                  return Text(
                                    isFrench ? 'Voici ce que j\'ai préparé pour toi !' : 'Here\'s what I prepared for you!',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Panda félicitations à DROITE
                      Container(
                        width: 140,
                        height: 140,
                        child: Image.asset(
                          'assets/images/coach_ryze_congratulations.png',
                          fit: BoxFit.contain,
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
                        try {
                          debugPrint('💾 Sauvegarde des données...');
                          await _saveUserData();
                          debugPrint('✅ Données sauvegardées');

                          // Rafraîchir le GlobalState avant de naviguer pour charger les nouvelles données
                          try {
                            final globalState = GlobalStateManager.instance;
                            debugPrint('🔄 Rafraîchissement du GlobalState...');
                            await globalState.initialize();
                            debugPrint('✅ GlobalState rafraîchi - Calories: ${globalState.calorieGoal}');

                            // Invalider les caches pour forcer le rechargement des données
                            debugPrint('🗑️ Invalidation des caches...');
                            FastCacheService.invalidateDashboard();
                            DashboardService.clearAllCache();
                            debugPrint('✅ Caches invalidés');
                          } catch (e) {
                            debugPrint('⚠️ Erreur rafraîchissement GlobalState: $e');
                          }

                          // Marquer onboarding comme terminé
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('has_seen_intro', true);
                          await prefs.setBool('is_onboarded', true);

                          // Mettre à jour Supabase
                          final supabase = Supabase.instance.client;
                          final user = supabase.auth.currentUser;
                          if (user != null) {
                            try {
                              await supabase.from('users').update({
                                'is_onboarded': true,
                              }).eq('id', user.id);
                              debugPrint('✅ Onboarding marqué comme terminé dans Supabase');
                            } catch (e) {
                              debugPrint('⚠️ Erreur mise à jour onboarding Supabase: $e');
                            }
                          }

                          // Navigation DIRECTE vers Paywall depuis ce widget (context valide)
                          if (!mounted) return;
                          debugPrint('🚀 Navigation directe vers PaywallScreen...');

                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (ctx) => PaywallScreen(
                                context: PaywallContext.genericUpgrade,
                                customTitle: 'Débloquez Coach Ryze Premium',
                                customMessage: 'Profitez de 7 jours d\'essai gratuit',
                                onDismiss: () {
                                  debugPrint('🏠 Paywall fermé → Navigation vers MainApp');
                                  Navigator.of(ctx, rootNavigator: true).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const MainApp()),
                                    (route) => false,
                                  );
                                },
                              ),
                            ),
                            (route) => false,
                          );
                        } catch (e) {
                          debugPrint('❌ Erreur onboarding: $e');
                          // En cas d'erreur, permettre de continuer vers MainApp
                          if (mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Erreur de sauvegarde'),
                                content: Text(
                                  'Impossible de sauvegarder vos données dans le cloud.\n\n'
                                  'Vos informations sont sauvegardées localement.\n\n'
                                  'Erreur: $e'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      // Aller directement vers MainApp
                                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const MainApp()),
                                        (route) => false,
                                      );
                                    },
                                    child: const Text('Continuer'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
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

          // Estimation du temps pour atteindre le poids cible
          Builder(
            builder: (context) {
              final profile = UserProfile.fromMap(userData);
              final timeEstimateText = MetabolicCalculations.getTimeEstimateText(
                profile,
                isMetric: userData['isMetric'] ?? true,
              );

              if (timeEstimateText.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0B132B).withOpacity(0.08),
                          const Color(0xFF1C2951).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0B132B).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 16,
                          color: const Color(0xFF0B132B).withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            timeEstimateText,
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF1A1A1A).withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Recommandation de séances de sport par semaine
          Builder(
            builder: (context) {
              final profile = UserProfile.fromMap(userData);
              final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
              final workoutText = MetabolicCalculations.getWorkoutRecommendationText(
                profile,
                isFrench: languageCode == 'fr',
              );

              if (workoutText.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.08),
                          const Color(0xFF059669).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.dumbbell,
                          size: 16,
                          color: const Color(0xFF10B981).withOpacity(0.8),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            workoutText,
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF065F46).withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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
      'low': 1.2,      // Rarement (sédentaire)
      'light': 1.375,  // Quelques fois (légèrement actif)
      'moderate': 1.55, // Régulièrement (modérément actif)
      'high': 1.725,   // Très souvent (très actif)
    };
    return multipliers[activity] ?? 1.2;
  }

  int _getGoalAdjustment(String goal, {double? tdee}) {
    // Si TDEE n'est pas fourni, utiliser les anciennes valeurs par défaut
    if (tdee == null) {
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

    // Nouveau calcul adaptatif
    switch (goal) {
      case 'lose':
        // Déficit adaptatif : 20% du TDEE (max 500 kcal)
        final deficit = (tdee * 0.20).round();
        return -(deficit > 500 ? 500 : deficit);

      case 'gain':
        // Surplus adaptatif : 15% du TDEE (max 500 kcal)
        final surplus = (tdee * 0.15).round();
        return surplus > 500 ? 500 : surplus;

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
