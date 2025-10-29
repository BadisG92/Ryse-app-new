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

    // ⚡ FIX: Si déjà en écoute, forcer l'arrêt avant de recommencer
    if (_isListening) {
      debugPrint('⚠️ Already listening, forcing stop before restart');
      await _speech.stop();
      _isListening = false;
      // Petit délai pour laisser le micro se libérer
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isListening = true;

    // Déterminer la langue selon les paramètres
    final lang = LocalizationService.instance.currentLanguageCode;
    final localeId = lang == 'fr' ? 'fr_FR' : 'en_US';

    try {
      // 🎯 Configuration OPTIMALE pour meilleure reconnaissance (iOS-like quality)
      await _speech.listen(
        onResult: (result) {
          // Résultats partiels pendant que l'user parle
          if (!result.finalResult) {
            onPartialResult(result.recognizedWords);
          } else {
            // Résultat final quand l'user arrête de parler
            debugPrint('🎯 Final result detected: "${result.recognizedWords}"');
            onFinalResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 6), // Timeout total réduit à 6s
        pauseFor: const Duration(milliseconds: 800),  // ⚡ 0.8s de silence = validation (plus réactif)
        localeId: localeId,
        cancelOnError: true,
        listenMode: ListenMode.dictation, // 🔥 CHANGEMENT CLÉ : dictation au lieu de confirmation
        // 🔇 onDevice désactivé car API cloud Apple a MEILLEURE qualité pour dictée
        onDevice: false, // Cloud API = meilleure reconnaissance pour nombres et termes techniques
        partialResults: true,
        // 🎯 NOUVEAUX PARAMÈTRES pour qualité maximale
        sampleRate: 16000, // Qualité audio HD (recommandé par Apple)
      );
    } catch (e) {
      // Fallback en cas d'erreur (rare)
      debugPrint('⚠️ Erreur reconnaissance principale, fallback: $e');
      await _speech.listen(
        onResult: (result) {
          if (!result.finalResult) {
            onPartialResult(result.recognizedWords);
          } else {
            onFinalResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 1),
        localeId: localeId,
        cancelOnError: true,
        listenMode: ListenMode.dictation, // Même mode que principal
        onDevice: false,
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

  /// Convertir nombres en lettres vers chiffres (français et anglais)
  String _convertWordsToNumbers(String text) {
    // Map français (nombres courants en musculation: 0-30, dizaines, 100)
    final Map<String, String> frenchNumbers = {
      'zéro': '0', 'zero': '0',
      'un': '1', 'une': '1',
      'deux': '2',
      'trois': '3',
      'quatre': '4',
      'cinq': '5',
      'six': '6',
      'sept': '7',
      'huit': '8',
      'neuf': '9',
      'dix': '10',
      'onze': '11',
      'douze': '12',
      'treize': '13',
      'quatorze': '14',
      'quinze': '15',
      'seize': '16',
      'dix-sept': '17', 'dixsept': '17',
      'dix-huit': '18', 'dixhuit': '18',
      'dix-neuf': '19', 'dixneuf': '19',
      'vingt': '20',
      'vingt-et-un': '21', 'vingt et un': '21', 'vingt-un': '21',
      'vingt-deux': '22', 'vingt deux': '22',
      'vingt-trois': '23', 'vingt trois': '23',
      'vingt-quatre': '24', 'vingt quatre': '24',
      'vingt-cinq': '25', 'vingt cinq': '25',
      'vingt-six': '26', 'vingt six': '26',
      'vingt-sept': '27', 'vingt sept': '27',
      'vingt-huit': '28', 'vingt huit': '28',
      'vingt-neuf': '29', 'vingt neuf': '29',
      'trente': '30',
      'trente-cinq': '35', 'trente cinq': '35',
      'quarante': '40',
      'quarante-cinq': '45', 'quarante cinq': '45',
      'cinquante': '50',
      'cinquante-cinq': '55', 'cinquante cinq': '55',
      'soixante': '60',
      'soixante-cinq': '65', 'soixante cinq': '65',
      'soixante-dix': '70', 'soixante dix': '70',
      'soixante-quinze': '75', 'soixante quinze': '75',
      'quatre-vingts': '80', 'quatre vingts': '80', 'quatre vingt': '80',
      'quatre-vingt-cinq': '85', 'quatre vingt cinq': '85',
      'quatre-vingt-dix': '90', 'quatre vingt dix': '90',
      'quatre-vingt-quinze': '95', 'quatre vingt quinze': '95',
      'cent': '100',
      'cent cinq': '105', 'cent-cinq': '105',
      'cent dix': '110', 'cent-dix': '110',
      'cent quinze': '115', 'cent-quinze': '115',
      'cent vingt': '120', 'cent-vingt': '120',
      'cent cinquante': '150', 'cent-cinquante': '150',
      'deux cents': '200', 'deux cent': '200',
    };

    // Map anglais
    final Map<String, String> englishNumbers = {
      'zero': '0',
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'nine': '9',
      'ten': '10',
      'eleven': '11',
      'twelve': '12',
      'thirteen': '13',
      'fourteen': '14',
      'fifteen': '15',
      'sixteen': '16',
      'seventeen': '17',
      'eighteen': '18',
      'nineteen': '19',
      'twenty': '20',
      'twenty-five': '25', 'twenty five': '25',
      'thirty': '30',
      'thirty-five': '35', 'thirty five': '35',
      'forty': '40',
      'forty-five': '45', 'forty five': '45',
      'fifty': '50',
      'fifty-five': '55', 'fifty five': '55',
      'sixty': '60',
      'sixty-five': '65', 'sixty five': '65',
      'seventy': '70',
      'seventy-five': '75', 'seventy five': '75',
      'eighty': '80',
      'eighty-five': '85', 'eighty five': '85',
      'ninety': '90',
      'ninety-five': '95', 'ninety five': '95',
      'hundred': '100',
      'one hundred': '100',
      'one hundred twenty': '120',
      'one hundred fifty': '150',
      'two hundred': '200',
    };

    String result = text;

    // Appliquer les remplacements français
    frenchNumbers.forEach((word, number) {
      result = result.replaceAll(RegExp(r'\b' + word + r'\b'), number);
    });

    // Appliquer les remplacements anglais
    englishNumbers.forEach((word, number) {
      result = result.replaceAll(RegExp(r'\b' + word + r'\b'), number);
    });

    return result;
  }

  /// Parser l'input vocal pour extraire reps et poids
  /// Formats supportés:
  /// - "10 reps 80 kilos"
  /// - "80 kilos 10 reps" (ordre inversé)
  /// - "10 répétitions de 80 kilos" (avec "de")
  /// - "cinq reps quinze kilos" (nombres en lettres)
  /// - Variantes: rep, reps, répétition, répétitions, wraps, repetition, kg, kilo, kilos, kilogrammes
  WorkoutSetData? parseVoiceInput(String text) {
    final normalized = text.toLowerCase().trim();
    debugPrint('🔍 Parsing: "$normalized"');

    // ⚡ ÉTAPE 1: Convertir nombres en lettres → chiffres
    final withNumbers = _convertWordsToNumbers(normalized);
    if (withNumbers != normalized) {
      debugPrint('🔢 Converted numbers: "$withNumbers"');
    }

    // ÉTAPE 2: Nettoyer le texte des mots parasites communs (plus agressif)
    var cleaned = withNumbers
        // Remplacer virgules par points pour nombres décimaux
        .replaceAll(',', '.')
        // Retirer "non" au début (bug reconnaissance vocale)
        .replaceAll(RegExp(r'^\s*non\s+'), '')
        // Retirer mots parasites français et anglais
        .replaceAll(RegExp(r'\b(et|de|d|à|au|avec|pour|the|and|of|at|with|for|a|an)\b'), ' ')
        // Gérer "x" comme multiplicateur (ex: "10 x 80" ou "10x80")
        .replaceAll(RegExp(r'(\d+)\s*x\s*(\d+)'), r'\1 fois \2')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    debugPrint('🧹 Cleaned: "$cleaned"');

    // Pattern 1: "10 reps 80 kilos" (avec séparateurs optionnels)
    // Français: répétitions, reps, fois, séries, kg, kilo, kilos, kilogrammes
    // Anglais: reps, repetitions, times, sets, pounds, lbs, lb
    final pattern1 = RegExp(
      r'(\d+)\s*(?:rep|reps|répétitions?|répétition|wraps?|repetitions?|times?|sets?|séries?|série|fois|x)s?\s*(\d+\.?\d*)\s*(?:kg|kilo|kilos|kilogrammes?|pounds?|lbs?|lb)',
      caseSensitive: false,
    );

    final match1 = pattern1.firstMatch(cleaned);
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
      r'(\d+\.?\d*)\s*(?:kg|kilo|kilos|kilogrammes?|pounds?|lbs?|lb)\s*(\d+)\s*(?:rep|reps|répétitions?|répétition|wraps?|repetitions?|times?|sets?|séries?|série|fois|x)s?',
      caseSensitive: false,
    );

    final match2 = pattern2.firstMatch(cleaned);
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

    // Pattern 3: Juste les reps "10 reps" (poids garde valeur précédente ou 0)
    final pattern3 = RegExp(
      r'(\d+)\s*(?:rep|reps|répétitions?|répétition|wraps?|repetitions?|times?|sets?|séries?|série|fois|x)s?',
      caseSensitive: false,
    );

    final match3 = pattern3.firstMatch(cleaned);
    if (match3 != null && !cleaned.contains(RegExp(r'kg|kilo', caseSensitive: false))) {
      try {
        final reps = int.parse(match3.group(1)!);
        debugPrint('✅ Parsed (pattern 3 - reps only): $reps reps');
        return WorkoutSetData(reps: reps, weight: null);
      } catch (e) {
        debugPrint('⚠️ Parse error pattern 3: $e');
      }
    }

    // Pattern 4: Format simple nombres "10 80" (reps poids)
    // Accepte si 2 nombres séparés, le premier < 50 (probablement reps)
    final pattern4 = RegExp(r'(\d+)\s+(\d+\.?\d*)');
    final match4 = pattern4.firstMatch(cleaned);
    if (match4 != null) {
      try {
        final first = int.parse(match4.group(1)!);
        final second = double.parse(match4.group(2)!);

        // Si premier nombre < 50, c'est probablement reps, sinon poids
        if (first < 50) {
          debugPrint('✅ Parsed (pattern 4 - numbers): $first reps, $second kg');
          return WorkoutSetData(reps: first, weight: second);
        } else {
          debugPrint('✅ Parsed (pattern 4 reversed): ${second.toInt()} reps, $first kg');
          return WorkoutSetData(reps: second.toInt(), weight: first.toDouble());
        }
      } catch (e) {
        debugPrint('⚠️ Parse error pattern 4: $e');
      }
    }

    // Pattern 5: INTELLIGENCE - Extraire TOUS les nombres + mots-clés indépendamment
    // Cherche n'importe quel nombre avec "rep-like" mot et n'importe quel nombre avec "kg-like" mot
    // ULTRA FLEXIBLE : accepte TOUTES les variations possibles
    final repsPattern = RegExp(
      r'(\d+)\s*(?:rep|reps|répétitions?|répétition|wraps?|repetitions?|times?|sets?|séries?|série|fois|x)',
      caseSensitive: false,
    );
    final weightPattern = RegExp(
      r'(\d+\.?\d*)\s*(?:kg|kilo|kilos|kilogrammes?|pounds?|lbs?|lb)',
      caseSensitive: false,
    );

    final repsMatch = repsPattern.firstMatch(cleaned);
    final weightMatch = weightPattern.firstMatch(cleaned);

    if (repsMatch != null || weightMatch != null) {
      try {
        final reps = repsMatch != null ? int.parse(repsMatch.group(1)!) : null;
        var weight = weightMatch != null ? double.parse(weightMatch.group(1)!) : null;


        if (reps != null || weight != null) {
          debugPrint('✅ Parsed (pattern 5 - intelligent): ${reps ?? 0} reps, ${weight?.toStringAsFixed(1) ?? 0.0}');
          return WorkoutSetData(reps: reps, weight: weight);
        }
      } catch (e) {
        debugPrint('⚠️ Parse error pattern 5: $e');
      }
    }

    // Pattern 6: Format français "10 répétitions à 80 kilos" ou "10 reps at 80kg"
    final pattern6 = RegExp(
      r'(\d+)\s*(?:rep|reps|répétitions?|répétition|séries?|série|fois)\s*(?:à|at|of)\s*(\d+\.?\d*)\s*(?:kg|kilo|kilos|kilogrammes?|pounds?|lbs?|lb)',
      caseSensitive: false,
    );
    final match6 = pattern6.firstMatch(cleaned);
    if (match6 != null) {
      try {
        final reps = int.parse(match6.group(1)!);
        final weight = double.parse(match6.group(2)!);
        debugPrint('✅ Parsed (pattern 6 - à/at): $reps reps, $weight kg');
        return WorkoutSetData(reps: reps, weight: weight);
      } catch (e) {
        debugPrint('⚠️ Parse error pattern 6: $e');
      }
    }

    // Pattern 7: Nombres avec virgule décimale "10 reps 82.5 kilos" ou "12 fois 75,5kg"
    final pattern7 = RegExp(
      r'(\d+)\s*(?:rep|reps|répétitions?|répétition|séries?|série|fois|x)\s*(\d+[.,]\d+)\s*(?:kg|kilo|kilos|kilogrammes?|pounds?|lbs?|lb)',
      caseSensitive: false,
    );
    final match7 = pattern7.firstMatch(cleaned);
    if (match7 != null) {
      try {
        final reps = int.parse(match7.group(1)!);
        final weightStr = match7.group(2)!.replaceAll(',', '.');
        final weight = double.parse(weightStr);
        debugPrint('✅ Parsed (pattern 7 - decimal): $reps reps, $weight kg');
        return WorkoutSetData(reps: reps, weight: weight);
      } catch (e) {
        debugPrint('⚠️ Parse error pattern 7: $e');
      }
    }

    // Pattern 8: Format "je fais 10 à 80" ou "I do 10 at 80"
    final pattern8 = RegExp(
      r'(?:je fais|i do|fais|do)?\s*(\d+)\s*(?:à|at|with)?\s*(\d+\.?\d*)',
      caseSensitive: false,
    );
    final match8 = pattern8.firstMatch(cleaned);
    if (match8 != null) {
      try {
        final first = int.parse(match8.group(1)!);
        final second = double.parse(match8.group(2)!);
        // Heuristique: si premier < 50, c'est probablement reps
        if (first < 50) {
          debugPrint('✅ Parsed (pattern 8 - je fais): $first reps, $second kg');
          return WorkoutSetData(reps: first, weight: second);
        }
      } catch (e) {
        debugPrint('⚠️ Parse error pattern 8: $e');
      }
    }

    debugPrint('❌ No pattern matched for: "$cleaned"');
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
