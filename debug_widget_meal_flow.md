# 🔍 Debug du flux de sélection de repas depuis le widget

## Flux actuel (théorique) :

1. **Widget iOS** → Flutter : `ryse://add-food?meal=dejeuner`
2. **Handler** (`widget_deep_link_handler.dart`) :
   - Reçoit `mealType = "dejeuner"`
   - Transforme via `_getMealName("dejeuner")` → `"Déjeuner"`
   - Passe `"Déjeuner"` à `showAddFoodOptionsForNewMeal()`
3. **NutritionQuickActionsSection** :
   - Reçoit `mealType = "Déjeuner"`
   - Passe à `generateMealId(mealName: "Déjeuner")`
4. **FoodEntriesService** :
   - Cherche `"Déjeuner"` dans `_mealTypeMapping`
   - Trouve `"Déjeuner" → "lunch"`
   - Génère le meal_id

## Points de debug à vérifier :

```dart
// Dans widget_deep_link_handler.dart
debugPrint('🔗 Deep link reçu: ${uri.toString()}');
debugPrint('   - meal: $mealType'); // Devrait afficher "dejeuner"
debugPrint('   - mealName après transformation: $mealName'); // Devrait afficher "Déjeuner"

// Dans _showAddFoodOptionsForNewMeal
debugPrint('📝 showAddFoodOptionsForNewMeal reçu: $mealType'); // Devrait afficher "Déjeuner"

// Dans generateMealId
debugPrint('🔑 generateMealId reçu mealName: $mealName'); // Devrait afficher "Déjeuner"
```

## Hypothèses sur l'erreur :

L'erreur "Type de repas non reconnu: dejeuner (base: meal_1762808338967)" pourrait venir de :

1. **Un repas existant mal formaté** :
   - Le meal_id existe déjà avec le type "dejeuner" au lieu de "lunch" en base
   - Quand on essaie d'ajouter à ce repas, le système ne reconnaît pas le type

2. **Un autre flux** :
   - Peut-être que l'erreur vient du flux "chat" spécifiquement
   - Ou d'un autre endroit qui n'utilise pas `_getMealName()`

3. **Un problème de timing** :
   - Le repas est créé avec le mauvais type
   - Puis on essaie de l'utiliser

## Tests à effectuer :

1. **Test 1 : Petit-déjeuner**
   - Cliquer sur "Petit-déj." dans le widget
   - Vérifier si l'erreur apparaît aussi ou seulement pour "Déjeuner"

2. **Test 2 : Dîner**
   - Cliquer sur "Dîner" dans le widget
   - Vérifier le mapping (avec accent circonflexe)

3. **Test 3 : Vérifier en base de données**
   ```sql
   SELECT meal_id, meal_type, meal_name
   FROM food_entries
   WHERE meal_id LIKE 'meal_%'
   AND consumed_at >= CURRENT_DATE
   ORDER BY created_at DESC;
   ```
   Vérifier si des meal_type contiennent "dejeuner" au lieu de "lunch"

## Solution potentielle :

Si le problème est que des repas existants ont le mauvais type, on pourrait :
1. Ajouter une migration pour corriger les types en base
2. Ou ajouter une normalisation dans le code qui gère les anciens formats