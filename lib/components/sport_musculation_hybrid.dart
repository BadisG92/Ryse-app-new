import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'ui/custom_card.dart';
import 'ui/workout_widgets.dart';
import 'ui/exercise_sets_widget.dart';
import '../models/sport_models.dart';
import '../bottom_sheets/program_selection_bottom_sheet.dart';
import '../screens/workout_session_screen.dart';
import '../screens/ai_workout_generator_screen.dart';
import '../services/workout_service.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';

class SportMusculationHybrid extends StatefulWidget {
  const SportMusculationHybrid({super.key});

  @override
  State<SportMusculationHybrid> createState() => _SportMusculationHybridState();
}

class _SportMusculationHybridState extends State<SportMusculationHybrid> {
  bool _isSessionActive = false;
  bool _isSessionCompleted = false;
  WorkoutSession? _currentSession;
  List<WorkoutExercise> _currentExercises = [];
  bool _isFromProgram = false;

  final WorkoutService _workoutService = WorkoutService();

  // Clé unique pour forcer le rafraîchissement des sections
  Key _refreshKey = UniqueKey();

  void _refreshPage() {
    setState(() {
      _refreshKey = UniqueKey();
    });
    debugPrint('🔄 Page musculation rafraîchie');
  }

  List<String> _getSessionTypes(String languageCode) {
    return [
      'workout_upper_body'.tr(languageCode),
      'workout_lower_body'.tr(languageCode),
      'workout_full_body'.tr(languageCode),
    ];
  }

  Widget _buildSessionTypeButtons() {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'workout_session_type'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 16),

