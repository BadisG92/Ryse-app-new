import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../ai/ryze_oneshot.dart';
import '../ai/ryze_transport.dart';
import '../config/gemini_config.dart';
import '../models/ai_analysis_models.dart';
import 'location_service.dart';
import 'localization_service.dart';
import 'translations.dart';

/// Lire une assiette, ou une phrase, et en tirer des macros.
///
/// Deux chemins arrivent ici : la photo prise au scanner, avec la note tapée
/// avant le déclenchement, et la description écrite à la main ou dictée à
/// Ryze. Les deux posent la même question au modèle et reçoivent la même
/// forme de réponse ; seul ce qu'ils lui donnent à regarder change.
///
/// La règle qui commande tout le reste : **une quantité annoncée par
/// l'utilisateur est un fait, pas un indice**. « 150 g de purée » doit être
/// chiffré sur 150 g de purée, sans arrondi et sans correction. Le modèle le
/// dit lui-même, par le champ `portion_from`, et c'est ce champ qui décide si
/// la compensation ci-dessous s'applique.
class GeminiAnalysisServiceV2 {
  /// Ce que le modèle sous-estime, et de combien.
  ///
  /// Ces facteurs ne s'appliquent qu'aux portions que le modèle a **devinées**
  /// à l'œil, où il se trompe de façon connue et dans le même sens : l'huile
  /// de cuisson, la sauce et le beurre lui échappent. Ils ne s'appliquent
  /// jamais à une quantité donnée par l'utilisateur.
  ///
  /// Il y avait ici une quatrième entrée, `calories: 1.25`, que rien n'a
  /// jamais lue : les calories ne sont pas rendues par le modèle, elles sont
  /// recalculées depuis les macros (4/4/9). L'inflation réelle d'un plat
  /// ordinaire est donc d'environ 17 %, et non de 25.
  static const Map<String, double> geminiCorrections = {
    'proteines': 1.15,
    'glucides': 1.20,
    'lipides': 1.10,
  };

  /// En dessous, l'aliment est trop incertain pour valoir une ligne.
  ///
  /// Le même seuil des deux côtés. La photo exigeait 0,6 et ne gardait que
  /// cinq aliments : un plat vu mais mal identifié disparaissait sans un mot,
  /// et le total devenait faux sans que rien ne le dise. L'écran de revue est
  /// là pour ça — mieux vaut une ligne à retirer qu'une ligne manquante.
  static const double _minConfidence = 0.3;

  /// Au-delà, la liste devient impossible à relire.
  static const int _maxFoods = 8;

