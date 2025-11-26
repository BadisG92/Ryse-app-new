import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sport_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/ui/custom_scrollbar.dart';
import '../components/ui/numeric_text_field.dart';
import '../services/database_service.dart' as db;
import '../services/calorie_burn_service.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/offline_workout_service.dart';
import '../services/workout_cache_service.dart';
import '../services/sport_dashboard_service.dart';
import '../services/global_state_manager.dart';
import '../services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import '../services/workout_voice_service.dart';
import '../services/native_speech_service.dart';
import '../services/celebration_service.dart';
import '../services/haptic_service.dart';
import '../services/unit_service.dart';
import 'package:provider/provider.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String sessionName;
  final List<WorkoutExercise> exercises;
  final bool isFromProgram;
  final String? guidedTemplateId; // si séance guidée, passer l'id du template
  final bool isFromAI; // ⚡ NEW: Identifie les séances Coach Ryze pour navigation 3-pop
  final Function(WorkoutProgram)? onProgramSaved;
  final Function(WorkoutSession)? onSessionCompleted;

  // Paramètres pour le mode édition
  final bool isEditMode;
  final String? editSessionId;
  final String? editHistorySessionId;
  final String? editSessionDate;
  final int? editDurationMinutes;
  final String? editIntensity;

  const WorkoutSessionScreen({
    super.key,
    required this.sessionName,
    required this.exercises,
    this.isFromProgram = false,
    this.guidedTemplateId,
    this.isFromAI = false, // ⚡ Par défaut false (manuel et guidé)
    this.onProgramSaved,
    this.onSessionCompleted,
    this.isEditMode = false,
    this.editSessionId,
    this.editHistorySessionId,
    this.editSessionDate,
    this.editDurationMinutes,
    this.editIntensity,
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
  bool _addSeriePressed = false;
  bool _addExercisePressed = false;
  String? _selectedIntensity;

  // Mapper les intensités anglaises vers les valeurs françaises de la DB
  String _mapIntensityToDbValue(String intensity) {
    final locService = LocalizationService.instance;
    switch (intensity) {
      case 'low':
        return 'workout_intensity_low'.tr(locService.currentLanguageCode);
      case 'moderate':
        return 'workout_intensity_moderate'.tr(locService.currentLanguageCode);
      case 'high':
        return 'workout_intensity_high'.tr(locService.currentLanguageCode);
      default:
        return 'workout_intensity_moderate'.tr(locService.currentLanguageCode); // fallback
    }
  }

  // Mapper les valeurs DB vers les clés d'intensité (inverse de _mapIntensityToDbValue)
  String? _mapDbValueToIntensityKey(String? dbValue) {
    if (dbValue == null) return null;
    final locService = LocalizationService.instance;
    final low = 'workout_intensity_low'.tr(locService.currentLanguageCode);
    final moderate = 'workout_intensity_moderate'.tr(locService.currentLanguageCode);
    final high = 'workout_intensity_high'.tr(locService.currentLanguageCode);

    if (dbValue == low) return 'low';
    if (dbValue == moderate) return 'moderate';
    if (dbValue == high) return 'high';
    return null;
  }

  int? _effectiveDurationMinutes; // permet d'éditer la durée réelle
  
  // Mode offline
  final OfflineWorkoutService _offlineService = OfflineWorkoutService();
  StreamSubscription<OfflineStatus>? _offlineStatusSubscription;
  OfflineStatus? _offlineStatus;
  
  // Controllers pour gérer les inputs de chaque série de manière indépendante
  final Map<String, Map<int, TextEditingController>> _weightControllers = {};
  final Map<String, Map<int, TextEditingController>> _repsControllers = {};
  final Map<String, Map<int, FocusNode>> _weightFocusNodes = {};
  final Map<String, Map<int, FocusNode>> _repsFocusNodes = {};
  
  // Controller pour la liste scrollable et keys pour les champs
  final ScrollController _scrollController = ScrollController();
  final Map<String, Map<int, GlobalKey>> _setKeys = {};
  late FocusNode _currentFocusNode;
  
  // Pour tracker quelle série est actuellement active
  int? _activeSetIndex;
  
  // Pour la bulle d'historique
  bool _showHistoryBubble = false;
  final GlobalKey _historyIconKey = GlobalKey();
  Map<String, dynamic>? _exerciseHistoryData;

  // Mode vocal (Voice input pour reps/poids) - Service hybride iOS natif + Android fallback
  final HybridVoiceService _voiceService = HybridVoiceService();
  bool _isVoiceListening = false;
  String _recognizedText = '';
  bool _voiceInitialized = false;
  bool _voiceHasError = false; // État d'erreur pour afficher bouton rouge
  bool _isProcessingVoiceResult = false; // ⚡ Guard pour éviter appels multiples
  Timer? _voiceAutoStopTimer; // ⚡ Timer pour auto-stop après détection
  DateTime? _lastValidDataDetectedAt; // ⚡ Timestamp dernière détection valide

  // Système Undo
  Timer? _undoTimer;
  bool _showUndoButton = false;
  int _undoCountdown = 3;
  int? _lastVoiceExerciseIndex;
  int? _lastVoiceSetIndex;

  // Système Auto-Retry
  int _voiceRetryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    // ⚡ FIX: Coach Ryze (isFromAI) et programmes guidés arrivent avec exercices pré-remplis
    // Seules les séances VRAIMENT manuelles (ni program, ni AI) commencent vides
    _exercises = (widget.isFromProgram || widget.isFromAI || widget.isEditMode) ? List.from(widget.exercises) : [];

    if (kDebugMode) debugPrint('🏋️ WorkoutSessionScreen init: ${_exercises.length} exercices (isFromProgram: ${widget.isFromProgram}, isFromAI: ${widget.isFromAI}, isEditMode: ${widget.isEditMode})');

    _sessionStartTime = DateTime.now();
    _currentFocusNode = FocusNode();

    // En mode édition, pré-remplir la durée et l'intensité
    if (widget.isEditMode) {
      _effectiveDurationMinutes = widget.editDurationMinutes;
      _selectedIntensity = _mapDbValueToIntensityKey(widget.editIntensity);
    }

    // Initialiser les controllers pour tous les exercices existants
    for (final exercise in _exercises) {
      _initializeControllersForExercise(exercise);
    }
    
    _startTimer();
    
    // Initialiser le service offline et écouter les changements de statut
    _initOfflineMode();
  }
  
  void _initOfflineMode() async {
    await _offlineService.initialize();
    _offlineStatusSubscription = _offlineService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _offlineStatus = status;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    _currentFocusNode.dispose();
    _offlineStatusSubscription?.cancel();
    // Dispose des controllers
    for (var controllers in _weightControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    for (var controllers in _repsControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    // Dispose des focus nodes
    for (var focusNodes in _weightFocusNodes.values) {
      for (var focusNode in focusNodes.values) {
        focusNode.dispose();
      }
    }
    for (var focusNodes in _repsFocusNodes.values) {
      for (var focusNode in focusNodes.values) {
        focusNode.dispose();
      }
    }
    // Dispose voice service
    _voiceService.dispose();
    // Dispose undo timer
    _undoTimer?.cancel();
    // Dispose voice auto-stop timer
    _voiceAutoStopTimer?.cancel();
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

  Duration get _displayedDuration {
    if (_effectiveDurationMinutes != null && _effectiveDurationMinutes! >= 0) {
      return Duration(minutes: _effectiveDurationMinutes!);
    }
    return _sessionDuration;
  }

  int get _totalSets {
    return _exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
  }

  int get _completedSets {
    return _exercises.fold(
      0,
      (sum, exercise) => sum + exercise.sets.where((set) => set.isValid).length,
    );
  }

  double get _totalWeight {
    return _exercises.fold(
      0.0,
      (sum, exercise) => sum + exercise.sets
          .where((set) => set.isValid)
          .fold(0.0, (setSum, set) => setSum + (set.weight * set.reps)),
    );
  }

  int get _estimatedCalories {
    final user = AuthService().currentUser;
    final double assumedWeightKg = (user?.weight != null && user!.weight! > 0)
        ? user.weight!
        : 75.0; // fallback
    final minutes = _displayedDuration.inMinutes > 0 ? _displayedDuration.inMinutes : 1;
    final intensity = _selectedIntensity ?? 'moderate';
    return CalorieBurnService.calculateKcal(
      'musculation',
      assumedWeightKg,
      minutes,
      intensity: intensity,
      totalWeightKg: _totalWeight,
    );
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
      _addSeriePressed = true;
      final currentExercise = _exercises[_currentExerciseIndex];
      final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
      
      updatedSets.add(const ExerciseSet(
        weight: 0,
        reps: 0,
        isCompleted: false,
      ));
      
      _exercises[_currentExerciseIndex] = currentExercise.copyWith(sets: updatedSets);
      
      // Ajouter les controllers et keys pour la nouvelle série
      final exerciseId = currentExercise.exercise.id;
      final newSetIndex = updatedSets.length - 1;
      
      _weightControllers[exerciseId] ??= {};
      _repsControllers[exerciseId] ??= {};
      _weightFocusNodes[exerciseId] ??= {};
      _repsFocusNodes[exerciseId] ??= {};
      _setKeys[exerciseId] ??= {};
      
      _weightControllers[exerciseId]![newSetIndex] = TextEditingController();
      _repsControllers[exerciseId]![newSetIndex] = TextEditingController();
      
      // Créer les FocusNodes avec listeners pour la nouvelle série
      final weightFocus = FocusNode();
      final repsFocus = FocusNode();
      
      weightFocus.addListener(() => _onFieldFocusChanged(newSetIndex, weightFocus.hasFocus));
      repsFocus.addListener(() => _onFieldFocusChanged(newSetIndex, repsFocus.hasFocus));
      
      _weightFocusNodes[exerciseId]![newSetIndex] = weightFocus;
      _repsFocusNodes[exerciseId]![newSetIndex] = repsFocus;
      _setKeys[exerciseId]![newSetIndex] = GlobalKey();
    });
    
    // Reset après un délai
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _addSeriePressed = false;
        });
      }
    });
  }
  
  // ❌ SUPPRIMÉ : Plus besoin de validation manuelle
  // La validation est automatique dès que reps > 0 (voir ExerciseSet.copyWith)
  /*
  void _validateSet(int setIndex) {
    // Ancienne méthode de validation manuelle - remplacée par auto-validation
  }
  */
  
  void _updateSetValue(int setIndex, {double? weight, int? reps}) {
    if (_exercises.isEmpty) return;

    final currentExercise = _exercises[_currentExerciseIndex];
    if (setIndex >= currentExercise.sets.length) return;

    // ✅ NOUVEAU : Contrainte séquentielle - vérifier que série précédente a des reps
    if (setIndex > 0 && reps != null && reps > 0) {
      final previousSet = currentExercise.sets[setIndex - 1];
      if (previousSet.reps == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'complete_set_before'.tr(locService.currentLanguageCode)
                    .replaceAll('{setIndex}', setIndex.toString()),
              ),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    setState(() {
      final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
      final currentSet = updatedSets[setIndex];

      // ✅ Auto-validation basée sur reps > 0 (copyWith gère automatiquement)
      updatedSets[setIndex] = currentSet.copyWith(
        weight: weight ?? currentSet.weight,
        reps: reps ?? currentSet.reps,
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

  void _addExercise(String name, String muscleGroup, {int setsCount = 3, String? exerciseId, bool isCustom = false}) {
    final resolvedId = exerciseId ?? DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      // Créer les séries vides
      final sets = List.generate(setsCount, (index) =>
        const ExerciseSet(weight: 0, reps: 0, isCompleted: false)
      );

      final newExercise = WorkoutExercise(
        exercise: Exercise(
          id: resolvedId,
          name: name,
          muscleGroup: muscleGroup,
          isCustom: isCustom || exerciseId == null,
        ),
        sets: sets,
      );

      _exercises.add(newExercise);

      // Initialiser les controllers pour cet exercice
      _initializeControllersForExercise(newExercise);

      // Si c'est le premier exercice, le sélectionner
      if (_exercises.length == 1) {
        _currentExerciseIndex = 0;
      } else {
        // Aller directement sur le nouvel exercice
        _currentExerciseIndex = _exercises.length - 1;
      }
    });
  }
  
  void _initializeControllersForExercise(WorkoutExercise exercise) {
    final exerciseId = exercise.exercise.id;
    _weightControllers[exerciseId] = {};
    _repsControllers[exerciseId] = {};
    _weightFocusNodes[exerciseId] = {};
    _repsFocusNodes[exerciseId] = {};
    _setKeys[exerciseId] = {};

    for (int i = 0; i < exercise.sets.length; i++) {
      final set = exercise.sets[i];

      // Pré-remplir les controllers avec les valeurs de l'IA si disponibles
      // Convertir le poids stocké (kg) en unité d'affichage (lbs si impérial)
      final displayWeight = set.weight > 0
          ? UnitService.instance.formatWeightValue(set.weight, decimals: set.weight % 1 == 0 ? 0 : 1)
          : '';
      final weightController = TextEditingController(
        text: displayWeight,
      );
      final repsController = TextEditingController(
        text: set.reps > 0 ? set.reps.toString() : '',
      );

      _weightControllers[exerciseId]![i] = weightController;
      _repsControllers[exerciseId]![i] = repsController;

      // Créer les FocusNodes avec listeners
      final weightFocus = FocusNode();
      final repsFocus = FocusNode();

      weightFocus.addListener(() => _onFieldFocusChanged(i, weightFocus.hasFocus));
      repsFocus.addListener(() => _onFieldFocusChanged(i, repsFocus.hasFocus));

      _weightFocusNodes[exerciseId]![i] = weightFocus;
      _repsFocusNodes[exerciseId]![i] = repsFocus;
      _setKeys[exerciseId]![i] = GlobalKey();
    }
  }
  
  TextEditingController _getWeightController(int setIndex) {
    final exerciseId = _exercises[_currentExerciseIndex].exercise.id;
    return _weightControllers[exerciseId]?[setIndex] ?? TextEditingController();
  }
  
  TextEditingController _getRepsController(int setIndex) {
    final exerciseId = _exercises[_currentExerciseIndex].exercise.id;
    return _repsControllers[exerciseId]?[setIndex] ?? TextEditingController();
  }

  FocusNode _getWeightFocusNode(int setIndex) {
    final exerciseId = _exercises[_currentExerciseIndex].exercise.id;
    return _weightFocusNodes[exerciseId]?[setIndex] ?? FocusNode();
  }

  FocusNode _getRepsFocusNode(int setIndex) {
    final exerciseId = _exercises[_currentExerciseIndex].exercise.id;
    return _repsFocusNodes[exerciseId]?[setIndex] ?? FocusNode();
  }

  GlobalKey _getSetKey(int setIndex) {
    final exerciseId = _exercises[_currentExerciseIndex].exercise.id;
    return _setKeys[exerciseId]?[setIndex] ?? GlobalKey();
  }
  
  void _scrollToField(int setIndex) {
    setState(() {
      _activeSetIndex = setIndex;
    });
    
    final key = _getSetKey(setIndex);
    
    // Première tentative immédiate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performScroll(key);
    });
    
    // Deuxième tentative après un délai pour s'assurer que le clavier est apparu
    Timer(const Duration(milliseconds: 300), () {
      _performScroll(key);
    });
  }
  
  Future<void> _loadExerciseHistory() async {
    if (_exercises.isEmpty) return;
    
    final currentExercise = _exercises[_currentExerciseIndex];
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    if (userId == null) {
      setState(() {
        _exerciseHistoryData = null;
      });
      return;
    }
    
    try {
      final exerciseData = await WorkoutCacheService.getExerciseDetails(userId, currentExercise.exercise.name);
      setState(() {
        _exerciseHistoryData = exerciseData;
      });
    } catch (e) {
      setState(() {
        _exerciseHistoryData = null;
      });
    }
  }
  
  void _toggleHistoryBubble() {
    setState(() {
      if (!_showHistoryBubble) {
        _loadExerciseHistory();
      }
      _showHistoryBubble = !_showHistoryBubble;
    });
  }
  
  void _hideHistoryBubble() {
    setState(() {
      _showHistoryBubble = false;
    });
  }

  void _onFieldFocusChanged(int setIndex, bool hasFocus) {
    if (hasFocus) {
      setState(() {
        _activeSetIndex = setIndex;
      });
    } else {
      // Ne pas réinitialiser immédiatement car l'autre champ de la même série peut prendre le focus
      Timer(const Duration(milliseconds: 100), () {
        final weightFocus = _getWeightFocusNode(setIndex);
        final repsFocus = _getRepsFocusNode(setIndex);
        if (!weightFocus.hasFocus && !repsFocus.hasFocus && _activeSetIndex == setIndex) {
          setState(() {
            _activeSetIndex = null;
          });
        }
      });
    }
  }
  
  void _performScroll(GlobalKey key) {
    if (key.currentContext != null && _scrollController.hasClients) {
      try {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3, // Positionner le champ vers le haut de l'écran visible
        );
      } catch (e) {
        // En cas d'erreur, essayer avec le scroll controller directement
        final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          final screenHeight = MediaQuery.of(context).size.height;
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final availableHeight = screenHeight - keyboardHeight - 200; // Marge de sécurité
          
          if (position.dy > availableHeight) {
            final scrollOffset = position.dy - availableHeight + 100; // Scroll un peu plus pour avoir de la marge
            _scrollController.animateTo(
              _scrollController.offset + scrollOffset,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    }
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

  void _showSetsCountDialog(String exerciseName, String muscleGroup, {String? exerciseId, bool isCustom = false}) {
    int selectedSets = 3; // Valeur par défaut
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'workout_how_many_sets'.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_for_exercise'.tr(locService.currentLanguageCode).replaceAll('{0}', exerciseName),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final sets = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedSets = sets;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedSets == sets 
                            ? const Color(0xFF0B132B) 
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedSets == sets 
                              ? const Color(0xFF0B132B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$sets',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selectedSets == sets 
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'cancel'.tr(locService.currentLanguageCode),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addExercise(exerciseName, muscleGroup, setsCount: selectedSets, exerciseId: exerciseId, isCustom: isCustom);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B132B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_create'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
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

  void _showAddExerciseDialog() async {
    setState(() {
      _addExercisePressed = true;
    });

    final TextEditingController searchController = TextEditingController();
    List<Exercise> filteredExercises = [];
    Map<String, int> exerciseSessionCounts = {};

    // Variable pour le filtre de groupe musculaire (sélection multiple)
    final locService = LocalizationService.instance;
    Set<String> selectedMuscleFilters = {}; // Vide = tous les exercices
    List<String> availableMuscleGroups = [];

    // Charger depuis Supabase ou cache offline
    final List<Exercise> allExercises = await db.DatabaseService.getSystemExercises();

    // Extraire les groupes musculaires uniques
    final muscleGroupsSet = <String>{};
    for (final exercise in allExercises) {
      if (exercise.muscleGroup.isNotEmpty) {
        muscleGroupsSet.add(exercise.muscleGroup);
      }
    }
    availableMuscleGroups = muscleGroupsSet.toList()..sort();
    if (kDebugMode) debugPrint('✅ ${availableMuscleGroups.length} groupes musculaires extraits: $availableMuscleGroups');
    
    // Charger les statistiques des exercices pour les tags de fréquence
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final topExercises = await WorkoutCacheService.getTopExercises(userId);
        for (final exercise in topExercises) {
          final exerciseName = exercise['localized_name']?.toString() ?? exercise['name']?.toString();
          final sessions = exercise['sessions'] as int? ?? 0;
          if (exerciseName != null && exerciseName.isNotEmpty) {
            exerciseSessionCounts[exerciseName] = sessions;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur lors du chargement des stats d\'exercices: $e');
    }
    
    // Trier les exercices par fréquence
    allExercises.sort((a, b) {
      final aSessionCount = exerciseSessionCounts[a.name] ?? 0;
      final bSessionCount = exerciseSessionCounts[b.name] ?? 0;
      
      // Si les deux ont des sessions, trier par nombre de sessions décroissant
      if (aSessionCount > 0 && bSessionCount > 0) {
        return bSessionCount.compareTo(aSessionCount);
      }
      // Si seulement a a des sessions, a vient en premier
      if (aSessionCount > 0 && bSessionCount == 0) {
        return -1;
      }
      // Si seulement b a des sessions, b vient en premier
      if (aSessionCount == 0 && bSessionCount > 0) {
        return 1;
      }
      // Si aucun n'a de sessions, trier alphabétiquement
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    
    // Si aucun exercice et mode hors ligne, afficher un message
    if (allExercises.isEmpty && _offlineStatus != null && !_offlineStatus!.isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.wifiOff, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'workout_no_offline_exercises'.tr(LocalizationService.instance.currentLanguageCode),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Reset le bouton après un délai
        Timer(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _addExercisePressed = false;
            });
          }
        });
        return;
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void filterExercises() {
            setModalState(() {
              filteredExercises = allExercises.where((exercise) {
                // Filtre par texte de recherche
                final matchesSearch = exercise.name
                    .toLowerCase()
                    .contains(searchController.text.toLowerCase());

                // Filtre par groupe musculaire (sélection multiple)
                // Si aucun filtre sélectionné, afficher tous les exercices
                final matchesMuscleGroup = selectedMuscleFilters.isEmpty ||
                    selectedMuscleFilters.contains(exercise.muscleGroup);

                return matchesSearch && matchesMuscleGroup;
              }).toList();
              
              // Re-trier par fréquence après le filtrage
              filteredExercises.sort((a, b) {
                final aSessionCount = exerciseSessionCounts[a.name] ?? 0;
                final bSessionCount = exerciseSessionCounts[b.name] ?? 0;
                
                if (aSessionCount > 0 && bSessionCount > 0) {
                  return bSessionCount.compareTo(aSessionCount);
                }
                if (aSessionCount > 0 && bSessionCount == 0) {
                  return -1;
                }
                if (aSessionCount == 0 && bSessionCount > 0) {
                  return 1;
                }
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });
            });
          }
          
          searchController.addListener(filterExercises);
          if (filteredExercises.isEmpty && searchController.text.isEmpty) {
            filteredExercises = allExercises;
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
                    
                    Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'workout_add_exercise'.tr(locService.currentLanguageCode),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Barre de recherche
                    TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        hintText: 'workout_search_create_exercise'.tr(LocalizationService.instance.currentLanguageCode),
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

                    // Grille de groupes musculaires si recherche vide et aucun filtre actif
                    if (searchController.text.isEmpty && selectedMuscleFilters.isEmpty) ...[
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          locService.isFrench ? 'Choisir par groupe musculaire' : 'Choose by muscle group',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.95,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: availableMuscleGroups.length + 1, // +1 pour "Personnalisé"
                          itemBuilder: (context, index) {
                            // Dernier élément = "Personnalisé"
                            if (index == availableMuscleGroups.length) {
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedMuscleFilters.add('workout_custom_type'.tr(LocalizationService.instance.currentLanguageCode));
                                    filterExercises();
                                  });
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0B132B), Color(0xFF1E293B)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: ColorFiltered(
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                        child: Image.asset(
                                          'assets/images/muscle_groups/custom.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Consumer<LocalizationService>(
                                      builder: (context, locService, _) => Text(
                                        locService.isFrench ? 'Personnalisé' : 'Custom',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final group = availableMuscleGroups[index];

                            // Images personnalisées par groupe musculaire
                            String imagePath;

                            switch (group.toLowerCase()) {
                              case 'cardio':
                                imagePath = 'assets/images/muscle_groups/cardio.png';
                                break;
                              case 'personnalisé':
                                imagePath = 'assets/images/muscle_groups/custom.png';
                                break;
                              case 'pectoraux':
                                imagePath = 'assets/images/muscle_groups/chest.png';
                                break;
                              case 'dos':
                                imagePath = 'assets/images/muscle_groups/back.png';
                                break;
                              case 'jambes':
                                imagePath = 'assets/images/muscle_groups/legs.png';
                                break;
                              case 'épaules':
                                imagePath = 'assets/images/muscle_groups/shoulders.png';
                                break;
                              case 'bras':
                                imagePath = 'assets/images/muscle_groups/arms.png';
                                break;
                              case 'abdos':
                                imagePath = 'assets/images/muscle_groups/abs.png';
                                break;
                              case 'corps complet':
                                imagePath = 'assets/images/muscle_groups/full_body.png';
                                break;
                              default:
                                imagePath = 'assets/images/muscle_groups/chest.png';
                            }

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedMuscleFilters.add(group);
                                  filterExercises();
                                });
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0B132B), Color(0xFF1E293B)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                      child: Image.asset(
                                        imagePath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    group,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ]
                    else ...[
                      // Ligne de filtres de groupes musculaires défilable (si filtre actif ou recherche non vide)
                      Row(
                        children: [
                          // Bouton "Tout" pour déselectionner tous les filtres
                          if (selectedMuscleFilters.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedMuscleFilters.clear();
                                    filterExercises();
                                  });
                                },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.x,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      locService.isFrench ? 'Tout' : 'All',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Liste défilable des groupes musculaires
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: availableMuscleGroups.length,
                              itemBuilder: (context, index) {
                                final group = availableMuscleGroups[index];
                                final isSelected = selectedMuscleFilters.contains(group);

                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index < availableMuscleGroups.length - 1 ? 6 : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          selectedMuscleFilters.remove(group);
                                        } else {
                                          selectedMuscleFilters.add(group);
                                        }
                                        filterExercises();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF0B132B)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0B132B)
                                              : const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          group,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF64748B),
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Indicateur du nombre d'exercices trouvés
                    Row(
                      children: [
                        Text(
                          'exercise_found'.tr(locService.currentLanguageCode)
                              .replaceAll('{count}', filteredExercises.length.toString())
                              .replaceAll('{plural}', filteredExercises.length > 1 ? 's' : ''),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bouton pour créer un exercice custom si pas de résultats
                    if (searchController.text.isNotEmpty && filteredExercises.isEmpty)
                      GestureDetector(
                        onTap: () async {
                          final tempName = searchController.text.trim();
                          Navigator.pop(context);
                          // Ajouter immédiatement en local (custom) sans attendre l'UUID
                          _showSetsCountDialog(tempName, 'workout_custom_type'.tr(LocalizationService.instance.currentLanguageCode), exerciseId: null, isCustom: true);
                          // Création en arrière-plan puis synchronisation de l'UUID
                          final created = await db.DatabaseService.createCustomExercise(
                            name: tempName,
                            muscleGroup: 'workout_custom_type'.tr(LocalizationService.instance.currentLanguageCode),
                          );
                          if (created != null && mounted) {
                            setState(() {
                              for (int i = 0; i < _exercises.length; i++) {
                                final e = _exercises[i];
                                if (e.exercise.isCustom && e.exercise.name == tempName) {
                                  _exercises[i] = e.copyWith(
                                    exercise: e.exercise.copyWith(
                                      id: created.id,
                                      isCustom: true,
                                    ),
                                  );
                                }
                              }
                            });
                          }
                          // Reset après un délai
                          Timer(const Duration(milliseconds: 200), () {
                            if (mounted) {
                              setState(() {
                                _addExercisePressed = false;
                              });
                            }
                          });
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
                                    Consumer<LocalizationService>(
                                      builder: (context, locService, _) => Text(
                                        'workout_create_new_exercise'.tr(locService.currentLanguageCode),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
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
                                Navigator.pop(context);
                                _showSetsCountDialog(
                                  exercise.name,
                                  exercise.muscleGroup,
                                  exerciseId: exercise.id,
                                );
                                // Reset après un délai
                                Timer(const Duration(milliseconds: 200), () {
                                  if (mounted) {
                                    setState(() {
                                      _addExercisePressed = false;
                                    });
                                  }
                                });
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  exercise.name,
                                                  style: TextStyle(
                                                    fontSize: exercise.name.length > 30 ? 12 : 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF1A1A1A),
                                                    height: 1.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                ),
                                              if (exercise.isCustom) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0B132B).withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: const Color(0xFF0B132B).withOpacity(0.2)),
                                                  ),
                                                  child: Consumer<LocalizationService>(
                                                    builder: (context, locService, _) => Text(
                                                      'workout_custom_badge'.tr(locService.currentLanguageCode),
                                                      style: const TextStyle(fontSize: 10, color: Color(0xFF0B132B), fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              // Tag de fréquence
                                              () {
                                                final sessionCount = exerciseSessionCounts[exercise.name] ?? 0;

                                                if (sessionCount == 0) {
                                                  // Nouveau - Style comme les kcal dans week history (bleu foncé avec lettres blanches)
                                                  return Row(
                                                    children: [
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF0B132B),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          LocalizationService.instance.isFrench ? 'Nouveau' : 'New',
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                } else {
                                                  // Déjà utilisé - Couleur principale de l'app
                                                  return Row(
                                                    children: [
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF0B132B).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: const Color(0xFF0B132B).withOpacity(0.3), width: 1),
                                                        ),
                                                        child: Text(
                                                          LocalizationService.instance.isFrench
                                                              ? '$sessionCount ${sessionCount == 1 ? 'fois' : 'fois'}'
                                                              : '$sessionCount ${sessionCount == 1 ? 'time' : 'times'}',
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF0B132B),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                              }(),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (exercise.isCustom)
                                      IconButton(
                                        icon: const Icon(LucideIcons.eyeOff, size: 16, color: Color(0xFF64748B)),
                                        tooltip: 'hide'.tr(LocalizationService.instance.currentLanguageCode),
                                        onPressed: () async {
                                          final ok = await db.DatabaseService.hideCustomExercise(exercise.id);
                                          if (ok) {
                                            setModalState(() {
                                              filteredExercises.removeAt(index);
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Consumer<LocalizationService>(
                                                    builder: (context, locService, _) => Text('workout_exercise_hidden'.tr(locService.currentLanguageCode)),
                                                  ),
                                                  duration: const Duration(seconds: 2)
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      )
                                    else
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFilterModal(BuildContext context, StateSetter setModalState, List<String> availableMuscleGroups, Set<String> currentFilters, Function(Set<String>) onFiltersSelected) {
    if (availableMuscleGroups.isEmpty) {
      if (kDebugMode) debugPrint('⚠️ Aucun groupe musculaire disponible');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Copier les filtres actuels pour modification locale
        Set<String> tempSelectedFilters = Set.from(currentFilters);

        return StatefulBuilder(
          builder: (context, setFilterModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
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

                    // Header avec titre et bouton "Effacer tout"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<LocalizationService>(
                          builder: (context, locService, _) => Text(
                            'filters'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        if (tempSelectedFilters.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setFilterModalState(() {
                                tempSelectedFilters.clear();
                              });
                            },
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'clear_all'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Groupes musculaires avec Wrap (bulles horizontales - sélection multiple)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableMuscleGroups.map((group) {
                            final isSelected = tempSelectedFilters.contains(group);
                            return GestureDetector(
                              onTap: () {
                                setFilterModalState(() {
                                  if (isSelected) {
                                    tempSelectedFilters.remove(group);
                                  } else {
                                    tempSelectedFilters.add(group);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0B132B)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0B132B)
                                        : const Color(0xFFE2E8F0),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  group,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bouton Appliquer avec compteur
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          onFiltersSelected(tempSelectedFilters);
                          Navigator.pop(context);
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
                            tempSelectedFilters.isEmpty
                                ? 'apply_filters'.tr(locService.currentLanguageCode)
                                : '${'apply_filters'.tr(locService.currentLanguageCode)} (${tempSelectedFilters.length})',
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
            );
          },
        );
      },
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
                color: Colors.black.withOpacity(0.1),
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
                    color: const Color(0xFF0B132B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.bookmark,
                    size: 32,
                    color: Color(0xFF0B132B),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'workout_save_session_title'.tr(locService.currentLanguageCode),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'workout_save_session_question_detail'.tr(locService.currentLanguageCode).replaceAll('{0}', widget.sessionName),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // OPTIMISATION: Invalider les caches même sans sauvegarde
                          try {
                            SportDashboardService.forceInvalidateAllCaches();
                            DashboardService.invalidateAndRefreshAfterWorkout();
                            debugPrint('✅ Caches Sport invalidés');
                          } catch (e) {
                            debugPrint('⚠️ Erreur invalidation caches: $e');
                          }

                          Navigator.pop(context); // Fermer popup

                          // Navigation d'abord - retourner à la page précédente
                          Navigator.pop(context);

                          // ⚡ FIX: Pop supplémentaire pour Coach Ryze (isFromAI)
                          if (widget.isFromAI) {
                            Navigator.pop(context); // Fermer AI Generator → retour musculation
                            debugPrint('✅ Navigation pop x3 effectuée (bouton Non - Coach Ryze)');
                          }

                          _triggerWorkoutCelebration();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, _) => Text(
                            'no'.tr(locService.currentLanguageCode),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _saveAsProgram(widget.sessionName);

                          // OPTIMISATION: Invalider les caches après sauvegarde
                          try {
                            SportDashboardService.forceInvalidateAllCaches();
                            DashboardService.invalidateAndRefreshAfterWorkout();
                            debugPrint('✅ Caches Sport invalidés après sauvegarde programme');
                          } catch (e) {
                            debugPrint('⚠️ Erreur invalidation caches: $e');
                          }

                          Navigator.pop(context); // Fermer popup

                          // Navigation d'abord - retourner à la page précédente
                          Navigator.pop(context);

                          // ⚡ FIX: Pop supplémentaire pour Coach Ryze (isFromAI)
                          if (widget.isFromAI) {
                            Navigator.pop(context); // Fermer AI Generator → retour musculation
                            debugPrint('✅ Navigation pop x3 effectuée (bouton Oui - Coach Ryze)');
                          }

                          _triggerWorkoutCelebration();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, _) => Text(
                            'yes'.tr(locService.currentLanguageCode),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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

  Future<void> _updateExistingSession() async {
    try {
      debugPrint('✏️ Mise à jour de la séance existante: ${widget.editSessionId}');

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Supprimer tous les sets existants pour cette séance
      await Supabase.instance.client
          .from('workout_set_history')
          .delete()
          .eq('history_session_id', widget.editHistorySessionId!);

      debugPrint('🗑️ Anciens sets supprimés');

      // 2. Insérer les nouveaux sets
      final List<Map<String, dynamic>> rows = [];
      int globalOrder = 1;

      for (final we in _exercises) {
        for (final set in we.sets.where((s) => s.reps > 0)) {
          rows.add({
            'user_id': userId,
            'history_session_id': widget.editHistorySessionId!,
            'exercise_name': we.exercise.name,
            'set_order': globalOrder,
            'reps': set.reps,
            'weight': set.weight,
            'performed_at': widget.editSessionDate ?? DateTime.now().toIso8601String().split('T')[0],
            'session_name': widget.sessionName,
          });
          globalOrder++;
        }
      }

      if (rows.isNotEmpty) {
        await Supabase.instance.client
            .from('workout_set_history')
            .insert(rows);
        debugPrint('✅ ${rows.length} nouveaux sets insérés');
      }

      // 3. Mettre à jour le résumé de la séance
      final totalWeight = _exercises.fold<double>(
        0,
        (sum, we) => sum + we.sets.fold<double>(
          0,
          (setSum, s) => setSum + (s.weight * s.reps),
        ),
      );

      final completedSets = _exercises.fold<int>(
        0,
        (sum, we) => sum + we.sets.where((s) => s.reps > 0).length,
      );

      await Supabase.instance.client
          .from('workout_session_summaries')
          .update({
            'session_name': widget.sessionName,
            'duration_minutes': _effectiveDurationMinutes ?? _displayedDuration.inMinutes,
            'calories_burned': _estimatedCalories,
            'intensity': _selectedIntensity != null ? _mapIntensityToDbValue(_selectedIntensity!) : null,
            'total_weight_kg': totalWeight.round(),
            'total_sets': completedSets,
          })
          .eq('id', widget.editSessionId!);

      debugPrint('✅ Résumé de séance mis à jour');

      // 4. Invalider les caches
      SportDashboardService.forceInvalidateAllCaches();
      DashboardService.invalidateAndRefreshAfterWorkout();
      await GlobalStateManager.instance.refreshSportData();

      // 5. Retourner avec succès
      if (mounted) {
        Navigator.pop(context, true); // Retourner true pour indiquer que la modification a réussi
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour de la séance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _validateSession() async {
    // MODE ÉDITION : Mettre à jour la séance existante
    if (widget.isEditMode && widget.editSessionId != null && widget.editHistorySessionId != null) {
      await _updateExistingSession();
      return;
    }

    // MODE CRÉATION : Créer une nouvelle séance
    // Créer la session complète et validée
    final sessionEndTime = DateTime.now();

    // Generate unique session name with automatic numbering if needed
    final uniqueSessionName = await db.DatabaseService.generateUniqueSessionName(
      baseSessionName: widget.sessionName,
      performedAtDate: sessionEndTime,
    );

    final completedSession = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: uniqueSessionName,
      startTime: _sessionStartTime ?? DateTime.now(),
      endTime: sessionEndTime,
      exercises: _exercises,
      isCompleted: true,
    );

    // Vérifier si on est hors ligne (variable mutable pour le fallback)
    bool isOffline = _offlineStatus != null && !_offlineStatus!.isOnline;

    // Déterminer le type de source de la séance
    String sessionSource;
    String? guidedTemplateId;

    if (widget.isFromAI) {
      // Séance générée par l'IA directement -> traiter comme AI coach
      sessionSource = 'ai_coach';
      guidedTemplateId = null; // Pas de template pour les séances IA directes
      if (kDebugMode) debugPrint('🤖 Séance IA directe détectée: session_source=ai_coach, guidedTemplateId=null');
    } else if (widget.isFromProgram) {
      // Séance depuis un programme guidé - vérifier si c'est un template IA sauvegardé
      final potentialTemplateId = widget.guidedTemplateId ?? _inferGuidedTemplateId();

      // Vérifier si ce template a été généré par l'IA
      bool isTemplateFromAI = false;
      if (potentialTemplateId != null) {
        isTemplateFromAI = await db.DatabaseService.isTemplateFromAI(potentialTemplateId);
      }

      if (isTemplateFromAI) {
        // Template généré par l'IA et sauvegardé -> traiter comme AI coach
        sessionSource = 'ai_coach';
        guidedTemplateId = null; // Ne pas référencer le template car il n'existe pas dans workout_templates
        if (kDebugMode) debugPrint('🤖 Séance IA sauvegardée détectée (template=$potentialTemplateId): session_source=ai_coach, guidedTemplateId=null');
      } else {
        // Vrai template guidé de l'application
        sessionSource = 'guided_template';
        guidedTemplateId = potentialTemplateId;
        if (kDebugMode) debugPrint('📋 Séance guidée détectée: session_source=guided_template, guidedTemplateId=$guidedTemplateId');
      }
    } else {
      // Séance créée manuellement
      sessionSource = 'manual';
      guidedTemplateId = null;
      if (kDebugMode) debugPrint('✍️ Séance manuelle détectée: session_source=manual, guidedTemplateId=null');
    }

    // 📊 Analytics: Workout completed
    AnalyticsService.logWorkoutCompleted(
      workoutType: 'strength',
      durationMinutes: _displayedDuration.inMinutes,
      exerciseCount: completedSession.exercises.length,
      caloriesBurned: _estimatedCalories,
    );

    // Historiser la séance (manuel, guidé, ou IA) avec fallback offline
    bool savedSuccessfully = false;
    try {
      await db.DatabaseService.persistCompletedWorkoutAsHistory(
        session: completedSession,
        guidedTemplateId: guidedTemplateId,
        sessionSource: sessionSource,
        intensity: _selectedIntensity != null ? _mapIntensityToDbValue(_selectedIntensity!) : null,
        durationMinutes: _displayedDuration.inMinutes,
        caloriesBurned: _estimatedCalories,
      );

      savedSuccessfully = true;
      isOffline = false;

      if (kDebugMode) debugPrint('✅ Séance sauvegardée en ligne avec succès');

      // OPTIMISATION: Invalider les caches pour forcer le rafraîchissement
      try {
        SportDashboardService.forceInvalidateAllCaches();
        DashboardService.invalidateAndRefreshAfterWorkout();

        // Recharger TOUTES les données Sport depuis la DB
        await GlobalStateManager.instance.refreshSportData();

        if (kDebugMode) debugPrint('✅ Caches Sport invalidés après séance musculation');
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Erreur invalidation caches: $e');
      }
    } catch (e) {
      // FALLBACK OFFLINE: Sauvegarder localement pour synchronisation ultérieure
      if (kDebugMode) debugPrint('❌ Erreur sauvegarde en ligne: $e');
      if (kDebugMode) debugPrint('💾 Activation du mode offline - Sauvegarde locale...');

      isOffline = true;

      try {
        await _offlineService.saveSessionForSync(
          completedSession,
          guidedTemplateId: guidedTemplateId,
          sessionSource: sessionSource,
          intensity: _selectedIntensity != null ? _mapIntensityToDbValue(_selectedIntensity!) : null,
          durationMinutes: _displayedDuration.inMinutes,
          caloriesBurned: _estimatedCalories,
        );

        savedSuccessfully = true;
        if (kDebugMode) debugPrint('✅ Séance sauvegardée en mode offline - Sync auto à la reconnexion');
      } catch (offlineError) {
        if (kDebugMode) debugPrint('❌ Erreur sauvegarde offline: $offlineError');
        savedSuccessfully = false;
      }
    }

    // Afficher un message selon le mode de sauvegarde
    if (mounted && savedSuccessfully) {
      if (isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.wifiOff, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'workout_session_saved_locally'.tr(locService.currentLanguageCode),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'workout_sync_on_reconnect'.tr(locService.currentLanguageCode),
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else if (mounted && !savedSuccessfully) {
      // Échec complet de la sauvegarde
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'workout_save_failed'.tr(locService.currentLanguageCode),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    // Appeler le callback pour valider la session
    if (widget.onSessionCompleted != null) {
      widget.onSessionCompleted!(completedSession);
    }

    if (kDebugMode) debugPrint('Séance validée: ${completedSession.name}');
    if (kDebugMode) debugPrint('- Durée totale: ${_formatDuration(completedSession.duration)}');
    if (kDebugMode) debugPrint('- ${completedSession.completedSets}/${completedSession.totalSets} séries terminées');
  }

  // Si la session vient d'un programme, tenter d'extraire l'id depuis le nom (format optionnel) sinon null
  String? _inferGuidedTemplateId() {
    // Si on injecte le screen avec un programme, idéalement on passerait l'id en paramètre.
    // Ici on tente juste de parser si le nom est au format "<nom> (#<id>)";
    final match = RegExp(r'#([0-9a-fA-F-]{36})').firstMatch(widget.sessionName);
    return match != null ? match.group(1) : null;
  }

  void _saveAsProgram(String sessionName) async {
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
    
    try {
      // Sauvegarder dans Supabase
      final templateId = await db.DatabaseService.saveUserWorkoutTemplate(
        completedSession,
        isFromAI: widget.isFromAI, // ⚡ Pass the Coach Ryze flag
      );
      if (kDebugMode) debugPrint('✅ Template utilisateur sauvegardé avec ID: $templateId');
      
      // Créer le programme à partir de la séance (pour compatibilité avec l'ancien système)
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
        id: templateId,
        name: sessionName,
        description: 'workout_program_from_manual'.tr(LocalizationService.instance.currentLanguageCode),
        type: 'workout_custom_type'.tr(LocalizationService.instance.currentLanguageCode),
        estimatedDuration: durationInMinutes,
        exercises: programExercises,
        isCustom: true, // Toujours custom quand sauvegardé par l'utilisateur
        isFromAI: widget.isFromAI, // ⚡ Marquer si vient de Coach Ryze
      );
      
      // Appeler les callbacks pour sauvegarder dans l'écran parent
      if (widget.onSessionCompleted != null) {
        widget.onSessionCompleted!(completedSession);
      }
      
      if (widget.onProgramSaved != null) {
        widget.onProgramSaved!(workoutProgram);
      }
      
      if (kDebugMode) debugPrint('=== DEBUG SAUVEGARDE ===');
      if (kDebugMode) debugPrint('Séance validée: ${completedSession.name}');
      if (kDebugMode) debugPrint('- Template ID: $templateId');
      if (kDebugMode) debugPrint('- Heure début: $_sessionStartTime');
      if (kDebugMode) debugPrint('- Heure fin: $sessionEndTime');
      if (kDebugMode) debugPrint('- Durée en minutes: $durationInMinutes');
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur lors de la sauvegarde du template: $e');
      // Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_save_failed'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showSessionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CustomScrollbar(
            child: SingleChildScrollView(
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
                        color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 32,
                    color: Color(0xFF10B981),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                    Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'workout_session_completed'.tr(locService.currentLanguageCode),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                
                const SizedBox(height: 8),
                
                    Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'workout_session_summary'.tr(locService.currentLanguageCode),
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => _buildSummaryMetric(
                                'workout_duration'.tr(locService.currentLanguageCode),
                                _formatDuration(_displayedDuration),
                                LucideIcons.clock,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => _buildSummaryMetric(
                                'exercises'.tr(locService.currentLanguageCode),
                                '${_exercises.length}',
                                LucideIcons.dumbbell,
                              ),
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
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => _buildSummaryMetric(
                                'workout_sets_count'.tr(locService.currentLanguageCode),
                                '$_completedSets',
                                LucideIcons.repeat,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => _buildSummaryMetric(
                                'workout_volume'.tr(locService.currentLanguageCode),
                                UnitService.instance.formatWeight(_totalWeight, decimals: 0),
                                LucideIcons.activity,
                              ),
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
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => _buildSummaryMetric(
                                'calories'.tr(locService.currentLanguageCode),
                                '$_estimatedCalories kcal',
                                LucideIcons.flame,
                              ),
                            ),
                          ),
                          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                          Expanded(
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => _buildSummaryMetric(
                                'workout_intensity'.tr(locService.currentLanguageCode),
                                _selectedIntensity != null 
                                  ? 'workout_intensity_${_selectedIntensity}'.tr(locService.currentLanguageCode) 
                                  : '—',
                                _selectedIntensity == 'high' ? LucideIcons.zap : _selectedIntensity == 'moderate' ? LucideIcons.activity : LucideIcons.wind,
                              ),
                            ),
                          ),
                        ],
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

                      // ⚡ Popup uniquement si PAS un programme prédéfini (manuel ou Coach Ryze)
                      if (!widget.isFromProgram && _exercises.isNotEmpty) {
                        _showSaveSessionDialog();
                      } else {
                        // Programmes guidés: invalider caches et retourner
                        try {
                          SportDashboardService.forceInvalidateAllCaches();
                          DashboardService.invalidateAndRefreshAfterWorkout();
                          debugPrint('✅ Caches Sport invalidés');
                        } catch (e) {
                          debugPrint('⚠️ Erreur invalidation caches: $e');
                        }

                        // Navigation d'abord - retourner à la musculation
                        Navigator.pop(context);

                        _triggerWorkoutCelebration();
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
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'session_end_session'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  void _showIntensityAndDurationDialog() {
    // ✅ NOUVEAU : Auto-supprimer les séries vides en fin d'exercice
    setState(() {
      for (int i = 0; i < _exercises.length; i++) {
        final exercise = _exercises[i];

        // Trouver la dernière série avec des reps
        int lastValidSetIndex = -1;
        for (int j = exercise.sets.length - 1; j >= 0; j--) {
          if (exercise.sets[j].reps > 0) {
            lastValidSetIndex = j;
            break;
          }
        }

        // Supprimer toutes les séries vides après la dernière série valide
        if (lastValidSetIndex >= 0 && lastValidSetIndex < exercise.sets.length - 1) {
          final validSets = exercise.sets.sublist(0, lastValidSetIndex + 1);
          _exercises[i] = exercise.copyWith(sets: validSets);
          if (kDebugMode) debugPrint('✂️ Auto-suppression de ${exercise.sets.length - validSets.length} série(s) vide(s) pour ${exercise.exercise.name}');
        }
      }
    });

    final TextEditingController minutesController = TextEditingController(
      text: (_effectiveDurationMinutes ?? (_sessionDuration.inMinutes > 0 ? _sessionDuration.inMinutes : 1)).toString(),
    );
    String? selected = _selectedIntensity ?? 'moderate';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'workout_intensity_duration_title'.tr(locService.currentLanguageCode),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_intensity_question'.tr(locService.currentLanguageCode),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Row(
                  children: [
                    _buildIntensityChip(
                      'workout_intensity_low'.tr(locService.currentLanguageCode), 
                      selected == 'low', 
                      () => setStateDialog(() => selected = 'low')
                    ),
                    const SizedBox(width: 8),
                    _buildIntensityChip(
                      'workout_intensity_moderate'.tr(locService.currentLanguageCode), 
                      selected == 'moderate', 
                      () => setStateDialog(() => selected = 'moderate')
                    ),
                    const SizedBox(width: 8),
                    _buildIntensityChip(
                      'workout_intensity_high'.tr(locService.currentLanguageCode), 
                      selected == 'high', 
                      () => setStateDialog(() => selected = 'high')
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_effective_duration'.tr(locService.currentLanguageCode), 
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))
                ),
              ),
              const SizedBox(height: 8),
              NumericTextField(
                controller: minutesController,
                allowDecimals: false,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'minutes'.tr(LocalizationService.instance.currentLanguageCode),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'cancel'.tr(locService.currentLanguageCode), 
                  style: const TextStyle(color: Color(0xFF64748B))
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final minutes = int.tryParse(minutesController.text.trim());
                setState(() {
                  _selectedIntensity = selected;
                  _effectiveDurationMinutes = (minutes != null && minutes > 0) ? minutes : (_sessionDuration.inMinutes > 0 ? _sessionDuration.inMinutes : 1);
                });
                Navigator.pop(context);
                _showSessionSummary();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B132B)),
              child: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'validate'.tr(locService.currentLanguageCode), 
                  style: const TextStyle(color: Colors.white)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : const Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildWorkoutScreen(),
        _buildHistoryBubble(),
        // Overlay d'écoute vocale (quand micro actif)
        if (_isVoiceListening) _buildVoiceListeningOverlay(),
        // Bouton Undo (si actif)
        if (_showUndoButton) _buildUndoButton(),
      ],
    );
  }

  Widget _buildWorkoutScreen() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C2951), // Bleu secondaire
        resizeToAvoidBottomInset: true, // Important pour gérer le clavier
      body: SafeArea(
          child: Column(
            children: [
              // Header compact figé - seulement nom séance + timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
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
                          fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Row(
                    children: [
                      // Indicateur de mode offline
                      if (_offlineStatus != null && !_offlineStatus!.isOnline) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.wifiOff,
                                size: 14,
                                color: Colors.orange.shade300,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'offline'.tr(LocalizationService.instance.currentLanguageCode),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
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
                ],
                ),
              ),

              // Contenu scrollable
              Expanded(
                child: _exercises.isEmpty 
                    ? _buildEmptyState() 
                    : _buildExerciseContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
                const Spacer(),
                const Icon(
                  LucideIcons.dumbbell,
                  size: 64,
                  color: Colors.white30,
                ),
                const SizedBox(height: 16),
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'workout_no_exercises_added'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'workout_start_by_adding_exercise'.tr(locService.currentLanguageCode),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
                const Spacer(),
          
          // Boutons en bas pour état vide
          Column(
            children: [
              // Ligne des boutons série et exercice
              Row(
                children: [
                  // Bouton ajouter série (désactivé si vide)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null, // Désactivé
                      icon: const Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: Colors.white30,
                      ),
                      label: Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'workout_set'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white30,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        side: BorderSide(color: Colors.white30, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Bouton ajouter exercice
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showAddExerciseDialog,
                      icon: Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: _addExercisePressed ? Colors.white : Colors.white,
                      ),
                      label: Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'workout_add_exercise'.tr(locService.currentLanguageCode),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _addExercisePressed ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _addExercisePressed 
                            ? const Color(0xFF0B132B) 
                            : Colors.white.withOpacity(0.2),
                        side: BorderSide(
                          color: _addExercisePressed 
                              ? const Color(0xFF0B132B)
                              : Colors.white.withOpacity(0.3), 
                          width: 2
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bouton terminer séance (désactivé si vide)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null, // Désactivé
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white30,
                    side: BorderSide(color: Colors.white30, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      'session_end_session'.tr(locService.currentLanguageCode),
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
        ],
      ),
    );
  }

  Widget _buildExerciseContent() {
    return Column(
      children: [
        // Section exercice figée - compact
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              // Navigation entre exercices + nom
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _currentExerciseIndex > 0 ? _previousExercise : null,
                      icon: Icon(
                        LucideIcons.chevronLeft,
                        color: _currentExerciseIndex > 0 ? Colors.white : Colors.white30,
                      size: 28,
                      ),
                    ),
                    
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  _exercises[_currentExerciseIndex].exercise.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                key: _historyIconKey,
                                onTap: _toggleHistoryBubble,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    LucideIcons.calendar,
                                    size: 18,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Supprimé l'affichage du groupe musculaire
                        ],
                      ),
                    ),
                    
                    IconButton(
                      onPressed: _currentExerciseIndex < _exercises.length - 1 ? _nextExercise : null,
                      icon: Icon(
                        LucideIcons.chevronRight,
                        color: _currentExerciseIndex < _exercises.length - 1 ? Colors.white : Colors.white30,
                      size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                                 // Indicateur d'exercice
                 Consumer<LocalizationService>(
                   builder: (context, locService, _) => Text(
                     'workout_exercise_counter'.tr(locService.currentLanguageCode)
                       .replaceAll('{current}', '${_currentExerciseIndex + 1}')
                       .replaceAll('{total}', '${_exercises.length}'),
                     style: TextStyle(
                       fontSize: 12,
                       color: Colors.white.withOpacity(0.5),
                     ),
                   ),
                 ),

              const SizedBox(height: 16),

              // En-têtes des colonnes (figés)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  '${'workout_weight'.tr(locService.currentLanguageCode)} (${UnitService.instance.weightUnit})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  'workout_reps'.tr(locService.currentLanguageCode),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 136), // Espace pour 3 boutons (micro + copier + supprimer) = ~32*3 + 8*3 = 120 + marges
                  ],
                ),
              ),
                          ],
                        ),
                      ),
                      
        // Liste des séries (scrollable)
                      Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => true,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                children: [
                  // Séries
                  ...List.generate(
                    _getDisplayedSetsCount(),
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildSetBubbleWithFocus(index),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons en bas dans la partie scrollable
                  Column(
                    children: [
                      // Ligne des boutons série et exercice
                      Row(
                        children: [
                          // Bouton ajouter série
                          Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addNewSet,
                              icon: Icon(
                            LucideIcons.plus,
                                size: 16,
                                color: _addSeriePressed 
                                    ? Colors.white
                                    : Colors.white,
                              ),
                              label: Text(
                                'set'.tr(LocalizationService.instance.currentLanguageCode),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                                  color: _addSeriePressed 
                                      ? Colors.white
                                      : Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                                backgroundColor: _addSeriePressed 
                                    ? const Color(0xFF0B132B) 
                                    : Colors.white.withOpacity(0.2),
                                side: BorderSide(
                                  color: _addSeriePressed 
                                      ? const Color(0xFF0B132B)
                                      : Colors.white.withOpacity(0.3), 
                                  width: 2
                                ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                          const SizedBox(width: 12),

              // Bouton ajouter exercice
                          Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddExerciseDialog,
                              icon: Icon(
                    LucideIcons.plus,
                                size: 16,
                                color: _addExercisePressed ? Colors.white : Colors.white,
                  ),
                              label: Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  'workout_add_exercise'.tr(locService.currentLanguageCode),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _addExercisePressed ? Colors.white : Colors.white,
                                  ),
                                ),
                              ),
                  style: OutlinedButton.styleFrom(
                                backgroundColor: _addExercisePressed 
                                    ? const Color(0xFF0B132B) 
                                    : Colors.white.withOpacity(0.2),
                                side: BorderSide(
                                  color: _addExercisePressed 
                                      ? const Color(0xFF0B132B)
                                      : Colors.white.withOpacity(0.3), 
                                  width: 2
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                          ),
                        ],
              ),

                      const SizedBox(height: 12),

                      // Bouton terminer séance
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                          onPressed: _showConfirmEndSessionDialog,
                  style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B132B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                            elevation: 0,
                  ),
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      'session_end_session'.tr(locService.currentLanguageCode),
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetBubbleWithFocus(int setIndex) {
    final currentExercise = _exercises[_currentExerciseIndex];
    final isActive = _activeSetIndex == setIndex;
    
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
      key: _getSetKey(setIndex),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentSet.isCompleted 
            ? const Color(0xFF10B981).withOpacity(0.15)
            : isActive 
                ? const Color(0xFF0B132B).withOpacity(0.15) // Série active
                : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: currentSet.isCompleted 
            ? Border.all(color: const Color(0xFF10B981).withOpacity(0.6), width: 2)
            : isActive
                ? Border.all(color: const Color(0xFF0B132B).withOpacity(0.8), width: 2) // Bordure série active
                : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          // Indicateur de série active
          if (isActive && !currentSet.isCompleted)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0B132B),
                shape: BoxShape.circle,
              ),
            ),
          
          // Input Poids
          Expanded(
            child: _buildNumberField(
              controller: _getWeightController(setIndex),
              focusNode: _getWeightFocusNode(setIndex),
              hintText: '0',
              onChanged: (value) {
                final inputWeight = double.tryParse(value) ?? 0.0;
                // Convertir l'entrée utilisateur (lbs si impérial) en kg pour le stockage
                final weightKg = UnitService.instance.storageWeight(inputWeight);
                _updateSetValue(setIndex, weight: weightKg);
              },
              setIndex: setIndex,
              isDecimal: true,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Input Répétitions
          Expanded(
            child: _buildNumberField(
              controller: _getRepsController(setIndex),
              focusNode: _getRepsFocusNode(setIndex),
              hintText: _getRepsSuggestionHint(),
              onChanged: (value) {
                final reps = int.tryParse(value) ?? 0;
                _updateSetValue(setIndex, reps: reps);
              },
              setIndex: setIndex,
              isDecimal: false,
            ),
          ),
          
          const SizedBox(width: 12),

          // 🎤 Bouton micro par série (visible si série précédente non vide)
          if (_canShowVoiceButtonForSet(setIndex))
            GestureDetector(
              onTap: () => _startVoiceInputForSet(setIndex),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: _isVoiceListening && _activeSetIndex == setIndex
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF10B981), // Vert emerald-500
                            Color(0xFF059669), // Vert emerald-600
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _isVoiceListening && _activeSetIndex == setIndex
                      ? null
                      : const Color(0xFF1C2951), // Bleu de l'app (visible)
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.mic,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),

          const SizedBox(width: 8),

          // ➕ NOUVEAU : Bouton copier vers série suivante
          GestureDetector(
            onTap: () => _copyToNextSet(setIndex),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1C2951).withOpacity(0.3), // Bleu de l'app
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.arrowDown,
                color: Colors.white, // Blanc
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
                color: Colors.red.withOpacity(0.2),
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

  // Composant réutilisable pour les champs de saisie
  Widget _buildNumberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required Function(String) onChanged,
    required int setIndex,
    required bool isDecimal,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onTap: () => _scrollToField(setIndex),
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) {
        // Passer au champ suivant ou fermer le clavier
        focusNode.unfocus();
      },
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
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
    );
  }

  void _showConfirmEndSessionDialog() {
    // ✅ NOUVEAU : Détecter séries incomplètes et séries vides en fin d'exercice
    final List<String> incompleteSets = [];
    final List<String> emptyTrailingSets = [];

    for (var i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];

      // Trouver la dernière série avec des reps
      int lastValidSetIndex = -1;
      for (int j = exercise.sets.length - 1; j >= 0; j--) {
        if (exercise.sets[j].reps > 0) {
          lastValidSetIndex = j;
          break;
        }
      }

      // Séries vides en fin (après la dernière série valide)
      if (lastValidSetIndex >= 0 && lastValidSetIndex < exercise.sets.length - 1) {
        final emptyCount = exercise.sets.length - lastValidSetIndex - 1;
        final plural = emptyCount > 1 ? 's' : '';
        final message = 'series_empty'.tr(LocalizationService.instance.currentLanguageCode)
            .replaceAll('{count}', emptyCount.toString())
            .replaceAll('{plural}', plural);
        emptyTrailingSets.add('${exercise.exercise.name}: $message');
      }

      // Séries incomplètes (avec poids mais sans reps, ou gaps)
      for (int j = 0; j < exercise.sets.length; j++) {
        final set = exercise.sets[j];
        if (set.reps == 0 && set.weight > 0) {
          final message = 'series_incomplete'.tr(LocalizationService.instance.currentLanguageCode)
              .replaceAll('{setNumber}', (j + 1).toString());
          incompleteSets.add('${exercise.exercise.name} - $message');
        }
      }
    }

    final hasIncompleteSets = incompleteSets.isNotEmpty;
    final hasEmptyTrailingSets = emptyTrailingSets.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Consumer<LocalizationService>(
          builder: (context, locService, _) => Text(
            hasIncompleteSets || hasEmptyTrailingSets
                ? 'warning_attention'.tr(locService.currentLanguageCode)
                : 'workout_confirm_end_session'.tr(locService.currentLanguageCode),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        content: Consumer<LocalizationService>(
          builder: (context, locService, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasIncompleteSets) ...[
                Text(
                  'incomplete_sets_detected'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 8),
                ...incompleteSets.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• $s',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                )),
                const SizedBox(height: 12),
              ],
              if (hasEmptyTrailingSets) ...[
                Text(
                  'empty_sets_will_be_removed'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 8),
                ...emptyTrailingSets.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• $s',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                )),
                const SizedBox(height: 12),
              ],
              Text(
                hasIncompleteSets || hasEmptyTrailingSets
                    ? 'want_to_finish_anyway'.tr(locService.currentLanguageCode)
                    : 'workout_confirm_end_session_message'.tr(locService.currentLanguageCode),
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  fontWeight: hasIncompleteSets || hasEmptyTrailingSets
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'workout_cancel'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog de confirmation
              // Demander intensité + durée avant le bilan
              _showIntensityAndDurationDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C2951),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'finish'.tr(locService.currentLanguageCode),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Générer le placeholder pour les répétitions selon les suggestions
  String _getRepsSuggestionHint() {
    if (_currentExerciseIndex < 0 || _currentExerciseIndex >= _exercises.length) {
      return '0';
    }
    
    final currentExercise = _exercises[_currentExerciseIndex];
    final repsMin = currentExercise.suggestedRepsMin;
    final repsMax = currentExercise.suggestedRepsMax;
    
    if (repsMin != null && repsMax != null) {
      return '$repsMin-$repsMax';
    } else if (repsMin != null) {
      return '$repsMin+';
    } else if (repsMax != null) {
      return '≤$repsMax';
    } else {
      return '0';
    }
  }

  Widget _buildHistoryBubble() {
    if (!_showHistoryBubble) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleWidth = screenWidth * 0.9;
    final maxSets = (_exerciseHistoryData?['maxSets'] as int?) ?? 0;
    final sessionHistory = (_exerciseHistoryData?['sessionHistory'] as List?) ?? [];

    return Positioned.fill(
      child: GestureDetector(
        onTap: _hideHistoryBubble, // Fermer en cliquant hors de la bulle
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Empêcher la fermeture en cliquant sur la bulle
              child: Container(
                width: bubbleWidth,
                constraints: const BoxConstraints(maxHeight: 450),
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2951).withOpacity(0.95), // Couleur de l'app avec transparence
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header de la bulle
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 22,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer<LocalizationService>(
                            builder: (context, locService, _) => Text(
                              'workout_session_history'.tr(locService.currentLanguageCode),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _hideHistoryBubble,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Contenu de la bulle
                    if (sessionHistory.isEmpty)
                      _buildNoHistoryMessage()
                    else
                      _buildHistoryTable(maxSets, sessionHistory),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoHistoryMessage() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            LucideIcons.dumbbell,
            size: 56,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'workout_no_history'.tr(locService.currentLanguageCode),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'workout_no_history_description'.tr(locService.currentLanguageCode),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
                height: 1.4,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable(int maxSets, List sessionHistory) {
    // Largeur totale du contenu scrollable
    final scrollableContentWidth = 80.0 + (maxSets * 70.0); // Max + Séries

    return Expanded(
      child: Row(
        children: [
          // Colonne Date fixe (non scrollable)
          Container(
            width: 70,
            child: Column(
              children: [
                // Header Date
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'date'.tr(locService.currentLanguageCode),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Dates des sessions
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: sessionHistory.map((session) {
                        return Container(
                          height: 40,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _formatBubbleDate(session['date']),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Partie scrollable horizontalement (Header + Data)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Container(
                width: scrollableContentWidth,
                child: Column(
                  children: [
                    // Header scrollable (Max + Séries)
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Header Max
                          Container(
                            width: 80,
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'workout_max'.tr(locService.currentLanguageCode),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.8),
                                  decoration: TextDecoration.none,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Headers des séries
                          ...List.generate(maxSets, (index) => Container(
                            width: 70,
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'workout_set_number'.tr(locService.currentLanguageCode).replaceAll('{number}', '${index + 1}'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.8),
                                  decoration: TextDecoration.none,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Données scrollables verticalement
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: sessionHistory.map((session) {
                            final allSets = (session['allSets'] as List<String>?) ?? [];
                            return Container(
                              height: 40,
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Charge Max
                                  Container(
                                    width: 80,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      session['weight'] ?? '—',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.7),
                                        decoration: TextDecoration.none,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  // Toutes les séries
                                  ...List.generate(maxSets, (seriesIndex) => Container(
                                    width: 70,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      seriesIndex < allSets.length ? _formatBubbleSetValue(allSets[seriesIndex]) : '—',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.6),
                                        decoration: TextDecoration.none,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBubbleDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}';
  }

  String _formatBubbleSetValue(String setValue) {
    // Raccourcir les valeurs pour la bulle
    if (setValue.contains(' kg x ')) {
      final parts = setValue.split(' kg x ');
      return '${parts[0]}×${parts[1]}';
    } else if (setValue.contains(' reps')) {
      return setValue.replaceAll(' reps', '');
    }
    return setValue;
  }

  // ========================================
  // VOICE INPUT METHODS
  // ========================================

  // ❌ SUPPRIMÉ : Ancien bouton micro flottant (remplacé par bouton micro par série)
  /*
  Widget _buildVoiceButton() {
    // Ancien système global - plus utilisé
  }
  */

  /// Bouton Undo avec countdown
  Widget _buildUndoButton() {
    return Positioned(
      left: 16,
      bottom: 100,
      child: GestureDetector(
        onTap: _undoVoiceInput,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.undo2,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  locService.currentLanguageCode == 'fr'
                      ? 'Annuler ($_undoCountdown)'
                      : 'Undo ($_undoCountdown)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Overlay en bas de page pendant l'écoute (plus fullscreen)
  Widget _buildVoiceListeningOverlay() {
    // Couleur verte pour l'écoute active - dégradé selon retry count pour feedback
    final micColor = _voiceRetryCount == 0
        ? const Color(0xFF10B981) // Vert emerald-500
        : _voiceRetryCount == 1
            ? const Color(0xFF059669) // Vert emerald-600
            : const Color(0xFF047857); // Vert emerald-700

    // Parser les données en temps réel pour feedback visuel
    final parsedData = _recognizedText.isNotEmpty
        ? _voiceService.parseVoiceInput(_recognizedText)
        : null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1C2951).withOpacity(0.98),
              const Color(0xFF0F172A),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: micColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête avec micro animé et bouton fermer
            Row(
              children: [
                // Animation micro pulsante avec effet de pulsation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercle extérieur pulsant
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: micColor.withOpacity(0.15),
                      ),
                    ),
                    // Cercle intérieur
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: micColor.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.mic,
                          size: 24,
                          color: micColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Texte principal et statut
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) {
                          String mainText;
                          if (_voiceRetryCount == 0) {
                            mainText = locService.currentLanguageCode == 'fr'
                                ? "En écoute..."
                                : "Listening...";
                          } else {
                            mainText = locService.currentLanguageCode == 'fr'
                                ? "Réessayez ($_voiceRetryCount/$_maxRetries)"
                                : "Try again ($_voiceRetryCount/$_maxRetries)";
                          }

                          return Text(
                            mainText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              shadows: _voiceRetryCount > 0
                                  ? [
                                      Shadow(
                                        color: micColor.withOpacity(0.5),
                                        blurRadius: 10,
                                      )
                                    ]
                                  : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      // Indicateur de ce qui est compris
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) {
                          if (parsedData != null && parsedData.hasData) {
                            final repsText = parsedData.reps != null
                                ? '${parsedData.reps} reps'
                                : '';
                            final weightText = parsedData.weight != null
                                ? '${UnitService.instance.formatWeight(parsedData.weight!.toDouble())}'
                                : '';
                            final separator = repsText.isNotEmpty && weightText.isNotEmpty ? ' • ' : '';

                            return Text(
                              '✓ $repsText$separator$weightText',
                              style: const TextStyle(
                                color: Color(0xFF10B981), // Vert success
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          } else {
                            return Text(
                              locService.currentLanguageCode == 'fr'
                                  ? 'Dites "10 reps 80 kilos"'
                                  : 'Say "10 reps 80 kilos"',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Bouton arrêter le micro (plus gros et visible)
                GestureDetector(
                  onTap: () async {
                    // Annuler les timers
                    _voiceAutoStopTimer?.cancel();
                    _lastValidDataDetectedAt = null;

                    await _voiceService.stopListening();
                    if (mounted) {
                      setState(() {
                        _isVoiceListening = false;
                        _recognizedText = '';
                        _voiceRetryCount = 0;
                        _voiceHasError = false;
                        _activeSetIndex = null;
                      });
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 22,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Texte reconnu en temps réel - plus grand et clair
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: parsedData != null && parsedData.hasData
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Text(
                _recognizedText.isEmpty ? "..." : _recognizedText,
                style: TextStyle(
                  color: parsedData != null && parsedData.hasData
                      ? const Color(0xFF10B981)
                      : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Feedback multi-sensoriel selon le type d'événement
  void _multiSensoryFeedback(String type) {
    switch (type) {
      case 'start':
        // Début d'écoute
        HapticService.instance.selectionClick();
        break;
      case 'success':
        // Succès de reconnaissance
        HapticService.instance.heavyImpact();
        break;
      case 'warning':
        // Avertissement (retry)
        HapticService.instance.mediumImpact();
        break;
      case 'error':
        // Erreur finale
        HapticService.instance.vibrate();
        break;
      case 'undo':
        // Action annulée
        HapticService.instance.lightImpact();
        break;
    }
  }

  /// Vérifie si le bouton micro peut être affiché pour une série
  /// Condition : Toutes les séries précédentes doivent être validées (reps > 0)
  bool _canShowVoiceButtonForSet(int setIndex) {
    if (_exercises.isEmpty) return false;

    final currentExercise = _exercises[_currentExerciseIndex];

    // Première série : toujours OK
    if (setIndex == 0) return true;

    // Vérifier que toutes les séries précédentes ont des reps
    for (int i = 0; i < setIndex; i++) {
      if (i < currentExercise.sets.length && currentExercise.sets[i].reps == 0) {
        return false; // Une série précédente n'est pas validée
      }
    }

    return true;
  }

  /// Copie les valeurs de la série actuelle vers la série suivante
  void _copyToNextSet(int setIndex) {
    if (_exercises.isEmpty) return;

    final currentExercise = _exercises[_currentExerciseIndex];
    if (setIndex >= currentExercise.sets.length) return;

    final currentSet = currentExercise.sets[setIndex];

    // Vérifier qu'il y a une série suivante
    if (setIndex + 1 < currentExercise.sets.length) {
      // Copier vers série existante (⚡ PAS DE VALIDATION VERTE)
      setState(() {
        final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
        updatedSets[setIndex + 1] = currentSet.copyWith(
          isCompleted: false, // ⚡ NE PAS valider la série copiée
        );
        _exercises[_currentExerciseIndex] = currentExercise.copyWith(sets: updatedSets);

        // Mettre à jour les controllers (convertir kg → unité d'affichage)
        final exerciseId = currentExercise.exercise.id;
        _weightControllers[exerciseId]?[setIndex + 1]?.text =
            currentSet.weight > 0 ? UnitService.instance.formatWeightValue(currentSet.weight, decimals: currentSet.weight % 1 == 0 ? 0 : 1) : '';
        _repsControllers[exerciseId]?[setIndex + 1]?.text =
            currentSet.reps > 0 ? currentSet.reps.toString() : '';
      });

      // Feedback
      HapticService.instance.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'values_copied_to_set'.tr(locService.currentLanguageCode)
                  .replaceAll('{setNumber}', (setIndex + 2).toString()),
            ),
          ),
          backgroundColor: const Color(0xFF1C2951), // Bleu de l'app
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // Créer nouvelle série avec les mêmes valeurs
      setState(() {
        final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
        updatedSets.add(currentSet.copyWith());
        _exercises[_currentExerciseIndex] = currentExercise.copyWith(sets: updatedSets);

        // Initialiser les controllers pour la nouvelle série
        final exerciseId = currentExercise.exercise.id;
        final newSetIndex = updatedSets.length - 1;

        _weightControllers[exerciseId] ??= {};
        _repsControllers[exerciseId] ??= {};
        _weightFocusNodes[exerciseId] ??= {};
        _repsFocusNodes[exerciseId] ??= {};
        _setKeys[exerciseId] ??= {};

        _weightControllers[exerciseId]![newSetIndex] = TextEditingController(
          text: currentSet.weight > 0 ? UnitService.instance.formatWeightValue(currentSet.weight, decimals: currentSet.weight % 1 == 0 ? 0 : 1) : '',
        );
        _repsControllers[exerciseId]![newSetIndex] = TextEditingController(
          text: currentSet.reps > 0 ? currentSet.reps.toString() : '',
        );

        final weightFocus = FocusNode();
        final repsFocus = FocusNode();
        weightFocus.addListener(() => _onFieldFocusChanged(newSetIndex, weightFocus.hasFocus));
        repsFocus.addListener(() => _onFieldFocusChanged(newSetIndex, repsFocus.hasFocus));

        _weightFocusNodes[exerciseId]![newSetIndex] = weightFocus;
        _repsFocusNodes[exerciseId]![newSetIndex] = repsFocus;
        _setKeys[exerciseId]![newSetIndex] = GlobalKey();
      });

      // Feedback
      HapticService.instance.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              locService.isFrench
                  ? 'new_set_added_same_values'.tr(LocalizationService.instance.currentLanguageCode)
                  : 'New set added with same values',
            ),
          ),
          backgroundColor: const Color(0xFF1C2951), // Bleu de l'app
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// 🎤 NOUVEAU : Démarrer l'input vocal pour une série spécifique
  Future<void> _startVoiceInputForSet(int setIndex) async {
    if (_exercises.isEmpty) return;

    // ⚡ IMPORTANT: Reset TOUS les états pour éviter blocage
    _isProcessingVoiceResult = false;
    _voiceAutoStopTimer?.cancel();
    _lastValidDataDetectedAt = null;

    // Marquer cette série comme active
    setState(() {
      _activeSetIndex = setIndex;
      _voiceHasError = false;
      _recognizedText = '';
    });

    // Feedback début
    _multiSensoryFeedback('start');

    // Initialiser la première fois
    if (!_voiceInitialized) {
      final success = await _voiceService.initialize();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  locService.currentLanguageCode == 'fr'
                      ? 'error_microphone_check_permissions'.tr(LocalizationService.instance.currentLanguageCode)
                      : 'Microphone error. Check permissions.',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      _voiceInitialized = true;
    }

    setState(() => _isVoiceListening = true);
    HapticService.instance.mediumImpact();

    await _voiceService.startListening(
      onPartialResult: (text) {
        if (mounted) {
          setState(() => _recognizedText = text);
        }

        // ⚡ NOUVEAU: Détecter si on a des données valides
        final parsedData = _voiceService.parseVoiceInput(text);
        if (parsedData != null && parsedData.hasData) {
          final now = DateTime.now();

          // Si c'est la première détection OU si plus d'1 sec depuis la dernière
          if (_lastValidDataDetectedAt == null ||
              now.difference(_lastValidDataDetectedAt!).inMilliseconds > 1000) {
            _lastValidDataDetectedAt = now;
            if (kDebugMode) debugPrint('✅ Données valides détectées, démarrage timer auto-stop (1.5s)');

            // Annuler le timer précédent
            _voiceAutoStopTimer?.cancel();

            // Nouveau timer de 1.5 secondes
            _voiceAutoStopTimer = Timer(const Duration(milliseconds: 1500), () async {
              if (_isVoiceListening && !_isProcessingVoiceResult) {
                debugPrint('⏱️ Auto-stop timer déclenché');
                await _stopVoiceInputForSet(setIndex);
              }
            });
          }
        }
      },
      onFinalResult: (text) async {
        // ⚡ Guard: éviter appels multiples (bug speech_to_text)
        if (_isProcessingVoiceResult) {
          if (kDebugMode) debugPrint('⚠️ Already processing voice result, ignoring duplicate call');
          return;
        }

        _isProcessingVoiceResult = true;

        if (mounted) {
          setState(() => _recognizedText = text);
        }

        // Annuler le timer auto-stop si on arrive ici
        _voiceAutoStopTimer?.cancel();

        // Auto-stop et traiter immédiatement
        await _stopVoiceInputForSet(setIndex);

        // Reset guard after processing
        _isProcessingVoiceResult = false;
      },
    );
  }

  /// Arrêter l'écoute vocale pour une série spécifique
  Future<void> _stopVoiceInputForSet(int setIndex) async {
    // ⚡ IMPORTANT: Reset guard immédiatement pour éviter blocage
    _isProcessingVoiceResult = false;

    // Annuler le timer auto-stop
    _voiceAutoStopTimer?.cancel();
    _lastValidDataDetectedAt = null;

    await _voiceService.stopListening();

    // Parser le résultat
    final setData = _voiceService.parseVoiceInput(_recognizedText);

    if (setData != null && setData.hasData) {
      // ✅ Données extraites - remplir la série ciblée
      _voiceRetryCount = 0;

      final currentExercise = _exercises[_currentExerciseIndex];

      // Remplir directement la série ciblée
      _fillSetWithVoiceData(currentExercise, setIndex, setData);

      // Feedback succès
      final confirmMsg = _voiceService.getConfirmationMessage(setData);
      await _voiceService.speak(confirmMsg);
      _multiSensoryFeedback('success');

      if (mounted) {
        setState(() {
          _isVoiceListening = false;
          _recognizedText = '';
          _voiceHasError = false;
          _activeSetIndex = null;
        });
      }
    } else {
      // ❌ Pas compris
      _voiceRetryCount++;

      if (_voiceRetryCount < _maxRetries) {
        final locService = LocalizationService.instance;
        final retryMsg = 'did_not_understand_retry'.tr(locService.currentLanguageCode);

        await _voiceService.speak(retryMsg);
        _multiSensoryFeedback('warning');

        if (mounted) {
          setState(() {
            _isVoiceListening = false;
            _voiceHasError = true;
          });
        }
      } else {
        _voiceRetryCount = 0;
        final errorMsg = _voiceService.getErrorMessage();
        await _voiceService.speak(errorMsg);
        _multiSensoryFeedback('error');

        if (mounted) {
          setState(() {
            _isVoiceListening = false;
            _recognizedText = '';
            _voiceHasError = false;
            _activeSetIndex = null;
          });
        }
      }
    }
  }

  /// Démarrer l'écoute vocale (bouton pressé) - ANCIEN SYSTÈME GLOBAL
  Future<void> _startVoiceInput() async {
    // Reset error state quand user relance
    if (mounted) {
      setState(() {
        _voiceHasError = false;
        _recognizedText = '';
      });
    }

    // Feedback début
    _multiSensoryFeedback('start');

    // Initialiser la première fois
    if (!_voiceInitialized) {
      final success = await _voiceService.initialize();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  locService.currentLanguageCode == 'fr'
                      ? 'error_microphone_check_permissions'.tr(LocalizationService.instance.currentLanguageCode)
                      : 'Microphone error. Check permissions.',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      _voiceInitialized = true;
    }

    setState(() => _isVoiceListening = true);
    HapticService.instance.mediumImpact();

    await _voiceService.startListening(
      onPartialResult: (text) {
        if (mounted) {
          setState(() => _recognizedText = text);
        }
      },
      onFinalResult: (text) {
        // Final sera traité dans stopVoiceInput
        if (mounted) {
          setState(() => _recognizedText = text);
        }
      },
    );
  }

  /// Arrêter l'écoute (bouton relâché)
  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();

    // Parser le résultat
    final setData = _voiceService.parseVoiceInput(_recognizedText);

    if (setData != null && setData.hasData) {
      // ✅ Données extraites avec succès
      _voiceRetryCount = 0; // Reset retry counter
      await _handleVoiceSetData(setData);

      if (mounted) {
        setState(() {
          _isVoiceListening = false;
          _recognizedText = '';
          _voiceHasError = false; // Reset error state
        });
      }
    } else {
      // ❌ Pas compris - Auto-retry si tentatives restantes
      _voiceRetryCount++;

      if (_voiceRetryCount < _maxRetries) {
        // MANUEL RETRY : Utilisateur doit TAP à nouveau sur le bouton rouge
        if (kDebugMode) debugPrint('❌ Parse failed. Waiting for manual retry $_voiceRetryCount/$_maxRetries');

        final locService = LocalizationService.instance;
        final retryMsg = 'did_not_understand_press_mic_again'.tr(locService.currentLanguageCode);

        await _voiceService.speak(retryMsg);
        _multiSensoryFeedback('warning'); // Feedback warning

        // Arrêter l'écoute et passer en mode "error" (bouton rouge)
        if (mounted) {
          setState(() {
            _isVoiceListening = false;
            _recognizedText = retryMsg; // Afficher le message
            _voiceHasError = true; // Activer l'état d'erreur (bouton rouge)
          });
        }
      } else {
        // Max retries atteint - abandon
        _voiceRetryCount = 0; // Reset pour la prochaine fois

        final errorMsg = _voiceService.getErrorMessage();
        await _voiceService.speak(errorMsg);
        _multiSensoryFeedback('error'); // Feedback error

        if (mounted) {
          setState(() {
            _isVoiceListening = false;
            _recognizedText = '';
            _voiceHasError = false; // Reset error state
          });
        }
      }
    }
  }

  /// Annuler l'input vocal (bouton X dans la bottom bar)
  Future<void> _cancelVoiceInput() async {
    await _voiceService.stopListening();

    if (mounted) {
      setState(() {
        _isVoiceListening = false;
        _recognizedText = '';
        _voiceRetryCount = 0;
        _voiceHasError = false; // Reset error state
      });
    }

    if (kDebugMode) debugPrint('❌ Voice input cancelled by user');
  }

  /// Gérer les données vocales (logique intelligente selon tes specs)
  Future<void> _handleVoiceSetData(WorkoutSetData data) async {
    final exercise = _exercises[_currentExerciseIndex];
    final sets = exercise.sets;

    // Trouver la dernière série non validée
    int targetSetIndex = -1;
    bool hasNonValidatedData = false;

    for (int i = 0; i < sets.length; i++) {
      final set = sets[i];
      // Série non validée = isCompleted = false
      if (!set.isCompleted) {
        targetSetIndex = i;
        // Vérifier si elle a des données
        if (set.reps > 0 || set.weight > 0) {
          hasNonValidatedData = true;
        }
        break; // Prendre la première non validée
      }
    }

    // Cas 1: Série non validée avec données existantes
    if (hasNonValidatedData && targetSetIndex != -1) {
      // LOGIQUE AUTO (sans dialog pour garder hands-free)
      // Si série a reps=0 → Écraser (série vide ou juste poids saisi)
      final set = sets[targetSetIndex];
      if (set.reps == 0) {
        // Écraser car pas de reps = série incomplète
        final locService = LocalizationService.instance;
        final msg = locService.currentLanguageCode == 'fr'
            ? 'replacing_incomplete_set'.tr(LocalizationService.instance.currentLanguageCode)
            : 'Replacing incomplete set';
        await _voiceService.speak(msg);
      } else {
        // Si série a reps>0 (avec ou sans poids) → Créer nouvelle série
        targetSetIndex++;
        if (targetSetIndex >= sets.length) {
          _addSerie(exercise);
          targetSetIndex = sets.length - 1;
        }

        final locService = LocalizationService.instance;
        final msg = locService.currentLanguageCode == 'fr'
            ? 'new_set_added'.tr(LocalizationService.instance.currentLanguageCode)
            : 'New set added';
        await _voiceService.speak(msg);
      }
    }

    // Cas 2: Pas de série non validée (toutes validées) → Ajouter nouvelle série
    if (targetSetIndex == -1) {
      _addSerie(exercise);
      targetSetIndex = sets.length - 1;
    }

    // Remplir les champs
    _fillSetWithVoiceData(exercise, targetSetIndex, data);

    // Valider EN CASCADE (toutes les séries jusqu'à celle-là incluse)
    _validateSetsUpTo(exercise, targetSetIndex);

    // Sauvegarder indices pour undo
    _lastVoiceExerciseIndex = _currentExerciseIndex;
    _lastVoiceSetIndex = targetSetIndex;

    // Démarrer timer undo (3 secondes)
    _startUndoTimer();

    // Feedback vocal + multi-sensoriel
    final confirmMsg = _voiceService.getConfirmationMessage(data);
    await _voiceService.speak(confirmMsg);
    _multiSensoryFeedback('success'); // Feedback succès avec vibration forte
  }

  /// Démarrer le timer d'undo (3 secondes)
  void _startUndoTimer() {
    // Annuler le timer précédent si existe
    _undoTimer?.cancel();

    setState(() {
      _showUndoButton = true;
      _undoCountdown = 3;
    });

    // Countdown chaque seconde
    _undoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _undoCountdown--;
      });

      if (_undoCountdown <= 0) {
        timer.cancel();
        setState(() {
          _showUndoButton = false;
        });
      }
    });
  }

  /// Annuler la dernière saisie vocale
  void _undoVoiceInput() {
    if (_lastVoiceExerciseIndex == null || _lastVoiceSetIndex == null) return;

    final exercise = _exercises[_lastVoiceExerciseIndex!];
    final setIndex = _lastVoiceSetIndex!;

    // Réinitialiser les valeurs en utilisant copyWith
    setState(() {
      // Créer une nouvelle instance avec valeurs vides
      final updatedSet = exercise.sets[setIndex].copyWith(
        reps: 0,
        weight: 0.0,
        isCompleted: false,
      );

      // Remplacer dans la liste
      exercise.sets[setIndex] = updatedSet;

      // Vider les controllers
      _repsControllers[exercise.exercise.id]?[setIndex]?.text = '';
      _weightControllers[exercise.exercise.id]?[setIndex]?.text = '';

      // Masquer le bouton undo
      _showUndoButton = false;
    });

    // Annuler le timer
    _undoTimer?.cancel();

    // Feedback multi-sensoriel + vocal
    _multiSensoryFeedback('undo');

    final locService = LocalizationService.instance;
    final undoMsg = locService.currentLanguageCode == 'fr'
        ? 'cancelled'.tr(LocalizationService.instance.currentLanguageCode)
        : 'Undone';
    _voiceService.speak(undoMsg);

    if (kDebugMode) debugPrint('↩️ Undo: série $setIndex réinitialisée');
  }

  /// Remplir une série avec les données vocales
  void _fillSetWithVoiceData(WorkoutExercise exercise, int setIndex, WorkoutSetData data) {
    // ⚡ NOUVEAU: Si donnée non mentionnée dans le micro, on VIDE la case (au lieu de garder l'ancienne valeur)
    final reps = data.reps ?? 0;
    final weightKg = data.weight ?? 0.0; // Le poids vocal est toujours en kg

    // Mettre à jour les controllers (convertir kg → unité d'affichage)
    _repsControllers[exercise.exercise.id]?[setIndex]?.text = reps > 0 ? reps.toString() : '';
    _weightControllers[exercise.exercise.id]?[setIndex]?.text = weightKg > 0
        ? UnitService.instance.formatWeightValue(weightKg, decimals: weightKg % 1 == 0 ? 0 : 1)
        : '';

    // Mettre à jour le modèle avec copyWith (PAS de isCompleted = true)
    // Le modèle stocke toujours en kg
    setState(() {
      final updatedSet = exercise.sets[setIndex].copyWith(
        reps: reps,
        weight: weightKg,
        // ⚡ NE PAS valider la série (pas de vert)
      );
      exercise.sets[setIndex] = updatedSet;
    });

    if (kDebugMode) debugPrint('✅ Filled set $setIndex: $reps reps, $weightKg kg (sans validation)');
  }

  /// Valider EN CASCADE (toutes les séries jusqu'à celle-là incluse)
  void _validateSetsUpTo(WorkoutExercise exercise, int upToIndex) {
    for (int i = 0; i <= upToIndex && i < exercise.sets.length; i++) {
      final set = exercise.sets[i];
      if (!set.isCompleted) {
        setState(() {
          final updatedSet = set.copyWith(isCompleted: true);
          exercise.sets[i] = updatedSet;
        });
        if (kDebugMode) debugPrint('✅ Validated set $i');
      }
    }
  }


  /// Méthode helper pour ajouter une série (si elle n'existe pas déjà)
  void _addSerie(WorkoutExercise exercise) {
    final newSet = ExerciseSet(
      reps: 0,
      weight: 0.0,
      isCompleted: false,
    );

    setState(() {
      exercise.sets.add(newSet);
    });

    // Initialiser les controllers pour la nouvelle série
    final setIndex = exercise.sets.length - 1;
    _weightControllers[exercise.exercise.id]?[setIndex] = TextEditingController();
    _repsControllers[exercise.exercise.id]?[setIndex] = TextEditingController();
    _weightFocusNodes[exercise.exercise.id]?[setIndex] = FocusNode();
    _repsFocusNodes[exercise.exercise.id]?[setIndex] = FocusNode();
    _setKeys[exercise.exercise.id]?[setIndex] = GlobalKey();

    if (kDebugMode) debugPrint('➕ Added new set (index $setIndex)');
  }

  void _triggerWorkoutCelebration() {
    final workoutType = widget.isFromAI
        ? 'coach'
        : (widget.isFromProgram ? 'guided' : 'manual');

    CelebrationService().celebrateWorkoutCompletionGlobal(
      sessionName: widget.sessionName,
      workoutType: workoutType,
      exerciseCount: _exercises.length,
    );
  }
}
