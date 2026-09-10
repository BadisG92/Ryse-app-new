import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../components/ui/motion.dart';
import '../components/weekly_planner/meal_proposal_page.dart';
import '../components/weekly_planner/session_proposal_sheet.dart';
import '../components/weekly_planner/proposal_card.dart';
import '../components/weekly_planner/slot_entries_sheet.dart';
import '../components/weekly_planner/week_strip.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/weekly_planner_models.dart';
import '../services/weekly_planner_service.dart';
import '../services/global_state_manager.dart';
import '../design/design.dart';
import '../home/home_slots.dart';
import '../nutrition/meal_sheet.dart';
import '../services/ryze_dates.dart';
import '../sport/sport_data.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../ai/ryze_access.dart';
import '../ai/ryze_events.dart';
import '../ai/ryze_planner_session.dart';
import '../ai/ryze_tools/ryze_tool.dart';
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

  /// La demande à envoyer dès l'ouverture.
  ///
  /// Quand Ryze passe le relais depuis la conversation, l'utilisateur ne doit
  /// pas avoir à réécrire ce qu'il vient de dire.
  final String? initialMessage;

  // Demo mode (onboarding)
  final bool demoMode;
  final int? maxMessages;
  final void Function(List<PendingMeal> meals, List<PendingWorkout> workouts, List<PendingSession> sessions)? onDemoDataCollected;

  const PlannerChatScreen({
    super.key,
    required this.initialMode,
    required this.weekData,
    this.initialMessage,
    this.demoMode = false,
    this.maxMessages,
    this.onDemoDataCollected,
  });

  @override
  State<PlannerChatScreen> createState() => _PlannerChatScreenState();
}

