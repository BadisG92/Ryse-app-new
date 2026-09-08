import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ryze_oneshot.dart';
import '../ai/ryze_transport.dart';
import '../models/coach_chat_models.dart';

/// Service to extract user preferences from coach conversations
/// Uses AI to identify allergies, restrictions, constraints mentioned in chat
class CoachPreferenceExtractor {
  static final CoachPreferenceExtractor _instance = CoachPreferenceExtractor._internal();
  static CoachPreferenceExtractor get instance => _instance;

  CoachPreferenceExtractor._internal();

  final _supabase = Supabase.instance.client;

  /// Froid : on relève ce qui a été dit, on ne l'interprète pas.
  static const double _temperature = 0.3;
  static const int _maxOutputTokens = 1000;

  /// Le modèle n'a plus à être monté d'avance ; gardé pour les appelants.
  void initialize() {}

  /// Extract preferences from a list of messages
  Future<UserCoachPreferences?> extractFromMessages(
    List<CoachMessage> messages,
    UserCoachPreferences? existingPreferences,
  ) async {
    if (messages.isEmpty) return existingPreferences;

    try {
      // Build conversation text
      final conversationText = messages
          .map((m) => '${m.role == MessageRole.user ? "User" : "Coach"}: ${m.content}')
          .join('\n\n');

      // Build the extraction prompt
      final prompt = _buildExtractionPrompt(conversationText, existingPreferences);

      if (kDebugMode) {
        debugPrint('');
        debugPrint('🔍 ========== PREFERENCE EXTRACTION ==========');
        debugPrint('📊 Messages to analyze: ${messages.length}');
      }

      final answer = await RyzeOneShot.jsonObject(
        prompt: prompt,
        surface: RyzeUsageLabel.memory,
        temperature: _temperature,
        maxOutputTokens: _maxOutputTokens,
      );

      if (answer == null) {
        if (kDebugMode) debugPrint('❌ Empty response from Gemini');
        return existingPreferences;
      }

      final extractedPrefs = _parseExtractionResponse(answer);

      if (extractedPrefs == null) {
        return existingPreferences;
      }

      // Merge with existing preferences
      final mergedPrefs = _mergePreferences(existingPreferences, extractedPrefs);

      if (kDebugMode) {
        debugPrint('');
        debugPrint('✅ Preferences extracted:');
        debugPrint('   - Allergies: ${mergedPrefs.allergies}');
        debugPrint('   - Dietary restrictions: ${mergedPrefs.dietaryRestrictions}');
        debugPrint('   - Food preferences: ${mergedPrefs.foodPreferences}');
        debugPrint('   - Fitness constraints: ${mergedPrefs.fitnessConstraints}');
        debugPrint('');
      }

      return mergedPrefs;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error extracting preferences: $e');
      return existingPreferences;
    }
  }

  /// Build the extraction prompt
  String _buildExtractionPrompt(
    String conversationText,
    UserCoachPreferences? existing,
  ) {
    final existingJson = existing != null
        ? '''
Préférences déjà connues:
- Allergies: ${existing.allergies.join(', ')}
- Restrictions alimentaires: ${existing.dietaryRestrictions.join(', ')}
- Préférences alimentaires: ${existing.foodPreferences.join(', ')}
- Contraintes fitness: ${existing.fitnessConstraints.join(', ')}
- Horaires préférés: ${existing.preferredWorkoutTimes.join(', ')}
- Notes: ${existing.customNotes.join(', ')}
'''
        : 'Aucune préférence connue.';

    return '''
Tu es un assistant qui extrait les préférences utilisateur à partir de conversations.

$existingJson

Analyse cette conversation et extrait UNIQUEMENT les nouvelles informations mentionnées explicitement par l'utilisateur:

---
$conversationText
---

Réponds en JSON avec ce format exact:
{
  "allergies": ["liste des allergies mentionnées"],
  "dietary_restrictions": ["ex: végétarien, sans gluten, halal, etc."],
  "food_preferences": ["ex: préfère le poulet, n'aime pas les brocolis"],
  "fitness_constraints": ["ex: blessure au genou, problème de dos"],
  "preferred_workout_times": ["ex: matin, après le travail"],
  "custom_notes": ["autres informations importantes"]
}

IMPORTANT:
- N'invente RIEN. Extrait uniquement ce qui est explicitement dit par l'utilisateur.
- Si aucune nouvelle information n'est trouvée, retourne des listes vides.
- Chaque élément doit être court (2-5 mots max).
- Réponds UNIQUEMENT avec le JSON, pas de texte autour.
''';
  }

