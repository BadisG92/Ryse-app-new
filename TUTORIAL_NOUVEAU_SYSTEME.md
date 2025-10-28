# 🎓 Nouveau Système de Tutorials avec Image Overlay

## ✅ Ce qui a été implémenté

### 1. Fichiers créés

#### Widgets
- **`lib/components/ui/tutorial_image_overlay.dart`**
  - Widget principal pour afficher le tutorial sur une image
  - Gère la navigation entre les étapes
  - Affiche les bulles avec le panda
  - Highlight automatique des zones cibles

#### Configuration
- **`lib/services/tutorial_config.dart`**
  - Positions de toutes les bulles et cibles
  - Configurations pour Nutrition, Sport et Cardio
  - Facile à ajuster (valeurs en %)

#### Documentation
- **`assets/images/tutorials/README_SCREENSHOTS.md`**
  - Guide complet pour créer les screenshots
  - Spécifications techniques
  - Checklist de vérification

---

## 📸 ÉTAPE CRITIQUE : Créer les screenshots

**TU DOIS FAIRE 3 SCREENSHOTS AVANT QUE LE TUTORIAL FONCTIONNE** :

### Screenshots nécessaires :
1. `assets/images/tutorials/nutrition_dashboard_empty.png`
2. `assets/images/tutorials/sport_dashboard_empty.png`
3. `assets/images/tutorials/cardio_dashboard_empty.png`

### Comment les faire :

#### Option A : Compte test vide (recommandé)
```bash
# 1. Créer un nouveau compte dans l'app
# 2. NE PAS ajouter de données
# 3. Naviguer vers chaque page et faire un screenshot
```

#### Option B : Modifier temporairement le code
```dart
// Dans le widget concerné, remplacer temporairement :
final hasData = userHasData(); // avant

final hasData = false; // pour le screenshot
```

### Checklist screenshots :
- [ ] Les 3 fichiers PNG sont créés
- [ ] Nommés EXACTEMENT comme ci-dessus (sensible à la casse!)
- [ ] Placés dans `assets/images/tutorials/`
- [ ] Les pages sont VIDES (pas de données utilisateur)
- [ ] Tout le contenu est visible (pas juste un crop)

---

## 🎯 Comment ça marche maintenant

### Avant (ancien système - complexe)
```
Welcome Screen → GlobalKeys → Scroll → Coach Mark sur vrais données
❌ Problème scroll
❌ Panda pas toujours visible
❌ Varie selon les données de l'utilisateur
```

### Maintenant (nouveau système - simple)
```
Welcome Screen → Image Overlay → Coach Mark sur image statique
✅ Pas de scroll nécessaire
✅ Panda toujours visible
✅ Identique pour tous les utilisateurs
```

---

## 🔧 Ajuster les positions des bulles

Si les bulles ne sont pas bien placées après avoir mis les screenshots :

### 1. Ouvrir `lib/services/tutorial_config.dart`

### 2. Trouver la fonction concernée :
- `getNutritionSteps()` pour Nutrition
- `getSportSteps()` pour Sport
- `getCardioSteps()` pour Cardio

### 3. Ajuster les valeurs (en pourcentage 0.0 à 1.0) :

```dart
TutorialStep(
  title: '...',
  description: '...',

  // Position de la BULLE (où le dialogue apparaît)
  bubblePosition: const Offset(0.075, 0.35),
  // 0.075 = 7.5% depuis la gauche
  // 0.35 = 35% depuis le haut

  // Position de la CIBLE (zone à highlighter)
  targetPosition: const Offset(0.05, 0.15),
  // 0.05 = 5% depuis la gauche
  // 0.15 = 15% depuis le haut

  // Taille de la CIBLE
  targetSize: const Size(0.9, 0.15),
  // 0.9 = 90% de la largeur de l'écran
  // 0.15 = 15% de la hauteur de l'écran
),
```

### 4. Exemples de positions courantes :

```dart
// Bulle en HAUT (au-dessus de la cible)
bubblePosition: const Offset(0.075, 0.10), // près du haut

// Bulle en BAS (en dessous de la cible)
bubblePosition: const Offset(0.075, 0.55), // vers le milieu-bas

// Bulle tout en BAS
bubblePosition: const Offset(0.075, 0.70), // près du bas

// Cible tout en HAUT de l'écran
targetPosition: const Offset(0.05, 0.10),

// Cible au MILIEU
targetPosition: const Offset(0.05, 0.40),

// Cible en BAS
targetPosition: const Offset(0.05, 0.70),
```

