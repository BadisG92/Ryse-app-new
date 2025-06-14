# 📱 ANALYSE DES FLUX DE NAVIGATION - RYZE APP

## 🎯 ARCHITECTURE GÉNÉRALE

### Point d'entrée : main.dart
- **Widget principal** : MyApp 
- **Navigation initiale** : RyzeApp
- **Thème** : Material 3 avec Google Fonts (Inter)

### Flux principal : RyzeApp 
- **Condition d'entrée** : Vérification SharedPreferences pour l'onboarding
- **Si pas onboardé** → OnboardingGamifiedHybrid
- **Si onboardé** → MainApp

---

## 🚀 FLUX D'ONBOARDING

### Widget : OnboardingGamifiedHybrid
**Fichier** : lib/components/onboarding_gamified_hybrid.dart

#### Navigation séquentielle (8 étapes) :
1. **Étape 0 : Bienvenue**
   - Widget : WelcomeStep()
   - Bouton : "Commencer" → Étape suivante

2. **Étape 1 : Genre**
   - Boutons : 3x InkWell (Homme/Femme/Autre)
   - Action : setState(() => userData['gender'] = value)

3. **Étape 2 : Date de naissance**
   - Widgets : CupertinoPicker pour jour/mois/année
   - Boutons : Toggle métrique/impérial (GestureDetector)

4. **Étape 3 : Taille & Poids**
   - Inputs : TextField pour poids/taille
   - Toggle : Métrique/Impérial avec animation

5. **Étape 4 : Niveau d'activité**
   - Boutons : Liste d'options avec GestureDetector
   - Options : Sédentaire, Peu actif, Modérément actif, Très actif, Extrêmement actif

6. **Étape 5 : Objectif**
   - Boutons : GestureDetector pour chaque objectif
   - Options : Perdre du poids, Maintenir, Prendre du poids, Développer muscle

7. **Étape 6 : Obstacles**
   - Boutons : Multi-sélection avec GestureDetector
   - Action : Ajout/Suppression des obstacles dans la liste

8. **Étape 7 : Restrictions alimentaires**
   - Boutons : Multi-sélection avec GestureDetector
   - Options : Végétarien, Végan, Sans gluten, Sans lactose, etc.

#### Boutons de navigation :
- **Retour** : IconButton (visible sauf étape 0)
- **Suivant** : ElevatedButton "Suivant" ou "Terminer"
- **Finalisation** : InkWell → Calcul + sauvegarde + widget.onComplete()

---

## 🏠 FLUX APPLICATION PRINCIPALE

### Widget : MainApp
**Fichier** : lib/components/main_app.dart

#### Navigation par onglets (Bottom Navigation) :
- **Widget de navigation** : BottomNavigation
- **État** : _activeTab (String)
- **Méthode** : _onTabChange(String tab)

#### 4 Onglets principaux :

##### 1. **Accueil** (home)
- **Widget** : MainDashboardHybrid
- **Bouton navigation** : GestureDetector avec icône LucideIcons.home

##### 2. **Nutrition** (nutrition)
- **Widget** : NutritionSection
- **Bouton navigation** : GestureDetector avec icône LucideIcons.apple

##### 3. **Sport** (sport)
- **Widget** : SportSection 
- **Bouton navigation** : GestureDetector avec icône LucideIcons.dumbbell

##### 4. **Progrès** (progress)
- **Widget** : GlobalProgress
- **Bouton navigation** : GestureDetector avec icône LucideIcons.trendingUp

---

## 🍎 SECTION NUTRITION DÉTAILLÉE

### Widget : NutritionSection
**Fichier** : lib/components/nutrition_section.dart

#### Navigation par PageView (3 pages) :
- **Controller** : PageController + TabController
- **État** : _currentIndex (int)

#### Pages internes :

##### Page 0 : **Tableau de bord** 
- **Widget** : NutritionDashboardHybrid
- **Onglet** : GestureDetector avec icône LucideIcons.pieChart

