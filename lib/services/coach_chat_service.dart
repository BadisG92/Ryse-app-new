import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ryze_agent.dart';
import '../ai/ryze_context.dart';
import '../ai/ryze_context_source.dart';
import '../ai/ryze_events.dart';
import '../ai/ryze_memory.dart';
import '../ai/ryze_persona.dart';
import '../ai/ryze_tools/ryze_tools.dart';
import '../models/coach_chat_models.dart';
import '../models/weekly_planner_models.dart';
import 'planner_ai_service.dart';
import 'coach_personality_service.dart';
import 'global_state_manager.dart';
import 'localization_service.dart';
import 'translations.dart';
import 'weekly_bilan_service.dart';

/// Main service for Coach Ryze chat functionality
/// Handles conversations, messages, rate limiting, and Gemini API calls
class CoachChatService {
  static final CoachChatService _instance = CoachChatService._internal();
  static CoachChatService get instance => _instance;

  CoachChatService._internal();


  /// Le moteur : il porte l'historique, l'instruction système et le flux.
  RyzeAgent? _agent;

  // Supabase client
  final _supabase = Supabase.instance.client;

  // Configuration
  static const int maxMessagesContext = 30; // Last 30 messages sent to AI
  static const int maxMessagesHistory = 200; // Max messages loaded for display

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