class _PlannerChatScreenState extends State<PlannerChatScreen>
    with GlobalStateListener {
  /// La bande des jours suit ce qui change ailleurs.
  ///
  /// L'écran n'écoutait rien et relisait sans forcer : un repas supprimé
  /// depuis la conversation, ou une séance terminée pendant qu'il était
  /// ouvert, ne s'y voyaient pas. Le mode démo garde sa semaine en mémoire,
  /// il ne doit pas être rechargé depuis la base.
  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    if (widget.demoMode) return;
    switch (event.type) {
      case ChangeType.planner:
      case ChangeType.meals:
      case ChangeType.workout:
      case ChangeType.sport:
      case ChangeType.dayReset:
      case ChangeType.batch:
        _refreshWeekData();
      default:
        break;
    }
  }

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
  final Map<String, GlobalKey> _rowKeys = {};
  final Set<String> _poppedSlots = {};
  final Set<String> _incomingSlots = {};
  final List<_ChatMessage> _messages = [];
  bool _isProcessing = false;

  // Week data (peut être mis à jour)
  late WeeklyPlannerData _weekData;

  // Free tier tracking
  bool _isPremium = false;
  bool _isTestMode = false;
  bool _showPaywallButton = false;

  // Preview mode
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

  // Confirmation mode (pour actions destructrices)
  Map<String, dynamic>? _pendingConfirmation;

  /// L'action que Ryze propose et qui attend un oui.
  RyzePending? _pendingCard;

  /// Le moteur, partagé avec la conversation.
  late final RyzePlannerSession _session;

  // Undo tracking
  int _undoableMessageIndex = -1;

  // Demo mode tracking
  int _userMessageCount = 0;
  final Set<_ChatMessage> _shownMessages = {}; // bulles déjà animées (pas de rejeu au scroll)
  final ValueNotifier<int> _proposalVersion = ValueNotifier<int>(0); // bumped on every setState: the detail sheets rebuild with the screen
  final List<PendingMeal> _demoConfirmedMeals = [];
  final List<PendingSession> _demoConfirmedSessions = [];
  bool _demoMealsGuided = false;
  bool _demoSportGuided = false;

  @override
  void initState() {
    super.initState();
    _weekData = widget.weekData;
    // La demo de l'onboarding n'a pas d'historique a lire.
    if (!widget.demoMode) _loadSportDone();
    if (widget.demoMode) {
      // In demo mode, bypass premium checks
      _isPremium = true;
      PlannerAIService.setDemoMode(true);
      RyzeAccess.setDemoMode(true);
    } else {
      _refreshAccess();
    }

    // Le moteur pose lui-même la fenêtre de planification sur cette semaine.
    _session = RyzePlannerSession(mode: widget.initialMode, weekStart: _weekData.weekStart);
    _addBotMessage(_getWelcomeMessage());

    // Scroll vers aujourd'hui après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCalendarToToday();

      // La demande passée par Ryze part toute seule : l'utilisateur vient de
      // l'écrire dans la conversation, il n'a pas à la retaper ici.
      final relayee = widget.initialMessage?.trim() ?? '';
      if (relayee.isNotEmpty) {
        _textController.text = relayee;
        _handleSend();
      }
    });
  }

  /// Relit l'accès. Le paywall est dur : abonné, mode test, ou rien.
  ///
  /// Il restait de l'ancien compteur une méthode qui comptait des
  /// planifications gratuites ; elles n'existent plus.
  void _refreshAccess() {
    final premium = PlannerAIService.isPremium;
    final test = UnifiedSubscriptionService().testMode;
    if (premium == _isPremium && test == _isTestMode) return;
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _isTestMode = test;
    });
  }

  /// Demo confirmations are written like real ones, so the coach's modify,
  /// move and delete tools find the rows they act on. Demo mode stays on, so
  /// the write does not count against the free planner uses.
  Future<void> _persistDemo(Future<PlannerActionResult> Function() write) async {
    try {
      final result = await write();
      if (!result.success) debugPrint('⚠️ Demo confirmation refused: ${result.message}');
    } catch (e) {
      debugPrint('⚠️ Demo confirmation failed: $e');
    }
    if (mounted) await _refreshWeekData();
  }

  Future<void> _refreshWeekData() async {
    try {
      // the demo bypasses the cache: it just wrote what it wants to see
      final data = await WeeklyPlannerService.getWeekData(forceRefresh: widget.demoMode);
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
    // one dish per slot: asking for salmon at lunch replaces lunch, it does
    // not stack a second lunch under the first one
    bool sameSlot(PlannedActivity a, PendingMeal m) =>
        a.activityType == m.mealType &&
        a.plannedDate.year == m.plannedDate.year &&
        a.plannedDate.month == m.plannedDate.month &&
        a.plannedDate.day == m.plannedDate.day;
    final newActivities = _weekData.activities.where((a) => !meals.any((m) => sameSlot(a, m))).toList();
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
        journalEntriesByDate: _journalByDate,
        eatenMealTypesByDate: _eatenByDate,
      );
    });
  }

  /// Ce qui a déjà été mangé, jour par jour.
  ///
  /// Les trois reconstructions locales de la semaine repartent de zéro avec
  /// `fromLists`, et elles oubliaient le journal : ajouter un repas au plan
  /// effaçait de la bande tous les repas réellement notés, jusqu'au prochain
  /// chargement depuis la base.
  /// Ce qui a vraiment eu lieu, cote sport : meme garde-fou que l'accueil.
  Map<String, Set<SportKind>> _sportDone = const {};

  Future<void> _loadSportDone() async {
    try {
      final days = List<DateTime>.generate(7, (i) => _weekData.weekStart.add(Duration(days: i)));
      final done = await SportData.kinds(from: days.first, to: days.last);
      if (mounted) setState(() => _sportDone = done);
    } catch (_) {
      // la bande garde ce qu'elle sait du plan
    }
  }

  Map<DateTime, List<JournalFoodEntry>> get _journalByDate => {
        for (final plan in _weekData.dayPlans.values)
          if (plan.journalEntries.isNotEmpty) plan.date: plan.journalEntries,
      };

  /// Les repas déjà mangés, par jour.
  ///
  /// Les reconstructions locales l'oubliaient : après un ajout, un repas
  /// prévu et déjà mangé repassait de « fait » à « prévu » à l'écran,
  /// jusqu'à la prochaine relecture.
  Map<DateTime, Set<String>> get _eatenByDate => {
        for (final plan in _weekData.dayPlans.values)
          if (plan.eatenMealTypes.isNotEmpty) plan.date: plan.eatenMealTypes,
      };

  void _addWorkoutsToWeekDataLocally(List<PendingWorkout> workouts) {
    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    final newWorkouts = _weekData.workouts.where((w) => !workouts.any((n) => sameDay(w.plannedDate, n.plannedDate))).toList();
    for (final w in workouts) {
      newWorkouts.add(w.toPlannedWorkout());
    }
    setState(() {
      _weekData = WeeklyPlannerData.fromLists(
        weekStart: _weekData.weekStart,
        activities: _weekData.activities.toList(),
        workouts: newWorkouts,
        journalEntriesByDate: _journalByDate,
        eatenMealTypesByDate: _eatenByDate,
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
          journalEntriesByDate: _journalByDate,
          eatenMealTypesByDate: _eatenByDate,
        );
      });
    }
  }

  GlobalKey _slotKey(int day, WeekSlot slot) => _slotKeys.putIfAbsent('$day-${slot.name}', () => GlobalKey());

  /// Anchor of one row of the proposal card, so a validated item flies from
  /// the line the user read rather than from the top of the card.
  GlobalKey _rowKey(String id) => _rowKeys.putIfAbsent(id, () => GlobalKey());

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
    _session.dispose();
    _weekFoldTimer?.cancel();
    _proposalVersion.dispose();
    if (widget.demoMode) {
      PlannerAIService.setDemoMode(false);
      RyzeAccess.setDemoMode(false);
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
    });
    _scrollChatToBottom();

    // Ce qu'un outil produit attend la phrase qui l'explique.
    //
    // Le modèle appelle l'outil avant de parler : au moment où la carte
    // arrive, il n'a encore rien dit. Vider le tampon ne posait donc rien,
    // et la carte se retrouvait au-dessus de la phrase — « Retirer ces
    // séances ? » avec ses deux boutons, puis, dessous, « Je retire ta
    // séance prévue pour demain. » On lisait la question après la réponse.
    final held = <void Function()>[];
    void reveal() {
      for (final poser in held) {
        poser();
      }
      held.clear();
    }

    try {
      if (!RyzeAccess.canUse) {
        _addBotMessage(PlannerAIService.paywallMessage(LocalizationService.instance.currentLanguageCode));
        setState(() => _showPaywallButton = true);
        return;
      }

      // Le même moteur que la conversation. L'écran garde sa mise en scène —
      // la bande des jours, les cartes feuilletées — et ne s'occupe plus que
      // de montrer ce qui arrive.
      // Le texte du tour devient une bulle une fois complet : cet écran ne
      // fait pas défiler les caractères, il pose la réponse. Elle est posée
      // avant toute carte, pour que ce qu'il y a à valider reste en bas.
      final buffer = StringBuffer();
      void flush() {
        final said = buffer.toString().trim();
        buffer.clear();
        if (said.isNotEmpty) _addBotMessage(said);
      }

      await for (final event in _session.send(text)) {
        if (!mounted) break;

        switch (event) {
          case CoachText(:final text):
            buffer.write(text);

          case CoachProposals(:final meals, :final sessions):
            held.add(() => _showProposals(meals, sessions));

          case CoachAsk(:final pending):
            held.add(() => _addPendingCard(pending));

          case CoachAction(:final summary):
            held.add(() => _addBotMessage(summary));
            // La bande des jours, elle, n'attend pas : elle montre l'état,
            // pas le récit.
            await _refreshWeekData();

          case CoachFailure(:final message):
            flush();
            reveal();
            _addBotMessage(message);
            return;
        }
      }

      flush();
      reveal();
    } catch (e) {
      debugPrint('Error processing AI request: $e');
      // Une carte prête ne disparaît pas avec la phrase qui a échoué : ce
      // qu'elle propose est déjà construit.
      reveal();
      // a failed call must not eat one of the demo messages
      if (widget.demoMode && widget.maxMessages != null && _userMessageCount > 0) _userMessageCount--;
      _addBotMessage(_getErrorMessage());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Ce que Ryze propose d'ajouter, posé dans les pages de l'écran.
  ///
  /// Les repas se feuillettent par jour, les séances une par une : une semaine
  /// entière fait une douzaine de propositions, et les montrer d'un bloc
  /// reviendrait à demander de tout accepter sans rien lire.
  void _showProposals(List<PendingMeal> meals, List<PendingSession> sessions) {
    if (meals.isNotEmpty) {
      final days = <DateTime>{
        for (final m in meals) DateTime(m.plannedDate.year, m.plannedDate.month, m.plannedDate.day),
      }.toList()
        ..sort();

      setState(() {
        _pendingMeals = meals;
        _mealsDays = days;
        _currentMealsDayIndex = 0;
        _mealsPageController?.dispose();
        _mealsPageController = PageController(initialPage: 0);
      });
    }

    if (sessions.isNotEmpty) {
      setState(() {
        _pendingSessions = sessions;
        _currentSessionIndex = 0;
        _sessionsPageController?.dispose();
        _sessionsPageController = PageController(initialPage: 0);
      });
    }
    _scrollChatToBottom();
  }

  /// Une action qui touche à la semaine déjà posée : elle demande avant.
  void _addPendingCard(RyzePending pending) {
    _pendingCard = pending;

    // Le détail dit ce qui va disparaître, nommément. Sans lui, la carte
    // demandait « Retirer ces séances ? » sans jamais dire lesquelles.
    final detail = pending.detail;
    _addConfirmationMessage(
      detail == null || detail.isEmpty ? pending.title : '${pending.title}\n$detail',
    );
  }

  /// L'utilisateur a répondu à la carte.
  Future<void> _resolveCard({required bool accept}) async {
    final pending = _pendingCard;
    _pendingCard = null;
    if (pending == null) return;

    if (!accept) {
      _session.note('cancelled by the user: ${pending.title}');
      RyzeFeedback.removed();
      return;
    }

    RyzeFeedback.confirm();
    final result = await pending.commit();
    if (!mounted) return;

    _session.note(result.summary);

    // Ce qui vient d'être retiré ou déplacé peut revenir : la bulle garde son
    // « annuler » jusqu'au message suivant.
    if (result.undo != null) {
      _addUndoableBotMessage(result.summary);
    } else {
      _addBotMessage(result.summary);
    }
    await _refreshWeekData();
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
          if (_slotOf(m.mealType) != null)
            (
              date: m.plannedDate,
              slot: _slotOf(m.mealType)!,
              row: _mealsDays.length > 1 ? 'd-${_mealsDays.indexWhere((d) => d.isAtSameMomentAs(currentDay))}' : 'm-${m.mealType.name}',
            ),
      ]));

      if (widget.demoMode) {
        // Demo mode: store in memory, don't save to DB
        _demoConfirmedMeals.addAll(mealsForCurrentDay);
        _addMealsToWeekDataLocally(mealsForCurrentDay);
        unawaited(_persistDemo(() => PlannerAIService.confirmMeals(mealsForCurrentDay)));

        final remainingMeals = _pendingMeals!.where((meal) {
          final mealDate = DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day);
          return !mealDate.isAtSameMomentAs(currentDay);
        }).toList();

        if (remainingMeals.isEmpty) {
          final langCode = LocalizationService.instance.currentLanguageCode;
          final successMsg = 'planner_all_meals_planned'.tr(langCode);
          _addBotMessage(successMsg);
          _session.note(successMsg);
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
        _refreshAccess();

        // Retirer les repas confirmés de la liste
        final remainingMeals = _pendingMeals!.where((meal) {
          final mealDate = DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day);
          return !mealDate.isAtSameMomentAs(currentDay);
        }).toList();

        // Vérifier s'il reste des jours
        if (remainingMeals.isEmpty) {
          // Tous les jours ont été confirmés
          _addBotMessage(result.message);
          _session.note(result.message);
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
      _pendingMeals = null;
      _mealsDays = [];
      _currentMealsDayIndex = 0;
      _mealsPageController?.dispose();
      _mealsPageController = null;
    });

    _addBotMessage(messages[langCode] ?? messages['en']!);
  }

  void _cancelConfirmation() {
    final langCode = LocalizationService.instance.currentLanguageCode;

    setState(() {
      if (_messages.isNotEmpty && _messages.last.actions != null) {
        _messages.removeLast();
      }
      _pendingConfirmation = null;
    });

    _resolveCard(accept: false);
    _addBotMessage('ryze_cancelled'.tr(langCode));
  }

  Future<void> _executeConfirmation() async {
    if (_isConfirming || _pendingConfirmation == null) return;
    setState(() => _isConfirming = true);

    try {
      setState(() {
        if (_messages.isNotEmpty && _messages.last.actions != null) {
          _messages.removeLast();
        }
        _pendingConfirmation = null;
      });

      // L'action attendue vit maintenant dans la carte de l'agent. Elle porte
      // ce qu'il faut faire, il n'y a plus d'état d'attente à retrouver
      // ailleurs dans le service.
      await _resolveCard(accept: true);
    } catch (e) {
      debugPrint('Error executing confirmation: $e');
      _addBotMessage(_getErrorMessage());
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
      _session.note(result.message);

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
    // Plus de liste de séances à part : une séance validée est une
    // `PendingSession`, qui porte sa musculation ou son cardio.
    widget.onDemoDataCollected?.call(
      _demoConfirmedMeals,
      const [],
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
    WorkoutRecapBottomSheet.show(context, workout: workout, onWorkoutStarted: _refreshWeekData, onWorkoutDeleted: _refreshWeekData);
  }

  void _showCardioRecap(PlannedActivity activity) {
    CardioRecapBottomSheet.show(context, activity: activity, onCardioStarted: _refreshWeekData, onCardioDeleted: _refreshWeekData);
  }

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final langCode = locService.currentLanguageCode;

    final scaffold = Scaffold(
      backgroundColor: RyzeColors.paper,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SafeArea(bottom: false, child: _buildHeader(langCode)),

          // La semaine, fixe sous l'en-tete.
          _buildCalendarSection(langCode),
          Divider(height: 1, color: RyzeColors.line),

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
          if (widget.demoMode && _pendingMeals == null && _pendingSessions == null)
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
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          child: const SizedBox.expand(),
        );
      },
      child: scaffold,
    );
  }

  /// L'en-tete de la conversation. C'etait une `AppBar` Material ; c'est
  /// maintenant celle du systeme, la meme que le chat du coach.
  /// Le coach de ce mode : la conversation est soit des repas, soit des
  /// seances, donc on sait toujours lequel des deux parle.
  String get _coachFace =>
      widget.initialMode == 'meals' ? RyzeAssets.nutriAvatar : RyzeAssets.sportAvatar;

  Widget _buildHeader(String langCode) {
    final title = widget.demoMode
        ? (widget.initialMode == 'meals'
            ? 'onboarding_demo_meals_title'.tr(langCode)
            : 'onboarding_demo_sport_title'.tr(langCode))
        : (widget.initialMode == 'meals'
            ? 'plan_my_meals'.tr(langCode)
            : 'plan_my_workouts'.tr(langCode));

    final subtitle = widget.demoMode && widget.maxMessages != null
        ? '${widget.maxMessages! - _userMessageCount} ${'onboarding_demo_messages_left'.tr(langCode)}'
        : 'planner_ai_subtitle'.tr(langCode);

    return RyzeChatHeader(
      title: title,
      subtitle: subtitle,
      avatars: [_coachFace],
      onBack: widget.demoMode ? null : () => Navigator.pop(context),
    );
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
  /// La bande du planificateur lit la journée exactement comme l'accueil.
  ///
  /// Elle ne lisait que le **planifié** : un repas noté hors plan — la plupart
  /// des repas, donc — ne remplissait pas son créneau. Les deux écrans
  /// montraient la même journée avec deux jeux de marques différents, et
  /// c'est l'accueil qui avait raison. Une seule lecture pour les deux :
  /// [HomeSlots.ofDay], qui sait déjà écarter un repas du journal déjà
  /// rattaché à un repas prévu.
  List<DaySlots> _weekSlots() {
    return List<DaySlots>.generate(7, (i) {
      final date = _weekData.weekStart.add(Duration(days: i));
      final day = HomeSlots.ofDay(_weekData.getDayPlan(date), done: _sportDone[SportData.dayKey(date)]);
      final states = Map<WeekSlot, SlotState>.from(day.states);
      // Les tuiles de la bande sont étroites : le libellé y tient en un mot.
      final labels = {for (final e in day.labels.entries) e.key: _shortLabel(e.value)};

      // Tant qu'une marque est en l'air, sa case ne montre rien : la tuile
      // apparaît quand la marque se pose, pas avant.
      //
      // Mais seulement si la case est vide. Une deuxième séance le même jour
      // effaçait la première pendant tout le vol : le jour se vidait sous
      // les yeux, et la marque avait l'air de chercher une case libre. Elle
      // se pose maintenant sur ce qui est déjà là.
      for (final slot in WeekSlot.values) {
        final deja = states[slot] ?? SlotState.empty;
        if (deja == SlotState.empty && _incomingSlots.contains('$i-${slot.name}')) {
          states[slot] = SlotState.incoming;
        }
      }
      return DaySlots(states: states, labels: labels);
    });
  }

  Widget _buildCalendarSection(String langCode) {
    // the window does not always start on a Monday, so each letter comes from
    // the weekday its own date falls on
    final letters = _getDayNames(langCode);
    final days = List<DateTime>.generate(7, (i) => _weekData.weekStart.add(Duration(days: i)));
    return WeekStrip(
      days: days,
      dayLetters: [for (final d in days) letters[d.weekday - 1]],
      slots: _weekSlots(),
      expanded: _weekExpanded,
      onToggle: _toggleWeek,
      slotKey: _slotKey,
      popped: _poppedSlots,
      onSlotTap: _openSlot,
    );
  }

  /// A tile in the unfolded week opens what it holds: the session recap, or
  /// the dish with its ingredients, its recipe and its macros.
  /// Ce qu'une case de la semaine ouvre.
  ///
  /// Elle n'ouvrait que sa première entrée — la première séance du jour, le
  /// premier plat du créneau. Les autres existaient dans les données, se
  /// comptaient dans les totaux, et n'étaient atteignables nulle part depuis
  /// le calendrier. Elles défilent maintenant, chacune disant si elle est
  /// faite ou prévue ; une seule entrée va toujours droit au détail.
  Future<void> _openSlot(int day, WeekSlot slot) async {
    final date = _weekData.weekStart.add(Duration(days: day));
    final plan = _weekData.getDayPlan(date);
    if (plan == null) return;
    final lang = LocalizationService.instance.currentLanguageCode;

    final entries = <SlotEntry>[];
    final opens = <VoidCallback>[];

    if (slot == WeekSlot.sport) {
      for (final w in plan.workouts) {
        entries.add((
          title: w.workoutName,
          detail: _sportDetail(w.exercises.length, w.durationMinutes, lang),
          done: w.status == PlannedStatus.completed,
          sport: true,
        ));
        opens.add(() => _showWorkoutRecap(w));
      }
      for (final c in plan.cardios) {
        final data = c.cardioData;
        entries.add((
          title: data?.activityName ?? '',
          detail: _sportDetail(0, data?.targetMinutes, lang),
          done: c.status == PlannedStatus.completed,
          sport: true,
        ));
        opens.add(() => _showCardioRecap(c));
      }
    } else {
      // Ce qui a été mangé sur ce créneau. Le journal remonte maintenant en
      // entier, liens compris : un plat prévu coché n'est plus une entrée à
      // part, sinon le même repas s'affiche deux fois.
      final mange = [
        for (final e in plan.journalEntries)
          if (HomeSlots.normalizeMealType(e.mealType) == slot.name) e,
      ];
      for (final meal in plan.meals) {
        if (_slotOf(meal.activityType) != slot) continue;
        if (meal.status == PlannedStatus.completed && mange.isNotEmpty) continue;
        final data = meal.activityData;
        entries.add((
          title: (data['dish_name'] as String?) ?? '',
          detail: 'slot_kcal'.tr(lang).replaceAll('{n}', '${(data['calories'] as num?)?.round() ?? 0}'),
          done: meal.status == PlannedStatus.completed,
          sport: false,
        ));
        // La même feuille que l'accueil et Nutrition, et non plus une page
        // de lecture seule : depuis le calendrier, un plat prévu ne pouvait
        // ni se valider ni se retirer, alors que c'est l'écran où on le
        // regarde en décidant de sa semaine.
        opens.add(() async {
          final change = await MealSheet.show(context, day: date, slot: slot, planned: meal);
          if (change && mounted) await _refreshWeekData();
        });
      }
      // Ce qui a vraiment été mangé sur ce créneau : le journal. Il n'était
      // atteignable que depuis l'accueil et Nutrition.
      for (final e in mange) {
        entries.add((
          title: e.name,
          detail: 'slot_kcal'.tr(lang).replaceAll('{n}', '${e.calories}'),
          done: true,
          sport: false,
        ));
        opens.add(() async {
          final change = await MealSheet.show(context, day: date, slot: slot);
          if (change && mounted) await _refreshWeekData();
        });
      }
    }

    if (entries.isEmpty) return;
    if (entries.length == 1) {
      opens.first();
      return;
    }

    final chosen = await SlotEntriesSheet.show(
      context,
      title: _slotLabel(slot, lang),
      subtitle: RyzeDates.full(date, lang),
      lang: lang,
      entries: entries,
    );
    if (chosen == null || !mounted) return;
    opens[chosen]();
  }

  /// « 5 exercices · 45 min », ou la durée seule pour un cardio. Mêmes mots
  /// que la carte du jour dans l'onglet Sport.
  String _sportDetail(int exercises, int? minutes, String lang) {
    final min = minutes ?? 0;
    if (exercises > 0) {
      return 'sport_exercises_n_min'.tr(lang).replaceAll('{n}', '$exercises').replaceAll('{min}', '$min');
    }
    return min > 0 ? '$min ${'minutes'.tr(lang)}' : '';
  }

  String _slotLabel(WeekSlot slot, String lang) =>
      slot == WeekSlot.sport ? 'slot_sport'.tr(lang) : 'meal_name_${slot.name}'.tr(lang);

  // ---------------------------------------------------------------- landing

  int _dayIndexOf(DateTime date) {
    final start = DateTime(_weekData.weekStart.year, _weekData.weekStart.month, _weekData.weekStart.day);
    return DateTime(date.year, date.month, date.day).difference(start).inDays;
  }

  /// Opens the week, flies one mark per validated item to its day, then folds
  /// it back. This is the moment that shows the app placing things in the week.
  Future<void> _landInWeek(List<({DateTime date, WeekSlot slot, String? row})> items) async {
    if (items.isEmpty || !mounted) return;
    final fallback = _rectOf(_proposalCardKey); // the card is about to leave the screen
    final targets = <({int day, WeekSlot slot, Rect? from})>[];
    for (final item in items) {
      final day = _dayIndexOf(item.date);
      if (day < 0 || day > 6) continue;
      if (targets.any((t) => t.day == day && t.slot == item.slot)) continue;
      targets.add((day: day, slot: item.slot, from: (item.row == null ? null : _rectOf(_rowKeys[item.row!])) ?? fallback));
    }
    if (targets.isEmpty) return;

    _weekFoldTimer?.cancel();
    setState(() {
      for (final t in targets) {
        _incomingSlots.add('${t.day}-${t.slot.name}');
      }
      if (!_weekExpanded) {
        _weekAutoOpened = true;
        _weekExpanded = true;
      }
    });
    if (_weekAutoOpened) {
      await Future<void>.delayed(const Duration(milliseconds: 440));
      if (!mounted) return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final overlay = Overlay.of(context);
    for (var i = 0; i < targets.length; i++) {
      final t = targets[i];
      Future<void>.delayed(Duration(milliseconds: i * 70), () {
        if (!mounted) return;
        _flyMark(overlay, t.from, _slotKeys['${t.day}-${t.slot.name}'], t.slot, () {
          if (!mounted) return;
          final id = '${t.day}-${t.slot.name}';
          setState(() {
            _incomingSlots.remove(id);
            _poppedSlots.add(id);
          });
          Future<void>.delayed(const Duration(milliseconds: 260), () {
            if (mounted) setState(() => _poppedSlots.remove(id));
          });
        });
      });
    }
    await Future<void>.delayed(Duration(milliseconds: 700 + targets.length * 70));
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

  void _flyMark(OverlayState overlay, Rect? from, GlobalKey? to, WeekSlot slot, VoidCallback onArrived) {
    final end = _rectOf(to);
    if (end == null) {
      onArrived();
      return;
    }
    final source = from ?? Rect.fromCenter(center: Offset(end.center.dx, end.center.dy + 240), width: 34, height: 34);
    // the icon tile at the left of a proposal row is where the eye already is
    final start = Rect.fromLTWH(source.left + 14, source.center.dy - 20, 40, 40);
    // La cible est relue à chaque image plutôt que figée au décollage : la
    // bande se réorganise pendant les 620 ms du vol — une tuile qui
    // apparaît, une relecture de la semaine après l'écriture — et la
    // marque se posait alors là où la case était, c'est-à-dire à côté.
    final entry = OverlayEntry(
      builder: (context) => _FlyingMark(start: start, end: end, target: to, slot: slot),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 620), onArrived);
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
      padding: EdgeInsets.all(context.vw(4.1)),
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
    if (_pendingMeals != null && _pendingMeals!.isNotEmpty) {
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

  Widget _buildMessageBubble(_ChatMessage message, int index) {
    final lang = LocalizationService.instance.currentLanguageCode;
    final canUndo = message.isUndoable && index == _undoableMessageIndex;
    final fresh = _shownMessages.add(message);

    return PopIn(
      key: ObjectKey(message),
      animate: fresh,
      dy: 12,
      duration: const Duration(milliseconds: 420),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RyzeBubble(
              text: message.text,
              mine: message.isUser,
              copyLabel: 'chat_copied'.tr(lang),
              avatar: message.isUser ? null : _coachFace,
              footer: message.actions == null || message.actions!.isEmpty
                  ? null
                  : Wrap(
                      spacing: context.vw(2.1),
                      runSpacing: context.vw(2.1),
                      children: [
                        for (final action in message.actions!)
                          Pressable(
                            onTap: action.onTap,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(2.3)),
                              decoration: BoxDecoration(
                                color: action.isDestructive ? RyzeColors.danger : RyzeColors.paper,
                                borderRadius: BorderRadius.circular(RyzeRadius.sm),
                                border: Border.all(color: action.isDestructive ? RyzeColors.danger : RyzeColors.line),
                              ),
                              child: Text(
                                action.label,
                                style: RyzeText.body(
                                  context,
                                  3.2,
                                  weight: FontWeight.w600,
                                  color: action.isDestructive ? RyzeColors.surf : RyzeColors.ink,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          if (canUndo) ...[
            SizedBox(width: context.vw(2.1)),
            Padding(
              padding: EdgeInsets.only(top: context.vw(2.6)),
              child: Pressable(
                onTap: () => _executeUndo(index),
                child: Container(
                  padding: EdgeInsets.all(context.vw(2.3)),
                  decoration: BoxDecoration(
                    color: RyzeColors.surf,
                    borderRadius: BorderRadius.circular(RyzeRadius.sm),
                    border: Border.all(color: RyzeColors.line),
                  ),
                  child: Icon(LucideIcons.undo2, size: context.vw(4.1), color: RyzeColors.mute),
                ),
              ),
            ),
          ],
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RyzeThinking(avatar: _coachFace),
          Padding(
            padding: EdgeInsets.only(left: context.vw(7.7), bottom: context.vw(3.1)),
            child: Text(loadingText, style: RyzeText.body(context, 2.9, color: RyzeColors.mute2)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions(String langCode) {
    return Padding(
      padding: EdgeInsets.only(left: context.vw(7.7), bottom: context.vw(3.1)),
      child: RyzeChatChips(
        labels: _getQuickSuggestions(langCode),
        onTap: (suggestion) {
          _textController.text = widget.initialMode == 'meals'
              ? _transformQuickSuggestionToPrompt(suggestion, langCode)
              : suggestion;
          _handleSend();
        },
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
      suggestionNextMeal: 'prompt_next_meal'.tr(langCode).replaceAll('{meal}', nextMealType),
      suggestionToday: 'prompt_today_meals'.tr(langCode),
      suggestionWeek: 'prompt_week_meals'.tr(langCode),
    };

    return prompts[suggestion] ?? suggestion;
  }

  String _formatDayName(DateTime date, String langCode) {
    return 'day_${date.weekday}'.tr(langCode);
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
              child: KeyedSubtree(
                key: _rowKey('m-${meal.mealType.name}'),
                child: _buildMealPreviewItem(meal, langCode, typeLabel: _mealTypeLabel(meal, langCode), letters: letters),
              ),
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
            child: KeyedSubtree(
              key: _rowKey('d-$i'),
              child: ProposalWorkoutRow(
              dayShort: _formatDayNameShort(day, langCode),
              title: _mealsForDay(day).map((m) => m.dishName).join(' · '),
              subtitle: '${_mealsForDay(day).length} $mealsWord · ${_mealsForDay(day).fold<int>(0, (sum, m) => sum + _mealKcal(m))} kcal',
              onTap: () => _showMealsDetailSheet(langCode, initialDay: i),
              last: i == shownDays.length - 1 && _mealsDays.length <= 3,
            ),
            ),          ),
        if (_mealsDays.length > 3)
          InkWell(
            onTap: () => _showMealsDetailSheet(langCode, initialDay: 3),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  const SizedBox(width: 52),
                  Text(moreDays.replaceAll('{n}', '${_mealsDays.length}'), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: RyzeColors.ink)),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 14, color: RyzeColors.ink),
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
        builder: (context) => MealProposalPage(meal: meal, lang: langCode),
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
          if (_slotOf(m.mealType) != null)
            (
              date: m.plannedDate,
              slot: _slotOf(m.mealType)!,
              row: 'd-${_mealsDays.indexWhere((d) => d.isAtSameMomentAs(DateTime(m.plannedDate.year, m.plannedDate.month, m.plannedDate.day)))}',
            ),
      ]));
      final result = await PlannerAIService.confirmMeals(_pendingMeals!);

      _addBotMessage(result.message);
      _session.note(result.message);

      if (result.success) {
        await _refreshWeekData();
        _refreshAccess();
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
            child: KeyedSubtree(
              key: _rowKey('s-$i'),
              child: ProposalWorkoutRow(
              dayShort: _formatDayNameShort(session.plannedDate, langCode),
              title: session.displayTitle,
              subtitle: session.dateLabel(langCode),
              selected: n > 1 && i == _currentSessionIndex,
              last: i == n - 1,
              onTap: () {
                setState(() => _currentSessionIndex = i);
                _showSessionDetailSheet(langCode);
              },
            ),
            ),          ),
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
      builder: (sheetContext) => SessionProposalSheet(
        version: _proposalVersion,
        langCode: langCode,
        sessions: () => _pendingSessions,
        currentIndex: () => _currentSessionIndex,
        dayName: (d) => _formatDayName(DateTime(d.year, d.month, d.day), langCode),
        isConfirming: () => _isConfirming,
        onConfirm: _confirmCurrentSession,
        onCancel: _cancelSessionsPreview,
        onIndexChanged: (i) => setState(() => _currentSessionIndex = i),
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
    });

    final langCode = LocalizationService.instance.currentLanguageCode;
    _addBotMessage('planner_cancelled_what_now'.tr(langCode));
  }

  Future<void> _confirmCurrentSession() async {
    if (_pendingSessions == null || _pendingSessions!.isEmpty || _isConfirming) return;

    final session = _pendingSessions![_currentSessionIndex];

    setState(() => _isConfirming = true);
    unawaited(_landInWeek([(date: session.plannedDate, slot: WeekSlot.sport, row: 's-$_currentSessionIndex')]));

    try {
      if (widget.demoMode) {
        // Demo mode: store in memory
        _demoConfirmedSessions.add(session);
        _addSessionToWeekDataLocally(session);
        unawaited(_persistDemo(() => PlannerAIService.confirmSingleSession(session)));
        final remaining = List<PendingSession>.from(_pendingSessions!);
        remaining.removeAt(_currentSessionIndex);

        if (remaining.isEmpty) {
          final langCode = LocalizationService.instance.currentLanguageCode;
          final successMessage = 'planner_all_sessions_planned'.tr(langCode);
          _addBotMessage(successMessage);
          _session.note(successMessage);

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
          _session.note(successMessage);

          await _refreshWeekData();
          _refreshAccess();

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
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        border: Border(top: BorderSide(color: RyzeColors.line)),
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
                style: TextStyle(
                  fontSize: 13,
                  color: RyzeColors.mute2,
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
                backgroundColor: RyzeColors.ink, // v2: navy for demo actions
                foregroundColor: RyzeColors.surf,
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
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        border: Border(top: BorderSide(color: RyzeColors.line)),
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
            backgroundColor: RyzeColors.ink, // v2: navy for demo actions
            foregroundColor: RyzeColors.surf,
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
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: RyzeColors.line)),
      ),
      child: Column(
        children: [
          Text(
            subtitleText,
            style: TextStyle(fontSize: 13, color: RyzeColors.mute),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPaywall,
              icon: const Icon(LucideIcons.crown, size: 18),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: RyzeColors.accDeep,
                foregroundColor: RyzeColors.surf,
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
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _textController,
      builder: (context, value, _) => RyzeChatInput(
        controller: _textController,
        focusNode: _focusNode,
        hint: widget.initialMode == 'meals'
            ? 'planner_meals_placeholder'.tr(langCode)
            : 'planner_workouts_placeholder'.tr(langCode),
        canSend: value.text.trim().isNotEmpty,
        busy: _isProcessing,
        onSend: _handleSend,
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
// ═══════════════════════════════════════════════════════════════════════════
// Proposal detail sheets (meals by day, session recap). They read the screen
// state through getters and rebuild when the screen calls setState.
// ═══════════════════════════════════════════════════════════════════════════

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

        return ryzeSheetFrame(
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
  const _FlyingMark({required this.start, required this.end, required this.slot, this.target});
  final Rect start;

  /// Où la case était au décollage. Sert de repli quand la tuile a disparu
  /// de l'arbre en cours de vol.
  final Rect end;

  /// La tuile visée. Relue à chaque image : si la bande bouge pendant le
  /// vol, la marque la suit au lieu d'atterrir à côté.
  final GlobalKey? target;
  final WeekSlot slot;

  @override
  State<_FlyingMark> createState() => _FlyingMarkState();
}

class _FlyingMarkState extends State<_FlyingMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 620))..forward();
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: const Cubic(0.2, 0.7, 0.2, 1));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Où la tuile visée se trouve maintenant.
  Rect? _here() {
    final box = widget.target?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final sport = widget.slot == WeekSlot.sport;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final v = _t.value;
        final rect = Rect.lerp(widget.start, _here() ?? widget.end, v)!;
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
                  color: RyzeColors.surf,
                  shape: sport ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: sport ? null : BorderRadius.circular(size * 0.24),
                  border: Border.all(color: RyzeColors.ink, width: 1.6),
                  boxShadow: [BoxShadow(color: RyzeColors.ink.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: size > 16 ? Icon(iconForSlot(widget.slot), size: size * 0.5, color: RyzeColors.ink) : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