#### Boutons d'ajout rapide dans le tableau de bord :
**Widget** : `NutritionQuickActionsSection` (4 boutons circulaires)

##### Bouton 1 : **Saisie manuelle**
- Bouton : `GestureDetector` avec icône `LucideIcons.edit3`
- Action : Ouvre directement `_showManualEntryBottomSheet()` (même flux que journal)
- Widget cible : `DraggableScrollableSheet` avec barre de recherche

##### Bouton 2 : **Scanner avec l'IA**
- Bouton : `GestureDetector` avec icône `LucideIcons.camera`
- Action : `Navigator.push()` vers `AIScannerScreen` (même flux que journal)

##### Bouton 3 : **Code-barres**
- Bouton : `GestureDetector` avec icône `LucideIcons.scan`
- Action : `Navigator.push()` vers `BarcodeScannerScreen` (même flux que journal)

##### Bouton 4 : **Mes recettes**
- Bouton : `GestureDetector` avec icône `LucideIcons.chefHat`
- Action : `Navigator.push()` vers `SelectRecipeScreen` (même flux que journal)

##### Page 1 : **Journal**
- **Widget** : NutritionJournalHybrid
- **Onglet** : GestureDetector avec icône LucideIcons.bookOpen

##### Page 2 : **Recettes**
- **Widget** : NutritionRecipesHybrid
- **Onglet** : GestureDetector avec icône LucideIcons.chefHat

### Flux Journal Nutrition : NutritionJournalHybrid

#### Boutons principaux :
1. **Sélecteur de date**
   - Bouton : GestureDetector → Ouvre calendrier
   - Action : setState(() => showCalendar = true)

2. **Ajouter un repas**
   - Bouton : GestureDetector → _showAddMealBottomSheet()
   - Flux : Ouvre AddMealBottomSheet

#### Bottom Sheets en cascade :

##### 1. AddMealBottomSheet 
- **4 boutons de repas** : Petit-déjeuner, Déjeuner, Dîner, Collation
- **Action** : Sélection → Ferme → Ouvre AddFoodBottomSheet

##### 2. AddFoodBottomSheet
**4 options d'ajout d'aliment** :

###### Option 1 : **Saisie manuelle**
- Bouton : FoodOptionWidget avec GestureDetector
- Action : Ferme bottom sheet → Ouvre ManualEntryBottomSheet
- Widget cible : ManualEntryBottomSheet

###### Option 2 : **Scanner avec l'IA**
- Bouton : FoodOptionWidget avec GestureDetector
- Action : Ferme bottom sheet → Navigator.push() vers AIScannerScreen

###### Option 3 : **Code-barres** 
- Bouton : FoodOptionWidget avec GestureDetector
- Action : Ferme bottom sheet → Navigator.push() vers BarcodeScannerScreen

###### Option 4 : **Mes recettes**
- Bouton : FoodOptionWidget avec GestureDetector
- Action : Ferme bottom sheet → Navigator.push() vers SelectRecipeScreen

---

## 📱 ÉCRANS DÉTAILLÉS

### 1. **AIScannerScreen**
**Fichier** : lib/screens/ai_scanner_screen.dart

#### Boutons disponibles :
- **Retour** : GestureDetector → Navigator.pop(context)
- **Capture photo** : GestureDetector → _takePicture()
- **Valider** : ElevatedButton → Traitement et retour
- **Annuler** : TextButton → Navigator.pop(context)
- **Éditer aliment détecté** : GestureDetector → Dialog d'édition

### 2. **BarcodeScannerScreen**
**Fichier** : lib/screens/barcode_scanner_screen.dart

#### Boutons disponibles :
- **Retour** : GestureDetector → Navigator.pop(context)
- **Simuler scan** : ElevatedButton → _simulateScan() (dev)
- **Valider produit** : ElevatedButton → Ajout + retour
- **Annuler** : TextButton → Navigator.pop(context)

### 3. **SelectRecipeScreen**
**Fichier** : lib/screens/select_recipe_screen.dart

