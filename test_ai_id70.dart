import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() async {
  print('🤖 Test IA Gemini - Image ID 70');
  print('=================================');
  
  const geminiApiKey = 'AIzaSyDCdJLXaVF68RsJkmHTPlnMoJvqbxOSxac';
  const geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // Chemin vers l'image ID 70
  const imagePath = r'C:\rise app v2\id 70.jpeg';
  
  try {
    print('\n📥 Chargement de l\'image ID 70...');
    final imageFile = File(imagePath);
    
    if (!await imageFile.exists()) {
      print('❌ Image non trouvée à : $imagePath');
      return;
    }
    
    final imageBytes = await imageFile.readAsBytes();
    print('✅ Image chargée: ${imageBytes.length} bytes');
    
    // Encoder en base64
    final base64Image = base64Encode(imageBytes);
    print('🔄 Image encodée: ${base64Image.length} caractères');
    
    // Prompt détaillé pour analyse nutritionnelle
    const prompt = '''
Analysez cette image de nourriture et fournissez une réponse JSON détaillée en français:

{
  "foods": [
    {
      "name": "Nom de l'aliment en français",
      "confidence": 85,
      "portion_grams": 120,
      "nutrition": {
        "proteins_g": 15.2,
        "carbs_g": 25.8,
        "fats_g": 8.1
      },
      "description": "Description détaillée de ce que vous voyez"
    }
  ]
}

Exigences:
1. Estimez les portions en grammes selon les indices visuels (taille d'assiette, volume, portions typiques)
2. Fournissez les valeurs nutritionnelles en grammes pour la portion estimée que vous voyez
3. Utilisez des scores de confiance de 0-100 selon la clarté d'identification
4. Nommez les aliments en français si possible
5. Incluez seulement les aliments clairement visibles et identifiables
6. Si vous voyez plusieurs éléments similaires, combinez-les en une entrée
7. Soyez réaliste avec les estimations de portions selon ce que vous voyez réellement
8. Ajoutez une description détaillée pour expliquer ce que vous identifiez

Analysez soigneusement cette image et donnez votre meilleure estimation nutritionnelle.
''';

    print('\n🔍 Envoi à l\'API Gemini pour analyse...');
    
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
      final candidates = jsonResponse['candidates'] as List?;
      
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        final textResponse = parts[0]['text'] as String;
        
        print('\n🤖 Réponse brute de l\'IA:');
        print('=' * 50);
        print(textResponse);
        print('=' * 50);
        
        // Tentative de parsing JSON dans la réponse
        try {
          final jsonStart = textResponse.indexOf('{');
          final jsonEnd = textResponse.lastIndexOf('}') + 1;
          
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = textResponse.substring(jsonStart, jsonEnd);
            final parsedResponse = json.decode(jsonString);
            
            print('\n🍽️ ANALYSE NUTRITIONNELLE - IMAGE ID 70:');
            print('=' * 60);
            
            final foods = parsedResponse['foods'] as List;
            
            double totalCalories = 0;
            double totalProteins = 0;
            double totalCarbs = 0;
            double totalFats = 0;
            double totalWeight = 0;
            
            for (int i = 0; i < foods.length; i++) {
              final food = foods[i];
              final proteins = (food['nutrition']['proteins_g'] as num).toDouble();
              final carbs = (food['nutrition']['carbs_g'] as num).toDouble();
              final fats = (food['nutrition']['fats_g'] as num).toDouble();
              final weight = (food['portion_grams'] as num).toDouble();
              
              // Calcul calories (4 kcal/g protéines et glucides, 9 kcal/g lipides)
              final calories = (proteins * 4) + (carbs * 4) + (fats * 9);
              
              print('\n🥘 ${i + 1}. ${food['name']}');
              print('   📏 Portion estimée: ${weight.round()}g');
              print('   🔥 Calories: ${calories.round()} kcal');
              print('   🥩 Protéines: ${proteins.toStringAsFixed(1)}g');
              print('   🍞 Glucides: ${carbs.toStringAsFixed(1)}g');
              print('   🥑 Lipides: ${fats.toStringAsFixed(1)}g');
              print('   📈 Confiance: ${food['confidence']}%');
              if (food['description'] != null) {
                print('   💬 Description: ${food['description']}');
              }
              
              totalCalories += calories;
              totalProteins += proteins;
              totalCarbs += carbs;
              totalFats += fats;
              totalWeight += weight;
            }
            
            print('\n📊 TOTAUX DU REPAS ANALYSÉ:');
            print('=' * 40);
            print('🍽️  Poids total estimé: ${totalWeight.round()}g');
            print('🔥  Calories totales: ${totalCalories.round()} kcal');
            print('🥩  Protéines totales: ${totalProteins.toStringAsFixed(1)}g');
            print('🍞  Glucides totaux: ${totalCarbs.toStringAsFixed(1)}g');
            print('🥑  Lipides totaux: ${totalFats.toStringAsFixed(1)}g');
            
            // Calcul des macros en pourcentage
            final proteinPercent = (totalProteins * 4 / totalCalories * 100);
            final carbPercent = (totalCarbs * 4 / totalCalories * 100);
            final fatPercent = (totalFats * 9 / totalCalories * 100);
            
            print('\n📈 RÉPARTITION DES MACRONUTRIMENTS:');
            print('🥩  Protéines: ${proteinPercent.toStringAsFixed(1)}%');
            print('🍞  Glucides: ${carbPercent.toStringAsFixed(1)}%');
            print('🥑  Lipides: ${fatPercent.toStringAsFixed(1)}%');
            
          } else {
            print('⚠️  Aucun JSON trouvé dans la réponse');
          }
        } catch (e) {
          print('❌ Erreur parsing JSON: $e');
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
  print('\n💡 Cette analyse peut maintenant être utilisée pour:');
  print('   - Ajouter automatiquement au journal alimentaire');
  print('   - Comparer avec les objectifs nutritionnels');
  print('   - Suivre les macronutriments quotidiens');
}