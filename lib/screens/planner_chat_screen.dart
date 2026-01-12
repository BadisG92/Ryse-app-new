import 'package:flutter/material.dart';
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

  const PlannerChatScreen({
    super.key,
    required this.initialMode,
    required this.weekData,
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
  bool _isConfirming = false;

  // Confirmation mode (pour actions destructrices)
  Map<String, dynamic>? _pendingConfirmation;

  // Undo tracking
  int _undoableMessageIndex = -1;

  @override
  void initState() {
    super.initState();
    _weekData = widget.weekData;
    _loadFreeUsageStatus();
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
      _messages.add(_ChatMessage(text: text, isUser: false));
    });
    _scrollChatToBottom();
  }

  void _addUndoableBotMessage(String text) {
    setState(() {
      _undoableMessageIndex = _messages.length;
      _messages.add(_ChatMessage(text: text, isUser: false, isUndoable: true));
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
      final result = await PlannerAIService.processRequestWithTools(
        text,
        mode: widget.initialMode,
      );

      if (result.isPaywallRequired) {
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
      } else if (result.requiresConfirmation && result.pendingWorkouts == null) {
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

  void _cancelPreview() {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final messages = {
      'fr': "Pas de souci ! Dis-moi ce que tu voudrais modifier.",
      'en': "No problem! Tell me what you'd like to change.",
      'de': "Kein Problem! Sag mir, was du ändern möchtest.",
    };

    setState(() {
      _pendingWorkouts = null;
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

  String _getErrorMessage() {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final messages = {
      'fr': "Oups, une erreur s'est produite. Réessaie !",
      'en': "Oops, an error occurred. Try again!",
      'de': "Hoppla, ein Fehler ist aufgetreten. Versuche es erneut!",
    };
    return messages[langCode] ?? messages['en']!;
  }

  void _showAddActivitySheet(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddActivityBottomSheet(
        selectedDate: date,
        onActivityAdded: () {
          _refreshWeekData();
        },
      ),
    );
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

    return Hero(
      tag: 'weekly_planner_hero',
      flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
        // Pendant l'animation, afficher juste un container blanc pour éviter l'overflow
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox.expand(),
        );
      },
      child: Scaffold(
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
            if (_messages.length <= 1 && !keyboardVisible && _pendingWorkouts == null && !_showPaywallButton)
              _buildQuickSuggestions(langCode),

            // Preview des workouts générés
            if (_pendingWorkouts != null && _pendingWorkouts!.isNotEmpty)
              _buildWorkoutPreview(langCode),

            // Zone du bas selon l'état
            if (_showPaywallButton)
              _buildPaywallButton(langCode)
            else if (_pendingWorkouts != null && _pendingWorkouts!.isNotEmpty)
              _buildPreviewButtons(langCode)
            else
              _buildInputZone(langCode),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String langCode) {
    final title = widget.initialMode == 'meals'
        ? 'plan_my_meals'.tr(langCode)
        : 'plan_my_workouts'.tr(langCode);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0B132B)),
      ),
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
                    ? 'planner_ai_subtitle'.tr(langCode)
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          controller: _calendarScrollController,
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
              onTap: () => _showAddActivitySheet(date),
              onActivityTap: (activity) {
                if (activity.activityType == PlannedActivityType.cardio) {
                  _showCardioRecap(activity);
                }
              },
              onWorkoutTap: (workout) => _showWorkoutRecap(workout),
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

  Widget _buildTypingIndicator(String langCode) {
    final loadingText = widget.initialMode == 'meals'
        ? (langCode == 'fr' ? 'Ryze prépare ton programme...' : 'Ryze is preparing your plan...')
        : (langCode == 'fr' ? 'Ryze génère tes séances...' : 'Ryze is generating your workouts...');

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
    final suggestions = widget.initialMode == 'meals'
        ? (langCode == 'fr'
            ? ['Petit-déj protéiné', 'Repas équilibrés', 'Déjeuner léger']
            : ['Protein breakfast', 'Balanced meals', 'Light lunch'])
        : (langCode == 'fr'
            ? ['3 séances muscu', 'Programme full body', 'Cardio + muscu']
            : ['3 gym sessions', 'Full body program', 'Cardio + weights']);

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
                  _textController.text = suggestion;
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
    final exercisesLabel = langCode == 'fr' ? 'exercices' : langCode == 'de' ? 'Übungen' : 'exercises';

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
    final personalizedText = {
      'fr': 'Poids personnalisés selon ton historique',
      'en': 'Personalized weights based on your history',
      'de': 'Personalisierte Gewichte basierend auf deinem Verlauf',
    };
    final seriesLabel = langCode == 'fr' ? 'séries' : langCode == 'de' ? 'Sätze' : 'sets';

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
                      personalizedText[langCode] ?? personalizedText['en']!,
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
    final dayNames = {
      'fr': ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
      'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      'de': ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'],
    };
    final days = dayNames[langCode] ?? dayNames['en']!;
    return days[date.weekday - 1];
  }

  Widget _buildPreviewButtons(String langCode) {
    final confirmText = langCode == 'fr' ? 'Valider ce programme' : 'Confirm this program';
    final modifyText = langCode == 'fr' ? 'Modifier' : 'Modify';

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

  Widget _buildPaywallButton(String langCode) {
    final buttonText = langCode == 'fr' ? 'Passer à Premium' : 'Upgrade to Premium';
    final subtitleText = langCode == 'fr' ? 'Planifications illimitées avec Ryze' : 'Unlimited planning with Ryze';

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
