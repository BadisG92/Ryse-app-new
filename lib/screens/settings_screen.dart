import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/goals_notifier.dart';
import '../components/ui/onboarding_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  // État des sections expandables
  final Map<String, bool> _expandedSections = {};
  
  // État local pour la V1 - sera migré vers Supabase plus tard
  
  // Profil utilisateur
  String _gender = 'Homme';
  String _age = '25';
  String _height = '175';
  String _weight = '70';
  
  // Objectifs
  String _activityLevel = 'moderate'; // 'low', 'moderate', 'high'
  String _mainGoal = 'maintain'; // 'lose', 'maintain', 'gain'
  String _targetWeight = '70';
  int _proteinTarget = 150;
  int _carbsTarget = 200;
  int _fatTarget = 80;
  int _caloriesTarget = 2200;
  
  // Macros personnalisées
  bool _hasCustomMacros = false;
  double _proteinPercentage = 0.30;
  double _carbsPercentage = 0.40;
  double _fatPercentage = 0.30;
  
  // Notifications
  bool _dailyReminder = true;
  bool _workoutReminder = true;
  bool _mealReminder = true;
  bool _progressNotifications = true;
  String _reminderTime = '08:00';
  
  // Préférences
  String _language = 'Français';
  String _measurementUnit = 'Métrique';
  String _startWeekDay = 'Lundi';
  bool _darkMode = false;
  bool _soundEffects = true;
  bool _hapticFeedback = true;
  
  // Restrictions alimentaires
  List<String> _dietaryRestrictions = [];
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Toutes les sections sont fermées par défaut
    _expandedSections['profile'] = false;
    _expandedSections['objectives'] = false;
    _expandedSections['notifications'] = false;
    _expandedSections['preferences'] = false;
    _expandedSections['restrictions'] = false;
    _expandedSections['account'] = false;
  }
  
  Future<void> _loadSettings() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        // Si pas connecté, charger depuis SharedPreferences
        await _loadFromSharedPreferences();
        return;
      }
      
      // Charger les données depuis Supabase
      final response = await supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      // Charger aussi le profil historique actuel pour les macros personnalisées
      final historyResponse = await supabase
          .from('user_profile_history')
          .select('*')
          .eq('user_id', userId)
          .eq('is_current', true)
          .maybeSingle();
      
      setState(() {
        // Données du profil
        _gender = response['gender'] ?? 'Homme';
        _age = response['age']?.toString() ?? '25';
        _height = response['height']?.toString() ?? '175';
        _weight = response['weight']?.toString() ?? '70';
        
        // Objectifs et activité
        _activityLevel = response['activity_level'] ?? 'moderate';
        _mainGoal = response['fitness_goal'] ?? 'maintain';
        _targetWeight = response['target_weight']?.toString() ?? response['weight']?.toString() ?? _weight;
        
        // Valeurs nutritionnelles
        _caloriesTarget = response['daily_calories'] ?? 2200;
        _proteinTarget = response['daily_protein'] ?? 150;
        _carbsTarget = response['daily_carbs'] ?? 200;
        _fatTarget = response['daily_fat'] ?? 80;
        
        // Macros personnalisées depuis l'historique si disponible
        if (historyResponse != null) {
          _hasCustomMacros = historyResponse['has_custom_macros'] ?? false;
          _proteinPercentage = historyResponse['protein_percentage'] ?? 0.30;
          _carbsPercentage = historyResponse['carbs_percentage'] ?? 0.40;
          _fatPercentage = historyResponse['fat_percentage'] ?? 0.30;
        }
        
        // Restrictions alimentaires
        _dietaryRestrictions = List<String>.from(response['dietary_restrictions'] ?? []);
      });
      
      // Charger les préférences locales depuis SharedPreferences
      await _loadLocalPreferences();
      
    } catch (e) {
      print('Erreur lors du chargement des paramètres depuis Supabase: $e');
      // En cas d'erreur, charger depuis SharedPreferences
      await _loadFromSharedPreferences();
    }
  }
  
  Future<void> _loadLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Préférences locales (non stockées dans Supabase)
      _dailyReminder = prefs.getBool('daily_reminder') ?? true;
      _workoutReminder = prefs.getBool('workout_reminder') ?? true;
      _mealReminder = prefs.getBool('meal_reminder') ?? true;
      _progressNotifications = prefs.getBool('progress_notifications') ?? true;
      _reminderTime = prefs.getString('reminder_time') ?? '08:00';
      
      _language = prefs.getString('language') ?? 'Français';
      _measurementUnit = prefs.getString('measurement_unit') ?? 'Métrique';
      _startWeekDay = prefs.getString('start_week_day') ?? 'Lundi';
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _soundEffects = prefs.getBool('sound_effects') ?? true;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
    });
  }
  
  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Charger les données depuis SharedPreferences (fallback)
      _gender = prefs.getString('user_gender') ?? 'Homme';
      _age = prefs.getString('user_age') ?? '25';
      _height = prefs.getString('user_height') ?? '175';
      _weight = prefs.getString('user_weight') ?? '70';
      
      _activityLevel = prefs.getString('user_activity') ?? 'moderate';
      _mainGoal = prefs.getString('user_goal') ?? 'maintain';
      _targetWeight = prefs.getString('target_weight') ?? _weight;
      _proteinTarget = prefs.getInt('protein_target') ?? 150;
      _carbsTarget = prefs.getInt('carbs_target') ?? 200;
      _fatTarget = prefs.getInt('fat_target') ?? 80;
      _caloriesTarget = prefs.getInt('calories_target') ?? 2200;
      
      _hasCustomMacros = prefs.getBool('has_custom_macros') ?? false;
      _proteinPercentage = prefs.getDouble('protein_percentage') ?? 0.30;
      _carbsPercentage = prefs.getDouble('carbs_percentage') ?? 0.40;
      _fatPercentage = prefs.getDouble('fat_percentage') ?? 0.30;
      
      _dailyReminder = prefs.getBool('daily_reminder') ?? true;
      _workoutReminder = prefs.getBool('workout_reminder') ?? true;
      _mealReminder = prefs.getBool('meal_reminder') ?? true;
      _progressNotifications = prefs.getBool('progress_notifications') ?? true;
      _reminderTime = prefs.getString('reminder_time') ?? '08:00';
      
      _language = prefs.getString('language') ?? 'Français';
      _measurementUnit = prefs.getString('measurement_unit') ?? 'Métrique';
      _startWeekDay = prefs.getString('start_week_day') ?? 'Lundi';
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _soundEffects = prefs.getBool('sound_effects') ?? true;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
      
      _dietaryRestrictions = prefs.getStringList('dietary_restrictions') ?? [];
    });
  }
  
  Future<void> _saveSettings() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId != null) {
        // Calculer le BMR si les données ont changé
        final bmr = MetabolicCalculations.calculateBMR(_userProfile);
        
        // Sauvegarder dans Supabase
        await supabase.from('users').update({
          'gender': _gender,
          'age': int.tryParse(_age) ?? 25,
          'height': double.tryParse(_height) ?? 175,
          'weight': double.tryParse(_weight) ?? 70,
          'target_weight': double.tryParse(_targetWeight) ?? double.tryParse(_weight) ?? 70,
          'activity_level': _activityLevel,
          'fitness_goal': _mainGoal,
          'daily_calories': _caloriesTarget,
          'daily_protein': _proteinTarget,
          'daily_carbs': _carbsTarget,
          'daily_fat': _fatTarget,
          'bmr': bmr,
          'dietary_restrictions': _dietaryRestrictions,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
        
        // Si les macros sont personnalisées, les sauvegarder dans l'historique
        if (_hasCustomMacros) {
          await supabase.from('user_profile_history').update({
            'has_custom_macros': _hasCustomMacros,
            'protein_percentage': _proteinPercentage,
            'carbs_percentage': _carbsPercentage,
            'fat_percentage': _fatPercentage,
          }).eq('user_id', userId).eq('is_current', true);
        }
      }
      
      // Sauvegarder aussi localement pour la synchronisation
      await _saveToSharedPreferences();
      
    } catch (e) {
      print('Erreur lors de la sauvegarde dans Supabase: $e');
      // En cas d'erreur, sauvegarder localement
      await _saveToSharedPreferences();
      
      // Afficher une erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sauvegarde. Les modifications sont enregistrées localement.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  Future<void> _saveToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Sauvegarder toutes les préférences localement
    await prefs.setString('user_gender', _gender);
    await prefs.setString('user_age', _age);
    await prefs.setString('user_height', _height);
    await prefs.setString('user_weight', _weight);
    
    await prefs.setString('user_activity', _activityLevel);
    await prefs.setString('user_goal', _mainGoal);
    await prefs.setString('target_weight', _targetWeight);
    await prefs.setInt('protein_target', _proteinTarget);
    await prefs.setInt('carbs_target', _carbsTarget);
    await prefs.setInt('fat_target', _fatTarget);
    await prefs.setInt('calories_target', _caloriesTarget);
    
    await prefs.setBool('has_custom_macros', _hasCustomMacros);
    await prefs.setDouble('protein_percentage', _proteinPercentage);
    await prefs.setDouble('carbs_percentage', _carbsPercentage);
    await prefs.setDouble('fat_percentage', _fatPercentage);
    
    await prefs.setBool('daily_reminder', _dailyReminder);
    await prefs.setBool('workout_reminder', _workoutReminder);
    await prefs.setBool('meal_reminder', _mealReminder);
    await prefs.setBool('progress_notifications', _progressNotifications);
    await prefs.setString('reminder_time', _reminderTime);
    
    await prefs.setString('language', _language);
    await prefs.setString('measurement_unit', _measurementUnit);
    await prefs.setString('start_week_day', _startWeekDay);
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setBool('sound_effects', _soundEffects);
    await prefs.setBool('haptic_feedback', _hapticFeedback);
    
    await prefs.setStringList('dietary_restrictions', _dietaryRestrictions);
  }
  
  void _toggleSection(String section) {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    setState(() {
      _expandedSections[section] = !(_expandedSections[section] ?? false);
    });
  }
  
  // Méthodes de calcul basées sur l'onboarding
  UserProfile get _userProfile => UserProfile(
    gender: _gender,
    age: _age,
    weight: _weight,
    height: _height,
    activity: _activityLevel,
    goal: _mainGoal,
    obstacles: [],
    restrictions: _dietaryRestrictions,
  );
  
  void _recalculateNutrition() async {
    if (_hapticFeedback) HapticFeedback.mediumImpact();
    
    // Calculer les nouvelles valeurs basées sur le profil actuel
    final calories = MetabolicCalculations.calculateDailyGoal(_userProfile);
    final macros = MetabolicCalculations.calculateMacros(_userProfile);
    
    // Initialiser les pourcentages selon l'objectif
    _initializeMacroPercentages(_mainGoal);
    
    // Mettre à jour les valeurs
    setState(() {
      _caloriesTarget = calories;
      _proteinTarget = macros['protein'] ?? 150;
      _carbsTarget = macros['carbs'] ?? 200;
      _fatTarget = macros['fat'] ?? 80;
      _hasCustomMacros = false; // Reset custom macros
    });
    
    await _saveSettings();
    
    // Afficher le bottom sheet pour permettre la personnalisation
    _showMacroEditModal(context, calories);
  }
  
  void _initializeMacroPercentages(String goal) {
    switch (goal) {
      case 'lose':
        _proteinPercentage = 0.35;
        _carbsPercentage = 0.30;
        _fatPercentage = 0.35;
        break;
      case 'gain':
        _proteinPercentage = 0.25;
        _carbsPercentage = 0.50;
        _fatPercentage = 0.25;
        break;
      case 'maintain':
      default:
        _proteinPercentage = 0.30;
        _carbsPercentage = 0.40;
        _fatPercentage = 0.30;
        break;
    }
  }
  
  Map<String, int> _calculateCustomMacros(int calories) {
    return {
      'protein': ((calories * _proteinPercentage) / 4).round(),
      'carbs': ((calories * _carbsPercentage) / 4).round(),
      'fat': ((calories * _fatPercentage) / 9).round(),
    };
  }
  
  String _getCurrentPreset() {
    if (_proteinPercentage == 0.35 && _carbsPercentage == 0.30 && _fatPercentage == 0.35) {
      return 'Perte de poids';
    } else if (_proteinPercentage == 0.25 && _carbsPercentage == 0.50 && _fatPercentage == 0.25) {
      return 'Prise de masse';
    } else if (_proteinPercentage == 0.30 && _carbsPercentage == 0.40 && _fatPercentage == 0.30) {
      return 'Équilibré';
    } else {
      return 'Personnalisé';
    }
  }
  
  String _getCurrentPresetKey() {
    const tolerance = 0.02; // Tolérance de 2%
    
    // Équilibré (30-40-30)
    if ((_proteinPercentage - 0.30).abs() < tolerance &&
        (_carbsPercentage - 0.40).abs() < tolerance &&
        (_fatPercentage - 0.30).abs() < tolerance) {
      return 'equilibre';
    }
    
    // Perte (35-30-35)
    if ((_proteinPercentage - 0.35).abs() < tolerance &&
        (_carbsPercentage - 0.30).abs() < tolerance &&
        (_fatPercentage - 0.35).abs() < tolerance) {
      return 'perte';
    }
    
    // Prise (25-50-25)
    if ((_proteinPercentage - 0.25).abs() < tolerance &&
        (_carbsPercentage - 0.50).abs() < tolerance &&
        (_fatPercentage - 0.25).abs() < tolerance) {
      return 'prise';
    }
    
    return ''; // Aucun preset correspondant
  }
  
  void _showMacroEditModal(BuildContext context, int baseCalories) {
    // Variables temporaires pour les modifications
    double tempProtein = _proteinPercentage;
    double tempCarbs = _carbsPercentage;
    double tempFat = _fatPercentage;
    int tempCalories = _caloriesTarget;
    String selectedPreset = _getCurrentPresetKey(); // Utiliser les clés de l'onboarding
    
    final TextEditingController caloriesController = TextEditingController(
      text: tempCalories.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Calculer les grammes en temps réel
          Map<String, int> tempMacros = {
            'protein': ((tempCalories * tempProtein) / 4).round(),
            'carbs': ((tempCalories * tempCarbs) / 4).round(),
            'fat': ((tempCalories * tempFat) / 9).round(),
          };

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
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
                                  const Text(
                                    'Objectif calorique quotidien',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: caloriesController,
                                keyboardType: TextInputType.number,
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
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Recommandé: $baseCalories kcal',
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
                        const Text(
                          'Répartition des macronutriments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        // Protéines
                        _buildMacroSliderOnboarding(
                          name: 'Protéines',
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
                        _buildMacroSliderOnboarding(
                          name: 'Glucides',
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
                        _buildMacroSliderOnboarding(
                          name: 'Lipides',
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
                        const Text(
                          'Répartitions prédéfinies',
                          style: TextStyle(
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
                                'Équilibré',
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
                                'Perte',
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
                                'Prise',
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
                          child: const Text(
                            'Annuler',
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
                          onPressed: () async {
                            setState(() {
                              _caloriesTarget = tempCalories;
                              _proteinPercentage = tempProtein;
                              _carbsPercentage = tempCarbs;
                              _fatPercentage = tempFat;
                              _hasCustomMacros = true;
                              
                              // Recalculer les macros en grammes
                              final newMacros = _calculateCustomMacros(tempCalories);
                              _proteinTarget = newMacros['protein']!;
                              _carbsTarget = newMacros['carbs']!;
                              _fatTarget = newMacros['fat']!;
                            });
                            
                            await _saveSettings();
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B132B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Appliquer',
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
  }
  
  Widget _buildMacroSliderOnboarding({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bandeau bleu comme les autres pages
            _buildHeader(),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Section Profil
                    _buildExpandableSection(
                      key: 'profile',
                      icon: LucideIcons.user,
                      title: 'Profil',
                      subtitle: '$_age ans, $_weight kg, $_height cm',
                      children: [
                        _buildSectionContent(
                          child: Column(
                            children: [
                              _buildInputRow(
                                label: 'Genre',
                                child: _buildSegmentedControl(
                                  value: _gender,
                                  options: ['Homme', 'Femme', 'Autre'],
                                  onChanged: (value) {
                                    setState(() => _gender = value);
                                    _saveSettings();
                                  },
                                ),
                              ),
                              _buildInputRow(
                                label: 'Âge',
                                child: _buildNumberField(
                                  value: _age,
                                  suffix: 'ans',
                                  onChanged: (value) {
                                    _age = value;
                                    _saveSettings();
                                  },
                                ),
                              ),
                              _buildInputRow(
                                label: 'Taille',
                                child: _buildNumberField(
                                  value: _height,
                                  suffix: 'cm',
                                  onChanged: (value) {
                                    _height = value;
                                    _saveSettings();
                                  },
                                ),
                              ),
                              _buildInputRow(
                                label: 'Poids',
                                child: _buildNumberField(
                                  value: _weight,
                                  suffix: 'kg',
                                  decimal: true,
                                  onChanged: (value) {
                                    _weight = value;
                                    _saveSettings();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Section Objectifs
                    _buildExpandableSection(
                      key: 'objectives',
                      icon: LucideIcons.target,
                      title: 'Objectifs',
                      subtitle: _getGoalSummary(),
                      children: [
                        _buildSectionContent(
                          child: Column(
                            children: [
                              // Objectif calorique quotidien en haut
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Objectif calorique quotidien',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  Text(
                                    '$_caloriesTarget kcal',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0B132B),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Bilan nutritionnel style onboarding
                              _buildNutritionPlan(),
                              
                              const SizedBox(height: 20),
                              
                              // Bouton de recalcul
                              _buildRecalculateButton(),
                              
                              const SizedBox(height: 20),
                              
                              // Niveau d'activité compact
                              _buildCompactActivitySelector(),
                              
                              const SizedBox(height: 16),
                              
                              // Objectif principal compact
                              _buildCompactGoalSelector(),
                              
                              if (_mainGoal != 'maintain') ...[
                                const SizedBox(height: 16),
                                _buildInputRow(
                                  label: 'Poids cible',
                                  child: _buildNumberField(
                                    value: _targetWeight,
                                    suffix: 'kg',
                                    decimal: true,
                                    onChanged: (value) {
                                      _targetWeight = value;
                                      _saveSettings();
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Section Notifications
                    _buildExpandableSection(
                      key: 'notifications',
                      icon: LucideIcons.bell,
                      title: 'Notifications',
                      subtitle: _getNotificationSummary(),
                      children: [
                        _buildSectionContent(
                          child: Column(
                            children: [
                              _buildSwitchTile(
                                title: 'Rappel quotidien',
                                subtitle: 'Rappel pour vos objectifs du jour',
                                value: _dailyReminder,
                                onChanged: (value) {
                                  setState(() => _dailyReminder = value);
                                  _saveSettings();
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Rappel entraînement',
                                subtitle: 'Notification avant vos séances',
                                value: _workoutReminder,
                                onChanged: (value) {
                                  setState(() => _workoutReminder = value);
                                  _saveSettings();
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Rappel repas',
                                subtitle: 'Notification pour vos repas',
                                value: _mealReminder,
                                onChanged: (value) {
                                  setState(() => _mealReminder = value);
                                  _saveSettings();
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Notifications de progrès',
                                subtitle: 'Mises à jour hebdomadaires',
                                value: _progressNotifications,
                                onChanged: (value) {
                                  setState(() => _progressNotifications = value);
                                  _saveSettings();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Section Préférences
                    _buildExpandableSection(
                      key: 'preferences',
                      icon: LucideIcons.settings2,
                      title: 'Préférences',
                      subtitle: '$_language • $_measurementUnit',
                      children: [
                        _buildSectionContent(
                          child: Column(
                            children: [
                              _buildInputRow(
                                label: 'Langue',
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _language = 'Français');
                                        _saveSettings();
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: _language == 'Français' ? const Color(0xFF0B132B) : Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '🇫🇷',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _language = 'English');
                                        _saveSettings();
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: _language == 'English' ? const Color(0xFF0B132B) : Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '🇺🇸',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildInputRow(
                                label: 'Système de mesure',
                                child: _buildSegmentedControl(
                                  value: _measurementUnit,
                                  options: ['Métrique', 'Impérial'],
                                  onChanged: (value) {
                                    setState(() => _measurementUnit = value);
                                    _saveSettings();
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSwitchTile(
                                title: 'Effets sonores',
                                subtitle: 'Sons dans l\'application',
                                value: _soundEffects,
                                onChanged: (value) {
                                  setState(() => _soundEffects = value);
                                  _saveSettings();
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Retour haptique',
                                subtitle: 'Vibrations lors des interactions',
                                value: _hapticFeedback,
                                onChanged: (value) {
                                  setState(() => _hapticFeedback = value);
                                  _saveSettings();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Section Restrictions alimentaires
                    _buildExpandableSection(
                      key: 'restrictions',
                      icon: LucideIcons.utensils,
                      title: 'Restrictions alimentaires',
                      subtitle: _dietaryRestrictions.isEmpty 
                          ? 'Aucune restriction' 
                          : '${_dietaryRestrictions.length} restriction(s)',
                      children: [
                        _buildSectionContent(
                          child: Column(
                            children: [
                              'Classique',
                              'Végétarien',
                              'Végétalien',
                              'Pescetarien',
                            ].map((restriction) {
                              return _buildCheckboxTile(
                                title: restriction,
                                value: _dietaryRestrictions.contains(restriction),
                                onChanged: (value) {
                                  setState(() {
                                    if (value!) {
                                      _dietaryRestrictions.add(restriction);
                                    } else {
                                      _dietaryRestrictions.remove(restriction);
                                    }
                                  });
                                  _saveSettings();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    
                    // Section Compte
                    _buildExpandableSection(
                      key: 'account',
                      icon: LucideIcons.user,
                      title: 'Compte',
                      subtitle: 'Gestion du compte',
                      children: [
                        _buildSectionContent(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _buildListTile(
                                icon: LucideIcons.mail,
                                title: 'Email et mot de passe',
                                onTap: () {
                                  // Navigation vers page compte
                                },
                              ),
                              _buildListTile(
                                icon: LucideIcons.shield,
                                title: 'Confidentialité',
                                onTap: () {
                                  // Navigation vers page confidentialité
                                },
                              ),
                              _buildListTile(
                                icon: LucideIcons.circleHelp,
                                title: 'Aide et support',
                                onTap: () {
                                  // Navigation vers page aide
                                },
                              ),
                              _buildListTile(
                                icon: LucideIcons.info,
                                title: 'À propos',
                                onTap: () {
                                  // Navigation vers page à propos
                                },
                              ),
                              _buildListTile(
                                icon: LucideIcons.logOut,
                                title: 'Déconnexion',
                                textColor: Colors.red,
                                onTap: () async {
                                  if (_hapticFeedback) HapticFeedback.mediumImpact();
                                  
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Déconnexion'),
                                      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Déconnexion'),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirm == true && mounted) {
                                    final authService = context.read<AuthService>();
                                    await authService.signOut();
                                    
                                    if (mounted) {
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        '/login',
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Espace en bas
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bandeau streak/XP comme les autres pages
          Container(
            width: double.infinity,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBannerItem(LucideIcons.flame, '7 jours'),
                    _buildBannerSeparator(),
                    ValueListenableBuilder<GoalsSummary>(
                      valueListenable: GoalsNotifier.instance,
                      builder: (context, summary, _) {
                        return _buildBannerItem(LucideIcons.target, summary.toString());
                      },
                    ),
                    _buildBannerSeparator(),
                    _buildBannerItemWithLogo('Paramètres'),
                  ],
                ),
                Positioned(
                  left: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBannerItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }
  
  Widget _buildBannerSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('•', style: TextStyle(color: Colors.white60, fontSize: 14)),
    );
  }
  
  Widget _buildBannerItemWithLogo(String text) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/logo_seul.svg',
          width: 16,
          height: 16,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
  
  Widget _buildExpandableSection({
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final isExpanded = _expandedSections[key] ?? false;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(key),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF0B132B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.5 : 0,
                    child: const Icon(
                      LucideIcons.chevronDown,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox.shrink(),
            secondChild: Column(children: children),
            crossFadeState: isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionContent({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: child,
    );
  }
  
  Widget _buildInputRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
  
  Widget _buildSegmentedControl({
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = value == option;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0B132B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildNumberField({
    required String value,
    required String suffix,
    bool decimal = false,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              suffix,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0B132B),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A1A1A),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF0B132B),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
  
  Widget _buildListTile({
    required IconData icon,
    required String title,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: textColor ?? const Color(0xFF64748B),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF1A1A1A),
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: textColor?.withOpacity(0.5) ?? const Color(0xFF94A3B8),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
  
  
  
  Widget _buildNutritionPlan() {
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
                  LucideIcons.activity,
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
          
          const SizedBox(height: 16),
          
          // Protéines
          _buildMacroBar(
            name: 'Protéines',
            value: _proteinTarget,
            unit: 'g',
            color: const Color(0xFF0B132B),
            icon: LucideIcons.zap,
          ),
          
          const SizedBox(height: 12),
          
          // Glucides
          _buildMacroBar(
            name: 'Glucides',
            value: _carbsTarget,
            unit: 'g',
            color: const Color(0xFF1C2951),
            icon: LucideIcons.wheat,
          ),
          
          const SizedBox(height: 12),
          
          // Lipides
          _buildMacroBar(
            name: 'Lipides',
            value: _fatTarget,
            unit: 'g',
            color: const Color(0xFF64748B),
            icon: LucideIcons.droplets,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroBar({
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
        
        // Barre de progression
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
              value: 1.0, // Pleine comme dans l'onboarding
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCompactActivitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NIVEAU D\'ACTIVITÉ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            {'key': 'low', 'title': 'Peu actif'},
            {'key': 'moderate', 'title': 'Modéré'},
            {'key': 'high', 'title': 'Très actif'},
          ].map((item) {
            final isSelected = _activityLevel == item['key'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _activityLevel = item['key']!);
                  _saveSettings();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    item['title']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCompactGoalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OBJECTIF PRINCIPAL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            {'key': 'lose', 'title': 'Perte'},
            {'key': 'maintain', 'title': 'Maintien'},
            {'key': 'gain', 'title': 'Prise'},
          ].map((item) {
            final isSelected = _mainGoal == item['key'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _mainGoal = item['key']!);
                  _saveSettings();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    item['title']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildRecalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _recalculateNutrition,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B132B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(
          LucideIcons.calculator,
          size: 18,
        ),
        label: const Text(
          'Recalculer le plan nutritionnel',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  
  String _getGoalSummary() {
    String activityText;
    switch (_activityLevel) {
      case 'low':
        activityText = 'Peu actif';
        break;
      case 'high':
        activityText = 'Très actif';
        break;
      default:
        activityText = 'Modérément actif';
    }
    
    String goalText;
    switch (_mainGoal) {
      case 'lose':
        goalText = 'Perte';
        break;
      case 'gain':
        goalText = 'Prise de masse';
        break;
      default:
        goalText = 'Maintien';
    }
    
    return '$goalText • $activityText • $_caloriesTarget kcal/jour';
  }
  
  String _getNotificationSummary() {
    int activeCount = 0;
    if (_dailyReminder) activeCount++;
    if (_workoutReminder) activeCount++;
    if (_mealReminder) activeCount++;
    if (_progressNotifications) activeCount++;
    
    if (activeCount == 0) {
      return 'Toutes désactivées';
    } else if (activeCount == 4) {
      return 'Toutes activées';
    } else {
      return '$activeCount activée${activeCount > 1 ? 's' : ''}';
    }
  }
}