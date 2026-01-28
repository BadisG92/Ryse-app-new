import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/weekly_planner_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/global_state_manager.dart';
import '../../services/feature_trial_service.dart';
import '../../services/subscription_service.dart';
import '../../services/paywall_service.dart';
import '../../screens/planner_chat_screen.dart';
import '../../components/ui/custom_card.dart';
import 'day_column_widget.dart';
import 'workout_recap_bottom_sheet.dart';
import 'cardio_recap_bottom_sheet.dart';

/// Badge Trial pour le planificateur - affiche le nombre d'essais restants
/// Même style que les autres features mais avec le compteur
class _PlannerTrialBadge extends StatefulWidget {
  final String langCode;
  final int remainingUsages;
  final bool isLocked;

  const _PlannerTrialBadge({
    required this.langCode,
    required this.remainingUsages,
    required this.isLocked,
  });

  @override
  State<_PlannerTrialBadge> createState() => _PlannerTrialBadgeState();
}

class _PlannerTrialBadgeState extends State<_PlannerTrialBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.isLocked;
    final count = widget.remainingUsages;

    // Texte du badge avec le nombre
    String badgeText;
    if (isLocked) {
      badgeText = 'UPGRADE';
    } else {
      // Afficher "X restants" selon la langue
      if (widget.langCode == 'fr') {
        badgeText = '$count restant${count > 1 ? 's' : ''}';
      } else if (widget.langCode == 'de') {
        badgeText = '$count übrig';
      } else {
        badgeText = '$count left';
      }
    }

    // Badge avec style uniforme doré (même design que TrialStatusBadge)
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Gold gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock_open : Icons.card_giftcard,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    return ScaleTransition(
      scale: _pulseAnimation,
      child: badge,
    );
  }
}

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
  WeeklyPlannerData? _weekData;
  bool _isLoading = true;
  bool _isMigrating = false; // Flag pour éviter les boucles de rechargement
  bool _shouldAnimateProgress = false; // Flag pour animer après génération
  bool _hasCompletedInitialSync = false; // Flag pour éviter fullSync à chaque refresh
  int _dailyCalorieTarget = 2000; // Objectif calorique journalier
  final ScrollController _scrollController = ScrollController();

  // Gestion des essais gratuits du planificateur
  int _remainingUsages = FeatureTrialService.maxPlannerUsages;
  bool _isPlannerLocked = false;
  bool _isCheckingTrials = true;

  @override
  void initState() {
    super.initState();
    _loadUserCalorieTarget();
    _loadData(fullSync: true); // Premier chargement: sync complète
    _loadTrialStatus();
    // S'abonner aux changements globaux
    GlobalStateManager.instance.events.listen(_onGlobalStateChange);
  }

  /// Charger le statut des essais gratuits
  Future<void> _loadTrialStatus() async {
    // Si premium, pas besoin de vérifier les trials
    if (SubscriptionService.instance.isPremium) {
      if (mounted) {
        setState(() {
          _isCheckingTrials = false;
        });
      }
      return;
    }

    try {
      final remaining = await FeatureTrialService.instance.getPlannerRemainingUsages();
      if (mounted) {
        setState(() {
          _remainingUsages = remaining;
          _isPlannerLocked = remaining <= 0;
          _isCheckingTrials = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingTrials = false;
        });
      }
    }
  }

  /// Charger l'objectif calorique de l'utilisateur depuis Supabase
  Future<void> _loadUserCalorieTarget() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('users')
          .select('daily_calories')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _dailyCalorieTarget = response['daily_calories'] ?? 2000;
        });
      }
    } catch (e) {
      // Utiliser la valeur par défaut en cas d'erreur
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onGlobalStateChange(StateChangeEvent event) {
    // Recharger si nécessaire, mais pas pendant une migration
    if (_isMigrating) return;

    // Recharger sur tous les types de changements qui affectent le planner:
    // - dayReset: nouveau jour
    // - planner: mise à jour explicite du planner
    // - calories/meals: ajout/modification de nourriture (affecte le fill rate)
    // - sport/workout: ajout/modification d'activité sportive
    if (event.type == ChangeType.dayReset ||
        event.type == ChangeType.planner ||
        event.type == ChangeType.calories ||
        event.type == ChangeType.meals ||
        event.type == ChangeType.sport ||
        event.type == ChangeType.workout) {
      _loadData();
    }
  }

  Future<void> _loadData({bool fullSync = false}) async {
    if (!mounted) return;

    // Ne pas afficher le loader pour les refreshes rapides (quand on a déjà des données)
    final isFirstLoad = _weekData == null;
    if (isFirstLoad) {
      setState(() => _isLoading = true);
    }

    try {
      // Sync complète UNIQUEMENT au premier chargement de la session
      // Les refreshes suivants ne font que récupérer les données à jour
      if (fullSync && !_hasCompletedInitialSync) {
        debugPrint('🔄 WeeklyPlanner: Initial full sync...');
        // Nettoyer les activités manquées
        await WeeklyPlannerService.cleanupMissedActivities();

        // Sync complète: nettoie les orphelins + migre les sessions manquantes
        _isMigrating = true;
        await WeeklyPlannerService.fullSyncFromHistory();
        _isMigrating = false;
        _hasCompletedInitialSync = true;
        debugPrint('✅ WeeklyPlanner: Initial sync complete');
      }

      // Récupérer les données (utilise le cache si disponible, sinon fetch)
      // Le cache est automatiquement invalidé après toute modification
      debugPrint('📦 WeeklyPlanner: Fetching week data...');
      final data = await WeeklyPlannerService.getWeekData();

      if (mounted) {
        setState(() {
          _weekData = data;
          _isLoading = false;
        });

        // Scroller vers aujourd'hui uniquement au premier chargement
        if (isFirstLoad) {
          _scrollToToday();
        }
      }
    } catch (e) {
      debugPrint('❌ WeeklyPlanner._loadData error: $e');
      _isMigrating = false;
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

  void _openPlannerChat(BuildContext context, {required String mode}) async {
    // Ne pas naviguer si les données ne sont pas encore chargées
    if (_weekData == null) return;

    // Si l'utilisateur n'est pas premium et que le planner est locked, afficher le paywall
    final isPremium = SubscriptionService.instance.isPremium;
    if (!isPremium && _isPlannerLocked) {
      await PaywallService.instance.showPaywall(
        context: context,
        paywallContext: PaywallContext.planner,
      );
      // Recharger le statut des trials (l'utilisateur a peut-être upgrade)
      await _loadTrialStatus();
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlannerChatScreen(
          initialMode: mode,
          weekData: _weekData!,
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
      // Activer l'animation de progression au retour du chat (après génération)
      setState(() {
        _shouldAnimateProgress = true;
      });
      // Rafraîchir les données au retour
      _loadData();
      // Recharger le statut des trials (peut avoir changé après génération)
      _loadTrialStatus();
      // Désactiver l'animation après un délai
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _shouldAnimateProgress = false;
          });
        }
      });
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
        child: CustomCard(
          padding: EdgeInsets.zero,
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
          const Icon(
            LucideIcons.calendar,
            size: 20,
            color: Color(0xFF0B132B),
          ),
          const SizedBox(width: 12),
          Text(
            'weekly_planner_title'.tr(langCode),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays(BuildContext context, String langCode) {
    // Afficher le loader uniquement au premier chargement (pas de données encore)
    if (_isLoading || _weekData == null) {
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

    final weekData = _weekData!;
    final dayNames = _getDayNames(langCode);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dayWidth = constraints.maxWidth / 7;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (index) {
              final date = weekData.weekStart.add(Duration(days: index));
              final dayPlan = weekData.getDayPlan(date);
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final isToday = normalizedDate == today;

              return SizedBox(
                width: dayWidth,
                child: DayColumnWidget(
                  date: date,
                  dayName: dayNames[index],
                  dayPlan: dayPlan,
                  dailyCalorieTarget: _dailyCalorieTarget,
                  animateProgress: _shouldAnimateProgress && isToday,
                  onDataRefresh: _loadData,
                  onActivityTap: (activity) {
                    if (activity.activityType == PlannedActivityType.cardio) {
                      _showCardioRecap(context, activity);
                    }
                  },
                  onWorkoutTap: (workout) => _showWorkoutRecap(context, workout),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildAIZone(BuildContext context, String langCode) {
    final isPremium = SubscriptionService.instance.isPremium;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: isPremium ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          // Phrase d'accroche + Badge (sur la même ligne pour non-premium, centré pour premium)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: isPremium
              ? Text(
                  'planner_plan_your_week'.tr(langCode),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                )
              : Row(
                  children: [
                    // Texte aligné à gauche
                    Text(
                      'planner_plan_your_week'.tr(langCode),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge avec nombre d'essais (uniquement pour non-premium)
                    if (!_isCheckingTrials)
                      _PlannerTrialBadge(
                        langCode: langCode,
                        remainingUsages: _remainingUsages,
                        isLocked: _isPlannerLocked,
                      ),
                  ],
                ),
          ),
          // Boutons
          Row(
            children: [
              // Bouton Repas
              Expanded(
                child: _buildCompactAIButton(
                  context,
                  icon: LucideIcons.utensils,
                  label: 'planner_meals_button'.tr(langCode),
                  mode: 'meals',
                ),
              ),
              const SizedBox(width: 12),
              // Bouton Séances
              Expanded(
                child: _buildCompactAIButton(
                  context,
                  icon: LucideIcons.dumbbell,
                  label: 'planner_sessions_button'.tr(langCode),
                  mode: 'workouts',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAIButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String mode,
  }) {
    return InkWell(
      onTap: () => _openPlannerChat(context, mode: mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
