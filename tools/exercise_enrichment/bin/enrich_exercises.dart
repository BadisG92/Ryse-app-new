import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:exercise_enrichment/gemini_service.dart';
import 'package:exercise_enrichment/youtube_service.dart';

/// Script CLI pour enrichir les exercices avec Gemini et YouTube
///
/// Usage:
///   dart run bin/enrich_exercises.dart --test          # Test sur 10 exercices
///   dart run bin/enrich_exercises.dart --generate-sql  # Génère le SQL complet
///   dart run bin/enrich_exercises.dart --youtube-only  # Recherche vidéos seulement
void main(List<String> args) async {
  print('═══════════════════════════════════════════════════════════');
  print('   EXERCISE ENRICHMENT TOOL - Ryse App');
  print('═══════════════════════════════════════════════════════════\n');

  // Charger les variables d'environnement
  final env = DotEnv()..load(['.env']);

  final geminiApiKey = env['GEMINI_API_KEY'];
  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseKey = env['SUPABASE_ANON_KEY'];
  final youtubeApiKey = env['YOUTUBE_API_KEY'];

  if (geminiApiKey == null || geminiApiKey.isEmpty) {
    print('❌ GEMINI_API_KEY not found in .env file');
    exit(1);
  }

  if (supabaseUrl == null || supabaseKey == null) {
    print('❌ SUPABASE_URL or SUPABASE_ANON_KEY not found in .env file');
    exit(1);
  }

  final geminiService = GeminiService(apiKey: geminiApiKey);
  final youtubeService = youtubeApiKey != null && youtubeApiKey.isNotEmpty
      ? YouTubeService(apiKey: youtubeApiKey)
      : null;

  // Parser les arguments
  final isTest = args.contains('--test');
  final isYoutubeOnly = args.contains('--youtube-only');
  final limit = isTest ? 10 : null;

  print('📊 Fetching exercises from Supabase...\n');

  // Récupérer les exercices depuis Supabase
  final exercises = await fetchExercises(supabaseUrl, supabaseKey, limit: limit);
  print('✅ Found ${exercises.length} exercises\n');

  if (exercises.isEmpty) {
    print('No exercises found.');
    exit(0);
  }

  // Stocker les résultats
  final results = <EnrichedExercise>[];
  var successCount = 0;
  var errorCount = 0;

  for (var i = 0; i < exercises.length; i++) {
    final exercise = exercises[i];
    final nameEn = exercise['name_en'] ?? '';
    final nameFr = exercise['name_fr'] ?? '';
    final muscleGroup = exercise['muscle_group'] ?? '';
    final equipment = exercise['equipment'] ?? '';
    final difficulty = exercise['difficulty_level'] ?? 'beginner';
    final id = exercise['id'];

    print('[${ i + 1}/${exercises.length}] Processing: $nameEn');

    String? descriptionEn;
    String? descriptionFr;
    String? instructionsEn;
    String? instructionsFr;
    String? videoUrl;

    if (!isYoutubeOnly) {
      // Générer contenu EN
      print('   → Generating EN content...');
      final contentEn = await geminiService.generateExerciseContent(
        exerciseName: nameEn,
        muscleGroup: muscleGroup,
        equipment: equipment,
        difficulty: difficulty,
        language: 'en',
      );

      if (contentEn != null) {
        descriptionEn = contentEn.description;
        instructionsEn = contentEn.instructions;
      }

      // Petit délai pour éviter rate limit
      await Future.delayed(Duration(milliseconds: 300));

      // Générer contenu FR
      print('   → Generating FR content...');
      final contentFr = await geminiService.generateExerciseContent(
        exerciseName: nameFr.isNotEmpty ? nameFr : nameEn,
        muscleGroup: muscleGroup,
        equipment: equipment,
        difficulty: difficulty,
        language: 'fr',
      );

      if (contentFr != null) {
        descriptionFr = contentFr.description;
        instructionsFr = contentFr.instructions;
      }

      await Future.delayed(Duration(milliseconds: 300));
    }

    // Rechercher vidéo YouTube (si API key fournie)
    if (youtubeService != null) {
      print('   → Searching YouTube video...');
      videoUrl = await youtubeService.findExerciseVideo(nameEn);
      await Future.delayed(Duration(milliseconds: 200));
    }

    if (descriptionEn != null || videoUrl != null) {
      results.add(EnrichedExercise(
        id: id,
        nameEn: nameEn,
        descriptionEn: descriptionEn,
        descriptionFr: descriptionFr,
        instructionsEn: instructionsEn,
        instructionsFr: instructionsFr,
        videoUrl: videoUrl,
      ));
      successCount++;
      print('   ✅ Success\n');
    } else {
      errorCount++;
      print('   ❌ Failed\n');
    }

    // Pause entre les batches
    if ((i + 1) % 10 == 0) {
      print('--- Batch complete. Waiting 3 seconds... ---\n');
      await Future.delayed(Duration(seconds: 3));
    }
  }

  // Générer le fichier SQL
  print('\n═══════════════════════════════════════════════════════════');
  print('   RESULTS');
  print('═══════════════════════════════════════════════════════════');
  print('✅ Success: $successCount');
  print('❌ Errors: $errorCount');
  print('');

  if (results.isNotEmpty) {
    final sqlFile = generateSqlFile(results);
    print('📄 SQL file generated: $sqlFile');
    print('\n⚠️  Review the SQL file before executing!');
    print('   You can run it via Supabase SQL Editor or psql.');
  }
}

