import 'translation_checker.dart';

void main() {
  print("=== TEST DU VÉRIFICATEUR DE TRADUCTIONS ===\n");

  // Test 1: Texte existant
  print("TEST 1 - Texte qui existe déjà:");
  var result1 = TranslationChecker.findExistingTranslation(
    frenchText: "Annuler",
    englishText: "Cancel",
  );
  print(result1);
  print("");

  // Test 2: Texte nouveau
  print("TEST 2 - Nouveau texte:");
  var result2 = TranslationChecker.findExistingTranslation(
    frenchText: "Réinitialiser les paramètres",
    englishText: "Reset settings",
    context: "settings",
  );
  print(result2);
  print("");

  // Test 3: Texte similaire
  print("TEST 3 - Texte similaire à existant:");
  var result3 = TranslationChecker.findExistingTranslation(
    frenchText: "Terminer la séance",
    englishText: "End session",
  );
  print(result3);
  print("");

  // Test 4: Recherche par mot-clé
  print("TEST 4 - Recherche de clés contenant 'workout':");
  var workoutKeys = TranslationChecker.findKeysByKeyword("workout");
  print("Trouvé ${workoutKeys.length} clés:");
  for (String key in workoutKeys.take(5)) { // Afficher seulement les 5 premières
    print("  - $key");
  }
  if (workoutKeys.length > 5) {
    print("  ... et ${workoutKeys.length - 5} autres");
  }
  print("");

  print("=== MÉTHODE D'UTILISATION ===");
  print("1. Avant d'ajouter une traduction, lancez:");
  print("   TranslationChecker.findExistingTranslation(frenchText: '...', englishText: '...')");
  print("2. Si hasExisting = true → utilisez la clé existante");
  print("3. Si hasExisting = false → ajoutez avec la suggestedKey");
}