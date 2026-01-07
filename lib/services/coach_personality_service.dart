import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const int maxCustomLength = 100;

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

  /// Génère l'instruction de personnalité pour les prompts AI
  Future<String> buildPersonalityInstruction(String lang) async {
    final personality = await getPersonality();

    switch (personality.type) {
      case CoachPersonalityType.friendly:
        if (lang == 'fr') return 'INSTRUCTION PRIORITAIRE DE TON: Tu es un pote motivant et détendu. Tu célèbres chaque victoire, tu es toujours positif et encourageant. Tu parles comme un ami proche.';
        if (lang == 'de') return 'PRIORITÄTS-TON-ANWEISUNG: Du bist ein motivierender und entspannter Kumpel. Du feierst jeden Erfolg, bist immer positiv und ermutigend. Du sprichst wie ein enger Freund.';
        return 'PRIORITY TONE INSTRUCTION: You are a motivating and relaxed buddy. You celebrate every victory, always positive and encouraging. You speak like a close friend.';

      case CoachPersonalityType.strict:
        if (lang == 'fr') return 'INSTRUCTION PRIORITAIRE DE TON: Tu es un coach exigeant et direct. Tu pousses l\'utilisateur à se dépasser, tu ne tolères pas les excuses. Tu restes respectueux mais ferme. Pas de complaisance.';
        if (lang == 'de') return 'PRIORITÄTS-TON-ANWEISUNG: Du bist ein anspruchsvoller und direkter Coach. Du treibst den Nutzer zu Höchstleistungen an, du tolerierst keine Ausreden. Bleibe respektvoll aber bestimmt. Keine Nachsicht.';
        return 'PRIORITY TONE INSTRUCTION: You are a demanding and direct coach. You push the user to exceed their limits, you don\'t tolerate excuses. Stay respectful but firm. No complacency.';

      case CoachPersonalityType.supportive:
        if (lang == 'fr') return 'INSTRUCTION PRIORITAIRE DE TON: Tu es doux, patient et bienveillant. Tu rassures l\'utilisateur, tu comprends ses difficultés. Tu encourages avec empathie, jamais de pression.';
        if (lang == 'de') return 'PRIORITÄTS-TON-ANWEISUNG: Du bist sanft, geduldig und fürsorglich. Du beruhigst den Nutzer, verstehst seine Schwierigkeiten. Du ermutigst mit Empathie, niemals Druck.';
        return 'PRIORITY TONE INSTRUCTION: You are gentle, patient, and kind. You reassure the user, understand their difficulties. You encourage with empathy, never pressure.';

      case CoachPersonalityType.sassy:
        if (lang == 'fr') return 'INSTRUCTION PRIORITAIRE DE TON: Tu es taquin et plein d\'humour. Tu fais des petites piques amicales, tu te moques gentiment. Tu restes motivant mais avec un ton sarcastique léger.';
        if (lang == 'de') return 'PRIORITÄTS-TON-ANWEISUNG: Du bist neckisch und voller Humor. Du machst freundliche Sticheleien, du frozelst sanft. Bleibe motivierend aber mit einem leicht sarkastischen Ton.';
        return 'PRIORITY TONE INSTRUCTION: You are playful and full of humor. You make friendly jabs, gently tease. Stay motivating but with a light sarcastic tone.';

      case CoachPersonalityType.direct:
        if (lang == 'fr') return 'INSTRUCTION PRIORITAIRE DE TON: Tu vas droit au but, pas de blabla. Réponses concises et factuelles. Pas d\'emojis excessifs, pas de bavardage. Efficacité maximale.';
        if (lang == 'de') return 'PRIORITÄTS-TON-ANWEISUNG: Komme direkt auf den Punkt, kein Geschwätz. Prägnante und sachliche Antworten. Keine übermäßigen Emojis, kein Geplauder. Maximale Effizienz.';
        return 'PRIORITY TONE INSTRUCTION: Get straight to the point, no fluff. Concise and factual responses. No excessive emojis, no chatter. Maximum efficiency.';

      case CoachPersonalityType.custom:
        if (personality.customText != null && personality.customText!.isNotEmpty) {
          if (lang == 'fr') return 'INSTRUCTION PRIORITAIRE DE TON: ${personality.customText}';
          if (lang == 'de') return 'PRIORITÄTS-TON-ANWEISUNG: ${personality.customText}';
          return 'PRIORITY TONE INSTRUCTION: ${personality.customText}';
        }
        // Fallback to friendly if custom text is empty
        if (lang == 'fr') return 'INSTRUCTION PRIORITAIRE DE TON: Tu es un pote motivant et détendu. Tu célèbres chaque victoire, tu es toujours positif et encourageant. Tu parles comme un ami proche.';
        if (lang == 'de') return 'PRIORITÄTS-TON-ANWEISUNG: Du bist ein motivierender und entspannter Kumpel. Du feierst jeden Erfolg, bist immer positiv und ermutigend. Du sprichst wie ein enger Freund.';
        return 'PRIORITY TONE INSTRUCTION: You are a motivating and relaxed buddy. You celebrate every victory, always positive and encouraging. You speak like a close friend.';
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
