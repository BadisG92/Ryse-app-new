import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() async {
  print('🤖 Test de l\'IA Gemini avec image réelle');
  print('==========================================');
  
  const geminiApiKey = 'AIzaSyDCdJLXaVF68RsJkmHTPlnMoJvqbxOSxac';
  const geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // URL d'image de test (salade française)
  const imageUrl = 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';
  
  try {
    print('\n📥 Téléchargement de l\'image de test...');
    final imageResponse = await http.get(Uri.parse(imageUrl));
    
    if (imageResponse.statusCode != 200) {
      print('❌ Erreur téléchargement image: ${imageResponse.statusCode}');
      return;
    }
    
    print('✅ Image téléchargée: ${imageResponse.bodyBytes.length} bytes');
    
    // Encoder en base64
    final base64Image = base64Encode(imageResponse.bodyBytes);
    print('🔄 Image encodée en base64: ${base64Image.length} caractères');
    
    // Prompt pour analyse nutritionnelle (plus flexible)
    const prompt = '''
Analyze this food image and provide a detailed JSON response:

{
  "foods": [
    {
      "name": "Food name in French if possible, otherwise English",
      "confidence": 85,
      "portion_grams": 120,
      "nutrition": {
        "proteins_g": 15.2,
        "carbs_g": 25.8,
        "fats_g": 8.1
      },
      "description": "Brief description"
    }
  ]
}

Requirements:
1. Estimate portion sizes based on visual cues (plate size, volume, typical serving)
2. Provide nutritional values in grams for the estimated portion size you see
3. Use confidence scores 0-100 based on how clearly you can identify each food
4. Only include foods that are clearly visible and identifiable
5. If you see multiple similar items, combine them into one entry
6. Be realistic with portion size estimates based on what you actually see
''';

    print('\n🔍 Envoi à l\'API Gemini...');
    
    final requestBody = {
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
      'generationConfig': {
        'temperature': 0.3,
        'topK': 40,
        'topP': 0.8,
        'maxOutputTokens': 2000,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
      ],
    };

    final response = await http.post(
      Uri.parse('$geminiApiUrl?key=$geminiApiKey'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(requestBody),
    );

    print('📡 Statut réponse: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ Analyse réussie!');
      
      final jsonResponse = json.decode(response.body);
      print('\n📊 Réponse complète:');
      print(json.encode(jsonResponse, toEncodable: (obj) => obj.toString()));
      
      // Extraction du texte de réponse
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        final textResponse = parts[0]['text'] as String;
        
        print('\n🤖 Réponse IA:');
        print(textResponse);
        
        // Tentative de parsing JSON dans la réponse
        try {
          final jsonStart = textResponse.indexOf('{');
          final jsonEnd = textResponse.lastIndexOf('}') + 1;
          
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = textResponse.substring(jsonStart, jsonEnd);
            final parsedResponse = json.decode(jsonString);
            
            print('\n🍽️ Aliments détectés par l\'IA:');
            final foods = parsedResponse['foods'] as List;
            
            double totalCalories = 0;
            double totalProteins = 0;
            double totalCarbs = 0;
            double totalFats = 0;
            
            for (int i = 0; i < foods.length; i++) {
              final food = foods[i];
              final proteins = (food['nutrition']['proteins_g'] as num).toDouble();
              final carbs = (food['nutrition']['carbs_g'] as num).toDouble();
              final fats = (food['nutrition']['fats_g'] as num).toDouble();
              
              // Calcul calories (4 kcal/g protéines et glucides, 9 kcal/g lipides)
              final calories = (proteins * 4) + (carbs * 4) + (fats * 9);
              
              print('  ${i + 1}. ${food['name']}');
              print('     📏 Portion: ${food['portion_grams']}g');
              print('     🔥 Calories: ${calories.round()} kcal');
              print('     🥩 Protéines: ${proteins}g');
              print('     🍞 Glucides: ${carbs}g');
              print('     🥑 Lipides: ${fats}g');
              print('     📈 Confiance: ${food['confidence']}%');
              if (food['description'] != null) {
                print('     💬 Description: ${food['description']}');
              }
              print('');
              
              totalCalories += calories;
              totalProteins += proteins;
              totalCarbs += carbs;
              totalFats += fats;
            }
            
            print('📈 Totaux du plat analysé par IA:');
            print('   🔥 Calories totales: ${totalCalories.round()} kcal');
            print('   🥩 Protéines totales: ${totalProteins.toStringAsFixed(1)}g');
            print('   🍞 Glucides totaux: ${totalCarbs.toStringAsFixed(1)}g');
            print('   🥑 Lipides totaux: ${totalFats.toStringAsFixed(1)}g');
            
          }
        } catch (e) {
          print('⚠️ Erreur parsing JSON: $e');
        }
      }
      
    } else {
      print('❌ Erreur API: ${response.statusCode}');
      print('Détails: ${response.body}');
    }

  } catch (e) {
    print('❌ Exception: $e');
  }
  
  print('\n✅ Test terminé!');
  print('\n💡 Valeurs attendues pour une salade composée typique (150g):');
  print('   🔥 Calories: ~80-120 kcal');
  print('   🥩 Protéines: ~6-10g');
  print('   🍞 Glucides: ~8-15g');
  print('   🥑 Lipides: ~3-8g');
}