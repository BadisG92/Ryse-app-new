import 'package:flutter/material.dart';
import '../../services/global_state_manager.dart';
import '../../services/localization_service.dart';
import 'package:provider/provider.dart';

/// Widget de header qui écoute GlobalStateManager pour synchronisation instantanée
/// Remplace l'ancien HeaderCacheService pour une architecture unifiée
class GlobalStateHeaderWidget extends StatefulWidget {
  final bool useGradient;

  const GlobalStateHeaderWidget({
    super.key,
    this.useGradient = true,
  });

  @override
  State<GlobalStateHeaderWidget> createState() => _GlobalStateHeaderWidgetState();
}

class _GlobalStateHeaderWidgetState extends State<GlobalStateHeaderWidget> with GlobalStateListener {
  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    // Le mixin GlobalStateListener appelle automatiquement setState
    // Pas besoin de faire quoi que ce soit ici, le widget se rebuild automatiquement
  }

  @override
  Widget build(BuildContext context) {
    final globalState = GlobalStateManager.instance;
    final locService = Provider.of<LocalizationService>(context);
    final isEnglish = locService.currentLanguageCode == 'en';
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topInset, left: 12, right: 12),
      decoration: widget.useGradient
          ? const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            )
          : const BoxDecoration(
              color: Colors.transparent,
            ),
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Calories
            _buildStatItem(
              icon: Icons.restaurant,
              value: '${globalState.currentCalories.toInt()}',
              label: isEnglish ? 'kcal' : 'kcal',
              progress: globalState.calorieProgress / 100,
            ),

            const _HeaderSeparator(),

            // Eau
            _buildStatItem(
              icon: Icons.water_drop,
              value: '${globalState.currentWaterL.toStringAsFixed(1)}',
              label: 'L',
              progress: globalState.waterProgress / 100,
            ),

            const _HeaderSeparator(),

            // Sport
            _buildStatItem(
              icon: Icons.fitness_center,
              value: globalState.workoutCompleted ? '✓' : '○',
              label: isEnglish ? 'Sport' : 'Sport',
              progress: globalState.workoutCompleted ? 1.0 : 0.0,
              isCompleted: globalState.workoutCompleted,
            ),

            const _HeaderSeparator(),

            // Streak
            _buildStatItem(
              icon: Icons.local_fire_department,
              value: '${globalState.currentStreak}',
              label: isEnglish ? 'days' : 'jours',
              progress: 1.0, // Streak n'a pas de progression
              color: const Color(0xFFFF6B35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required double progress,
    bool isCompleted = false,
    Color? color,
  }) {
    final displayColor = color ?? (isCompleted ? const Color(0xFF10B981) : Colors.white70);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: displayColor,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: displayColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: displayColor.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _HeaderSeparator extends StatelessWidget {
  const _HeaderSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}
