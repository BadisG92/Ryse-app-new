# Modification du bouton d'édition des aliments

## Problème résolu

Dans la partie nutrition du journal, lors de l'ajout d'un aliment via photo avec l'IA, quand on clique sur le stylo pour modifier les caractéristiques d'un aliment, le bouton "Valider" :

1. **Avant** : S'appelait "Valider"/"Confirmer" et ajoutait directement l'aliment au repas
2. **Après** : S'appelle maintenant "Enregistrer" et sauvegarde seulement les modifications sans ajouter au repas

## Changements effectués

### 1. EditableFoodDetailsBottomSheet.dart
- Ajout d'un nouveau paramètre `onFoodSaved` pour différencier l'enregistrement de l'ajout
- Modification de la logique du bouton pour utiliser `onFoodSaved` quand disponible
- Changement du texte du bouton : "Enregistrer" quand `onFoodSaved` est fourni

### 2. ai_scanner_screen.dart
- Modification de `_editDetectedFood()` pour utiliser `onFoodSaved` au lieu de `onFoodAdded`
- L'aliment est maintenant seulement enregistré, pas ajouté au repas
- L'ajout se fait uniquement via le bouton "Ajouter tous les aliments"

### 3. recipe_details_screen.dart
- Modification de `_editIngredient()` pour utiliser `onFoodSaved` au lieu de `onFoodAdded`
- L'ingrédient est maintenant seulement enregistré dans la recette, pas ajouté au repas
- L'ajout se fait uniquement via le bouton "Ajouter au repas" de la recette complète

## Flux de fonctionnement

### Scanner IA - Modification d'aliment
1. Utilisateur prend une photo → aliments détectés
2. Clic sur le stylo → bottom sheet d'édition s'ouvre
3. Modification des caractéristiques → clic sur "Enregistrer"
4. **Résultat** : Aliment enregistré avec modifications, PAS ajouté au repas
5. Pour ajouter : utilisateur doit cliquer sur "Ajouter tous les aliments"

### Recette - Modification d'ingrédient  
1. Utilisateur sélectionne une recette → voir les détails
2. Clic sur "Modifier les aliments" → écran d'édition des ingrédients
3. Clic sur le stylo d'un ingrédient → bottom sheet d'édition s'ouvre
4. Modification des caractéristiques → clic sur "Enregistrer"
5. **Résultat** : Ingrédient enregistré avec modifications dans la recette, PAS ajouté au repas
6. Pour ajouter : utilisateur doit cliquer sur "Ajouter au repas" de la recette complète

### Actions rapides Dashboard - Ajout manuel (NOUVEAU FIX ✅)
1. Clic sur bouton "Saisie manuelle" → bottom sheet de recherche s'ouvre
2. Sélection d'un aliment → **page d'informations sur l'aliment s'affiche** ✅
3. Modification éventuelle des caractéristiques → clic sur "Ajouter"  
4. **Maintenant** : Sélection de repas s'affiche (existant ou nouveau)
5. **Avant** : Sautait directement à l'étape 4 en bypassant la page d'infos ❌

#### Modifications effectuées pour ce fix :
- **manual_food_search_bottom_sheet.dart** : Suppression de la logique spéciale `isFromDashboard`
- **nutrition_widgets.dart** : Ajout de `_handleDashboardFoodSelectionFromDetails()`
- **Flux uniformisé** : Tous les aliments passent maintenant par la page d'informations

### Autres flux (inchangés)
- Création d'aliment : bouton "Créer" → crée et ajoute directement

## Compatibilité

Les autres utilisations d'`EditableFoodDetailsBottomSheet` restent inchangées car elles n'utilisent pas le nouveau paramètre `onFoodSaved`. 