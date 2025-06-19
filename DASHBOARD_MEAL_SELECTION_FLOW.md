# Flux d'Ajout d'Aliments depuis le Dashboard

## Vue d'ensemble

Ce document décrit les nouveaux flux pour l'ajout d'aliments depuis les boutons rapides du tableau de bord nutrition. L'objectif était de remettre l'étape de sélection de repas qui avait été supprimée tout en distinguant les différents types d'ajout.

## Distinction des Flux

### 1. Flux Journal (Existant)
- **Point d'entrée** : Bouton "+" dans un repas spécifique du journal
- **Comportement** : Le repas est déjà sélectionné, va directement à la recherche d'aliments
- **Validation** : L'aliment est ajouté au repas pré-sélectionné

### 2. Flux Dashboard - Recherche Manuelle (Nouveau)
- **Point d'entrée** : Bouton "Saisie manuelle" des actions rapides du dashboard
- **Comportement** : Sélection de repas PUIS recherche d'aliments
- **Validation** : L'aliment trouvé est ajouté au repas sélectionné

### 3. Flux Dashboard - Aliments Détectés (Nouveau)
- **Point d'entrée** : Boutons "Scanner IA", "Code-barres" des actions rapides du dashboard
- **Comportement** : Détection d'aliment PUIS sélection de repas PUIS confirmation
- **Validation** : L'aliment détecté est ajouté au repas sélectionné

## Étapes des Flux Dashboard

### Flux A : Recherche Manuelle

**Étape 1** : Sélection Type de Repas
- Question : "Voulez-vous ajouter à un repas existant ou créer un nouveau repas ?"
- Options : Repas existant / Nouveau repas

**Étape 2A** : Sélection Repas Existant
- Affichage : Liste des repas du jour
- Sélection : Tap sur un repas → Étape 3

**Étape 2B** : Création Nouveau Repas
- Sélection type : Petit-déjeuner, Déjeuner, etc. → Étape 3

**Étape 3** : Recherche d'Aliments
- Interface : `ManualFoodSearchBottomSheet` avec suggestions fréquentes
- Sélection : Tap sur un aliment → Étape 4

**Étape 4** : Détails de l'Aliment
- Interface : `EditableFoodDetailsBottomSheet` pour ajuster quantités
- Validation : Ajout au repas pré-sélectionné

### Flux B : Aliments Détectés

**Étape 1** : Détection d'Aliment
- Scanner IA : Photo → Analyse → Aliments détectés
- Code-barres : Scan → Recherche produit → Aliment identifié

**Étape 2** : Sélection Repas pour Aliment Détecté
- Question : "À quel repas voulez-vous ajouter [NOM_ALIMENT] ?"
- Options : Repas existant / Nouveau repas

**Étape 3A/3B** : Même logique que Flux A pour sélection repas

**Étape 4** : Ajout Direct
- L'aliment détecté est ajouté directement au repas sélectionné
- Pas de passage par `EditableFoodDetailsBottomSheet`

## Implémentation Technique

### Méthodes Principales

```dart
// Flux recherche manuelle
NutritionQuickActionsSection.showMealSelectionForDashboard(context)

// Flux aliments détectés
NutritionQuickActionsSection.showMealSelectionWithDetectedFood(context, foodItem)

// Méthodes internes communes
static void _showMealSelectionFirst(context)                    // Étape 1 - Manuel
static void _showMealSelectionForDetectedFood(context, food)    // Étape 2 - Détecté
static void _showExistingMealsSelection(context, meals)         // Étape 2A - Manuel
static void _showExistingMealsSelectionForDetectedFood(...)     // Étape 3A - Détecté
static void _showNewMealTypeSelection(context)                  // Étape 2B - Manuel  
static void _showNewMealTypeSelectionForDetectedFood(...)       // Étape 3B - Détecté
static void _showManualFoodSearchForMeal(context, meal)         // Étape 3 - Manuel
static void _addFoodToSelectedMeal(context, food, meal)         // Étape 4 - Final
```

### Architecture des Fichiers

**Fichiers modifiés** :
- `nutrition_widgets.dart` : Deux flux complets statiques
- `nutrition_dashboard_hybrid.dart` : Utilise flux manuel
- `ai_scanner_screen.dart` : Utilise flux détecté  
- `barcode_scanner_screen.dart` : Utilise flux détecté
- `manual_food_search_bottom_sheet.dart` : Simplifié (callback seul)

### Détails d'Implémentation

**Gestion des types d'aliments** :
- Recherche manuelle → Choix d'aliment → Sélection repas → Détails
- Scanner/Code-barres → Aliment détecté → Sélection repas → Ajout direct

**Navigation et contexte** :
- Vérification `context.mounted` à chaque étape
- `Future.delayed()` pour éviter conflits de navigation
- `Navigator.pop()` puis nouvelle navigation

**Données temporaires** :
- Repas simulés (TODO: récupération BDD)
- Transmission d'aliment détecté via paramètres
- Pas de stockage d'état global

## Prochaines Étapes

### TODO : Intégration Base de Données
1. Récupérer les vrais repas du jour depuis la BDD
2. Implémenter l'ajout réel d'aliments aux repas  
3. Rafraîchir le dashboard après ajout
4. Gestion des erreurs de sauvegarde

### TODO : Autres Fonctionnalités
1. Appliquer le flux détecté aux recettes
2. Gestion des aliments multiples (scanner IA)
3. Edition des aliments détectés avant ajout
4. Historique des ajouts depuis dashboard

### TODO : Optimisations
- Cache des repas du jour
- Animations de transition entre étapes
- Préchargement des données fréquentes
- Tests automatisés des flux 