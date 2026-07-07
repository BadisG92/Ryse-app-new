import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/gemini_config.dart';
import '../models/coach_chat_models.dart';
import 'coach_context_builder.dart';
import 'coach_preference_extractor.dart';
import 'coach_personality_service.dart';
import 'global_state_manager.dart';
import 'localization_service.dart';
import 'subscription_service.dart';
import 'weekly_bilan_service.dart';

/// Main service for Coach Ryze chat functionality
/// Handles conversations, messages, rate limiting, and Gemini API calls
class CoachChatService {
  static final CoachChatService _instance = CoachChatService._internal();
  static CoachChatService get instance => _instance;

  CoachChatService._internal();

  // Gemini model for chat
  GenerativeModel? _model;
  ChatSession? _currentChatSession;

  // Supabase client
  final _supabase = Supabase.instance.client;

  // Configuration
  static const int maxMessagesContext = 30; // Last 30 messages sent to AI
  static const int maxMessagesHistory = 200; // Max messages loaded for display
  static const int freeTotalLimit = 10; // 10 messages total (not per day) for free users

  // Current conversation state
  CoachConversation? _currentConversation;
  List<CoachMessage> _currentMessages = [];
  UserCoachPreferences? _userPreferences;

  // Getters
  CoachConversation? get currentConversation => _currentConversation;
  List<CoachMessage> get currentMessages => List.unmodifiable(_currentMessages);
  UserCoachPreferences? get userPreferences => _userPreferences;