---

## 🚀 Pour tester

### 1. Assure-toi que les screenshots sont en place

```bash
# Vérifier que les fichiers existent
ls assets/images/tutorials/
# Doit afficher :
# - nutrition_dashboard_empty.png
# - sport_dashboard_empty.png
# - cardio_dashboard_empty.png
```

### 2. Clean et rebuild

```bash
flutter clean
flutter pub get
flutter run
```

### 3. Naviguer vers la page Nutrition

Le tutorial devrait se lancer automatiquement !

---

## 🎨 Avantages du nouveau système

### Avant vs Maintenant

| Aspect | Ancien système | Nouveau système |
|--------|----------------|-----------------|
| **Scroll** | Complexe, parfois cassé | Pas nécessaire |
| **Panda** | Parfois caché | Toujours visible |
| **Données** | Varie selon l'utilisateur | Identique pour tous |
| **Positions** | Calcul dynamique | Statique, prévisible |
| **Maintenance** | Difficile | Facile (juste ajuster %) |
| **Performance** | GlobalKeys, states | Simple dialogue |

---

## 📝 Structure du code

### Fichiers modifiés

1. **`nutrition_section.dart`**
   - Utilise maintenant `TutorialImageOverlay`
   - Plus besoin de GlobalKeys complexes
   - Méthode `_launchDashboardTutorial()` simplifiée

2. **`sport_section.dart`** (à modifier)
   - Même pattern que Nutrition

3. **`sport_cardio_hybrid.dart`** (à modifier)
   - Même pattern que Nutrition

### Fichiers à garder (pour référence)
- `tutorial_service.dart` - Pour le Dashboard principal (garde l'ancien système)
- Les welcome screens - Toujours utilisés avant le tutorial

---

## 🔄 Migration des autres tutorials

Pour migrer Sport et Cardio au nouveau système, suivre ce pattern :

```dart
// Dans sport_section.dart, remplacer _launchDashboardTutorial par :

Future<void> _launchDashboardTutorial() async {
  await Future.delayed(const Duration(milliseconds: 300));

  final locService = LocalizationService.instance;
  if (!mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => TutorialImageOverlay(
      imagePath: TutorialConfig.sportImagePath,
      avatarPath: 'assets/images/coach_ryze_workout_avatar.png',
      steps: TutorialConfig.getSportSteps(locService.currentLanguageCode),
      languageCode: locService.currentLanguageCode,
      onFinish: () {
        Navigator.of(context).pop();
        debugPrint('✅ Tutorial Sport terminé');
      },
      onSkip: () {
        Navigator.of(context).pop();
        debugPrint('⏭️ Tutorial Sport skippé');
      },
    ),
  );
}
```

---

## ❓ FAQ

### Q: L'image ne s'affiche pas, je vois un placeholder gris
**R:** C'est normal si tu n'as pas encore créé les screenshots. Crée-les et recharge l'app.

### Q: Les bulles sont mal positionnées
**R:** Ajuste les valeurs dans `tutorial_config.dart`. Commence par ajuster `bubblePosition` en Y (2e valeur).

### Q: Je veux changer le texte des bulles
**R:** Les textes sont dans `translations.dart`, ils n'ont pas changé. Seule l'affichage est nouveau.

### Q: Peut-on avoir plus de 4 étapes ?
**R:** Oui ! Ajoute simplement plus de `TutorialStep` dans `TutorialConfig.getNutritionSteps()`.

### Q: Le tutorial se lance à chaque fois !
**R:** C'est normal, `debugMode = true`. Change à `false` pour qu'il ne se lance qu'une fois.

---

## ✨ Prochaines étapes

1. ✅ **Créer les 3 screenshots** (critique!)
2. ⏳ Tester le tutorial Nutrition
3. ⏳ Ajuster les positions si nécessaire
4. ⏳ Migrer Sport et Cardio au nouveau système
5. ⏳ Mettre `debugMode = false` en production

---

**Besoin d'aide ?** Tout est documenté dans :
- Ce fichier pour le système général
- `README_SCREENSHOTS.md` pour les screenshots
- `tutorial_config.dart` pour les positions
