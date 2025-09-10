import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sport_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/ui/custom_scrollbar.dart';
import '../services/database_service.dart' as db;
import '../services/calorie_burn_service.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/offline_workout_service.dart';
import '../services/workout_cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String sessionName;
  final List<WorkoutExercise> exercises;
  final bool isFromProgram;
  final String? guidedTemplateId; // si séance guidée, passer l'id du template
  final Function(WorkoutProgram)? onProgramSaved;
  final Function(WorkoutSession)? onSessionCompleted;

  const WorkoutSessionScreen({
    super.key,
    required this.sessionName,
    required this.exercises,
    this.isFromProgram = false,
    this.guidedTemplateId,
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

  @override
  void initState() {
    super.initState();
    _exercises = widget.isFromProgram ? List.from(widget.exercises) : [];
    _sessionStartTime = DateTime.now();
    _currentFocusNode = FocusNode();
    
    // Initialiser les controllers pour tous les exercices existants
    for (final exercise in _exercises) {
      _initializeControllersForExercise(exercise.exercise.id, exercise.sets.length);
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
  
  void _validateSet(int setIndex) {
    if (_exercises.isEmpty) return;
    
    final currentExercise = _exercises[_currentExerciseIndex];
    if (setIndex >= currentExercise.sets.length) return;
    
    // Vérifier que la série précédente est validée (si pas la première)
    if (setIndex > 0) {
      final previousSet = currentExercise.sets[setIndex - 1];
      if (!previousSet.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'workout_validate_set_first'.tr(locService.currentLanguageCode).replaceAll('{0}', setIndex.toString()),
              ),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    
    final set = currentExercise.sets[setIndex];
    
    if (set.reps > 0) {
      setState(() {
        final updatedSets = List<ExerciseSet>.from(currentExercise.sets);
        updatedSets[setIndex] = set.copyWith(isCompleted: true);
        _exercises[_currentExerciseIndex] = currentExercise.copyWith(sets: updatedSets);
        // Réinitialiser la série active après validation
        _activeSetIndex = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'workout_set_validated'.tr(locService.currentLanguageCode).replaceAll('{0}', '${setIndex + 1}'),
            ),
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'workout_enter_weight_reps'.tr(locService.currentLanguageCode),
            ),
          ),
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

  void _addExercise(String name, String muscleGroup, {int setsCount = 3, String? exerciseId, bool isCustom = false}) {
    final resolvedId = exerciseId ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    setState(() {
      // Créer les séries vides
      final sets = List.generate(setsCount, (index) => 
        const ExerciseSet(weight: 0, reps: 0, isCompleted: false)
      );
      
      _exercises.add(WorkoutExercise(
        exercise: Exercise(
          id: resolvedId,
          name: name,
          muscleGroup: muscleGroup,
          isCustom: isCustom || exerciseId == null,
        ),
        sets: sets,
      ));
      
      // Initialiser les controllers pour cet exercice
      _initializeControllersForExercise(resolvedId, setsCount);
      
      // Si c'est le premier exercice, le sélectionner
      if (_exercises.length == 1) {
        _currentExerciseIndex = 0;
      } else {
        // Aller directement sur le nouvel exercice
        _currentExerciseIndex = _exercises.length - 1;
      }
    });
  }
  
  void _initializeControllersForExercise(String exerciseId, int setsCount) {
    _weightControllers[exerciseId] = {};
    _repsControllers[exerciseId] = {};
    _weightFocusNodes[exerciseId] = {};
    _repsFocusNodes[exerciseId] = {};
    _setKeys[exerciseId] = {};
    
    for (int i = 0; i < setsCount; i++) {
      _weightControllers[exerciseId]![i] = TextEditingController();
      _repsControllers[exerciseId]![i] = TextEditingController();
      
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
    // Charger depuis Supabase ou cache offline
    final List<Exercise> allExercises = await db.DatabaseService.getSystemExercises();
    
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
                return exercise.name
                    .toLowerCase()
                    .contains(searchController.text.toLowerCase());
              }).toList();
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
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1A1A1A),
                                                ),
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
                                                    style: TextStyle(fontSize: 10, color: Color(0xFF0B132B), fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
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
                          Navigator.pop(context); // Fermer popup
                          Navigator.pop(context); // Retourner à la musculation
                          
                          // Afficher confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  'workout_session_saved_message'.tr(locService.currentLanguageCode).replaceAll('{0}', widget.sessionName),
                                ),
                              ),
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

  void _validateSession() async {
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
    
    // Vérifier si on est hors ligne
    final isOffline = _offlineStatus != null && !_offlineStatus!.isOnline;
    
    // Historiser la séance (manuel ou guidé)
    db.DatabaseService.persistCompletedWorkoutAsHistory(
      session: completedSession,
      guidedTemplateId: widget.isFromProgram ? (widget.guidedTemplateId ?? _inferGuidedTemplateId()) : null,
      intensity: _selectedIntensity != null ? _mapIntensityToDbValue(_selectedIntensity!) : null,
      durationMinutes: _displayedDuration.inMinutes,
      caloriesBurned: _estimatedCalories,
    ).then((_) {
      // Invalider le cache du dashboard principal après la sauvegarde
      try {
        DashboardService.invalidateAndRefreshAfterWorkout();
        debugPrint('✅ Dashboard principal mis à jour après musculation');
      } catch (e) {
        debugPrint('⚠️ Erreur lors de la mise à jour du dashboard principal: $e');
      }
      
      // Afficher un message différent si on est hors ligne
      if (isOffline && mounted) {
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
    }).catchError((e) {
      debugPrint('❌ persistCompletedWorkoutAsHistory error: $e');
    });

    // Appeler le callback pour valider la session
    if (widget.onSessionCompleted != null) {
      widget.onSessionCompleted!(completedSession);
    }
    
    print('Séance validée: ${completedSession.name}');
    print('- Durée totale: ${_formatDuration(completedSession.duration)}');
    print('- ${completedSession.completedSets}/${completedSession.totalSets} séries terminées');
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
      final templateId = await db.DatabaseService.saveUserWorkoutTemplate(completedSession);
      debugPrint('✅ Template utilisateur sauvegardé avec ID: $templateId');
      
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
      );
      
      // Appeler les callbacks pour sauvegarder dans l'écran parent
      if (widget.onSessionCompleted != null) {
        widget.onSessionCompleted!(completedSession);
      }
      
      if (widget.onProgramSaved != null) {
        widget.onProgramSaved!(workoutProgram);
      }
      
      debugPrint('=== DEBUG SAUVEGARDE ===');
      debugPrint('Séance validée: ${completedSession.name}');
      debugPrint('- Template ID: $templateId');
      debugPrint('- Heure début: $_sessionStartTime');
      debugPrint('- Heure fin: $sessionEndTime');
      debugPrint('- Durée en minutes: $durationInMinutes');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde du template: $e');
      // Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
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
                                '$_completedSets/$_totalSets',
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
                                '${_totalWeight.toStringAsFixed(0)} kg',
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
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                                  'workout_weight_kg'.tr(locService.currentLanguageCode),
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
                            const SizedBox(width: 80), // Espace pour les boutons
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
                final weight = double.tryParse(value) ?? 0.0;
                _updateSetValue(setIndex, weight: weight);
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
          
          // Bouton Valider
          GestureDetector(
            onTap: currentSet.isCompleted ? null : () => _validateSet(setIndex),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: currentSet.isCompleted 
                    ? const Color(0xFF10B981)
                    : Colors.white.withOpacity(0.9),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Consumer<LocalizationService>(
          builder: (context, locService, _) => Text(
            'workout_confirm_end_session'.tr(locService.currentLanguageCode),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        content: Consumer<LocalizationService>(
          builder: (context, locService, _) => Text(
            'workout_confirm_end_session_message'.tr(locService.currentLanguageCode),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
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
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header du tableau avec fond unique
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Header Date fixe
                  Container(
                    width: 70,
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
                  // Header scrollable (Max + Séries)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
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
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Lignes de données avec fond uniforme
            ...sessionHistory.map((session) {
              final allSets = (session['allSets'] as List<String>?) ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Date fixe
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                    const SizedBox(width: 4),
                    // Partie scrollable (Max + Séries)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Charge Max
                            Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
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
}