#### Boutons disponibles :
- **Retour** : GestureDetector → Navigator.pop(context)
- **Voir recette** : ElevatedButton.icon → _openRecipeDetails(recipe)
  - Navigation : Navigator.push() vers RecipeDetailsScreen

### 4. **RecipeDetailsScreen**
**Fichier** : lib/screens/recipe_details_screen.dart

#### Boutons nombreux :
- **Retour** : GestureDetector → Navigator.pop(context)
- **Modifier portions** : ElevatedButton → _showPortionDialog()
- **Éditer ingrédients** : ElevatedButton → _editIngredients()
- **Ajouter au journal** : ElevatedButton.icon → Ajout + navigation retour
- **Éditer ingrédient** : GestureDetector → Dialog d'édition
- **Annuler** : TextButton → Navigator.pop(context)
- **Valider** : ElevatedButton → Sauvegarde + fermeture

### 5. **ManualFoodEntryScreen**
**Fichier** : lib/screens/manual_food_entry_screen.dart

#### Boutons disponibles :
- **Retour** : GestureDetector → Navigator.pop(context)
- **Ajouter** : ElevatedButton.icon → _submitForm()
- **Annuler** : TextButton → Navigator.pop(context)

---

## 🏃 SECTION SPORT DÉTAILLÉE

### Widget : SportSection
**Fichier** : lib/components/sport_section.dart

#### Navigation par PageView (3 pages) :
- **Controller** : PageController + TabController

#### Pages internes :

##### Page 0 : **Tableau de bord**
- **Widget** : SportDashboard
- **Onglet** : GestureDetector avec icône LucideIcons.pieChart

##### Page 1 : **Cardio**
- **Widget** : SportCardioHybrid
- **Onglet** : GestureDetector avec icône LucideIcons.activity

##### Page 2 : **Musculation**
- **Widget** : SportMusculationHybrid
- **Onglet** : GestureDetector avec icône LucideIcons.dumbbell

### Sport Dashboard : SportDashboard
**Fichier** : lib/components/sport_dashboard.dart

#### Boutons disponibles :
- **Menu** : IconButton → Actions non définies
- **Cartes d'exercices** : GestureDetector → Actions vides (onTap: () {})
- **Boutons d'action** : GestureDetector → Fonctionnalités à implémenter

---

## 📊 SECTION PROGRÈS

### Widget : GlobalProgress
**Fichier** : lib/components/global_progress_hybrid.dart

#### Boutons disponibles :
- **Fermer** : IconButton → Navigator.pop(context)
- **Exporter données** : ElevatedButton → Fonctionnalité d'export
- **Autres actions** : TextButton.icon → Fonctionnalités diverses

---

## 🔗 BOTTOM SHEETS SYSTÈME

### 1. **AddMealBottomSheet**
**Fichier** : lib/bottom_sheets/add_meal_bottom_sheet.dart
- **4 boutons repas** → Sélection et navigation vers AddFoodBottomSheet

### 2. **ManualFoodSearchBottomSheet**
**Fichier** : lib/bottom_sheets/manual_food_search_bottom_sheet.dart
- **Widget réutilisable** utilisé par le journal ET le tableau de bord
- **Barre de recherche** avec suggestions d'aliments
- **Option "Créer un aliment"** → EditableFoodDetailsBottomSheet.showCreateFood()
- **Suggestions d'aliments** → EditableFoodDetailsBottomSheet.show()
- **Plus de duplication** ✅

### 3. **FoodDetailsBottomSheet**
**Fichier** : lib/bottom_sheets/food_details_bottom_sheet.dart
- **Boutons d'édition et validation**

### 4. **EditableFoodDetailsBottomSheet**
**Fichier** : lib/bottom_sheets/editable_food_details_bottom_sheet.dart
- **Interface d'édition complète avec boutons de sauvegarde**

---

## 🎯 PATTERNS DE NAVIGATION IDENTIFIÉS

### 1. **Navigation par onglets** (Bottom Navigation)
- Changement d'état via setState()
- Rendu conditionnel avec switch/case

