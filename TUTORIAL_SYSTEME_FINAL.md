# 🎓 Système de Tutorial Final - Avec Page Réelle en Mode Démo

## ✨ Concept

Au lieu d'utiliser des screenshots statiques, le système utilise la **vraie page Flutter** mais affiche des **données vides/démo** pendant le tutorial.

### Flux du tutorial:
```
1. Welcome Screen (Bienvenue)
   ↓
2. Mode Tutorial activé (TutorialModeProvider)
   ↓
3. Page se rebuild avec données vides (0 calories, 0 repas, etc.)
   ↓
4. Overlay transparent avec bulles Coach Ryze
   ↓
5. Utilisateur navigue les étapes
   ↓
6. À la fin: Mode Tutorial désactivé
   ↓
7. Page se rebuild avec vraies données utilisateur
```

---

## 🎯 Avantages

| Aspect | Ancien système | Nouveau système |
|--------|----------------|-----------------|
| **Data** | Varie selon utilisateur | Toujours vide/démo |
| **Scroll** | Complexe, parfois cassé | ✅ Automatique |
| **Panda** | Parfois caché | ✅ Toujours visible |
| **Maintenance** | Screenshots à refaire | ✅ Code seulement |
| **Dynamique** | Image statique | ✅ Vraie page Flutter |
| **Performance** | Charge image | ✅ Widgets natifs |

---

## 🏗️ Architecture

### 1. TutorialModeProvider
**Fichier**: `lib/services/tutorial_mode_provider.dart`

```dart
final tutorialProvider = TutorialModeProvider();

// Activer le mode tutorial
tutorialProvider.enableTutorialMode();

// Dans ton widget
if (tutorialProvider.isTutorialMode) {
  // Afficher données vides
  return _buildEmptyState();
} else {
  // Afficher vraies données
  return _buildRealData();
}

// Désactiver à la fin
tutorialProvider.disableTutorialMode();
```

### 2. TutorialLiveOverlay
**Fichier**: `lib/components/ui/tutorial_live_overlay.dart`

Widget qui affiche:
- Overlay sombre avec découpe sur la cible
- Bulle de dialogue avec Coach Ryze
- Navigation entre les étapes
- Positionnement automatique des bulles

### 3. TutorialStep
Modèle pour chaque étape:

```dart
TutorialStep(
  title: 'Calories du jour',
  description: 'Ici tu retrouves...',
  targetKey: _caloriesCardKey, // GlobalKey du widget à cibler
  alignTop: false, // Bulle en haut ou en bas
)
```

---

## 📝 Comment implémenter pour une nouvelle page

### Étape 1: Ajouter le mode tutorial dans ton widget

```dart
import '../services/tutorial_mode_provider.dart';

class MyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tutorialProvider = TutorialModeProvider();

    // Utiliser les données selon le mode
    final calories = tutorialProvider.isTutorialMode
        ? 0  // Données vides
        : getUserCalories(); // Vraies données

    return MyCaloriesCard(calories: calories);
  }
}
```

### Étape 2: Créer les GlobalKeys

```dart
class NutritionDashboard extends StatefulWidget {
  @override
  State<NutritionDashboard> createState() => NutritionDashboardState();
}

class NutritionDashboardState extends State<NutritionDashboard> {
  // GlobalKeys pour le tutorial
  final GlobalKey _caloriesCardKey = GlobalKey();
  final GlobalKey _macrosCardKey = GlobalKey();
  final GlobalKey _hydrationKey = GlobalKey();
  final GlobalKey _actionsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(key: _caloriesCardKey, child: CaloriesCard()),
        Container(key: _macrosCardKey, child: MacrosCard()),
        Container(key: _hydrationKey, child: HydrationCard()),
        Container(key: _actionsKey, child: QuickActions()),
      ],
    );
  }
}
```

### Étape 3: Lancer le tutorial

```dart
Future<void> _launchTutorial() async {
  final tutorialProvider = TutorialModeProvider();
  final locService = LocalizationService.instance;

  // 1. Activer le mode tutorial
  tutorialProvider.enableTutorialMode();

  // 2. Attendre le rebuild avec données vides
  await Future.delayed(const Duration(milliseconds: 200));

  // 3. Créer les steps
  final steps = [
    TutorialStep(
      title: 'tutorial_calories_title'.tr(locService.currentLanguageCode),
      description: 'tutorial_calories_desc'.tr(locService.currentLanguageCode),
      targetKey: _caloriesCardKey,
      alignTop: false,
    ),
    TutorialStep(
      title: 'tutorial_macros_title'.tr(locService.currentLanguageCode),
      description: 'tutorial_macros_desc'.tr(locService.currentLanguageCode),
      targetKey: _macrosCardKey,
      alignTop: true,
    ),
    // ... autres steps
  ];

  // 4. Afficher le tutorial
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => TutorialLiveOverlay(
      demoPage: Container(), // La page est déjà visible en dessous
      avatarPath: 'assets/images/coach_ryze_nutrition_avatar.png',
      steps: steps,
      languageCode: locService.currentLanguageCode,
      onFinish: () {
        tutorialProvider.disableTutorialMode(); // Revenir aux vraies données
        Navigator.of(context).pop();
      },
      onSkip: () {
        tutorialProvider.disableTutorialMode();
        Navigator.of(context).pop();
      },
    ),
  );
}
```

