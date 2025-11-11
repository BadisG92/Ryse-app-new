import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';
import '../models/ai_analysis_models.dart';
import 'location_service.dart';
import 'localization_service.dart';
import 'translations.dart';

class GeminiAnalysisServiceV2 {

  // Corrections pour compenser la sous-estimation de Gemini
  static const Map<String, double> geminiCorrections = {
    'calories': 1.25,     // +25% (50% des cas dévient de +20%)
    'proteines': 1.15,    // +15% (tendance sous-estimation)
    'glucides': 1.20,     // +20% (sous-estimation fréquente)
    'lipides': 1.10,      // +10% (moins problématique)
  };

  /// Resize image to optimize for Gemini API (max 1024x1024)
  static Future<Uint8List> _resizeImage(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Unable to decode image');
      }

      // Calculate new dimensions (max 1024x1024, maintain aspect ratio)
      const maxDimension = 1024;
      int newWidth = image.width;
      int newHeight = image.height;

      if (newWidth > maxDimension || newHeight > maxDimension) {
        if (newWidth > newHeight) {
          newHeight = (newHeight * maxDimension / newWidth).round();
          newWidth = maxDimension;
        } else {
          newWidth = (newWidth * maxDimension / newHeight).round();
          newHeight = maxDimension;
        }
      }

      // Resize image if needed
      if (newWidth != image.width || newHeight != image.height) {
        final resizedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
        // Encode as JPEG with 85% quality to reduce size further
        return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
      }

