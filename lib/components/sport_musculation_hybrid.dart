import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';
import 'ui/workout_widgets.dart';
import 'ui/exercise_sets_widget.dart';
import '../models/sport_models.dart';
import '../bottom_sheets/exercise_selection_bottom_sheet.dart';
import '../bottom_sheets/program_selection_bottom_sheet.dart';

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
  List<WorkoutProgram> _customPrograms = [];

  final List<String> _sessionTypes = ['Haut du corps', 'Bas du corps', 'Full body'];

  Widget _buildSessionTypeButtons() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de séance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Grille 1x2 avec les 2 boutons
            Row(
              children: [
                // Bouton séance manuelle
                Expanded(
                  child: _buildSessionTypeButton(
                    icon: LucideIcons.edit3,
                    title: 'Séance manuelle',
                    subtitle: '',
                    onTap: _showManualSessionFlow,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Bouton séance guidée
                Expanded(
                  child: _buildSessionTypeButton(
                    icon: LucideIcons.bookOpen,
                    title: 'Séance guidée',
                    subtitle: '',
                    onTap: _showProgramsModal,
                  ),
                ),
              ],
            ),
          ],
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
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
            const WeeklyStatsSection(),
            
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
            const WeekHistorySection(),
            
            const SizedBox(height: 16),
            
            // 6. Bloc "Progression par exercice" (FACTORISÉ)
            const ExerciseProgressSection(),
            
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
      builder: (context) => Container(
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
              
              const Text(
                'Nouvelle séance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Options
              _buildSessionChoiceButton(
                icon: LucideIcons.edit3,
                title: 'Créer une séance manuellement',
                subtitle: 'Construire sa séance étape par étape',
                onTap: () {
                  Navigator.pop(context);
                  _showManualSessionFlow();
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildSessionChoiceButton(
                icon: LucideIcons.bookOpen,
                title: 'Choisir un programme enregistré',
                subtitle: 'Utiliser un programme existant',
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

  void _showSessionNameModal() {
    final TextEditingController nameController = TextEditingController();
    nameController.text = 'Séance du ${DateTime.now().day}/${DateTime.now().month}';

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
                
                const Text(
                  'Nom de la séance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nom de la séance',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
                    child: const Text(
                      'Commencer la séance',
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
        customPrograms: _customPrograms,
      ),
    );
  }

  void _startSession(String name) {
    setState(() {
      _isSessionActive = true;
      _isFromProgram = false;
      _currentSession = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        startTime: DateTime.now(),
        exercises: [],
      );
      _currentExercises = [];
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
      );
    }).toList();

    setState(() {
      _isSessionActive = true;
      _isFromProgram = true;
      _currentSession = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: program.name,
        startTime: DateTime.now(),
        exercises: [],
      );
      _currentExercises = programExercises;
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
            const Text(
              'Exercices de la séance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_currentExercises.isEmpty)
              const Center(
                child: Text(
                  'Aucun exercice ajouté',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
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
            
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _showExerciseSelection,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Ajouter un exercice'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0B132B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      muscleGroup: 'Personnalisé',
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
          title: const Text(
            'Sauvegarder cette séance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            'Souhaitez-vous ajouter cette séance aux séances guidées ?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
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
              child: const Text('Non'),
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
              child: const Text('Oui'),
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
      description: 'Programme créé à partir de votre séance',
      type: 'Personnalisé',
      estimatedDuration: duration.inMinutes,
      exercises: _currentExercises.map((workoutExercise) {
        return ProgramExercise(
          exercise: workoutExercise.exercise,
          sets: workoutExercise.sets.length,
        );
      }).toList(),
    );

    setState(() {
      _customPrograms.add(newProgram);
    });

    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Séance ajoutée aux programmes guidés !'),
        backgroundColor: Color(0xFF059669),
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
            const Text(
              'Séance terminée !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Durée',
                    '${duration.inMinutes} min',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Exercices',
                    '${_currentExercises.length}',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Séries',
                    '$completedSets/$totalSets',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Nouvelle ligne avec kilos soulevés et calories
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Kilos soulevés',
                    '${totalWeight.toInt()} kg',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Calories dépensées',
                    '$caloriesInt kcal',
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
                    child: const Text('Nouvelle séance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Séance enregistrée !')),
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
                    child: const Text('Enregistrer'),
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