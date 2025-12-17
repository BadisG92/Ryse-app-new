import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/sport_models.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import '../services/sport_dashboard_service.dart';
import '../services/dashboard_service.dart';
import '../services/global_state_manager.dart';
import '../services/calorie_burn_service.dart';
import '../services/auth_service.dart';
import '../services/unit_service.dart';
import '../widgets/exercise/exercise_selector_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen dédié à l'édition d'une séance de musculation existante
class WorkoutEditScreen extends StatefulWidget {
  final String sessionId;
  final String historySessionId;
  final String sessionName;
  final List<WorkoutExercise> exercises;
  final int durationMinutes;
  final String? intensity;
  final String sessionDate;

  const WorkoutEditScreen({
    super.key,
    required this.sessionId,
    required this.historySessionId,
    required this.sessionName,
    required this.exercises,
    required this.durationMinutes,
    this.intensity,
    required this.sessionDate,
  });

  @override
  State<WorkoutEditScreen> createState() => _WorkoutEditScreenState();
}

class _WorkoutEditScreenState extends State<WorkoutEditScreen> {
  late List<WorkoutExercise> _exercises;
  late int _durationMinutes;
  String? _selectedIntensity;
  final Map<int, bool> _expandedExercises = {};
  int _estimatedCalories = 0;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.exercises);
    _durationMinutes = widget.durationMinutes;
    _selectedIntensity = _mapDbValueToIntensityKey(widget.intensity);

    // Initialiser tous les exercices comme repliés
    for (int i = 0; i < _exercises.length; i++) {
      _expandedExercises[i] = false;
    }

    // Calculer les calories initiales
    _recalculateCalories();
  }

  void _recalculateCalories() {
    final totalWeight = _exercises.fold<double>(
      0,
      (sum, we) => sum + we.sets.fold<double>(
        0,
        (setSum, s) => setSum + (s.weight * s.reps),
      ),
    );

    final user = AuthService().currentUser;
    final double assumedWeightKg = (user?.weight != null && user!.weight! > 0)
        ? user.weight!
        : 75.0;
    final minutes = _durationMinutes > 0 ? _durationMinutes : 1;
    final intensity = _selectedIntensity ?? 'moderate';

    setState(() {
      _estimatedCalories = CalorieBurnService.calculateKcal(
        'musculation',
        assumedWeightKg,
        minutes,
        intensity: intensity,
        totalWeightKg: totalWeight,
      );
    });
  }

  // Mapper les valeurs DB vers les clés d'intensité
  // La DB stocke: 'Faible', 'Modéré', 'Élevé'
  String? _mapDbValueToIntensityKey(String? dbValue) {
    if (dbValue == null) return null;

    switch (dbValue) {
      case 'Faible':
        return 'low';
      case 'Modéré':
        return 'moderate';
      case 'Élevé':
        return 'high';
      default:
        return null;
    }
  }

  // Mapper les clés d'intensité UI vers les valeurs françaises de la DB
  // La DB attend: 'Faible', 'Modéré', 'Élevé' (contrainte CHECK)
  String _mapIntensityToDbValue(String intensity) {
    switch (intensity) {
      case 'low':
        return 'Faible';
      case 'moderate':
        return 'Modéré';
      case 'high':
        return 'Élevé';
      default:
        return 'Modéré';
    }
  }

  void _toggleExercise(int index) {
    setState(() {
      _expandedExercises[index] = !(_expandedExercises[index] ?? false);
    });
  }

  void _updateSet(int exerciseIndex, int setIndex, int? reps, double? weight) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final oldSet = exercise.sets[setIndex];
      final newSet = ExerciseSet(
        reps: reps ?? oldSet.reps,
        weight: weight ?? oldSet.weight,
        isCompleted: true,
      );

      final newSets = List<ExerciseSet>.from(exercise.sets);
      newSets[setIndex] = newSet;

      _exercises[exerciseIndex] = exercise.copyWith(sets: newSets);
    });
    _recalculateCalories();
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final lastSet = exercise.sets.isNotEmpty
          ? exercise.sets.last
          : const ExerciseSet(reps: 10, weight: 0);

      final newSets = List<ExerciseSet>.from(exercise.sets);
      newSets.add(ExerciseSet(
        reps: lastSet.reps,
        weight: lastSet.weight,
        isCompleted: true,
      ));

      _exercises[exerciseIndex] = exercise.copyWith(sets: newSets);
    });
    _recalculateCalories();
  }

  void _deleteSet(int exerciseIndex, int setIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final newSets = List<ExerciseSet>.from(exercise.sets);
      newSets.removeAt(setIndex);

      _exercises[exerciseIndex] = exercise.copyWith(sets: newSets);
    });
    _recalculateCalories();
  }

  void _deleteExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      // Réorganiser les clés d'expansion
      final newExpandedExercises = <int, bool>{};
      for (int i = 0; i < _exercises.length; i++) {
        newExpandedExercises[i] = _expandedExercises[i < index ? i : i + 1] ?? false;
      }
      _expandedExercises.clear();
      _expandedExercises.addAll(newExpandedExercises);
    });
    _recalculateCalories();
  }

  Future<void> _addExercise() async {
    // Ouvrir le bottom sheet de sélection d'exercice
    final selectedExercise = await ExerciseSelectorBottomSheet.show(context);

    if (selectedExercise == null || !mounted) return;

    // Demander le nombre de séries
    final setsCount = await _showSetsCountDialog(selectedExercise.name);

    if (setsCount == null || !mounted) return;

    // Ajouter l'exercice avec le nombre de séries demandé
    setState(() {
      final sets = List.generate(
        setsCount,
        (index) => const ExerciseSet(reps: 10, weight: 0, isCompleted: true),
      );

      _exercises.add(WorkoutExercise(
        exercise: selectedExercise,
        sets: sets,
      ));
      _expandedExercises[_exercises.length - 1] = true;
    });
    _recalculateCalories();
  }

  Future<int?> _showSetsCountDialog(String exerciseName) async {
    int selectedSets = 3;

    return await showDialog<int>(
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedSets),
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

  Future<void> _saveChanges() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Afficher un loader
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Si tous les exercices ont été supprimés, supprimer la séance entière
      if (_exercises.isEmpty) {
        debugPrint('🗑️ Tous les exercices ont été supprimés, suppression de la séance');

        // Supprimer les sets
        await Supabase.instance.client
            .from('workout_set_history')
            .delete()
            .eq('history_session_id', widget.historySessionId);

        // Supprimer le résumé
        await Supabase.instance.client
            .from('workout_session_summaries')
            .delete()
            .eq('id', widget.sessionId);

        debugPrint('✅ Séance supprimée');

        // Invalider les caches
        SportDashboardService.forceInvalidateAllCaches();
        DashboardService.invalidateAndRefreshAfterWorkout();
        await GlobalStateManager.instance.refreshSportData();

        // Fermer le loader
        if (mounted) Navigator.pop(context);

        // Retourner avec succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Séance supprimée'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
        return;
      }

      // 1. Supprimer tous les sets existants
      await Supabase.instance.client
          .from('workout_set_history')
          .delete()
          .eq('history_session_id', widget.historySessionId);

      // 2. Insérer les nouveaux sets
      final List<Map<String, dynamic>> rows = [];
      int globalOrder = 1;

      for (final we in _exercises) {
        for (final set in we.sets.where((s) => s.reps > 0)) {
          rows.add({
            'user_id': userId,
            'history_session_id': widget.historySessionId,
            'exercise_name': we.exercise.name,
            'set_order': globalOrder,
            'reps': set.reps,
            'weight': set.weight,
            'performed_at': widget.sessionDate,
            'session_name': widget.sessionName,
          });
          globalOrder++;
        }
      }

      if (rows.isNotEmpty) {
        await Supabase.instance.client
            .from('workout_set_history')
            .insert(rows);
      }

      // 3. Mettre à jour le résumé
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

      debugPrint('📊 Mise à jour du résumé: sessionId=${widget.sessionId}');
      debugPrint('📊 totalWeight=${totalWeight.round()}, completedSets=$completedSets, calories=$_estimatedCalories');

      final updateData = {
        'session_name': widget.sessionName,
        'duration_minutes': _durationMinutes,
        'calories_burned': _estimatedCalories,
        'intensity': _selectedIntensity != null ? _mapIntensityToDbValue(_selectedIntensity!) : null,
        'total_volume_kg': totalWeight.round(),
      };

      debugPrint('📝 Données à mettre à jour: $updateData');

      await Supabase.instance.client
          .from('workout_session_summaries')
          .update(updateData)
          .eq('id', widget.sessionId);

      debugPrint('✅ Résumé de séance mis à jour');

      // 4. Invalider les caches
      SportDashboardService.forceInvalidateAllCaches();
      DashboardService.invalidateAndRefreshAfterWorkout();
      await GlobalStateManager.instance.refreshSportData();

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Retourner avec succès
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
      // Fermer le loader
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde des modifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDurationPicker() {
    final controller = TextEditingController(text: _durationMinutes.toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_duration'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
                decoration: InputDecoration(
                  hintText: '45',
                  suffixText: 'min',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'cancel'.tr(locService.currentLanguageCode),
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value > 0) {
                          setState(() {
                            _durationMinutes = value;
                          });
                          _recalculateCalories();
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B132B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'validate'.tr(locService.currentLanguageCode),
                          style: const TextStyle(color: Colors.white),
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
    );
  }

  void _showIntensityPicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_intensity'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildIntensityOption('low'),
              _buildIntensityOption('moderate'),
              _buildIntensityOption('high'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityOption(String intensity) {
    final locService = LocalizationService.instance;
    final isSelected = _selectedIntensity == intensity;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0B132B).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIntensity = intensity;
          });
          _recalculateCalories();
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                intensity == 'high' ? LucideIcons.zap :
                intensity == 'moderate' ? LucideIcons.activity :
                LucideIcons.wind,
                size: 20,
                color: isSelected ? const Color(0xFF0B132B) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'workout_intensity_$intensity'.tr(locService.currentLanguageCode),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF0B132B) : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  LucideIcons.check,
                  size: 20,
                  color: Color(0xFF0B132B),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sessionName,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'save'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec durée et intensité
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showDurationPicker,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 16, color: Color(0xFF0B132B)),
                          const SizedBox(width: 8),
                          Text(
                            '$_durationMinutes min',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _showIntensityPicker,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.zap, size: 16, color: Color(0xFF0B132B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                _selectedIntensity != null
                                    ? 'workout_intensity_$_selectedIntensity'.tr(locService.currentLanguageCode)
                                    : 'workout_intensity'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                                overflow: TextOverflow.ellipsis,
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
          ),

          // Liste des exercices
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exercises.length,
              itemBuilder: (context, index) => _buildExerciseCard(index),
            ),
          ),

          // Bouton ajouter exercice
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(LucideIcons.plus),
                  label: Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      'workout_add_exercise'.tr(locService.currentLanguageCode),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final isExpanded = _expandedExercises[exerciseIndex] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header de l'exercice
          InkWell(
            onTap: () => _toggleExercise(exerciseIndex),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exercise.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exercise.sets.length} série${exercise.sets.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                    onPressed: () => _deleteExercise(exerciseIndex),
                    padding: const EdgeInsets.all(8),
                  ),
                  Icon(
                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          // Séries (si déplié)
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Liste des séries
                  ...List.generate(exercise.sets.length, (setIndex) {
                    return _buildSetRow(exerciseIndex, setIndex);
                  }),

                  const SizedBox(height: 12),

                  // Bouton ajouter série
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addSet(exerciseIndex),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Ajouter une série'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B132B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetRow(int exerciseIndex, int setIndex) {
    final set = _exercises[exerciseIndex].sets[setIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Numéro de série
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${setIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Poids
          Expanded(
            child: _buildInputField(
              value: UnitService.instance.formatWeightValue(set.weight, decimals: set.weight % 1 == 0 ? 0 : 1),
              suffix: UnitService.instance.weightUnit,
              onChanged: (value) {
                final weight = double.tryParse(value);
                if (weight != null) {
                  // Convertir en kg pour le stockage
                  _updateSet(exerciseIndex, setIndex, null, UnitService.instance.storageWeight(weight));
                }
              },
            ),
          ),

          const SizedBox(width: 12),

          // Reps
          Expanded(
            child: _buildInputField(
              value: set.reps.toString(),
              suffix: 'reps',
              onChanged: (value) {
                final reps = int.tryParse(value);
                if (reps != null) {
                  _updateSet(exerciseIndex, setIndex, reps, null);
                }
              },
            ),
          ),

          const SizedBox(width: 8),

          // Bouton supprimer
          if (_exercises[exerciseIndex].sets.length > 1)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
              onPressed: () => _deleteSet(exerciseIndex, setIndex),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String value,
    required String suffix,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: value.length),
                ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            suffix,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
