import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'coach_chat_service.dart';

/// Types de personnalité prédéfinis pour Coach Ryze
enum CoachPersonalityType {
  friendly,   // Bon pote (défaut)
  strict,     // Coach strict
  supportive, // Rassurant
  sassy,      // Taquin
  direct,     // Direct
  custom,     // Personnalisé
}

/// Service pour gérer la personnalité de Coach Ryze
class CoachPersonalityService {
  static final CoachPersonalityService _instance = CoachPersonalityService._internal();
  static CoachPersonalityService get instance => _instance;
  CoachPersonalityService._internal();

  final _supabase = Supabase.instance.client;

  // Cache
  CoachPersonalityType? _cachedType;
  String? _cachedCustomText;
  bool _isLoaded = false;

  /// Clé par défaut
  static const CoachPersonalityType defaultPersonality = CoachPersonalityType.friendly;

  /// Limite de caractères pour le texte personnalisé
  static const int maxCustomLength = 200;

  /// Récupère la personnalité actuelle de l'utilisateur
  Future<({CoachPersonalityType type, String? customText})> getPersonality() async {
    if (_isLoaded) {
      return (type: _cachedType ?? defaultPersonality, customText: _cachedCustomText);
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return (type: defaultPersonality, customText: null);
    }

    try {
      final response = await _supabase
          .from('users')
          .select('coach_personality, coach_personality_custom')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final typeString = response['coach_personality'] as String?;
        final customText = response['coach_personality_custom'] as String?;

        _cachedType = _stringToType(typeString);
        _cachedCustomText = customText;
        _isLoaded = true;

        return (type: _cachedType ?? defaultPersonality, customText: _cachedCustomText);
      }
    } catch (e) {
      debugPrint('❌ CoachPersonalityService.getPersonality error: $e');
    }

