import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/planner_ai_service.dart';
import '../../services/paywall_service.dart';
import '../../services/unified_subscription_service.dart';
import '../../services/food_entries_service.dart';
import '../../services/auth_service.dart';

/// Bottom sheet pour planifier avec l'IA (Ryze)
class PlannerAIBottomSheet extends StatefulWidget {
  final WeeklyPlannerData weekData;
  final VoidCallback onPlanningComplete;
  final String? initialMode; // 'meals' ou 'workouts'

  const PlannerAIBottomSheet({
    super.key,
    required this.weekData,
    required this.onPlanningComplete,
    this.initialMode,
  });

  @override
  State<PlannerAIBottomSheet> createState() => _PlannerAIBottomSheetState();
}

/// Type d'action en cours (pour le message de chargement)
enum _LoadingAction {
  thinking,    // Réflexion générique
  planning,    // Planification de repas/séances
  deleting,    // Suppression
  modifying,   // Modification
  confirming,  // Confirmation d'action
}

class _PlannerAIBottomSheetState extends State<PlannerAIBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isProcessing = false;
  _LoadingAction _currentAction = _LoadingAction.thinking;

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

  // Undo tracking - index du message qui peut être annulé (-1 = aucun)
  int _undoableMessageIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadFreeUsageStatus();
    // Effacer l'historique pour une nouvelle conversation
    PlannerAIService.clearHistory();
    // Message d'accueil
    _addBotMessage(_getWelcomeMessage());

    // Scroll to bottom when keyboard opens
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Delay to let keyboard animation complete
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
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

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll vers le bas pour afficher le dernier message
  /// Avec reverse: true, scroll vers 0 = messages récents (en bas visuellement)
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Avec reverse: true, 0 = bas de la liste (messages récents)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getWelcomeMessage() {
    final locService = LocalizationService.instance;
    final langCode = locService.currentLanguageCode;

    // Messages spécifiques selon le mode
    if (widget.initialMode == 'meals') {
      return 'planner_welcome_meals'.tr(langCode);
    }

    if (widget.initialMode == 'workouts') {
      return 'planner_welcome_sport'.tr(langCode);
    }

    // Message générique (fallback)
    return 'planner_welcome_both'.tr(langCode);
  }

  void _addBotMessage(String text) {
    setState(() {
      // Effacer l'état undoable du message précédent
      _undoableMessageIndex = -1;
      _messages.add(_ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  /// Ajoute un message de succès avec possibilité d'annuler
  void _addUndoableBotMessage(String text) {
    setState(() {
      // Effacer l'état undoable précédent
      _undoableMessageIndex = _messages.length; // Le prochain index
      _messages.add(_ChatMessage(text: text, isUser: false, isUndoable: true));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      // Quand l'utilisateur envoie un message, l'undo n'est plus possible
      _undoableMessageIndex = -1;
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  /// Ajoute un message de confirmation avec boutons inline (style ChatGPT/Claude)
  void _addConfirmationMessage(String description) {
    final langCode = LocalizationService.instance.currentLanguageCode;

    setState(() {
      _pendingConfirmation = {'description': description}; // Garder pour tracking
      _messages.add(_ChatMessage(
        text: description,
        isUser: false,
        actions: [
          _ChatAction(
            label: 'planner_cancel'.tr(langCode),
            onTap: _cancelConfirmation,
            isDestructive: false,
          ),
          _ChatAction(
            label: 'planner_confirm'.tr(langCode),
            onTap: _executeConfirmation,
            isDestructive: true,
          ),
        ],
      ));
    });
    _scrollToBottom();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isProcessing) return;

    _addUserMessage(text);
    _textController.clear();
    _focusNode.unfocus();

    // Si une confirmation était en attente, la supprimer (l'utilisateur a envoyé autre chose)
    if (_pendingConfirmation != null) {
      // Supprimer le dernier message (celui avec les boutons de confirmation)
      if (_messages.isNotEmpty && _messages.last.actions != null) {
        setState(() {
          _messages.removeLast();
        });
      }
      _pendingConfirmation = null;
    }

    // Détecter l'action en cours à partir du texte
    final lowerText = text.toLowerCase();
    _LoadingAction detectedAction = _LoadingAction.thinking;

    if (lowerText.contains('suppr') || lowerText.contains('delete') ||
        lowerText.contains('enlev') || lowerText.contains('retir') ||
        lowerText.contains('annul') || lowerText.contains('cancel') ||
        lowerText.contains('remove') || lowerText.contains('efface') ||
        lowerText.contains('vider') || lowerText.contains('clear')) {
      detectedAction = _LoadingAction.deleting;
    } else if (lowerText.contains('modif') || lowerText.contains('change') ||
               lowerText.contains('edit') || lowerText.contains('déplac') ||
               lowerText.contains('move') || lowerText.contains('remplace')) {
      detectedAction = _LoadingAction.modifying;
    } else if (widget.initialMode == 'meals' || widget.initialMode == 'workouts') {
      detectedAction = _LoadingAction.planning;
    }

    setState(() {
      _isProcessing = true;
      _currentAction = detectedAction;
      _pendingWorkouts = null; // Reset preview
    });
    _scrollToBottom(); // Scroll pour voir le typing indicator

    try {
      // Utiliser le service IA avec function calling pour la planification
      final result = await PlannerAIService.processRequestWithTools(
        text,
        mode: widget.initialMode,
      );

      if (result.isPaywallRequired) {
        // Limite atteinte - afficher message et bouton paywall
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);
        setState(() => _showPaywallButton = true);
      } else if (result.requiresConfirmation && result.pendingWorkouts != null) {
        // Mode preview - afficher les workouts à valider
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);
        setState(() {
          _pendingWorkouts = result.pendingWorkouts;
        });
      } else if (result.requiresConfirmation && result.pendingWorkouts == null) {
        // Mode confirmation pour actions destructrices (delete) - style ChatGPT/Claude
        _addConfirmationMessage(result.message);
      } else if (result.success) {
        _addBotMessage(result.message);
        PlannerAIService.addToHistory('assistant', result.message);

        // Toujours notifier le parent pour rafraîchir le calendrier
        // (même pour les suppressions qui ne créent pas d'items)
        widget.onPlanningComplete();
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

    setState(() {
      _isConfirming = true;
      _isProcessing = true;
      _currentAction = _LoadingAction.confirming;
    });

    try {
      final result = await PlannerAIService.confirmWorkouts(_pendingWorkouts!);

      _addBotMessage(result.message);
      PlannerAIService.addToHistory('assistant', result.message);

      if (result.success) {
        PlannerAIService.clearHistory(); // Nouvelle conversation après succès
        widget.onPlanningComplete();
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
        setState(() {
          _isConfirming = false;
          _isProcessing = false;
        });
      }
    }
  }

  void _cancelPreview() {
    final langCode = LocalizationService.instance.currentLanguageCode;

    setState(() {
      _pendingWorkouts = null;
    });

    _addBotMessage('planner_cancel_preview_msg'.tr(langCode));
  }

  /// Annuler la confirmation d'action destructrice
  void _cancelConfirmation() {
    PlannerAIService.cancelPendingAction();
    final langCode = LocalizationService.instance.currentLanguageCode;

    setState(() {
      // Remplacer le dernier message (avec actions) par un message sans actions
      if (_messages.isNotEmpty && _messages.last.actions != null) {
        _messages.removeLast();
      }
      _pendingConfirmation = null;
    });
    _addBotMessage('planner_action_cancelled'.tr(langCode));
  }

  /// Exécuter l'action destructrice après confirmation
  Future<void> _executeConfirmation() async {
    if (_isConfirming || _pendingConfirmation == null) return;

    try {
      // Remplacer le message avec actions par un indicateur de chargement
      setState(() {
        _isConfirming = true;
        _isProcessing = true;
        _currentAction = _LoadingAction.deleting;
        if (_messages.isNotEmpty && _messages.last.actions != null) {
          _messages.removeLast();
        }
      });

      final result = await PlannerAIService.executePendingAction();

      // Ajouter le message de résultat avec ou sans bouton undo
      // Note: Si d'autres actions suivent, l'undo sera remplacé par le suivant
      if (result.canUndo && result.success) {
        _addUndoableBotMessage(result.message);
      } else {
        _addBotMessage(result.message);
      }
      PlannerAIService.addToHistory('assistant', result.message);

      if (result.success) {
        widget.onPlanningComplete();
      }

      // S'il y a d'autres actions en attente avec confirmation requise
      if (result.hasMoreActions && result.requiresConfirmation && result.nextActionDescription != null) {
        // Afficher la prochaine confirmation comme un message SÉPARÉ
        _addConfirmationMessage(result.nextActionDescription!);
      } else if (result.hasMoreActions && result.nextActionDescription != null) {
        // Action suivante sans confirmation - déjà exécutée, afficher le résultat
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
        setState(() {
          _isConfirming = false;
          _isProcessing = false;
        });
      }
    }
  }

  void _showPaywall() {
    Navigator.pop(context);
    PaywallService().showPaywall(
      context: context,
      paywallContext: PaywallContext.workoutGenerator,
    );
  }

  String _generateMockResponse(String userInput) {
    final locService = LocalizationService.instance;
    final langCode = locService.currentLanguageCode;

    // Détection simple d'intent
    final lowerInput = userInput.toLowerCase();

    if (lowerInput.contains('séance') ||
        lowerInput.contains('workout') ||
        lowerInput.contains('training') ||
        lowerInput.contains('musculation') ||
        lowerInput.contains('sport')) {
      final responses = {
        'fr':
            "Super ! Quel type de séances veux-tu ?\n\n• Full Body\n• Haut du corps\n• Bas du corps\n• Push/Pull/Legs\n\nEt quelle durée par séance ?",
        'en':
            "Great! What type of sessions do you want?\n\n• Full Body\n• Upper body\n• Lower body\n• Push/Pull/Legs\n\nAnd how long per session?",
        'de':
            "Super! Welche Art von Training möchtest du?\n\n• Ganzkörper\n• Oberkörper\n• Unterkörper\n• Push/Pull/Legs\n\nUnd wie lange pro Einheit?",
      };
      return responses[langCode] ?? responses['en']!;
    }

    if (lowerInput.contains('repas') ||
        lowerInput.contains('meal') ||
        lowerInput.contains('mahlzeit') ||
        lowerInput.contains('petit-déjeuner') ||
        lowerInput.contains('breakfast') ||
        lowerInput.contains('déjeuner') ||
        lowerInput.contains('lunch') ||
        lowerInput.contains('dîner') ||
        lowerInput.contains('dinner')) {
      final responses = {
        'fr':
            "Parfait ! Décris-moi le repas que tu veux planifier.\n\nPar exemple : \"4 oeufs et des tartines pour le petit-déjeuner du mardi\"",
        'en':
            "Perfect! Describe the meal you want to plan.\n\nFor example: \"4 eggs and toast for Tuesday's breakfast\"",
        'de':
            "Perfekt! Beschreibe mir die Mahlzeit, die du planen möchtest.\n\nZum Beispiel: \"4 Eier und Toast für das Frühstück am Dienstag\"",
      };
      return responses[langCode] ?? responses['en']!;
    }

    if (lowerInput.contains('cardio') ||
        lowerInput.contains('course') ||
        lowerInput.contains('running') ||
        lowerInput.contains('vélo') ||
        lowerInput.contains('bike') ||
        lowerInput.contains('marche') ||
        lowerInput.contains('walk')) {
      final responses = {
        'fr':
            "Génial ! Quel type de cardio veux-tu faire ?\n\n• Course\n• Vélo\n• Marche\n• Natation\n• HIIT\n\nEt quel objectif ? (temps ou distance)",
        'en':
            "Great! What type of cardio do you want to do?\n\n• Running\n• Cycling\n• Walking\n• Swimming\n• HIIT\n\nAnd what's your goal? (time or distance)",
        'de':
            "Toll! Welche Art von Cardio möchtest du machen?\n\n• Laufen\n• Radfahren\n• Gehen\n• Schwimmen\n• HIIT\n\nUnd welches Ziel? (Zeit oder Distanz)",
      };
      return responses[langCode] ?? responses['en']!;
    }

    // Réponse par défaut
    final defaultResponses = {
      'fr':
          "Je n'ai pas bien compris. Peux-tu préciser ce que tu veux planifier ?\n\n• Des séances de sport\n• Tes repas\n• Du cardio",
      'en':
          "I didn't quite understand. Can you specify what you want to plan?\n\n• Workout sessions\n• Your meals\n• Cardio",
      'de':
          "Ich habe nicht ganz verstanden. Kannst du präzisieren, was du planen möchtest?\n\n• Trainingseinheiten\n• Deine Mahlzeiten\n• Cardio",
    };
    return defaultResponses[langCode] ?? defaultResponses['en']!;
  }

  String _getErrorMessage() {
    final locService = LocalizationService.instance;
    final langCode = locService.currentLanguageCode;
    return 'planner_error_generic'.tr(langCode);
  }

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final langCode = locService.currentLanguageCode;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Hauteur FIXE - pattern iMessage/WhatsApp
    // Le clavier pousse la zone input, pas le container
    final sheetHeight = screenHeight * 0.55;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
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
          _buildHeader(context, langCode),

          // Messages (avec reverse: true pour pattern chat)
          Expanded(
            child: _buildMessagesList(),
          ),

          // Suggestions rapides (cachées si paywall ou preview)
          if (!_showPaywallButton && _pendingWorkouts == null) _buildQuickSuggestions(langCode),

          // Preview des workouts
          if (_pendingWorkouts != null)
            _buildWorkoutPreview(langCode),

          // Paywall, Preview buttons, ou Input zone
          // Le padding du clavier est appliqué uniquement sur la zone input
          if (_showPaywallButton)
            _buildPaywallButton(langCode)
          else if (_pendingWorkouts != null)
            _buildPreviewButtons(langCode)
          else
            Padding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: _buildInputZone(langCode),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPreview(String langCode) {
    if (_pendingWorkouts == null || _pendingWorkouts!.isEmpty) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.eye,
                  size: 16,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  _getPreviewTitle(langCode),
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
              color: const Color(0xFF0B132B).withOpacity(0.1),
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
                  '${workout.durationMinutes} min • $exerciseCount exercices',
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
                      color: const Color(0xFF0B132B).withOpacity(0.1),
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
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 14,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPersonalizedWeightsText(langCode),
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
                  // Récupérer le poids suggéré depuis le premier set
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
                            color: const Color(0xFF0B132B).withOpacity(0.1),
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
                                '${exercise.sets.length} séries • ${exercise.suggestedRepsMin ?? 8}-${exercise.suggestedRepsMax ?? 12} reps${weightText.isNotEmpty ? ' • $weightText' : ''}',
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

  Widget _buildPreviewButtons(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bouton Modifier
            Expanded(
              child: OutlinedButton(
                onPressed: _isConfirming ? null : _cancelPreview,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('planner_modify'.tr(langCode)),
              ),
            ),
            const SizedBox(width: 12),
            // Bouton Valider
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isConfirming ? null : _confirmWorkouts,
                icon: _isConfirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.check, size: 18),
                label: Text('planner_confirm_program'.tr(langCode)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewTitle(String langCode) {
    return 'planner_preview_title'.tr(langCode);
  }

  String _formatDayName(DateTime date, String langCode) {
    return 'day_${date.weekday}'.tr(langCode);
  }

  String _getPersonalizedWeightsText(String langCode) {
    return 'planner_personalized_weights'.tr(langCode);
  }

  Widget _buildPaywallButton(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Text(
              'planner_unlimited_planning'.tr(langCode),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showPaywall,
                icon: const Icon(LucideIcons.crown, size: 18),
                label: Text('planner_upgrade_premium'.tr(langCode)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          // Image des pandas qui se check
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/coach_ryze_contract.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getHeaderTitle(langCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),
                // Afficher selon le mode
                Text(
                  _isPremium
                      ? 'planner_ai_subtitle'.tr(langCode)
                      : _isTestMode
                          ? 'planner_test_mode'.tr(langCode)
                          : _getRemainingUsesText(langCode),
                  style: TextStyle(
                    fontSize: 13,
                    color: _isPremium || _isTestMode || _remainingFreeUses > 0
                        ? const Color(0xFF64748B)
                        : const Color(0xFFEF4444),
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
    );
  }

  String _getHeaderTitle(String langCode) {
    if (widget.initialMode == 'meals') {
      return 'plan_my_meals'.tr(langCode);
    }
    if (widget.initialMode == 'workouts') {
      return 'plan_my_workouts'.tr(langCode);
    }
    return 'plan_with_ryze'.tr(langCode);
  }

  String _getPlaceholder(String langCode) {
    if (widget.initialMode == 'meals') {
      return 'planner_meals_placeholder'.tr(langCode);
    }
    if (widget.initialMode == 'workouts') {
      return 'planner_workouts_placeholder'.tr(langCode);
    }
    return 'planner_ai_placeholder'.tr(langCode);
  }

  String _getRemainingUsesText(String langCode) {
    if (_remainingFreeUses <= 0) {
      return 'planner_limit_reached'.tr(langCode);
    }

    if (_remainingFreeUses == 1) {
      return 'planner_remaining_one'.tr(langCode);
    }

    return '$_remainingFreeUses ${'planner_remaining_multiple'.tr(langCode)}';
  }

  Widget _buildMessagesList() {
    final itemCount = _messages.length + (_isProcessing ? 1 : 0);

    return GestureDetector(
      onTap: () => _focusNode.unfocus(), // Dismiss keyboard on tap outside
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        reverse: true, // Pattern iMessage/WhatsApp - nouveaux messages en bas
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Avec reverse: true, index 0 = bas de la liste
          // Typing indicator en premier (en bas)
          if (_isProcessing && index == 0) {
            return _buildTypingIndicator();
          }

          // Ajuster l'index pour les messages
          final messageIndex = _isProcessing ? index - 1 : index;
          final actualIndex = _messages.length - 1 - messageIndex;
          return _buildMessageBubble(_messages[actualIndex], actualIndex);
        },
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, int index) {
    // Vérifier si ce message peut être annulé (dernier undoable et index correspond)
    final bool canUndo = message.isUndoable && index == _undoableMessageIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
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
                  // Actions inline (style ChatGPT/Claude)
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
          // Bouton undo à droite des messages de validation
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

  /// Exécuter l'annulation de la dernière action
  Future<void> _executeUndo(int messageIndex) async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    try {
      final result = await PlannerAIService.undoLastAction();

      setState(() {
        // Désactiver le bouton undo de ce message
        _undoableMessageIndex = -1;
      });

      _addBotMessage(result.message);
      PlannerAIService.addToHistory('assistant', result.message);

      if (result.success) {
        widget.onPlanningComplete();
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

  Widget _buildTypingIndicator() {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final loadingText = _getLoadingMessage(langCode);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFF0B132B).withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      loadingText,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
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

  String _getLoadingMessage(String langCode) {
    // Messages différents selon l'action en cours
    switch (_currentAction) {
      case _LoadingAction.deleting:
        return 'planner_ai_deleting'.tr(langCode);
      case _LoadingAction.modifying:
        return 'planner_ai_modifying'.tr(langCode);
      case _LoadingAction.confirming:
        return 'planner_ai_confirming'.tr(langCode);
      case _LoadingAction.planning:
        // Selon le mode initial
        if (widget.initialMode == 'meals') {
          return 'planner_ai_preparing_meal'.tr(langCode);
        }
        if (widget.initialMode == 'workouts') {
          return 'planner_ai_generating_workouts'.tr(langCode);
        }
        return 'planner_ai_thinking'.tr(langCode);
      case _LoadingAction.thinking:
        return 'planner_ai_thinking'.tr(langCode);
    }
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFCBD5E1),
              const Color(0xFF64748B),
              (value + index * 0.3) % 1,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
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
                onTap: () async {
                  // Pour le mode meals, récupérer les repas logués et transformer le prompt
                  if (widget.initialMode == 'meals') {
                    final loggedMeals = await _getLoggedMealTypesToday();
                    final prompt = _transformQuickSuggestionToPrompt(suggestion, langCode, loggedMeals);
                    _textController.text = prompt;
                  } else {
                    _textController.text = suggestion;
                  }
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
    // Suggestions spécifiques selon le mode
    if (widget.initialMode == 'meals') {
      return [
        'suggestion_next_meal'.tr(langCode),
        'suggestion_today'.tr(langCode),
        'suggestion_week'.tr(langCode),
      ];
    }

    if (widget.initialMode == 'workouts') {
      return [
        'suggestion_3_workouts'.tr(langCode),
        'suggestion_fullbody'.tr(langCode),
        'suggestion_cardio_strength'.tr(langCode),
      ];
    }

    // Suggestions génériques (fallback)
    return [
      'suggestion_3_sports'.tr(langCode),
      'suggestion_week_meals'.tr(langCode),
      'suggestion_cardio_tuesday'.tr(langCode),
    ];
  }

  /// Récupérer les types de repas déjà logués aujourd'hui dans le journal
  Future<List<String>> _getLoggedMealTypesToday() async {
    try {
      final user = AuthService().currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final todayMeals = await FoodEntriesService.getFoodEntriesForDate(user.id, now);

      final loggedTypes = <String>{};
      for (final meal in todayMeals) {
        if (meal.items.isNotEmpty && meal.mealType != null) {
          loggedTypes.add(meal.mealType!);
        }
      }

      return loggedTypes.toList();
    } catch (e) {
      debugPrint('❌ _getLoggedMealTypesToday error: $e');
      return [];
    }
  }

  /// Transforme les boutons rapides en prompts optimisés pour l'IA
  /// Prend en compte les repas déjà logués pour ne pas les redemander
  String _transformQuickSuggestionToPrompt(String suggestion, String langCode, List<String> loggedMeals) {
    final now = DateTime.now();
    final hour = now.hour;

    // Déterminer le prochain repas NON LOGUÉ selon l'heure
    String? nextMealType;
    if (hour < 10 && !loggedMeals.contains('breakfast')) {
      nextMealType = langCode == 'fr' ? 'petit-déjeuner' : langCode == 'de' ? 'Frühstück' : 'breakfast';
    } else if (hour < 14 && !loggedMeals.contains('lunch')) {
      nextMealType = langCode == 'fr' ? 'déjeuner' : langCode == 'de' ? 'Mittagessen' : 'lunch';
    } else if (hour < 21 && !loggedMeals.contains('dinner')) {
      nextMealType = langCode == 'fr' ? 'dîner' : langCode == 'de' ? 'Abendessen' : 'dinner';
    } else if (!loggedMeals.contains('snack')) {
      nextMealType = langCode == 'fr' ? 'collation' : langCode == 'de' ? 'Snack' : 'snack';
    }

    // Si tous les repas sont logués, suggérer pour demain
    if (nextMealType == null) {
      nextMealType = langCode == 'fr' ? 'petit-déjeuner de demain' : langCode == 'de' ? 'Frühstück morgen' : 'tomorrow\'s breakfast';
    }

    // Pour "Aujourd'hui", lister seulement les repas NON logués
    final mealTypesForToday = <String>[];
    if (!loggedMeals.contains('breakfast')) {
      mealTypesForToday.add(langCode == 'fr' ? 'petit-déjeuner' : langCode == 'de' ? 'Frühstück' : 'breakfast');
    }
    if (!loggedMeals.contains('lunch')) {
      mealTypesForToday.add(langCode == 'fr' ? 'déjeuner' : langCode == 'de' ? 'Mittagessen' : 'lunch');
    }
    if (!loggedMeals.contains('dinner')) {
      mealTypesForToday.add(langCode == 'fr' ? 'dîner' : langCode == 'de' ? 'Abendessen' : 'dinner');
    }

    // Si aucun repas restant aujourd'hui, proposer demain
    String todayPrompt;
    if (mealTypesForToday.isEmpty) {
      todayPrompt = langCode == 'fr'
          ? 'Tous mes repas sont déjà logués aujourd\'hui. Planifie mes repas pour demain'
          : langCode == 'de'
              ? 'Alle meine Mahlzeiten sind heute schon protokolliert. Plane meine Mahlzeiten für morgen'
              : 'All my meals are already logged today. Plan my meals for tomorrow';
    } else {
      final mealsJoined = mealTypesForToday.join(', ');
      todayPrompt = langCode == 'fr'
          ? 'Planifie mes repas restants pour aujourd\'hui ($mealsJoined)'
          : langCode == 'de'
              ? 'Plane meine restlichen Mahlzeiten für heute ($mealsJoined)'
              : 'Plan my remaining meals for today ($mealsJoined)';
    }

    // Prompts optimisés par langue
    final prompts = {
      // Français
      '🍽️ Prochain repas': 'Propose-moi un $nextMealType équilibré',
      '📅 Aujourd\'hui': todayPrompt,
      '📆 La semaine': 'Planifie tous mes repas pour toute la semaine (petit-déjeuner, déjeuner et dîner pour chaque jour)',
      // English
      '🍽️ Next meal': 'Suggest a balanced $nextMealType',
      '📅 Today': todayPrompt,
      '📆 The week': 'Plan all my meals for the entire week (breakfast, lunch and dinner for each day)',
      // Deutsch
      '🍽️ Nächste Mahlzeit': 'Schlage mir ein ausgewogenes $nextMealType vor',
      '📅 Heute': todayPrompt,
      '📆 Die Woche': 'Plane alle meine Mahlzeiten für die ganze Woche (Frühstück, Mittagessen und Abendessen für jeden Tag)',
    };

    return prompts[suggestion] ?? suggestion;
  }

  Widget _buildInputZone(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      // Plus de SafeArea ici - le padding clavier est géré au niveau parent
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
                    hintText: _getPlaceholder(langCode),
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0B132B),
                  ),
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
                  color: _isProcessing
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF0B132B),
                  shape: BoxShape.circle,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF64748B),
                        ),
                      )
                    : const Icon(
                        LucideIcons.send,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
    );
  }
}

/// Modèle pour un message de chat
class _ChatMessage {
  final String text;
  final bool isUser;
  final List<_ChatAction>? actions; // Actions inline (style ChatGPT/Claude)
  final bool isUndoable; // Si ce message peut être annulé (bouton undo à droite)

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.actions,
    this.isUndoable = false,
  });
}

/// Action cliquable dans un message (style ChatGPT/Claude)
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
