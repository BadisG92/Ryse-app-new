import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'localization_service.dart';

/// Service de reconnaissance vocale pour les workouts
/// Permet de dicter reps et poids mains-libres pendant l'entraînement
class WorkoutVoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  /// Initialiser le service (à faire une fois au démarrage de la séance)
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) => debugPrint('🎤 Speech status: $status'),
        onError: (error) => debugPrint('❌ Speech error: $error'),
      );

      if (_isInitialized) {
        // Configurer TTS selon la langue
        final lang = LocalizationService.instance.currentLanguageCode;
        await _tts.setLanguage(lang == 'fr' ? 'fr-FR' : 'en-US');
        await _tts.setSpeechRate(0.5); // Vitesse lecture
        await _tts.setVolume(0.8);

        debugPrint('✅ WorkoutVoiceService initialized');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Failed to initialize voice service: $e');
      return false;
    }
  }

  /// Démarrer l'écoute (bouton micro pressé)
  Future<void> startListening({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        debugPrint('❌ Cannot start listening: not initialized');
        return;
      }
    }

    if (_isListening) {
      debugPrint('⚠️ Already listening');
      return;
    }

    _isListening = true;

    // Déterminer la langue selon les paramètres
    final lang = LocalizationService.instance.currentLanguageCode;
    final localeId = lang == 'fr' ? 'fr_FR' : 'en_US';

    try {
      // Tenter avec onDevice = true (meilleur filtre bruit)
      await _speech.listen(
        onResult: (result) {
          // Résultats partiels pendant que l'user parle
          if (!result.finalResult) {
            onPartialResult(result.recognizedWords);
          } else {
            // Résultat final quand l'user arrête de parler
            onFinalResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 5), // Timeout max
        pauseFor: const Duration(seconds: 2),  // Pause avant finalisation
        localeId: localeId,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        // 🔇 Filtre de bruit activé pour environnement bruyant (salle de sport)
        onDevice: true, // Traitement sur appareil = meilleure qualité dans le bruit
        partialResults: true, // Afficher résultats partiels même avec bruit
      );
    } catch (e) {
      // Fallback: vieux devices qui ne supportent pas onDevice
      debugPrint('⚠️ onDevice not supported, fallback to cloud');
      await _speech.listen(
        onResult: (result) {
          if (!result.finalResult) {
            onPartialResult(result.recognizedWords);
          } else {
            onFinalResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        localeId: localeId,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        onDevice: false, // Fallback sans onDevice
        partialResults: true,
      );
    }
  }

  /// Arrêter l'écoute (bouton micro relâché)
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
    debugPrint('🛑 Stopped listening');
  }

  /// Feedback vocal (confirmation ou erreur)
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('❌ TTS error: $e');
    }
  }

  /// Parser l'input vocal pour extraire reps et poids
  /// Formats supportés:
  /// - "10 reps 80 kilos"
  /// - "80 kilos 10 reps" (ordre inversé)
  /// - "dix répétitions quatre-vingts kilos" (à venir)
  WorkoutSetData? parseVoiceInput(String text) {
    final normalized = text.toLowerCase().trim();
    debugPrint('🔍 Parsing: "$normalized"');

    // Pattern 1: "10 reps 80 kilos" (ou kg/kilo)
    final pattern1 = RegExp(
      r'(\d+)\s*(?:rep|reps|répétitions?|répétition)\s*(\d+\.?\d*)\s*(?:kg|kilo|kilos)',
      caseSensitive: false,
    );

    final match1 = pattern1.firstMatch(normalized);
    if (match1 != null) {
      try {
        final reps = int.parse(match1.group(1)!);
        final weight = double.parse(match1.group(2)!);
        debugPrint('✅ Parsed (pattern 1): $reps reps, $weight kg');
        return WorkoutSetData(reps: reps, weight: weight);
      } catch (e) {
        debugPrint('⚠️ Parse error pattern 1: $e');
      }
    }

    // Pattern 2: "80 kilos 10 reps" (ordre inversé)
    final pattern2 = RegExp(
      r'(\d+\.?\d*)\s*(?:kg|kilo|kilos)\s*(\d+)\s*(?:rep|reps|répétitions?|répétition)',
      caseSensitive: false,
    );

    final match2 = pattern2.firstMatch(normalized);
    if (match2 != null) {
      try {
        final weight = double.parse(match2.group(1)!);
        final reps = int.parse(match2.group(2)!);
        debugPrint('✅ Parsed (pattern 2): $reps reps, $weight kg');
        return WorkoutSetData(reps: reps, weight: weight);
      } catch (e) {
        debugPrint('⚠️ Parse error pattern 2: $e');
      }
    }

    // Pattern 3: SUPPRIMÉ - On n'accepte JAMAIS juste le poids seul
    // L'utilisateur DOIT donner au moins les reps

    // Pattern 4: Juste les reps "10 reps" (poids garde valeur précédente ou 0)
    final pattern4 = RegExp(
      r'(\d+)\s*(?:rep|reps|répétitions?|répétition)',
      caseSensitive: false,
    );

    final match4 = pattern4.firstMatch(normalized);
    if (match4 != null && !normalized.contains(RegExp(r'kg|kilo', caseSensitive: false))) {
      try {
        final reps = int.parse(match4.group(1)!);
        debugPrint('✅ Parsed (pattern 4 - reps only): $reps reps');
        return WorkoutSetData(reps: reps, weight: null);
      } catch (e) {
        debugPrint('⚠️ Parse error pattern 4: $e');
      }
    }

    debugPrint('❌ No pattern matched');
    return null;
  }

  /// Générer message de confirmation selon la langue
  String getConfirmationMessage(WorkoutSetData data) {
    final lang = LocalizationService.instance.currentLanguageCode;

    if (lang == 'fr') {
      if (data.reps != null && data.weight != null) {
        return '${data.reps} répétitions, ${data.weight} kilos enregistrés';
      } else if (data.reps != null) {
        return '${data.reps} répétitions enregistrées';
      }
      // Plus de cas "weight only" car on ne l'accepte plus
    } else {
      if (data.reps != null && data.weight != null) {
        return '${data.reps} reps, ${data.weight} kilos logged';
      } else if (data.reps != null) {
        return '${data.reps} reps logged';
      }
      // Plus de cas "weight only" car on ne l'accepte plus
    }

    return 'Logged';
  }

  /// Message d'erreur si pas compris
  String getErrorMessage() {
    final lang = LocalizationService.instance.currentLanguageCode;

    if (lang == 'fr') {
      return 'Je n\'ai pas compris. Répétez en disant le nombre de répétitions puis le poids.';
    } else {
      return 'I didn\'t understand. Please repeat with reps then weight.';
    }
  }

  /// Libérer les ressources
  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}

/// Données d'une série extraites de la voix
class WorkoutSetData {
  final int? reps;
  final double? weight;

  WorkoutSetData({this.reps, this.weight});

  bool get hasReps => reps != null;
  bool get hasWeight => weight != null;
  bool get hasData => hasReps || hasWeight;
}
