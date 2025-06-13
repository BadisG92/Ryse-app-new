import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/sport_models.dart';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterExercises() {
    setState(() {
      _filteredExercises = _predefinedExercises.where((exercise) {
        final matchesSearch = exercise.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
        final matchesMuscle = _selectedMuscleFilter == 'Tous' ||
            exercise.muscleGroup == _selectedMuscleFilter;
        return matchesSearch && matchesMuscle;
      }).toList();
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
                
                const Text(
                  'Nombre de séries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                TextField(
                  controller: setsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Nombre de séries',
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
                
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nom de l\'exercice',
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
                
                const Text(
                  'Nombre de séries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                TextField(
                  controller: setsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Nombre de séries',
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un exercice...',
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Créer un exercice personnalisé',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'Ajouter un exercice qui ne figure pas dans la liste',
                    style: TextStyle(
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
}