              // Grille 1x3 avec les 3 boutons
              Row(
                children: [
                  // Bouton séance manuelle
                  Expanded(
                    child: _buildSessionTypeButton(
                      icon: LucideIcons.pencil,
                      title: 'workout_manual_session'.tr(locService.currentLanguageCode),
                      subtitle: '',
                      onTap: _showManualSessionFlow,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Bouton séance guidée
                  Expanded(
                    child: _buildSessionTypeButton(
                      icon: LucideIcons.bookOpen,
                      title: 'workout_guided_session'.tr(locService.currentLanguageCode),
                      subtitle: '',
                      onTap: _showProgramsModal,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Bouton Coach Ryze (avec logo SVG)
                  Expanded(
                    child: _buildCoachRyzeButton(
                      title: locService.isFrench ? 'Coach Ryze' : 'Coach Ryze',
                      onTap: _navigateToAIWorkoutGenerator,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTypeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachRyzeButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none, // Permet à la bulle de sortir du bouton
          children: [
            // Bouton principal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/logo_solo.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: Text(
                        'Coach\nRyze',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bulle "For you" positionnée au-dessus
            Positioned(
              top: -10, // Moitié sur le bouton, moitié en dehors
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B), // Couleur principale de l'app (bleu marine)
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B132B).withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  locService.currentLanguageCode == 'fr' ? 'Pour toi' : 'For you',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Bloc "Cette semaine" (FACTORISÉ)
            WeeklyStatsSection(key: ValueKey('weekly_$_refreshKey')),

            const SizedBox(height: 16),
            
            // 2. Bloc principal "Types de séance" (2 boutons côte à côte)
            if (!_isSessionActive && !_isSessionCompleted) ...[
              _buildSessionTypeButtons(),
              const SizedBox(height: 16),
            ],
            
            // 3. Bloc "Suivi de séance en cours" (HYBRIDE - Card factorisée, logique intégrée)
            if (_isSessionActive && _currentSession != null) ...[
              SessionTrackingCard(
                sessionName: _currentSession!.name,
                sessionStartTime: _currentSession!.startTime,
                currentExercises: _convertExercisesToMap(),
                onComplete: _completeSession,
              ),
              const SizedBox(height: 16),
              _buildSessionExercises(),
              const SizedBox(height: 16),
            ],
            
            // 4. Bloc "Récapitulatif post-séance" (INTÉGRÉ - logique spécifique)
            if (_isSessionCompleted) ...[
              _buildSessionSummary(),
              const SizedBox(height: 16),
            ],
            
            // 5. Bloc "Historique de la semaine" (FACTORISÉ)
            WeekHistorySection(key: ValueKey('history_$_refreshKey')),

            const SizedBox(height: 16),

            // 6. Bloc "Progression par exercice" (FACTORISÉ)
            ExerciseProgressSection(key: ValueKey('progress_$_refreshKey')),
            
            // Padding bottom
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // SECTION INTÉGRÉE : Bottom sheets et logique de session (complexité élevée, spécifique)
  void _showSessionChoiceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<LocalizationService>(
        builder: (context, locService, _) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'workout_new_session'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Options
                _buildSessionChoiceButton(
                  icon: LucideIcons.pencil,
                  title: 'workout_create_manually'.tr(locService.currentLanguageCode),
                  subtitle: 'workout_create_manually_desc'.tr(locService.currentLanguageCode),
                  onTap: () {
                    Navigator.pop(context);
                    _showManualSessionFlow();
                  },
                ),
                
                const SizedBox(height: 12),
                
                _buildSessionChoiceButton(
                  icon: LucideIcons.bookOpen,
                  title: 'workout_choose_program'.tr(locService.currentLanguageCode),
                  subtitle: 'workout_choose_program_desc'.tr(locService.currentLanguageCode),
                  onTap: () {
                    Navigator.pop(context);
                    _showProgramsModal();
                  },
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionChoiceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
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
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualSessionFlow() {
    _showSessionNameModal();
  }

  void _navigateToAIWorkoutGenerator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIWorkoutGeneratorScreen(),
      ),
    ).then((_) {
      // Rafraîchir la page au retour
      _refreshPage();
    });
  }

  void _showSessionNameModal() {
    final TextEditingController nameController = TextEditingController();
    final locService = LocalizationService.instance;
    nameController.text = 'workout_default_session_name'.tr(locService.currentLanguageCode)
        .replaceAll('{day}', '${DateTime.now().day}')
        .replaceAll('{month}', '${DateTime.now().month}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'workout_session_name'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'workout_session_name_hint'.tr(locService.currentLanguageCode),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startSession(nameController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'workout_start_session'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProgramsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgramSelectionBottomSheet(
        onProgramSelected: (program) => _startSessionFromProgram(program),
        customPrograms: _workoutService.customPrograms,
      ),
    );
  }

  void _startSession(String name) {
    // Naviguer vers l'écran de session en plein écran avec une liste vide
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          sessionName: name,
          exercises: [], // Liste vide pour session manuelle
          isFromProgram: false,
          guidedTemplateId: null,
          onProgramSaved: (WorkoutProgram program) {
            _workoutService.addProgram(program);
            setState(() {}); // Rafraîchir l'UI
          },
          onSessionCompleted: (WorkoutSession session) {
            print('Session reçue: ${session.name} - ${session.duration.inMinutes}min - Complétée: ${session.isCompleted}');
            // Ici on pourrait ajouter la session à un historique
          },
        ),
      ),
    ).then((_) {
      // Rafraîchir la page au retour de la séance
      _refreshPage();
    });
  }

  void _startSessionFromProgram(WorkoutProgram program) {
    // Convertir les exercices du programme en WorkoutExercise avec séries vides
    final programExercises = program.exercises.map((programExercise) {
      return WorkoutExercise(
        exercise: programExercise.exercise,
        sets: List.generate(
          programExercise.sets,
          (index) => const ExerciseSet(reps: 0, weight: 0),
        ),
        suggestedRepsMin: programExercise.suggestedRepsMin,
        suggestedRepsMax: programExercise.suggestedRepsMax,
      );
    }).toList();

    // Naviguer vers l'écran de session en plein écran
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          sessionName: program.name,
          exercises: programExercises,
          isFromProgram: true,
          guidedTemplateId: program.id,
        ),
      ),
    ).then((_) {
      // Rafraîchir la page au retour de la séance
      _refreshPage();
    });
  }

