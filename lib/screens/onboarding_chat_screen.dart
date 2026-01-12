import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/gemini_config.dart';
import '../services/localization_service.dart';

/// Onboarding chat screen with Coach Ryze - Glassmorphism design
/// Background: Last frame of onboarding video
/// Chat bubbles: Glass effect with BackdropFilter
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

class _OnboardingChatScreenState extends State<OnboardingChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isConversationDone = false;
  int _userExchangeCount = 0;
  static const int _maxExchanges = 5;
  static const int _minExchangesToSkip = 3;
  static const int _maxCharacters = 500;

  // Ryse dark blue color for text
  static const Color _ryseDarkBlue = Color(0xFF0B132B);

  GenerativeModel? _model;
  ChatSession? _chatSession;

  // Animation for reveal effect (middle to edges)
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  // Flag to show "typing" indicator before first message
  bool _isCoachTyping = false;

  @override
  void initState() {
    super.initState();
    // Immersive mode for premium feel
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Setup reveal animation
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );

    // Start reveal animation
    _revealController.forward();

    _initializeChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final lang = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;

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

    final systemPrompt = _buildOnboardingPrompt(lang);

    _chatSession = _model!.startChat(history: [
      Content.text('[SYSTEM INSTRUCTIONS]\n$systemPrompt'),
      Content.model([TextPart(_getAcknowledgement(lang))]),
    ]);

    final welcomeMessage = lang == 'fr'
        ? "Hey, bienvenue ! 🐼 On est les Coach Ryze, ton duo sport et nutrition. Ensemble, on va t'aider à atteindre tes objectifs. Qu'est-ce qui t'a donné envie de nous rejoindre ?"
        : lang == 'de'
            ? "Hey, willkommen! 🐼 Wir sind die Coach Ryze, dein Sport- und Ernährungs-Duo. Zusammen werden wir dir helfen, deine Ziele zu erreichen. Was hat dich dazu gebracht, uns beizutreten?"
            : "Hey, welcome! 🐼 We're the Coach Ryze team, your sport and nutrition duo. Together, we'll help you reach your goals. What made you want to join us?";

    // Wait 1 second to simulate coach "typing" like iMessage
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    // Show typing indicator
    setState(() {
      _isCoachTyping = true;
    });

    // Wait another 500ms for typing effect
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Add message with animation effect like iMessage
    setState(() {
      _isCoachTyping = false;
      _messages.add(_ChatMessage(content: welcomeMessage, isUser: false));
    });
  }

  String _getAcknowledgement(String lang) {
    return lang == 'fr'
        ? "Compris ! On est les Coach Ryze, prêts pour l'onboarding."
        : lang == 'de'
            ? "Verstanden! Wir sind die Coach Ryze, bereit für das Onboarding."
            : "Got it! We're the Coach Ryze team, ready for onboarding.";
  }

  String _buildOnboardingPrompt(String lang) {
    final isEnglish = lang == 'en';
    final isGerman = lang == 'de';

    return '''
Tu es les Coach Ryze, un DUO de coachs : un coach sportif et un coach nutritionnel (les deux pandas qu'on voit). Tu parles au "NOUS". Tu es un EXCELLENT VENDEUR. Tu dois couvrir TOUS les sujets en 5 echanges.

## REGLE ABSOLUE : PREMIERE PERSONNE PLURIEL
Tu dis "ON va t'aider", "ON te fait", "ON te guide", "NOUS sommes la". JAMAIS "l'app", "our app", jamais "je".

## OBJECTIF EN 5 ECHANGES
Tu dois ABSOLUMENT couvrir ces themes (pas rester bloque sur un seul sujet):
- Motivation profonde (pourquoi il veut changer)
- Pain points (ce qui l'a empeche de reussir avant)
- Comment ON va l'aider (sport ET nutrition - on est deux coachs!)
- Projection emotionnelle (comment il va se SENTIR)
- Engagement (le contrat)

## STRUCTURE PAR ECHANGE

ECHANGE 1 (actuel: ${_userExchangeCount + 1}/5) - MOTIVATION
-> Comprendre pourquoi il a telecharge. Creuser l'emotion derriere l'objectif.
-> Question: "Qu'est-ce qui t'a fait passer a l'action maintenant ?" ou similaire

ECHANGE 2 - PAIN POINTS
-> Comprendre ce qui l'a bloque avant. Montrer de l'empathie.
-> Question: "C'est quoi qui t'a empeche d'y arriver jusqu'ici ?" ou sur la nutrition

ECHANGE 3 - COMMENT ON L'AIDE
-> Montrer nos features: programmes sport, scan repas, suivi calories, coaching H24
-> Mentionner qu'on est DEUX coachs: un pour le sport, un pour la nutrition
-> Question: orienter vers ce qu'on n'a pas encore couvert

ECHANGE 4 - PROJECTION EMOTIONNELLE
-> Lui faire visualiser le resultat. Jouer sur l'emotion.
-> "Imagine dans 3 mois, tu te regardes dans le miroir et..."
-> "Tu vas te sentir tellement mieux, plus confiant, plus energique..."
-> Question: preparer le terrain pour le contrat

ECHANGE 5 - CONTRAT
-> Recapituler son objectif + ses blocages + comment on l'aide
-> Proposer le deal: "Chaque semaine on fait le point ensemble, 2 min. Deal ? 🐼"

## VENTE EMOTIONNELLE
- Utilise l'evenement mentionne (mariage, ete, etc.) pour creer l'urgence
- Projette-le dans le futur: "Imagine la tete des gens quand ils vont te voir"
- Parle de confiance en soi, energie, fierte
- Montre qu'ON est la solution a ses problemes passes (duo sport + nutrition)

## CE QU'ON FAIT (en tant que duo)
- On scanne ses repas en photo et on compte les calories (coach nutrition)
- On cree des programmes sport personnalises (coach sport)
- On le motive et on le suit au quotidien
- On lui rappelle de manger/s'entrainer
- On est dispo H24 pour ses questions

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
- Dire "l'app", "our app", "je" (toujours "on" ou "nous")

## ECHANGE ACTUEL: ${_userExchangeCount + 1}/5
${_userExchangeCount == 0 ? "-> Focus: MOTIVATION - Creuser pourquoi il veut changer" : ""}
${_userExchangeCount == 1 ? "-> Focus: PAIN POINTS - Ce qui l'a bloque avant" : ""}
${_userExchangeCount == 2 ? "-> Focus: COMMENT ON AIDE - Sport ET nutrition (duo de coachs)" : ""}
${_userExchangeCount == 3 ? "-> Focus: EMOTION - Comment il va se sentir, projection futur" : ""}
${_userExchangeCount >= 4 ? "-> Focus: CONTRAT - Recap + proposition du deal hebdo" : ''}

## LANGUE
${isEnglish ? 'Respond in English. Use "we" not "I".' : isGerman ? 'Antworte auf Deutsch. Benutze "wir" nicht "ich".' : 'Reponds en francais. Utilise "on/nous" pas "je".'}
''';
  }

  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        .replaceAll(RegExp(r'_([^_]+)_'), r'$1')
        .replaceAll(RegExp(r'^[-*]\s', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\.\s', multiLine: true), '')
        .trim();
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
    if (text.isEmpty || _isSending || _chatSession == null) return;

    setState(() {
      _isSending = true;
      _textController.clear();
      _messages.add(_ChatMessage(content: text, isUser: true));
      _userExchangeCount++;
    });
    _scrollToBottom();

    try {
      final contextPrompt = "[EXCHANGE ${_userExchangeCount}/$_maxExchanges]\n$text";
      final response = await _chatSession!.sendMessage(Content.text(contextPrompt));
      var responseText = response.text ?? '';
      responseText = _cleanMarkdown(responseText);

      if (mounted && responseText.isNotEmpty) {
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

        setState(() {
          _messages[_messages.length - 1] = _ChatMessage(
            content: responseText,
            isUser: false,
          );
        });
        _scrollToBottom();

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

  Future<void> _extractAndSaveInsights() async {
    if (_messages.length < 2) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final conversationText = _messages
          .map((m) => '${m.isUser ? "User" : "Coach"}: ${m.content}')
          .join('\n\n');

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

      final existingResponse = await Supabase.instance.client
          .from('user_coach_preferences')
          .select('preferences')
          .eq('user_id', user.id)
          .maybeSingle();

      Map<String, dynamic> existingPrefs = {};
      if (existingResponse != null && existingResponse['preferences'] != null) {
        existingPrefs = Map<String, dynamic>.from(existingResponse['preferences']);
      }

      existingPrefs['onboarding_insights'] = insights;

      await Supabase.instance.client.from('user_coach_preferences').upsert(
        {
          'user_id': user.id,
          'preferences': existingPrefs,
          'last_extraction_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      if (kDebugMode) debugPrint('✅ Onboarding insights saved to preferences');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error extracting onboarding insights: $e');
    }
  }

  Future<void> _handleSkip() async {
    await _extractAndSaveInsights();
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }

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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Keep image fixed when keyboard opens
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with reveal animation (middle to edges)
          AnimatedBuilder(
            animation: _revealAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (Rect bounds) {
                  // Reveal from middle: animation 0->1 expands the visible area
                  final progress = _revealAnimation.value;

                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [
                      (0.4 - progress * 0.4).clamp(0.0, 1.0), // Top edge moves up
                      (0.4 - progress * 0.3).clamp(0.0, 1.0), // Top fade
                      (0.4 + progress * 0.5).clamp(0.0, 1.0), // Bottom fade
                      (0.4 + progress * 0.6).clamp(0.0, 1.0), // Bottom edge moves down
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/onboarding_chat_background.png',
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),

          // Gradient overlay at bottom only (for input bar transition)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.35,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF1A1A1A).withOpacity(0.5),
                    const Color(0xFF1A1A1A).withOpacity(0.85),
                    const Color(0xFF1A1A1A),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Counter badge - fixed at very top of screen
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _buildCounterBadge(lang),
          ),

          // Chat zone - full screen like iMessage/WhatsApp
          Positioned(
            top: MediaQuery.of(context).padding.top + 40, // Below status bar + counter badge
            left: 0,
            right: 0,
            bottom: keyboardHeight > 0 ? keyboardHeight : 0,
            child: Column(
              children: [
                // Header "Faisons connaissance"
                _buildChatHeader(lang),

                // Messages list (takes all available space)
                Expanded(child: _buildMessagesList()),

                // Input bar or contract button
                Padding(
                  padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 0 : bottomPadding),
                  child: _isConversationDone
                      ? _buildContractButton(lang, 0)
                      : _buildInputBar(lang, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBadge(String lang) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Exchange counter
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                '$_userExchangeCount/$_maxExchanges',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Skip button
        if (_userExchangeCount >= _minExchangesToSkip) ...[
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: GestureDetector(
                onTap: _handleSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    lang == 'fr' ? 'Passer' : lang == 'de' ? 'Überspringen' : 'Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChatHeader(String lang) {
    final headerText = lang == 'fr'
        ? 'Faisons connaissance'
        : lang == 'de'
            ? 'Lass uns kennenlernen'
            : "Let's get to know each other";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              headerText,
              style: const TextStyle(
                color: _ryseDarkBlue,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    // Calculate total items: messages + typing indicator if active
    final itemCount = _messages.length + (_isCoachTyping ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      reverse: true, // New messages at bottom, scroll naturally like iMessage
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show typing indicator at the bottom (index 0 in reversed list)
        if (_isCoachTyping && index == 0) {
          return _buildTypingIndicator();
        }

        // Adjust index for messages when typing indicator is showing
        final messageIndex = _isCoachTyping ? index - 1 : index;
        final message = _messages[_messages.length - 1 - messageIndex];
        return _buildGlassMessageBubble(message);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
        left: 16,
        right: 48,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.40),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    const SizedBox(width: 4),
                    _buildTypingDot(1),
                    const SizedBox(width: 4),
                    _buildTypingDot(2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return _AnimatedTypingDot(
      index: index,
      color: _ryseDarkBlue,
    );
  }

  Widget _buildGlassMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isUser ? 20 : 4),
      topRight: Radius.circular(isUser ? 4 : 20),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 48 : 16,
        right: isUser ? 16 : 48,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.white.withOpacity(0.30)
                        : Colors.white.withOpacity(0.40),
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: Colors.white.withOpacity(isUser ? 0.35 : 0.45),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(
                      color: _ryseDarkBlue,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(String lang, double bottomPadding) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: bottomPadding + 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 3,
                minLines: 1,
                maxLength: _maxCharacters,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: lang == 'fr'
                      ? 'Écris ton message...'
                      : lang == 'de'
                          ? 'Schreibe deine Nachricht...'
                          : 'Type your message...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  counterText: '',
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
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

  Widget _buildContractButton(String lang, double bottomPadding) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: bottomPadding + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
      ),
      child: GestureDetector(
        onTap: _handleSeeContract,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  lang == 'fr'
                      ? 'Voir le contrat 🤝'
                      : lang == 'de'
                          ? 'Vertrag ansehen 🤝'
                          : 'See the contract 🤝',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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

/// Animated typing dot with continuous bounce animation like iMessage
class _AnimatedTypingDot extends StatefulWidget {
  final int index;
  final Color color;

  const _AnimatedTypingDot({
    required this.index,
    required this.color,
  });

  @override
  State<_AnimatedTypingDot> createState() => _AnimatedTypingDotState();
}

class _AnimatedTypingDotState extends State<_AnimatedTypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Staggered delay based on dot index
    final delay = widget.index * 0.15;
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(delay, 1.0, curve: Curves.linear),
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.5 + 0.3 * _animation.value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
