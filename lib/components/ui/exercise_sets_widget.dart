import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/sport_models.dart';
import 'numeric_text_field.dart';

class ExerciseSetsWidget extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final Function(int setIndex, ExerciseSet updatedSet) onSetUpdated;
  final Function() onAddSet;
  final Function(int setIndex) onRemoveSet;
  final Function() onRemoveExercise;
  final bool initiallyExpanded;

  const ExerciseSetsWidget({
    super.key,
    required this.workoutExercise,
    required this.onSetUpdated,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
    this.initiallyExpanded = true,
  });

  @override
  State<ExerciseSetsWidget> createState() => _ExerciseSetsWidgetState();
}

class _ExerciseSetsWidgetState extends State<ExerciseSetsWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de l'exercice (cliquable pour plier/déplier)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // Icône pour déplier/replier à gauche
                  Icon(
                    _isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 16,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.dumbbell,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workoutExercise.exercise.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          widget.workoutExercise.exercise.muscleGroup,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.workoutExercise.sets.where((set) => set.isValid).length}/${widget.workoutExercise.sets.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bouton suppression de l'exercice à droite
                  GestureDetector(
                    onTap: widget.onRemoveExercise,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Séries (seulement si déplié)
          if (_isExpanded) ...[
            if (widget.workoutExercise.sets.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Text(
                    'Aucune série ajoutée',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Headers des colonnes
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Poids (kg)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Répétitions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 50), // Pour le bouton done/delete
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Liste des séries
                    ...widget.workoutExercise.sets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final set = entry.value;
                      return _buildSetRow(index, set);
                    }).toList(),
                  ],
                ),
              ),
          ],
          
          // Bouton ajouter une série (seulement si déplié)
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Center(
                child: TextButton.icon(
                  onPressed: widget.onAddSet,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Ajouter une série'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0B132B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int index, ExerciseSet set) {
    final weightController = TextEditingController(
      text: set.weight > 0 ? set.weight.toString() : '',
    );
    final repsController = TextEditingController(
      text: set.reps > 0 ? set.reps.toString() : '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          
          // Champ poids
          Expanded(
            child: NumericTextField(
              controller: weightController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                final weight = double.tryParse(value) ?? 0;
                final updatedSet = set.copyWith(weight: weight);
                widget.onSetUpdated(index, updatedSet);
              },
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Champ répétitions
          Expanded(
            child: NumericTextField(
              controller: repsController,
              allowDecimals: false,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                final reps = int.tryParse(value) ?? 0;
                final updatedSet = set.copyWith(reps: reps);
                widget.onSetUpdated(index, updatedSet);
              },
            ),
          ),
          
          const SizedBox(width: 8),

          // Bouton supprimer (affiché seulement s'il y a plus d'une série)
          if (widget.workoutExercise.sets.length > 1)
            GestureDetector(
              onTap: () => widget.onRemoveSet(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.trash2,
                  size: 12,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
