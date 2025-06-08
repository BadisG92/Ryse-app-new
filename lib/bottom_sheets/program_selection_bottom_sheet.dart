import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/sport_models.dart';

class ProgramSelectionBottomSheet extends StatefulWidget {
  final Function(WorkoutProgram program) onProgramSelected;
  final List<WorkoutProgram> customPrograms;

  const ProgramSelectionBottomSheet({
    super.key,
    required this.onProgramSelected,
    this.customPrograms = const [],
  });

  @override
  State<ProgramSelectionBottomSheet> createState() => _ProgramSelectionBottomSheetState();
}

class _ProgramSelectionBottomSheetState extends State<ProgramSelectionBottomSheet> {
  // Base de données de programmes prédéfinis
  final List<WorkoutProgram> _predefinedPrograms = [
    WorkoutProgram(
      id: '1',
      name: 'Push Day - Haut du corps',
      description: 'Séance de poussée : pectoraux, épaules, triceps',
      type: 'Haut du corps',
      estimatedDuration: 60,
      exercises: [
        ProgramExercise(
          exercise: Exercise(
            id: '1',
            name: 'Développé couché',
            muscleGroup: MuscleGroups.chest,
            equipment: 'Barre',
          ),
          sets: 4,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: '4',
            name: 'Développé militaire',
            muscleGroup: MuscleGroups.shoulders,
            equipment: 'Barre',
          ),
          sets: 3,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: '6',
            name: 'Dips',
            muscleGroup: MuscleGroups.triceps,
            equipment: 'Barres parallèles',
          ),
          sets: 3,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: '5',
            name: 'Curl biceps',
            muscleGroup: MuscleGroups.biceps,
            equipment: 'Haltères',
          ),
          sets: 3,
        ),
      ],
    ),
    WorkoutProgram(
      id: '2',
      name: 'Pull Day - Haut du corps',
      description: 'Séance de traction : dos, biceps',
      type: 'Haut du corps',
      estimatedDuration: 50,
      exercises: [
        ProgramExercise(
          exercise: Exercise(
            id: '3',
            name: 'Tractions',
            muscleGroup: MuscleGroups.back,
            equipment: 'Barre de traction',
          ),
          sets: 4,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: '7',
            name: 'Soulevé de terre',
            muscleGroup: MuscleGroups.back,
            equipment: 'Barre',
          ),
          sets: 3,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: '5',
            name: 'Curl biceps',
            muscleGroup: MuscleGroups.biceps,
            equipment: 'Haltères',
          ),
          sets: 4,
        ),
      ],
    ),
    WorkoutProgram(
      id: '3',
      name: 'Leg Day - Bas du corps',
      description: 'Séance jambes et fessiers complète',
      type: 'Bas du corps',
      estimatedDuration: 70,
      exercises: [
        ProgramExercise(
          exercise: Exercise(
            id: '2',
            name: 'Squat',
            muscleGroup: MuscleGroups.legs,
            equipment: 'Barre',
          ),
          sets: 4,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: '7',
            name: 'Soulevé de terre',
            muscleGroup: MuscleGroups.back,
            equipment: 'Barre',
          ),
          sets: 3,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: 'leg_press',
            name: 'Presse à cuisses',
            muscleGroup: MuscleGroups.legs,
            equipment: 'Machine',
          ),
          sets: 3,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: 'calf_raise',
            name: 'Mollets debout',
            muscleGroup: MuscleGroups.calves,
            equipment: 'Machine',
          ),
          sets: 4,
        ),
      ],
    ),
    WorkoutProgram(
      id: '4',
      name: 'Full Body - Débutant',
      description: 'Programme complet pour tout le corps',
      type: 'Full body',
      estimatedDuration: 45,
      exercises: [
        ProgramExercise(
          exercise: Exercise(
            id: '2',
            name: 'Squat',
            muscleGroup: MuscleGroups.legs,
            equipment: 'Barre',
          ),
          sets: 3,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: '1',
            name: 'Développé couché',
            muscleGroup: MuscleGroups.chest,
            equipment: 'Barre',
          ),
          sets: 3,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: '3',
            name: 'Tractions',
            muscleGroup: MuscleGroups.back,
            equipment: 'Barre de traction',
          ),
          sets: 3,
        ),
        ProgramExercise(
          exercise: Exercise(
            id: '8',
            name: 'Crunchs',
            muscleGroup: MuscleGroups.abs,
            equipment: 'Aucun',
          ),
          sets: 3,
        ),
      ],
    ),
  ];

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
              'Choisir un programme',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              widget.customPrograms.isNotEmpty 
                  ? 'Vos programmes personnalisés et programmes prédéfinis'
                  : 'Sélectionnez un programme avec exercices prédéfinis',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Liste des programmes
            Expanded(
              child: ListView.builder(
                itemCount: widget.customPrograms.length + _predefinedPrograms.length + 
                    (widget.customPrograms.isNotEmpty ? 1 : 0), // +1 pour le séparateur
                itemBuilder: (context, index) {
                  if (index < widget.customPrograms.length) {
                    // Programmes personnalisés en premier
                    final program = widget.customPrograms[index];
                    return _buildProgramCard(program, isCustom: true);
                  } else if (index == widget.customPrograms.length && widget.customPrograms.isNotEmpty) {
                    // Séparateur entre programmes personnalisés et prédéfinis
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: const Color(0xFFE2E8F0))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Programmes prédéfinis',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: const Color(0xFFE2E8F0))),
                        ],
                      ),
                    );
                  } else {
                    // Programmes prédéfinis
                    final adjustedIndex = widget.customPrograms.isNotEmpty 
                        ? index - widget.customPrograms.length - 1 
                        : index - widget.customPrograms.length;
                    final program = _predefinedPrograms[adjustedIndex];
                    return _buildProgramCard(program, isCustom: false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard(WorkoutProgram program, {bool isCustom = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onProgramSelected(program);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCustom 
                          ? [const Color(0xFF059669), const Color(0xFF10B981)] 
                          : [const Color(0xFF0B132B), const Color(0xFF1C2951)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCustom ? LucideIcons.user : LucideIcons.dumbbell,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        program.description,
                        style: const TextStyle(
                          fontSize: 13,
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
            
            const SizedBox(height: 12),
            
            // Informations du programme
            Row(
              children: [
                // Pour les programmes personnalisés, on ne montre pas la durée
                if (!isCustom) ...[
                  _buildProgramInfo(
                    LucideIcons.clock,
                    '${program.estimatedDuration} min',
                  ),
                  const SizedBox(width: 16),
                ],
                _buildProgramInfo(
                  LucideIcons.target,
                  program.type,
                ),
                const SizedBox(width: 16),
                _buildProgramInfo(
                  LucideIcons.listChecks,
                  '${program.exercises.length} exercices',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Liste des exercices du programme
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: program.exercises.map((programExercise) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '${programExercise.exercise.name} (${programExercise.sets}x)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
