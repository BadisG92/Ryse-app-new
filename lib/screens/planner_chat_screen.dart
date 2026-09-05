import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../components/ui/motion.dart';
import '../components/weekly_planner/proposal_card.dart';
import '../components/weekly_planner/week_strip.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/weekly_planner_models.dart';
import '../services/weekly_planner_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/planner_ai_service.dart';
import '../services/paywall_service.dart';
import '../services/unified_subscription_service.dart';
import '../components/weekly_planner/workout_recap_bottom_sheet.dart';
import '../components/weekly_planner/cardio_recap_bottom_sheet.dart';

/// Screen full-page pour planifier avec Ryze
/// Contient le calendrier fixe en haut et le chat en dessous
class PlannerChatScreen extends StatefulWidget {
  final String initialMode; // 'meals' ou 'workouts'
  final WeeklyPlannerData weekData;

  // Demo mode (onboarding)
  final bool demoMode;
  final int? maxMessages;
  final void Function(List<PendingMeal> meals, List<PendingWorkout> workouts, List<PendingSession> sessions)? onDemoDataCollected;

  const PlannerChatScreen({
    super.key,
    required this.initialMode,
    required this.weekData,
    this.demoMode = false,
    this.maxMessages,
    this.onDemoDataCollected,
  });

  @override
  State<PlannerChatScreen> createState() => _PlannerChatScreenState();
}

