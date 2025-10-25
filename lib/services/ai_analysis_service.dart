import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../config/google_vision_config.dart';
import '../models/ai_analysis_models.dart';
import 'location_service.dart';

class AIAnalysisService {
  
  /// Resize image to optimize for Vision API (max 1024x1024)
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

  /// Analyze an image file for food detection using Google Vision API
  static Future<AIAnalysisResult> analyzeImage(File imageFile) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Check if Google Vision is configured
      if (!GoogleVisionConfig.isConfigured) {
        return AIAnalysisResult.error(
          error: 'Google Vision API not configured. Please set your API key and project ID.',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      // Convert and resize image to base64
      final Uint8List originalBytes = await imageFile.readAsBytes();
      final Uint8List resizedBytes = await _resizeImage(originalBytes);
      final String base64Image = base64Encode(resizedBytes);

      // Get user's country for cultural context
      final cultureContext = await LocationService.getFoodCultureContext();
      
      // Create custom prompt for food analysis
      final customPrompt = '''
Analyze this food image taken in a region with $cultureContext.

For each food item you identify, please provide:
1. Food name (recognize local dishes if visible)
2. Estimated portion size in grams based on what you see in the image (visual estimation)
3. Nutritional values per portion in grams: proteins, carbohydrates, fats
4. Confidence level (0-100%)

Focus on identifying what is actually visible in the image. 
Estimate portions based on visual cues like plate size, food volume, and typical serving sizes you can observe.
The cultural context is just additional information to help recognize local dishes.
''';

      // Prepare the API request with cultural context and custom prompt
      final Map<String, dynamic> requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'LABEL_DETECTION',
                'maxResults': GoogleVisionConfig.maxResults,
              },
              {
                'type': 'TEXT_DETECTION',
                'maxResults': 5, // Pour détecter le texte des menus/étiquettes
              },
            ],
            'imageContext': {
              'textDetectionParams': {
                'enableTextDetectionConfidenceScore': true,
              },
            },
          }
        ],
        // Note: Le prompt personnalisé sera utilisé dans le post-processing
        'customContext': {
          'culturalContext': cultureContext,
          'analysisPrompt': customPrompt,
        },
      };

      // Remove custom context before sending (not supported by Vision API)
      final apiRequestBody = Map<String, dynamic>.from(requestBody);
      apiRequestBody.remove('customContext');
      
      // Make the API call
      final response = await http.post(
        Uri.parse(GoogleVisionConfig.fullApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(apiRequestBody),
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        return _processVisionResponse(
          response.body, 
          stopwatch.elapsedMilliseconds / 1000.0,
          cultureContext, // Pass cultural context to processing
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

  /// Process the Google Vision API response
  static AIAnalysisResult _processVisionResponse(
    String responseBody, 
    double processingTime,
    String cultureContext,
  ) {
    try {
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);
      final List<dynamic> responses = jsonResponse['responses'] ?? [];
      
      if (responses.isEmpty) {
        return AIAnalysisResult.error(
          error: 'No response from Vision API',
          processingTime: processingTime,
        );
      }

      final firstResponse = responses[0];
      final visionResponse = GoogleVisionResponse.fromJson(firstResponse);

      // Check for API errors
      if (visionResponse.error != null) {
        return AIAnalysisResult.error(
          error: 'Vision API Error: ${visionResponse.error!.message}',
          processingTime: processingTime,
        );
      }

      // Combine all annotations
      final List<GoogleVisionAnnotation> allAnnotations = [
        ...visionResponse.labelAnnotations,
        ...visionResponse.localizedObjectAnnotations,
      ];

      // Filter for food-related labels with cultural context
      final List<DetectedFood> detectedFoods = _filterAndProcessFoodLabels(
        allAnnotations, 
        cultureContext,
      );

      return AIAnalysisResult.success(
        detectedFoods: detectedFoods,
        processingTime: processingTime,
      );

    } catch (e) {
      return AIAnalysisResult.error(
        error: 'Failed to process API response: $e',
        processingTime: processingTime,
      );
    }
  }

  /// Filter annotations for food-related content and convert to DetectedFood
  static List<DetectedFood> _filterAndProcessFoodLabels(
    List<GoogleVisionAnnotation> annotations,
    String cultureContext,
  ) {
    final List<DetectedFood> detectedFoods = [];
    final Set<String> processedLabels = {}; // To avoid duplicates

    for (final annotation in annotations) {
      final String label = annotation.description.toLowerCase();
      final double confidence = annotation.score;

      // Check if confidence meets threshold
      if (confidence < GoogleVisionConfig.confidenceThreshold) {
        continue;
      }

      // Check if it's food-related
      final bool isFoodRelated = GoogleVisionConfig.foodKeywords.any(
        (keyword) => label.contains(keyword),
      );

      if (isFoodRelated && !processedLabels.contains(label)) {
        processedLabels.add(label);
        
        try {
          final detectedFood = DetectedFood.fromVisionLabel(
            label: annotation.description,
            confidence: confidence,
            cultureContext: cultureContext, // Pass cultural context
          );
          detectedFoods.add(detectedFood);
        } catch (e) {
          debugPrint('Error processing food label ${annotation.description}: $e');
          continue;
        }
      }
    }

    // Sort by confidence (highest first)
    detectedFoods.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Limit to reasonable number of results
    return detectedFoods.take(5).toList();
  }

  /// Analyze image with fallback to mock data for development
  static Future<AIAnalysisResult> analyzeImageWithFallback(File imageFile) async {
    // Try real API first
    final result = await analyzeImage(imageFile);
    
    // If API is not configured or fails, use mock data
    if (!result.success && !GoogleVisionConfig.isConfigured) {
      return _createMockAnalysisResult();
    }
    
    return result;
  }

  /// Create mock analysis result for development/testing
  static AIAnalysisResult _createMockAnalysisResult() {
    final List<DetectedFood> mockFoods = [
      DetectedFood.fromVisionLabel(
        label: 'Grilled salmon', 
        confidence: 0.95,
        cultureContext: 'French cuisine and portion sizes',
      ),
      DetectedFood.fromVisionLabel(
        label: 'Basmati rice', 
        confidence: 0.88,
        cultureContext: 'French cuisine and portion sizes',
      ),
      DetectedFood.fromVisionLabel(
        label: 'Broccoli', 
        confidence: 0.92,
        cultureContext: 'French cuisine and portion sizes',
      ),
    ];

    return AIAnalysisResult.success(
      detectedFoods: mockFoods,
      processingTime: 2.5, // Mock processing time
    );
  }

  /// Validate image file before analysis
  static bool isValidImageFile(File imageFile) {
    final String extension = imageFile.path.toLowerCase().split('.').last;
    const List<String> supportedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return supportedExtensions.contains(extension);
  }

  /// Get maximum file size allowed (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

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