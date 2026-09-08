import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../ai/ryze_events.dart';
import '../ai/ryze_tools/ryze_tool.dart';
import '../models/coach_chat_models.dart';
import '../services/coach_chat_service.dart';
import '../design/design.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/weekly_bilan_service.dart';
import '../components/ui/microphone_permission_dialog.dart';

/// Main chat screen for conversation with Coach Ryze
class CoachChatScreen extends StatefulWidget {
  final CoachConversation conversation;

  const CoachChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<CoachMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _showBilanBanner = false;

  /// Les actions que Ryze propose et qui attendent un oui.
  ///
  /// Elles vivent hors de la liste des messages : tant qu'elles ne sont pas
  /// tranchées, elles ne sont rien qui se soit passé.
  final List<RyzePending> _pendingCards = [];

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initLocale();
    _loadConversation();
    _initSpeech();
    _checkBilanBanner();

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

  Future<void> _initLocale() async {
    try {
      await initializeDateFormatting('fr_FR', null);
      await initializeDateFormatting('en_US', null);
      await initializeDateFormatting('de_DE', null);
    } catch (e) {
      // Locale data may already be initialized
    }
    if (mounted) setState(() {});
  }

  Future<void> _checkBilanBanner() async {
    // Note: Test mode is controlled in WeeklyBilanService.kTestMode
    // shouldShowBilanBanner() respects _bilanStartedThisSession flag
    final shouldShow = await WeeklyBilanService.instance.shouldShowBilanBanner();
    if (mounted) {
      setState(() => _showBilanBanner = shouldShow);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _speech.stop();

    // Ce que Ryze retient se relit en quittant la conversation, pas après
    // chaque réponse. Sans attendre : l'écran se ferme, l'extraction suit.
    unawaited(CoachChatService.instance.extractMemoryIfDue());

    super.dispose();
  }

  Future<void> _initSpeech() async {
    // Don't initialize yet - wait for user to tap the mic button
    // This avoids showing permission dialog on screen load
    _speechAvailable = false;
  }

  Future<void> _initSpeechWithPermission() async {
    // Show explanation dialog first
    final shouldContinue = await MicrophonePermissionDialog.showExplanationIfNeeded(
      context,
      isMounted: () => mounted,
    );

    if (!shouldContinue || !mounted) {
      return;
    }

    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      _speechAvailable = false;
    }
  }

