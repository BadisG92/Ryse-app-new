import 'package:flutter/material.dart';
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
import '../components/weekly_planner/day_column_widget.dart';
import '../components/weekly_planner/add_activity_bottom_sheet.dart';
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

  @override
  void dispose() {
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
          0, // reverse: true, donc 0 = bas
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
    final confirmText = {'fr': 'Confirmer', 'en': 'Confirm', 'de': 'Bestätigen'};
    final cancelText = {'fr': 'Annuler', 'en': 'Cancel', 'de': 'Abbrechen'};

    setState(() {
      _pendingConfirmation = {'description': description};
      _messages.add(_ChatMessage(
        text: description,
        isUser: false,
        actions: [
          _ChatAction(
            label: cancelText[langCode] ?? cancelText['en']!,
            onTap: _cancelConfirmation,
            isDestructive: false,
          ),
          _ChatAction(
            label: confirmText[langCode] ?? confirmText['en']!,
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

      if (widget.demoMode) {
        // Demo mode: store in memory, don't save to DB
        _demoConfirmedMeals.addAll(mealsForCurrentDay);

        final remainingMeals = _pendingMeals!.where((meal) {
          final mealDate = DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day);
          return !mealDate.isAtSameMomentAs(currentDay);
        }).toList();

        if (remainingMeals.isEmpty) {
          final langCode = LocalizationService.instance.currentLanguageCode;
          final successMsg = 'planner_all_sessions_planned'.tr(langCode);
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
          final remainingDays = _mealsDays.sublist(_currentMealsDayIndex + 1);
          setState(() {
            _pendingMeals = remainingMeals;
            _mealsDays = remainingDays;
            _currentMealsDayIndex = 0;
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
          final remainingDays = _mealsDays.sublist(_currentMealsDayIndex + 1);
          setState(() {
            _pendingMeals = remainingMeals;
            _mealsDays = remainingDays;
            _currentMealsDayIndex = 0;
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
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

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

          // Quick suggestions (au début, pas de clavier, pas de preview)
          if (_messages.length <= 1 && !keyboardVisible && _pendingWorkouts == null && _pendingMeals == null && _pendingSessions == null && !_showPaywallButton)
            _buildQuickSuggestions(langCode),

          // Preview des workouts générés (ancien mode)
          if (_pendingWorkouts != null && _pendingWorkouts!.isNotEmpty)
            _buildWorkoutPreview(langCode),

          // Preview des repas générés
          if (_pendingMeals != null && _pendingMeals!.isNotEmpty)
            _buildMealsPreview(langCode),

          // NOUVEAU: Preview des sessions paginé (workouts + cardio)
          if (_pendingSessions != null && _pendingSessions!.isNotEmpty)
            _buildSessionsPreview(langCode),

          // Zone du bas selon l'état
          if (_showPaywallButton && !widget.demoMode)
            _buildPaywallButton(langCode)
          else if (_pendingSessions != null && _pendingSessions!.isNotEmpty)
            _buildSessionsPreviewButtons(langCode)
          else if (_pendingWorkouts != null && _pendingWorkouts!.isNotEmpty)
            _buildPreviewButtons(langCode)
          else if (_pendingMeals != null && _pendingMeals!.isNotEmpty)
            _buildMealsPreviewButtons(langCode)
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
              Text(
                _isPremium
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

  Widget _buildCalendarSection(String langCode) {
    final dayNames = _getDayNames(langCode);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          controller: _calendarScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 7,
          itemBuilder: (context, index) {
            final date = _weekData.weekStart.add(Duration(days: index));
            final dayPlan = _weekData.getDayPlan(date);

            // Calculer la largeur pour que 7 jours remplissent l'écran
            final screenWidth = MediaQuery.of(context).size.width;
            final dayWidth = (screenWidth - 24) / 7; // 24 = padding horizontal total

            // Filtre selon le mode
            final filter = widget.initialMode == 'meals'
                ? ActivityFilter.meals
                : ActivityFilter.workouts;

            return SizedBox(
              width: dayWidth,
              child: DayColumnWidget(
                date: date,
                dayName: dayNames[index],
                dayPlan: dayPlan,
                onDataRefresh: _refreshWeekData,
                onActivityTap: (activity) {
                  if (activity.activityType == PlannedActivityType.cardio) {
                    _showCardioRecap(activity);
                  }
                },
                onWorkoutTap: (workout) => _showWorkoutRecap(workout),
                isCompact: true,
                filter: filter,
              ),
            );
          },
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

  Widget _buildChatSection(String langCode) {
    final itemCount = _messages.length + (_isProcessing ? 1 : 0);

    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      reverse: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_isProcessing && index == 0) {
          return _buildTypingIndicator(langCode);
        }

        final messageIndex = _isProcessing ? index - 1 : index;
        final actualIndex = _messages.length - 1 - messageIndex;
        return _buildMessageBubble(_messages[actualIndex], actualIndex);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, int index) {
    final bool canUndo = message.isUndoable && index == _undoableMessageIndex;

    return Padding(
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
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: message.isUser ? Colors.white : const Color(0xFF0B132B),
                        height: 1.4,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: const Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      loadingText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions(String langCode) {
    final suggestions = _getQuickSuggestions(langCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
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
            );
          }).toList(),
        ),
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

    final previewTitle = {
      'fr': 'Aperçu du programme',
      'en': 'Program preview',
      'de': 'Programmvorschau',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                const Icon(LucideIcons.eye, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  previewTitle[langCode] ?? previewTitle['en']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _pendingWorkouts!.length,
              itemBuilder: (context, index) {
                final workout = _pendingWorkouts![index];
                return _buildWorkoutPreviewItem(workout, langCode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPreviewItem(PendingWorkout workout, String langCode) {
    final dayName = _formatDayName(workout.plannedDate, langCode);
    final exerciseCount = workout.exercises?.length ?? 0;
    final exercisesLabel = 'planner_exercises_count'.tr(langCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.dumbbell,
              size: 16,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayName - ${workout.workoutType}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                ),
                Text(
                  '${workout.durationMinutes} min • $exerciseCount $exercisesLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showWorkoutDetails(workout, langCode),
            icon: const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Color(0xFF64748B),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
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
    final confirmText = 'planner_confirm_program'.tr(langCode);
    final modifyText = 'planner_modify'.tr(langCode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isConfirming ? null : _cancelPreview,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(modifyText),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isConfirming ? null : _confirmWorkouts,
              icon: _isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.check, size: 18),
              label: Text(confirmText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
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

  Widget _buildMealsPreview(String langCode) {
    if (_pendingMeals == null || _pendingMeals!.isEmpty || _mealsDays.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header avec navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                // Flèche gauche
                if (_mealsDays.length > 1)
                  GestureDetector(
                    onTap: _currentMealsDayIndex > 0
                        ? () {
                            _mealsPageController?.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: _currentMealsDayIndex > 0
                          ? const Color(0xFF0B132B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _formatDayName(_mealsDays[_currentMealsDayIndex], langCode),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                      if (_mealsDays.length > 1)
                        Text(
                          '${_currentMealsDayIndex + 1}/${_mealsDays.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Flèche droite
                if (_mealsDays.length > 1)
                  GestureDetector(
                    onTap: _currentMealsDayIndex < _mealsDays.length - 1
                        ? () {
                            _mealsPageController?.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: _currentMealsDayIndex < _mealsDays.length - 1
                          ? const Color(0xFF0B132B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          // PageView des jours
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _mealsPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentMealsDayIndex = index;
                });
              },
              itemCount: _mealsDays.length,
              itemBuilder: (context, dayIndex) {
                final day = _mealsDays[dayIndex];
                final mealsForDay = _pendingMeals!.where((meal) {
                  final mealDate = DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day);
                  return mealDate.isAtSameMomentAs(day);
                }).toList();

                // Calculer les totaux du jour avec formule
                final dayProteins = mealsForDay.fold<double>(0, (sum, m) => sum + m.proteins);
                final dayCarbs = mealsForDay.fold<double>(0, (sum, m) => sum + m.carbs);
                final dayFats = mealsForDay.fold<double>(0, (sum, m) => sum + m.fats);
                final dayCalories = ((dayProteins * 4) + (dayCarbs * 4) + (dayFats * 9)).round();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  children: [
                    ...mealsForDay.map((meal) => _buildMealPreviewItem(meal, langCode, showDay: false)),
                    // Total du jour
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMacroChip('$dayCalories', 'kcal', const Color(0xFF0B132B)),
                          _buildMacroChip('${dayProteins.toInt()}g', 'proteins'.tr(langCode)[0], const Color(0xFF3B82F6)),
                          _buildMacroChip('${dayCarbs.toInt()}g', 'carbs'.tr(langCode)[0], const Color(0xFFF59E0B)),
                          _buildMacroChip('${dayFats.toInt()}g', 'fats'.tr(langCode)[0], const Color(0xFFEF4444)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Indicateurs de page (dots)
          if (_mealsDays.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_mealsDays.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _currentMealsDayIndex ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _currentMealsDayIndex
                          ? const Color(0xFF0B132B)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMealPreviewItem(PendingMeal meal, String langCode, {bool showDay = true}) {
    final dayName = _formatDayName(meal.plannedDate, langCode);
    final mealTypeNames = {
      PlannedActivityType.breakfast: {'fr': 'Petit-déj', 'en': 'Breakfast', 'de': 'Frühstück'},
      PlannedActivityType.lunch: {'fr': 'Déjeuner', 'en': 'Lunch', 'de': 'Mittagessen'},
      PlannedActivityType.dinner: {'fr': 'Dîner', 'en': 'Dinner', 'de': 'Abendessen'},
      PlannedActivityType.snack: {'fr': 'Collation', 'en': 'Snack', 'de': 'Snack'},
    };
    final mealTypeName = mealTypeNames[meal.mealType]?[langCode] ?? meal.mealType.value;

    return GestureDetector(
      onTap: () => _showMealDetailPage(meal, langCode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: meal.mealType.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                meal.mealType.icon,
                size: 16,
                color: meal.mealType.color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showDay ? '$dayName - $mealTypeName' : mealTypeName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    meal.dishName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B132B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    // Calculer calories avec formule + utiliser traductions pour abréviations
                    '~${((meal.proteins * 4) + (meal.carbs * 4) + (meal.fats * 9)).round()} kcal | ${'proteins'.tr(langCode)[0]}: ${meal.proteins.toInt()}g | ${'carbs'.tr(langCode)[0]}: ${meal.carbs.toInt()}g | ${'fats'.tr(langCode)[0]}: ${meal.fats.toInt()}g',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
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
    final modifyText = 'planner_cancel'.tr(langCode);

    // Texte du bouton selon si un seul jour ou plusieurs
    String confirmText;
    if (_mealsDays.length <= 1) {
      confirmText = 'planner_validate'.tr(langCode);
    } else {
      final currentDayName = _mealsDays.isNotEmpty
          ? _formatDayNameShort(_mealsDays[_currentMealsDayIndex], langCode)
          : '';
      final validateText = 'planner_validate'.tr(langCode);
      confirmText = langCode == 'de'
          ? '$currentDayName $validateText'.toLowerCase()
          : '$validateText $currentDayName';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Boutons principaux
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isConfirming ? null : _cancelPreview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(modifyText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isConfirming ? null : _confirmMeals,
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.check, size: 18),
                  label: Text(confirmText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          // Bouton "Tout valider" si plusieurs jours
          if (_mealsDays.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isConfirming ? null : _confirmAllMeals,
                  child: Text(
                    '${'planner_confirm_all_days'.tr(langCode)} (${_mealsDays.length} ${'planner_days_count'.tr(langCode)})',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDayNameShort(DateTime date, String langCode) {
    return 'planner_day_short_${date.weekday}'.tr(langCode);
  }

  Future<void> _confirmAllMeals() async {
    if (_pendingMeals == null || _isConfirming) return;

    setState(() => _isConfirming = true);

    try {
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

    final currentSession = _pendingSessions![_currentSessionIndex];
    // Afficher le jour comme pour les repas
    final dayLabel = _formatDayName(
      DateTime(currentSession.plannedDate.year, currentSession.plannedDate.month, currentSession.plannedDate.day),
      langCode,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header avec navigation (même style que meals)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                // Flèche gauche
                if (_pendingSessions!.length > 1)
                  GestureDetector(
                    onTap: _currentSessionIndex > 0
                        ? () {
                            _sessionsPageController?.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: _currentSessionIndex > 0
                          ? const Color(0xFF0B132B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        dayLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                      if (_pendingSessions!.length > 1)
                        Text(
                          '${_currentSessionIndex + 1}/${_pendingSessions!.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Flèche droite
                if (_pendingSessions!.length > 1)
                  GestureDetector(
                    onTap: _currentSessionIndex < _pendingSessions!.length - 1
                        ? () {
                            _sessionsPageController?.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: _currentSessionIndex < _pendingSessions!.length - 1
                          ? const Color(0xFF0B132B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),

          // PageView avec les sessions
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _sessionsPageController,
              itemCount: _pendingSessions!.length,
              onPageChanged: (index) {
                setState(() => _currentSessionIndex = index);
              },
              itemBuilder: (context, index) {
                final session = _pendingSessions![index];
                return _buildSessionCard(session, langCode);
              },
            ),
          ),

          // Indicateurs de page (dots)
          if (_pendingSessions!.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pendingSessions!.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _currentSessionIndex ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _currentSessionIndex
                          ? const Color(0xFF0B132B)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
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
    final cancelText = 'planner_cancel'.tr(langCode);
    final confirmText = '${'planner_validate'.tr(langCode)} ✓';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isConfirming ? null : _cancelSessionsPreview,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(cancelText),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isConfirming ? null : _confirmCurrentSession,
              icon: _isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.check, size: 18),
              label: Text(confirmText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
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

    try {
      if (widget.demoMode) {
        // Demo mode: store in memory
        _demoConfirmedSessions.add(session);
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
    // Only show after at least one message exchange
    if (_userMessageCount == 0) return const SizedBox.shrink();

    return Container(
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
              onPressed: () {
                _collectDemoData();
                Navigator.pop(context);
              },
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
              onPressed: () {
                _collectDemoData();
                Navigator.pop(context);
              },
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
                backgroundColor: widget.initialMode == 'meals'
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
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
          onPressed: () {
            _collectDemoData();
            Navigator.pop(context);
          },
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
            backgroundColor: widget.initialMode == 'meals'
                ? const Color(0xFF3B82F6)
                : const Color(0xFF10B981),
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

    final mealTypeNames = {
      PlannedActivityType.breakfast: {'fr': 'Petit-déjeuner', 'en': 'Breakfast', 'de': 'Frühstück'},
      PlannedActivityType.lunch: {'fr': 'Déjeuner', 'en': 'Lunch', 'de': 'Mittagessen'},
      PlannedActivityType.dinner: {'fr': 'Dîner', 'en': 'Dinner', 'de': 'Abendessen'},
      PlannedActivityType.snack: {'fr': 'Collation', 'en': 'Snack', 'de': 'Snack'},
    };
    final mealTypeName = mealTypeNames[meal.mealType]?[langCode] ?? meal.mealType.value;

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
