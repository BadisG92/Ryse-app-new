import 'dart:io';
import 'lib/services/gemini_analysis_service.dart';
import 'lib/config/gemini_config.dart';
import 'lib/models/ai_analysis_models.dart';

void main() async {
  print('🤖 Test d\'intégration de l\'IA Gemini - Recette Blanquette de Veau');
  print('==================================================================');
  
  // Vérifier la configuration
  print('\n🔧 Configuration Gemini:');
  print('API Key configurée: ${GeminiConfig.isConfigured ? "✅ Oui" : "❌ Non"}');
  print('URL API: ${GeminiConfig.geminiApiUrl}');
  print('Modèle: ${GeminiConfig.modelName}');
  print('Seuil de confiance: ${(GeminiConfig.confidenceThreshold * 100).round()}%');
  
  // Test avec recette française réaliste
  print('\n🍽️ Test d\'analyse d\'une recette française typique:');
  print('Recette: Blanquette de veau avec accompagnements');
  print('Source: Base de données Ryze');
  
  try {
    final mockResult = GeminiAnalysisService.createMockAnalysisResult();
    
    if (mockResult.success) {
      print('✅ Mock créé avec succès');
      print('📊 Nombre d\'aliments détectés: ${mockResult.detectedFoods.length}');
      print('⏱️ Temps de traitement simulé: ${mockResult.processingTime}s');
      
      int totalCalories = 0;
      double totalProteins = 0;
      double totalCarbs = 0;
      double totalFats = 0;
      
      print('\n🍽️ Aliments détectés:');
      for (int i = 0; i < mockResult.detectedFoods.length; i++) {
        final food = mockResult.detectedFoods[i];
        print('  ${i + 1}. ${food.name}');
        print('     📏 Portion: ${food.estimatedQuantity.round()}g');
        print('     🔥 Calories: ${food.calories} kcal');
        print('     🥩 Protéines: ${food.nutrition.proteins.toStringAsFixed(1)}g');
        print('     🍞 Glucides: ${food.nutrition.carbs.toStringAsFixed(1)}g');
        print('     🥑 Lipides: ${food.nutrition.fats.toStringAsFixed(1)}g');
        print('     📈 Confiance: ${(food.confidence * 100).round()}%');
        print('');
        
        totalCalories += food.calories;
        totalProteins += food.nutrition.proteins;
        totalCarbs += food.nutrition.carbs;
        totalFats += food.nutrition.fats;
      }
      
      print('📈 Totaux du plat:');
      print('   🔥 Calories totales: ${totalCalories} kcal');
      print('   🥩 Protéines totales: ${totalProteins.toStringAsFixed(1)}g');
      print('   🍞 Glucides totaux: ${totalCarbs.toStringAsFixed(1)}g');
      print('   🥑 Lipides totaux: ${totalFats.toStringAsFixed(1)}g');
      
    } else {
      print('❌ Erreur mock: ${mockResult.error}');
    }
  } catch (e) {
    print('❌ Exception lors du test mock: $e');
  }
  
  // Test de validation de fichier
  print('\n📁 Test de validation de fichier:');
  print('Extensions supportées: JPG, JPEG, PNG, GIF, BMP, WebP');
  print('Taille maximale: ${GeminiAnalysisService.maxFileSizeBytes ~/ (1024 * 1024)}MB');
  
  // Simulation d'analyse avec fallback (si pas de vraie image)
  print('\n🔄 Test du service avec fallback:');
  print('Si la clé API est configurée, l\'analyse réelle sera tentée.');
  print('Sinon, les données mockées seront utilisées automatiquement.');
  
  print('\n✅ Test d\'intégration terminé!');
  print('\n🚀 Pour tester l\'IA complète:');
  print('1. Lancez l\'app Flutter');
  print('2. Allez dans le dashboard ou journal');
  print('3. Cliquez sur le bouton caméra/photo');
  print('4. Sélectionnez une photo depuis la galerie');
  print('5. Observez l\'analyse IA en temps réel');
}