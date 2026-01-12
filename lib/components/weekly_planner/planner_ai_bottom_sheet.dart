import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/planner_ai_service.dart';
import '../../services/paywall_service.dart';
import '../../services/unified_subscription_service.dart';

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

class _PlannerAIBottomSheetState extends State<PlannerAIBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isProcessing = false;

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
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll vers le bas pour afficher le dernier message
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
      final messages = {
        'fr': "Salut ! Je suis Ryze, ton coach nutrition. Dis-moi quels repas tu veux planifier cette semaine.\n\nPar exemple :\n• \"Un petit-déjeuner protéiné pour lundi\"\n• \"Des repas équilibrés pour la semaine\"\n• \"Un déjeuner healthy mardi\"",
        'en': "Hi! I'm Ryze, your nutrition coach. Tell me which meals you want to plan this week.\n\nFor example:\n• \"A protein breakfast for Monday\"\n• \"Balanced meals for the week\"\n• \"A healthy lunch on Tuesday\"",
        'de': "Hallo! Ich bin Ryze, dein Ernährungscoach. Sag mir, welche Mahlzeiten du diese Woche planen möchtest.\n\nZum Beispiel:\n• \"Ein proteinreiches Frühstück für Montag\"\n• \"Ausgewogene Mahlzeiten für die Woche\"\n• \"Ein gesundes Mittagessen am Dienstag\"",
      };
      return messages[langCode] ?? messages['en']!;
    }

    if (widget.initialMode == 'workouts') {
      final messages = {
        'fr': "Salut ! Je suis Ryze, ton coach fitness. Dis-moi quelles séances tu veux planifier cette semaine.\n\nPar exemple :\n• \"3 séances de musculation\"\n• \"Un programme full body\"\n• \"Du cardio et de la muscu\"",
        'en': "Hi! I'm Ryze, your fitness coach. Tell me which workouts you want to plan this week.\n\nFor example:\n• \"3 strength training sessions\"\n• \"A full body program\"\n• \"Cardio and weight training\"",
        'de': "Hallo! Ich bin Ryze, dein Fitnesscoach. Sag mir, welche Trainings du diese Woche planen möchtest.\n\nZum Beispiel:\n• \"3 Krafttrainingseinheiten\"\n• \"Ein Ganzkörperprogramm\"\n• \"Cardio und Krafttraining\"",
      };
      return messages[langCode] ?? messages['en']!;
    }

    // Message générique (fallback)
    final messages = {
      'fr': "Salut ! Je suis Ryze, ton coach. Dis-moi ce que tu veux planifier cette semaine :\n\n• Des séances de sport\n• Tes repas\n• Du cardio\n\nPar exemple : \"Je veux 3 séances de musculation cette semaine\"",
      'en': "Hi! I'm Ryze, your coach. Tell me what you want to plan this week:\n\n• Workout sessions\n• Your meals\n• Cardio\n\nFor example: \"I want 3 strength training sessions this week\"",
      'de': "Hallo! Ich bin Ryze, dein Coach. Sag mir, was du diese Woche planen möchtest:\n\n• Trainingseinheiten\n• Deine Mahlzeiten\n• Cardio\n\nZum Beispiel: \"Ich möchte 3 Krafttrainingseinheiten diese Woche\"",
    };

    return messages[langCode] ?? messages['en']!;
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
    final confirmText = {
      'fr': 'Confirmer',
      'en': 'Confirm',
      'de': 'Bestätigen',
    };
    final cancelText = {
      'fr': 'Annuler',
      'en': 'Cancel',
      'de': 'Abbrechen',
    };

    setState(() {
      _pendingConfirmation = {'description': description}; // Garder pour tracking
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

    setState(() {
      _isProcessing = true;
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

    setState(() => _isConfirming = true);

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

  /// Annuler la confirmation d'action destructrice
  void _cancelConfirmation() {
    PlannerAIService.cancelPendingAction();
    final langCode = LocalizationService.instance.currentLanguageCode;
    final cancelledText = {
      'fr': '❌ Action annulée',
      'en': '❌ Action cancelled',
      'de': '❌ Aktion abgebrochen',
    };

    setState(() {
      // Remplacer le dernier message (avec actions) par un message sans actions
      if (_messages.isNotEmpty && _messages.last.actions != null) {
        _messages.removeLast();
      }
      _pendingConfirmation = null;
    });
    _addBotMessage(cancelledText[langCode] ?? cancelledText['en']!);
  }

  /// Exécuter l'action destructrice après confirmation
  Future<void> _executeConfirmation() async {
    if (_isConfirming || _pendingConfirmation == null) return;
    setState(() => _isConfirming = true);

    try {
      // Remplacer le message avec actions par un indicateur de chargement
      setState(() {
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
        setState(() => _isConfirming = false);
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

    final messages = {
      'fr': "Oups, une erreur s'est produite. Réessaie !",
      'en': "Oops, an error occurred. Try again!",
      'de': "Hoppla, ein Fehler ist aufgetreten. Versuche es erneut!",
    };

    return messages[langCode] ?? messages['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final langCode = locService.currentLanguageCode;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Hauteur réduite pour voir le calendrier (50% ou 55% avec le clavier)
    final sheetHeight = bottomPadding > 0
        ? screenHeight * 0.55 // Plus grand avec le clavier pour avoir de l'espace
        : screenHeight * 0.50; // 50% sans clavier pour voir le calendrier

    return Container(
      height: sheetHeight,
      padding: EdgeInsets.only(bottom: bottomPadding),
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

          // Messages
          Expanded(
            child: _buildMessagesList(),
          ),

          // Suggestions rapides (cachées si paywall ou preview)
          if (!_showPaywallButton && _pendingWorkouts == null) _buildQuickSuggestions(langCode),

          // Preview des workouts
          if (_pendingWorkouts != null)
            _buildWorkoutPreview(langCode),

          // Paywall, Preview buttons, ou Input zone
          // Note: Les boutons de confirmation sont maintenant inline dans le message (style ChatGPT/Claude)
          if (_showPaywallButton)
            _buildPaywallButton(langCode)
          else if (_pendingWorkouts != null)
            _buildPreviewButtons(langCode)
          else
            _buildInputZone(langCode),
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
    final confirmText = {
      'fr': 'Valider ce programme',
      'en': 'Confirm this program',
      'de': 'Dieses Programm bestätigen',
    };

    final modifyText = {
      'fr': 'Modifier',
      'en': 'Modify',
      'de': 'Ändern',
    };

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
                child: Text(modifyText[langCode] ?? modifyText['en']!),
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
                label: Text(confirmText[langCode] ?? confirmText['en']!),
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
    switch (langCode) {
      case 'fr':
        return 'Aperçu du programme';
      case 'de':
        return 'Programmvorschau';
      default:
        return 'Program preview';
    }
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

  String _getPersonalizedWeightsText(String langCode) {
    switch (langCode) {
      case 'fr':
        return 'Poids adaptés à ton historique - ajuste si besoin';
      case 'de':
        return 'Gewichte an deinen Verlauf angepasst - bei Bedarf anpassen';
      default:
        return 'Weights adapted to your history - adjust if needed';
    }
  }

  Widget _buildPaywallButton(String langCode) {
    final buttonText = {
      'fr': 'Passer à Premium',
      'en': 'Upgrade to Premium',
      'de': 'Auf Premium upgraden',
    };

    final subtitleText = {
      'fr': 'Planifications illimitées avec Ryze',
      'en': 'Unlimited planning with Ryze',
      'de': 'Unbegrenzte Planungen mit Ryze',
    };

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
              subtitleText[langCode] ?? subtitleText['en']!,
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
                label: Text(buttonText[langCode] ?? buttonText['en']!),
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
                          ? 'Mode test - illimité'
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
      switch (langCode) {
        case 'fr':
          return 'Limite atteinte cette semaine';
        case 'de':
          return 'Limit diese Woche erreicht';
        default:
          return 'Limit reached this week';
      }
    }

    switch (langCode) {
      case 'fr':
        return '$_remainingFreeUses planification${_remainingFreeUses > 1 ? 's' : ''} gratuite${_remainingFreeUses > 1 ? 's' : ''} restante${_remainingFreeUses > 1 ? 's' : ''}';
      case 'de':
        return '$_remainingFreeUses kostenlose Planung${_remainingFreeUses > 1 ? 'en' : ''} übrig';
      default:
        return '$_remainingFreeUses free planning${_remainingFreeUses > 1 ? 's' : ''} left';
    }
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isProcessing) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index], index);
      },
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
    // Messages différents selon le mode
    if (widget.initialMode == 'meals') {
      final messages = {
        'fr': 'Ryze prépare ton programme nutritionnel...',
        'en': 'Ryze is preparing your nutrition plan...',
        'de': 'Ryze bereitet deinen Ernährungsplan vor...',
      };
      return messages[langCode] ?? messages['en']!;
    }

    if (widget.initialMode == 'workouts') {
      final messages = {
        'fr': 'Ryze génère tes séances personnalisées...',
        'en': 'Ryze is generating your personalized workouts...',
        'de': 'Ryze erstellt deine personalisierten Trainings...',
      };
      return messages[langCode] ?? messages['en']!;
    }

    // Message générique
    final messages = {
      'fr': 'Ryze réfléchit...',
      'en': 'Ryze is thinking...',
      'de': 'Ryze denkt nach...',
    };
    return messages[langCode] ?? messages['en']!;
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

  List<String> _getQuickSuggestions(String langCode) {
    // Suggestions spécifiques selon le mode
    if (widget.initialMode == 'meals') {
      final suggestions = {
        'fr': ['Petit-déj protéiné', 'Repas équilibrés', 'Déjeuner léger'],
        'en': ['Protein breakfast', 'Balanced meals', 'Light lunch'],
        'de': ['Protein-Frühstück', 'Ausgewogene Mahlzeiten', 'Leichtes Mittagessen'],
      };
      return suggestions[langCode] ?? suggestions['en']!;
    }

    if (widget.initialMode == 'workouts') {
      final suggestions = {
        'fr': ['3 séances muscu', 'Programme full body', 'Cardio + muscu'],
        'en': ['3 gym sessions', 'Full body program', 'Cardio + weights'],
        'de': ['3 Gym-Sessions', 'Ganzkörper-Programm', 'Cardio + Gewichte'],
      };
      return suggestions[langCode] ?? suggestions['en']!;
    }

    // Suggestions génériques (fallback)
    final suggestions = {
      'fr': ['3 séances de sport', 'Repas de la semaine', 'Cardio mardi'],
      'en': ['3 workout sessions', 'Weekly meals', 'Cardio on Tuesday'],
      'de': ['3 Trainingseinheiten', 'Wöchentliche Mahlzeiten', 'Cardio am Dienstag'],
    };

    return suggestions[langCode] ?? suggestions['en']!;
  }

  Widget _buildInputZone(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
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