  /// Parse the extraction response
  Map<String, List<String>>? _parseExtractionResponse(Map<String, dynamic> json) {
    try {
      return {
        'allergies': List<String>.from(json['allergies'] ?? []),
        'dietary_restrictions': List<String>.from(json['dietary_restrictions'] ?? []),
        'food_preferences': List<String>.from(json['food_preferences'] ?? []),
        'fitness_constraints': List<String>.from(json['fitness_constraints'] ?? []),
        'preferred_workout_times': List<String>.from(json['preferred_workout_times'] ?? []),
        'custom_notes': List<String>.from(json['custom_notes'] ?? []),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error parsing extraction response: $e');
      return null;
    }
  }

  /// Merge existing and new preferences
  UserCoachPreferences _mergePreferences(
    UserCoachPreferences? existing,
    Map<String, List<String>> extracted,
  ) {
    final user = _supabase.auth.currentUser;

    return UserCoachPreferences(
      id: existing?.id ?? '',
      userId: user?.id ?? '',
      allergies: mergeList(existing?.allergies, extracted['allergies']),
      dietaryRestrictions: mergeList(existing?.dietaryRestrictions, extracted['dietary_restrictions']),
      foodPreferences: mergeList(existing?.foodPreferences, extracted['food_preferences']),
      fitnessConstraints: mergeList(existing?.fitnessConstraints, extracted['fitness_constraints']),
      preferredWorkoutTimes: mergeList(existing?.preferredWorkoutTimes, extracted['preferred_workout_times']),
      customNotes: mergeList(existing?.customNotes, extracted['custom_notes']),
      onboardingInsights: existing?.onboardingInsights,
      lastExtractionAt: DateTime.now(),
      extractionCount: (existing?.extractionCount ?? 0) + 1,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Réunit l'ancienne liste et la nouvelle sans doublon.
  ///
  /// La comparaison se fait sur une forme normalisée (minuscules, sans accents
  /// ni ponctuation) : le modèle réécrit rarement deux fois la même contrainte
  /// de la même façon, et une union de chaînes brutes laissait cohabiter
  /// « sans gluten » et « Sans gluten, ». La première écriture d'un fait garde
  /// sa formulation.
  static List<String> mergeList(List<String>? existing, List<String>? newItems) {
    final out = <String>[];
    final seen = <String>{};
    for (final item in [...?existing, ...?newItems]) {
      final text = item.trim();
      if (text.isEmpty) continue;
      final key = normalizeFact(text);
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(text);
    }
    return out;
  }

  /// La forme comparable d'un fait retenu.
  static String normalizeFact(String value) {
    const accents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ';
    const plain = 'aaaaaaceeeeiiiinooooouuuuyyoa';
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final index = accents.indexOf(char);
      final mapped = index >= 0 ? plain[index] : char;
      if (RegExp(r'[a-z0-9]').hasMatch(mapped)) {
        buffer.write(mapped);
      } else if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
        buffer.write(' ');
      }
    }
    return buffer.toString().trim();
  }

  /// Get user preferences from database
  Future<UserCoachPreferences?> getUserPreferences() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('user_coach_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return UserCoachPreferences.fromJson(response);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting preferences: $e');
      return null;
    }
  }
}
