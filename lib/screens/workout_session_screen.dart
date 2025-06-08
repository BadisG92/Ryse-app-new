import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/sport_models.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String sessionName;
  final List<WorkoutExercise> exercises;
  final bool isFromProgram;
  final Function(WorkoutProgram)? onProgramSaved;
  final Function(WorkoutSession)? onSessionCompleted;

  const WorkoutSessionScreen({
    super.key,
    required this.sessionName,
    required this.exercises,
    this.isFromProgram = false,
    this.onProgramSaved,
    this.onSessionCompleted,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late List<WorkoutExercise> _exercises;
  int _currentExerciseIndex = 0;
  DateTime? _sessionStartTime;
  late Timer _timer;
  Duration _currentDuration = Duration.zero;


  @override
  void initState() {
    super.initState();
    _exercises = widget.isFromProgram ? List.from(widget.exercises) : [];
    _sessionStartTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDuration = _sessionStartTime != null 
              ? DateTime.now().difference(_sessionStartTime!)
              : Duration.zero;
        });
      }
    });
  }

  Duration get _sessionDuration {
    return _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;
  }

  int get _totalSets {
    return _exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
  }

  int get _completedSets {
    return _exercises.fold(
      0,
      (sum, exercise) => sum + exercise.sets.where((set) => set.isCompleted).length,
    );
  }

  double get _totalWeight {
    return _exercises.fold(
      0.0,
      (sum, exercise) => sum + exercise.sets
          .where((set) => set.isCompleted)
          .fold(0.0, (setSum, set) => setSum + (set.weight * set.reps)),
    );
  }

  int get _estimatedCalories {
    final baseCalories = _totalWeight * 0.35;
    final timeCalories = _sessionDuration.inMinutes * 5.0;
    return (baseCalories + timeCalories).round();
  }

  int _getDisplayedSetsCount() {
    if (_exercises.isEmpty) return 0;
    final currentExercise = _exercises[_currentExerciseIndex];
    
    // Pour les programmes guidés, on affiche toutes les séries définies
    if (widget.isFromProgram) {
      return currentExercise.sets.length;
    }
    
    // Pour les séances manuelles, on affiche au minimum 1 série
    return currentExercise.sets.isEmpty ? 1 : currentExercise.sets.length;
  }
  
  void _addNewSet() {
    if (_exercises.isEmpty) return;
    
    setState(() {
      final currentExercise = _exercises[_currentExerciseIndex];
      final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
      
      updatedSets.add(const ExerciseSet(
        weight: 0,
        reps: 0,
        isCompleted: false,
      ));
      
      _exercises[_currentExerciseIndex] = currentExercise.copyWith(sets: updatedSets);
    });
  }
  
  void _validateSet(int setIndex) {
    if (_exercises.isEmpty) return;
    
    final currentExercise = _exercises[_currentExerciseIndex];
    if (setIndex >= currentExercise.sets.length) return;
    
    final set = currentExercise.sets[setIndex];
    
    if (set.weight > 0 && set.reps > 0) {
      setState(() {
        final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
        updatedSets[setIndex] = set.copyWith(isCompleted: true);
        _exercises[_currentExerciseIndex] = currentExercise.copyWith(sets: updatedSets);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Série ${setIndex + 1} validée !'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir le poids et les répétitions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _updateSetValue(int setIndex, {double? weight, int? reps}) {
    if (_exercises.isEmpty) return;
    
    final currentExercise = _exercises[_currentExerciseIndex];
    if (setIndex >= currentExercise.sets.length) return;
    
    setState(() {
      final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
      final currentSet = updatedSets[setIndex];
      
      updatedSets[setIndex] = currentSet.copyWith(
        weight: weight ?? currentSet.weight,
        reps: reps ?? currentSet.reps,
        isCompleted: false, // Reset validation quand on modifie
      );
      
      _exercises[_currentExerciseIndex] = currentExercise.copyWith(sets: updatedSets);
    });
  }

  void _removeSet(int setIndex) {
    if (_exercises.isEmpty) return;
    
    final currentExercise = _exercises[_currentExerciseIndex];
    if (setIndex >= currentExercise.sets.length || currentExercise.sets.length <= 1) return;
    
    setState(() {
      final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
      updatedSets.removeAt(setIndex);
      _exercises[_currentExerciseIndex] = currentExercise.copyWith(sets: updatedSets);
    });
  }

  void _addExercise(String name, String muscleGroup) {
    setState(() {
      _exercises.add(WorkoutExercise(
        exercise: Exercise(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          muscleGroup: muscleGroup,
          isCustom: true,
        ),
        sets: [],
      ));
      
      // Si c'est le premier exercice, le sélectionner
      if (_exercises.length == 1) {
        _currentExerciseIndex = 0;
      }
    });
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });
    }
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    }
  }

  void _showAddExerciseDialog() {
    final TextEditingController searchController = TextEditingController();
    List<Exercise> filteredExercises = [];
    
    // Base de données d'exercices prédéfinis (comme dans le bottom sheet)
    final List<Exercise> predefinedExercises = [
      const Exercise(
        id: '1',
        name: 'Développé couché',
        muscleGroup: 'Pectoraux',
        equipment: 'Barre',
        description: 'Exercice pour les pectoraux avec barre',
      ),
      const Exercise(
        id: '2',
        name: 'Squat',
        muscleGroup: 'Jambes',
        equipment: 'Barre',
        description: 'Exercice pour les jambes et fessiers',
      ),
      const Exercise(
        id: '3',
        name: 'Tractions',
        muscleGroup: 'Dos',
        equipment: 'Barre de traction',
        description: 'Exercice pour le dos',
      ),
      const Exercise(
        id: '4',
        name: 'Développé militaire',
        muscleGroup: 'Épaules',
        equipment: 'Barre',
        description: 'Exercice pour les épaules',
      ),
      const Exercise(
        id: '5',
        name: 'Curl biceps',
        muscleGroup: 'Biceps',
        equipment: 'Haltères',
        description: 'Exercice pour les biceps',
      ),
      const Exercise(
        id: '6',
        name: 'Dips',
        muscleGroup: 'Triceps',
        equipment: 'Barres parallèles',
        description: 'Exercice pour les triceps',
      ),
      const Exercise(
        id: '7',
        name: 'Soulevé de terre',
        muscleGroup: 'Dos',
        equipment: 'Barre',
        description: 'Exercice composé pour le dos et les jambes',
      ),
      const Exercise(
        id: '8',
        name: 'Crunchs',
        muscleGroup: 'Abdominaux',
        equipment: 'Aucun',
        description: 'Exercice pour les abdominaux',
      ),
      const Exercise(
        id: '9',
        name: 'Pompes',
        muscleGroup: 'Pectoraux',
        equipment: 'Aucun',
        description: 'Exercice au poids du corps pour les pectoraux',
      ),
      const Exercise(
        id: '10',
        name: 'Rowing barre',
        muscleGroup: 'Dos',
        equipment: 'Barre',
        description: 'Exercice pour le dos avec barre',
      ),
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void filterExercises() {
            setModalState(() {
              filteredExercises = predefinedExercises.where((exercise) {
                return exercise.name
                    .toLowerCase()
                    .contains(searchController.text.toLowerCase());
              }).toList();
            });
          }
          
          searchController.addListener(filterExercises);
          if (filteredExercises.isEmpty && searchController.text.isEmpty) {
            filteredExercises = predefinedExercises;
          }
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
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
                      'Ajouter un exercice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Barre de recherche
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher ou créer un exercice...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bouton pour créer un exercice custom si pas de résultats
                    if (searchController.text.isNotEmpty && filteredExercises.isEmpty)
                      GestureDetector(
                        onTap: () {
                          _addExercise(searchController.text, 'Personnalisé');
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.plus, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Créer un nouvel exercice',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '"${searchController.text}"',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Liste des exercices
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          return GestureDetector(
                            onTap: () {
                              _addExercise(exercise.name, exercise.muscleGroup);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 8),
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
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
                                    LucideIcons.chevronRight,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSaveSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.bookmark,
                    size: 32,
                    color: Color(0xFF0B132B),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Sauvegarder la séance ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Souhaitez-vous ajouter la séance "${widget.sessionName}" à votre liste de séances guidées ?',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context); // Fermer popup
                          Navigator.pop(context); // Retourner à la musculation
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Non',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _saveAsProgram(widget.sessionName);
                          Navigator.pop(context); // Fermer popup
                          Navigator.pop(context); // Retourner à la musculation
                          
                          // Afficher confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Séance "${widget.sessionName}" ajoutée aux programmes guidés !'),
                              backgroundColor: const Color(0xFF10B981),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Oui',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _validateSession() {
    // Créer la session complète et validée
    final sessionEndTime = DateTime.now();
    final completedSession = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.sessionName,
      startTime: _sessionStartTime ?? DateTime.now(),
      endTime: sessionEndTime,
      exercises: _exercises,
      isCompleted: true,
    );
    
    // Appeler le callback pour valider la session
    if (widget.onSessionCompleted != null) {
      widget.onSessionCompleted!(completedSession);
    }
    
    print('Séance validée: ${completedSession.name}');
    print('- Durée totale: ${_formatDuration(completedSession.duration)}');
    print('- ${completedSession.completedSets}/${completedSession.totalSets} séries terminées');
  }

  void _saveAsProgram(String sessionName) {
    // Calculer la durée réelle de la session au moment de la sauvegarde
    final sessionEndTime = DateTime.now();
    final realSessionDuration = _sessionStartTime != null 
        ? sessionEndTime.difference(_sessionStartTime!)
        : Duration.zero;
    
    // Créer la session complète et validée
    final completedSession = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: sessionName,
      startTime: _sessionStartTime ?? DateTime.now(),
      endTime: sessionEndTime,
      exercises: _exercises,
      isCompleted: true,
    );
    
    // Créer le programme à partir de la séance
    final programExercises = _exercises.map((workoutExercise) {
      return ProgramExercise(
        exercise: workoutExercise.exercise,
        sets: workoutExercise.sets.length,
      );
    }).toList();
    
    // S'assurer qu'on a au moins 1 minute affichée, même pour des sessions courtes
    final durationInMinutes = realSessionDuration.inMinutes > 0 
        ? realSessionDuration.inMinutes 
        : (realSessionDuration.inSeconds > 0 ? 1 : 1); // Minimum 1 minute
    
    final workoutProgram = WorkoutProgram(
      id: completedSession.id + "_program",
      name: sessionName,
      description: 'Programme créé à partir d\'une séance manuelle',
      type: 'Personnalisé',
      estimatedDuration: durationInMinutes,
      exercises: programExercises,
    );
    
    // Appeler les callbacks pour sauvegarder dans l'écran parent
    if (widget.onSessionCompleted != null) {
      widget.onSessionCompleted!(completedSession);
    }
    
    if (widget.onProgramSaved != null) {
      widget.onProgramSaved!(workoutProgram);
    }
    
    print('=== DEBUG SAUVEGARDE ===');
    print('Séance validée: ${completedSession.name}');
    print('- Heure début: ${_sessionStartTime}');
    print('- Heure fin: $sessionEndTime');
    print('- Durée en secondes: ${realSessionDuration.inSeconds}');
    print('- Durée en minutes: ${realSessionDuration.inMinutes}');
    print('- Durée calculée: $durationInMinutes min');
    print('- Durée formatée: ${_formatDuration(realSessionDuration)}');
    print('Programme créé: ${workoutProgram.name}');
    print('- estimatedDuration: ${workoutProgram.estimatedDuration} min');
    print('========================');
  }

  void _showSessionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de succès
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle,
                    size: 32,
                    color: Color(0xFF10B981),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Séance terminée !',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Excellent travail ! Voici le résumé de votre séance.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Métriques
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryMetric(
                              'Durée',
                              _formatDuration(_sessionDuration),
                              LucideIcons.clock,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _buildSummaryMetric(
                              'Exercices',
                              '${_exercises.length}',
                              LucideIcons.dumbbell,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryMetric(
                              'Séries',
                              '$_completedSets/$_totalSets',
                              LucideIcons.repeat,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _buildSummaryMetric(
                              'Volume',
                              '${_totalWeight.toStringAsFixed(0)} kg',
                              LucideIcons.barChart3,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      
                      _buildSummaryMetric(
                        'Calories',
                        '$_estimatedCalories kcal',
                        LucideIcons.flame,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Fermer dialog
                      
                      // Toujours valider la session d'abord
                      _validateSession();
                      
                      // Afficher le popup de sauvegarde avant de retourner (séances manuelles uniquement)
                      if (!widget.isFromProgram && _exercises.isNotEmpty) {
                        _showSaveSessionDialog();
                      } else {
                        Navigator.pop(context); // Retourner à la musculation
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
                      'Terminer la séance',
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
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF0B132B),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 2),
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
    } else {
      return '${minutes}min';
    }
  }

  String _formatDurationRealTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }



  @override
  Widget build(BuildContext context) {
    return _buildWorkoutScreen();
  }



  Widget _buildWorkoutScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B), // Bleu principal
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header avec minuteur global
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      LucideIcons.x,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.sessionName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDurationRealTime(_currentDuration),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Si aucun exercice
              if (_exercises.isEmpty) ...[
                const Spacer(),
                const Icon(
                  LucideIcons.dumbbell,
                  size: 64,
                  color: Colors.white30,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun exercice ajouté',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                                 Text(
                   'Commencez par ajouter un exercice',
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.white.withValues(alpha: 0.5),
                   ),
                 ),
                const Spacer(),
              ] else ...[
                // Navigation entre exercices
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _currentExerciseIndex > 0 ? _previousExercise : null,
                      icon: Icon(
                        LucideIcons.chevronLeft,
                        color: _currentExerciseIndex > 0 ? Colors.white : Colors.white30,
                        size: 32,
                      ),
                    ),
                    
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _exercises[_currentExerciseIndex].exercise.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _exercises[_currentExerciseIndex].exercise.muscleGroup,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    IconButton(
                      onPressed: _currentExerciseIndex < _exercises.length - 1 ? _nextExercise : null,
                      icon: Icon(
                        LucideIcons.chevronRight,
                        color: _currentExerciseIndex < _exercises.length - 1 ? Colors.white : Colors.white30,
                        size: 32,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                                 // Indicateur d'exercice
                 Text(
                   'Exercice ${_currentExerciseIndex + 1}/${_exercises.length}',
                   style: TextStyle(
                     fontSize: 12,
                     color: Colors.white.withValues(alpha: 0.5),
                   ),
                 ),

                const SizedBox(height: 12),

                // Section des séries
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Séries',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // En-têtes des colonnes
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Poids (kg)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Répétitions',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 80), // Espace pour les boutons
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Bulles des séries
                      Expanded(
                        child: _buildSetsList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Bouton pour ajouter une série (pour toutes les séances)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: OutlinedButton.icon(
                          onPressed: _addNewSet,
                          icon: const Icon(
                            LucideIcons.plus,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Ajouter une série',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Bouton ajouter exercice
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAddExerciseDialog,
                  icon: const Icon(
                    LucideIcons.plus,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Ajouter un exercice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bouton terminer séance (toujours visible)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showSessionSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Terminer la séance',
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
    );
  }

  Widget _buildSetsList() {
    if (_exercises.isEmpty) return Container();
    
    final displayedCount = _getDisplayedSetsCount();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: displayedCount,
      itemBuilder: (context, index) => _buildSetBubble(index),
    );
  }

  Widget _buildSetBubble(int setIndex) {
    final currentExercise = _exercises[_currentExerciseIndex];
    
    // Créer une série par défaut si elle n'existe pas
    ExerciseSet currentSet;
    if (setIndex < currentExercise.sets.length) {
      currentSet = currentExercise.sets[setIndex];
    } else {
      currentSet = const ExerciseSet(weight: 0, reps: 0, isCompleted: false);
      // Ajouter cette série à l'exercice
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
          updatedSets.add(currentSet);
          _exercises[_currentExerciseIndex] = currentExercise.copyWith(sets: updatedSets);
        });
      });
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentSet.isCompleted 
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: currentSet.isCompleted 
            ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1)
            : Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          // Input Poids
          Expanded(
            child: TextField(
              onChanged: (value) {
                final weight = double.tryParse(value) ?? 0.0;
                _updateSetValue(setIndex, weight: weight);
              },
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: currentSet.weight > 0 ? currentSet.weight.toString() : '0',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Input Répétitions
          Expanded(
            child: TextField(
              onChanged: (value) {
                final reps = int.tryParse(value) ?? 0;
                _updateSetValue(setIndex, reps: reps);
              },
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: currentSet.reps > 0 ? currentSet.reps.toString() : '0',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Bouton Valider
          GestureDetector(
            onTap: currentSet.isCompleted ? null : () => _validateSet(setIndex),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: currentSet.isCompleted 
                    ? const Color(0xFF10B981)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.check,
                color: currentSet.isCompleted 
                    ? Colors.white
                    : const Color(0xFF0B132B),
                size: 16,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Bouton Supprimer
          GestureDetector(
            onTap: () => _removeSet(setIndex),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.x,
                color: Colors.red,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }




}