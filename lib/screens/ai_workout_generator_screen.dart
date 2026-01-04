import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/ai_workout_generation_service.dart';
import '../services/localization_service.dart';
import '../services/offline_workout_service.dart';
import '../services/translations.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/feature_trial_service.dart';
import '../services/unit_service.dart';
import '../models/sport_models.dart';
import '../components/ui/coach_ryze_avatar.dart';
import '../bottom_sheets/exercise_info_bottom_sheet.dart';
import 'workout_session_screen.dart';

class AIWorkoutGeneratorScreen extends StatefulWidget {
  const AIWorkoutGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<AIWorkoutGeneratorScreen> createState() => _AIWorkoutGeneratorScreenState();
}

class _AIWorkoutGeneratorScreenState extends State<AIWorkoutGeneratorScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  String? _selectedChip;
  bool _showParams = false;
  int _duration = 45;
  double _intensity = 0.5;
  String _focus = 'Hypertrophie';
  List<String> _equipment = ['Haltères', 'Barre'];
  bool _isGenerating = false;
  List<WorkoutExercise>? _generatedWorkout;
  String? _aiSuggestions;
  String? _errorMessage;
  bool _isEditMode = false; // Mode édition du plan
  String _sessionName = ''; // Nom de la séance généré automatiquement

  // Animation du panda
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 8 chips de suggestions rapides
  final List<Map<String, String>> _quickChips = [
    {'label_fr': 'Haut du corps', 'label_en': 'Upper body', 'emoji': '💪'},
    {'label_fr': 'Jambes', 'label_en': 'Legs', 'emoji': '🦵'},
    {'label_fr': 'Full body', 'label_en': 'Full body', 'emoji': '🏋️'},
    {'label_fr': 'Push', 'label_en': 'Push', 'emoji': '🔥'},
    {'label_fr': 'Pull', 'label_en': 'Pull', 'emoji': '💙'},
    {'label_fr': 'Abdos/Core', 'label_en': 'Abs/Core', 'emoji': '🎯'},
    {'label_fr': 'Bras', 'label_en': 'Arms', 'emoji': '💪'},
    {'label_fr': 'Circuit training', 'label_en': 'Circuit training', 'emoji': '🔥'},
  ];

  @override
  void initState() {
    super.initState();

    // Initialiser l'animation du panda
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0), // Vient de la droite
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Démarrer l'animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool get _canGenerate =>
      _selectedChip != null || _textController.text.trim().isNotEmpty;

  Future<void> _generateWorkout() async {
    if (!_canGenerate) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedWorkout = null;
    });

    try {
      final locService = LocalizationService.instance;
      final userRequest = _textController.text.trim().isNotEmpty
          ? _textController.text.trim()
          : _selectedChip!;

      final result = await AIWorkoutGenerationService.generateWorkout(
        userRequest: userRequest,
        durationMinutes: _duration,
        intensity: _intensity,
        focus: _focus,
        equipment: _equipment,
      );

      if (result.success && result.exercises.isNotEmpty) {
        setState(() {
          _generatedWorkout = result.exercises;
          _aiSuggestions = result.aiSuggestions;
          _sessionName = _generateSessionName(result.exercises, locService.isFrench);
        });

        // ✅ Marquer le trial comme utilisé UNIQUEMENT si le workout a été généré avec succès
        if (!SubscriptionService.instance.isPremium) {
          FeatureTrialService.instance.markFeatureAsUsed(
            FeatureTrialService.keyWorkout,
          );
          if (kDebugMode) debugPrint('✅ Workout Generator trial marked as used after successful generation');
        }
      } else {
        setState(() {
          _errorMessage = result.error ?? 'ai_workout_error_unknown'.tr(locService.currentLanguageCode);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _startWorkout() {
    if (_generatedWorkout == null) {
      debugPrint('❌ _startWorkout: _generatedWorkout est null!');
      return;
    }

    debugPrint('✅ _startWorkout: ${_generatedWorkout!.length} exercices');
    for (var i = 0; i < _generatedWorkout!.length; i++) {
      final ex = _generatedWorkout![i];
      debugPrint('  [$i] ${ex.exercise.name} - ${ex.sets.length} séries');
    }

    // ⚡ FIX: Use push instead of pushReplacement to preserve navigation stack
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          sessionName: _sessionName.isNotEmpty ? _sessionName : 'ai_workout_generated_session'.tr(LocalizationService.instance.currentLanguageCode),
          exercises: _generatedWorkout!,
          isFromProgram: false, // ⚡ Coach Ryze is NOT a predefined program - user chooses whether to save
          isFromAI: true, // ⚡ Marks as Coach Ryze for 3-pop navigation
        ),
      ),
    );
  }

  /// Génère un nom de séance intelligent basé sur les groupes musculaires
  String _generateSessionName(List<WorkoutExercise> exercises, bool isFrench) {
    // Compter les groupes musculaires
    final muscleGroups = <String, int>{};
    for (final ex in exercises) {
      final group = ex.exercise.muscleGroup.toLowerCase();
      muscleGroups[group] = (muscleGroups[group] ?? 0) + 1;
    }

    // Mapper vers noms français/anglais
    final muscleNamesFr = {
      'chest': 'Pectoraux',
      'pectoraux': 'Pectoraux',
      'back': 'Dos',
      'dorsaux': 'Dos',
      'legs': 'Jambes',
      'quadriceps': 'Jambes',
      'ischio-jambiers': 'Jambes',
      'hamstrings': 'Jambes',
      'shoulders': 'Épaules',
      'épaules': 'Épaules',
      'arms': 'Bras',
      'biceps': 'Bras',
      'triceps': 'Bras',
      'core': 'Core',
      'abdominaux': 'Core',
      'abs': 'Core',
      'glutes': 'Fessiers',
      'fessiers': 'Fessiers',
      'calves': 'Mollets',
      'mollets': 'Mollets',
    };

    final muscleNamesEn = {
      'chest': 'Chest',
      'pectoraux': 'Chest',
      'back': 'Back',
      'dorsaux': 'Back',
      'legs': 'Legs',
      'quadriceps': 'Legs',
      'ischio-jambiers': 'Legs',
      'hamstrings': 'Legs',
      'shoulders': 'Shoulders',
      'épaules': 'Shoulders',
      'arms': 'Arms',
      'biceps': 'Arms',
      'triceps': 'Arms',
      'core': 'Core',
      'abdominaux': 'Core',
      'abs': 'Core',
      'glutes': 'Glutes',
      'fessiers': 'Glutes',
      'calves': 'Calves',
      'mollets': 'Calves',
    };

    final nameMap = isFrench ? muscleNamesFr : muscleNamesEn;

    // Trouver les groupes dominants (>= 2 exercices)
    final dominantGroups = <String>[];
    for (final entry in muscleGroups.entries) {
      if (entry.value >= 2) {
        final normalizedName = nameMap[entry.key] ?? entry.key;
        if (!dominantGroups.contains(normalizedName)) {
          dominantGroups.add(normalizedName);
        }
      }
    }

    // Si pas de groupes dominants, prendre les 2 premiers différents
    if (dominantGroups.isEmpty) {
      final uniqueGroups = <String>[];
      for (final entry in muscleGroups.entries) {
        final normalizedName = nameMap[entry.key] ?? entry.key;
        if (!uniqueGroups.contains(normalizedName)) {
          uniqueGroups.add(normalizedName);
          if (uniqueGroups.length >= 2) break;
        }
      }
      dominantGroups.addAll(uniqueGroups);
    }

    // Construire le nom
    if (dominantGroups.isEmpty) {
      return isFrench ? 'Coach Ryze - Full Body' : 'Coach Ryze - Full Body';
    } else if (dominantGroups.length == 1) {
      return 'Coach Ryze - ${dominantGroups[0]}';
    } else if (dominantGroups.length == 2) {
      return 'Coach Ryze - ${dominantGroups[0]} + ${dominantGroups[1]}';
    } else if (dominantGroups.length >= 3) {
      return isFrench ? 'Coach Ryze - Full Body' : 'Coach Ryze - Full Body';
    }

    return isFrench ? 'Coach Ryze - Séance' : 'Coach Ryze - Workout';
  }

  /// Génère un message contextuel basé sur l'heure et l'état de l'utilisateur
  String _getContextualMessage(bool isFrench, String userName) {
    final hour = DateTime.now().hour;

    // Message selon l'heure de la journée
    if (_generatedWorkout != null) {
      // Si un workout est déjà généré
      if (isFrench) {
        return 'Ta séance est prête ! Lance-toi et donne tout 💪';
      } else {
        return 'Your workout is ready! Let\'s crush it 💪';
      }
    } else {
      // Aucun workout généré encore
      if (hour >= 5 && hour < 12) {
        return isFrench
          ? 'Prêt à commencer la journée en force ?'
          : 'Ready to start your day strong?';
      } else if (hour >= 12 && hour < 18) {
        return isFrench
          ? 'C\'est le moment parfait pour t\'entraîner !'
          : 'Perfect time for a workout!';
      } else if (hour >= 18 && hour < 22) {
        return isFrench
          ? 'Une bonne séance pour finir la journée ?'
          : 'End your day with a great session?';
      } else {
        return isFrench
          ? 'Motivé pour une séance nocturne ?'
          : 'Motivated for a late workout?';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locService = Provider.of<LocalizationService>(context);
    final isFrench = locService.isFrench;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0B132B)),
          onPressed: () {
            // Si en mode édition, sortir du mode édition au lieu de quitter
            if (_isEditMode && _generatedWorkout != null) {
              setState(() {
                _isEditMode = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'ai_workout_title'.tr(locService.currentLanguageCode),
          style: const TextStyle(
            color: Color(0xFF0B132B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Icône Modifier (seulement si workout généré)
          if (_generatedWorkout != null)
            IconButton(
              icon: Icon(
                _isEditMode ? LucideIcons.check : LucideIcons.pencil,
                color: _isEditMode ? const Color(0xFF10B981) : const Color(0xFF1C2951),
              ),
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
              tooltip: _isEditMode
                  ? (isFrench ? 'Valider' : 'Confirm')
                  : (isFrench ? 'Modifier' : 'Edit'),
            ),
        ],
      ),
      body: _generatedWorkout == null
          ? _buildGeneratorView(isFrench)
          : _buildPreviewView(isFrench),
    );
  }

  Widget _buildGeneratorView(bool isFrench) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Capitaliser le prénom (même méthode que le dashboard)
        final rawName = authService.currentUser?.firstName ?? (isFrench ? 'Champion' : 'Champion');
        final userName = rawName.isEmpty ? rawName : rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
        final greeting = isFrench ? 'Salut' : 'Hey';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header avec Coach Ryze - Design simple et unifié
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Message principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting $userName !',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B132B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isFrench
                              ? 'Prêt pour une séance sur-mesure ?'
                              : 'Ready for a custom workout?',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Avatar Coach Ryze à droite avec animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: const CoachRyzeAvatar(
                          type: CoachRyzeAvatarType.workout,
                          size: CoachRyzeAvatarSize.xxlarge, // 160px
                          withShadow: false, // Pas besoin, le container a déjà une ombre
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

          // Suggestions rapides (sans emoji)
          Row(
            children: [
              const Icon(
                LucideIcons.zap,
                size: 18,
                color: Color(0xFF0B132B),
              ),
              const SizedBox(width: 8),
              Text(
                isFrench ? 'Suggestions rapides' : 'Quick suggestions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Chips horizontaux (sans emojis)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickChips.length,
              itemBuilder: (context, index) {
                final chip = _quickChips[index];
                final label = isFrench ? chip['label_fr']! : chip['label_en']!;
                final isSelected = _selectedChip == label;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedChip = isSelected ? null : label;
                        if (_selectedChip != null) {
                          _textController.clear();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0B132B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0B132B)
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF0B132B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Séparateur "ou"
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isFrench ? 'ou' : 'or',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),

          const SizedBox(height: 24),

          // Décris ta séance (sans emoji)
          Row(
            children: [
              const Icon(
                LucideIcons.messageSquare,
                size: 18,
                color: Color(0xFF0B132B),
              ),
              const SizedBox(width: 8),
              Text(
                isFrench ? 'Décris ta séance' : 'Describe your workout',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: isFrench
                  ? 'Ex: Je veux travailler les pectoraux et les épaules'
                  : 'Ex: I want to work chest and shoulders',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
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
            ),
            onChanged: (value) {
              if (value.trim().isNotEmpty) {
                setState(() {
                  _selectedChip = null;
                });
              }
            },
          ),

          const SizedBox(height: 24),

          // Paramètres (expandable)
          GestureDetector(
            onTap: () {
              setState(() {
                _showParams = !_showParams;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.settings, size: 20, color: Color(0xFF0B132B)),
                      const SizedBox(width: 8),
                      Text(
                        isFrench ? 'Paramètres' : 'Settings',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showParams ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          if (_showParams) ...[
            const SizedBox(height: 16),
            _buildParametersSection(isFrench),
          ],

          const SizedBox(height: 32),

          // Message d'erreur
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 13, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Bouton Générer
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _canGenerate && !_isGenerating ? _generateWorkout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B132B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/logo_solo.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFrench ? 'Générer ma séance' : 'Generate my workout',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
    );
  }

  /// Helper pour afficher les détails de l'exercice de façon compacte (colonne à droite)
  Widget _buildCompactExerciseDetails(WorkoutExercise workoutEx, bool isFrench) {
    final weights = workoutEx.sets.map((s) => s.weight).toSet().toList();
    weights.sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${workoutEx.sets.length}×${workoutEx.sets.first.reps}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
        if (weights.isNotEmpty && weights.first > 0) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.dumbbell,
                size: 12,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                weights.length == 1
                    ? UnitService.instance.formatWeight(weights.first, decimals: weights.first.truncateToDouble() == weights.first ? 0 : 1)
                    : '${UnitService.instance.formatWeight(weights.first, decimals: weights.first.truncateToDouble() == weights.first ? 0 : 1).split(' ').first}-${UnitService.instance.formatWeight(weights.last, decimals: weights.last.truncateToDouble() == weights.last ? 0 : 1)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Helper pour afficher les détails de l'exercice avec poids
  Widget _buildExerciseDetails(WorkoutExercise workoutEx, bool isFrench) {
    final weights = workoutEx.sets.map((s) => s.weight).toSet().toList();
    weights.sort();

    String weightText = '';
    if (weights.isNotEmpty && weights.first > 0) {
      if (weights.length == 1) {
        // Un seul poids pour toutes les séries
        weightText = UnitService.instance.formatWeight(weights.first, decimals: weights.first.truncateToDouble() == weights.first ? 0 : 1);
      } else {
        // Plusieurs poids différents
        final minWeight = weights.first;
        final maxWeight = weights.last;
        final minDec = minWeight.truncateToDouble() == minWeight ? 0 : 1;
        final maxDec = maxWeight.truncateToDouble() == maxWeight ? 0 : 1;
        weightText = '${UnitService.instance.displayWeight(minWeight).toStringAsFixed(minDec)} - ${UnitService.instance.formatWeight(maxWeight, decimals: maxDec)}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${workoutEx.sets.length} ${isFrench ? 'séries' : 'sets'} × ${workoutEx.sets.first.reps} ${isFrench ? 'reps' : 'reps'}',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        if (weightText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.fitness_center, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                weightText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildParametersSection(bool isFrench) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Durée
          Text(
            isFrench ? 'Durée' : 'Duration',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [30, 45, 60, 90].map((duration) {
              final isSelected = _duration == duration;
              return GestureDetector(
                onTap: () => setState(() => _duration = duration),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    '${duration}min',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Intensité
          Text(
            isFrench ? 'Intensité' : 'Intensity',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          Slider(
            value: _intensity,
            onChanged: (value) => setState(() => _intensity = value),
            activeColor: const Color(0xFF0B132B),
            inactiveColor: const Color(0xFFE2E8F0),
            divisions: 2,
            label: _intensity < 0.33
                ? (isFrench ? 'Léger' : 'Light')
                : _intensity < 0.67
                    ? (isFrench ? 'Modéré' : 'Moderate')
                    : (isFrench ? 'Intense' : 'Intense'),
          ),

          const SizedBox(height: 8),

          // Focus
          Text(
            isFrench ? 'Focus' : 'Focus',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              isFrench ? 'Force' : 'Strength',
              isFrench ? 'Hypertrophie' : 'Hypertrophy',
              isFrench ? 'Endurance' : 'Endurance',
            ].map((focus) {
              final isSelected = _focus == focus;
              return GestureDetector(
                onTap: () => setState(() => _focus = focus),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    focus,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewView(bool isFrench) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom de la séance (éditable en mode édition)
                GestureDetector(
                  onTap: _isEditMode ? _showEditNameDialog : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isEditMode
                          ? const Color(0xFF1C2951).withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: _isEditMode
                          ? Border.all(color: const Color(0xFF1C2951).withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _sessionName.isNotEmpty ? _sessionName : 'Coach Ryze - Séance',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B132B),
                            ),
                          ),
                        ),
                        if (_isEditMode)
                          Icon(
                            LucideIcons.pencil,
                            size: 18,
                            color: const Color(0xFF1C2951).withOpacity(0.6),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Nombre d'exercices
                Text(
                  isFrench
                      ? '${_generatedWorkout!.length} exercices'
                      : '${_generatedWorkout!.length} exercises',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des exercices (compacte ou éditable)
                ..._generatedWorkout!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final workoutEx = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        // Mode édition : boutons haut/bas
                        if (_isEditMode) ...[
                          Column(
                            children: [
                              // Bouton monter
                              GestureDetector(
                                onTap: index > 0
                                    ? () => _moveExerciseUp(index)
                                    : null,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: index > 0
                                        ? const Color(0xFF0B132B).withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    LucideIcons.arrowUp,
                                    size: 16,
                                    color: index > 0
                                        ? const Color(0xFF0B132B)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Bouton descendre
                              GestureDetector(
                                onTap: index < _generatedWorkout!.length - 1
                                    ? () => _moveExerciseDown(index)
                                    : null,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: index < _generatedWorkout!.length - 1
                                        ? const Color(0xFF0B132B).withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    LucideIcons.arrowDown,
                                    size: 16,
                                    color: index < _generatedWorkout!.length - 1
                                        ? const Color(0xFF0B132B)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                        ] else
                          // Numéro normal (mode preview)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B132B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        // Infos exercice
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workoutEx.exercise.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                workoutEx.exercise.muscleGroup,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Icône info (seulement pour les exercices non-custom)
                        if (!workoutEx.exercise.isCustom) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              ExerciseInfoBottomSheet.show(
                                context,
                                exerciseId: workoutEx.exercise.id,
                                exerciseName: workoutEx.exercise.name,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                LucideIcons.info,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        // Mode édition : bouton supprimer
                        if (_isEditMode)
                          GestureDetector(
                            onTap: () => _removeExercise(index),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                LucideIcons.trash2,
                                size: 16,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          )
                        else
                          // Détails à droite (mode preview)
                          _buildCompactExerciseDetails(workoutEx, isFrench),
                      ],
                    ),
                  );
                }).toList(),

                // Bouton ajouter exercice (mode édition)
                if (_isEditMode) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showAddExerciseToWorkout,
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: Text(isFrench ? 'Ajouter un exercice' : 'Add exercise'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B132B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                // Conseils de Coach Ryze (style identique à l'analyse d'exercice)
                if (_aiSuggestions != null && _aiSuggestions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B132B).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header avec logo Ryze
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/logo_solo.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isFrench ? 'Conseils de Coach Ryze' : 'Coach Ryze Tips',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Contenu blanc
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _aiSuggestions!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Color(0xFF334155),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom buttons
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            children: [
              // Bouton Régénérer (toujours visible)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _generatedWorkout = null;
                      _aiSuggestions = null;
                      _isEditMode = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B132B),
                    side: const BorderSide(color: Color(0xFF0B132B)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isFrench ? 'Régénérer' : 'Regenerate',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bouton Commencer
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _startWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.play, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isFrench ? 'Commencer la séance' : 'Start workout',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================
  // EDIT MODE FUNCTIONS
  // ========================================

  void _moveExerciseUp(int index) {
    if (index == 0 || _generatedWorkout == null) return;

    setState(() {
      final workout = List<WorkoutExercise>.from(_generatedWorkout!);
      final temp = workout[index];
      workout[index] = workout[index - 1];
      workout[index - 1] = temp;
      _generatedWorkout = workout;
    });
  }

  void _moveExerciseDown(int index) {
    if (_generatedWorkout == null || index >= _generatedWorkout!.length - 1) return;

    setState(() {
      final workout = List<WorkoutExercise>.from(_generatedWorkout!);
      final temp = workout[index];
      workout[index] = workout[index + 1];
      workout[index + 1] = temp;
      _generatedWorkout = workout;
    });
  }

  void _removeExercise(int index) {
    if (_generatedWorkout == null) return;

    setState(() {
      final workout = List<WorkoutExercise>.from(_generatedWorkout!);
      workout.removeAt(index);
      _generatedWorkout = workout.isEmpty ? null : workout;

      // Si plus d'exercices, sortir du mode édition
      if (_generatedWorkout == null) {
        _isEditMode = false;
      }
    });
  }

  Future<void> _showAddExerciseToWorkout() async {
    // Utiliser le même bottom sheet que l'écran de session
    // Pour l'instant, navigation vers sélection d'exercice simple
    final locService = LocalizationService.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          locService.isFrench ? 'Ajouter un exercice' : 'Add exercise',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Note importante
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2951).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.info,
                        size: 20,
                        color: Color(0xFF1C2951),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          locService.isFrench
                              ? 'Les exercices ajoutés n\'auront pas de poids ou répétitions pré-remplis'
                              : 'Added exercises won\'t have pre-filled weight or reps',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1C2951),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste simplifiée pour sélection rapide
                Expanded(
                  child: FutureBuilder(
                    future: _loadExercisesForSelection(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final exercises = snapshot.data as List<Exercise>? ?? [];

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];

                          return GestureDetector(
                            onTap: () {
                              _addExerciseToWorkout(exercise);
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0B132B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          exercise.muscleGroup,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    LucideIcons.plus,
                                    color: Color(0xFF1C2951),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Exercise>> _loadExercisesForSelection() async {
    // Charger exercices depuis le service offline (cache)
    try {
      final offlineService = OfflineWorkoutService();
      final exercises = await offlineService.getCachedExercises();
      return exercises;
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      return [];
    }
  }

  void _addExerciseToWorkout(Exercise exercise) {
    if (_generatedWorkout == null) return;

    setState(() {
      final workout = List<WorkoutExercise>.from(_generatedWorkout!);

      // Créer un WorkoutExercise SANS reps/poids pré-remplis
      final newWorkoutExercise = WorkoutExercise(
        exercise: exercise,
        sets: [
          const ExerciseSet(weight: 0, reps: 0, isCompleted: false),
          const ExerciseSet(weight: 0, reps: 0, isCompleted: false),
          const ExerciseSet(weight: 0, reps: 0, isCompleted: false),
        ],
        suggestedRepsMin: null, // Pas de suggestions
        suggestedRepsMax: null,
      );

      workout.add(newWorkoutExercise);
      _generatedWorkout = workout;
    });
  }

  /// Affiche un dialog pour éditer le nom de la séance
  void _showEditNameDialog() {
    final locService = LocalizationService.instance;
    final TextEditingController nameController = TextEditingController(text: _sessionName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          locService.isFrench ? 'Nom de la séance' : 'Session name',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          maxLength: 50,
          decoration: InputDecoration(
            hintText: locService.isFrench ? 'Ex: Coach Ryze - Pectoraux' : 'Ex: Coach Ryze - Chest',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1C2951), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              locService.isFrench ? 'Annuler' : 'Cancel',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _sessionName = nameController.text.trim().isNotEmpty
                    ? nameController.text.trim()
                    : _sessionName;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C2951),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              locService.isFrench ? 'Valider' : 'Confirm',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
