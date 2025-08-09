import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/sport_models.dart';
import '../services/database_service.dart';

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
  // Programmes chargés depuis Supabase
  List<WorkoutProgram> _fetchedPrograms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      // 1) Instant cache/seed for immediate UI
      final instant = await DatabaseService.getWorkoutTemplatesInstant(language: 'fr');
      if (!mounted) return;
      setState(() {
        _fetchedPrograms = instant;
        _isLoading = false;
      });

      // 2) Fresh data in background; update UI if changed
      final fresh = await DatabaseService.getWorkoutTemplates(language: 'fr', includePublic: true);
      if (!mounted) return;
      if (fresh.isNotEmpty) {
        setState(() {
          _fetchedPrograms = fresh;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement des programmes';
        _isLoading = false;
      });
    }
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFEF4444)),
                          ),
                        )
                      : ListView.builder(
                          itemCount: widget.customPrograms.length + _fetchedPrograms.length +
                              (widget.customPrograms.isNotEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < widget.customPrograms.length) {
                              // Programmes personnalisés en premier
                              final program = widget.customPrograms[index];
                              return _buildProgramCard(program, isCustom: true);
                            } else if (index == widget.customPrograms.length && widget.customPrograms.isNotEmpty) {
                              // Séparateur entre programmes personnalisés et ceux de Supabase
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(child: Divider(color: const Color(0xFFE2E8F0))),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Programmes',
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
                              // Programmes depuis Supabase
                              final adjustedIndex = widget.customPrograms.isNotEmpty
                                  ? index - widget.customPrograms.length - 1
                                  : index - widget.customPrograms.length;
                              if (adjustedIndex < 0 || adjustedIndex >= _fetchedPrograms.length) {
                                return const SizedBox.shrink();
                              }
                              final program = _fetchedPrograms[adjustedIndex];
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