    // Le contexte se met à jour tout seul à partir d'ici : boire un verre ou
    // finir une séance rafraîchit le bloc concerné, sans reconstruire la
    // conversation.
    RyzeContext.instance.listen();

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
      _profileTraitsLoaded = false; // le profil a pu changer dans les réglages
      await _loadUserPreferences();
      await _startChatSession();
    }
  }

  // ==========================================
  // MESSAGE HANDLING
  // ==========================================

  /// Ce que l'écran reçoit pendant que Ryze répond.
  ///
  /// La conversation ne rend plus seulement du texte : elle rend aussi ce que
  /// Ryze vient de faire, et ce qu'il demande la permission de faire.

  /// Prépare l'agent avec l'historique de la conversation.
  ///
  /// L'instruction système n'est plus injectée en faux premier tour utilisateur
  /// suivi d'un « Compris ! » français : c'est un vrai champ de la requête,
  /// relu à chaque envoi. Changer de ton ou sauver une préférence ne coûte donc
  /// plus la reconstruction de la conversation.
  Future<void> _startChatSession() async {
    // Les outils du plan travaillent dans une fenêtre : sans elle, « jeudi »
    // désigne le jeudi d'une semaine que personne n'a choisie. La conversation
    // parle de la semaine en cours, comme l'accueil.
    PlannerAIService.setPlanningWindow(getCurrentWeekStart());

    _agent ??= RyzeAgent(config: RyzeGenerationConfig.coach, surface: RyzeSurface.coach)
      ..systemInstructionBuilder = _buildSystemInstruction
      ..tools = ryzeTools.declarationsFor(RyzeSurface.coach);

    // Les trente derniers messages seulement : l'écran en garde deux cents
    // pour l'affichage, le modèle n'a pas besoin de tout relire.
    final messagesToSend = _currentMessages.length > maxMessagesContext
        ? _currentMessages.sublist(_currentMessages.length - maxMessagesContext)
        : _currentMessages;

    _agent!.seed(messagesToSend.map((m) => (fromUser: m.isUser, text: m.content)));

    if (kDebugMode) {
      debugPrint('🤖 CoachChatService: agent prêt, ${_agent!.historyLength} tours');
    }
  }

  /// L'instruction système, reconstruite à chaque envoi.
  Future<String> _buildSystemInstruction() async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final strings = RyzePersona.of(lang);
    await _loadProfileTraits();

    final profile = await RyzeContextSource.instance.build(strings);
    final prefs = await RyzeMemory.instance.load();

    return RyzePersona.build(
      lang: lang,
      surface: RyzeSurface.coach,
      userName: GlobalStateManager.instance.userName,
      gender: _userGender,
      age: _userAge,
      context: profile,
    ).then((prompt) {
      if (kDebugMode) {
        debugPrint('🤖 Instruction système : ${prompt.length} caractères, '
            'mémoire ${RyzeMemory.itemsOf(prefs).length} éléments');
      }
      return prompt;
    });
  }

  /// Le sexe et l'âge, relus avec le profil et gardés pour l'adaptation du ton.
  ///
  /// Ils étaient déclarés, passés à la persona… et jamais remplis : les règles
  /// de ton par sexe et par âge tournaient donc à vide à chaque message.
  String? _userGender;
  int? _userAge;

  /// Vrai une fois la lecture faite, réussie ou non : on ne rejoue pas une
  /// requête à chaque envoi de message.
  bool _profileTraitsLoaded = false;

  Future<void> _loadProfileTraits() async {
    if (_profileTraitsLoaded) return;
    _profileTraitsLoaded = true;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final row = await _supabase
          .from('users')
          .select('gender, age')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      if (row == null) return;
      final gender = (row['gender'] as String?)?.trim();
      _userGender = (gender == null || gender.isEmpty) ? null : gender;
      _userAge = (row['age'] as num?)?.toInt();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ CoachChatService: profil (sexe/âge) indisponible: $e');
    }
  }


  /// Send a message with streaming response
  ///
  /// Les messages d'erreur passent par le dictionnaire : ils s'affichent dans
  /// la bulle comme une réponse du coach, et huit phrases françaises en dur y
  /// arrivaient jusqu'ici quelle que soit la langue.
  Stream<CoachEvent> streamMessage(String userMessage) async* {
    final lang = LocalizationService.instance.currentLanguageCode;

    if (_currentConversation == null) {
      await getOrCreateConversation();
    }

    if (_currentConversation == null || _agent == null) {
      yield CoachFailure('coach_error_start'.tr(lang));
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield CoachFailure('error_user_not_authenticated'.tr(lang));
      return;
    }

    try {
      await _saveMessage(role: 'user', content: userMessage);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error saving user message: $e');
      yield CoachFailure('coach_error_send'.tr(lang));
      return;
    }

    try {
      final buffer = StringBuffer();

      await for (final event in _agent!.send(userMessage)) {
        switch (event) {
          case RyzeTextDelta(:final text):
            buffer.write(text);
            yield CoachText(text);

          case RyzeToolCall():
            // Le texte accumulé jusqu'ici devient une bulle à lui, avant que
            // l'action ne s'intercale : sinon les phrases d'avant et d'après
            // se recollent autour d'une ligne qui n'était pas là.
            await _flush(buffer);
            yield* _runTool(event, lang);

          case RyzeError(:final messageKey):
            await _flush(buffer);
            yield CoachFailure(messageKey.tr(lang));
            return;

          case RyzeDone():
            break;
        }
      }

      await _flush(buffer);
    } catch (e) {
      // Le transport a déjà ses reprises et ses délais ; ce qui remonte ici
      // est une écriture en base qui a échoué, pas une panne du modèle.
      if (kDebugMode) debugPrint('❌ CoachChatService: Error streaming message: $e');
      yield CoachFailure('coach_error_generic'.tr(lang));
    }
  }

  /// Exécute l'outil demandé, ou demande d'abord la permission.
  Stream<CoachEvent> _runTool(RyzeToolCall call, String lang) async* {
    final tool = ryzeTools.byName(call.name);

    if (tool == null) {
      // Le modèle a inventé un outil. On le lui dit, plutôt que de le laisser
      // croire que c'est passé.
      _agent!.addToolResults([
        (name: call.name, response: {'ok': false, 'error': 'unknown tool'})
      ]);
      return;
    }

    if (tool.needsConfirmation(call.args) && tool.preview != null) {
      final pending = await tool.preview!(call.args);
      _pending[pending.id] = pending;

      // « en attente » et non « fait » : c'est ce qui empêche Ryze d'annoncer
      // une action que l'utilisateur n'a pas encore validée.
      _agent!.addToolResults([
        (name: call.name, response: {'ok': false, 'status': 'awaiting_user_validation'})
      ]);

      yield CoachAsk(pending);
      return;
    }

    final result = await tool.execute(call.args);
    _agent!.addToolResults([(name: call.name, response: result.toResponse())]);
    await _saveAction(call.name, result);
    yield CoachAction(result.summary, ok: result.ok, toolName: call.name, undo: result.undo);
  }

  /// Les actions proposées et pas encore tranchées.
  final Map<String, RyzePending> _pending = {};

  /// L'utilisateur a validé une carte.
  Future<CoachAction> confirmPending(String id) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final pending = _pending.remove(id);
    if (pending == null) return CoachAction('ryze_action_failed'.tr(lang), ok: false);

    final result = await pending.commit();
    _agent?.note(result.summary);
    await _saveAction(pending.toolName, result);
    return CoachAction(result.summary, ok: result.ok, toolName: pending.toolName, undo: result.undo);
  }

  /// L'utilisateur a refusé une carte.
  void cancelPending(String id) {
    final pending = _pending.remove(id);
    if (pending != null) _agent?.note('cancelled by the user: ${pending.title}');
  }

  /// Écrit la bulle de texte accumulée, s'il y en a une.
  Future<void> _flush(StringBuffer buffer) async {
    final text = buffer.toString().trim();
    buffer.clear();
    if (text.isEmpty) return;
    await _saveMessage(role: 'assistant', content: text);
  }

  /// Écrit une action dans la transcription.
  Future<void> _saveAction(String toolName, RyzeToolResult result) => _saveMessage(
        role: 'assistant',
        content: result.summary,
        metadata: {
          'kind': 'tool',
          'name': toolName,
          'status': result.ok ? 'done' : 'failed',
        },
      );

  Future<void> _saveMessage({
    required String role,
    required String content,
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || _currentConversation == null) return;

    final row = await _supabase
        .from('coach_messages')
        .insert({
          'conversation_id': _currentConversation!.id,
          'user_id': user.id,
          'role': role,
          'content': content,
          'tokens_used': content.length ~/ 4,
          if (metadata.isNotEmpty) 'metadata': metadata,
        })
        .select()
        .single();

    _currentMessages.add(CoachMessage.fromJson(row));
  }

  /// Stream weekly bilan response from Coach Ryze
  /// Does NOT display user message - only Ryze's analysis
  Stream<String> streamBilanResponse(String lang) async* {
    if (_currentConversation == null) {
      await getOrCreateConversation();
    }

    if (_currentConversation == null || _agent == null) {
      yield 'coach_error_start'.tr(lang);
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield 'error_user_not_authenticated'.tr(lang);
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

      // Le bilan passe ses consignes en message caché : l'utilisateur voit sa
      // phrase courte, le modèle reçoit le tout.
      final buffer = StringBuffer();

      await for (final event in _agent!.send(userMessageText, hidden: bilanPrompt)) {
        if (event is RyzeTextDelta) {
          buffer.write(event.text);
          yield event.text;
        } else if (event is RyzeError) {
          yield event.messageKey.tr(lang);
          return;
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
      yield 'coach_error_generic'.tr(lang);
    }
  }


  // ==========================================
  // PREFERENCES
  // ==========================================

  /// Update user preferences
  ///
  /// L'écriture relit le document en base et fusionne, au lieu de le
  /// reconstruire : `preferences` porte aussi ce que l'onboarding y a écrit, et
  /// un upsert qui repart des six listes l'effaçait à la première extraction.
  Future<void> updatePreferences(UserCoachPreferences preferences) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final existing = await _supabase
          .from('user_coach_preferences')
          .select('preferences')
          .eq('user_id', user.id)
          .maybeSingle();

      await _supabase
          .from('user_coach_preferences')
          .upsert(
            {
              'user_id': user.id,
              'preferences': UserCoachPreferences.mergePreferencesJson(
                existing?['preferences'] as Map<String, dynamic>?,
                preferences.toPreferencesJson(),
              ),
              'last_extraction_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id',
          );

      _userPreferences = preferences;

      // La conversation n'est plus reconstruite ici. L'instruction système est
      // relue au prochain envoi, ce qui suffit pour que Ryze tienne compte de
      // ce qu'il vient d'apprendre — et le fil de la discussion survit.
      RyzeMemory.instance.clearCache();
      RyzeContext.instance.invalidate({RyzeBlock.memory});
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachChatService: Error updating preferences: $e');
    }
  }

  /// L'extraction de ce que Ryze retient, quand elle est due.
  ///
  /// Appelée en quittant l'écran, et non après chaque réponse. Elle ne touche
  /// pas la conversation : le bloc mémoire sera relu au prochain envoi.
  Future<void> extractMemoryIfDue() async {
    try {
      final change = await RyzeMemory.instance.extractIfDue(_currentMessages);
      if (change) {
        await _loadUserPreferences();
        RyzeContext.instance.invalidate({RyzeBlock.memory});
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ CoachChatService: extraction mémoire : $e');
    }
  }

  // ==========================================
  // CLEANUP
  // ==========================================

  /// Clear current conversation state (but keep in DB)
  void clearCurrentConversation() {
    _currentConversation = null;
    _currentMessages = [];
    _agent?.clear();
  }

  /// Reset the service (for logout)
  void reset() {
    _currentConversation = null;
    _currentMessages = [];
    _agent?.dispose();
    _agent = null;
    _userPreferences = null;
    RyzeMemory.instance.clearCache();
    RyzeContextSource.instance.invalidate();
  }
}