  Future<void> _loadConversation() async {
    setState(() => _isLoading = true);

    try {
      await CoachChatService.instance.loadConversation(widget.conversation.id);

      if (mounted) {
        setState(() {
          _messages = List.from(CoachChatService.instance.currentMessages);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // With reverse: true, scroll to 0 to show latest messages
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _textController.clear();
    });

    // Add temporary user message
    final tempUserMessage = CoachMessage.temporary(
      conversationId: widget.conversation.id,
      userId: '',
      content: text,
    );
    setState(() {
      _messages.add(tempUserMessage);
    });
    _scrollToBottom();

    try {
      // La réponse n'est plus seulement du texte : Ryze peut agir au milieu
      // d'une phrase. Chaque nature d'événement a sa place à l'écran.
      String fullResponse = '';
      String displayedText = '';
      bool typing = false;

      /// Ouvre une bulle de frappe si aucune n'attend le texte.
      void openBubble() {
        if (typing) return;
        typing = true;
        fullResponse = '';
        displayedText = '';
        setState(() {
          _messages.add(CoachMessage.streaming(
            conversationId: widget.conversation.id,
            userId: '',
          ));
        });
      }

      /// Ferme la bulle en cours : ce qui suit est d'une autre nature.
      void closeBubble() {
        typing = false;
        if (_messages.isNotEmpty && _messages.last.content.trim().isEmpty) {
          setState(() => _messages.removeLast());
        }
      }

      await for (final event in CoachChatService.instance.streamMessage(text)) {
        if (!mounted) break;

        switch (event) {
          case CoachText(:final text):
            openBubble();
            fullResponse += text;

            // L'effet de frappe : quelques caractères à la fois.
            while (displayedText.length < fullResponse.length && mounted) {
              final charsToAdd = (fullResponse.length - displayedText.length).clamp(1, 3);
              displayedText = fullResponse.substring(0, displayedText.length + charsToAdd);

              setState(() {
                if (_messages.isNotEmpty) {
                  final last = _messages.length - 1;
                  _messages[last] = _messages[last].copyWith(content: displayedText);
                }
              });
              await Future.delayed(const Duration(milliseconds: 15));
            }
            _scrollToBottom();

          case CoachAction(:final summary, :final ok, :final toolName, :final undo):
            closeBubble();
            RyzeFeedback.confirm();
            setState(() {
              _messages.add(CoachMessage.temporary(
                conversationId: widget.conversation.id,
                userId: '',
                content: summary,
              ).copyWith(
                role: MessageRole.assistant,
                metadata: {
                  'kind': 'tool',
                  'name': toolName,
                  'status': ok ? 'done' : 'failed',
                },
              ));
            });
            _scrollToBottom();

            // Ce qui s'est fait sans demander se reprend d'un geste : la barre
            // remplace la carte à valider pour un verre d'eau.
            if (ok && undo != null && mounted) {
              RyzeUndo.show(
                context,
                message: summary,
                undoLabel: 'undo'.tr(LocalizationService.instance.currentLanguageCode),
                onUndo: () async {
                  await undo();
                  if (mounted) setState(() {});
                },
              );
            }

          case CoachAsk(:final pending):
            closeBubble();
            RyzeFeedback.tap();
            setState(() => _pendingCards.add(pending));
            _scrollToBottom();

          case CoachProposals():
            // Une fournée de propositions se feuillette par jour : c'est la
            // mise en scène de l'écran du planificateur. Ici, chaque création
            // arrive déjà en carte, une par une, par `CoachAsk`.
            break;

          case CoachFailure(:final message):
            closeBubble();
            setState(() {
              _messages.add(CoachMessage.temporary(
                conversationId: widget.conversation.id,
                userId: '',
                content: message,
              ).copyWith(role: MessageRole.assistant));
            });
            _scrollToBottom();
        }
      }

      closeBubble();
    } catch (e) {
      if (mounted) {
        RyzeUndo.failed(context, message: 'error_generic'.tr(LocalizationService.instance.currentLanguageCode));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _startListening() async {
    if (_isListening) return;

    // If speech not initialized yet, show permission dialog first
    if (!_speechAvailable) {
      await _initSpeechWithPermission();
      if (!_speechAvailable || !mounted) return;
    }

    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;
    final localeId = lang == 'fr' ? 'fr_FR' : lang == 'de' ? 'de_DE' : 'en_US';

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;

    return Scaffold(
      backgroundColor: RyzeColors.paper,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const OnbBackground(scene: false),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                RyzeChatHeader(
                  title: 'coach_ryze'.tr(lang),
                  subtitle: _isSending ? 'coach_chat_typing'.tr(lang) : null,
                  // Cette conversation couvre la nourriture et le sport :
                  // les deux coachs sont dessus, comme sur la pilule de la
                  // barre du bas.
                  avatars: const [RyzeAssets.sportAvatar, RyzeAssets.nutriAvatar],
                  onBack: () => Navigator.pop(context),
                ),
                if (_showBilanBanner) _buildBilanBanner(),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _focusNode.unfocus(),
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: RyzeColors.ink))
                        : _buildMessagesList(),
                  ),
                ),
                AnimatedPadding(
                  duration: RyzeDurations.enter,
                  curve: RyzeCurves.out,
                  padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: _buildInputBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Le bilan de la semaine : la marque, une phrase, un bouton. La banniere
  /// disait ses trois langues en dur, hors du dictionnaire.
  Widget _buildBilanBanner() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(3.1), context.vw(4.1), 0),
      child: Pressable(
        onTap: _startWeeklyBilan,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
          decoration: BoxDecoration(
            color: RyzeColors.accTint,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.acc),
          ),
          child: Row(
            children: [
              RyzeMark(size: context.vw(5.1), color: RyzeColors.accInk),
              SizedBox(width: context.vw(3.1)),
              Expanded(
                child: Text(
                  'coach_bilan_title'.tr(lang),
                  style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.accInk),
                ),
              ),
              Text(
                'coach_bilan_start'.tr(lang),
                style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.accInk),
              ),
              Icon(LucideIcons.chevronRight, size: context.vw(3.9), color: RyzeColors.accInk),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startWeeklyBilan() async {
    setState(() => _showBilanBanner = false);
    WeeklyBilanService.instance.markBilanStarted();

    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;

    setState(() {
      _isSending = true;
    });

    try {
      // Stream bilan response (pas de message utilisateur visible)
      final stream = CoachChatService.instance.streamBilanResponse(lang);

      // Add streaming placeholder for Ryze's response
      final streamingMessage = CoachMessage.streaming(
        conversationId: widget.conversation.id,
        userId: '',
      );
      setState(() {
        _messages.add(streamingMessage);
      });

      String fullResponse = '';
      String displayedText = '';

      await for (final chunk in stream) {
        if (mounted) {
          fullResponse += chunk;

          // Typing effect
          while (displayedText.length < fullResponse.length && mounted) {
            final charsToAdd = (fullResponse.length - displayedText.length).clamp(1, 3);
            displayedText = fullResponse.substring(0, displayedText.length + charsToAdd);

            setState(() {
              if (_messages.isNotEmpty) {
                final lastIndex = _messages.length - 1;
                _messages[lastIndex] = _messages[lastIndex].copyWith(
                  content: displayedText,
                );
              }
            });

            await Future.delayed(const Duration(milliseconds: 15));
          }

          _scrollToBottom();
        }
      }

      // Reload to get the saved message from DB
      await _loadConversation();

    } catch (e) {
      if (mounted) {
        RyzeUndo.failed(context, message: 'error_generic'.tr(LocalizationService.instance.currentLanguageCode));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }


  /// Get day label for date separator
  String _getDayLabel(DateTime date, String lang) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return 'today'.tr(lang);
    } else if (messageDay == yesterday) {
      return 'yesterday'.tr(lang);
    } else {
      // Format: "Lundi 6 jan" or "Monday, Jan 6"
      try {
        if (lang == 'fr') {
          return DateFormat('EEEE d MMM', 'fr_FR').format(date);
        } else if (lang == 'de') {
          return DateFormat('EEEE, d. MMM', 'de_DE').format(date);
        } else {
          return DateFormat('EEEE, MMM d', 'en_US').format(date);
        }
      } catch (e) {
        // Fallback if locale not initialized
        return DateFormat('yyyy-MM-dd').format(date);
      }
    }
  }

  /// Check if we need a day separator before this message
  bool _needsDaySeparator(int index) {
    if (index == 0) return true;

    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];

    final currentDay = DateTime(
      currentMessage.createdAt.year,
      currentMessage.createdAt.month,
      currentMessage.createdAt.day,
    );
    final previousDay = DateTime(
      previousMessage.createdAt.year,
      previousMessage.createdAt.month,
      previousMessage.createdAt.day,
    );

    return currentDay != previousDay;
  }

  Widget _buildDaySeparator(DateTime date, String lang) => RyzeChatDay(label: _getDayLabel(date, lang));

  Widget _buildMessagesList() {
    final lang = LocalizationService.instance.currentLanguageCode;
    if (_messages.isEmpty) return _buildWelcomeMessage();

    // Les cartes en attente vivent au bas de la liste, après les messages :
    // elles ne sont pas encore de l'histoire.
    final total = _messages.length + _pendingCards.length;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(context.vw(4.1)),
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: total,
      itemBuilder: (context, index) {
        final at = total - 1 - index;

        if (at >= _messages.length) {
          return _buildPendingCard(_pendingCards[at - _messages.length], lang);
        }

        final message = _messages[at];

        // Une action faite se lit d'un coup d'œil : elle n'a pas besoin d'une
        // bulle, qui la ferait passer pour une phrase.
        if (message.isAction) {
          return Column(
            children: [
              if (_needsDaySeparator(at)) _buildDaySeparator(message.createdAt, lang),
              RyzeToolLine(
                label: message.content,
                failed: message.actionStatus == 'failed',
              ),
            ],
          );
        }

        // La date annonce le jour, donc elle passe avant sa première bulle.
        // Posée après, elle s'intercalait entre ce message et le suivant : la
        // liste est inversée, mais chaque élément se lit toujours de haut en bas.
        return Column(
          children: [
            if (_needsDaySeparator(at)) _buildDaySeparator(message.createdAt, lang),
            RyzeBubble(
              text: message.content,
              mine: message.isUser,
              streaming: _isSending && at == _messages.length - 1 && message.isAssistant,
              copyLabel: 'chat_copied'.tr(lang),
              avatar: message.isUser ? null : coachFaceOfDay(message.createdAt),
            ),
          ],
        );
      },
    );
  }

  /// Une action que Ryze propose, à valider ou à refuser.
  Widget _buildPendingCard(RyzePending pending, String lang) => RyzeActionCard(
        key: ValueKey(pending.id),
        title: pending.title,
        detail: pending.detail,
        confirmLabel: pending.confirmLabelKey.tr(lang),
        cancelLabel: 'ryze_cancel'.tr(lang),
        onConfirm: () => _resolveCard(pending, accept: true),
        onCancel: () => _resolveCard(pending, accept: false),
      );

  Future<void> _resolveCard(RyzePending pending, {required bool accept}) async {
    setState(() => _pendingCards.removeWhere((p) => p.id == pending.id));

    if (!accept) {
      CoachChatService.instance.cancelPending(pending.id);
      RyzeFeedback.removed();
      return;
    }

    RyzeFeedback.confirm();
    final done = await CoachChatService.instance.confirmPending(pending.id);
    if (!mounted) return;

    setState(() {
      _messages.add(CoachMessage.temporary(
        conversationId: widget.conversation.id,
        userId: '',
        content: done.summary,
      ).copyWith(
        role: MessageRole.assistant,
        metadata: {
          'kind': 'tool',
          'name': done.toolName,
          'status': done.ok ? 'done' : 'failed',
        },
      ));
    });
    _scrollToBottom();
  }

  /// La conversation vide : le buste, une question, quatre amorces. Le coach
  /// ne parle pas le premier ; il attend, ce qui vaut mieux que de remplir
  /// l'ecran d'un message qu'on n'a pas demande.
  Widget _buildWelcomeMessage() {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.vw(6.2)),
      child: Column(
        children: [
          SizedBox(height: context.vw(8)),
          CoachAvatar(coachFaceOfDay(DateTime.now()), sizeVw: 26),
          SizedBox(height: context.vw(5.1)),
          Text(
            'coach_chat_how_can_i_help'.tr(lang),
            textAlign: TextAlign.center,
            style: RyzeText.display(context, 5.6, weight: FontWeight.w600),
          ),
          SizedBox(height: context.vw(7)),
          _buildSuggestionChips(lang),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(String lang) {
    return RyzeChatChips(
      labels: [
        'coach_chat_suggestion_dinner'.tr(lang),
        'coach_chat_suggestion_leg_workout'.tr(lang),
        'coach_chat_suggestion_macros'.tr(lang),
        'coach_chat_suggestion_snack'.tr(lang),
      ],
      onTap: (text) {
        _textController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildInputBar() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _textController,
      builder: (context, value, _) => RyzeChatInput(
        controller: _textController,
        focusNode: _focusNode,
        hint: _isListening ? 'coach_chat_listening'.tr(lang) : 'coach_chat_message_placeholder'.tr(lang),
        canSend: value.text.trim().isNotEmpty,
        busy: _isSending,
        listening: _isListening,
        onMic: _isListening ? _stopListening : _startListening,
        onSend: _sendMessage,
      ),
    );
  }
}