  /// Initialize the service
  Future<void> initialize() async {
    if (kDebugMode) debugPrint('🤖 CoachChatService: Initializing...');

    // Initialize Gemini model for chat
    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8, // More creative for conversational tone
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 400, // Short responses for conversational coach
      ),
    );

    // Load user preferences
    await _loadUserPreferences();

    if (kDebugMode) debugPrint('✅ CoachChatService: Initialized');
  }

  /// Load user preferences from database
  Future<void> _loadUserPreferences() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('user_coach_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        _userPreferences = UserCoachPreferences.fromJson(response);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error loading preferences: $e');
    }
  }

  // ==========================================
  // CONVERSATION MANAGEMENT
  // ==========================================

  /// Get the single conversation for current user
  Future<CoachConversation?> getConversation() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('coach_conversations')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return CoachConversation.fromJson(response);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error getting conversation: $e');
      return null;
    }
  }

  /// Create the single conversation for user
  Future<CoachConversation?> createConversation() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('coach_conversations')
          .insert({
            'user_id': user.id,
            'title': 'Coach Ryze',
          })
          .select()
          .single();

      final conversation = CoachConversation.fromJson(response);
      _currentConversation = conversation;
      _currentMessages = [];

      // Start a new Gemini chat session
      await _startChatSession();

      return conversation;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error creating conversation: $e');
      return null;
    }
  }

  /// Load a conversation and ALL its messages (for display)
  /// AI context is limited to last 30 messages in _startChatSession
  Future<void> loadConversation(String conversationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Load conversation
      final convResponse = await _supabase
          .from('coach_conversations')
          .select()
          .eq('id', conversationId)
          .eq('user_id', user.id)
          .single();

      _currentConversation = CoachConversation.fromJson(convResponse);

      // Load last 200 messages for display (user can scroll through history)
      final msgResponse = await _supabase
          .from('coach_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(maxMessagesHistory);

      _currentMessages = (msgResponse as List)
          .map((json) => CoachMessage.fromJson(json))
          .toList()
          .reversed // Reverse to get chronological order (oldest first)
          .toList();

      // Start Gemini chat session with history (limited to last 30)
      await _startChatSession();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error loading conversation: $e');
    }
  }

  /// Get or create the single conversation
  Future<CoachConversation?> getOrCreateConversation() async {
    final conversation = await getConversation();

    if (conversation == null) {
      return await createConversation();
    }

    // Load the conversation
    await loadConversation(conversation.id);
    return _currentConversation;
  }

  /// Force refresh of the chat session (e.g., after personality change)
  /// This will rebuild the system prompt with the new personality and reload preferences
  Future<void> refreshChatSession() async {
    if (_currentConversation != null) {
      if (kDebugMode) debugPrint('🔄 CoachChatService: Refreshing chat session with new personality');
      // Reload preferences from database to get latest changes
      await _loadUserPreferences();
      await _startChatSession();
    }
  }

  // ==========================================
  // MESSAGE HANDLING
  // ==========================================

  /// Start a Gemini chat session with system prompt and history
  Future<void> _startChatSession() async {
    if (_model == null) {
      await initialize();
    }

    // Build system prompt with user context
    final systemPrompt = await CoachContextBuilder.instance.buildSystemPrompt(
      preferences: _userPreferences,
    );

    if (kDebugMode) {
      debugPrint('🤖 CoachChatService: System prompt built (${systemPrompt.length} chars)');
      // Log first 500 chars of personality section
      final personalityIndex = systemPrompt.indexOf('ADOPTE CE TON');
      if (personalityIndex > 0) {
        debugPrint('🎭 Personality section: ${systemPrompt.substring(personalityIndex, (personalityIndex + 200).clamp(0, systemPrompt.length))}...');
      }
    }

    // Convert existing messages to Gemini format
    final history = <Content>[];

    // Add system prompt as first user message (workaround for system instructions)
    history.add(Content.text('[SYSTEM INSTRUCTIONS]\n$systemPrompt'));
    history.add(Content.model([TextPart('Compris ! Je suis Coach Ryze, prêt à t\'accompagner. Comment puis-je t\'aider aujourd\'hui ?')]));

    // Add conversation history (limited to last 30 messages for AI context)
    // Note: _currentMessages contains ALL messages for display, but AI only sees the last 30
    final messagesToSend = _currentMessages.length > maxMessagesContext
        ? _currentMessages.sublist(_currentMessages.length - maxMessagesContext)
        : _currentMessages;

    // Build history with day markers to give AI temporal context
    final historyWithDays = _buildHistoryWithDayMarkers(messagesToSend);
    history.addAll(historyWithDays);

    _currentChatSession = _model!.startChat(history: history);
  }

  /// Build chat history with day markers inserted between messages from different days
  /// This helps the AI understand temporal context (e.g., "yesterday's conversation was about X, today is a new day")
  List<Content> _buildHistoryWithDayMarkers(List<CoachMessage> messages) {
    final history = <Content>[];
    if (messages.isEmpty) return history;

    final lang = LocalizationService.instance.currentLanguageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? lastMessageDay;
    bool isFirstDayMarker = true;

    for (var msg in messages) {
      final msgDay = DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);

      // Check if we need to insert a day marker
      if (lastMessageDay == null || msgDay != lastMessageDay) {
        // Insert day marker as a system note
        final dayMarker = _buildDayMarker(msgDay, today, lang, isFirstDayMarker);

        // Add day marker as user message (context note) and AI acknowledgment
        history.add(Content.text('[CONTEXTE TEMPOREL] $dayMarker'));
        history.add(Content.model([TextPart('Noté.')]));

        lastMessageDay = msgDay;
        isFirstDayMarker = false;
      }

      // Add the actual message
      if (msg.role == MessageRole.user) {
        history.add(Content.text(msg.content));
      } else {
        history.add(Content.model([TextPart(msg.content)]));
      }
    }

    return history;
  }

  /// Build a day marker string for the AI context
  String _buildDayMarker(DateTime msgDay, DateTime today, String lang, bool isFirstMarker) {
    final difference = today.difference(msgDay).inDays;
    final dateFormatter = DateFormat('EEEE d MMMM yyyy', lang == 'fr' ? 'fr_FR' : lang == 'de' ? 'de_DE' : 'en_US');
    final formattedDate = dateFormatter.format(msgDay);

    if (difference == 0) {
      // Today
      if (lang == 'fr') {
        return "Nous sommes AUJOURD'HUI ($formattedDate). Les données nutritionnelles et sportives dans le contexte sont celles d'aujourd'hui. Réponds en fonction des données du jour actuel.";
      } else if (lang == 'de') {
        return "Wir sind HEUTE ($formattedDate). Die Ernährungs- und Sportdaten im Kontext sind die von heute.";
      } else {
        return "We are TODAY ($formattedDate). The nutrition and sport data in context are today's data. Answer based on today's data.";
      }
    } else if (difference == 1) {
      // Yesterday
      if (lang == 'fr') {
        return isFirstMarker
            ? "Les messages suivants datent d'HIER ($formattedDate). C'est de l'historique passé."
            : "--- HIER ($formattedDate) ---";
      } else if (lang == 'de') {
        return isFirstMarker
            ? "Die folgenden Nachrichten sind von GESTERN ($formattedDate). Das ist vergangene Geschichte."
            : "--- GESTERN ($formattedDate) ---";
      } else {
        return isFirstMarker
            ? "The following messages are from YESTERDAY ($formattedDate). This is past history."
            : "--- YESTERDAY ($formattedDate) ---";
      }
    } else {
      // Older
      if (lang == 'fr') {
        return isFirstMarker
            ? "Les messages suivants datent du $formattedDate (il y a $difference jours). C'est de l'historique passé."
            : "--- $formattedDate (il y a $difference jours) ---";
      } else if (lang == 'de') {
        return isFirstMarker
            ? "Die folgenden Nachrichten sind vom $formattedDate (vor $difference Tagen). Das ist vergangene Geschichte."
            : "--- $formattedDate (vor $difference Tagen) ---";
      } else {
        return isFirstMarker
            ? "The following messages are from $formattedDate ($difference days ago). This is past history."
            : "--- $formattedDate ($difference days ago) ---";
      }
    }
  }

  /// Send a message and get a response
  Future<CoachMessage?> sendMessage(String userMessage) async {
    if (_currentConversation == null) {
      await getOrCreateConversation();
    }

    if (_currentConversation == null || _currentChatSession == null) {
      if (kDebugMode) debugPrint('❌ CoachChatService: No conversation or chat session');
      return null;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Check rate limit
      final canSend = await canSendMessage();
      if (!canSend) {
        if (kDebugMode) debugPrint('⚠️ CoachChatService: Rate limit reached');
        return null;
      }

      // Save user message to database
      final userMsgResponse = await _supabase
          .from('coach_messages')
          .insert({
            'conversation_id': _currentConversation!.id,
            'user_id': user.id,
            'role': 'user',
            'content': userMessage,
          })
          .select()
          .single();

      final userMsgModel = CoachMessage.fromJson(userMsgResponse);
      _currentMessages.add(userMsgModel);

      // Increment usage
      await _incrementUsage();

      if (kDebugMode) {
        debugPrint('');
        debugPrint('💬 ========== COACH CHAT REQUEST ==========');
        debugPrint('📝 User message: $userMessage');
        debugPrint('📊 Messages in context: ${_currentMessages.length}');
        debugPrint('');
      }

      // Get response from Gemini
      final response = await _currentChatSession!.sendMessage(
        Content.text(userMessage),
      );

      final responseText = response.text ?? '';

      if (kDebugMode) {
        debugPrint('');
        debugPrint('🤖 ========== COACH CHAT RESPONSE ==========');
        debugPrint('📝 Coach response (${responseText.length} chars):');
        debugPrint('─' * 50);
        debugPrint(responseText);
        debugPrint('─' * 50);
        debugPrint('');
      }

      if (responseText.isEmpty) {
        if (kDebugMode) debugPrint('❌ Empty response from Gemini');
        return null;
      }

      // Estimate tokens used (rough estimate: 1 token ~ 4 chars)
      final tokensUsed = (userMessage.length + responseText.length) ~/ 4;

      // Save assistant message to database
      final assistantMsgResponse = await _supabase
          .from('coach_messages')
          .insert({
            'conversation_id': _currentConversation!.id,
            'user_id': user.id,
            'role': 'assistant',
            'content': responseText,
            'tokens_used': tokensUsed,
          })
          .select()
          .single();

      final assistantMsgModel = CoachMessage.fromJson(assistantMsgResponse);
      _currentMessages.add(assistantMsgModel);

      return assistantMsgModel;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error sending message: $e');
      return null;
    }
  }

  /// Send a message with streaming response
  Stream<String> streamMessage(String userMessage, {int retryCount = 0}) async* {
    if (_currentConversation == null) {
      await getOrCreateConversation();
    }

    if (_currentConversation == null || _currentChatSession == null) {
      yield '[Erreur: Impossible de démarrer la conversation]';
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield '[Erreur: Utilisateur non connecté]';
      return;
    }

    // Check rate limit
    final canSend = await canSendMessage();
    if (!canSend) {
      yield '[Limite atteinte: Tu as utilisé tes 5 messages gratuits du jour. Passe à Premium pour des conversations illimitées !]';
      return;
    }

    // Only save user message on first attempt (not on retry)
    CoachMessage? userMsgModel;
    if (retryCount == 0) {
      try {
        final userMsgResponse = await _supabase
            .from('coach_messages')
            .insert({
              'conversation_id': _currentConversation!.id,
              'user_id': user.id,
              'role': 'user',
              'content': userMessage,
            })
            .select()
            .single();

        userMsgModel = CoachMessage.fromJson(userMsgResponse);
        _currentMessages.add(userMsgModel);

        // Increment usage
        await _incrementUsage();
      } catch (e) {
        if (kDebugMode) debugPrint('❌ CoachChatService: Error saving user message: $e');
        yield '[Erreur: Impossible d\'envoyer le message]';
        return;
      }
    }

    try {
      // Stream response from Gemini
      final responseStream = _currentChatSession!.sendMessageStream(
        Content.text(userMessage),
      );

      final buffer = StringBuffer();

      await for (final response in responseStream) {
        if (response.text != null) {
          buffer.write(response.text);
          yield response.text!;
        }
      }

      // Save complete response
      final fullResponse = buffer.toString();
      if (fullResponse.isNotEmpty) {
        final tokensUsed = (userMessage.length + fullResponse.length) ~/ 4;

        final assistantMsgResponse = await _supabase
            .from('coach_messages')
            .insert({
              'conversation_id': _currentConversation!.id,
              'user_id': user.id,
              'role': 'assistant',
              'content': fullResponse,
              'tokens_used': tokensUsed,
            })
            .select()
            .single();

        final assistantMsgModel = CoachMessage.fromJson(assistantMsgResponse);
        _currentMessages.add(assistantMsgModel);

        // Extract preferences in background after 4+ messages
        if (_currentMessages.length >= 4) {
          _extractPreferencesInBackground();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error streaming message: $e');

      // Handle known SDK bug with empty responses - silent retry
      if (e.toString().contains('Unhandled format for Content') && retryCount < 2) {
        if (kDebugMode) debugPrint('🔄 CoachChatService: Retrying after SDK error (attempt ${retryCount + 1})');

        // Reset chat session and retry
        _currentChatSession = null;
        await initialize();

        // Small delay before retry
        await Future.delayed(const Duration(milliseconds: 500));

        // Retry silently
        await for (final chunk in streamMessage(userMessage, retryCount: retryCount + 1)) {
          yield chunk;
        }
      } else {
        yield '[Erreur: Une erreur est survenue. Réessaie dans quelques instants.]';
      }
    }
  }

  /// Stream weekly bilan response from Coach Ryze
  /// Does NOT display user message - only Ryze's analysis
  Stream<String> streamBilanResponse(String lang) async* {
    if (_currentConversation == null) {
      await getOrCreateConversation();
    }

    if (_currentConversation == null || _currentChatSession == null) {
      yield '[Erreur: Impossible de démarrer la conversation]';
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield '[Erreur: Utilisateur non connecté]';
      return;
    }

    try {
      // Ajouter un message utilisateur pour la cohérence de l'historique
      final isFr = lang == 'fr';
      final isDe = lang == 'de';
      final userMessageText = isFr
          ? 'Faire mon bilan hebdo'
          : isDe
              ? 'Meine Wochenbilanz machen'
              : 'Do my weekly summary';

      // Sauvegarder le message utilisateur en DB
      await _supabase.from('coach_messages').insert({
        'conversation_id': _currentConversation!.id,
        'user_id': user.id,
        'role': 'user',
        'content': userMessageText,
        'tokens_used': 0,
      });

      // Get weekly stats
      final stats = await WeeklyBilanService.instance.getWeeklyStats();
      final personality = await CoachPersonalityService.instance.getPersonality();
      final userName = GlobalStateManager.instance.userName.isNotEmpty
          ? GlobalStateManager.instance.userName
          : 'Champion';
      final opener = await CoachPersonalityService.instance.getBilanOpener(
        lang,
        userName,
      );

      // Build bilan prompt (sent to AI but not displayed)

      final bilanPrompt = '''
[INSTRUCTION SYSTÈME - BILAN HEBDOMADAIRE]
L'utilisateur a cliqué sur "Faire le bilan". Tu dois lui donner son bilan hebdomadaire complet.

DONNÉES DE LA SEMAINE:
${stats.toPromptString()}

INSTRUCTIONS:
1. Commence par l'opener adapté à ta personnalité: "$opener"
2. Donne un résumé des données (jours trackés, calories moyennes, sport)
3. Donne ton AVIS GÉNÉRAL sur la semaine (${isFr ? 'bonne semaine, peut mieux faire, excellent, etc.' : isDe ? 'gute Woche, kann besser werden, ausgezeichnet, usw.' : 'good week, room for improvement, excellent, etc.'})
4. ${isFr ? 'Termine avec un message motivant personnalisé' : isDe ? 'Beende mit einer personalisierten motivierenden Nachricht' : 'End with a personalized motivating message'}

IMPORTANT:
- Réponds en ${isFr ? 'français' : isDe ? 'allemand' : 'anglais'}
- Adapte ton ton à ta personnalité: ${personality.type.name}
- Si les données sont à zéro, encourage l'utilisateur à tracker la semaine prochaine
- Sois concis mais complet (max 150 mots)
''';

      // Send to Gemini (no user message saved)
      final responseStream = _currentChatSession!.sendMessageStream(
        Content.text(bilanPrompt),
      );

      final buffer = StringBuffer();

      await for (final response in responseStream) {
        if (response.text != null) {
          buffer.write(response.text);
          yield response.text!;
        }
      }

      // Save only assistant response to database
      final fullResponse = buffer.toString();
      if (fullResponse.isNotEmpty) {
        final tokensUsed = (bilanPrompt.length + fullResponse.length) ~/ 4;

        final assistantMsgResponse = await _supabase
            .from('coach_messages')
            .insert({
              'conversation_id': _currentConversation!.id,
              'user_id': user.id,
              'role': 'assistant',
              'content': fullResponse,
              'tokens_used': tokensUsed,
            })
            .select()
            .single();

        final assistantMsgModel = CoachMessage.fromJson(assistantMsgResponse);
        _currentMessages.add(assistantMsgModel);
      }

      // Mark bilan as done for this week
      await WeeklyBilanService.instance.markBilanDone();

    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error streaming bilan: $e');
      yield '[Erreur: ${e.toString()}]';
    }
  }

  /// Extract user preferences from conversation in background
  void _extractPreferencesInBackground() {
    // Run async without awaiting to not block UI
    Future(() async {
      try {
        if (_currentConversation == null) return;

        final newPrefs = await CoachPreferenceExtractor.instance.extractFromMessages(
          _currentMessages,
          _userPreferences,
        );

        if (newPrefs != null && !newPrefs.isEmpty) {
          await updatePreferences(newPrefs);
          if (kDebugMode) debugPrint('✅ Preferences extracted and saved');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Background preference extraction failed: $e');
      }
    });
  }

  // ==========================================
  // RATE LIMITING
  // ==========================================

  /// Check if user can send a message
  Future<bool> canSendMessage() async {
    // Premium users have unlimited messages
    if (SubscriptionService.instance.isPremium) {
      return true;
    }

    final usage = await getTotalUsage();
    return usage < freeTotalLimit;
  }

  /// Get total usage (not daily - total lifetime for free users)
  Future<int> getTotalUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final key = 'coach_chat_total_usage_${user.id}';
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Increment total usage
  Future<void> _incrementUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final key = 'coach_chat_total_usage_${user.id}';
      final current = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, current + 1);

      if (kDebugMode) {
        debugPrint('📊 Coach chat usage: ${current + 1}/$freeTotalLimit total');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error incrementing usage: $e');
    }
  }

  /// Get remaining messages (total, not daily)
  Future<int> getRemainingMessages() async {
    if (SubscriptionService.instance.isPremium) {
      return -1; // Unlimited
    }

    final usage = await getTotalUsage();
    return (freeTotalLimit - usage).clamp(0, freeTotalLimit);
  }

  /// Get rate limit status
  Future<CoachRateLimitStatus> getRateLimitStatus() async {
    if (SubscriptionService.instance.isPremium) {
      return CoachRateLimitStatus.premium();
    }

    final usage = await getTotalUsage();
    return CoachRateLimitStatus.free(
      messagesUsed: usage,
      messagesLimit: freeTotalLimit,
    );
  }

  // ==========================================
  // PREFERENCES
  // ==========================================

  /// Update user preferences
  Future<void> updatePreferences(UserCoachPreferences preferences) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_coach_preferences')
          .upsert(
            {
              'user_id': user.id,
              'preferences': {
                'allergies': preferences.allergies,
                'dietary_restrictions': preferences.dietaryRestrictions,
                'food_preferences': preferences.foodPreferences,
                'fitness_constraints': preferences.fitnessConstraints,
                'preferred_workout_times': preferences.preferredWorkoutTimes,
                'custom_notes': preferences.customNotes,
              },
              'last_extraction_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id',
          );

      _userPreferences = preferences;

      // Restart chat session with updated preferences
      if (_currentChatSession != null) {
        await _startChatSession();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error updating preferences: $e');
    }
  }

  // ==========================================
  // CLEANUP
  // ==========================================

  /// Clear current conversation state (but keep in DB)
  void clearCurrentConversation() {
    _currentConversation = null;
    _currentMessages = [];
    _currentChatSession = null;
  }

  /// Reset the service (for logout)
  void reset() {
    _currentConversation = null;
    _currentMessages = [];
    _currentChatSession = null;
    _userPreferences = null;
  }
}
