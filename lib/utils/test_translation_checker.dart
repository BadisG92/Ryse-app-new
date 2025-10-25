import 'package:flutter/foundation.dart';
import 'translation_checker.dart';

void main() {
  debugPrint("=== TEST DU VÉRIFICATEUR DE TRADUCTIONS ===\n");

  // Test 1: Texte existant
  debugPrint("TEST 1 - Texte qui existe déjà:");
  var result1 = TranslationChecker.findExistingTranslation(
    frenchText: "Annuler",
    englishText: "Cancel",
  );
  debugPrint(result1.toString());
  debugPrint("");

  // Test 2: Texte nouveau
  debugPrint("TEST 2 - Nouveau texte:");
  var result2 = TranslationChecker.findExistingTranslation(
    frenchText: "Réinitialiser les paramètres",
    englishText: "Reset settings",
    context: "settings",
  );
  debugPrint(result2.toString());
  debugPrint("");

  // Test 3: Texte similaire
  debugPrint("TEST 3 - Texte similaire à existant:");
  var result3 = TranslationChecker.findExistingTranslation(
    frenchText: "Terminer la séance",
    englishText: "End session",
  );
  debugPrint(result3.toString());
  debugPrint("");

  // Test 4: Recherche par mot-clé
  debugPrint("TEST 4 - Recherche de clés contenant 'workout':");
  var workoutKeys = TranslationChecker.findKeysByKeyword("workout");
  debugPrint("Trouvé ${workoutKeys.length} clés:");
  for (String key in workoutKeys.take(5)) { // Afficher seulement les 5 premières
    debugPrint("  - $key");
  }
  if (workoutKeys.length > 5) {
    debugPrint("  ... et ${workoutKeys.length - 5} autres");
  }
  debugPrint("");

  debugPrint("=== MÉTHODE D'UTILISATION ===");
  debugPrint("1. Avant d'ajouter une traduction, lancez:");
  debugPrint("   TranslationChecker.findExistingTranslation(frenchText: '...', englishText: '...')");
  debugPrint("2. Si hasExisting = true → utilisez la clé existante");
  debugPrint("3. Si hasExisting = false → ajoutez avec la suggestedKey");
}