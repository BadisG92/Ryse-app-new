import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/gemini_config.dart';
import '../services/localization_service.dart';
import '../components/ui/coach_ryze_avatar.dart';

/// Onboarding chat screen with Coach Ryze
/// 5 exchanges max, skip available after 3
class OnboardingChatScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const OnboardingChatScreen({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<OnboardingChatScreen> createState() => _OnboardingChatScreenState();
}

class _OnboardingChatScreenState extends State<OnboardingChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isConversationDone = false; // True when 5 exchanges are done
  int _userExchangeCount = 0;
  static const int _maxExchanges = 5;
  static const int _minExchangesToSkip = 3;
  static const int _maxCharacters = 500;

  GenerativeModel? _model;
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final lang = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;

    // Initialize Gemini model
    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.85,
        topK: 40,
        topP: 0.9,
        maxOutputTokens: 200,
      ),
    );

    // Build system prompt
    final systemPrompt = _buildOnboardingPrompt(lang);

    // Start chat session with system prompt
    _chatSession = _model!.startChat(history: [
      Content.text('[SYSTEM INSTRUCTIONS]\n$systemPrompt'),
      Content.model([TextPart(_getAcknowledgement(lang))]),
    ]);

    // Add welcome message - warm intro + open question
    final welcomeMessage = lang == 'fr'
        ? "Hey, bienvenue ! 🐼 Moi c'est Coach Ryze, ton nouveau coach perso. Qu'est-ce qui t'a donné envie de télécharger l'app ?"
        : lang == 'de'
            ? "Hey, willkommen! 🐼 Ich bin Coach Ryze, dein neuer persönlicher Coach. Was hat dich dazu gebracht, die App herunterzuladen?"
            : "Hey, welcome! 🐼 I'm Coach Ryze, your new personal coach. What made you download the app?";

    setState(() {
      _messages.add(_ChatMessage(
        content: welcomeMessage,
        isUser: false,
      ));
    });
  }

  String _getAcknowledgement(String lang) {
    return lang == 'fr'
        ? "Compris ! Je suis Coach Ryze, prêt pour l'onboarding."
        : lang == 'de'
            ? "Verstanden! Ich bin Coach Ryze, bereit für das Onboarding."
            : "Got it! I'm Coach Ryze, ready for onboarding.";
  }

  String _buildOnboardingPrompt(String lang) {
    final isEnglish = lang == 'en';
    final isGerman = lang == 'de';

    return '''
Tu es Coach Ryze, coach fitness/nutrition. Tu es un EXCELLENT VENDEUR. Tu dois couvrir TOUS les sujets en 5 echanges.

## REGLE ABSOLUE : PREMIERE PERSONNE
Tu dis "JE vais t'aider", "JE te fais", "JE te guide". JAMAIS "l'app", "our app".

## OBJECTIF EN 5 ECHANGES
Tu dois ABSOLUMENT couvrir ces themes (pas rester bloque sur un seul sujet):
- Motivation profonde (pourquoi il veut changer)
- Pain points (ce qui l'a empeche de reussir avant)
- Comment TU vas l'aider (sport ET nutrition)
- Projection emotionnelle (comment il va se SENTIR)
- Engagement (le contrat)

## STRUCTURE PAR ECHANGE

ECHANGE 1 (actuel: ${_userExchangeCount + 1}/5) - MOTIVATION
-> Comprendre pourquoi il a telecharge. Creuser l'emotion derriere l'objectif.
-> Question: "Qu'est-ce qui t'a fait passer a l'action maintenant ?" ou similaire

ECHANGE 2 - PAIN POINTS
-> Comprendre ce qui l'a bloque avant. Montrer de l'empathie.
-> Question: "C'est quoi qui t'a empeche d'y arriver jusqu'ici ?" ou sur la nutrition

ECHANGE 3 - COMMENT TU L'AIDES
-> Montrer tes features: programmes sport, scan repas, suivi calories, coaching H24
-> Couvrir SPORT et NUTRITION, pas juste un des deux
-> Question: orienter vers ce qu'on n'a pas encore couvert

ECHANGE 4 - PROJECTION EMOTIONNELLE
-> Lui faire visualiser le resultat. Jouer sur l'emotion.
-> "Imagine dans 3 mois, tu te regardes dans le miroir et..."
-> "Tu vas te sentir tellement mieux, plus confiant, plus energique..."
-> Question: preparer le terrain pour le contrat

ECHANGE 5 - CONTRAT
-> Recapituler son objectif + ses blocages + comment tu l'aides
-> Proposer le deal: "Chaque semaine on fait le point ensemble, 2 min. Deal ? 🐼"

## VENTE EMOTIONNELLE
- Utilise l'evenement mentionne (mariage, ete, etc.) pour creer l'urgence
- Projette-le dans le futur: "Imagine la tete des gens quand ils vont te voir"
- Parle de confiance en soi, energie, fierte
- Montre que TU es la solution a ses problemes passes

## CE QUE TU FAIS
- Tu scannes ses repas en photo et tu comptes les calories
- Tu crees des programmes sport personnalises
- Tu le motives et tu le suis au quotidien
- Tu lui rappelles de manger/s'entrainer
- Tu es dispo H24 pour ses questions

## FORMAT
- MAX 5 phrases courtes. Pas de longs paragraphes.
- PAS de markdown (pas de **gras**, pas de listes a puces)
- Texte simple et direct
- TOUJOURS terminer par une question (meme simple: "ca te parle ?", "on est d'accord ?", "t'en penses quoi ?")

## CE QUE TU NE FAIS JAMAIS
- Finir sans question (INTERDIT sauf echange 5)
- Messages trop longs (5 phrases MAX)
- Markdown ou formatage special
- Rester bloque sur le meme sujet
- Oublier l'aspect emotionnel
- Dire "l'app", "our app"

## ECHANGE ACTUEL: ${_userExchangeCount + 1}/5
${_userExchangeCount == 0 ? "-> Focus: MOTIVATION - Creuser pourquoi il veut changer" : ""}
${_userExchangeCount == 1 ? "-> Focus: PAIN POINTS - Ce qui l'a bloque avant" : ""}
${_userExchangeCount == 2 ? "-> Focus: COMMENT TU AIDES - Sport ET nutrition" : ""}
${_userExchangeCount == 3 ? "-> Focus: EMOTION - Comment il va se sentir, projection futur" : ""}
${_userExchangeCount >= 4 ? "-> Focus: CONTRAT - Recap + proposition du deal hebdo" : ''}

## LANGUE
${isEnglish ? 'Respond in English.' : isGerman ? 'Antworte auf Deutsch.' : 'Reponds en francais.'}
''';
  }

  /// Clean markdown formatting from response
  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // Remove **bold**
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1') // Remove *italic*
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1') // Remove __bold__
        .replaceAll(RegExp(r'_([^_]+)_'), r'$1') // Remove _italic_
        .replaceAll(RegExp(r'^[-*]\s', multiLine: true), '') // Remove bullet points
        .replaceAll(RegExp(r'^\d+\.\s', multiLine: true), '') // Remove numbered lists
        .trim();
  }

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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending || _chatSession == null) return;

    setState(() {
      _isSending = true;
      _textController.clear();
      _messages.add(_ChatMessage(content: text, isUser: true));
      _userExchangeCount++;
    });
    _scrollToBottom();

    try {
      // Rebuild prompt with updated exchange count
      final lang = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
      final contextPrompt = "[EXCHANGE ${_userExchangeCount}/$_maxExchanges]\n$text";

      // Get response from Gemini
      final response = await _chatSession!.sendMessage(Content.text(contextPrompt));
      var responseText = response.text ?? '';

      // Clean markdown formatting
      responseText = _cleanMarkdown(responseText);

      if (mounted && responseText.isNotEmpty) {
        // Typing effect
        String displayedText = '';
        setState(() {
          _messages.add(_ChatMessage(content: '', isUser: false));
        });

        for (int i = 0; i < responseText.length; i += 3) {
          if (!mounted) break;
          displayedText = responseText.substring(0, (i + 3).clamp(0, responseText.length));
          setState(() {
            _messages[_messages.length - 1] = _ChatMessage(
              content: displayedText,
              isUser: false,
            );
          });
          await Future.delayed(const Duration(milliseconds: 15));
        }

        // Ensure full text is displayed
        setState(() {
          _messages[_messages.length - 1] = _ChatMessage(
            content: responseText,
            isUser: false,
          );
        });
        _scrollToBottom();

        // Check if we've reached max exchanges
        if (_userExchangeCount >= _maxExchanges) {
          setState(() {
            _isConversationDone = true;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  /// Extract key insights from the onboarding conversation and save to preferences
  Future<void> _extractAndSaveInsights() async {
    if (_messages.length < 2) return; // Need at least 1 user message

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Build conversation text
      final conversationText = _messages
          .map((m) => '${m.isUser ? "User" : "Coach"}: ${m.content}')
          .join('\n\n');

      // Use Gemini to extract key insights
      final extractionPrompt = '''
Tu es un assistant qui extrait les informations clés d'une conversation d'onboarding fitness.

Analyse cette conversation et extrait les informations importantes que le coach devra se souvenir:

---
$conversationText
---

Retourne un résumé structuré et concis (max 200 mots) avec ces catégories SI elles sont mentionnées:
- **Motivation principale**: pourquoi il utilise l'app (ex: perdre du poids pour un mariage)
- **Objectif concret**: ce qu'il veut atteindre (ex: perdre 10kg, courir 5km)
- **Blocages passés**: ce qui l'a empêché de réussir avant (ex: manque de temps, régimes trop stricts)
- **Contexte émotionnel**: événements ou émotions liés au fitness (ex: rupture, manque de confiance)
- **Contraintes**: limitations connues (ex: blessure, allergie, emploi du temps)

IMPORTANT:
- N'invente RIEN. Extrait uniquement ce qui est explicitement dit par l'utilisateur.
- Si une catégorie n'est pas mentionnée, ne l'inclus pas.
- Sois concis mais précis.
- Format: texte simple, pas de JSON.
''';

      final response = await _model!.generateContent([Content.text(extractionPrompt)]);
      final insights = response.text?.trim();

      if (insights == null || insights.isEmpty) {
        if (kDebugMode) debugPrint('⚠️ No insights extracted from onboarding');
        return;
      }

      if (kDebugMode) {
        debugPrint('');
        debugPrint('💡 ========== ONBOARDING INSIGHTS ==========');
        debugPrint(insights);
        debugPrint('============================================');
        debugPrint('');
      }

      // Get existing preferences to merge
      final existingResponse = await Supabase.instance.client
          .from('user_coach_preferences')
          .select('preferences')
          .eq('user_id', user.id)
          .maybeSingle();

      Map<String, dynamic> existingPrefs = {};
      if (existingResponse != null && existingResponse['preferences'] != null) {
        existingPrefs = Map<String, dynamic>.from(existingResponse['preferences']);
      }

      // Merge with existing preferences (don't overwrite other data)
      existingPrefs['onboarding_insights'] = insights;

      // Save to user_coach_preferences
      await Supabase.instance.client.from('user_coach_preferences').upsert({
        'user_id': user.id,
        'preferences': existingPrefs,
        'last_extraction_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) debugPrint('✅ Onboarding insights saved to preferences');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error extracting onboarding insights: $e');
      // Don't block onboarding if extraction fails
    }
  }

  /// Handle skip button - extract insights then complete
  Future<void> _handleSkip() async {
    await _extractAndSaveInsights();
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }

  /// Handle "Voir le contrat" button
  Future<void> _handleSeeContract() async {
    await _extractAndSaveInsights();
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(lang),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          // Show contract button after 5 exchanges, otherwise show input
          if (_isConversationDone)
            _buildContractButton(lang)
          else
            _buildInputBar(lang),
        ],
      ),
    );
  }

  Widget _buildContractButton(String lang) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: GestureDetector(
        onTap: _handleSeeContract,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B132B).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              lang == 'fr' ? 'Voir le contrat 🤝' : lang == 'de' ? 'Vertrag ansehen 🤝' : 'See the contract 🤝',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String lang) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
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
                  'Coach Ryze 🐼',
                  style: const TextStyle(
                    color: Color(0xFF0B132B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isSending)
                  Text(
                    lang == 'fr' ? 'écrit...' : lang == 'de' ? 'schreibt...' : 'typing...',
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
        // Exchange counter
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$_userExchangeCount/$_maxExchanges',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Skip button (visible after 3 exchanges)
        if (_userExchangeCount >= _minExchangesToSkip)
          TextButton(
            onPressed: _handleSkip,
            child: Text(
              lang == 'fr' ? 'Passer' : lang == 'de' ? 'Überspringen' : 'Skip',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: 16, left: isUser ? 48 : 0, right: isUser ? 0 : 48),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CoachRyzeAvatar(
              type: CoachRyzeAvatarType.nutritionChat,
              size: CoachRyzeAvatarSize.small,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // User: gradient, Coach: white (matches ChatMessageBubble)
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                      )
                    : null,
                color: isUser ? null : Colors.white,
                // Exact same borderRadius as ChatMessageBubble
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 4),
                  topRight: const Radius.circular(20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF0B132B),
                  fontSize: 15,
                  height: isUser ? 1.4 : 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(String lang) {
    final charCount = _textController.text.length;
    final showCharCount = charCount > 400;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
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
                    maxLines: 3,
                    minLines: 1,
                    maxLength: _maxCharacters,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: lang == 'fr' ? 'Écris ton message...' : lang == 'de' ? 'Schreibe deine Nachricht...' : 'Type your message...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      counterText: '', // Hide default counter
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
          // Character counter (visible when > 400)
          if (showCharCount)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$charCount/$_maxCharacters',
                style: TextStyle(
                  fontSize: 12,
                  color: charCount > 480 ? Colors.orange : const Color(0xFF94A3B8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple chat message model for onboarding (not persisted)
class _ChatMessage {
  final String content;
  final bool isUser;

  _ChatMessage({
    required this.content,
    required this.isUser,
  });
}
