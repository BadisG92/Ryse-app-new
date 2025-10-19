import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../models/sport_models.dart';
import '../../screens/workout_session_screen.dart';
import '../../screens/ai_workout_generator_screen.dart';
import '../../bottom_sheets/program_selection_bottom_sheet.dart';
import '../../services/workout_service.dart';
import '../../services/localization_service.dart';

class WorkoutActions {
  static void showMusculationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                'Musculation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Choisissez votre type de séance',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 16),

              // Les 3 boutons côte à côte
              Row(
                children: [
                  // Bouton séance manuelle
                  Expanded(
                    child: WorkoutOptionButton(
                      icon: LucideIcons.pencil,
                      title: 'Séance manuelle',
                      onTap: () => startManualSession(context),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Bouton séance guidée
                  Expanded(
                    child: WorkoutOptionButton(
                      icon: LucideIcons.bookOpen,
                      title: 'Séance guidée',
                      onTap: () => showGuidedSessionOptions(context),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Bouton Coach Ryze
                  Expanded(
                    child: CoachRyzeButton(
                      onTap: () => startAIWorkoutGenerator(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static void startManualSession(BuildContext context) {
    Navigator.pop(context); // Fermer le bottom sheet
    showSessionNameModal(context);
  }

  static void showGuidedSessionOptions(BuildContext context) {
    Navigator.pop(context); // Fermer le bottom sheet actuel
    showProgramsModal(context);
  }

  static void showSessionNameModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    nameController.text = 'Séance du ${DateTime.now().day}/${DateTime.now().month}';

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
                  'Nom de la séance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nom de la séance',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      startSession(context, nameController.text);
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
                      'Commencer la séance',
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

  static void showProgramsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgramSelectionBottomSheet(
        onProgramSelected: (program) => startSessionFromProgram(context, program),
        customPrograms: WorkoutService().customPrograms,
      ),
    );
  }

  static void startSession(BuildContext context, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          sessionName: name,
          exercises: [],
          isFromProgram: false,
          guidedTemplateId: null,
          onProgramSaved: (WorkoutProgram program) {
            WorkoutService().addProgram(program);
          },
          onSessionCompleted: (WorkoutSession session) {
            print('Session complétée: ${session.name}');
          },
        ),
      ),
    );
  }

  static void startSessionFromProgram(BuildContext context, WorkoutProgram program) {
    final programExercises = program.exercises.map((programExercise) {
      return WorkoutExercise(
        exercise: programExercise.exercise,
        sets: List.generate(
          programExercise.sets,
          (index) => const ExerciseSet(reps: 0, weight: 0),
        ),
        suggestedRepsMin: programExercise.suggestedRepsMin,
        suggestedRepsMax: programExercise.suggestedRepsMax,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          sessionName: program.name,
          exercises: programExercises,
          isFromProgram: true,
          guidedTemplateId: program.id,
          onSessionCompleted: (WorkoutSession session) {
            print('Session complétée: ${session.name}');
          },
        ),
      ),
    );
  }

  static void startAIWorkoutGenerator(BuildContext context) {
    Navigator.pop(context); // Fermer le bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIWorkoutGeneratorScreen(),
      ),
    );
  }
}

class WorkoutOptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const WorkoutOptionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoachRyzeButton extends StatelessWidget {
  final VoidCallback onTap;

  const CoachRyzeButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/logo_solo.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: Text(
                        'Coach\nRyze',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bulle "For you" positionnée au-dessus
            Positioned(
              top: -10,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B132B).withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  locService.currentLanguageCode == 'fr' ? 'Pour toi' : 'For you',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
