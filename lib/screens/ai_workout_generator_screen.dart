import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/ai_workout_generation_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../models/sport_models.dart';
import 'workout_session_screen.dart';

class AIWorkoutGeneratorScreen extends StatefulWidget {
  const AIWorkoutGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<AIWorkoutGeneratorScreen> createState() => _AIWorkoutGeneratorScreenState();
}

class _AIWorkoutGeneratorScreenState extends State<AIWorkoutGeneratorScreen> {
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
  void dispose() {
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
        });
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
    if (_generatedWorkout == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          sessionName: 'ai_workout_generated_session'.tr(LocalizationService.instance.currentLanguageCode),
          exercises: _generatedWorkout!,
          isFromProgram: true,
        ),
      ),
    );
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
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ai_workout_title'.tr(locService.currentLanguageCode),
          style: const TextStyle(
            color: Color(0xFF0B132B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _generatedWorkout == null
          ? _buildGeneratorView(isFrench)
          : _buildPreviewView(isFrench),
    );
  }

  Widget _buildGeneratorView(bool isFrench) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header avec avatar Coach Ryze - Comparaison PNG vs SVG
          Center(
            child: Column(
              children: [
                // Afficher les 2 avatars côte à côte
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Version PNG
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0B132B).withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/coach_ryze_avatar.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PNG',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),
                    // Version SVG
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0B132B).withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: SvgPicture.asset(
                              'assets/images/coach_ryze_avatar.svg',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SVG',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  isFrench ? 'Crée ta séance idéale' : 'Create your ideal workout',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isFrench
                      ? "L'IA analyse tes performances\net crée un programme personnalisé"
                      : "AI analyzes your performance\nand creates a personalized program",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

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
    );
  }

  /// Helper pour afficher les détails de l'exercice de façon compacte (colonne à droite)
  Widget _buildCompactExerciseDetails(WorkoutExercise workoutEx, bool isFrench) {
    final weights = workoutEx.sets.map((s) => s.weight).toSet().toList();
    weights.sort();

    String weightText = '';
    if (weights.isNotEmpty && weights.first > 0) {
      if (weights.length == 1) {
        weightText = '🏋️ ${weights.first.toStringAsFixed(weights.first.truncateToDouble() == weights.first ? 0 : 1)}kg';
      } else {
        final minWeight = weights.first;
        final maxWeight = weights.last;
        weightText = '🏋️ ${minWeight.toStringAsFixed(minWeight.truncateToDouble() == minWeight ? 0 : 1)}-${maxWeight.toStringAsFixed(maxWeight.truncateToDouble() == maxWeight ? 0 : 1)}kg';
      }
    }

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
        if (weightText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            weightText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
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
        weightText = '${weights.first.toStringAsFixed(weights.first.truncateToDouble() == weights.first ? 0 : 1)} kg';
      } else {
        // Plusieurs poids différents
        final minWeight = weights.first;
        final maxWeight = weights.last;
        weightText = '${minWeight.toStringAsFixed(minWeight.truncateToDouble() == minWeight ? 0 : 1)} - ${maxWeight.toStringAsFixed(maxWeight.truncateToDouble() == maxWeight ? 0 : 1)} kg';
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
                // Titre des exercices générés
                Text(
                  isFrench
                      ? '${_generatedWorkout!.length} exercices'
                      : '${_generatedWorkout!.length} exercises',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des exercices (compacte)
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
                        // Numéro
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
                        const SizedBox(width: 8),
                        // Détails à droite
                        _buildCompactExerciseDetails(workoutEx, isFrench),
                      ],
                    ),
                  );
                }).toList(),

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
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _generatedWorkout = null;
                      _aiSuggestions = null;
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
}
