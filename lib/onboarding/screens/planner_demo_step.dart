import 'package:flutter/material.dart';

import '../../models/weekly_planner_models.dart';
import '../../screens/planner_chat_screen.dart';

/// The real planner, in demo mode: meals first, then workouts.
/// Same widget the app uses, so what the user tries is what they get.
class PlannerDemoStep extends StatefulWidget {
  const PlannerDemoStep({super.key, required this.onCollected, required this.onDone});

  final void Function(List<PendingMeal> meals, List<PendingWorkout> workouts, List<PendingSession> sessions) onCollected;
  final VoidCallback onDone;

  @override
  State<PlannerDemoStep> createState() => _PlannerDemoStepState();
}

class _PlannerDemoStepState extends State<PlannerDemoStep> {
  bool _sport = false;

  /// Seven days from today, not a calendar week: a demo opened on a Saturday
  /// would otherwise have two days left to fill. The planner service plans
  /// into the same window, so what is validated lands where it is shown.
  WeeklyPlannerData _emptyWeek() {
    final now = DateTime.now();
    return WeeklyPlannerData.fromLists(weekStart: DateTime(now.year, now.month, now.day), activities: [], workouts: []);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim), child: child),
      ),
      child: _sport
          ? PlannerChatScreen(
              key: const ValueKey('demo_workouts'),
              initialMode: 'workouts',
              weekData: _emptyWeek(),
              demoMode: true,
              maxMessages: 5,
              onDemoDataCollected: (meals, workouts, sessions) {
                widget.onCollected(meals, workouts, sessions);
                widget.onDone();
              },
            )
          : PlannerChatScreen(
              key: const ValueKey('demo_meals'),
              initialMode: 'meals',
              weekData: _emptyWeek(),
              demoMode: true,
              maxMessages: 5,
              onDemoDataCollected: (meals, workouts, sessions) {
                widget.onCollected(meals, workouts, sessions);
                setState(() => _sport = true);
              },
            ),
    );
  }
}
