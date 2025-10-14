import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/gemini_config.dart';

/// Service pour l'analyse IA des performances d'exercice avec Gemini 2.0 Flash
class ExerciseAiAnalysisService {
  // PAS de limite de temps pour le cache - l'analyse reste tant qu'il n'y a pas de nouvelle séance
  static const int _minimumSessions = 3;
  static const int _maxSessionsForAnalysis = 10;

  static late GenerativeModel _model;

  /// Initialise le modèle Gemini
  static void initialize() {
    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8, // Plus créatif pour des analyses variées
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1000,
      ),
    );
  }

  /// Vérifie si une analyse est disponible en cache
  static Future<CachedAnalysis?> getCachedAnalysis({
    required String userId,
    required String exerciseName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCacheKey(userId, exerciseName);
    final cached = prefs.getString(key);

    if (cached == null) return null;

    try {
      final data = json.decode(cached);
      final analysis = CachedAnalysis.fromJson(data);

      // PAS de vérification d'expiration - le cache reste indéfiniment
      // Il ne sera supprimé que si une nouvelle séance est ajoutée et qu'on régénère

      return analysis;
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si de nouvelles séances ont été ajoutées depuis la dernière analyse
  static Future<bool> hasNewSessions({
    required String userId,
    required String exerciseName,
    required int currentSessionCount,
  }) async {
    final cached = await getCachedAnalysis(
      userId: userId,
      exerciseName: exerciseName,
    );

    if (cached == null) return false;

    return currentSessionCount > cached.sessionCount;
  }

  /// Génère une nouvelle analyse IA
  static Future<String> generateAnalysis({
    required String exerciseName,
    required List<Map<String, dynamic>> sessionHistory,
    required String languageCode,
  }) async {
    // Vérifier le minimum de séances
    if (sessionHistory.length < _minimumSessions) {
      throw Exception(
        languageCode == 'fr'
            ? 'Au moins $_minimumSessions séances sont nécessaires pour une analyse'
            : 'At least $_minimumSessions sessions are required for analysis'
      );
    }

    // Limiter aux 10 dernières séances
    final sessions = sessionHistory.take(_maxSessionsForAnalysis).toList();

    // Construire le prompt
    final prompt = _buildPrompt(
      exerciseName: exerciseName,
      sessions: sessions,
      languageCode: languageCode,
    );

    // LOG: Afficher le prompt envoyé
    print('🤖 ========== GEMINI PROMPT ==========');
    print('📝 Exercice: $exerciseName');
    print('🌍 Langue: $languageCode');
    print('📊 Nombre de séances: ${sessions.length}');
    print('');
    print('📄 PROMPT COMPLET:');
    print('─' * 50);
    print(prompt);
    print('─' * 50);
    print('');

    // Appeler Gemini
    final content = [Content.text(prompt)];

    print('⏳ Envoi de la requête à Gemini...');
    final response = await _model.generateContent(content);

    // LOG: Afficher la réponse
    print('');
    print('✅ ========== GEMINI RESPONSE ==========');
    if (response.text != null && response.text!.isNotEmpty) {
      print('📝 Réponse reçue (${response.text!.length} caractères):');
      print('─' * 50);
      print(response.text);
      print('─' * 50);
    } else {
      print('❌ Aucune réponse reçue de Gemini');
    }
    print('');

    if (response.text == null || response.text!.isEmpty) {
      throw Exception(
        languageCode == 'fr'
            ? 'Impossible de générer l\'analyse'
            : 'Failed to generate analysis'
      );
    }

    return response.text!;
  }

  /// Sauvegarde l'analyse en cache
  static Future<void> cacheAnalysis({
    required String userId,
    required String exerciseName,
    required String analysisText,
    required int sessionCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCacheKey(userId, exerciseName);

    final analysis = CachedAnalysis(
      text: analysisText,
      timestamp: DateTime.now(),
      sessionCount: sessionCount,
    );

    await prefs.setString(key, json.encode(analysis.toJson()));
  }

  /// Supprime le cache pour un exercice (utilisé seulement en cas de régénération)
  static Future<void> clearCache(String userId, String exerciseName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCacheKey(userId, exerciseName);
    await prefs.remove(key);
  }

  /// Construit le prompt pour Gemini
  static String _buildPrompt({
    required String exerciseName,
    required List<Map<String, dynamic>> sessions,
    required String languageCode,
  }) {
    if (languageCode == 'fr') {
      return _buildFrenchPrompt(exerciseName, sessions);
    } else {
      return _buildEnglishPrompt(exerciseName, sessions);
    }
  }

  static String _buildFrenchPrompt(
    String exerciseName,
    List<Map<String, dynamic>> sessions,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Tu es Coach Ryze, un coach sportif expert en musculation et progression.');
    buffer.writeln('');
    buffer.writeln('MISSION : Analyse concise et actionnable des performances sur "$exerciseName".');
    buffer.writeln('');
    buffer.writeln('⚠️ CONTRAINTES ABSOLUES :');
    buffer.writeln('- LONGUEUR TOTALE : 100 mots MAXIMUM (pas un de plus)');
    buffer.writeln('- ANALYSE : 40-50 mots (2-3 phrases courtes)');
    buffer.writeln('- RECOMMANDATIONS : 2 conseils × 25 mots maximum chacun');
    buffer.writeln('- Si tu dépasses 100 mots, SUPPRIME les détails secondaires');
    buffer.writeln('');
    buffer.writeln('DONNÉES D\'ENTRAÎNEMENT (${sessions.length} dernières séances, chronologique) :');
    buffer.writeln('');

    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final date = session['date'] ?? '';
      final allSets = session['allSets'] as List<String>? ?? [];

      buffer.writeln('Séance ${i + 1} - $date :');
      if (allSets.isNotEmpty) {
        for (int j = 0; j < allSets.length; j++) {
          buffer.writeln('  Série ${j + 1}: ${allSets[j]}');
        }
      } else {
        buffer.writeln('  Performance: ${session['weight']} x ${session['reps']} répétitions');
      }
      buffer.writeln('');
    }

    buffer.writeln('STRUCTURE OBLIGATOIRE :');
    buffer.writeln('');
    buffer.writeln('1. ANALYSE (40-50 mots max)');
    buffer.writeln('   - NE PAS écrire "Analyse de ta progression sur [exercice]"');
    buffer.writeln('   - Commence DIRECTEMENT par le constat : "Tu progresses..." ou "Tes performances..."');
    buffer.writeln('   - Pas de préambule, pas d\'introduction');
    buffer.writeln('   - Constat principal en 1 phrase (progression/plateau/régression)');
    buffer.writeln('   - Observation clé en 1-2 phrases (variations, patterns)');
    buffer.writeln('   - Évite les dates précises (dis "récemment", "au début")');
    buffer.writeln('   - Évite de détailler chaque séance');
    buffer.writeln('');
    buffer.writeln('2. RECOMMANDATIONS (2 conseils × 25 mots max)');
    buffer.writeln('   - Titre court (3-4 mots) : Action concrète avec chiffres');
    buffer.writeln('   - Chaque conseil doit être actionnable immédiatement');
    buffer.writeln('   ');
    buffer.writeln('   Exemples selon situation :');
    buffer.writeln('   - Si progression → "Augmente de [X]kg à la prochaine séance"');
    buffer.writeln('   - Si plateau → "Change le format : passe à [X] séries de [Y] reps"');
    buffer.writeln('   - Si fatigue → "Réduis à [X]kg pendant 1 semaine puis reprends"');
    buffer.writeln('   - Si débutant → "Maintiens [X]kg pendant 2 séances puis augmente"');
    buffer.writeln('');
    buffer.writeln('STYLE :');
    buffer.writeln('- Ton direct et pro, tutoiement');
    buffer.writeln('- Phrases courtes et simples');
    buffer.writeln('- Chiffres précis (poids, reps, pourcentages)');
    buffer.writeln('- Motivant mais réaliste');
    buffer.writeln('- AUCUN emoji, AUCUN symbole (📊 💡 •)');
    buffer.writeln('- Pas de mots de remplissage ("en effet", "notamment", "par exemple")');
    buffer.writeln('');
    buffer.writeln('FORMAT :');
    buffer.writeln('- Paragraphes de 2 lignes max');
    buffer.writeln('- Saut de ligne entre chaque paragraphe');
    buffer.writeln('- Le mot "Recommandations" en gras avec **');
    buffer.writeln('- Saut de ligne entre chaque recommandation');
    buffer.writeln('');
    buffer.writeln('EXEMPLE DE FEEDBACK IDÉAL (85 mots) :');
    buffer.writeln('');
    buffer.writeln('Tes performances montrent de l\'irrégularité avec des variations importantes de charge.');
    buffer.writeln('');
    buffer.writeln('Tu es passé de charges élevées à plus légères, ce qui peut indiquer une gestion de fatigue ou un manque de structure dans ta planification.');
    buffer.writeln('');
    buffer.writeln('**Recommandations**');
    buffer.writeln('');
    buffer.writeln('Planifie ta progression : Augmente de 2.5kg toutes les 2 séances en gardant 3 séries de 15-20 reps.');
    buffer.writeln('');
    buffer.writeln('Technique avant charge : Maîtrise parfaitement le mouvement avec charge modérée avant d\'augmenter. Focus sur la contraction complète.');
    buffer.writeln('');
    buffer.writeln('VÉRIFICATION FINALE :');
    buffer.writeln('Compte tes mots avant de répondre. Si >100 mots, supprime :');
    buffer.writeln('1. Les détails de séances individuelles');
    buffer.writeln('2. Les explications longues dans les recommandations');
    buffer.writeln('3. Les phrases d\'introduction inutiles');
    buffer.writeln('');
    buffer.writeln('Réponds maintenant avec maximum 100 mots.');

    return buffer.toString();
  }

  static String _buildEnglishPrompt(
    String exerciseName,
    List<Map<String, dynamic>> sessions,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('You are Coach Ryze, an expert fitness coach in strength training and progression.');
    buffer.writeln('');
    buffer.writeln('MISSION: Concise and actionable performance analysis on "$exerciseName".');
    buffer.writeln('');
    buffer.writeln('⚠️ ABSOLUTE CONSTRAINTS:');
    buffer.writeln('- TOTAL LENGTH: 100 words MAXIMUM (not one more)');
    buffer.writeln('- ANALYSIS: 40-50 words (2-3 short sentences)');
    buffer.writeln('- RECOMMENDATIONS: 2 tips × 25 words maximum each');
    buffer.writeln('- If you exceed 100 words, DELETE secondary details');
    buffer.writeln('');
    buffer.writeln('TRAINING DATA (last ${sessions.length} sessions, chronological):');
    buffer.writeln('');

    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final date = session['date'] ?? '';
      final allSets = session['allSets'] as List<String>? ?? [];

      buffer.writeln('Session ${i + 1} - $date:');
      if (allSets.isNotEmpty) {
        for (int j = 0; j < allSets.length; j++) {
          buffer.writeln('  Set ${j + 1}: ${allSets[j]}');
        }
      } else {
        buffer.writeln('  Performance: ${session['weight']} x ${session['reps']} reps');
      }
      buffer.writeln('');
    }

    buffer.writeln('MANDATORY STRUCTURE:');
    buffer.writeln('');
    buffer.writeln('1. ANALYSIS (40-50 words max)');
    buffer.writeln('   - DO NOT write "Analysis of your progression on [exercise]"');
    buffer.writeln('   - Start DIRECTLY with the observation: "You\'re progressing..." or "Your performance..."');
    buffer.writeln('   - No preamble, no introduction');
    buffer.writeln('   - Main observation in 1 sentence (progression/plateau/regression)');
    buffer.writeln('   - Key observation in 1-2 sentences (variations, patterns)');
    buffer.writeln('   - Avoid precise dates (say "recently", "initially")');
    buffer.writeln('   - Avoid detailing each session');
    buffer.writeln('');
    buffer.writeln('2. RECOMMENDATIONS (2 tips × 25 words max)');
    buffer.writeln('   - Short title (3-4 words): Concrete action with numbers');
    buffer.writeln('   - Each tip must be immediately actionable');
    buffer.writeln('   ');
    buffer.writeln('   Examples by situation:');
    buffer.writeln('   - If progression → "Increase by [X]lbs next session"');
    buffer.writeln('   - If plateau → "Change format: switch to [X] sets of [Y] reps"');
    buffer.writeln('   - If fatigue → "Reduce to [X]lbs for 1 week then resume"');
    buffer.writeln('   - If beginner → "Maintain [X]lbs for 2 sessions then increase"');
    buffer.writeln('');
    buffer.writeln('STYLE:');
    buffer.writeln('- Direct and pro tone');
    buffer.writeln('- Short and simple sentences');
    buffer.writeln('- Precise numbers (weight, reps, percentages)');
    buffer.writeln('- Motivating but realistic');
    buffer.writeln('- NO emojis, NO symbols (📊 💡 •)');
    buffer.writeln('- No filler words ("indeed", "notably", "for example")');
    buffer.writeln('');
    buffer.writeln('FORMAT:');
    buffer.writeln('- Paragraphs of 2 lines max');
    buffer.writeln('- Line break between each paragraph');
    buffer.writeln('- The word "Recommendations" in bold with **');
    buffer.writeln('- Line break between each recommendation');
    buffer.writeln('');
    buffer.writeln('IDEAL FEEDBACK EXAMPLE (85 words):');
    buffer.writeln('');
    buffer.writeln('Your performance shows irregularity with significant load variations.');
    buffer.writeln('');
    buffer.writeln('You went from high loads to lighter ones, which may indicate fatigue management or lack of structure in your planning.');
    buffer.writeln('');
    buffer.writeln('**Recommendations**');
    buffer.writeln('');
    buffer.writeln('Plan your progression: Increase by 5lbs every 2 sessions while keeping 3 sets of 15-20 reps.');
    buffer.writeln('');
    buffer.writeln('Technique before load: Master the movement perfectly with moderate load before increasing. Focus on full contraction.');
    buffer.writeln('');
    buffer.writeln('FINAL CHECK:');
    buffer.writeln('Count your words before answering. If >100 words, delete:');
    buffer.writeln('1. Individual session details');
    buffer.writeln('2. Long explanations in recommendations');
    buffer.writeln('3. Unnecessary introduction sentences');
    buffer.writeln('');
    buffer.writeln('Answer now with maximum 100 words.');

    return buffer.toString();
  }

  static String _getCacheKey(String userId, String exerciseName) {
    return 'ai_analysis_${userId}_${exerciseName.replaceAll(' ', '_')}';
  }
}

/// Modèle pour l'analyse en cache
class CachedAnalysis {
  final String text;
  final DateTime timestamp;
  final int sessionCount;

  CachedAnalysis({
    required this.text,
    required this.timestamp,
    required this.sessionCount,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'sessionCount': sessionCount,
  };

  factory CachedAnalysis.fromJson(Map<String, dynamic> json) => CachedAnalysis(
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    sessionCount: json['sessionCount'] as int,
  );
}
