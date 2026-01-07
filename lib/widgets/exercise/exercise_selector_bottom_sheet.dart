import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/sport_models.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/database_service.dart' as db;
import '../../bottom_sheets/exercise_info_bottom_sheet.dart';

/// Bottom sheet pour sélectionner ou créer un exercice
/// Retourne un `Exercise` via Navigator.pop(context, exercise)
class ExerciseSelectorBottomSheet extends StatefulWidget {
  const ExerciseSelectorBottomSheet({super.key});

  @override
  State<ExerciseSelectorBottomSheet> createState() => _ExerciseSelectorBottomSheetState();

  static Future<Exercise?> show(BuildContext context) async {
    return await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseSelectorBottomSheet(),
    );
  }
}

class _ExerciseSelectorBottomSheetState extends State<ExerciseSelectorBottomSheet> {
  List<Exercise> allExercises = [];
  List<Exercise> filteredExercises = [];
  List<String> availableMuscleGroups = [];
  Set<String> selectedMuscleFilters = {};
  final TextEditingController searchController = TextEditingController();
  Map<String, int> exerciseSessionCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('❌ User not authenticated');
        setState(() => _loading = false);
        return;
      }

      final locService = LocalizationService.instance;
      final suffix = locService.getColumnSuffix();
      debugPrint('🔍 Loading exercises with suffix: $suffix');
      debugPrint('🌍 Current language: ${locService.currentLanguageCode}, isGerman: ${locService.isGerman}');

      // Charger les exercices système avec TOUTES les colonnes localisées
      final exercisesData = await client
          .from('exercises')
          .select('id, name_en, name_fr, name_de, muscle_group_fr, muscle_group_en, muscle_group_de, equipment, description, is_custom')
          .order('name$suffix');

      // Charger les exercices custom
      final customExercisesData = await client
          .from('custom_exercises')
          .select('id, name, muscle_group, equipment, description')
          .eq('user_id', userId)
          .order('name');

      // Charger les statistiques d'utilisation
      final historyData = await client
          .from('workout_set_history')
          .select('exercise_name, history_session_id')
          .eq('user_id', userId);

      // Calculer le nombre de sessions par exercice
      final Map<String, Set<String>> exerciseToSessions = {};
      for (final row in historyData) {
        final name = row['exercise_name'] as String?;
        final sessionId = row['history_session_id'] as String?;
        if (name != null && sessionId != null) {
          exerciseToSessions.putIfAbsent(name, () => {}).add(sessionId);
        }
      }

      exerciseSessionCounts = exerciseToSessions.map(
        (name, sessions) => MapEntry(name, sessions.length),
      );

      debugPrint('✅ Loaded ${exercisesData.length} system exercises');
      debugPrint('✅ Loaded ${customExercisesData.length} custom exercises');

      // Convertir en modèles
      final exercises = <Exercise>[];
      final muscleGroupsSet = <String>{};

      for (final row in exercisesData) {
        final name = locService.getTextFromColumns(row['name_fr'], row['name_en'], row['name_de']);
        final muscleGroup = locService.getTextFromColumns(row['muscle_group_fr'], row['muscle_group_en'], row['muscle_group_de']);

        // Debug pour les premiers exercices
        if (exercisesData.indexOf(row) < 3) {
          debugPrint('🏋️ Exercise: name_de="${row['name_de']}", name_en="${row['name_en']}" -> final name="$name"');
        }

        final exercise = Exercise(
          id: row['id'] as String,
          name: name,
          muscleGroup: muscleGroup,
          equipment: row['equipment'] as String? ?? '',
          description: row['description'] as String? ?? '',
          isCustom: (row['is_custom'] as bool?) ?? false,
        );
        exercises.add(exercise);
        if (exercise.muscleGroup.isNotEmpty) {
          muscleGroupsSet.add(exercise.muscleGroup);
        }
      }

      for (final row in customExercisesData) {
        final exercise = Exercise(
          id: row['id'] as String,
          name: row['name'] as String? ?? '',
          muscleGroup: row['muscle_group'] as String? ?? '',
          equipment: row['equipment'] as String? ?? '',
          description: row['description'] as String? ?? '',
          isCustom: true,
        );
        exercises.add(exercise);
        if (exercise.muscleGroup.isNotEmpty) {
          muscleGroupsSet.add(exercise.muscleGroup);
        }
      }

      debugPrint('💪 Total exercises after conversion: ${exercises.length}');
      debugPrint('🏋️ Muscle groups found: ${muscleGroupsSet.length}');

      // Trier par fréquence d'utilisation
      exercises.sort((a, b) {
        final aCount = exerciseSessionCounts[a.name] ?? 0;
        final bCount = exerciseSessionCounts[b.name] ?? 0;

        if (aCount > 0 && bCount > 0) {
          return bCount.compareTo(aCount);
        }
        if (aCount > 0 && bCount == 0) return -1;
        if (aCount == 0 && bCount > 0) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      setState(() {
        allExercises = exercises;
        filteredExercises = exercises;
        availableMuscleGroups = muscleGroupsSet.toList()..sort();
        _loading = false;
      });

      debugPrint('✅ State updated - showing ${filteredExercises.length} exercises');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors du chargement des exercices: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _filterExercises() {
    setState(() {
      filteredExercises = allExercises.where((exercise) {
        final matchesSearch = exercise.name
            .toLowerCase()
            .contains(searchController.text.toLowerCase());

        // Cas spécial : si "Personnalisé" est dans les filtres
        final customFilterKey = 'workout_custom_type'.tr(LocalizationService.instance.currentLanguageCode);
        final hasCustomFilter = selectedMuscleFilters.contains(customFilterKey);

        if (hasCustomFilter && selectedMuscleFilters.length == 1) {
          // Uniquement le filtre "Personnalisé" est actif : ne montrer que les exercices custom
          return matchesSearch && exercise.isCustom;
        } else if (hasCustomFilter && selectedMuscleFilters.length > 1) {
          // "Personnalisé" + d'autres filtres : exercices custom OU exercices avec les groupes musculaires sélectionnés
          final otherFilters = selectedMuscleFilters.where((f) => f != customFilterKey).toSet();
          return matchesSearch && (exercise.isCustom || otherFilters.contains(exercise.muscleGroup));
        }

        final matchesMuscleGroup = selectedMuscleFilters.isEmpty ||
            selectedMuscleFilters.contains(exercise.muscleGroup);

        return matchesSearch && matchesMuscleGroup;
      }).toList();

      // Re-trier par fréquence après le filtrage
      filteredExercises.sort((a, b) {
        final aCount = exerciseSessionCounts[a.name] ?? 0;
        final bCount = exerciseSessionCounts[b.name] ?? 0;

        if (aCount > 0 && bCount > 0) {
          return bCount.compareTo(aCount);
        }
        if (aCount > 0 && bCount == 0) return -1;
        if (aCount == 0 && bCount > 0) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    });
  }

  Future<void> _createCustomExercise(String name) async {
    try {
      final customType = 'workout_custom_type'.tr(LocalizationService.instance.currentLanguageCode);

      // Créer l'exercice custom
      final created = await db.DatabaseService.createCustomExercise(
        name: name,
        muscleGroup: customType,
      );

      if (created != null && mounted) {
        // Retourner l'exercice créé
        Navigator.pop(context, created);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de l\'exercice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création de l\'exercice'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(
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
                onChanged: (_) => _filterExercises(),
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

              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Grille de groupes musculaires si recherche vide et aucun filtre actif
                if (searchController.text.isEmpty && selectedMuscleFilters.isEmpty) ...[
                  Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      locService.isGerman ? 'Nach Muskelgruppe wählen' : (locService.isFrench ? 'Choisir par groupe musculaire' : 'Choose by muscle group'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildMuscleGroupsGrid(),
                  ),
                ]
                else ...[
                  _buildFilterChips(),
                  const SizedBox(height: 12),
                  _buildExerciseCount(),
                  const SizedBox(height: 12),

                  // Bouton pour créer un exercice custom si pas de résultats
                  if (searchController.text.isNotEmpty && filteredExercises.isEmpty)
                    _buildCreateExerciseButton(),

                  // Liste des exercices
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = filteredExercises[index];
                        return _buildExerciseItem(exercise);
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleGroupsGrid() {
    debugPrint('🔢 Building grid with ${availableMuscleGroups.length} groups: $availableMuscleGroups');
    return GridView.builder(
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
          return _buildMuscleGroupCard(
            'workout_custom_type'.tr(LocalizationService.instance.currentLanguageCode),
            'assets/images/muscle_groups/custom.png',
          );
        }

        final group = availableMuscleGroups[index];
        final groupLower = group.toLowerCase().trim();

        // Normaliser les umlauts allemands pour la recherche
        final groupNormalized = groupLower
            .replaceAll('\u00FC', 'ue')  // ü -> ue
            .replaceAll('\u00F6', 'oe')  // ö -> oe
            .replaceAll('\u00E4', 'ae')  // ä -> ae
            .replaceAll('\u00DF', 'ss'); // ß -> ss

        // Map explicite pour éviter tout problème de switch
        final Map<String, String> muscleGroupImages = {
          // Français
          'cardio': 'assets/images/muscle_groups/cardio.png',
          'personnalise': 'assets/images/muscle_groups/custom.png',
          'pectoraux': 'assets/images/muscle_groups/chest.png',
          'dos': 'assets/images/muscle_groups/back.png',
          'jambes': 'assets/images/muscle_groups/legs.png',
          'epaules': 'assets/images/muscle_groups/shoulders.png',
          'bras': 'assets/images/muscle_groups/arms.png',
          'abdos': 'assets/images/muscle_groups/abs.png',
          'corps complet': 'assets/images/muscle_groups/full_body.png',
          // Anglais
          'custom': 'assets/images/muscle_groups/custom.png',
          'chest': 'assets/images/muscle_groups/chest.png',
          'back': 'assets/images/muscle_groups/back.png',
          'legs': 'assets/images/muscle_groups/legs.png',
          'shoulders': 'assets/images/muscle_groups/shoulders.png',
          'arms': 'assets/images/muscle_groups/arms.png',
          'core': 'assets/images/muscle_groups/abs.png',
          'abs': 'assets/images/muscle_groups/abs.png',
          'full body': 'assets/images/muscle_groups/full_body.png',
          // Allemand (normalisé sans umlauts)
          'arme': 'assets/images/muscle_groups/arms.png',
          'beine': 'assets/images/muscle_groups/legs.png',
          'brust': 'assets/images/muscle_groups/chest.png',
          'ruecken': 'assets/images/muscle_groups/back.png',
          'schultern': 'assets/images/muscle_groups/shoulders.png',
          'rumpf': 'assets/images/muscle_groups/abs.png',
          'ganzkoerper': 'assets/images/muscle_groups/full_body.png',
          'benutzerdefiniert': 'assets/images/muscle_groups/custom.png',
        };

        // Essayer d'abord avec la version normalisée, puis avec l'original
        var imagePath = muscleGroupImages[groupNormalized];
        imagePath ??= muscleGroupImages[groupLower];

        debugPrint('🔴 DEBUG MAPPING: group="$group" | groupLower="$groupLower" | normalized="$groupNormalized" | found=${imagePath != null}');

        final finalPath = imagePath ?? 'assets/images/muscle_groups/chest.png';

        return _buildMuscleGroupCard(group, finalPath);
      },
    );
  }

  Widget _buildMuscleGroupCard(String group, String imagePath) {
    debugPrint('🎨 RENDERING CARD: "$group" with image: $imagePath');
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMuscleFilters.add(group);
          _filterExercises();
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
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ Error loading image $imagePath: $error');
                  return const Icon(Icons.error, color: Colors.red);
                },
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
  }

  Widget _buildFilterChips() {
    final locService = LocalizationService.instance;
    final customFilterKey = 'workout_custom_type'.tr(locService.currentLanguageCode);

    // Créer une liste incluant "Personnalisé" + les groupes musculaires
    final allFilterOptions = [customFilterKey, ...availableMuscleGroups];

    return Row(
      children: [
        // Bouton "Tout" pour déselectionner tous les filtres
        if (selectedMuscleFilters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedMuscleFilters.clear();
                  _filterExercises();
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
                      locService.isGerman ? 'Alle' : (locService.isFrench ? 'Tout' : 'All'),
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

        // Liste défilable des groupes musculaires + Personnalisé
        Expanded(
          child: SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allFilterOptions.length,
              itemBuilder: (context, index) {
                final group = allFilterOptions[index];
                final isSelected = selectedMuscleFilters.contains(group);

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < allFilterOptions.length - 1 ? 6 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedMuscleFilters.remove(group);
                        } else {
                          selectedMuscleFilters.add(group);
                        }
                        _filterExercises();
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
    );
  }

  Widget _buildExerciseCount() {
    final locService = LocalizationService.instance;

    return Text(
      'exercise_found'.tr(locService.currentLanguageCode)
          .replaceAll('{count}', filteredExercises.length.toString())
          .replaceAll('{plural}', filteredExercises.length > 1 ? 's' : ''),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF64748B),
      ),
    );
  }

  Widget _buildCreateExerciseButton() {
    final locService = LocalizationService.instance;

    return GestureDetector(
      onTap: () => _createCustomExercise(searchController.text.trim()),
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
                  Text(
                    'workout_create_new_exercise'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
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
    );
  }

  Widget _buildExerciseItem(Exercise exercise) {
    final sessionCount = exerciseSessionCounts[exercise.name] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.pop(context, exercise),
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
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF0B132B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Tag de fréquence
                      if (sessionCount == 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            LocalizationService.instance.isGerman ? 'Neu' : (LocalizationService.instance.isFrench ? 'Nouveau' : 'New'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$sessionCount×',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0B132B),
                            ),
                          ),
                        ),
                      ],
                      // Icône info (seulement pour les exercices non-custom)
                      if (!exercise.isCustom) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            ExerciseInfoBottomSheet.show(
                              context,
                              exerciseId: exercise.id,
                              exerciseName: exercise.name,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF94A3B8).withValues(alpha: 0.3), width: 1),
                            ),
                            child: const Text(
                              '?',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (exercise.muscleGroup.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      exercise.muscleGroup,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
