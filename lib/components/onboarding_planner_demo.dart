import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/weekly_planner_models.dart';
import '../screens/planner_chat_screen.dart';
import '../screens/paywall_screen.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/paywall_service.dart';
import '../services/planner_ai_service.dart';
import 'main_app.dart';

/// Onboarding planner demo flow:
/// Phase 1: Meal planning chat (demo mode)
/// Phase 2: Sport planning chat (demo mode)
/// Then: Hard paywall → save data if user subscribes → MainApp
class OnboardingPlannerDemo extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPlannerDemo({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingPlannerDemo> createState() => _OnboardingPlannerDemoState();
}

class _OnboardingPlannerDemoState extends State<OnboardingPlannerDemo>
    with SingleTickerProviderStateMixin {
  // 0: intro, 1: meals chat, 2: sport chat, 3: paywall
  int _phase = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Collected demo data
  final List<PendingMeal> _allMeals = [];
  final List<PendingWorkout> _allWorkouts = [];
  final List<PendingSession> _allSessions = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  WeeklyPlannerData _buildEmptyWeekData() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return WeeklyPlannerData.fromLists(
      weekStart: monday,
      activities: [],
      workouts: [],
    );
  }

  void _onMealsDemoComplete(List<PendingMeal> meals, List<PendingWorkout> workouts, List<PendingSession> sessions) {
    _allMeals.addAll(meals);
    _allWorkouts.addAll(workouts);
    _allSessions.addAll(sessions);

    // Transition to sport phase
    setState(() => _phase = 2);
    _fadeController.reset();
    _fadeController.forward();
  }

  void _onSportDemoComplete(List<PendingMeal> meals, List<PendingWorkout> workouts, List<PendingSession> sessions) {
    _allMeals.addAll(meals);
    _allWorkouts.addAll(workouts);
    _allSessions.addAll(sessions);

    // Go to hard paywall
    _showHardPaywall();
  }

  Future<bool> _saveDemoDataToDatabase() async {
    try {
      // Save confirmed meals
      for (final meal in _allMeals) {
        await PlannerAIService.confirmMeals([meal]);
      }

      // Save confirmed workouts
      if (_allWorkouts.isNotEmpty) {
        await PlannerAIService.confirmWorkouts(_allWorkouts);
      }

      // Save confirmed sessions
      for (final session in _allSessions) {
        await PlannerAIService.confirmSingleSession(session);
      }

      debugPrint('✅ Demo data saved to database');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error saving demo data: $e');
      return false;
    }
  }

  void _navigateToMainApp(BuildContext navContext) {
    Navigator.of(navContext, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainApp()),
      (route) => false,
    );
  }

  void _showHardPaywall() {
    final langCode = LocalizationService.instance.currentLanguageCode;
    // Capture demo data and callback before navigation removes this widget
    final demoMeals = List<PendingMeal>.from(_allMeals);
    final demoWorkouts = List<PendingWorkout>.from(_allWorkouts);
    final demoSessions = List<PendingSession>.from(_allSessions);
    final onComplete = widget.onComplete;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (ctx) => PaywallScreen(
          context: PaywallContext.onboarding,
          isHardPaywall: true,
          onPurchaseSuccess: () async {
            // Show loading overlay while saving
            showDialog(
              context: ctx,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
            );

            // Save demo data
            bool saved = false;
            try {
              for (final meal in demoMeals) {
                await PlannerAIService.confirmMeals([meal]);
              }
              if (demoWorkouts.isNotEmpty) {
                await PlannerAIService.confirmWorkouts(demoWorkouts);
              }
              for (final session in demoSessions) {
                await PlannerAIService.confirmSingleSession(session);
              }
              saved = true;
            } catch (e) {
              debugPrint('⚠️ Error saving demo data: $e');
            }

            if (!ctx.mounted) return;
            Navigator.of(ctx).pop(); // Dismiss loading

            if (!saved && ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Données sauvegardées partiellement. Vous pouvez re-planifier depuis l\'app.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }

            // Mark onboarding as completed, then navigate to main app
            onComplete();
            if (ctx.mounted) _navigateToMainApp(ctx);
          },
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case 0:
        return _buildIntroScreen();
      case 1:
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: PlannerChatScreen(
              key: const ValueKey('demo_meals'),
              initialMode: 'meals',
              weekData: _buildEmptyWeekData(),
              demoMode: true,
              maxMessages: 5,
              onDemoDataCollected: _onMealsDemoComplete,
            ),
          ),
        );
      case 2:
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: PlannerChatScreen(
              key: const ValueKey('demo_workouts'),
              initialMode: 'workouts',
              weekData: _buildEmptyWeekData(),
              demoMode: true,
              maxMessages: 5,
              onDemoDataCollected: _onSportDemoComplete,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroScreen() {
    final langCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Coach Ryze avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/coach_ryze_contract.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'onboarding_plan_first_week'.tr(langCode),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'onboarding_plan_first_week_subtitle'.tr(langCode),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 40),

                // Steps preview
                _buildStepPreview(
                  icon: LucideIcons.apple,
                  title: 'onboarding_demo_meals_title'.tr(langCode),
                  subtitle: 'onboarding_demo_meals_subtitle'.tr(langCode),
                  color: Colors.white,
                  step: 1,
                ),
                const SizedBox(height: 12),
                _buildStepPreview(
                  icon: LucideIcons.dumbbell,
                  title: 'onboarding_demo_sport_title'.tr(langCode),
                  subtitle: 'onboarding_demo_sport_subtitle'.tr(langCode),
                  color: Colors.white,
                  step: 2,
                ),

                const Spacer(flex: 3),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _phase = 1);
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                    icon: const Icon(LucideIcons.calendar, size: 20),
                    label: Text(
                      'onboarding_plan_first_week_button'.tr(langCode),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0B132B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Skip button
                TextButton(
                  onPressed: _showHardPaywall,
                  child: Text(
                    'onboarding_demo_skip'.tr(langCode),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepPreview({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int step,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