class _PlannerChatScreenState extends State<PlannerChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _calendarScrollController = ScrollController();

  // The week above the chat: folded by default, opened while items land on it.
  bool _weekExpanded = false;
  bool _weekAutoOpened = false;
  Timer? _weekFoldTimer;
  final Map<String, GlobalKey> _slotKeys = {};
  final GlobalKey _proposalCardKey = GlobalKey();
  final Set<String> _incomingSlots = {};
  final List<_ChatMessage> _messages = [];
  bool _isProcessing = false;

  // Week data (peut être mis à jour)
  late WeeklyPlannerData _weekData;

  // Free tier tracking
  int _remainingFreeUses = 3;
  bool _isPremium = false;
  bool _isTestMode = false;
  bool _showPaywallButton = false;

  // Preview mode
  List<PendingWorkout>? _pendingWorkouts;
  List<PendingMeal>? _pendingMeals;
  bool _isConfirming = false;

  // Meals preview pagination (one day per page)
  PageController? _mealsPageController;
  int _currentMealsDayIndex = 0;
  List<DateTime> _mealsDays = [];

  // NOUVEAU: Sessions preview pagination (one session per page)
  List<PendingSession>? _pendingSessions;
  PageController? _sessionsPageController;
  int _currentSessionIndex = 0;
  SessionPlanningState? _planningState; // Pour le flow de questions

  // Confirmation mode (pour actions destructrices)
  Map<String, dynamic>? _pendingConfirmation;

  // Undo tracking
  int _undoableMessageIndex = -1;

  // Demo mode tracking
  int _userMessageCount = 0;
  final Set<_ChatMessage> _shownMessages = {}; // bulles déjà animées (pas de rejeu au scroll)
  final ValueNotifier<int> _proposalVersion = ValueNotifier<int>(0); // bumped on every setState: the detail sheets rebuild with the screen
  final List<PendingMeal> _demoConfirmedMeals = [];
  final List<PendingWorkout> _demoConfirmedWorkouts = [];
  final List<PendingSession> _demoConfirmedSessions = [];
  bool _demoMealsGuided = false;
  bool _demoSportGuided = false;

  @override
  void initState() {
    super.initState();
    _weekData = widget.weekData;
    if (widget.demoMode) {
      // In demo mode, bypass premium checks
      _isPremium = true;
      PlannerAIService.setDemoMode(true);
    } else {
      _loadFreeUsageStatus();
    }
    PlannerAIService.clearHistory();
    _addBotMessage(_getWelcomeMessage());

    // Scroll vers aujourd'hui après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCalendarToToday();
    });
  }

  Future<void> _loadFreeUsageStatus() async {
    _isPremium = PlannerAIService.isPremium;
    _isTestMode = UnifiedSubscriptionService().testMode;
    if (!_isPremium && !_isTestMode) {
      final remaining = await PlannerAIService.getRemainingFreeUses();
      if (mounted) {
        setState(() {
          _remainingFreeUses = remaining;
        });
      }
    }
  }

  Future<void> _refreshWeekData() async {
    try {
      // Le cache est automatiquement invalidé après chaque action (suppression, etc.)
      final data = await WeeklyPlannerService.getWeekData();
      if (mounted) {
        setState(() {
          _weekData = data;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing week data: $e');
    }
  }

  void _addMealsToWeekDataLocally(List<PendingMeal> meals) {
    final newActivities = List<PlannedActivity>.from(_weekData.activities);
    for (final meal in meals) {
      newActivities.add(PlannedActivity(
        id: 'demo_meal_${DateTime.now().millisecondsSinceEpoch}_${newActivities.length}',
        userId: '',
        plannedDate: meal.plannedDate,
        activityType: meal.mealType,
        activityData: meal.toActivityData(),
        status: PlannedStatus.planned,
        isAiGenerated: true,
        createdAt: DateTime.now(),
      ));
    }
    setState(() {
      _weekData = WeeklyPlannerData.fromLists(
        weekStart: _weekData.weekStart,
        activities: newActivities,
        workouts: _weekData.workouts.toList(),
      );
    });
  }

  void _addWorkoutsToWeekDataLocally(List<PendingWorkout> workouts) {
    final newWorkouts = List<PlannedWorkout>.from(_weekData.workouts);
    for (final w in workouts) {
      newWorkouts.add(w.toPlannedWorkout());
    }
    setState(() {
      _weekData = WeeklyPlannerData.fromLists(
        weekStart: _weekData.weekStart,
        activities: _weekData.activities.toList(),
        workouts: newWorkouts,
      );
    });
  }

  void _addSessionToWeekDataLocally(PendingSession session) {
    if (session.isWorkout && session.workout != null) {
      _addWorkoutsToWeekDataLocally([session.workout!]);
    } else if (session.isCardio && session.cardio != null) {
      final newActivities = List<PlannedActivity>.from(_weekData.activities);
      newActivities.add(session.cardio!.toPlannedActivity());
      setState(() {
        _weekData = WeeklyPlannerData.fromLists(
          weekStart: _weekData.weekStart,
          activities: newActivities,
          workouts: _weekData.workouts.toList(),
        );
      });
    }
  }

  GlobalKey _slotKey(int day, WeekSlot slot) => _slotKeys.putIfAbsent('$day-${slot.name}', () => GlobalKey());

  void _toggleWeek() {
    _weekFoldTimer?.cancel();
    _weekAutoOpened = false;
    setState(() => _weekExpanded = !_weekExpanded);
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _proposalVersion.value++;
  }

  @override
  void dispose() {
    _weekFoldTimer?.cancel();
    _proposalVersion.dispose();
    if (widget.demoMode) {
      PlannerAIService.setDemoMode(false);
    }
    _textController.dispose();
    _focusNode.dispose();
    _chatScrollController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _scrollCalendarToToday() {
    if (!_calendarScrollController.hasClients) return;

    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    const dayColumnWidth = 52.0;
    final offset = (todayIndex * dayColumnWidth) - 40;

    if (offset > 0 && offset < _calendarScrollController.position.maxScrollExtent) {
      _calendarScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getWelcomeMessage() {
    final locService = LocalizationService.instance;
    final langCode = locService.currentLanguageCode;

    // Demo mode uses specific welcome messages
    if (widget.demoMode) {
      if (widget.initialMode == 'meals') {
        return 'onboarding_demo_meals_welcome'.tr(langCode);
      }
      return 'onboarding_demo_sport_welcome'.tr(langCode);
    }

    if (widget.initialMode == 'meals') {
      final messages = {
        'fr': "Salut ! Je suis Ryze, ton coach nutrition. 🥗\n\nDis-moi quels repas tu veux planifier cette semaine.",
        'en': "Hi! I'm Ryze, your nutrition coach. 🥗\n\nTell me which meals you want to plan this week.",
        'de': "Hallo! Ich bin Ryze, dein Ernährungscoach. 🥗\n\nSag mir, welche Mahlzeiten du diese Woche planen möchtest.",
      };
      return messages[langCode] ?? messages['en']!;
    }

    final messages = {
      'fr': "Salut ! Je suis Ryze, ton coach fitness. 💪\n\nDis-moi quelles séances tu veux planifier cette semaine.",
      'en': "Hi! I'm Ryze, your fitness coach. 💪\n\nTell me which workouts you want to plan this week.",
      'de': "Hallo! Ich bin Ryze, dein Fitnesscoach. 💪\n\nSag mir, welche Trainings du diese Woche planen möchtest.",
    };
    return messages[langCode] ?? messages['en']!;
  }

  void _addBotMessage(String text) {
    setState(() {
      _undoableMessageIndex = -1;
      // Parser les bulles multiples (séparateur "|||")
      final parts = text.split('|||').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      for (final part in parts) {
        _messages.add(_ChatMessage(text: part, isUser: false));
      }
    });
    _scrollChatToBottom();
  }

  void _addUndoableBotMessage(String text) {
    setState(() {
      // Parser les bulles multiples (séparateur "|||")
      final parts = text.split('|||').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      // Marquer seulement la dernière bulle comme undoable
      for (int i = 0; i < parts.length; i++) {
        final isLast = i == parts.length - 1;
        if (isLast) {
          _undoableMessageIndex = _messages.length;
          _messages.add(_ChatMessage(text: parts[i], isUser: false, isUndoable: true));
        } else {
          _messages.add(_ChatMessage(text: parts[i], isUser: false));
        }
      }
    });
    _scrollChatToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _undoableMessageIndex = -1;
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _scrollChatToBottom();
  }

  void _addConfirmationMessage(String description) {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final confirmText = 'planner_confirm'.tr(langCode);
    final cancelText = 'planner_cancel'.tr(langCode);

    setState(() {
      _pendingConfirmation = {'description': description};
      _messages.add(_ChatMessage(
        text: description,
        isUser: false,
        actions: [
          _ChatAction(
            label: cancelText,
            onTap: _cancelConfirmation,
            isDestructive: false,
          ),
          _ChatAction(
            label: confirmText,
            onTap: _executeConfirmation,
            isDestructive: true,
          ),
        ],
      ));
    });
    _scrollChatToBottom();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isProcessing) return;

    // Demo mode: check message limit
    if (widget.demoMode && widget.maxMessages != null) {
      if (_userMessageCount >= widget.maxMessages!) return;
      _userMessageCount++;
    }

    _addUserMessage(text);
    _textController.clear();
    _focusNode.unfocus();

    if (_pendingConfirmation != null) {
      if (_messages.isNotEmpty && _messages.last.actions != null) {
        setState(() {
          _messages.removeLast();
        });
      }
      _pendingConfirmation = null;
    }

    setState(() {
      _isProcessing = true;
      _pendingWorkouts = null;
    });
    _scrollChatToBottom();

    try {
      PlannerActionResult result;

      // NOUVEAU: Si on a un état de planning en cours, c'est une réponse à une question
      if (_planningState != null) {
        final langCode = LocalizationService.instance.currentLanguageCode;
        result = await PlannerAIService.continueSessionPlanning(
          _planningState!,
          text,
          langCode,
        );
      } else {
        result = await PlannerAIService.processRequestWithTools(
          text,
          mode: widget.initialMode,
        );
      }

      // NOUVEAU: Gérer le type de résultat avec le nouvel enum
      if (result.isQuestion) {
        // Question à poser: afficher et stocker l'état
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);
        setState(() {
          _planningState = result.planningState;
        });
      } else if (result.isSessionPreview && result.pendingSessions != null) {
        // NOUVEAU: Preview de sessions paginé
        debugPrint('✅ Got ${result.pendingSessions!.length} pending sessions for preview');
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);
        setState(() {
          _pendingSessions = result.pendingSessions;
          _currentSessionIndex = 0;
          _sessionsPageController?.dispose();
          _sessionsPageController = PageController(initialPage: 0);
          _planningState = null; // Fin du flow de questions
        });
      } else if (result.isPaywallRequired) {
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);
        setState(() => _showPaywallButton = true);
      } else if (result.requiresConfirmation && result.pendingWorkouts != null) {
        debugPrint('✅ Got ${result.pendingWorkouts!.length} pending workouts for preview');
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);
        setState(() {
          _pendingWorkouts = result.pendingWorkouts;
        });
      } else if (result.requiresConfirmation && result.pendingMeals != null) {
        debugPrint('✅ Got ${result.pendingMeals!.length} pending meals for preview');
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);

        // Extraire les jours uniques et trier
        final daysSet = <DateTime>{};
        for (final meal in result.pendingMeals!) {
          daysSet.add(DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day));
        }
        final sortedDays = daysSet.toList()..sort();

        setState(() {
          _pendingMeals = result.pendingMeals;
          _mealsDays = sortedDays;
          _currentMealsDayIndex = 0;
          _mealsPageController?.dispose();
          _mealsPageController = PageController(initialPage: 0);
        });
      } else if (result.requiresConfirmation && result.pendingWorkouts == null && result.pendingMeals == null) {
        _addConfirmationMessage(result.message);
      } else if (result.success) {
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);
        await _refreshWeekData();
        await _loadFreeUsageStatus();
      } else {
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);
      }
    } catch (e) {
      debugPrint('Error processing AI request: $e');
      // a failed call must not eat one of the demo messages
      if (widget.demoMode && widget.maxMessages != null && _userMessageCount > 0) _userMessageCount--;
      _addBotMessage(_getErrorMessage());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _confirmWorkouts() async {
    if (_pendingWorkouts == null || _isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      if (widget.demoMode) {
        // Demo mode: store in memory, don't save to DB
        _demoConfirmedWorkouts.addAll(_pendingWorkouts!);
        _addWorkoutsToWeekDataLocally(_pendingWorkouts!);
        final langCode = LocalizationService.instance.currentLanguageCode;
        final successMsg = 'planner_all_sessions_planned'.tr(langCode);
        _addBotMessage(successMsg);
        PlannerAIService.addToHistory('assistant', successMsg);
        PlannerAIService.clearHistory();

        setState(() {
          _pendingWorkouts = null;
        });

        // Send demo guidance message
        _sendDemoSportGuidance();
        return;
      }

      unawaited(_landInWeek([for (final w in _pendingWorkouts!) (date: w.plannedDate, slot: WeekSlot.sport)]));
      final result = await PlannerAIService.confirmWorkouts(_pendingWorkouts!);

      _addBotMessage(result.message);
      PlannerAIService.addToHistory('assistant', result.message);

      if (result.success) {
        PlannerAIService.clearHistory();
        await _refreshWeekData();
        await _loadFreeUsageStatus();
      }

      setState(() {
        _pendingWorkouts = null;
      });
    } catch (e) {
      debugPrint('Error confirming workouts: $e');
      _addBotMessage(_getErrorMessage());
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _confirmMeals() async {
    if (_pendingMeals == null || _isConfirming || _mealsDays.isEmpty) return;

    setState(() => _isConfirming = true);

    try {
      // Récupérer uniquement les repas du jour actuel
      final currentDay = _mealsDays[_currentMealsDayIndex];
      final mealsForCurrentDay = _pendingMeals!.where((meal) {
        final mealDate = DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day);
        return mealDate.isAtSameMomentAs(currentDay);
      }).toList();

      unawaited(_landInWeek([
        for (final m in mealsForCurrentDay)
          if (_slotOf(m.mealType) != null) (date: m.plannedDate, slot: _slotOf(m.mealType)!),
      ]));

      if (widget.demoMode) {
        // Demo mode: store in memory, don't save to DB
        _demoConfirmedMeals.addAll(mealsForCurrentDay);
        _addMealsToWeekDataLocally(mealsForCurrentDay);

        final remainingMeals = _pendingMeals!.where((meal) {
          final mealDate = DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day);
          return !mealDate.isAtSameMomentAs(currentDay);
        }).toList();

        if (remainingMeals.isEmpty) {
          final langCode = LocalizationService.instance.currentLanguageCode;
          final successMsg = 'planner_all_meals_planned'.tr(langCode);
          _addBotMessage(successMsg);
          PlannerAIService.addToHistory('assistant', successMsg);
          PlannerAIService.clearHistory();
          setState(() {
            _pendingMeals = null;
            _mealsDays = [];
            _currentMealsDayIndex = 0;
            _mealsPageController?.dispose();
            _mealsPageController = null;
          });

          // Send demo guidance message
          _sendDemoMealsGuidance();
        } else {
          // keep every other day (validating Wednesday must not discard Monday and Tuesday)
          final remainingDays = _mealsDays.where((d) => !d.isAtSameMomentAs(currentDay)).toList();
          setState(() {
            _pendingMeals = remainingMeals;
            _mealsDays = remainingDays;
            _currentMealsDayIndex = _currentMealsDayIndex.clamp(0, remainingDays.length - 1);
            _mealsPageController?.dispose();
            _mealsPageController = PageController(initialPage: 0);
          });
        }
        return;
      }

      final result = await PlannerAIService.confirmMeals(mealsForCurrentDay);

      if (result.success) {
        await _refreshWeekData();
        await _loadFreeUsageStatus();

        // Retirer les repas confirmés de la liste
        final remainingMeals = _pendingMeals!.where((meal) {
          final mealDate = DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day);
          return !mealDate.isAtSameMomentAs(currentDay);
        }).toList();

        // Vérifier s'il reste des jours
        if (remainingMeals.isEmpty) {
          // Tous les jours ont été confirmés
          _addBotMessage(result.message);
          PlannerAIService.addToHistory('assistant', result.message);
          PlannerAIService.clearHistory();
          setState(() {
            _pendingMeals = null;
            _mealsDays = [];
            _currentMealsDayIndex = 0;
            _mealsPageController?.dispose();
            _mealsPageController = null;
          });
        } else {
          // Passer au jour suivant
          // keep every other day (validating Wednesday must not discard Monday and Tuesday)
          final remainingDays = _mealsDays.where((d) => !d.isAtSameMomentAs(currentDay)).toList();
          setState(() {
            _pendingMeals = remainingMeals;
            _mealsDays = remainingDays;
            _currentMealsDayIndex = _currentMealsDayIndex.clamp(0, remainingDays.length - 1);
            _mealsPageController?.dispose();
            _mealsPageController = PageController(initialPage: 0);
          });
        }
      } else {
        _addBotMessage(result.message);
      }
    } catch (e) {
      debugPrint('Error confirming meals: $e');
      _addBotMessage(_getErrorMessage());
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  void _cancelPreview() {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final messages = {
      'fr': "Pas de souci ! Dis-moi ce que tu voudrais modifier.",
      'en': "No problem! Tell me what you'd like to change.",
      'de': "Kein Problem! Sag mir, was du ändern möchtest.",
    };

    setState(() {
      _pendingWorkouts = null;
      _pendingMeals = null;
      _mealsDays = [];
      _currentMealsDayIndex = 0;
      _mealsPageController?.dispose();
      _mealsPageController = null;
    });

    _addBotMessage(messages[langCode] ?? messages['en']!);
  }

  void _cancelConfirmation() {
    PlannerAIService.cancelPendingAction();
    final langCode = LocalizationService.instance.currentLanguageCode;
    final cancelledText = {
      'fr': '❌ Action annulée',
      'en': '❌ Action cancelled',
      'de': '❌ Aktion abgebrochen',
    };

    setState(() {
      if (_messages.isNotEmpty && _messages.last.actions != null) {
        _messages.removeLast();
      }
      _pendingConfirmation = null;
    });
    _addBotMessage(cancelledText[langCode] ?? cancelledText['en']!);
  }

  Future<void> _executeConfirmation() async {
    if (_isConfirming || _pendingConfirmation == null) return;
    setState(() => _isConfirming = true);

    try {
      setState(() {
        if (_messages.isNotEmpty && _messages.last.actions != null) {
          _messages.removeLast();
        }
      });

      final result = await PlannerAIService.executePendingAction();

      if (result.canUndo && result.success) {
        _addUndoableBotMessage(result.message);
      } else {
        _addBotMessage(result.message);
      }
      PlannerAIService.addToHistory('assistant', result.message);

      if (result.success) {
        await _refreshWeekData();
      }

      if (result.hasMoreActions && result.requiresConfirmation && result.nextActionDescription != null) {
        _addConfirmationMessage(result.nextActionDescription!);
      } else if (result.hasMoreActions && result.nextActionDescription != null) {
        _addBotMessage(result.nextActionDescription!);
      } else {
        setState(() {
          _pendingConfirmation = null;
        });
      }
    } catch (e) {
      debugPrint('Error executing confirmation: $e');
      _addBotMessage(_getErrorMessage());
      setState(() {
        _pendingConfirmation = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _executeUndo(int messageIndex) async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    try {
      final result = await PlannerAIService.undoLastAction();

      setState(() {
        _undoableMessageIndex = -1;
      });

      _addBotMessage(result.message);
      PlannerAIService.addToHistory('assistant', result.message);

      if (result.success) {
        await _refreshWeekData();
      }
    } catch (e) {
      debugPrint('Error executing undo: $e');
      _addBotMessage(_getErrorMessage());
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  void _showPaywall() {
    PaywallService().showPaywall(
      context: context,
      paywallContext: PaywallContext.workoutGenerator,
    );
  }

  /// Demo mode: send guidance messages after meals are confirmed
  void _sendDemoMealsGuidance() {
    if (_demoMealsGuided) return;
    _demoMealsGuided = true;
    final langCode = LocalizationService.instance.currentLanguageCode;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _addBotMessage('onboarding_demo_meals_guide_click'.tr(langCode));
      }
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _addBotMessage('onboarding_demo_meals_guide_modify'.tr(langCode));
      }
    });
  }

  /// Demo mode: send guidance messages after sport sessions are confirmed
  void _sendDemoSportGuidance() {
    if (_demoSportGuided) return;
    _demoSportGuided = true;
    final langCode = LocalizationService.instance.currentLanguageCode;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _addBotMessage('onboarding_demo_sport_guide_click'.tr(langCode));
      }
    });
  }

  /// Demo mode: collect all data and call callback
  void _collectDemoData() {
    widget.onDemoDataCollected?.call(
      _demoConfirmedMeals,
      _demoConfirmedWorkouts,
      _demoConfirmedSessions,
    );
  }

  String _getErrorMessage() {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final messages = {
      'fr': "Oups, une erreur s'est produite. Réessaie !",
      'en': "Oops, an error occurred. Try again!",
      'de': "Hoppla, ein Fehler ist aufgetreten. Versuche es erneut!",
    };
    return messages[langCode] ?? messages['en']!;
  }

  void _showWorkoutRecap(PlannedWorkout workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutRecapBottomSheet(
        workout: workout,
        onWorkoutStarted: () {
          _refreshWeekData();
        },
        onWorkoutDeleted: () {
          _refreshWeekData();
        },
      ),
    );
  }

  void _showCardioRecap(PlannedActivity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CardioRecapBottomSheet(
        activity: activity,
        onCardioStarted: () {
          _refreshWeekData();
        },
        onCardioDeleted: () {
          _refreshWeekData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final langCode = locService.currentLanguageCode;

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(langCode),
      body: Column(
        children: [
          // Calendrier fixe en haut
          _buildCalendarSection(langCode),

          // Divider
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Chat (prend tout l'espace restant)
          Expanded(
            child: _buildChatSection(langCode),
          ),

          // Zone du bas selon l'état
          if (_showPaywallButton && !widget.demoMode)
            _buildPaywallButton(langCode)
          else if (_hasPendingPreview)
            const SizedBox(height: 8) // validation buttons live in the conversation, under the card
          else if (widget.demoMode && widget.maxMessages != null && _userMessageCount >= widget.maxMessages!)
            _buildDemoLimitReached(langCode)
          else
            _buildInputZone(langCode),

          // Demo mode: action buttons (switch to sport / finish)
          if (widget.demoMode && _pendingWorkouts == null && _pendingMeals == null && _pendingSessions == null)
            _buildDemoActionBar(langCode),
        ],
      ),
    );

    if (widget.demoMode) {
      return scaffold;
    }

    return Hero(
      tag: 'weekly_planner_hero',
      flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox.expand(),
        );
      },
      child: scaffold,
    );
  }

  PreferredSizeWidget _buildAppBar(String langCode) {
    final title = widget.demoMode
        ? (widget.initialMode == 'meals'
            ? 'onboarding_demo_meals_title'.tr(langCode)
            : 'onboarding_demo_sport_title'.tr(langCode))
        : (widget.initialMode == 'meals'
            ? 'plan_my_meals'.tr(langCode)
            : 'plan_my_workouts'.tr(langCode));

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: widget.demoMode
          ? null
          : IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0B132B)),
            ),
      automaticallyImplyLeading: !widget.demoMode,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/coach_ryze_contract.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
              ),
              SlideSwapText(
                text: _isPremium
                    ? (widget.demoMode && widget.maxMessages != null
                        ? '${widget.maxMessages! - _userMessageCount} ${'onboarding_demo_messages_left'.tr(langCode)}'
                        : 'planner_ai_subtitle'.tr(langCode))
                    : _isTestMode
                        ? 'Mode test'
                        : _getRemainingUsesText(langCode),
                style: TextStyle(
                  fontSize: 12,
                  color: _isPremium || _isTestMode || _remainingFreeUses > 0
                      ? const Color(0xFF64748B)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  String _getRemainingUsesText(String langCode) {
    if (_remainingFreeUses <= 0) {
      switch (langCode) {
        case 'fr':
          return 'Limite atteinte';
        case 'de':
          return 'Limit erreicht';
        default:
          return 'Limit reached';
      }
    }

    switch (langCode) {
      case 'fr':
        return '$_remainingFreeUses gratuite${_remainingFreeUses > 1 ? 's' : ''} restante${_remainingFreeUses > 1 ? 's' : ''}';
      case 'de':
        return '$_remainingFreeUses kostenlos übrig';
      default:
        return '$_remainingFreeUses free left';
    }
  }

  WeekSlot? _slotOf(PlannedActivityType type) {
    switch (type) {
      case PlannedActivityType.breakfast:
        return WeekSlot.breakfast;
      case PlannedActivityType.lunch:
        return WeekSlot.lunch;
      case PlannedActivityType.snack:
        return WeekSlot.snack;
      case PlannedActivityType.dinner:
        return WeekSlot.dinner;
      case PlannedActivityType.cardio:
        return WeekSlot.sport;
    }
  }

  static String _shortLabel(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final first = name.trim().split(RegExp(r'[ ,]')).first;
    return first.length > 9 ? first.substring(0, 9) : first;
  }

  /// What each day of the shown week holds, in the strip's own vocabulary.
  List<DaySlots> _weekSlots() {
    return List<DaySlots>.generate(7, (i) {
      final date = _weekData.weekStart.add(Duration(days: i));
      final plan = _weekData.getDayPlan(date);
      final states = <WeekSlot, SlotState>{};
      final labels = <WeekSlot, String>{};
      void put(WeekSlot slot, bool done, String label) {
        final current = states[slot];
        if (current == SlotState.done) return;
        states[slot] = done ? SlotState.done : SlotState.planned;
        if (label.isNotEmpty) labels[slot] = label;
      }

      if (plan != null) {
        for (final meal in plan.meals) {
          final slot = _slotOf(meal.activityType);
          if (slot != null) put(slot, meal.status == PlannedStatus.completed, _shortLabel(meal.mealData?.dishName));
        }
        for (final cardio in plan.cardios) {
          put(WeekSlot.sport, cardio.status == PlannedStatus.completed, _shortLabel(cardio.cardioData?.activityName));
        }
        for (final workout in plan.workouts) {
          put(WeekSlot.sport, workout.status == PlannedStatus.completed, _shortLabel(workout.workoutName));
        }
      }
      for (final slot in WeekSlot.values) {
        if (states[slot] == null && _incomingSlots.contains('$i-${slot.name}')) states[slot] = SlotState.incoming;
      }
      return DaySlots(states: states, labels: labels);
    });
  }

  Widget _buildCalendarSection(String langCode) {
    final letters = _getDayNames(langCode);
    return WeekStrip(
      days: List<DateTime>.generate(7, (i) => _weekData.weekStart.add(Duration(days: i))),
      dayLetters: letters,
      slots: _weekSlots(),
      expanded: _weekExpanded,
      onToggle: _toggleWeek,
      slotKey: _slotKey,
      onSlotTap: _openSlot,
    );
  }

  void _openSlot(int day, WeekSlot slot) {
    if (slot != WeekSlot.sport) return;
    final plan = _weekData.getDayPlan(_weekData.weekStart.add(Duration(days: day)));
    if (plan == null) return;
    if (plan.workouts.isNotEmpty) {
      _showWorkoutRecap(plan.workouts.first);
    } else if (plan.cardios.isNotEmpty) {
      _showCardioRecap(plan.cardios.first);
    }
  }

  // ---------------------------------------------------------------- landing

  int _dayIndexOf(DateTime date) {
    final start = DateTime(_weekData.weekStart.year, _weekData.weekStart.month, _weekData.weekStart.day);
    return DateTime(date.year, date.month, date.day).difference(start).inDays;
  }

  /// Opens the week, flies one mark per validated item to its day, then folds
  /// it back. This is the moment that shows the app placing things in the week.
  Future<void> _landInWeek(List<({DateTime date, WeekSlot slot})> items) async {
    if (items.isEmpty || !mounted) return;
    final from = _rectOf(_proposalCardKey); // resolved now: the card is about to go
    final targets = <({int day, WeekSlot slot})>[];
    for (final item in items) {
      final day = _dayIndexOf(item.date);
      if (day < 0 || day > 6) continue;
      if (targets.any((t) => t.day == day && t.slot == item.slot)) continue;
      targets.add((day: day, slot: item.slot));
    }
    if (targets.isEmpty) return;

    _weekFoldTimer?.cancel();
    if (!_weekExpanded) {
      _weekAutoOpened = true;
      setState(() => _weekExpanded = true);
      await Future<void>.delayed(const Duration(milliseconds: 440));
      if (!mounted) return;
    }
    setState(() {
      for (final t in targets) {
        _incomingSlots.add('${t.day}-${t.slot.name}');
      }
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final overlay = Overlay.of(context);
    for (var i = 0; i < targets.length; i++) {
      final t = targets[i];
      Future<void>.delayed(Duration(milliseconds: i * 70), () {
        if (!mounted) return;
        _flyMark(overlay, from, _slotKeys['${t.day}-${t.slot.name}'], t.slot);
      });
    }
    await Future<void>.delayed(Duration(milliseconds: 640 + targets.length * 70));
    if (!mounted) return;
    setState(() => _incomingSlots.clear());
    if (_weekAutoOpened) {
      _weekFoldTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && _weekAutoOpened) setState(() => _weekExpanded = false);
        _weekAutoOpened = false;
      });
    }
  }

  Rect? _rectOf(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _flyMark(OverlayState overlay, Rect? from, GlobalKey? to, WeekSlot slot) {
    final end = _rectOf(to);
    if (end == null) return;
    final source = from ?? Rect.fromCenter(center: Offset(end.center.dx, end.center.dy + 240), width: 34, height: 34);
    final start = Rect.fromCenter(center: Offset(source.center.dx, source.top + 40), width: 34, height: 34);
    final entry = OverlayEntry(
      builder: (context) => _FlyingMark(start: start, end: end, slot: slot),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 700), entry.remove);
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

  bool get _hasPendingPreview =>
      (_pendingWorkouts != null && _pendingWorkouts!.isNotEmpty) ||
      (_pendingMeals != null && _pendingMeals!.isNotEmpty) ||
      (_pendingSessions != null && _pendingSessions!.isNotEmpty);

  int _lastChatItemCount = 0;

  /// The conversation reads top-down, like the prototype: messages, then the
  /// typing indicator, then the quick suggestions or the card to validate.
  Widget _buildChatSection(String langCode) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible && _weekExpanded) {
      // typing wins: the conversation keeps its lines
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _weekExpanded && MediaQuery.of(context).viewInsets.bottom > 0) {
          _weekFoldTimer?.cancel();
          _weekAutoOpened = false;
          setState(() => _weekExpanded = false);
        }
      });
    }
    final showSuggestions = _messages.length <= 1 && !keyboardVisible && !_hasPendingPreview && !_showPaywallButton && !_isProcessing;
    final itemCount = _messages.length + (_isProcessing ? 1 : 0) + (showSuggestions ? 1 : 0) + (_hasPendingPreview ? 1 : 0);
    if (itemCount != _lastChatItemCount) {
      _lastChatItemCount = itemCount;
      _scrollChatToBottom();
    }
    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          return _buildMessageBubble(_messages[index], index);
        }
        var extra = index - _messages.length;
        if (_isProcessing) {
          if (extra == 0) return _buildTypingIndicator(langCode);
          extra--;
        }
        if (showSuggestions) {
          if (extra == 0) return _buildQuickSuggestions(langCode);
          extra--;
        }
        return _buildInlinePreview(langCode);
      },
    );
  }

  /// Pending proposal (meals, workouts or sessions) with its buttons, as a card
  /// in the conversation, indented under the coach avatar.
  Widget _buildInlinePreview(String langCode) {
    Widget? card;
    Widget? buttons;
    var key = 'none';
    if (_pendingWorkouts != null && _pendingWorkouts!.isNotEmpty) {
      card = _buildWorkoutPreview(langCode);
      buttons = _buildPreviewButtons(langCode);
      key = 'workouts';
    } else if (_pendingMeals != null && _pendingMeals!.isNotEmpty) {
      card = _buildMealsPreview(langCode);
      buttons = _buildMealsPreviewButtons(langCode);
      key = 'meals';
    } else if (_pendingSessions != null && _pendingSessions!.isNotEmpty) {
      card = _buildSessionsPreview(langCode);
      buttons = _buildSessionsPreviewButtons(langCode);
      key = 'sessions';
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim), child: child),
        ),
        child: card == null
            ? const SizedBox.shrink(key: ValueKey('preview-none'))
            : KeyedSubtree(
                key: ValueKey('preview-$key'),
                child: Padding(
                  key: _proposalCardKey,
                  padding: const EdgeInsets.only(left: 24),
                  child: ProposalCard(body: card, footer: buttons!),
                ),
              ),
      ),
    );
  }

  TextSpan _parseMarkdownBold(String text, Color color) {
    final regex = RegExp(r'\*\*(.+?)\*\*');
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return TextSpan(
      style: TextStyle(fontSize: 14, color: color, height: 1.4),
      children: spans,
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, int index) {
    final bool canUndo = message.isUndoable && index == _undoableMessageIndex;
    final bool fresh = _shownMessages.add(message);

    return PopIn(
      key: ObjectKey(message),
      animate: fresh,
      dy: 12,
      duration: const Duration(milliseconds: 420),
      child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                widget.initialMode == 'meals'
                    ? 'assets/images/coach_ryze_nutrition_avatar.png'
                    : 'assets/images/coach_ryze_workout_avatar.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyMessage(message.text),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? const Color(0xFF0B132B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight: message.isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                    bottomLeft: message.isUser
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: _parseMarkdownBold(
                        message.text,
                        message.isUser ? Colors.white : const Color(0xFF0B132B),
                      ),
                    ),
                    if (message.actions != null && message.actions!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: message.actions!.map((action) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: action.onTap,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: action.isDestructive
                                      ? const Color(0xFFEF4444)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: action.isDestructive
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  action.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: action.isDestructive
                                        ? Colors.white
                                        : const Color(0xFF0B132B),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (canUndo) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _executeUndo(index),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  LucideIcons.undo2,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
      ),
    );
  }

  /// Copy message on long press (like iMessage/WhatsApp)
  void _copyMessage(String text) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: text));

    final locService = context.read<LocalizationService>();
    final lang = locService.currentLanguageCode;
    final copiedText = lang == 'fr' ? 'Copié' : lang == 'de' ? 'Kopiert' : 'Copied';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(copiedText),
        backgroundColor: const Color(0xFF0B132B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        margin: const EdgeInsets.only(bottom: 50, left: 50, right: 50),
      ),
    );
  }

  Widget _buildTypingIndicator(String langCode) {
    final loadingText = widget.initialMode == 'meals'
        ? 'planner_ai_preparing_meal'.tr(langCode)
        : 'planner_ai_generating_workouts'.tr(langCode);

    return PopIn(
      key: const ValueKey('planner-typing'),
      dy: 10,
      duration: const Duration(milliseconds: 380),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                widget.initialMode == 'meals' ? 'assets/images/coach_ryze_nutrition_avatar.png' : 'assets/images/coach_ryze_workout_avatar.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.symmetric(vertical: 3), child: TypingDots(color: Color(0xFF0B132B))),
                    const SizedBox(height: 6),
                    Text(
                      loadingText,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions(String langCode) {
    final suggestions = _getQuickSuggestions(langCode);

    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.indexed.map((entry) {
            final suggestion = entry.$2;
            return PopIn(
              key: ValueKey('sugg-$suggestion'),
              delay: Duration(milliseconds: 120 + entry.$1 * 70),
              dy: 10,
              child: Padding(
              padding: EdgeInsets.zero,
              child: GestureDetector(
                onTap: () {
                  // Transformer le bouton en prompt optimisé pour l'IA (mode meals uniquement)
                  final prompt = widget.initialMode == 'meals'
                      ? _transformQuickSuggestionToPrompt(suggestion, langCode)
                      : suggestion;
                  _textController.text = prompt;
                  _handleSend();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              ),
            );
          }).toList(),
      ),
    );
  }

  List<String> _getQuickSuggestions(String langCode) {
    if (widget.initialMode == 'meals') {
      final suggestions = {
        'fr': ['🍽️ Prochain repas', '📅 Aujourd\'hui', '📆 La semaine'],
        'en': ['🍽️ Next meal', '📅 Today', '📆 The week'],
        'de': ['🍽️ Nächste Mahlzeit', '📅 Heute', '📆 Die Woche'],
      };
      return suggestions[langCode] ?? suggestions['en']!;
    }

    final suggestions = {
      'fr': ['3 séances muscu', 'Programme full body', 'Cardio + muscu'],
      'en': ['3 gym sessions', 'Full body program', 'Cardio + weights'],
      'de': ['3 Gym-Sessions', 'Ganzkörper-Programm', 'Cardio + Gewichte'],
    };
    return suggestions[langCode] ?? suggestions['en']!;
  }

  String _transformQuickSuggestionToPrompt(String suggestion, String langCode) {
    final now = DateTime.now();
    final hour = now.hour;

    // Déterminer le prochain repas selon l'heure
    String nextMealType;
    if (hour < 10) {
      nextMealType = 'meal_type_breakfast'.tr(langCode).toLowerCase();
    } else if (hour < 14) {
      nextMealType = 'meal_type_lunch'.tr(langCode).toLowerCase();
    } else if (hour < 21) {
      nextMealType = 'meal_type_dinner'.tr(langCode).toLowerCase();
    } else {
      nextMealType = 'meal_type_snack'.tr(langCode).toLowerCase();
    }

    // Utiliser les clés de suggestion traduites pour le matching
    final suggestionNextMeal = 'suggestion_next_meal'.tr(langCode);
    final suggestionToday = 'suggestion_today'.tr(langCode);
    final suggestionWeek = 'suggestion_week'.tr(langCode);

    final prompts = {
      suggestionNextMeal: langCode == 'fr'
          ? 'Propose-moi un $nextMealType équilibré pour aujourd\'hui'
          : langCode == 'de'
              ? 'Schlage mir ein ausgewogenes $nextMealType für heute vor'
              : 'Suggest a balanced $nextMealType for today',
      suggestionToday: langCode == 'fr'
          ? 'Planifie tous mes repas pour aujourd\'hui (petit-déjeuner, déjeuner, dîner)'
          : langCode == 'de'
              ? 'Plane alle meine Mahlzeiten für heute (Frühstück, Mittagessen, Abendessen)'
              : 'Plan all my meals for today (breakfast, lunch, dinner)',
      suggestionWeek: langCode == 'fr'
          ? 'Planifie tous mes repas pour toute la semaine (petit-déjeuner, déjeuner et dîner pour chaque jour)'
          : langCode == 'de'
              ? 'Plane alle meine Mahlzeiten für die ganze Woche (Frühstück, Mittagessen und Abendessen für jeden Tag)'
              : 'Plan all my meals for the entire week (breakfast, lunch and dinner for each day)',
    };

    return prompts[suggestion] ?? suggestion;
  }

  Widget _buildWorkoutPreview(String langCode) {
    if (_pendingWorkouts == null || _pendingWorkouts!.isEmpty) {
      return const SizedBox.shrink();
    }
    final title = 'planner_proposed_program'.tr(langCode);
    final sessionsWord = 'planner_sessions_word'.tr(langCode);
    final totalMin = _pendingWorkouts!.fold<int>(0, (sum, w) => sum + w.durationMinutes);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProposalHeader(icon: LucideIcons.dumbbell, title: title, subtitle: '${_pendingWorkouts!.length} $sessionsWord · $totalMin min'),
        for (final (i, w) in _pendingWorkouts!.indexed)
          PopIn(
            key: ValueKey('pw-${w.plannedDate.toIso8601String()}-${w.workoutType}'),
            delay: Duration(milliseconds: 80 + i * 50),
            dy: 10,
            duration: const Duration(milliseconds: 420),
            child: _buildWorkoutPreviewItem(w, langCode, last: i == _pendingWorkouts!.length - 1),
          ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildWorkoutPreviewItem(PendingWorkout workout, String langCode, {bool last = false}) {
    final exerciseCount = workout.exercises?.length ?? 0;
    final exercisesLabel = 'planner_exercises_count'.tr(langCode);
    return ProposalWorkoutRow(
      dayShort: _formatDayNameShort(workout.plannedDate, langCode),
      title: workout.workoutType,
      subtitle: '${workout.durationMinutes} min · $exerciseCount $exercisesLabel',
      onTap: () => _showWorkoutDetails(workout, langCode),
      last: last,
    );
  }

  void _showWorkoutDetails(PendingWorkout workout, String langCode) {
    final dayName = _formatDayName(workout.plannedDate, langCode);
    final personalizedText = 'planner_personalized_weights'.tr(langCode);
    final seriesLabel = 'planner_sets_label'.tr(langCode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.dumbbell,
                      size: 24,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.workoutType,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                        Text(
                          '$dayName • ${workout.durationMinutes} min',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            // Badge poids personnalisés
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      personalizedText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            // Exercices
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: workout.exercises?.length ?? 0,
                itemBuilder: (context, index) {
                  final exercise = workout.exercises![index];
                  final suggestedWeight = exercise.sets.isNotEmpty
                      ? exercise.sets.first.weight
                      : 0.0;
                  final weightText = suggestedWeight > 0
                      ? '${suggestedWeight.toStringAsFixed(suggestedWeight.truncateToDouble() == suggestedWeight ? 0 : 1)}kg'
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B132B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.exercise.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Text(
                                '${exercise.sets.length} $seriesLabel • ${exercise.suggestedRepsMin ?? 8}-${exercise.suggestedRepsMax ?? 12} reps${weightText.isNotEmpty ? ' • $weightText' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDayName(DateTime date, String langCode) {
    return 'day_${date.weekday}'.tr(langCode);
  }

  Widget _buildPreviewButtons(String langCode) {
    return ProposalActions(
      cancelLabel: 'planner_modify'.tr(langCode),
      confirmLabel: 'planner_confirm_program'.tr(langCode),
      onCancel: _cancelPreview,
      onConfirm: _confirmWorkouts,
      busy: _isConfirming,
    );
  }

  List<PendingMeal> _mealsForDay(DateTime day) {
    if (_pendingMeals == null) return const [];
    return _pendingMeals!.where((meal) {
      final d = DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day);
      return d.isAtSameMomentAs(day);
    }).toList();
  }

  String _mealTypeLabel(PendingMeal meal, String langCode) => _mealTypeKey(meal.mealType, short: true).tr(langCode);

  List<String> _macroLetters(String langCode) => ['proteins'.tr(langCode)[0], 'carbs'.tr(langCode)[0], 'fats'.tr(langCode)[0]];
  int _mealKcal(PendingMeal m) => ((m.proteins * 4) + (m.carbs * 4) + (m.fats * 9)).round();

  /// Compact card in the conversation. One day: the meals and their totals,
  /// ready to validate. Several days: a digest, "Tout valider" in one tap,
  /// and the detail sheet for day-by-day review.
  Widget _buildMealsPreview(String langCode) {
    if (_pendingMeals == null || _pendingMeals!.isEmpty || _mealsDays.isEmpty) {
      return const SizedBox.shrink();
    }
    final letters = _macroLetters(langCode);
    final several = _mealsDays.length > 1;
    final mealsWord = 'planner_meals_word'.tr(langCode);
    final daysWord = 'planner_days_count'.tr(langCode);
    final perDay = 'planner_kcal_per_day'.tr(langCode);
    final weekTitle = 'planner_proposed_week'.tr(langCode);
    final totalWord = 'planner_day_total'.tr(langCode);
    final moreDays = 'planner_see_all_days'.tr(langCode);

    if (!several) {
      final day = _mealsDays.first;
      final meals = _mealsForDay(day);
      final p = meals.fold<double>(0, (sum, m) => sum + m.proteins);
      final c = meals.fold<double>(0, (sum, m) => sum + m.carbs);
      final f = meals.fold<double>(0, (sum, m) => sum + m.fats);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProposalHeader(icon: LucideIcons.utensils, title: _formatDayName(day, langCode), subtitle: '${meals.length} $mealsWord'),
          for (final (i, meal) in meals.indexed)
            PopIn(
              key: ValueKey('pm-${meal.plannedDate.toIso8601String()}-${meal.mealType.name}-${meal.dishName}'),
              delay: Duration(milliseconds: 80 + i * 50),
              dy: 10,
              duration: const Duration(milliseconds: 420),
              child: _buildMealPreviewItem(meal, langCode, typeLabel: _mealTypeLabel(meal, langCode), letters: letters),
            ),
          ProposalDayTotals(
            calories: ((p * 4) + (c * 4) + (f * 9)).round(),
            proteins: p.toInt(),
            carbs: c.toInt(),
            fats: f.toInt(),
            totalLabel: totalWord,
            proteinLabel: 'proteins'.tr(langCode),
            carbsLabel: 'carbs'.tr(langCode),
            fatLabel: 'fats'.tr(langCode),
          ),
        ],
      );
    }

    final totalKcal = _pendingMeals!.fold<int>(0, (sum, m) => sum + _mealKcal(m));
    final avgKcal = (totalKcal / _mealsDays.length).round();
    final shownDays = _mealsDays.take(3).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProposalHeader(icon: LucideIcons.calendarDays, title: weekTitle, subtitle: '${_mealsDays.length} $daysWord · ${_pendingMeals!.length} $mealsWord · ~$avgKcal $perDay'),
        for (final (i, day) in shownDays.indexed)
          PopIn(
            key: ValueKey('pd-${day.toIso8601String()}'),
            delay: Duration(milliseconds: 80 + i * 50),
            dy: 10,
            duration: const Duration(milliseconds: 420),
            child: ProposalWorkoutRow(
              dayShort: _formatDayNameShort(day, langCode),
              title: _mealsForDay(day).map((m) => m.dishName).join(' · '),
              subtitle: '${_mealsForDay(day).length} $mealsWord · ${_mealsForDay(day).fold<int>(0, (sum, m) => sum + _mealKcal(m))} kcal',
              onTap: () => _showMealsDetailSheet(langCode, initialDay: i),
              last: i == shownDays.length - 1 && _mealsDays.length <= 3,
            ),
          ),
        if (_mealsDays.length > 3)
          InkWell(
            onTap: () => _showMealsDetailSheet(langCode, initialDay: 3),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  const SizedBox(width: 52),
                  Text(moreDays.replaceAll('{n}', '${_mealsDays.length}'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0B132B))),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF0B132B)),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 6),
      ],
    );
  }

  /// Bottom sheet: one page per day, meals and totals, validation of the shown
  /// day or of every day. Follows the screen state through [_proposalVersion].
  void _showMealsDetailSheet(String langCode, {int initialDay = 0}) {
    if (_pendingMeals == null || _mealsDays.isEmpty) return;
    final start = initialDay.clamp(0, _mealsDays.length - 1);
    setState(() => _currentMealsDayIndex = start);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MealsProposalSheet(
        version: _proposalVersion,
        langCode: langCode,
        initialDay: start,
        days: () => _mealsDays,
        currentIndex: () => _currentMealsDayIndex,
        mealsFor: _mealsForDay,
        dayName: (d) => _formatDayName(d, langCode),
        dayShort: (d) => _formatDayNameShort(d, langCode),
        typeLabel: (m) => _mealTypeLabel(m, langCode),
        letters: _macroLetters(langCode),
        isConfirming: () => _isConfirming,
        onDayChanged: (i) => setState(() => _currentMealsDayIndex = i),
        onConfirmDay: _confirmMeals,
        onConfirmAll: _confirmAllMeals,
        onCancel: _cancelPreview,
        onMealTap: (m) => _showMealDetailPage(m, langCode),
      ),
    );
  }

  Widget _buildMealPreviewItem(PendingMeal meal, String langCode, {required String typeLabel, required List<String> letters}) {
    return ProposalMealRow(
      icon: meal.mealType.icon,
      typeLabel: typeLabel,
      dishName: meal.dishName,
      calories: ((meal.proteins * 4) + (meal.carbs * 4) + (meal.fats * 9)).round(),
      proteins: meal.proteins.toInt(),
      carbs: meal.carbs.toInt(),
      fats: meal.fats.toInt(),
      macroLetters: letters,
      onTap: () => _showMealDetailPage(meal, langCode),
    );
  }

  void _showMealDetailPage(PendingMeal meal, String langCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MealDetailPage(meal: meal, langCode: langCode),
      ),
    );
  }

  Widget _buildMealsPreviewButtons(String langCode) {
    final several = _mealsDays.length > 1;
    if (!several) {
      return ProposalActions(
        cancelLabel: 'planner_cancel'.tr(langCode),
        confirmLabel: 'planner_validate'.tr(langCode),
        onCancel: _cancelPreview,
        onConfirm: _confirmMeals,
        busy: _isConfirming,
      );
    }
    final detail = 'planner_see_details'.tr(langCode);
    final cancelProposal = 'planner_dismiss_proposal'.tr(langCode);
    return ProposalActions(
      cancelLabel: detail,
      confirmLabel: '${'planner_confirm_all_days'.tr(langCode)} · ${_mealsDays.length} ${'planner_days_count'.tr(langCode)}',
      onCancel: () => _showMealsDetailSheet(langCode),
      onConfirm: _confirmAllMeals,
      busy: _isConfirming,
      linkLabel: cancelProposal,
      onLink: _cancelPreview,
    );
  }

  String _formatDayNameShort(DateTime date, String langCode) {
    return 'planner_day_short_${date.weekday}'.tr(langCode);
  }

  Future<void> _confirmAllMeals() async {
    if (_pendingMeals == null || _isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      unawaited(_landInWeek([
        for (final m in _pendingMeals!)
          if (_slotOf(m.mealType) != null) (date: m.plannedDate, slot: _slotOf(m.mealType)!),
      ]));
      final result = await PlannerAIService.confirmMeals(_pendingMeals!);

      _addBotMessage(result.message);
      PlannerAIService.addToHistory('assistant', result.message);

      if (result.success) {
        PlannerAIService.clearHistory();
        await _refreshWeekData();
        await _loadFreeUsageStatus();
      }

      setState(() {
        _pendingMeals = null;
        _mealsDays = [];
        _currentMealsDayIndex = 0;
        _mealsPageController?.dispose();
        _mealsPageController = null;
      });
    } catch (e) {
      debugPrint('Error confirming all meals: $e');
      _addBotMessage(_getErrorMessage());
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  // =====================================================
  // NOUVEAU: SESSIONS PREVIEW (WORKOUTS + CARDIO PAGINÉ)
  // =====================================================

  Widget _buildSessionsPreview(String langCode) {
    if (_pendingSessions == null || _pendingSessions!.isEmpty) {
      return const SizedBox.shrink();
    }
    final n = _pendingSessions!.length;
    final title = 'planner_proposed_sessions'.tr(langCode);
    final tapHint = 'planner_tap_session_detail'.tr(langCode);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProposalHeader(icon: LucideIcons.dumbbell, title: title, subtitle: n > 1 ? '$n · $tapHint' : tapHint),
        for (final (i, session) in _pendingSessions!.indexed)
          PopIn(
            key: ValueKey('ps-${session.plannedDate.toIso8601String()}-${session.displayTitle}'),
            delay: Duration(milliseconds: 80 + i * 50),
            dy: 10,
            duration: const Duration(milliseconds: 420),
            child: ProposalWorkoutRow(
              dayShort: _formatDayNameShort(session.plannedDate, langCode),
              title: session.displayTitle,
              subtitle: session.displaySubtitle,
              selected: n > 1 && i == _currentSessionIndex,
              last: i == n - 1,
              onTap: () {
                setState(() => _currentSessionIndex = i);
                _showSessionDetailSheet(langCode);
              },
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }

  /// Bottom sheet with the full recap of the current session and its validation.
  void _showSessionDetailSheet(String langCode) {
    if (_pendingSessions == null || _pendingSessions!.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SessionProposalSheet(
        version: _proposalVersion,
        langCode: langCode,
        sessions: () => _pendingSessions,
        currentIndex: () => _currentSessionIndex,
        dayName: (d) => _formatDayName(DateTime(d.year, d.month, d.day), langCode),
        cardBuilder: (session) => _buildSessionCard(session, langCode),
        isConfirming: () => _isConfirming,
        onConfirm: _confirmCurrentSession,
        onCancel: _cancelSessionsPreview,
        onIndexChanged: (i) => setState(() => _currentSessionIndex = i),
      ),
    );
  }

  Widget _buildSessionCard(PendingSession session, String langCode) {
    if (session.isWorkout) {
      return _buildWorkoutSessionCard(session, langCode);
    } else {
      return _buildCardioSessionCard(session, langCode);
    }
  }

  /// Preview d'un workout en utilisant le même widget que le recap
  Widget _buildWorkoutSessionCard(PendingSession session, String langCode) {
    final plannedWorkout = session.workout!.toPlannedWorkout();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: WorkoutRecapBottomSheet(
        workout: plannedWorkout,
        isPreview: true,
      ),
    );
  }

  /// Preview d'un cardio en utilisant le même widget que le recap
  Widget _buildCardioSessionCard(PendingSession session, String langCode) {
    final plannedActivity = session.cardio!.toPlannedActivity();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CardioRecapBottomSheet(
        activity: plannedActivity,
        isPreview: true,
      ),
    );
  }

  Widget _buildSessionsPreviewButtons(String langCode) {
    final n = _pendingSessions?.length ?? 0;
    final current = n > 0 ? _pendingSessions![_currentSessionIndex.clamp(0, n - 1)] : null;
    final validate = 'planner_validate'.tr(langCode);
    final label = current == null || n == 1 ? validate : '$validate ${_formatDayNameShort(current.plannedDate, langCode)}';
    return ProposalActions(
      cancelLabel: 'planner_cancel'.tr(langCode),
      confirmLabel: label,
      onCancel: _cancelSessionsPreview,
      onConfirm: _confirmCurrentSession,
      busy: _isConfirming,
    );
  }

  void _cancelSessionsPreview() {
    setState(() {
      _pendingSessions = null;
      _currentSessionIndex = 0;
      _sessionsPageController?.dispose();
      _sessionsPageController = null;
      _planningState = null;
    });

    final langCode = LocalizationService.instance.currentLanguageCode;
    _addBotMessage('planner_cancelled_what_now'.tr(langCode));
  }

  Future<void> _confirmCurrentSession() async {
    if (_pendingSessions == null || _pendingSessions!.isEmpty || _isConfirming) return;

    final session = _pendingSessions![_currentSessionIndex];

    setState(() => _isConfirming = true);
    unawaited(_landInWeek([(date: session.plannedDate, slot: WeekSlot.sport)]));

    try {
      if (widget.demoMode) {
        // Demo mode: store in memory
        _demoConfirmedSessions.add(session);
        _addSessionToWeekDataLocally(session);
        final remaining = List<PendingSession>.from(_pendingSessions!);
        remaining.removeAt(_currentSessionIndex);

        if (remaining.isEmpty) {
          final langCode = LocalizationService.instance.currentLanguageCode;
          final successMessage = 'planner_all_sessions_planned'.tr(langCode);
          _addBotMessage(successMessage);
          PlannerAIService.addToHistory('assistant', successMessage);
          PlannerAIService.clearHistory();

          setState(() {
            _pendingSessions = null;
            _currentSessionIndex = 0;
            _sessionsPageController?.dispose();
            _sessionsPageController = null;
          });

          // Send demo guidance
          if (widget.initialMode == 'meals') {
            _sendDemoMealsGuidance();
          } else {
            _sendDemoSportGuidance();
          }
        } else {
          setState(() {
            _pendingSessions = remaining;
            if (_currentSessionIndex >= remaining.length) {
              _currentSessionIndex = remaining.length - 1;
            }
          });

          final langCode = LocalizationService.instance.currentLanguageCode;
          final partialMsg = {
            'fr': 'Session confirmée ! Passons à la suivante.',
            'en': 'Session confirmed! Let\'s move to the next one.',
            'de': 'Einheit bestätigt! Weiter zur nächsten.',
          };
          _addBotMessage(partialMsg[langCode] ?? partialMsg['en']!);
        }
        return;
      }

      final result = await PlannerAIService.confirmSingleSession(session);

      if (result.success) {
        // Retirer la session confirmée
        final remaining = List<PendingSession>.from(_pendingSessions!);
        remaining.removeAt(_currentSessionIndex);

        if (remaining.isEmpty) {
          // Toutes les sessions confirmées
          final langCode = LocalizationService.instance.currentLanguageCode;
          final successMessage = 'planner_all_sessions_planned'.tr(langCode);
          _addBotMessage(successMessage);
          PlannerAIService.addToHistory('assistant', successMessage);
          PlannerAIService.clearHistory();

          // Note: le compteur est géré automatiquement par _incrementUsageOncePerSession dans confirmWorkouts/confirmMeals
          await _refreshWeekData();
          await _loadFreeUsageStatus();

          setState(() {
            _pendingSessions = null;
            _currentSessionIndex = 0;
            _sessionsPageController?.dispose();
            _sessionsPageController = null;
          });
        } else {
          // Passer à la session suivante
          setState(() {
            _pendingSessions = remaining;
            if (_currentSessionIndex >= remaining.length) {
              _currentSessionIndex = remaining.length - 1;
            }
          });

          // Message de confirmation partielle
          _addBotMessage(result.message);
          await _refreshWeekData();
        }
      } else {
        _addBotMessage(result.message);
      }
    } catch (e) {
      debugPrint('Error confirming session: $e');
      _addBotMessage(_getErrorMessage());
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Widget _buildDemoActionBar(String langCode) {
    // visible from the start: a hesitant user must always see a way out
    return PopIn(
      key: const ValueKey('planner-demo-bar'),
      dy: 24,
      duration: const Duration(milliseconds: 450),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Skip button
            TextButton(
              onPressed: _collectDemoData,
              child: Text(
                'onboarding_demo_skip'.tr(langCode),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            const Spacer(),
            // Main action button
            ElevatedButton.icon(
              onPressed: _collectDemoData,
              icon: Icon(
                widget.initialMode == 'meals' ? LucideIcons.dumbbell : LucideIcons.check,
                size: 18,
              ),
              label: Text(
                widget.initialMode == 'meals'
                    ? 'onboarding_demo_switch_to_sport'.tr(langCode)
                    : 'onboarding_demo_finish'.tr(langCode),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B132B), // v2: navy for demo actions
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDemoLimitReached(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed: _collectDemoData,
          icon: Icon(
            widget.initialMode == 'meals' ? LucideIcons.dumbbell : LucideIcons.check,
            size: 18,
          ),
          label: Text(
            widget.initialMode == 'meals'
                ? 'onboarding_demo_switch_to_sport'.tr(langCode)
                : 'onboarding_demo_finish'.tr(langCode),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B132B), // v2: navy for demo actions
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildPaywallButton(String langCode) {
    final buttonText = 'planner_upgrade_premium'.tr(langCode);
    final subtitleText = 'planner_unlimited_planning'.tr(langCode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Text(
            subtitleText,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPaywall,
              icon: const Icon(LucideIcons.crown, size: 18),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputZone(String langCode) {
    final placeholder = widget.initialMode == 'meals'
        ? 'planner_meals_placeholder'.tr(langCode)
        : 'planner_workouts_placeholder'.tr(langCode);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF0B132B)),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isProcessing ? const Color(0xFFE2E8F0) : const Color(0xFF0B132B),
                shape: BoxShape.circle,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF64748B)),
                    )
                  : const Icon(LucideIcons.send, size: 18, color: Colors.white),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// Modèle pour un message de chat
class _ChatMessage {
  final String text;
  final bool isUser;
  final List<_ChatAction>? actions;
  final bool isUndoable;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.actions,
    this.isUndoable = false,
  });
}

/// Action cliquable dans un message
class _ChatAction {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  _ChatAction({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Page de détail d'un repas planifié
class _MealDetailPage extends StatelessWidget {
  final PendingMeal meal;
  final String langCode;

  const _MealDetailPage({
    required this.meal,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    // Parser la description pour extraire les sections
    final sections = _parseDescription(meal.dishDescription);

    final mealTypeName = _mealTypeKey(meal.mealType).tr(langCode);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0B132B)),
        ),
        title: Text(
          mealTypeName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec nom et icône
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: meal.mealType.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    meal.mealType.icon,
                    size: 32,
                    color: meal.mealType.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.dishName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '~${meal.estimatedQuantityG.toInt()}g',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Macros
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroItem('${meal.calories}', 'kcal', const Color(0xFF0B132B)),
                  _buildDivider(),
                  _buildMacroItem('${meal.proteins.toInt()}g', 'planner_proteins'.tr(langCode), const Color(0xFF3B82F6)),
                  _buildDivider(),
                  _buildMacroItem('${meal.carbs.toInt()}g', 'planner_carbs'.tr(langCode), const Color(0xFFF59E0B)),
                  _buildDivider(),
                  _buildMacroItem('${meal.fats.toInt()}g', 'planner_fats'.tr(langCode), const Color(0xFFEF4444)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description
            if (sections['description']?.isNotEmpty == true) ...[
              Text(
                sections['description']!,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Ingrédients
            if (sections['ingredients']?.isNotEmpty == true) ...[
              _buildSectionHeader(
                icon: LucideIcons.shoppingBasket,
                title: 'section_ingredients'.tr(langCode),
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: Text(
                  sections['ingredients']!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0B132B),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Recette
            if (sections['recipe']?.isNotEmpty == true) ...[
              _buildSectionHeader(
                icon: LucideIcons.chefHat,
                title: 'section_recipe'.tr(langCode),
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                ),
                child: Text(
                  sections['recipe']!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0B132B),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Astuce
            if (sections['tip']?.isNotEmpty == true) ...[
              _buildSectionHeader(
                icon: LucideIcons.lightbulb,
                title: 'section_tip'.tr(langCode),
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sections['tip']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0B132B),
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Map<String, String> _parseDescription(String description) {
    final result = <String, String>{
      'description': '',
      'ingredients': '',
      'recipe': '',
      'tip': '',
    };

    if (description.isEmpty) return result;

    // Séparer par "---"
    final parts = description.split('---');

    if (parts.isNotEmpty) {
      result['description'] = parts[0].trim();
    }

    for (int i = 1; i < parts.length; i++) {
      final part = parts[i].trim();

      if (part.toUpperCase().startsWith('INGRÉDIENTS:') || part.toUpperCase().startsWith('INGREDIENTS:')) {
        result['ingredients'] = part.replaceFirst(RegExp(r'^INGRÉDIENTS:\s*|^INGREDIENTS:\s*', caseSensitive: false), '').trim();
      } else if (part.toUpperCase().startsWith('RECETTE:') || part.toUpperCase().startsWith('RECIPE:')) {
        result['recipe'] = part.replaceFirst(RegExp(r'^RECETTE:\s*|^RECIPE:\s*', caseSensitive: false), '').trim();
      } else if (part.toUpperCase().startsWith('ASTUCE:') || part.toUpperCase().startsWith('TIP:') || part.toUpperCase().startsWith('TIPP:')) {
        result['tip'] = part.replaceFirst(RegExp(r'^ASTUCE:\s*|^TIP:\s*|^TIPP:\s*', caseSensitive: false), '').trim();
      }
    }

    // Si pas de format structuré, utiliser la description complète
    if (result['ingredients']!.isEmpty && result['recipe']!.isEmpty && result['tip']!.isEmpty) {
      result['description'] = description;
    }

    return result;
  }

  Widget _buildMacroItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
      ],
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// Proposal detail sheets (meals by day, session recap). They read the screen
// state through getters and rebuild when the screen calls setState.
// ═══════════════════════════════════════════════════════════════════════════

Widget _sheetFrame(BuildContext context, {required Widget child}) {
  return Container(
    height: MediaQuery.of(context).size.height * 0.88,
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 10, bottom: 2), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class _MealsProposalSheet extends StatefulWidget {
  const _MealsProposalSheet({
    required this.version,
    required this.langCode,
    required this.initialDay,
    required this.days,
    required this.currentIndex,
    required this.mealsFor,
    required this.dayName,
    required this.dayShort,
    required this.typeLabel,
    required this.letters,
    required this.isConfirming,
    required this.onDayChanged,
    required this.onConfirmDay,
    required this.onConfirmAll,
    required this.onCancel,
    required this.onMealTap,
  });

  final ValueListenable<int> version;
  final String langCode;
  final int initialDay;
  final List<DateTime> Function() days;
  final int Function() currentIndex;
  final List<PendingMeal> Function(DateTime) mealsFor;
  final String Function(DateTime) dayName;
  final String Function(DateTime) dayShort;
  final String Function(PendingMeal) typeLabel;
  final List<String> letters;
  final bool Function() isConfirming;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onConfirmDay;
  final VoidCallback onConfirmAll;
  final VoidCallback onCancel;
  final ValueChanged<PendingMeal> onMealTap;

  @override
  State<_MealsProposalSheet> createState() => _MealsProposalSheetState();
}

class _MealsProposalSheetState extends State<_MealsProposalSheet> {
  late final PageController _pager = PageController(initialPage: widget.initialDay);
  bool _popping = false;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _pop() {
    if (_popping) return;
    _popping = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.version,
      builder: (context, _) {
        final days = widget.days();
        if (days.isEmpty) {
          _pop();
          return const SizedBox.shrink();
        }
        final index = widget.currentIndex().clamp(0, days.length - 1);
        // the screen is the source of truth (it resets the index after a validation)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pager.hasClients && (_pager.page ?? index).round() != index) _pager.jumpToPage(index);
        });
        final day = days[index];
        final meals = widget.mealsFor(day);
        final lang = widget.langCode;
        final mealsWord = 'planner_meals_word'.tr(lang);
        final totalWord = 'planner_day_total'.tr(lang);
        final several = days.length > 1;
        final validate = 'planner_validate'.tr(lang);
        final confirmLabel = several ? (lang == 'de' ? '${widget.dayShort(day)} $validate'.toLowerCase() : '$validate ${widget.dayShort(day)}') : validate;

        return _sheetFrame(
          context,
          child: Column(
            children: [
              ProposalHeader(
                icon: LucideIcons.utensils,
                title: widget.dayName(day),
                subtitle: several ? '${index + 1}/${days.length} · ${meals.length} $mealsWord' : '${meals.length} $mealsWord',
                paged: several,
                canPrev: index > 0,
                canNext: index < days.length - 1,
                onPrev: () => _pager.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                onNext: () => _pager.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pager,
                  itemCount: days.length,
                  onPageChanged: widget.onDayChanged,
                  itemBuilder: (context, i) {
                    final dayMeals = widget.mealsFor(days[i]);
                    final p = dayMeals.fold<double>(0, (sum, m) => sum + m.proteins);
                    final c = dayMeals.fold<double>(0, (sum, m) => sum + m.carbs);
                    final f = dayMeals.fold<double>(0, (sum, m) => sum + m.fats);
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final meal in dayMeals)
                            ProposalMealRow(
                              icon: meal.mealType.icon,
                              typeLabel: widget.typeLabel(meal),
                              dishName: meal.dishName,
                              calories: ((meal.proteins * 4) + (meal.carbs * 4) + (meal.fats * 9)).round(),
                              proteins: meal.proteins.toInt(),
                              carbs: meal.carbs.toInt(),
                              fats: meal.fats.toInt(),
                              macroLetters: widget.letters,
                              onTap: () => widget.onMealTap(meal),
                            ),
                          ProposalDayTotals(
                            calories: ((p * 4) + (c * 4) + (f * 9)).round(),
                            proteins: p.toInt(),
                            carbs: c.toInt(),
                            fats: f.toInt(),
                            totalLabel: totalWord,
                            proteinLabel: 'proteins'.tr(lang),
                            carbsLabel: 'carbs'.tr(lang),
                            fatLabel: 'fats'.tr(lang),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (several) ProposalPagerDots(count: days.length, index: index),
              ProposalActions(
                cancelLabel: 'planner_cancel'.tr(lang),
                confirmLabel: confirmLabel,
                onCancel: widget.onCancel,
                onConfirm: widget.onConfirmDay,
                busy: widget.isConfirming(),
                secondaryLabel: several ? '${'planner_confirm_all_days'.tr(lang)} · ${days.length} ${'planner_days_count'.tr(lang)}' : null,
                onSecondary: several ? widget.onConfirmAll : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionProposalSheet extends StatefulWidget {
  const _SessionProposalSheet({
    required this.version,
    required this.langCode,
    required this.sessions,
    required this.currentIndex,
    required this.dayName,
    required this.cardBuilder,
    required this.isConfirming,
    required this.onConfirm,
    required this.onCancel,
    required this.onIndexChanged,
  });

  final ValueListenable<int> version;
  final String langCode;
  final List<PendingSession>? Function() sessions;
  final int Function() currentIndex;
  final String Function(DateTime) dayName;
  final Widget Function(PendingSession) cardBuilder;
  final bool Function() isConfirming;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final ValueChanged<int> onIndexChanged;

  @override
  State<_SessionProposalSheet> createState() => _SessionProposalSheetState();
}

class _SessionProposalSheetState extends State<_SessionProposalSheet> {
  bool _popping = false;

  void _pop() {
    if (_popping) return;
    _popping = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.version,
      builder: (context, _) {
        final sessions = widget.sessions();
        if (sessions == null || sessions.isEmpty) {
          _pop();
          return const SizedBox.shrink();
        }
        final n = sessions.length;
        final index = widget.currentIndex().clamp(0, n - 1);
        final session = sessions[index];
        final lang = widget.langCode;
        final sessionWord = 'planner_session_word'.tr(lang);
        final thisOne = 'planner_this_session'.tr(lang);
        return _sheetFrame(
          context,
          child: Column(
            children: [
              ProposalHeader(
                icon: session.isWorkout ? LucideIcons.dumbbell : LucideIcons.activity,
                title: widget.dayName(session.plannedDate),
                subtitle: n > 1 ? '$sessionWord ${index + 1}/$n · ${session.displayTitle}' : session.displayTitle,
                paged: n > 1,
                canPrev: index > 0,
                canNext: index < n - 1,
                onPrev: () => widget.onIndexChanged(index - 1),
                onNext: () => widget.onIndexChanged(index + 1),
              ),
              Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 8), child: widget.cardBuilder(session))),
              if (n > 1) ProposalPagerDots(count: n, index: index),
              ProposalActions(
                cancelLabel: 'planner_cancel'.tr(lang),
                confirmLabel: '${'planner_validate'.tr(lang)} $thisOne',
                onCancel: widget.onCancel,
                onConfirm: widget.onConfirm,
                busy: widget.isConfirming(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dictionary key of a meal slot; the short form fits a proposal row.
String _mealTypeKey(PlannedActivityType t, {bool short = false}) {
  switch (t) {
    case PlannedActivityType.breakfast:
      return short ? 'planner_breakfast_short' : 'breakfast';
    case PlannedActivityType.lunch:
      return 'lunch';
    case PlannedActivityType.dinner:
      return 'dinner';
    case PlannedActivityType.snack:
      return 'snack';
    default:
      return t.value;
  }
}

/// A mark travelling from the proposal card to its day in the week.
class _FlyingMark extends StatefulWidget {
  const _FlyingMark({required this.start, required this.end, required this.slot});
  final Rect start;
  final Rect end;
  final WeekSlot slot;

  @override
  State<_FlyingMark> createState() => _FlyingMarkState();
}

class _FlyingMarkState extends State<_FlyingMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 620))..forward();
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sport = widget.slot == WeekSlot.sport;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final v = _t.value;
        final rect = Rect.lerp(widget.start, widget.end, v)!;
        final size = rect.shortestSide.clamp(6.0, 44.0);
        return Positioned(
          left: rect.center.dx - size / 2,
          top: rect.center.dy - size / 2,
          width: size,
          height: size,
          child: IgnorePointer(
            child: Opacity(
              opacity: v > 0.9 ? (1 - v) * 10 : 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: sport ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: sport ? null : BorderRadius.circular(size * 0.24),
                  border: Border.all(color: const Color(0xFF0B132B), width: 1.6),
                  boxShadow: [BoxShadow(color: const Color(0xFF0B132B).withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: size > 16 ? Icon(iconForSlot(widget.slot), size: size * 0.5, color: const Color(0xFF0B132B)) : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
