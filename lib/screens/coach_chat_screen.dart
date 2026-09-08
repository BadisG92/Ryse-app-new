import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
  CoachRateLimitStatus? _rateLimitStatus;
  bool _showBilanBanner = false;

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
      final rateLimitStatus = await CoachChatService.instance.getRateLimitStatus();

      if (mounted) {
        setState(() {
          _messages = List.from(CoachChatService.instance.currentMessages);
          _rateLimitStatus = rateLimitStatus;
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

    // Check rate limit
    if (_rateLimitStatus != null && !_rateLimitStatus!.canSendMessage) {
      _showUpgradeDialog();
      return;
    }

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
      // Use streaming for better UX
      final stream = CoachChatService.instance.streamMessage(text);

      // Add streaming placeholder
      final streamingMessage = CoachMessage.streaming(
        conversationId: widget.conversation.id,
        userId: '',
      );
      setState(() {
        _messages.add(streamingMessage);
      });

      // Buffer to accumulate chunks and display with typing effect
      String fullResponse = '';
      String displayedText = '';

      await for (final chunk in stream) {
        if (mounted) {
          fullResponse += chunk;

          // Typing effect: display characters progressively
          while (displayedText.length < fullResponse.length && mounted) {
            // Add characters in small batches for smoother effect
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

            // Small delay for typing effect (15ms per batch of chars)
            await Future.delayed(const Duration(milliseconds: 15));
          }

          _scrollToBottom();
        }
      }

      // Update rate limit status without reloading messages
      final rateLimitStatus = await CoachChatService.instance.getRateLimitStatus();
      if (mounted) {
        setState(() {
          _rateLimitStatus = rateLimitStatus;
        });
      }
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
    final localeId = locService.currentLanguageCode == 'fr' ? 'fr_FR' : 'en_US';

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

  /// La limite d'echanges, si le service la renvoie un jour : une feuille et
  /// non un dialogue, et pas un mot sur des essais qui n'existent plus.
  void _showUpgradeDialog() {
    final lang = LocalizationService.instance.currentLanguageCode;
    showRyzeSheet<void>(
      context,
      title: 'coach_limit_title'.tr(lang),
      builder: (sheet) => Text(
        'coach_limit_body'.tr(lang),
        style: RyzeText.body(sheet, 3.6, height: 1.5, color: RyzeColors.mute),
      ),
      actions: [OnbButton(label: 'ok'.tr(lang), onPressed: () => Navigator.pop(context))],
    );
  }

  @override
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
      return lang == 'fr' ? "Aujourd'hui" : lang == 'de' ? 'Heute' : 'Today';
    } else if (messageDay == yesterday) {
      return lang == 'fr' ? 'Hier' : lang == 'de' ? 'Gestern' : 'Yesterday';
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

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(context.vw(4.1)),
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final at = _messages.length - 1 - index;
        final message = _messages[at];
        return Column(
          children: [
            RyzeBubble(
              text: message.content,
              mine: message.isUser,
              streaming: _isSending && at == _messages.length - 1 && message.isAssistant,
              copyLabel: 'chat_copied'.tr(lang),
            ),
            if (_needsDaySeparator(at)) _buildDaySeparator(message.createdAt, lang),
          ],
        );
      },
    );
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
          const CoachAvatar(RyzeAssets.nutriAvatar, sizeVw: 26),
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