### 2. **Navigation par pages** (PageView)
- Synchronisation PageController + TabController
- Animations fluides entre pages

### 3. **Navigation modale** (Bottom Sheets)
- showModalBottomSheet() avec customisation
- Chaînage de bottom sheets (fermeture → ouverture)

### 4. **Navigation push** (Screens)
- Navigator.push() avec MaterialPageRoute
- Retour avec Navigator.pop()

### 5. **Navigation conditionnelle**
- Vérification d'état avant navigation
- Flux différents selon contexte utilisateur

---

## 🚨 POINTS D'ATTENTION

### Fonctionnalités non implémentées :
- Nombreux onTap: () {} vides dans SportDashboard
- Actions manquantes dans certains boutons
- Certaines navigations commentées en TODO

### ✅ Fonctionnalités récemment implémentées :
- **NutritionQuickActionsSection** : Les 4 boutons d'ajout rapide du tableau de bord nutrition utilisent maintenant exactement le même flux que dans le journal
- **Navigation cohérente** : Suppression des TODO et SnackBar temporaires, remplacement par une vraie navigation
- **Refactorisation DRY** : Création de `ManualFoodSearchBottomSheet` réutilisable, suppression de ~150 lignes de code dupliqué
- **Architecture améliorée** : Plus de duplication entre journal et tableau de bord, même widget utilisé partout

### Flux complexes :
- Onboarding avec 8 étapes et validation à chaque niveau
- Chaînage de 3 bottom sheets pour l'ajout d'aliments
- Synchronisation multiple des controllers de navigation

### Performance :
- Multiples AnimationController dans l'onboarding
- Timer pour les animations de texte de chargement
- Gestion mémoire avec dispose() approprié

---

## 📋 RÉSUMÉ ACTIONS UTILISATEUR

### Actions principales par écran :
1. **Onboarding** : 8 étapes de configuration avec ~20 boutons d'interaction
2. **Navigation principale** : 4 onglets de navigation
3. **Nutrition** : 3 sous-pages + 4 modes d'ajout d'aliments
4. **Sport** : 3 sous-pages avec tableaux de bord
5. **Progrès** : Visualisation et export de données

### Total estimé : **~54 boutons/interactions** uniques dans l'application

### ✅ Améliorations récentes :
- **Boutons d'ajout rapide du tableau de bord nutrition** : Maintenant connectés au même flux que dans le journal
- **Cohérence d'expérience** : Les 4 boutons rapides (manuel, IA, code-barres, recettes) offrent la même navigation depuis le tableau de bord et le journal

---

## 🔄 DIAGRAMME DE FLUX SIMPLIFIÉ

```
RyzeApp
├── OnboardingGamifiedHybrid (8 étapes)
│   └── → MainApp
└── MainApp
    ├── MainDashboardHybrid (Accueil)
    ├── NutritionSection
    │   ├── NutritionDashboardHybrid
    │   │   └── NutritionQuickActionsSection (4 boutons)
    │   │       ├── → ManualFoodSearchBottomSheet.show() (MÊME WIDGET que journal)
    │   │       ├── → AIScannerScreen (même flux que journal)
    │   │       ├── → BarcodeScannerScreen (même flux que journal)
    │   │       └── → SelectRecipeScreen (même flux que journal)
    │   │           └── → RecipeDetailsScreen
    │   ├── NutritionJournalHybrid
    │   │   ├── → AddMealBottomSheet
    │   │   └── → AddFoodBottomSheet
    │   │       ├── → ManualFoodSearchBottomSheet.show()
    │   │       ├── → AIScannerScreen
    │   │       ├── → BarcodeScannerScreen
    │   │       └── → SelectRecipeScreen
    │   │           └── → RecipeDetailsScreen
    │   └── NutritionRecipesHybrid
    ├── SportSection
    │   ├── SportDashboard
    │   ├── SportCardioHybrid
    │   └── SportMusculationHybrid
    └── GlobalProgress
```