  void _completeSession() {
    // Si c'est une séance manuelle, proposer de la sauvegarder
    if (!_isFromProgram && _currentExercises.isNotEmpty) {
      _showSaveAsCustomProgramDialog();
    }
    
    setState(() {
      _isSessionActive = false;
      _isSessionCompleted = true;
    });
  }

  // SECTION INTÉGRÉE : Exercices de session (logique complexe, état partagé)
  Widget _buildSessionExercises() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'workout_session_exercises'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_currentExercises.isEmpty)
              Center(
                child: Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'workout_no_exercises_added'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _currentExercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final workoutExercise = entry.value;
                  return ExerciseSetsWidget(
                    workoutExercise: workoutExercise,
                    onSetUpdated: (setIndex, updatedSet) => _updateSet(index, setIndex, updatedSet),
                    onAddSet: () => _addSet(index),
                    onRemoveSet: (setIndex) => _removeSet(index, setIndex),
                    onRemoveExercise: () => _removeExercise(index),
                    initiallyExpanded: !_isFromProgram,
                  );
                }).toList(),
              ),

            // NOTE: Le bouton "Ajouter un exercice" n'est plus ici car l'utilisateur
            // est redirigé vers WorkoutSessionScreen pour gérer les exercices
          ],
        ),
      ),
    );
  }

  // NOTE: Cette méthode n'est plus utilisée - le bottom sheet d'exercices
  // est maintenant directement dans WorkoutSessionScreen
  /*
  void _showExerciseSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseSelectionBottomSheet(
        onExerciseSelected: (exercise, sets) => _addExerciseFromDatabase(exercise, sets),
        onCustomExerciseCreated: (name, sets) => _addCustomExercise(name, sets),
      ),
    );
  }
  */

  void _addExerciseFromDatabase(Exercise exercise, int setsCount) {
    final workoutExercise = WorkoutExercise(
      exercise: exercise,
      sets: List.generate(setsCount, (index) => const ExerciseSet(reps: 0, weight: 0)),
    );
    
    setState(() {
      _currentExercises.add(workoutExercise);
    });
  }

  void _addCustomExercise(String name, int setsCount) {
    final customExercise = Exercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      muscleGroup: 'workout_custom_group'.tr(LocalizationService.instance.currentLanguageCode),
      isCustom: true,
    );
    
    final workoutExercise = WorkoutExercise(
      exercise: customExercise,
      sets: List.generate(setsCount, (index) => const ExerciseSet(reps: 0, weight: 0)),
    );
    
    setState(() {
      _currentExercises.add(workoutExercise);
    });
  }

  void _updateSet(int exerciseIndex, int setIndex, ExerciseSet updatedSet) {
    setState(() {
      final currentSets = List<ExerciseSet>.from(_currentExercises[exerciseIndex].sets);
      currentSets[setIndex] = updatedSet;
      _currentExercises[exerciseIndex] = _currentExercises[exerciseIndex].copyWith(sets: currentSets);
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final currentSets = List<ExerciseSet>.from(_currentExercises[exerciseIndex].sets);
      currentSets.add(const ExerciseSet(reps: 0, weight: 0));
      _currentExercises[exerciseIndex] = _currentExercises[exerciseIndex].copyWith(sets: currentSets);
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      final currentSets = List<ExerciseSet>.from(_currentExercises[exerciseIndex].sets);
      if (currentSets.length > 1) {
        currentSets.removeAt(setIndex);
        _currentExercises[exerciseIndex] = _currentExercises[exerciseIndex].copyWith(sets: currentSets);
      }
    });
  }

  void _removeExercise(int exerciseIndex) {
    setState(() {
      _currentExercises.removeAt(exerciseIndex);
    });
  }

  void _showSaveAsCustomProgramDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'workout_save_session_title'.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          content: Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'workout_save_session_message'.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
              ),
              child: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_no'.tr(locService.currentLanguageCode),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveCurrentSessionAsProgram();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B132B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_yes'.tr(locService.currentLanguageCode),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveCurrentSessionAsProgram() {
    // Convertir la séance actuelle en programme
    final duration = DateTime.now().difference(_currentSession!.startTime);
    
    final newProgram = WorkoutProgram(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _currentSession!.name,
      description: 'workout_program_from_session_desc'.tr(LocalizationService.instance.currentLanguageCode),
      type: 'workout_custom_type'.tr(LocalizationService.instance.currentLanguageCode),
      estimatedDuration: duration.inMinutes,
      exercises: _currentExercises.map((workoutExercise) {
        return ProgramExercise(
          exercise: workoutExercise.exercise,
          sets: workoutExercise.sets.length,
        );
      }).toList(),
    );

    _workoutService.addProgram(newProgram);
    setState(() {});

    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('workout_session_saved_message'.tr(LocalizationService.instance.currentLanguageCode)),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  // Fonction de conversion pour la compatibilité avec SessionTrackingCard
  List<Map<String, dynamic>> _convertExercisesToMap() {
    return _currentExercises.map((workoutExercise) {
      return {
        'name': workoutExercise.exercise.name,
        'sets': workoutExercise.sets.map((set) {
          return {
            'reps': set.reps,
            'weight': set.weight,
            'completed': set.isCompleted,
          };
        }).toList(),
      };
    }).toList();
  }

  // SECTION INTÉGRÉE : Récapitulatif de session (logique spécifique)
  Widget _buildSessionSummary() {
    final duration = DateTime.now().difference(_currentSession!.startTime);
    final totalSets = _currentExercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets.length,
    );
    final completedSets = _currentExercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets.where((set) => set.isCompleted).length,
    );
    
    // Calcul des kilos soulevés (poids × répétitions pour les séries terminées)
    final totalWeight = _currentExercises.fold<double>(
      0.0,
      (sum, exercise) => sum + exercise.sets
          .where((set) => set.isCompleted)
          .fold<double>(0.0, (setSum, set) => setSum + (set.weight * set.reps)),
    );
    
    // Calcul approximatif des calories (0.35 kcal par kg soulevé + métabolisme de base selon durée)
    final calories = (totalWeight * 0.35) + (duration.inMinutes * 5.0);
    final caloriesInt = calories.round();

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'workout_session_completed'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => _buildSummaryItem(
                      'workout_duration'.tr(locService.currentLanguageCode),
                      '${duration.inMinutes} min',
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => _buildSummaryItem(
                      'workout_exercises'.tr(locService.currentLanguageCode),
                      '${_currentExercises.length}',
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => _buildSummaryItem(
                      'workout_sets'.tr(locService.currentLanguageCode),
                      '$completedSets/$totalSets',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Nouvelle ligne avec kilos soulevés et calories
            Row(
              children: [
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => _buildSummaryItem(
                      'workout_weight_lifted'.tr(locService.currentLanguageCode),
                      '${totalWeight.toInt()} kg',
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => _buildSummaryItem(
                      'workout_calories_burned'.tr(locService.currentLanguageCode),
                      '$caloriesInt kcal',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isSessionCompleted = false;
                        _currentExercises.clear();
                        _currentSession = null;
                        _isFromProgram = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B132B),
                      side: const BorderSide(color: Color(0xFF0B132B)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'workout_new_session_btn'.tr(locService.currentLanguageCode),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('workout_session_recorded'.tr(LocalizationService.instance.currentLanguageCode)),
                        ),
                      );
                      setState(() {
                        _isSessionCompleted = false;
                        _currentExercises.clear();
                        _currentSession = null;
                        _isFromProgram = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'workout_save'.tr(locService.currentLanguageCode),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
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
} 
