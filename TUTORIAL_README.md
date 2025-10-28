# 🎯 Système de Tutorial / Feature Discovery - RYZE APP

## ✅ Ce qui a été fait

### 1. **Installation** ✅
- ✅ Package `tutorial_coach_mark: ^1.3.3` installé
- ✅ Dépendances récupérées avec `flutter pub get`

### 2. **Service Principal** ✅
**Fichier:** `lib/services/tutorial_service.dart`
- Service singleton centralisé
- Mode debug activé (affiche le tutorial à chaque fois)
- Gestion automatique des états (SharedPreferences)
- 3 méthodes de tutorial prêtes:
  - `showDashboardTutorial()` - Dashboard principal
  - `showNutritionTutorial()` - Page nutrition
  - `showSportTutorial()` - Page sport

### 3. **Traductions** ✅
**Fichier:** `lib/services/translations.dart`
- ✅ Toutes les traductions FR/EN ajoutées
- ✅ Textes des bulles explicatives
- ✅ Boutons "Compris" et "Passer"
- ✅ Descriptions pour chaque élément du tutorial

### 4. **Bottom Navigation** ✅
**Fichier:** `lib/components/bottom_navigation.dart`
- ✅ Support des GlobalKeys ajouté
- ✅ 4 paramètres optionnels: `homeTabKey`, `nutritionTabKey`, `sportTabKey`, `progressTabKey`
- ✅ Keys attachées aux bons onglets

### 5. **Documentation** ✅
- ✅ `TUTORIAL_README.md` (ce fichier)
- ✅ `TUTORIAL_IMPLEMENTATION_GUIDE.md` - Guide détaillé
- ✅ `lib/components/main_dashboard_with_tutorial_EXAMPLE.dart` - Exemple de code

---

## 🚀 Prochaines Étapes (À FAIRE)

### Étape 1: Dashboard Principal (PRIORITÉ 1)
**Fichier à modifier:** `lib/components/main_dashboard_hybrid.dart`

1. Ajouter l'import:
```dart
import '../services/tutorial_service.dart';
```

2. Déclarer les GlobalKeys dans `_MainDashboardHybridState`:
```dart
// Tutorial GlobalKeys
final GlobalKey _addFoodKey = GlobalKey();
final GlobalKey _addExerciseKey = GlobalKey();
final GlobalKey _caloriesCardKey = GlobalKey();
final GlobalKey _nutritionTabKey = GlobalKey();
final GlobalKey _sportTabKey = GlobalKey();
```

