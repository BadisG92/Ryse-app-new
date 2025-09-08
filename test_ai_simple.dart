import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🤖 Test simple de l\'IA Gemini');
  print('==================================');
  
  // Configuration directe
  const geminiApiKey = 'AIzaSyDCdJLXaVF68RsJkmHTPlnMoJvqbxOSxac';
  const geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // Test avec image URL depuis la base recipes_database
  print('\n🍽️ Test d\'analyse d\'une recette de la base de données:');
  print('URL de test: https://images.unsplash.com/photo-1546833999-b9f581a1996d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80');
  
  // Prompt simple pour analyse
  const prompt = '''
Analyze this food image and provide a JSON response with the following structure:

{
  "foods": [
    {
      "name": "Food name",
      "confidence": 85,
      "portion_grams": 120,
      "nutrition": {
        "proteins_g": 15.2,
        "carbs_g": 25.8,
        "fats_g": 8.1
      }
    }
  ]
}

Focus on identifying the main food items and estimating portion sizes based on visual cues.
''';

  try {
    // Préparer la requête API
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
                'data': '', // Vide pour ce test simple
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
    };

    print('\n🔧 Test de configuration API...');
    final response = await http.post(
      Uri.parse('$geminiApiUrl?key=$geminiApiKey'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(requestBody),
    );

    print('📡 Statut de réponse: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ Configuration API valide');
      final jsonResponse = json.decode(response.body);
      print('📊 Réponse reçue: ${jsonResponse.toString().substring(0, 200)}...');
    } else {
      print('❌ Erreur API: ${response.statusCode}');
      print('Détails: ${response.body}');
    }

  } catch (e) {
    print('❌ Exception: $e');
  }

  // Test des données mockées
  print('\n🔄 Test des données mockées:');
  final mockFoods = [
    {
      'name': 'Salade composée',
      'confidence': 0.92,
      'portion_grams': 150.0,
      'proteins': 8.5,
      'carbs': 12.3,
      'fats': 6.8,
    },
    {
      'name': 'Pain complet',
      'confidence': 0.88,
      'portion_grams': 50.0,
      'proteins': 4.2,
      'carbs': 24.1,
      'fats': 1.5,
    },
  ];

  print('🍽️ Aliments mockés détectés: ${mockFoods.length}');
  for (int i = 0; i < mockFoods.length; i++) {
    final food = mockFoods[i];
    print('  ${i + 1}. ${food['name']}');
    print('     📏 Portion: ${food['portion_grams']}g');
    print('     🥩 Protéines: ${food['proteins']}g');
    print('     🍞 Glucides: ${food['carbs']}g');
    print('     🥑 Lipides: ${food['fats']}g');
    print('     📈 Confiance: ${((food['confidence'] as double) * 100).round()}%');
    print('');
  }

  print('✅ Test simple terminé!');
  print('\n💡 Pour tester avec une vraie image:');
  print('1. Remplacez le champ "data" par une image encodée en base64');
  print('2. Utilisez une image de recette depuis la base de données');
  print('3. Comparez les résultats avec les valeurs nutritionnelles stockées');
}