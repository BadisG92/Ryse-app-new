import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service pour rechercher des vidéos YouTube d'exercices
class YouTubeService {
  final String apiKey;
  static const String _baseUrl =
      'https://www.googleapis.com/youtube/v3/search';

  YouTubeService({required this.apiKey});

  /// Recherche une vidéo tutoriel pour un exercice
  /// Retourne l'URL YouTube ou null si non trouvée
  Future<String?> findExerciseVideo(String exerciseName) async {
    // Construire une requête optimisée pour les tutoriels fitness
    final query = '$exerciseName exercise tutorial proper form';

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': '1',
        'videoDuration': 'short', // Vidéos courtes (< 4 min)
        'relevanceLanguage': 'en', // Préférer les vidéos en anglais (plus de contenu)
        'safeSearch': 'strict',
        'key': apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List?;

        if (items != null && items.isNotEmpty) {
          final videoId = items[0]['id']?['videoId'];
          if (videoId != null) {
            return 'https://www.youtube.com/watch?v=$videoId';
          }
        }
      } else if (response.statusCode == 403) {
        print('YouTube API quota exceeded or invalid key');
        return null;
      } else {
        print('YouTube API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling YouTube API: $e');
    }

    return null;
  }

  /// Vérifie si le quota API est encore disponible
  Future<bool> checkQuota() async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'part': 'snippet',
        'q': 'test',
        'type': 'video',
        'maxResults': '1',
        'key': apiKey,
      });

      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
