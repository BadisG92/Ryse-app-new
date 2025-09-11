import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/sport_models.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import '../services/workout_cache_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseSelectionBottomSheet extends StatefulWidget {
  final Function(Exercise exercise, int sets) onExerciseSelected;
  final Function(String name, int sets) onCustomExerciseCreated;

  const ExerciseSelectionBottomSheet({
    super.key,
    required this.onExerciseSelected,
    required this.onCustomExerciseCreated,
  });

  @override
  State<ExerciseSelectionBottomSheet> createState() => _ExerciseSelectionBottomSheetState();
}

class _ExerciseSelectionBottomSheetState extends State<ExerciseSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMuscleFilter = 'Tous';
  List<Exercise> _filteredExercises = [];
  Map<String, int> _exerciseSessionCounts = {}; // Nombre de sessions par exercice
  bool _isLoadingStats = false;
  
  // Base de données d'exercices prédéfinis
  final List<Exercise> _predefinedExercises = [
    Exercise(
      id: '1',
      name: 'Développé couché',
      muscleGroup: MuscleGroups.chest,
      equipment: 'Barre',
      description: 'Exercice pour les pectoraux avec barre',
    ),
    Exercise(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroups.legs,
      equipment: 'Barre',
      description: 'Exercice pour les jambes et fessiers',
    ),
    Exercise(
      id: '3',
      name: 'Tractions',
      muscleGroup: MuscleGroups.back,
      equipment: 'Barre de traction',
      description: 'Exercice pour le dos',
    ),
    Exercise(
      id: '4',
      name: 'Développé militaire',
      muscleGroup: MuscleGroups.shoulders,
      equipment: 'Barre',
      description: 'Exercice pour les épaules',
    ),
    Exercise(
      id: '5',
      name: 'Curl biceps',
      muscleGroup: MuscleGroups.biceps,
      equipment: 'Haltères',
      description: 'Exercice pour les biceps',
    ),
    Exercise(
      id: '6',
      name: 'Dips',
      muscleGroup: MuscleGroups.triceps,
      equipment: 'Barres parallèles',
      description: 'Exercice pour les triceps',
    ),
    Exercise(
      id: '7',
      name: 'Soulevé de terre',
      muscleGroup: MuscleGroups.back,
      equipment: 'Barre',
      description: 'Exercice composé pour le dos et les jambes',
    ),
    Exercise(
      id: '8',
      name: 'Crunchs',
      muscleGroup: MuscleGroups.abs,
      equipment: 'Aucun',
      description: 'Exercice pour les abdominaux',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredExercises = _predefinedExercises;
    _searchController.addListener(_filterExercises);
    _loadExerciseStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExerciseStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Récupérer les statistiques des exercices les plus fréquents
      final topExercises = await WorkoutCacheService.getTopExercises(userId);
      
      final Map<String, int> sessionCounts = {};
      for (final exercise in topExercises) {
        final exerciseName = exercise['localized_name']?.toString() ?? exercise['name']?.toString();
        final sessions = exercise['sessions'] as int? ?? 0;
        if (exerciseName != null && exerciseName.isNotEmpty) {
          sessionCounts[exerciseName] = sessions;
        }
      }

      setState(() {
        _exerciseSessionCounts = sessionCounts;
        _isLoadingStats = false;
        // Re-trier les exercices avec les nouvelles stats
        _sortAndFilterExercises();
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des stats d\'exercices: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  void _filterExercises() {
    _sortAndFilterExercises();
  }

  void _sortAndFilterExercises() {
    setState(() {
      _filteredExercises = _predefinedExercises.where((exercise) {
        final matchesSearch = exercise.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
        final matchesMuscle = _selectedMuscleFilter == 'Tous' ||
            exercise.muscleGroup == _selectedMuscleFilter;
        return matchesSearch && matchesMuscle;
      }).toList();

      // Trier par fréquence d'utilisation puis alphabétiquement
      _filteredExercises.sort((a, b) {
        final aSessionCount = _exerciseSessionCounts[a.name] ?? 0;
        final bSessionCount = _exerciseSessionCounts[b.name] ?? 0;
        
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
    });
  }

  void _selectExercise(Exercise exercise) {
    Navigator.pop(context);
    _showSetsSelectionModal(exercise: exercise);
  }

  void _createCustomExercise() {
    Navigator.pop(context);
    _showCustomExerciseModal();
  }

  void _showSetsSelectionModal({Exercise? exercise}) {
    final TextEditingController setsController = TextEditingController(text: '3');
    
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
                  exercise != null ? exercise.name : 'Nouvel exercice',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                if (exercise != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.target,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.muscleGroup,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (exercise.equipment.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          LucideIcons.dumbbell,
                          size: 16,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exercise.equipment,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                
                const SizedBox(height: 24),
                
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'sets_count_placeholder'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                TextField(
                  controller: setsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'sets_count_placeholder'.tr(context.read<LocalizationService>().currentLanguageCode),
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
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final sets = int.tryParse(setsController.text) ?? 3;
                      Navigator.pop(context);
                      if (exercise != null) {
                        widget.onExerciseSelected(exercise, sets);
                      }
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
                      'Ajouter l\'exercice',
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

  void _showCustomExerciseModal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController setsController = TextEditingController(text: '3');
    
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
                  'Créer un exercice',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Nom de l\'exercice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'exercise_name_placeholder'.tr(locService.currentLanguageCode),
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
                ),
                
                const SizedBox(height: 16),
                
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'sets_count_placeholder'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                TextField(
                  controller: setsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'sets_count_placeholder'.tr(context.read<LocalizationService>().currentLanguageCode),
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
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        final sets = int.tryParse(setsController.text) ?? 3;
                        Navigator.pop(context);
                        widget.onCustomExerciseCreated(nameController.text, sets);
                      }
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
                      'Créer l\'exercice',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Barre de recherche
            Consumer<LocalizationService>(
              builder: (context, locService, _) => TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'workout_search_exercise'.tr(locService.currentLanguageCode),
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
            ),
            
            const SizedBox(height: 16),
            
            // Filtre par muscle
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMuscleFilter('Tous'),
                  ...MuscleGroups.all.map((muscle) => _buildMuscleFilter(muscle)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Liste des exercices
            Expanded(
              child: ListView(
                children: [
                  // Option pour créer un exercice manuel
                  _buildCustomExerciseOption(),
                  
                  const SizedBox(height: 16),
                  
                  // Exercices prédéfinis
                  ..._filteredExercises.map((exercise) => _buildExerciseCard(exercise)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleFilter(String muscle) {
    final isSelected = _selectedMuscleFilter == muscle;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(muscle),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (selected) {
          setState(() {
            _selectedMuscleFilter = muscle;
            _filterExercises();
          });
        },
        backgroundColor: const Color(0xFFF8FAFC),
        selectedColor: const Color(0xFF0B132B),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildCustomExerciseOption() {
    return GestureDetector(
      onTap: _createCustomExercise,
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
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
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      'workout_add_exercise_not_in_list'.tr(locService.currentLanguageCode),
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
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

  Widget _buildExerciseCard(Exercise exercise) {
    return GestureDetector(
      onTap: () => _selectExercise(exercise),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                LucideIcons.dumbbell,
                color: Color(0xFF0B132B),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.target,
                        size: 12,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.muscleGroup,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (exercise.equipment.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.wrench,
                          size: 12,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exercise.equipment,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Ajouter les tags ici si besoin
                  const SizedBox(height: 4),
                  _buildExerciseTags(exercise),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTags(Exercise exercise) {
    final sessionCount = _exerciseSessionCounts[exercise.name] ?? 0;
    final locService = LocalizationService.instance;

    // Si on n'a pas encore chargé les stats, ne pas afficher de tags
    if (_isLoadingStats) {
      return const SizedBox.shrink();
    }

    List<Widget> tags = [];

    if (sessionCount == 0) {
      // Tag "Nouveau" pour les exercices jamais fait
      tags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            locService.isFrench ? 'Nouveau' : 'New',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (sessionCount >= 3) {
      // Tag avec nombre de sessions pour les exercices fréquents (≥3 sessions)
      tags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            locService.isFrench ? '$sessionCount séances' : '$sessionCount sessions',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: tags,
    );
  }
}
