import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service pour générer des descriptions et instructions d'exercices avec Gemini
class GeminiService {
  final String apiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  GeminiService({required this.apiKey});

  /// Génère description + instructions pour un exercice dans une langue donnée
  Future<ExerciseContent?> generateExerciseContent({
    required String exerciseName,
    required String muscleGroup,
    required String equipment,
    required String difficulty,
    required String language, // 'fr' ou 'en'
  }) async {
    final langName = language == 'fr' ? 'French' : 'English';
    final equipmentText = equipment.isEmpty ? 'Bodyweight' : equipment;

    final prompt = '''
You are a professional fitness coach. Generate content for the exercise "$exerciseName" in $langName.

Exercise details:
- Name: $exerciseName
- Muscle group: $muscleGroup
- Equipment: $equipmentText
- Difficulty: $difficulty

Generate:
1. A SHORT description (1-2 sentences max, ~30-50 words) explaining what this exercise is and its main benefit for that muscle group.
2. Step-by-step instructions (4-6 numbered steps) for proper execution with focus on posture and movement.

IMPORTANT: Return ONLY valid JSON, no markdown, no explanation:
{
  "description": "Short description here in $langName...",
  "instructions": "1. First step | 2. Second step | 3. Third step | 4. Fourth step"
}

Use pipe separator (|) between instruction steps. Keep each step concise (10-20 words max).
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 40,
            'topP': 0.8,
            'maxOutputTokens': 1000,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text != null) {
          return _parseResponse(text);
        }
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling Gemini: $e');
    }

    return null;
  }

  /// Parse la réponse JSON de Gemini
  ExerciseContent? _parseResponse(String text) {
    try {
      // Nettoyer le texte (enlever markdown si présent)
      var cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      final json = jsonDecode(cleanText);
      return ExerciseContent(
        description: json['description'] ?? '',
        instructions: json['instructions'] ?? '',
      );
    } catch (e) {
      print('Error parsing Gemini response: $e');
      print('Raw text: $text');
      return null;
    }
  }
}

/// Contenu généré pour un exercice
class ExerciseContent {
  final String description;
  final String instructions;

  ExerciseContent({
    required this.description,
    required this.instructions,
  });

  @override
  String toString() =>
      'ExerciseContent(description: $description, instructions: $instructions)';
}
