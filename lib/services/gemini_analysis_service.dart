import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../config/gemini_config.dart';
import '../models/ai_analysis_models.dart';
import 'location_service.dart';

class GeminiAnalysisService {
  
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
      debugPrint('Error resizing image: $e');
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
      
      // Create detailed prompt for food analysis
      final prompt = '''
Analyze this food image taken in $countryName ($cultureContext region).

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
2. Estimate portion sizes based on visual cues in the image (plate size, food volume, typical serving sizes you can observe)
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
      
      // Create detailed prompt for food analysis
      final prompt = '''
Analyze this food image taken in $countryName ($cultureContext region).

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
2. Estimate portion sizes based on visual cues in the image (plate size, food volume, typical serving sizes you can observe)
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
        mealName = parsedJson['meal_name'] ?? 'Plat détecté par IA';
        
        final List<dynamic> foods = parsedJson['foods'] ?? [];
        
        for (final foodData in foods) {
          try {
            final detectedFood = DetectedFood.fromAIResponse(
              name: foodData['name'] ?? 'Unknown food',
              confidence: (foodData['confidence'] ?? 50).toDouble() / 100.0,
              portionGrams: (foodData['portion_grams'] ?? 100).toDouble(),
              proteins: (foodData['nutrition']['proteins_g'] ?? 0).toDouble(),
              carbs: (foodData['nutrition']['carbs_g'] ?? 0).toDouble(),
              fats: (foodData['nutrition']['fats_g'] ?? 0).toDouble(),
            );
            
            // Only include foods with reasonable confidence
            if (detectedFood.confidence >= GeminiConfig.confidenceThreshold) {
              detectedFoods.add(detectedFood);
            }
          } catch (e) {
            debugPrint('Error parsing food item: $e');
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing Gemini response: $e');
      // Fallback: try to extract food names from text response
      final fallbackFoods = _extractFoodsFromText(textResponse);
      return {
        'foods': fallbackFoods,
        'mealName': 'Plat détecté par IA',
      };
    }
    
    return {
      'foods': detectedFoods.take(5).toList(), // Limit to 5 items
      'mealName': mealName ?? 'Plat détecté par IA',
    };
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

  /// Create mock analysis result for development/testing
  static AIAnalysisResult createMockAnalysisResult() {
    final List<DetectedFood> mockFoods = [
      DetectedFood.fromAIResponse(
        name: 'Blanquette de veau',
        confidence: 0.93,
        portionGrams: 200.0,
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

    return AIAnalysisResult.success(
      detectedFoods: mockFoods,
      processingTime: 2.5,
    );
  }

  /// Analyze image with fallback to mock data for development
  static Future<AIAnalysisResult> analyzeImageWithFallback(File imageFile) async {
    // Try real API first
    final result = await analyzeImage(imageFile);
    
    // If API is not configured or fails, use mock data
    if (!result.success && !GeminiConfig.isConfigured) {
      return createMockAnalysisResult();
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