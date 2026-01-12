import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/weekly_planner_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/global_state_manager.dart';
import '../../screens/planner_chat_screen.dart';
import 'day_column_widget.dart';
import 'add_activity_bottom_sheet.dart';
import 'workout_recap_bottom_sheet.dart';
import 'cardio_recap_bottom_sheet.dart';

/// Widget principal du planificateur hebdomadaire
class WeeklyPlannerWidget extends StatefulWidget {
  final bool isPremium;
  final VoidCallback? onPremiumTap;

  const WeeklyPlannerWidget({
    super.key,
    required this.isPremium,
    this.onPremiumTap,
  });

  @override
  State<WeeklyPlannerWidget> createState() => _WeeklyPlannerWidgetState();
}

class _WeeklyPlannerWidgetState extends State<WeeklyPlannerWidget> {
  WeeklyPlannerData _weekData = WeeklyPlannerData.empty();
  bool _isLoading = true;
  bool _isMigrating = false; // Flag pour éviter les boucles de rechargement
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    // S'abonner aux changements globaux
    GlobalStateManager.instance.events.listen(_onGlobalStateChange);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onGlobalStateChange(StateChangeEvent event) {
    // Recharger si nécessaire, mais pas pendant une migration
    if (_isMigrating) return;

    if (event.type == ChangeType.dayReset || event.type == ChangeType.planner) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Nettoyer les activités manquées au chargement
      await WeeklyPlannerService.cleanupMissedActivities();

      // Migrer les séances de l'historique vers le planificateur (sync rétroactive)
      // On active le flag pour éviter les boucles de rechargement
      _isMigrating = true;
      await WeeklyPlannerService.migrateHistoryToPlanner();
      _isMigrating = false;

      final data = await WeeklyPlannerService.getWeekData();

      if (mounted) {
        setState(() {
          _weekData = data;
          _isLoading = false;
        });

        // Scroller vers aujourd'hui
        _scrollToToday();
      }
    } catch (e) {
      _isMigrating = false; // S'assurer de réinitialiser le flag en cas d'erreur
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final now = DateTime.now();
      final todayIndex = now.weekday - 1; // 0 = Lundi

      // Largeur estimée d'une colonne jour (incluant padding)
      const dayColumnWidth = 52.0;
      final offset = (todayIndex * dayColumnWidth) - 40; // Centrer un peu

      if (offset > 0 && offset < _scrollController.position.maxScrollExtent) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAddActivitySheet(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddActivityBottomSheet(
        selectedDate: date,
        onActivityAdded: () {
          _loadData();
        },
      ),
    );
  }

  void _openPlannerChat(BuildContext context, {required String mode}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlannerChatScreen(
          initialMode: mode,
          weekData: _weekData,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Laisser le Hero gérer l'animation principale
          // Juste un léger fade pour le contenu qui n'est pas dans le Hero
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 500),
      ),
    ).then((_) {
      // Rafraîchir les données au retour
      _loadData();
    });
  }

  void _showWorkoutRecap(BuildContext context, PlannedWorkout workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutRecapBottomSheet(
        workout: workout,
        onWorkoutStarted: () {
          _loadData();
        },
        onWorkoutDeleted: () {
          _loadData();
        },
      ),
    );
  }

  void _showCardioRecap(BuildContext context, PlannedActivity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CardioRecapBottomSheet(
        activity: activity,
        onCardioStarted: () {
          _loadData();
        },
        onCardioDeleted: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final langCode = locService.currentLanguageCode;

    return Hero(
      tag: 'weekly_planner_hero',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, langCode),

              // Jours de la semaine
              _buildWeekDays(context, langCode),

              // Zone IA (planifier avec Ryze)
              _buildAIZone(context, langCode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String langCode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'weekly_planner_title'.tr(langCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B132B),
              ),
            ),
          ),
          // Badge Premium
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFF4E4BC)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.crown, size: 12, color: Color(0xFF0B132B)),
                SizedBox(width: 4),
                Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays(BuildContext context, String langCode) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF0B132B),
            ),
          ),
        ),
      );
    }

    final dayNames = _getDayNames(langCode);

    return SizedBox(
      height: 130,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = _weekData.weekStart.add(Duration(days: index));
          final dayPlan = _weekData.getDayPlan(date);

          return DayColumnWidget(
            date: date,
            dayName: dayNames[index],
            dayPlan: dayPlan,
            onTap: () => _showAddActivitySheet(context, date),
            onActivityTap: (activity) {
              // Afficher le recap selon le type d'activité
              if (activity.activityType == PlannedActivityType.cardio) {
                _showCardioRecap(context, activity);
              }
              // TODO: Gérer les repas si nécessaire
            },
            onWorkoutTap: (workout) => _showWorkoutRecap(context, workout),
          );
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, String langCode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showAddActivitySheet(context, today),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: Color(0xFF0B132B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'planner_add_activity'.tr(langCode),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIZone(BuildContext context, String langCode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Bouton Planifier mes repas
          _buildAIButton(
            context,
            langCode,
            icon: LucideIcons.utensils,
            label: 'plan_my_meals'.tr(langCode),
            mode: 'meals',
          ),
          const SizedBox(height: 10),
          // Bouton Planifier mes séances
          _buildAIButton(
            context,
            langCode,
            icon: LucideIcons.dumbbell,
            label: 'plan_my_workouts'.tr(langCode),
            mode: 'workouts',
          ),
        ],
      ),
    );
  }

  Widget _buildAIButton(
    BuildContext context,
    String langCode, {
    required IconData icon,
    required String label,
    required String mode,
  }) {
    return InkWell(
      onTap: () => _openPlannerChat(context, mode: mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0B132B).withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF0B132B),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B132B),
              ),
            ),
            const Spacer(),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: const Color(0xFF64748B).withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getDayNames(String langCode) {
    switch (langCode) {
      case 'fr':
        return ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
      case 'de':
        return ['M', 'D', 'M', 'D', 'F', 'S', 'S'];
      default:
        return ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    }
  }
}
