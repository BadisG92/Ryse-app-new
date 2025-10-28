# 🎓 Système de Tutorials - Guide Rapide

## ✨ Concept

Le système affiche la **vraie page Flutter avec des données vides** pendant le tutorial, puis montre les vraies données utilisateur à la fin.

**Plus besoin de screenshots!** Le panda est toujours visible et la position est toujours parfaite.

---

## ✅ Status Actuel

### Implémenté:
- ✅ **Infrastructure complète** (TutorialOverlaySystem avec pages mockées)
- ✅ **Nutrition** - Fonctionnel à 100% avec pages mockées

### À implémenter (même pattern):
- ⏳ **Sport Dashboard** - À convertir en pages mockées
- ⏳ **Cardio** - À convertir en pages mockées

---

## 📁 Fichiers Principaux

### Infrastructure (✅ Créés)
1. **[tutorial_overlay_system.dart](lib/components/tutorial/tutorial_overlay_system.dart)** - Système qui affiche des pages mockées avec tutorial_coach_mark
2. **[tutorial_nutrition_dashboard.dart](lib/components/tutorial/tutorial_nutrition_dashboard.dart)** - Page nutrition mockée avec données vides

### Nutrition (✅ Modifiés)
1. **[nutrition_section.dart](lib/components/nutrition_section.dart#L129-194)** - Lance le tutorial
2. **[nutrition_dashboard_hybrid.dart](lib/components/nutrition_dashboard_hybrid.dart)** - Support mode tutorial

### Sport & Cardio (⏳ À modifier)
1. **sport_section.dart** - À modifier (pattern dans TUTORIAL_FINAL_STATUS.md)
2. **sport_dashboard.dart** - À modifier
3. **sport_cardio_hybrid.dart** - À modifier

---

## 🚀 Comment Implémenter (Pattern Simple)

Pour chaque page de tutorial:

### 1. Ajouter les imports
```dart
import 'ui/tutorial_live_overlay.dart';
import '../services/tutorial_mode_provider.dart';
```

### 2. Créer la méthode getTutorialSteps()
```dart
List<TutorialStep> getTutorialSteps(String languageCode) {
  return [
    TutorialStep(
      title: 'tutorial_xxx_title'.tr(languageCode),
      description: 'tutorial_xxx_desc'.tr(languageCode),
      targetKey: _myWidgetKey,  // GlobalKey du widget
      alignTop: false,  // Bulle en bas (true = bulle en haut)
    ),
    // ... autres steps
  ];
}
```

### 3. Check le mode tutorial dans le chargement des données
```dart
void _loadData() {
  final tutorialProvider = TutorialModeProvider();

  if (tutorialProvider.isTutorialMode) {
    // DONNÉES VIDES (tutorial)
    calories = 0;
    sessions = 0;
  } else {
    // VRAIES DONNÉES (normal)
    calories = realUserCalories;
    sessions = realUserSessions;
  }
}
```

### 4. Lancer le tutorial
```dart
Future<void> _launchTutorial() async {
  final tutorialProvider = TutorialModeProvider();

  // Activer mode tutorial
  tutorialProvider.enableTutorialMode();
  await Future.delayed(const Duration(milliseconds: 200));

  // Obtenir les steps
  final steps = myWidgetState.getTutorialSteps(languageCode);

  // Afficher overlay
  await showDialog(
    context: context,
    builder: (context) => TutorialLiveOverlay(
      demoPage: Container(),
      avatarPath: 'assets/images/coach_ryze_xxx_avatar.png',
      steps: steps,
      languageCode: languageCode,
      onFinish: () {
        tutorialProvider.disableTutorialMode();  // IMPORTANT!
        Navigator.pop(context);
      },
      onSkip: () {
        tutorialProvider.disableTutorialMode();  // IMPORTANT!
        Navigator.pop(context);
      },
    ),
  );
}
```

---

## 📋 TODO Sport & Cardio

Copie-colle le code ci-dessus dans:
1. `sport_section.dart` → méthode `_launchDashboardTutorial()`
2. `sport_dashboard.dart` → ajouter `getTutorialSteps()` et check mode tutorial
3. `sport_section.dart` → méthode `_launchCardioTutorial()`
4. `sport_cardio_hybrid.dart` → ajouter `getTutorialSteps()` et check mode tutorial

**Exemples complets dans**: [TUTORIAL_FINAL_STATUS.md](TUTORIAL_FINAL_STATUS.md)

---

## 📚 Documentation Complète

- **Ce fichier** - Guide rapide
- **[TUTORIAL_FINAL_STATUS.md](TUTORIAL_FINAL_STATUS.md)** - Status + Code complet pour Sport/Cardio
- **[RESUME_TUTORIAL_SYSTEME.md](RESUME_TUTORIAL_SYSTEME.md)** - Résumé du système
- **[TUTORIAL_SYSTEME_FINAL.md](TUTORIAL_SYSTEME_FINAL.md)** - Guide détaillé

---

## ✨ Avantages

✅ Pas de screenshots
✅ Panda toujours visible
✅ Identique pour tous
✅ Facile à maintenir
✅ Vraie page Flutter

---

**C'est tout!** Le pattern est simple, tout est documenté. Il suffit de copier-coller pour Sport et Cardio. 🚀