      return imageBytes;
    } catch (e) {
      if (kDebugMode) debugPrint('Error resizing image: $e');
      return imageBytes; // Return original if resize fails
    }
  }

  /// Analyze an image from bytes for food detection using Gemini 1.5 Flash (Web compatible)
  static Future<AIAnalysisResult> analyzeImageFromBytes(Uint8List imageBytes, {String? userNote}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Check if Gemini is configured
      if (!GeminiConfig.isConfigured) {
        return AIAnalysisResult.error(
          error: 'Gemini API not configured. Please set your API key.',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      // Resize image
      final Uint8List resizedBytes = await _resizeImage(imageBytes);
      final String base64Image = base64Encode(resizedBytes);

      // Get user's country for cultural context
      final cultureContext = await LocationService.getFoodCultureContext();
      final countryName = await LocationService.getUserCountryName();
      
      // Create detailed prompt for food analysis with user note integration
      final userNoteContext = userNote != null && userNote.trim().isNotEmpty 
        ? "\n\nUser note: \"$userNote\"\nPlease take this user note into account for more accurate analysis of portion sizes and food identification."
        : "";
      
      final prompt = '''
Analyze this food image taken in $countryName ($cultureContext region).$userNoteContext

Please provide a detailed JSON response with the following structure:

{
  "meal_name": "Creative name for this meal/dish (e.g., 'Salade méditerranéenne', 'Plat du jour', etc.)",
  "foods": [
    {
      "name": "Food name in local language",
      "confidence": 85,
      "portion_grams": 120,
      "nutrition": {
        "proteins_g": 15.2,
        "carbs_g": 25.8,
        "fats_g": 8.1
      },
      "description": "Brief description of what you see"
    }
  ]
}

Requirements:
1. Generate a creative, appetizing name for the overall meal/dish in the "meal_name" field
2. Estimate portion sizes based on visual cues in the image (plate size, food volume, typical serving sizes you can observe)${userNote != null && userNote.trim().isNotEmpty ? " and the user's note" : ""}
3. Provide nutritional values in grams for the estimated portion size
4. Use confidence scores from 0-100 based on how clearly you can identify each item
5. Recognize local dishes common in $cultureContext if present
6. Focus only on food items that are clearly visible and identifiable
7. If you see multiple similar items, combine them into one entry with total weight

Be precise with your estimations and only include foods you can confidently identify.
''';

      // Prepare the Gemini API request
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': GeminiConfig.generationConfig,
        'safetySettings': GeminiConfig.safetySettingsList,
      };

      // Make the API call
      final response = await http.post(
        Uri.parse(GeminiConfig.fullApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        return _processGeminiResponse(
          response.body, 
          stopwatch.elapsedMilliseconds / 1000.0,
        );
      } else {
        return AIAnalysisResult.error(
          error: 'API request failed: ${response.statusCode} - ${response.body}',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

    } catch (e) {
      stopwatch.stop();
      return AIAnalysisResult.error(
        error: 'Analysis failed: $e',
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
      );
    }
  }

  /// Analyze an image file for food detection using Gemini 1.5 Flash
  static Future<AIAnalysisResult> analyzeImage(File imageFile, {String? userNote}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Check if Gemini is configured
      if (!GeminiConfig.isConfigured) {
        return AIAnalysisResult.error(
          error: 'Gemini API not configured. Please set your API key.',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      // Convert and resize image to base64
      final Uint8List originalBytes = await imageFile.readAsBytes();
      final Uint8List resizedBytes = await _resizeImage(originalBytes);
      final String base64Image = base64Encode(resizedBytes);

      // Get user's country for cultural context
      final cultureContext = await LocationService.getFoodCultureContext();
      final countryName = await LocationService.getUserCountryName();
      
      // Create detailed prompt for food analysis with user note integration
      final userNoteContext = userNote != null && userNote.trim().isNotEmpty 
        ? "\n\nUser note: \"$userNote\"\nPlease take this user note into account for more accurate analysis of portion sizes and food identification."
        : "";
      
      final prompt = '''
Analyze this food image taken in $countryName ($cultureContext region).$userNoteContext

Please provide a detailed JSON response with the following structure:

{
  "meal_name": "Creative name for this meal/dish (e.g., 'Salade méditerranéenne', 'Plat du jour', etc.)",
  "foods": [
    {
      "name": "Food name in local language",
      "confidence": 85,
      "portion_grams": 120,
      "nutrition": {
        "proteins_g": 15.2,
        "carbs_g": 25.8,
        "fats_g": 8.1
      },
      "description": "Brief description of what you see"
    }
  ]
}

Requirements:
1. Generate a creative, appetizing name for the overall meal/dish in the "meal_name" field
2. Estimate portion sizes based on visual cues in the image (plate size, food volume, typical serving sizes you can observe)${userNote != null && userNote.trim().isNotEmpty ? " and the user's note" : ""}
3. Provide nutritional values in grams for the estimated portion size
4. Use confidence scores from 0-100 based on how clearly you can identify each item
5. Recognize local dishes common in $cultureContext if present
6. Focus only on food items that are clearly visible and identifiable
7. If you see multiple similar items, combine them into one entry with total weight

Be precise with your estimations and only include foods you can confidently identify.
''';

      // Prepare the Gemini API request
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': GeminiConfig.generationConfig,
        'safetySettings': GeminiConfig.safetySettingsList,
      };

      // Make the API call
      final response = await http.post(
        Uri.parse(GeminiConfig.fullApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        return _processGeminiResponse(
          response.body, 
          stopwatch.elapsedMilliseconds / 1000.0,
        );
      } else {
        return AIAnalysisResult.error(
          error: 'API request failed: ${response.statusCode} - ${response.body}',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

    } catch (e) {
      stopwatch.stop();
      return AIAnalysisResult.error(
        error: 'Analysis failed: $e',
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
      );
    }
  }

  /// Process the Gemini API response
  static AIAnalysisResult _processGeminiResponse(String responseBody, double processingTime) {
    try {
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);
      
      // Check for API errors
      if (jsonResponse.containsKey('error')) {
        return AIAnalysisResult.error(
          error: 'Gemini API Error: ${jsonResponse['error']['message']}',
          processingTime: processingTime,
        );
      }

      final List<dynamic> candidates = jsonResponse['candidates'] ?? [];
      if (candidates.isEmpty) {
        return AIAnalysisResult.error(
          error: 'No response from Gemini API',
          processingTime: processingTime,
        );
      }

      final String textResponse = candidates[0]['content']['parts'][0]['text'] ?? '';
      
      // Parse the JSON response from Gemini
      final parseResult = _parseGeminiTextResponse(textResponse);

      return AIAnalysisResult.success(
        detectedFoods: parseResult['foods'],
        mealName: parseResult['mealName'],
        processingTime: processingTime,
      );

    } catch (e) {
      return AIAnalysisResult.error(
        error: 'Failed to process API response: $e',
        processingTime: processingTime,
      );
    }
  }

  /// Parse Gemini's text response to extract food data and meal name
  static Map<String, dynamic> _parseGeminiTextResponse(String textResponse) {
    final List<DetectedFood> detectedFoods = [];
    String? mealName;
    
    try {
      // Look for JSON in the response (Gemini sometimes adds extra text)
      final jsonStartIndex = textResponse.indexOf('{');
      final jsonEndIndex = textResponse.lastIndexOf('}') + 1;
      
      if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
        final jsonString = textResponse.substring(jsonStartIndex, jsonEndIndex);
        final Map<String, dynamic> parsedJson = json.decode(jsonString);
        
        // Extract meal name
        mealName = parsedJson['meal_name'] ?? 'coach_detected_dish'.tr(LocalizationService.instance.currentLanguageCode);
        
        final List<dynamic> foods = parsedJson['foods'] ?? [];
        
        for (final foodData in foods) {
          try {
            // Récupérer les valeurs brutes de Gemini
            final rawProteins = (foodData['nutrition']['proteins_g'] ?? 0).toDouble();
            final rawCarbs = (foodData['nutrition']['carbs_g'] ?? 0).toDouble();
            final rawFats = (foodData['nutrition']['fats_g'] ?? 0).toDouble();

            // Appliquer les corrections pour compenser la sous-estimation de Gemini
            final correctedProteins = rawProteins * geminiCorrections['proteines']!;
            final correctedCarbs = rawCarbs * geminiCorrections['glucides']!;
            final correctedFats = rawFats * geminiCorrections['lipides']!;

            final detectedFood = DetectedFood.fromAIResponse(
              name: foodData['name'] ?? 'Unknown food',
              confidence: (foodData['confidence'] ?? 50).toDouble() / 100.0,
              portionGrams: (foodData['portion_grams'] ?? 100).toDouble(),
              proteins: correctedProteins,
              carbs: correctedCarbs,
              fats: correctedFats,
            );

            // Only include foods with reasonable confidence
            if (detectedFood.confidence >= GeminiConfig.confidenceThreshold) {
              detectedFoods.add(detectedFood);
            }
          } catch (e) {
            if (kDebugMode) debugPrint('Error parsing food item: $e');
            continue;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error parsing Gemini response: $e');
      // Fallback: try to extract food names from text response
      final fallbackFoods = _extractFoodsFromText(textResponse);
      return {
        'foods': fallbackFoods,
        'mealName': 'coach_detected_dish'.tr(LocalizationService.instance.currentLanguageCode),
      };
    }
    
    return {
      'foods': detectedFoods.take(5).toList(), // Limit to 5 items
      'mealName': mealName ?? 'coach_detected_dish'.tr(LocalizationService.instance.currentLanguageCode),
    };
  }

  /// Analyze text description of food without image
  static Future<AIAnalysisResult> analyzeTextDescription(
    String textDescription, {
    String? userNote,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Check if Gemini is configured
      if (!GeminiConfig.isConfigured) {
        return AIAnalysisResult.error(
          error: 'gemini_not_configured',
          processingTime: 0,
        );
      }

      // Get user's language for better localization
      final languageCode = LocalizationService.instance.currentLanguageCode;
      final countryName = languageCode == 'fr' ? 'France' : 'United States';

      final prompt = _buildTextAnalysisPrompt(
        textDescription: textDescription,
        userNote: userNote,
        countryName: countryName,
        languageCode: languageCode,
      );

      if (kDebugMode) debugPrint('🔍 DEBUG: Sending text analysis request to Gemini...');
      final response = await _makeGeminiRequest(prompt, null);
      if (kDebugMode) debugPrint('🔍 DEBUG: Got response: ${response != null ? "YES" : "NULL"}');

      stopwatch.stop();
      final processingTime = stopwatch.elapsedMilliseconds / 1000.0;

      if (response == null) {
        if (kDebugMode) debugPrint('❌ DEBUG: Response is null');
        return AIAnalysisResult.error(
          error: 'gemini_no_response',
          processingTime: processingTime,
        );
      }

      if (kDebugMode) debugPrint('🔍 DEBUG: Response content: ${response.toString()}');

      // Parse the response directly - _makeGeminiRequest already returns parsed JSON
      final parseResult = _parseTextResponseFromJson(response);

      // Check for non-food input error
      if (parseResult.containsKey('error') && parseResult['error'] == 'non_food_input') {
        if (kDebugMode) debugPrint('❌ DEBUG: Non-food input detected');
        return AIAnalysisResult.error(
          error: parseResult['suggestion'] ?? 'Please describe food items with quantities. Examples: "250ml orange juice", "2 eggs with 50g cheese", "1 apple and 200ml milk"',
          processingTime: processingTime,
        );
      }

      if (parseResult['foods'].isEmpty) {
        if (kDebugMode) debugPrint('❌ DEBUG: No foods detected in response');
        return AIAnalysisResult.error(
          error: 'gemini_no_foods_detected',
          processingTime: processingTime,
        );
      }

      return AIAnalysisResult.success(
        detectedFoods: parseResult['foods'],
        mealName: parseResult['mealName'],
        processingTime: processingTime,
      );

    } catch (e, stackTrace) {
      stopwatch.stop();
      if (kDebugMode) debugPrint('❌ DEBUG: Error analyzing text: $e');
      if (kDebugMode) debugPrint('❌ DEBUG: Stack trace: $stackTrace');
      return AIAnalysisResult.error(
        error: 'gemini_analysis_failed',
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
      );
    }
  }

  /// Parse JSON response from _makeGeminiRequest
  static Map<String, dynamic> _parseTextResponseFromJson(Map<String, dynamic> jsonResponse) {
    final List<DetectedFood> detectedFoods = [];
    String? mealName;

    try {
      // Check for validation error (non-food input)
      if (jsonResponse.containsKey('error') && jsonResponse['error'] == 'non_food_input') {
        return {
          'error': 'non_food_input',
          'suggestion': jsonResponse['suggestion'] ?? 'Please describe food items with quantities.',
          'foods': [],
          'mealName': null,
        };
      }

      // Extract meal name
      mealName = jsonResponse['meal_name'] ?? 'Plat détecté';

      final List<dynamic> foods = jsonResponse['foods'] ?? [];

      for (final foodData in foods) {
        try {
          // Check if it's a liquid (use portion_ml) or solid (use portion_grams)
          final isLiquid = foodData['is_liquid'] ?? false;
          final portionGrams = isLiquid
            ? (foodData['portion_ml'] ?? 100).toDouble()  // ml for liquids
            : (foodData['portion_grams'] ?? 100).toDouble(); // grams for solids

          // Récupérer les valeurs brutes de Gemini
          final rawProteins = (foodData['nutrition']['proteins_g'] ?? 0).toDouble();
          final rawCarbs = (foodData['nutrition']['carbs_g'] ?? 0).toDouble();
          final rawFats = (foodData['nutrition']['fats_g'] ?? 0).toDouble();

          // Appliquer les corrections pour compenser la sous-estimation de Gemini
          final correctedProteins = rawProteins * geminiCorrections['proteines']!;
          final correctedCarbs = rawCarbs * geminiCorrections['glucides']!;
          final correctedFats = rawFats * geminiCorrections['lipides']!;

          final detectedFood = DetectedFood.fromAIResponse(
            name: foodData['name'] ?? 'Unknown food',
            confidence: (foodData['confidence'] ?? 50).toDouble() / 100.0,
            portionGrams: portionGrams,
            proteins: correctedProteins,
            carbs: correctedCarbs,
            fats: correctedFats,
            isLiquid: isLiquid, // Pass the isLiquid flag
          );

          // Include all foods with some confidence
          if (detectedFood.confidence >= 0.3) {
            detectedFoods.add(detectedFood);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error parsing food item: $e');
          continue;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error parsing JSON response: $e');
    }

    return {
      'foods': detectedFoods.take(8).toList(), // Limit to 8 items
      'mealName': mealName ?? 'Plat détecté',
    };
  }

  /// Build prompt for text-based food analysis
  static String _buildTextAnalysisPrompt({
    required String textDescription,
    String? userNote,
    required String countryName,
    required String languageCode,
  }) {
    final isFrench = languageCode == 'fr';
    final errorSuggestion = isFrench
      ? "Veuillez décrire un repas ou des aliments avec leurs quantités. Bonnes pratiques :\n• Listez les aliments du repas avec leurs portions (ex: '250ml jus d'orange', '2 œufs avec 50g de fromage')\n• Précisez les quantités en ml pour les liquides, en g pour les solides\n• Ajoutez des détails importants (mode de cuisson, accompagnements, etc.)\n\nExemples : '250ml de jus de carotte', '150g de poulet grillé avec 100g de riz', '1 pomme et 200ml de lait'"
      : "Please describe a meal or food items with quantities. Best practices:\n• List meal items with portions (e.g., '250ml orange juice', '2 eggs with 50g cheese')\n• Specify quantities in ml for liquids, in g for solids\n• Add important details (cooking method, sides, etc.)\n\nExamples: '250ml carrot juice', '150g grilled chicken with 100g rice', '1 apple and 200ml milk'";

    return '''
You are a nutrition expert AI. Analyze this text description of food and provide detailed nutritional information in ${isFrench ? 'French' : 'English'}.

Text description: "$textDescription"

${userNote != null ? 'Additional context: "$userNote"' : ''}

The user is in $countryName. Consider local food portions and preparations typical for this region.

VALIDATION FIRST:
1. Check if the description contains actual FOOD items
2. If the description contains NO food items (e.g., random objects, activities, nonsense), return:
{
  "error": "non_food_input",
  "suggestion": "$errorSuggestion"
}

For valid food descriptions:
1. Identify each food item mentioned in the description
2. Estimate reasonable INDIVIDUAL portions (not family portions)
3. For LIQUIDS: use milliliters (ml) in "portion_ml" field
4. For SOLIDS: use grams (g) in "portion_grams" field
5. If quantities are not specified, use standard INDIVIDUAL portions
6. Group related items logically (e.g., "coffee with milk and sugar" as one item)

Provide your response in the following JSON format:
{
  "meal_name": "A creative, appetizing name for the overall meal in the user's language",
  "foods": [
    {
      "name": "Food item name (be specific)",
      "confidence": 85,
      "portion_grams": 150,  // For solid foods
      "portion_ml": 250,     // For liquid foods (optional, use this OR portion_grams)
      "is_liquid": false,    // true for drinks, false for solid foods
      "nutrition": {
        "proteins_g": 25.5,
        "carbs_g": 30.2,
        "fats_g": 12.8
      }
    }
  ]
}

CRITICAL - EXACT CALORIE MATCHING:
🚨 If the user specifies EXACT calories or quantities for a food item (e.g., "gâteau de 500kcal", "500 calories cake", "200g de poulet"), you MUST respect these values EXACTLY.
- Calculate macros (proteins, carbs, fats) to match EXACTLY the specified calories
- DO NOT add or subtract even 1 kcal (e.g., if user says "500kcal", return exactly 500kcal, NOT 540, NOT 523, NOT 498)
- Use realistic macro distribution for that food type to reach the exact calorie target
- Example: "gâteau de 500kcal" → nutrition values must total EXACTLY 500kcal
- Example: "200g chicken" → use exactly 200g in portion_grams, then calculate accurate nutrition

IMPORTANT:
- Use realistic INDIVIDUAL portions (not family/restaurant portions)
- For liquids: prefer "portion_ml" and set "is_liquid": true
- For solids: use "portion_grams" and set "is_liquid": false
- If user says "jus de carotte" without quantity, assume 250ml (individual glass)
- If user says "steak" without quantity, assume 150g (individual portion)
- Provide accurate nutritional values
- Confidence should reflect how clear the description is
- Name foods in a user-friendly way
- Maximum 8 food items
''';
  }

  /// Make request to Gemini API
  static Future<Map<String, dynamic>?> _makeGeminiRequest(
    String prompt,
    File? imageFile,
  ) async {
    try {
      if (kDebugMode) debugPrint('🔍 DEBUG: Creating Gemini model with key: ${GeminiConfig.geminiApiKey.substring(0, 10)}...');

      final model = GenerativeModel(
        model: GeminiConfig.modelName, // Utilise gemini-2.0-flash comme le coach
        apiKey: GeminiConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: GeminiConfig.temperature,
          topK: GeminiConfig.topK,
          topP: GeminiConfig.topP,
          maxOutputTokens: GeminiConfig.maxOutputTokens,
          responseMimeType: 'application/json', // IMPORTANT: Force JSON response
        ),
      );

      if (kDebugMode) debugPrint('🔍 DEBUG: Preparing content for Gemini...');
      final List<Part> parts = [
        TextPart(prompt),
      ];

      if (imageFile != null) {
        if (kDebugMode) debugPrint('🔍 DEBUG: Adding image to request...');
        final imageBytes = await imageFile.readAsBytes();
        parts.add(DataPart('image/jpeg', imageBytes));
      }

      final content = [Content.multi(parts)];

      if (kDebugMode) debugPrint('🔍 DEBUG: Sending request to Gemini API...');
      final response = await model.generateContent(content);

      if (kDebugMode) debugPrint('🔍 DEBUG: Response received: ${response.text?.substring(0, 100) ?? "NULL"}...');

      if (response.text == null || response.text!.isEmpty) {
        if (kDebugMode) debugPrint('❌ DEBUG: Response text is null or empty');
        return null;
      }

      // Parse JSON from response text
      final jsonStartIndex = response.text!.indexOf('{');
      final jsonEndIndex = response.text!.lastIndexOf('}') + 1;

      if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
        final jsonString = response.text!.substring(jsonStartIndex, jsonEndIndex);
        if (kDebugMode) debugPrint('🔍 DEBUG: Extracted JSON: ${jsonString.substring(0, 100)}...');
        return json.decode(jsonString);
      }

      if (kDebugMode) debugPrint('❌ DEBUG: Could not find JSON in response');
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('❌ DEBUG: Error making Gemini request: $e');
      if (kDebugMode) debugPrint('❌ DEBUG: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fallback method to extract foods from plain text response
  static List<DetectedFood> _extractFoodsFromText(String textResponse) {
    final List<DetectedFood> foods = [];

    // Simple keyword matching as fallback
    final commonFoods = [
      'rice', 'pasta', 'bread', 'chicken', 'beef', 'fish', 'salmon',
      'vegetables', 'salad', 'tomato', 'broccoli', 'carrot', 'potato',
      'apple', 'banana', 'orange', 'cheese', 'egg', 'milk'
    ];

    for (final food in commonFoods) {
      if (textResponse.toLowerCase().contains(food)) {
        foods.add(DetectedFood.fromVisionLabel(
          label: food,
          confidence: 0.7,
          cultureContext: 'International cuisine and standard portion sizes',
        ));
      }
      if (foods.length >= 3) break; // Limit fallback results
    }

    return foods;
  }

  /// Create mock analysis result for development/testing with user note
  static AIAnalysisResult createMockAnalysisResult({String? userNote}) {
    final List<DetectedFood> mockFoods = [
      DetectedFood.fromAIResponse(
        name: userNote?.contains('riz') == true ? 'Riz basmati (${userNote?.replaceAll(RegExp(r'[^\d]'), '') ?? '200'}g)' : 'Blanquette de veau',
        confidence: 0.93,
        portionGrams: userNote?.contains('g') == true 
          ? double.tryParse(userNote!.replaceAll(RegExp(r'[^\d]'), '')) ?? 200.0 
          : 200.0,
        proteins: 28.5,
        carbs: 8.2,
        fats: 15.8,
      ),
      DetectedFood.fromAIResponse(
        name: 'Riz blanc',
        confidence: 0.89,
        portionGrams: 120.0,
        proteins: 3.2,
        carbs: 28.4,
        fats: 0.4,
      ),
      DetectedFood.fromAIResponse(
        name: 'Légumes sautés',
        confidence: 0.85,
        portionGrams: 80.0,
        proteins: 2.1,
        carbs: 6.5,
        fats: 1.2,
      ),
    ];

    final String mealName = userNote?.isNotEmpty == true 
      ? 'Plat personnalisé (avec note utilisateur)' 
      : 'coach_detected_dish'.tr(LocalizationService.instance.currentLanguageCode);

    return AIAnalysisResult.success(
      detectedFoods: mockFoods,
      mealName: mealName,
      processingTime: 2.5,
    );
  }

  /// Analyze image with fallback to mock data for development
  static Future<AIAnalysisResult> analyzeImageWithFallback(File imageFile, {String? userNote}) async {
    // Try real API first
    final result = await analyzeImage(imageFile, userNote: userNote);
    
    // If API is not configured or fails, use mock data with user note
    if (!result.success && !GeminiConfig.isConfigured) {
      return createMockAnalysisResult(userNote: userNote);
    }
    
    return result;
  }

  /// Validate image file before analysis
  static bool isValidImageFile(File imageFile) {
    final String extension = imageFile.path.toLowerCase().split('.').last;
    const List<String> supportedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return supportedExtensions.contains(extension);
  }

  /// Get maximum file size allowed (20MB for Gemini)
  static const int maxFileSizeBytes = 20 * 1024 * 1024;

  /// Check if image file size is within limits
  static Future<bool> isValidFileSize(File imageFile) async {
    try {
      final int fileSize = await imageFile.length();
      return fileSize <= maxFileSizeBytes;
    } catch (e) {
      return false;
    }
  }

  /// Validate image file completely
  static Future<String?> validateImageFile(File imageFile) async {
    // Check if file exists
    if (!await imageFile.exists()) {
      return 'Image file does not exist';
    }

    // Check file extension
    if (!isValidImageFile(imageFile)) {
      return 'Unsupported image format. Please use JPG, PNG, GIF, BMP, or WebP.';
    }

    // Check file size
    if (!await isValidFileSize(imageFile)) {
      return 'Image file too large. Maximum size is ${maxFileSizeBytes ~/ (1024 * 1024)}MB.';
    }

    return null; // Valid
  }
}