---

## 🎨 Exemple complet: Nutrition Dashboard

### Dans nutrition_dashboard_hybrid.dart

```dart
class NutritionDashboardHybridState extends State<NutritionDashboardHybrid> {
  final GlobalKey _caloriesCardKey = GlobalKey();
  final GlobalKey _macrosCardKey = GlobalKey();
  final GlobalKey _hydrationMealsKey = GlobalKey();
  final GlobalKey _quickActionsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final tutorialProvider = TutorialModeProvider();

    // Charger les données selon le mode
    final caloriesData = tutorialProvider.isTutorialMode
        ? TutorialModeProvider.nutritionDemoData
        : _loadRealData();

    return Column(
      children: [
        Container(
          key: _caloriesCardKey,
          child: CaloriesCard(
            consumed: caloriesData['calories_consumed'],
            target: caloriesData['calories_target'],
          ),
        ),
        Container(
          key: _macrosCardKey,
          child: MacrosCard(
            proteins: caloriesData['proteins'],
            carbs: caloriesData['carbs'],
            fats: caloriesData['fats'],
          ),
        ),
        // ... autres widgets
      ],
    );
  }
}
```

---

## 🔧 Données de démonstration

Les données vides sont définies dans `TutorialModeProvider`:

```dart
class TutorialModeProvider {
  static const nutritionDemoData = {
    'calories_consumed': 0,
    'calories_target': 2000,
    'proteins': 0.0,
    'carbs': 0.0,
    'fats': 0.0,
    'water_glasses': 0,
    'meals_count': 0,
  };

  static const sportDemoData = {
    'calories_burned': 0,
    'sessions_count': 0,
    'activities': [],
  };
}
```

Pour utiliser:
```dart
final data = tutorialProvider.isTutorialMode
    ? TutorialModeProvider.nutritionDemoData
    : realUserData;
```

---

## 🎯 Positionnement des bulles

Le widget `TutorialLiveOverlay` calcule automatiquement la position:

```dart
TutorialStep(
  targetKey: _myWidgetKey,  // Widget à cibler
  alignTop: false,           // false = bulle EN-DESSOUS
                            // true = bulle AU-DESSUS
)
```

L'overlay gère automatiquement:
- ✅ Découpe du widget ciblé
- ✅ Position de la bulle (dessus/dessous)
- ✅ Bordure blanche autour de la cible
- ✅ Gestion des débordements d'écran

---

## 📋 Checklist pour ajouter un tutorial

- [ ] Identifier les widgets clés à cibler
- [ ] Créer des GlobalKeys pour chaque widget
- [ ] Attacher les GlobalKeys aux widgets (via Container)
- [ ] Ajouter le check `tutorialProvider.isTutorialMode` dans le widget
- [ ] Définir les données de démo (valeurs à 0)
- [ ] Créer les TutorialStep avec traductions
- [ ] Implémenter la méthode _launchTutorial
- [ ] Appeler depuis le welcome screen
- [ ] Tester le flow complet

---

## 🚀 Avantages de cette approche

### vs Screenshots statiques:
✅ **Pas besoin de refaire des screenshots** à chaque changement de design
✅ **Widgets interactifs** (vrais boutons, animations Flutter)
✅ **Adaptatif** aux différentes tailles d'écran
✅ **Facile à maintenir** (juste du code)

### vs Tutorial sur données réelles:
✅ **Cohérent** pour tous les utilisateurs (nouveaux ou existants)
✅ **Panda toujours visible** (pas de long contenu qui scrolle)
✅ **Clair** (pas de distraction avec de vraies données)

---

## 🎓 Fichiers modifiés pour Nutrition

1. ✅ `lib/services/tutorial_mode_provider.dart` - Nouveau
2. ✅ `lib/components/ui/tutorial_live_overlay.dart` - Nouveau
3. ✅ `lib/components/nutrition_section.dart` - Méthode _launchDashboardTutorial
4. ⏳ `lib/components/nutrition_dashboard_hybrid.dart` - À modifier (check mode tutorial)

---

## 📚 Prochaines étapes

1. ⏳ Modifier `nutrition_dashboard_hybrid.dart` pour check le mode tutorial
2. ⏳ Appliquer le même pattern pour Sport
3. ⏳ Appliquer le même pattern pour Cardio
4. ⏳ Tester le flow complet
5. ⏳ Mettre `debugMode = false` en production

---

**Note**: Plus besoin de screenshots! Le système utilise la vraie page avec des données vides. 🎉