/// Récupère les exercices depuis Supabase
Future<List<Map<String, dynamic>>> fetchExercises(
  String supabaseUrl,
  String supabaseKey, {
  int? limit,
}) async {
  var url = '$supabaseUrl/rest/v1/exercises?select=id,name_en,name_fr,muscle_group,equipment,difficulty_level&order=name_en';
  if (limit != null) {
    url += '&limit=$limit';
  }

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'apikey': supabaseKey,
      'Authorization': 'Bearer $supabaseKey',
    },
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    print('Error fetching exercises: ${response.statusCode}');
    return [];
  }
}

/// Génère le fichier SQL pour mettre à jour les exercices
String generateSqlFile(List<EnrichedExercise> exercises) {
  final buffer = StringBuffer();
  final timestamp = DateTime.now().toIso8601String().split('T')[0];
  final filename = 'exercise_enrichment_$timestamp.sql';

  buffer.writeln('-- ═══════════════════════════════════════════════════════════');
  buffer.writeln('-- EXERCISE ENRICHMENT - Generated ${DateTime.now()}');
  buffer.writeln('-- Total exercises: ${exercises.length}');
  buffer.writeln('-- ═══════════════════════════════════════════════════════════');
  buffer.writeln('');
  buffer.writeln('-- IMPORTANT: A backup table "exercises_backup_20260103" already exists');
  buffer.writeln('-- To rollback: See the ROLLBACK section at the end of this file');
  buffer.writeln('');
  buffer.writeln('BEGIN;');
  buffer.writeln('');

  for (final ex in exercises) {
    buffer.writeln('-- Exercise: ${ex.nameEn}');
    buffer.writeln('UPDATE exercises SET');

    final updates = <String>[];

    if (ex.descriptionEn != null) {
      updates.add("  description = '${escapeSql(ex.descriptionEn!)}'");
    }
    if (ex.instructionsEn != null) {
      updates.add("  instructions_en = '${escapeSql(ex.instructionsEn!)}'");
    }
    if (ex.instructionsFr != null) {
      updates.add("  instructions_fr = '${escapeSql(ex.instructionsFr!)}'");
    }
    if (ex.videoUrl != null) {
      updates.add("  video_url = '${ex.videoUrl}'");
    }
    updates.add("  updated_at = NOW()");

    buffer.writeln(updates.join(',\n'));
    buffer.writeln("WHERE id = '${ex.id}';");
    buffer.writeln('');
  }

  buffer.writeln('COMMIT;');
  buffer.writeln('');
  buffer.writeln('-- ═══════════════════════════════════════════════════════════');
  buffer.writeln('-- ROLLBACK (if needed)');
  buffer.writeln('-- ═══════════════════════════════════════════════════════════');
  buffer.writeln('-- UPDATE exercises e SET');
  buffer.writeln('--   description = b.description,');
  buffer.writeln('--   instructions_en = b.instructions_en,');
  buffer.writeln('--   instructions_fr = b.instructions_fr,');
  buffer.writeln('--   video_url = b.video_url');
  buffer.writeln('-- FROM exercises_backup_20260103 b');
  buffer.writeln('-- WHERE e.id = b.id;');

  File(filename).writeAsStringSync(buffer.toString());
  return filename;
}

/// Échappe les caractères SQL
String escapeSql(String text) {
  return text.replaceAll("'", "''").replaceAll('\n', ' ').replaceAll('\r', '');
}

/// Exercice enrichi avec le contenu généré
class EnrichedExercise {
  final String id;
  final String nameEn;
  final String? descriptionEn;
  final String? descriptionFr;
  final String? instructionsEn;
  final String? instructionsFr;
  final String? videoUrl;

  EnrichedExercise({
    required this.id,
    required this.nameEn,
    this.descriptionEn,
    this.descriptionFr,
    this.instructionsEn,
    this.instructionsFr,
    this.videoUrl,
  });
}
