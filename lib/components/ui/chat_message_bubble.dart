import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/coach_chat_models.dart';
import '../../services/localization_service.dart';
import 'coach_ryze_avatar.dart';

/// Chat message bubble widget
/// Displays user and coach messages with proper styling
class ChatMessageBubble extends StatelessWidget {
  final CoachMessage message;
  final bool isStreaming;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    } else {
      return _buildCoachBubble(context);
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyMessage(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoachRyzeAvatar(
            type: CoachRyzeAvatarType.nutritionChat,
            size: CoachRyzeAvatarSize.small,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyMessage(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMessageContent(context),
                    if (isStreaming) ...[
                      const SizedBox(height: 8),
                      _buildTypingIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Check if message contains deep links (ryse://)
    if (message.content.contains('ryse://')) {
      return _buildContentWithDeepLinks(context);
    }

    // Use Markdown for coach messages (supports formatting)
    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: Color(0xFF0B132B),
          fontSize: 15,
          height: 1.5,
        ),
        h1: const TextStyle(
          color: Color(0xFF0B132B),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        h2: const TextStyle(
          color: Color(0xFF0B132B),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        h3: const TextStyle(
          color: Color(0xFF0B132B),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        strong: const TextStyle(
          color: Color(0xFF0B132B),
          fontWeight: FontWeight.w600,
        ),
        em: const TextStyle(
          color: Color(0xFF0B132B),
          fontStyle: FontStyle.italic,
        ),
        listBullet: const TextStyle(
          color: Color(0xFF0B132B),
          fontSize: 15,
        ),
        code: TextStyle(
          backgroundColor: const Color(0xFFF1F5F9),
          color: const Color(0xFF0B132B),
          fontSize: 14,
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onTapLink: (text, href, title) {
        _handleLink(href);
      },
    );
  }

  Widget _buildContentWithDeepLinks(BuildContext context) {
    final parts = <InlineSpan>[];
    final content = message.content;

    // Simple regex to find deep links
    final regex = RegExp(r'\[([^\]]+)\]\s*→\s*(ryse://[^\s\)]+)');
    int lastEnd = 0;

    for (final match in regex.allMatches(content)) {
      // Add text before the match
      if (match.start > lastEnd) {
        parts.add(TextSpan(
          text: content.substring(lastEnd, match.start),
          style: const TextStyle(
            color: Color(0xFF0B132B),
            fontSize: 15,
            height: 1.5,
          ),
        ));
      }

      // Add the button as a widget span
      final buttonText = match.group(1) ?? '';
      final deepLink = match.group(2) ?? '';

      parts.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ElevatedButton.icon(
            onPressed: () => _handleDeepLink(deepLink),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B132B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < content.length) {
      parts.add(TextSpan(
        text: content.substring(lastEnd),
        style: const TextStyle(
          color: Color(0xFF0B132B),
          fontSize: 15,
          height: 1.5,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: parts),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        const SizedBox(width: 4),
        _buildDot(1),
        const SizedBox(width: 4),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              const Color(0xFF94A3B8),
              const Color(0xFF0B132B),
              value,
            ),
          ),
        );
      },
    );
  }

  void _handleLink(String? href) {
    if (href == null) return;

    if (href.startsWith('ryse://')) {
      _handleDeepLink(href);
    } else {
      launchUrl(Uri.parse(href));
    }
  }

  void _handleDeepLink(String deepLink) {
    // TODO: Handle deep links to workouts, recipes, etc.
    // Example: ryse://workout/abc123
    // This will be implemented with proper navigation

    debugPrint('Deep link tapped: $deepLink');

    // For now, just show a snackbar or handle specific routes
    // The actual implementation will depend on the app's routing system
  }

  /// Copy message on long press (like iMessage/WhatsApp)
  void _copyMessage(BuildContext context) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: message.content));

    final lang = LocalizationService.instance.currentLanguageCode;
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
}

/// Message time indicator widget
class MessageTimeIndicator extends StatelessWidget {
  final DateTime time;

  const MessageTimeIndicator({
    super.key,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 11,
      ),
    );
  }
}
