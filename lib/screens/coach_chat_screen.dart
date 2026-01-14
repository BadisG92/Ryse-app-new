import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/coach_chat_models.dart';
import '../services/coach_chat_service.dart';
import '../services/localization_service.dart';
import '../services/subscription_service.dart';
import '../services/translations.dart';
import '../services/weekly_bilan_service.dart';
import '../services/paywall_service.dart';
import '../components/ui/coach_ryze_avatar.dart';
import '../components/ui/chat_message_bubble.dart';
import '../components/ui/microphone_permission_dialog.dart';
import 'paywall_screen.dart';

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
  String _streamingResponse = '';
  CoachRateLimitStatus? _rateLimitStatus;
  bool _showBilanBanner = false;
  bool _localeInitialized = false;

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
    if (mounted) {
      setState(() => _localeInitialized = true);
    }
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
      _streamingResponse = '';
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
              _streamingResponse = displayedText;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _streamingResponse = '';
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

  void _showUpgradeDialog() {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Lock icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.lock,
                  size: 32,
                  color: Color(0xFFFBBF24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'coach_chat_limit_reached'.tr(lang),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B132B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              'coach_chat_limit_reached_message'.tr(lang),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Premium button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaywallScreen(
                        context: PaywallContext.genericUpgrade,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'coach_chat_upgrade_to_premium'.tr(lang),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Later button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'coach_chat_later'.tr(lang),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: false, // We handle keyboard manually for smoother UX
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_showBilanBanner) _buildBilanBanner(),
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.unfocus(), // Dismiss keyboard on tap outside
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMessagesList(),
            ),
          ),
          // Input bar with keyboard-aware padding
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: _buildInputBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBilanBanner() {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;

    final title = lang == 'fr'
        ? 'Ton bilan hebdo est disponible!'
        : lang == 'de'
            ? 'Dein Wochenbericht ist verfügbar!'
            : 'Your weekly summary is available!';

    final buttonText = lang == 'fr'
        ? 'Faire le bilan'
        : lang == 'de'
            ? 'Zusammenfassung starten'
            : 'Start summary';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Panda image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/coach_ryze_ai_chat_nutrition.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Button
          TextButton(
            onPressed: _startWeeklyBilan,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Color(0xFF0B132B),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
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
      _streamingResponse = '';
    });

    try {
      // Stream bilan response directly (no user message displayed)
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
              _streamingResponse = displayedText;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _streamingResponse = '';
        });
      }
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const CoachRyzeAvatar(
            type: CoachRyzeAvatarType.nutritionChat,
            size: CoachRyzeAvatarSize.small,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'coach_ryze'.tr(lang),
                  style: const TextStyle(
                    color: Color(0xFF0B132B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isSending)
                  Text(
                    'coach_chat_typing'.tr(lang),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // N'afficher le compteur que pour les utilisateurs non-premium
        if (_rateLimitStatus != null && !_rateLimitStatus!.isPremium && !SubscriptionService.instance.isPremium)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _rateLimitStatus!.canSendMessage
                  ? const Color(0xFFF1F5F9)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _rateLimitStatus!.displayText,
              style: TextStyle(
                color: _rateLimitStatus!.canSendMessage
                    ? const Color(0xFF64748B)
                    : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
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

  Widget _buildDaySeparator(DateTime date, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _getDayLabel(date, lang),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return _buildWelcomeMessage();
    }

    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      reverse: true, // New messages at bottom, natural scroll behavior
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        // With reverse: true, index 0 is the last message
        final reversedIndex = _messages.length - 1 - index;
        final message = _messages[reversedIndex];
        final needsSeparator = _needsDaySeparator(reversedIndex);

        return Column(
          children: [
            // With reverse, separator comes after the message visually
            ChatMessageBubble(
              message: message,
              isStreaming: _isSending && reversedIndex == _messages.length - 1 && message.isAssistant,
            ),
            if (needsSeparator) _buildDaySeparator(message.createdAt, lang),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeMessage() {
    final locService = Provider.of<LocalizationService>(context);
    final lang = locService.currentLanguageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const CoachRyzeAvatar(
            type: CoachRyzeAvatarType.nutritionChat,
            size: CoachRyzeAvatarSize.xlarge,
          ),
          const SizedBox(height: 24),
          Text(
            'coach_chat_how_can_i_help'.tr(lang),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 32),
          _buildSuggestionChips(lang),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(String lang) {
    final suggestions = [
      'coach_chat_suggestion_dinner'.tr(lang),
      'coach_chat_suggestion_leg_workout'.tr(lang),
      'coach_chat_suggestion_macros'.tr(lang),
      'coach_chat_suggestion_snack'.tr(lang),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions.map((text) {
        return InkWell(
          onTap: () {
            _textController.text = text;
            _sendMessage();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF0B132B),
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputBar() {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        // Only add safe area padding when keyboard is hidden
        bottom: keyboardVisible ? 12 : MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          // Voice button - always show, will prompt for permission on first tap
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.red.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                _isListening ? LucideIcons.micOff : LucideIcons.mic,
                size: 22,
                color: _isListening ? Colors.red : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? 'coach_chat_listening'.tr(lang)
                      : 'coach_chat_message_placeholder'.tr(lang),
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Send button
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      LucideIcons.send,
                      size: 20,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
