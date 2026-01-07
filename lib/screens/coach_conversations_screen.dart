import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/coach_chat_models.dart';
import '../services/coach_chat_service.dart';
import '../services/localization_service.dart';
import '../services/subscription_service.dart';
import '../services/translations.dart';
import '../components/ui/coach_ryze_avatar.dart';
import 'coach_chat_screen.dart';

/// Screen showing list of coach conversations (max 5)
/// Style: Similar to Claude's conversation list
class CoachConversationsScreen extends StatefulWidget {
  const CoachConversationsScreen({super.key});

  @override
  State<CoachConversationsScreen> createState() => _CoachConversationsScreenState();
}

class _CoachConversationsScreenState extends State<CoachConversationsScreen> {
  List<CoachConversation> _conversations = [];
  bool _isLoading = true;
  CoachRateLimitStatus? _rateLimitStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await CoachChatService.instance.initialize();
      final conversations = await CoachChatService.instance.getConversations();
      final rateLimitStatus = await CoachChatService.instance.getRateLimitStatus();

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _rateLimitStatus = rateLimitStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createNewConversation() async {
    final conversation = await CoachChatService.instance.createConversation();
    if (conversation != null && mounted) {
      _navigateToChat(conversation);
    }
  }

  void _navigateToChat(CoachConversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoachChatScreen(conversation: conversation),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _deleteConversation(CoachConversation conversation) async {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('coach_chat_delete_conversation'.tr(lang)),
        content: Text('coach_chat_delete_irreversible'.tr(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('coach_chat_cancel'.tr(lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('coach_chat_delete'.tr(lang)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CoachChatService.instance.deleteConversation(conversation.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: _conversations.length < 5
          ? FloatingActionButton(
              onPressed: _createNewConversation,
              backgroundColor: const Color(0xFF0B132B),
              child: const Icon(LucideIcons.plus, color: Colors.white),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
          const Text(
            'Coach Ryze',
            style: TextStyle(
              color: Color(0xFF0B132B),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        // N'afficher le compteur que pour les utilisateurs non-premium
        if (_rateLimitStatus != null && !_rateLimitStatus!.isPremium && !SubscriptionService.instance.isPremium)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _rateLimitStatus!.displayText,
              style: TextStyle(
                color: _rateLimitStatus!.canSendMessage
                    ? const Color(0xFF64748B)
                    : Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final locService = Provider.of<LocalizationService>(context);
    final lang = locService.currentLanguageCode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CoachRyzeAvatar(
              type: CoachRyzeAvatarType.nutritionChat,
              size: CoachRyzeAvatarSize.xlarge,
            ),
            const SizedBox(height: 24),
            Text(
              'coach_chat_welcome'.tr(lang),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B132B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'coach_chat_welcome_subtitle'.tr(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createNewConversation,
              icon: const Icon(LucideIcons.messageCircle),
              label: Text('coach_chat_start_conversation'.tr(lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B132B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!SubscriptionService.instance.isPremium)
              Text(
                'coach_chat_free_messages_total'.tr(lang),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(CoachConversation conversation) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteConversation(conversation);
        return false; // We handle deletion manually
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: () => _navigateToChat(conversation),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.messageSquare,
                      size: 24,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.displayTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B132B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${conversation.messageCount} messages',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      conversation.formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