3. Dans `initState()`, ajouter après `_loadDashboardData()`:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _showDashboardTutorial();
});
```

4. Ajouter la méthode:
```dart
Future<void> _showDashboardTutorial() async {
  final locService = LocalizationService.instance;

  await TutorialService().showDashboardTutorial(
    context: context,
    addFoodKey: _addFoodKey,
    addExerciseKey: _addExerciseKey,
    caloriesCardKey: _caloriesCardKey,
    nutritionTabKey: _nutritionTabKey,
    sportTabKey: _sportTabKey,
    languageCode: locService.currentLanguageCode,
  );
}
```

5. **Trouver et attacher les keys aux widgets:**
   - `_addFoodKey` → Bouton "Ajouter aliment" (dans QuickActionsSection)
   - `_addExerciseKey` → Bouton "Ajouter exercice" (dans QuickActionsSection)
   - `_caloriesCardKey` → Carte principale des calories (EnhancedDailyGoalsSection)

6. **Passer les keys à BottomNavigation** (probablement dans `main_app.dart`):
```dart
BottomNavigation(
  activeTab: _activeTab,
  onTabChange: _onTabChange,
  nutritionTabKey: _nutritionTabKey,
  sportTabKey: _sportTabKey,
)
```

### Étape 2: Page Nutrition (PRIORITÉ 2)
**Fichier à modifier:** `lib/components/nutrition_section.dart`

Même approche avec ces keys:
- `_aiScannerKey` → Bouton Scanner IA
- `_barcodeScannerKey` → Bouton Scanner barcode
- `_manualSearchKey` → Bouton Recherche manuelle
- `_recipesKey` → Section Recettes
- `_waterTrackingKey` → Widget de suivi de l'eau

Méthode à ajouter:
```dart
Future<void> _showNutritionTutorial() async {
  final locService = LocalizationService.instance;

  await TutorialService().showNutritionTutorial(
    context: context,
    aiScannerKey: _aiScannerKey,
    barcodeScannerKey: _barcodeScannerKey,
    manualSearchKey: _manualSearchKey,
    recipesKey: _recipesKey,
    waterTrackingKey: _waterTrackingKey,
    languageCode: locService.currentLanguageCode,
  );
}
```

### Étape 3: Page Sport (PRIORITÉ 3)
**Fichier à modifier:** `lib/components/sport_section.dart`

Keys nécessaires:
- `_startWorkoutKey` → Bouton Démarrer workout
- `_addCardioKey` → Bouton Ajouter cardio
- `_workoutHistoryKey` → Section Historique

Méthode à ajouter:
```dart
Future<void> _showSportTutorial() async {
  final locService = LocalizationService.instance;

  await TutorialService().showSportTutorial(
    context: context,
    startWorkoutKey: _startWorkoutKey,
    addCardioKey: _addCardioKey,
    workoutHistoryKey: _workoutHistoryKey,
    languageCode: locService.currentLanguageCode,
  );
}
```

---

## 🎨 Personnalisation du Style

Le tutorial utilise déjà le style de votre app:
- **Couleur primaire**: `Color(0xFF0B132B)`
- **Couleur secondaire**: `Color(0xFF1C2951)`
- **Opacity de l'overlay**: `0.8`
- **Padding du focus**: `10px`

Pour modifier, éditer `lib/services/tutorial_service.dart`.

---

## 🔍 Mode Debug

**IMPORTANT:** Le mode debug est **ACTIVÉ** par défaut.

**Fichier:** `lib/services/tutorial_service.dart:15`

```dart
static const bool _debugMode = true; // ⚠️ ACTIVÉ POUR LES TESTS
```

**En mode debug:**
- ✅ Le tutorial s'affiche **à chaque fois** (ignore SharedPreferences)
- ✅ Parfait pour tester sans avoir à réinitialiser

**Pour la production:**
```dart
static const bool _debugMode = false; // Le tutorial ne s'affiche qu'une fois
```

---

## 🧪 Comment Tester

### Test Rapide (Dashboard)
1. Modifiez `main_dashboard_hybrid.dart` selon l'Étape 1
2. Lancez l'app:
```bash
flutter run
```
3. Le tutorial devrait apparaître automatiquement sur le dashboard
4. Testez les interactions:
   - Cliquez sur "Compris" → Passe à l'étape suivante
   - Cliquez sur "Passer" (en haut à droite) → Skip tout le tutorial
   - Appuyez en dehors → Rien ne se passe (pas de fermeture accidentelle)

### Test Complet
1. Implémentez les 3 pages (Dashboard, Nutrition, Sport)
2. Lancez l'app
3. Naviguez entre les pages
4. Le tutorial devrait apparaître la première fois sur chaque page
5. Avec debug mode = true, il réapparaît à chaque visite

### Réinitialiser les Tutorials
Pour tester à nouveau, appelez:
```dart
await TutorialService().resetAllTutorials();
```

Ou ajoutez un bouton dans Settings:
```dart
ElevatedButton(
  onPressed: () async {
    await TutorialService().resetAllTutorials();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tutorials réinitialisés !')),
    );
  },
  child: Text('Réinitialiser les tutorials'),
)
```

---

## 📝 Checklist d'Implémentation

### Dashboard Principal
- [ ] Import de `tutorial_service.dart`
- [ ] Déclaration des 5 GlobalKeys
- [ ] Ajout de `_showDashboardTutorial()` dans `initState()`
- [ ] Key attachée au bouton "Ajouter aliment"
- [ ] Key attachée au bouton "Ajouter exercice"
- [ ] Key attachée à la carte des calories
- [ ] Keys passées à BottomNavigation (nutrition + sport)
- [ ] Test: Tutorial s'affiche automatiquement
- [ ] Test: Tous les éléments sont correctement entourés

### Page Nutrition
- [ ] Import de `tutorial_service.dart`
- [ ] Déclaration des 5 GlobalKeys
- [ ] Ajout de `_showNutritionTutorial()` dans `initState()`
- [ ] Key attachée au Scanner IA
- [ ] Key attachée au Scanner barcode
- [ ] Key attachée à la Recherche manuelle
- [ ] Key attachée aux Recettes
- [ ] Key attachée au Suivi de l'eau
- [ ] Test: Tutorial s'affiche automatiquement
- [ ] Test: Tous les éléments sont correctement entourés

### Page Sport
- [ ] Import de `tutorial_service.dart`
- [ ] Déclaration des 3 GlobalKeys
- [ ] Ajout de `_showSportTutorial()` dans `initState()`
- [ ] Key attachée à "Démarrer workout"
- [ ] Key attachée à "Ajouter cardio"
- [ ] Key attachée à l'Historique
- [ ] Test: Tutorial s'affiche automatiquement
- [ ] Test: Tous les éléments sont correctement entourés

### Finitions
- [ ] Désactiver le mode debug pour la production
- [ ] Ajouter un bouton "Réinitialiser tutorials" dans Settings (optionnel)
- [ ] Vérifier les traductions FR/EN
- [ ] Tester sur différentes tailles d'écran
- [ ] Ajuster les positions des bulles si nécessaire (ContentAlign)

---

## 🐛 Dépannage

### Le tutorial ne s'affiche pas
1. Vérifier que `_debugMode = true` dans `tutorial_service.dart`
2. Vérifier que les GlobalKeys sont bien déclarées dans le State
3. Vérifier que `WidgetsBinding.instance.addPostFrameCallback` est bien appelé
4. Regarder les logs pour les erreurs (debugPrint dans tutorial_service.dart)

### Un élément n'est pas entouré
1. Vérifier que la key est bien attachée au bon widget
2. Vérifier que le widget existe au moment du tutorial
3. Essayer d'augmenter le délai: `await Future.delayed(Duration(milliseconds: 800))`

### La bulle est mal placée
1. Changer le `ContentAlign`:
   - `ContentAlign.bottom` → Bulle en dessous
   - `ContentAlign.top` → Bulle au-dessus
   - `ContentAlign.left` → Bulle à gauche
   - `ContentAlign.right` → Bulle à droite

### Le tutorial se ferme tout seul
1. Vérifier que `enableOverlayTab: true` est bien défini
2. C'est normal si vous appuyez sur "Passer" ou "Compris"

---

## 📚 Ressources

- **Documentation tutorial_coach_mark**: https://pub.dev/packages/tutorial_coach_mark
- **Guide d'implémentation**: `TUTORIAL_IMPLEMENTATION_GUIDE.md`
- **Exemple de code**: `lib/components/main_dashboard_with_tutorial_EXAMPLE.dart`
- **Service principal**: `lib/services/tutorial_service.dart`
- **Traductions**: `lib/services/translations.dart` (lignes 4161-4279)

---

## 🎉 Résultat Attendu

Une fois implémenté, votre app aura:
- ✨ Un overlay gris semi-transparent
- 🎯 Des cercles/rectangles lumineux autour des éléments importants
- 💬 Des bulles explicatives avec votre design
- 🌐 Traductions FR/EN automatiques
- 💾 Sauvegarde de l'état (ne s'affiche qu'une fois par défaut)
- 🐛 Mode debug pour faciliter les tests
- ⏭️ Bouton "Passer" pour les utilisateurs expérimentés

**Bon courage ! 🚀**

Si vous avez des questions, référez-vous aux fichiers de documentation ou au code d'exemple.
