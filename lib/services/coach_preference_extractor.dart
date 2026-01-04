import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/gemini_config.dart';
import '../models/coach_chat_models.dart';

/// Service to extract user preferences from coach conversations
/// Uses AI to identify allergies, restrictions, constraints mentioned in chat
class CoachPreferenceExtractor {
  static final CoachPreferenceExtractor _instance = CoachPreferenceExtractor._internal();
  static CoachPreferenceExtractor get instance => _instance;

  CoachPreferenceExtractor._internal();

  GenerativeModel? _model;
  final _supabase = Supabase.instance.client;

  /// Initialize the extractor
  void initialize() {
    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3, // Low temperature for accurate extraction
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1000,
      ),
    );
  }

  /// Extract preferences from a list of messages
  Future<UserCoachPreferences?> extractFromMessages(
    List<CoachMessage> messages,
    UserCoachPreferences? existingPreferences,
  ) async {
    if (_model == null) {
      initialize();
    }

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

      // Call Gemini
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        if (kDebugMode) debugPrint('❌ Empty response from Gemini');
        return existingPreferences;
      }

      // Parse the JSON response
      final extractedPrefs = _parseExtractionResponse(response.text!);

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
  Map<String, List<String>>? _parseExtractionResponse(String response) {
    try {
      // Clean up the response
      var cleaned = response.trim();

      // Remove markdown code blocks if present
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

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
    // Helper to merge lists without duplicates
    List<String> mergeList(List<String>? existing, List<String>? newItems) {
      final set = <String>{...(existing ?? []), ...(newItems ?? [])};
      return set.toList();
    }

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
      lastExtractionAt: DateTime.now(),
      extractionCount: (existing?.extractionCount ?? 0) + 1,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Extract and save preferences from a conversation
  Future<void> extractAndSave(String conversationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get conversation messages
      final messagesResponse = await _supabase
          .from('coach_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = (messagesResponse as List)
          .map((json) => CoachMessage.fromJson(json))
          .toList();

      if (messages.length < 4) {
        // Not enough messages to extract meaningful preferences
        return;
      }

      // Get existing preferences
      UserCoachPreferences? existing;
      final existingResponse = await _supabase
          .from('user_coach_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingResponse != null) {
        existing = UserCoachPreferences.fromJson(existingResponse);
      }

      // Extract new preferences
      final newPrefs = await extractFromMessages(messages, existing);

      if (newPrefs == null || newPrefs.isEmpty) {
        return;
      }

      // Save to database
      await _supabase.from('user_coach_preferences').upsert({
        'user_id': user.id,
        'preferences': {
          'allergies': newPrefs.allergies,
          'dietary_restrictions': newPrefs.dietaryRestrictions,
          'food_preferences': newPrefs.foodPreferences,
          'fitness_constraints': newPrefs.fitnessConstraints,
          'preferred_workout_times': newPrefs.preferredWorkoutTimes,
          'custom_notes': newPrefs.customNotes,
        },
        'last_extraction_at': DateTime.now().toIso8601String(),
        'extraction_count': newPrefs.extractionCount,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('✅ Preferences saved to database');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error in extractAndSave: $e');
    }
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