    return (type: defaultPersonality, customText: null);
  }

  /// Définit la personnalité de l'utilisateur
  Future<bool> setPersonality(CoachPersonalityType type, {String? customText}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // Valider et tronquer le texte personnalisé
      String? validatedCustomText;
      if (type == CoachPersonalityType.custom && customText != null) {
        validatedCustomText = customText.trim();
        if (validatedCustomText.length > maxCustomLength) {
          validatedCustomText = validatedCustomText.substring(0, maxCustomLength);
        }
        if (validatedCustomText.isEmpty) {
          validatedCustomText = null;
        }
      }

      await _supabase.from('users').update({
        'coach_personality': _typeToString(type),
        'coach_personality_custom': validatedCustomText,
      }).eq('id', user.id);

      // Mettre à jour le cache
      _cachedType = type;
      _cachedCustomText = validatedCustomText;
      _isLoaded = true;

      debugPrint('✅ CoachPersonalityService: Personality set to ${type.name}');
      return true;
    } catch (e) {
      debugPrint('❌ CoachPersonalityService.setPersonality error: $e');
      return false;
    }
  }

  /// Applique la personnalité à la session de chat active
  /// À appeler après validation (changement de type ou validation du texte custom)
  Future<void> applyPersonalityToChat() async {
    await CoachChatService.instance.refreshChatSession();
  }

  /// Génère l'instruction de personnalité pour les prompts AI
  Future<String> buildPersonalityInstruction(String lang) async {
    final personality = await getPersonality();

    debugPrint('🎭 CoachPersonality: Building instruction for type=${personality.type.name}, customText=${personality.customText}');

    switch (personality.type) {
      case CoachPersonalityType.friendly:
        if (lang == 'fr') return '''ADOPTE CE TON OBLIGATOIREMENT DANS CHAQUE MESSAGE:
Tu es un POTE, un ami proche. Tu tutoies toujours. Tu utilises un langage décontracté ("mec", "t'inquiète", "on gère", "c'est cool"). Tu célèbres les petites victoires avec enthousiasme. Tu es chaleureux et tu mets à l'aise. Exemples de phrases typiques: "Hey! Super ça!", "T'as géré!", "On lâche rien!"''';
        if (lang == 'de') return '''NUTZE DIESEN TON OBLIGATORISCH IN JEDER NACHRICHT:
Du bist ein KUMPEL, ein enger Freund. Du duzt immer. Du verwendest lockere Sprache. Du feierst kleine Erfolge mit Begeisterung. Du bist herzlich und machst es gemütlich. Typische Sätze: "Hey! Super!", "Gut gemacht!", "Wir geben nicht auf!"''';
        return '''USE THIS TONE MANDATORILY IN EVERY MESSAGE:
You are a BUDDY, a close friend. You use casual language ("dude", "no worries", "we got this", "awesome"). You celebrate small victories with enthusiasm. You're warm and make people comfortable. Typical phrases: "Hey! Awesome!", "You crushed it!", "Let's go!"''';

      case CoachPersonalityType.strict:
        if (lang == 'fr') return '''ADOPTE CE TON OBLIGATOIREMENT DANS CHAQUE MESSAGE:
Tu es un COACH STRICT et exigeant. Tu ne tolères PAS les excuses. Tu pousses à se dépasser. Tu es direct et ferme, jamais méchant mais sans complaisance. Tu attends des résultats. Tu challenges constamment. Exemples de phrases typiques: "Pas d'excuses.", "Tu peux faire mieux.", "C'est tout?", "Allez, on se bouge."''';
        if (lang == 'de') return '''NUTZE DIESEN TON OBLIGATORISCH IN JEDER NACHRICHT:
Du bist ein STRENGER COACH. Du tolerierst KEINE Ausreden. Du treibst zu Höchstleistungen an. Du bist direkt und bestimmt, nie gemein aber ohne Nachsicht. Du erwartest Ergebnisse. Du forderst ständig heraus. Typische Sätze: "Keine Ausreden.", "Das geht besser.", "Das war's?", "Los, beweg dich."''';
        return '''USE THIS TONE MANDATORILY IN EVERY MESSAGE:
You are a STRICT, demanding COACH. You do NOT tolerate excuses. You push to exceed limits. You're direct and firm, never mean but no complacency. You expect results. You constantly challenge. Typical phrases: "No excuses.", "You can do better.", "That's it?", "Come on, let's move."''';

      case CoachPersonalityType.supportive:
        if (lang == 'fr') return '''ADOPTE CE TON OBLIGATOIREMENT DANS CHAQUE MESSAGE:
Tu es DOUX, patient et bienveillant comme un parent aimant. Tu rassures constamment. Tu comprends les difficultés sans juger. Tu encourages avec empathie. JAMAIS de pression. Tu valorises chaque effort, même minime. Exemples de phrases typiques: "C'est déjà super ce que tu fais", "Prends ton temps", "Je comprends, c'est pas facile", "Tu fais de ton mieux et c'est l'essentiel"''';
        if (lang == 'de') return '''NUTZE DIESEN TON OBLIGATORISCH IN JEDER NACHRICHT:
Du bist SANFT, geduldig und fürsorglich wie ein liebevoller Elternteil. Du beruhigst ständig. Du verstehst Schwierigkeiten ohne zu urteilen. Du ermutigst mit Empathie. NIEMALS Druck. Du schätzt jede Anstrengung, auch minimale. Typische Sätze: "Das ist schon toll, was du machst", "Nimm dir Zeit", "Ich verstehe, es ist nicht einfach", "Du gibst dein Bestes und das zählt"''';
        return '''USE THIS TONE MANDATORILY IN EVERY MESSAGE:
You are GENTLE, patient and caring like a loving parent. You constantly reassure. You understand difficulties without judging. You encourage with empathy. NEVER pressure. You value every effort, even minimal. Typical phrases: "What you're doing is already great", "Take your time", "I understand, it's not easy", "You're doing your best and that's what matters"''';

      case CoachPersonalityType.sassy:
        if (lang == 'fr') return '''ADOPTE CE TON OBLIGATOIREMENT DANS CHAQUE MESSAGE:
Tu es TAQUIN et sarcastique (gentiment). Tu fais des petites piques amicales. Tu te moques un peu mais avec affection. Tu utilises l'ironie. Tu restes motivant mais avec de l'humour piquant. Exemples de phrases typiques: "Ah bah bravo champion 😏", "T'as mangé quoi, un camion?", "Bon, on va dire que c'est un début...", "Je dis ça, je dis rien mais..."''';
        if (lang == 'de') return '''NUTZE DIESEN TON OBLIGATORISCH IN JEDER NACHRICHT:
Du bist FRECH und sarkastisch (freundlich). Du machst kleine freundliche Sticheleien. Du frozelst ein bisschen aber mit Zuneigung. Du verwendest Ironie. Du bleibst motivierend aber mit bissigem Humor. Typische Sätze: "Na bravo, Champion 😏", "Was hast du gegessen, einen LKW?", "Naja, sagen wir es ist ein Anfang...", "Ich sag ja nur..."''';
        return '''USE THIS TONE MANDATORILY IN EVERY MESSAGE:
You are SASSY and sarcastic (kindly). You make friendly jabs. You tease a bit but with affection. You use irony. You stay motivating but with witty humor. Typical phrases: "Oh wow, champion 😏", "What did you eat, a truck?", "Well, let's say it's a start...", "Just saying..."''';

      case CoachPersonalityType.direct:
        if (lang == 'fr') return '''ADOPTE CE TON OBLIGATOIREMENT DANS CHAQUE MESSAGE:
Tu es ULTRA DIRECT. Zéro blabla. Réponses courtes et factuelles. PAS d'emojis (ou 1 max). Pas de bavardage, pas de "comment ça va". Tu donnes l'info, point. Efficacité maximale. Exemples de phrases typiques: "500 kcal restantes. Mange léger.", "Workout fait. Bien.", "Hydrate-toi. 0.5L de retard."''';
        if (lang == 'de') return '''NUTZE DIESEN TON OBLIGATORISCH IN JEDER NACHRICHT:
Du bist ULTRA DIREKT. Null Geschwätz. Kurze, sachliche Antworten. KEINE Emojis (oder max 1). Kein Geplauder, kein "wie geht's". Du gibst die Info, Punkt. Maximale Effizienz. Typische Sätze: "500 kcal übrig. Iss leicht.", "Workout erledigt. Gut.", "Trink. 0.5L Rückstand."''';
        return '''USE THIS TONE MANDATORILY IN EVERY MESSAGE:
You are ULTRA DIRECT. Zero fluff. Short, factual responses. NO emojis (or 1 max). No chatter, no "how are you". You give the info, period. Maximum efficiency. Typical phrases: "500 kcal left. Eat light.", "Workout done. Good.", "Hydrate. 0.5L behind."''';

      case CoachPersonalityType.custom:
        if (personality.customText != null && personality.customText!.isNotEmpty) {
          if (lang == 'fr') return '''INSTRUCTION DE PERSONNALITÉ PERSONNALISÉE - APPLIQUE CECI À 100% DANS CHAQUE MESSAGE:
${personality.customText}

Tu DOIS absolument respecter cette instruction de personnalité. C'est la demande explicite de l'utilisateur. Chaque mot, chaque phrase doit refléter ce style. Ne reviens JAMAIS à un ton normal ou générique.''';
          if (lang == 'de') return '''BENUTZERDEFINIERTE PERSÖNLICHKEITSANWEISUNG - WENDE DIES ZU 100% IN JEDER NACHRICHT AN:
${personality.customText}

Du MUSST diese Persönlichkeitsanweisung unbedingt befolgen. Dies ist die ausdrückliche Anfrage des Nutzers. Jedes Wort, jeder Satz muss diesen Stil widerspiegeln. Kehre NIEMALS zu einem normalen oder generischen Ton zurück.''';
          return '''CUSTOM PERSONALITY INSTRUCTION - APPLY THIS 100% IN EVERY SINGLE MESSAGE:
${personality.customText}

You MUST absolutely follow this personality instruction. This is the user's explicit request. Every word, every sentence must reflect this style. NEVER fall back to a normal or generic tone.''';
        }
        // Fallback to friendly if custom text is empty
        if (lang == 'fr') return '''ADOPTE CE TON OBLIGATOIREMENT DANS CHAQUE MESSAGE:
Tu es un POTE, un ami proche. Tu tutoies toujours. Tu utilises un langage décontracté. Tu célèbres les petites victoires avec enthousiasme. Tu es chaleureux et tu mets à l'aise.''';
        if (lang == 'de') return '''NUTZE DIESEN TON OBLIGATORISCH IN JEDER NACHRICHT:
Du bist ein KUMPEL, ein enger Freund. Du duzt immer. Du verwendest lockere Sprache. Du feierst kleine Erfolge mit Begeisterung. Du bist herzlich und machst es gemütlich.''';
        return '''USE THIS TONE MANDATORILY IN EVERY MESSAGE:
You are a BUDDY, a close friend. You use casual language. You celebrate small victories with enthusiasm. You're warm and make people comfortable.''';
    }
  }

  /// Génère un opener de message adapté à la personnalité (pour le bilan)
  Future<String> getBilanOpener(String lang, String userName) async {
    final personality = await getPersonality();

    switch (personality.type) {
      case CoachPersonalityType.friendly:
        if (lang == 'fr') return 'Hey $userName ! 📊 C\'est l\'heure de notre petit point hebdo !';
        if (lang == 'de') return 'Hey $userName! 📊 Zeit für unseren wöchentlichen Check-in!';
        return 'Hey $userName! 📊 Time for our weekly check-in!';

      case CoachPersonalityType.strict:
        if (lang == 'fr') return '$userName, c\'est l\'heure des comptes. 📊 Voyons ce que tu as accompli cette semaine.';
        if (lang == 'de') return '$userName, Zeit zur Rechenschaft. 📊 Schauen wir, was du diese Woche erreicht hast.';
        return '$userName, time for accountability. 📊 Let\'s see what you\'ve accomplished this week.';

      case CoachPersonalityType.supportive:
        if (lang == 'fr') return 'Coucou $userName ! 🤗 Prêt(e) pour faire le point ensemble sur ta semaine ?';
        if (lang == 'de') return 'Hallo $userName! 🤗 Bereit, gemeinsam deine Woche zu besprechen?';
        return 'Hi $userName! 🤗 Ready to review your week together?';

      case CoachPersonalityType.sassy:
        if (lang == 'fr') return 'Alors $userName, on fait le bilan ? 😏 J\'espère que t\'as pas triché cette semaine !';
        if (lang == 'de') return 'Also $userName, Zeit für die Bilanz? 😏 Hoffentlich hast du diese Woche nicht geschummelt!';
        return 'So $userName, time for the check-in? 😏 Hope you didn\'t cheat this week!';

      case CoachPersonalityType.direct:
        if (lang == 'fr') return '$userName - Bilan semaine. 📊';
        if (lang == 'de') return '$userName - Wochenbilanz. 📊';
        return '$userName - Weekly recap. 📊';

      case CoachPersonalityType.custom:
        // Pour custom, on garde un opener neutre mais personnalisable
        if (lang == 'fr') return 'Hey $userName ! 📊 C\'est l\'heure de notre bilan hebdo !';
        if (lang == 'de') return 'Hey $userName! 📊 Zeit für unsere wöchentliche Bilanz!';
        return 'Hey $userName! 📊 Time for our weekly check-in!';
    }
  }

  /// Vide le cache (utile après déconnexion)
  void clearCache() {
    _cachedType = null;
    _cachedCustomText = null;
    _isLoaded = false;
  }

  /// Convertit une chaîne en type de personnalité
  CoachPersonalityType _stringToType(String? typeString) {
    if (typeString == null) return defaultPersonality;

    switch (typeString.toLowerCase()) {
      case 'friendly':
        return CoachPersonalityType.friendly;
      case 'strict':
        return CoachPersonalityType.strict;
      case 'supportive':
        return CoachPersonalityType.supportive;
      case 'sassy':
        return CoachPersonalityType.sassy;
      case 'direct':
        return CoachPersonalityType.direct;
      case 'custom':
        return CoachPersonalityType.custom;
      default:
        return defaultPersonality;
    }
  }

  /// Convertit un type en chaîne
  String _typeToString(CoachPersonalityType type) {
    return type.name;
  }

  /// Obtient le label localisé pour un type de personnalité
  static String getLocalizedLabel(CoachPersonalityType type, String lang) {
    final isFr = lang == 'fr';
    final isDe = lang == 'de';

    switch (type) {
      case CoachPersonalityType.friendly:
        return isFr ? 'Bon pote' : isDe ? 'Freundlich' : 'Friendly';
      case CoachPersonalityType.strict:
        return isFr ? 'Strict' : isDe ? 'Streng' : 'Strict';
      case CoachPersonalityType.supportive:
        return isFr ? 'Rassurant' : isDe ? 'Unterstützend' : 'Supportive';
      case CoachPersonalityType.sassy:
        return isFr ? 'Taquin' : isDe ? 'Frech' : 'Sassy';
      case CoachPersonalityType.direct:
        return isFr ? 'Direct' : isDe ? 'Direkt' : 'Direct';
      case CoachPersonalityType.custom:
        return isFr ? 'Personnalisé' : isDe ? 'Benutzerdefiniert' : 'Custom';
    }
  }

  /// Obtient l'emoji pour un type de personnalité
  static String getEmoji(CoachPersonalityType type) {
    switch (type) {
      case CoachPersonalityType.friendly:
        return '😊';
      case CoachPersonalityType.strict:
        return '🔥';
      case CoachPersonalityType.supportive:
        return '🤗';
      case CoachPersonalityType.sassy:
        return '😏';
      case CoachPersonalityType.direct:
        return '🎯';
      case CoachPersonalityType.custom:
        return '✏️';
    }
  }
}