  /// Resize image to optimize for Gemini API (max 1024x1024)
  static Future<Uint8List> _resizeImage(Uint8List imageBytes) async {
    try {
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      if (image.width <= 1024 && image.height <= 1024) return imageBytes;

      final img.Image resized = img.copyResize(
        image,
        width: image.width > image.height ? 1024 : null,
        height: image.height >= image.width ? 1024 : null,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (e) {
      if (kDebugMode) debugPrint('Error resizing image: $e');
      return imageBytes;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // LA PHOTO
  // ═══════════════════════════════════════════════════════════════════

  /// Analyse une photo de repas, avec la note tapée avant le déclenchement.
  static Future<AIAnalysisResult> analyzeImage(File imageFile, {String? userNote}) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (!GeminiConfig.isConfigured) {
        return AIAnalysisResult.error(
          error: 'gemini_not_configured',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      final cultureContext = await LocationService.getFoodCultureContext();
      final countryName = await LocationService.getUserCountryName();
      final languageCode = LocalizationService.instance.currentLanguageCode;

      // L'image part redimensionnée : au-delà de 1024 px le modèle ne voit
      // rien de plus, et la requête double de poids.
      final Uint8List resized = await _resizeImage(await imageFile.readAsBytes());

      final prompt = buildImagePrompt(
        userNote: userNote,
        countryName: countryName,
        cultureContext: cultureContext,
        languageCode: languageCode,
      );

      final response = await _makeGeminiRequest(prompt, imageBytes: resized);
      stopwatch.stop();
      final processingTime = stopwatch.elapsedMilliseconds / 1000.0;

      if (response == null) {
        return AIAnalysisResult.error(
          error: 'gemini_no_response',
          processingTime: processingTime,
        );
      }

      final parsed = parseFoods(response);

      if (parsed.error != null) {
        return AIAnalysisResult.error(
          error: parsed.error!,
          processingTime: processingTime,
        );
      }
      if (parsed.foods.isEmpty) {
        return AIAnalysisResult.error(
          error: 'gemini_no_foods_detected',
          processingTime: processingTime,
        );
      }

      return AIAnalysisResult.success(
        detectedFoods: parsed.foods,
        mealName: parsed.mealName,
        processingTime: processingTime,
      );
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) debugPrint('❌ analyzeImage: $e');
      return AIAnalysisResult.error(
        error: 'gemini_analysis_failed',
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
      );
    }
  }

  /// Analyse une photo, avec un repas d'exemple si la clé manque.
  ///
  /// Le repas d'exemple ne sort **qu'en développement**. En production, une
  /// blanquette inventée présentée comme une analyse serait un mensonge, et
  /// le jour où la clé passera côté serveur `isConfigured` deviendra faux
  /// pour tout le monde.
  static Future<AIAnalysisResult> analyzeImageWithFallback(File imageFile, {String? userNote}) async {
    final result = await analyzeImage(imageFile, userNote: userNote);

    if (!result.success && !GeminiConfig.isConfigured && kDebugMode) {
      return createMockAnalysisResult(userNote: userNote);
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════
  // LA DESCRIPTION
  // ═══════════════════════════════════════════════════════════════════

  /// Analyse un repas décrit en toutes lettres, sans photo.
  static Future<AIAnalysisResult> analyzeTextDescription(
    String textDescription, {
    String? userNote,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (!GeminiConfig.isConfigured) {
        return AIAnalysisResult.error(error: 'gemini_not_configured', processingTime: 0);
      }

      final languageCode = LocalizationService.instance.currentLanguageCode;
      final countryName = await LocationService.getUserCountryName();

      final prompt = buildTextPrompt(
        textDescription: textDescription,
        userNote: userNote,
        countryName: countryName,
        languageCode: languageCode,
      );

      final response = await _makeGeminiRequest(prompt);
      stopwatch.stop();
      final processingTime = stopwatch.elapsedMilliseconds / 1000.0;

      if (response == null) {
        return AIAnalysisResult.error(
          error: 'gemini_no_response',
          processingTime: processingTime,
        );
      }

      final parsed = parseFoods(response);

      if (parsed.error != null) {
        return AIAnalysisResult.error(error: parsed.error!, processingTime: processingTime);
      }
      if (parsed.foods.isEmpty) {
        return AIAnalysisResult.error(
          error: 'gemini_no_foods_detected',
          processingTime: processingTime,
        );
      }

      return AIAnalysisResult.success(
        detectedFoods: parsed.foods,
        mealName: parsed.mealName,
        processingTime: processingTime,
      );
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) debugPrint('❌ analyzeTextDescription: $e');
      return AIAnalysisResult.error(
        error: 'gemini_analysis_failed',
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // CE QU'ON DEMANDE AU MODÈLE
  // ═══════════════════════════════════════════════════════════════════

  static String _languageName(String code) =>
      code == 'fr' ? 'French' : code == 'de' ? 'German' : 'English';

  /// La forme de la réponse, la même pour les deux chemins.
  ///
  /// Elle était écrite deux fois pour la photo — dont une copie que plus rien
  /// n'appelait — et une troisième fois pour la description, avec des champs
  /// différents. Les liquides, par exemple, n'existaient que du côté du
  /// texte : un verre de jus photographié était pesé en grammes.
  static String _responseShape(String responseLanguage) => '''
Respond with JSON only, in this exact shape:

{
  "meal_name": "a short, appetising name for the whole dish, in $responseLanguage",
  "foods": [
    {
      "name": "the food, named the way someone would say it, in $responseLanguage",
      "confidence": 85,
      "is_liquid": false,
      "portion_grams": 150,
      "portion_ml": null,
      "portion_from": "estimate",
      "nutrition": { "proteins_g": 3.0, "carbs_g": 22.0, "fats_g": 5.0 }
    }
  ]
}

Rules for these fields:
- "is_liquid": true for anything drunk. Liquids carry "portion_ml" and leave "portion_grams" null; solids do the opposite.
- "nutrition": the values for THIS portion, not for 100 g. If the portion is 150 g, give what 150 g contains.
- "confidence": 0 to 100, how sure you are of the identification.
- Group what is eaten together into one line (coffee with milk and sugar is one item). At most $_maxFoods lines.
- Every word you write goes in $responseLanguage.''';

  /// La règle qui commande tout le reste.
  ///
  /// Le prompt jurait déjà « pas un kcal d'écart » quand l'utilisateur donnait
  /// un chiffre, mais le code multipliait ensuite les macros par les facteurs
  /// de compensation : 150 g de purée annoncés s'affichaient avec les
  /// calories de 175 g. Le modèle dit maintenant d'où vient chaque quantité,
  /// et la compensation épargne celles qui viennent de l'utilisateur.
  static const String _portionSourceRule = '''
"portion_from" is the most important field in your answer. It says where the amount comes from:

- "user" — the person stated the amount for this item themselves: in grams or millilitres ("150 g of mash"), as a count ("2 eggs"), as a household measure ("a tablespoon of olive oil"), or as a calorie figure ("a 500 kcal cake"). Copy their number exactly into the portion field. Do not round it, do not adjust it, do not second-guess it against what you see. Work out the nutrition for exactly that amount. If they gave calories instead of a weight, choose macros that add up to exactly that figure using 4 kcal per gram of protein and of carbohydrate, 9 per gram of fat.
- "estimate" — you judged the amount yourself.

Never write "user" for an item whose amount the person did not give. Never write "estimate" for one they did. When they name an amount for one item only, that item is "user" and the others stay "estimate".''';

  /// Ce qui fait qu'une estimation est trop basse, dit au modèle plutôt que
  /// rattrapé après coup par un facteur.
  static const String _estimationGuidance = '''
When you estimate, count what people forget:
- the fat used to cook, the butter in the purée, the oil in the pan and on the salad;
- sauces, dressings, gravy, syrup, and what soaked into the food;
- weigh food as it is served, cooked, not as raw ingredients.''';

  /// Le prompt tel qu'il part, pour que le banc de coût le mesure sans
  /// le recopier — une copie dériverait au premier changement.
  @visibleForTesting
  static String buildImagePrompt({
    required String? userNote,
    required String countryName,
    required String cultureContext,
    required String languageCode,
  }) {
    final responseLanguage = _languageName(languageCode);
    final note = userNote?.trim() ?? '';
    final hasNote = note.isNotEmpty;

    return '''
You read a photo of a meal and work out what it holds.

The photo was taken in $countryName, where the cooking is $cultureContext. Recognise local dishes when you see them.
${hasNote ? '\nThe person wrote this alongside the photo: "$note"\nIt is not a caption, it is information about the meal. Where it names an amount, that amount wins over anything you think you see.\n' : ''}
To judge the portions, use what the photo gives you for scale: the diameter of the plate, a fork or a spoon beside it, the height of the glass, a hand. Say what is on the plate, not what a recipe would call for.

$_estimationGuidance

$_portionSourceRule

Only list food you can actually identify. If several pieces of the same thing are on the plate, make them one line with the total weight.

${_responseShape(responseLanguage)}''';
  }

  /// Le prompt tel qu'il part, pour que le banc de coût le mesure sans
  /// le recopier — une copie dériverait au premier changement.
  @visibleForTesting
  static String buildTextPrompt({
    required String textDescription,
    String? userNote,
    required String countryName,
    required String languageCode,
  }) {
    final responseLanguage = _languageName(languageCode);
    final note = userNote?.trim() ?? '';

    // La phrase d'aide est la seule chose que l'utilisateur lira telle quelle :
    // elle est écrite dans sa langue, pas traduite par le modèle.
    final suggestion = 'ai_describe_meal_hint'.tr(languageCode);

    return '''
You read a meal written in plain words and work out what it holds.

What the person wrote: "$textDescription"
${note.isEmpty ? '' : '\nExtra context: "$note"\n'}
They are in $countryName. Use the portions and preparations usual there.

FIRST, check there is food in it. If the text names no food at all, answer with this and nothing else:
{ "error": "non_food_input", "suggestion": "$suggestion" }

Then, for a real meal:
- Where no amount is given, use an ordinary portion for one person, not a family dish. A glass of juice is 250 ml, a steak is 150 g.
- $_estimationGuidance

$_portionSourceRule

${_responseShape(responseLanguage)}''';
  }

  // ═══════════════════════════════════════════════════════════════════
  // CE QU'ON EN FAIT
  // ═══════════════════════════════════════════════════════════════════

  /// Envoie la requête et rend le JSON de la réponse.
  ///
  /// Les deux chemins passaient par des clients différents, dont un qui posait
  /// la clé dans l'adresse. Ils passent maintenant par le transport commun,
  /// donc par la fonction serveur dès que le drapeau l'ordonne.
  static Future<Map<String, dynamic>?> _makeGeminiRequest(
    String prompt, {
    Uint8List? imageBytes,
  }) =>
      RyzeOneShot.jsonObject(
        prompt: prompt,
        surface: RyzeUsageLabel.scan,
        imageJpeg: imageBytes,
        // Une photo demande plus de patience qu'une phrase : elle voyage.
        timeout: Duration(seconds: imageBytes == null ? 45 : 60),
      );

  /// Ce que la lecture d'une réponse a donné.
  @visibleForTesting
  static ({List<DetectedFood> foods, String? mealName, String? error}) parseFoods(
    Map<String, dynamic> response,
  ) {
    final lang = LocalizationService.instance.currentLanguageCode;

    // Le modèle a jugé qu'il n'y avait pas de nourriture là-dedans.
    if (response['error'] == 'non_food_input') {
      final suggestion = response['suggestion'] as String?;
      return (
        foods: const <DetectedFood>[],
        mealName: null,
        error: suggestion?.trim().isNotEmpty == true
            ? suggestion
            : 'ai_describe_meal_hint'.tr(lang),
      );
    }

    final foods = <DetectedFood>[];
    final rawFoods = response['foods'];

    if (rawFoods is List) {
      for (final entry in rawFoods) {
        if (entry is! Map) continue;
        try {
          final nutrition = entry['nutrition'];
          if (nutrition is! Map) continue;

          final isLiquid = entry['is_liquid'] == true;
          final portion = isLiquid
              ? _toDouble(entry['portion_ml']) ?? _toDouble(entry['portion_grams'])
              : _toDouble(entry['portion_grams']) ?? _toDouble(entry['portion_ml']);

          // Ce que l'utilisateur a annoncé est pris tel quel. Le reste porte
          // la compensation d'une estimation visuelle trop basse.
          final fromUser = '${entry['portion_from']}'.toLowerCase() == 'user';
          final k = fromUser ? _noCorrection : geminiCorrections;

          final food = DetectedFood.fromAIResponse(
            name: '${entry['name'] ?? ''}'.trim().isEmpty
                ? 'coach_detected_dish'.tr(lang)
                : '${entry['name']}'.trim(),
            confidence: (_toDouble(entry['confidence']) ?? 50) / 100.0,
            portionGrams: portion ?? 100,
            proteins: (_toDouble(nutrition['proteins_g']) ?? 0) * k['proteines']!,
            carbs: (_toDouble(nutrition['carbs_g']) ?? 0) * k['glucides']!,
            fats: (_toDouble(nutrition['fats_g']) ?? 0) * k['lipides']!,
            isLiquid: isLiquid,
          );

          if (food.confidence >= _minConfidence) foods.add(food);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ aliment illisible : $e');
          continue;
        }
      }
    }

    final name = '${response['meal_name'] ?? ''}'.trim();

    return (
      foods: foods.take(_maxFoods).toList(),
      mealName: name.isEmpty ? 'coach_detected_dish'.tr(lang) : name,
      error: null,
    );
  }

  /// Une quantité donnée par l'utilisateur ne se corrige pas.
  static const Map<String, double> _noCorrection = {
    'proteines': 1.0,
    'glucides': 1.0,
    'lipides': 1.0,
  };

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  // ═══════════════════════════════════════════════════════════════════
  // DÉVELOPPEMENT
  // ═══════════════════════════════════════════════════════════════════

  /// Un repas d'exemple, pour travailler sans clé. Jamais en production.
  static AIAnalysisResult createMockAnalysisResult({String? userNote}) {
    final lang = LocalizationService.instance.currentLanguageCode;

    return AIAnalysisResult.success(
      detectedFoods: [
        DetectedFood.fromAIResponse(
          name: 'Blanquette de veau',
          confidence: 0.93,
          portionGrams: 200,
          proteins: 28.5,
          carbs: 8.2,
          fats: 15.8,
        ),
        DetectedFood.fromAIResponse(
          name: 'Riz blanc',
          confidence: 0.89,
          portionGrams: 120,
          proteins: 3.2,
          carbs: 28.4,
          fats: 0.4,
        ),
      ],
      mealName: 'coach_detected_dish'.tr(lang),
      processingTime: 2.5,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // VALIDATION DU FICHIER
  // ═══════════════════════════════════════════════════════════════════

  static bool isValidImageFile(File imageFile) {
    final String extension = imageFile.path.toLowerCase().split('.').last;
    const List<String> supportedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return supportedExtensions.contains(extension);
  }

  /// Get maximum file size allowed (20MB for Gemini)
  static const int maxFileSizeBytes = 20 * 1024 * 1024;

  static Future<bool> isValidFileSize(File imageFile) async {
    try {
      final int fileSize = await imageFile.length();
      return fileSize <= maxFileSizeBytes;
    } catch (e) {
      return false;
    }
  }

  /// Validate image file completely. Rend une clé de traduction, ou null.
  static Future<String?> validateImageFile(File imageFile) async {
    if (!await imageFile.exists()) return 'ai_image_missing';
    if (!isValidImageFile(imageFile)) return 'ai_image_format_unsupported';
    if (!await isValidFileSize(imageFile)) return 'ai_image_too_large';
    return null;
  }
}
