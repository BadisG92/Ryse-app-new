# Guide d'Implémentation du Tutorial

## 📝 Résumé

Le système de tutorial a été créé avec `tutorial_coach_mark`. Voici comment l'intégrer dans vos pages.

## ✅ Ce qui a été fait

1. ✅ Ajout de `tutorial_coach_mark: ^1.2.11` dans `pubspec.yaml`
2. ✅ Création du service `lib/services/tutorial_service.dart`
3. ✅ Ajout des traductions FR/EN dans `lib/services/translations.dart`
4. ⚠️ **MODE DEBUG ACTIVÉ** - Le tutorial s'affiche à chaque fois (ligne 15 de `tutorial_service.dart`)

## 🔧 Comment l'utiliser

### Étape 1: Ajouter les GlobalKeys

Dans votre widget State, déclarez des GlobalKeys pour chaque élément à mettre en évidence :

```dart
class _MaPageState extends State<MaPage> {
  // GlobalKeys pour le tutorial
  final GlobalKey _addFoodKey = GlobalKey();
  final GlobalKey _addExerciseKey = GlobalKey();
  final GlobalKey _caloriesCardKey = GlobalKey();

  // ... reste du code
}
```

### Étape 2: Attacher les keys aux widgets

Enveloppez vos widgets cibles avec une clé :

```dart
// Exemple: Bouton ajouter aliment
Container(
  key: _addFoodKey, // ← Ajouter la key ici
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Ajouter aliment'),
  ),
)
```

### Étape 3: Déclencher le tutorial

Dans `initState()` ou après que la page soit construite :

```dart
@override
void initState() {
  super.initState();

  // Attendre que le build soit fini
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _showTutorial();
  });
}

Future<void> _showTutorial() async {
  final locService = Provider.of<LocalizationService>(context, listen: false);

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

## 🎯 Pages à implémenter

### 1. Dashboard Principal (`main_dashboard_hybrid.dart`)

**Éléments à marquer:**
- ✅ Bouton "Ajouter aliment" dans QuickActions
- ✅ Bouton "Ajouter exercice" dans QuickActions
- ✅ Carte des calories
- ✅ Onglet Nutrition dans bottom navigation
- ✅ Onglet Sport dans bottom navigation

### 2. Page Nutrition (`nutrition_section.dart`)

**Éléments à marquer:**
- ✅ Bouton Scanner IA
- ✅ Bouton Scanner barcode
- ✅ Bouton Recherche manuelle
- ✅ Section Recettes
- ✅ Suivi de l'eau

### 3. Page Sport (`sport_section.dart`)

**Éléments à marquer:**
- ✅ Bouton Démarrer workout
- ✅ Bouton Ajouter cardio
- ✅ Historique des workouts

## 🔍 Mode Debug

**IMPORTANT:** Le mode debug est actuellement ACTIVÉ dans `tutorial_service.dart:15`

```dart
static const bool _debugMode = true; // ⚠️ Mettre à false en production
```

Cela force l'affichage du tutorial à chaque fois, ignorant SharedPreferences.

Pour désactiver en production:
```dart
static const bool _debugMode = false;
```

## 🎨 Personnalisation

Le tutorial utilise déjà le style de votre app :
- Couleur primaire: `Color(0xFF0B132B)`
- Overlay semi-transparent avec opacité 0.8
- Boutons personnalisés avec vos couleurs
- Traductions FR/EN automatiques

## 🧪 Tester

1. Installer les dépendances:
```bash
flutter pub get
```

2. Lancer l'app et naviguer vers la page concernée

3. Le tutorial devrait apparaître automatiquement (mode debug)

4. Cliquer sur "Compris" pour passer à l'étape suivante

5. Ou cliquer sur "Passer" (en haut à droite) pour tout skip

## 🔄 Réinitialiser les tutorials

Ajouter un bouton dans Settings ou debug menu :

```dart
ElevatedButton(
  onPressed: () {
    TutorialService().resetAllTutorials();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tutorials réinitialisés')),
    );
  },
  child: Text('Réinitialiser les tutorials'),
)
```

## 📦 Prochaines étapes

1. ✅ **FAIT** - Installer la dépendance
2. ✅ **FAIT** - Créer le service
3. ✅ **FAIT** - Ajouter les traductions
4. ⏳ **TODO** - Modifier `main_dashboard_hybrid.dart` pour ajouter les GlobalKeys
5. ⏳ **TODO** - Modifier `nutrition_section.dart` pour ajouter les GlobalKeys
6. ⏳ **TODO** - Modifier `sport_section.dart` pour ajouter les GlobalKeys
7. ⏳ **TODO** - Modifier `bottom_navigation.dart` pour exposer les keys des onglets

## 💡 Astuces

- Utilisez `ShapeLightFocus.Circle` pour les boutons ronds
- Utilisez `ShapeLightFocus.RRect` pour les cartes/boutons rectangulaires
- `ContentAlign.bottom` place la bulle en dessous de l'élément
- `ContentAlign.top` place la bulle au-dessus (utile pour bottom nav)
- Le padding de 10 crée un espace entre l'élément et le cercle lumineux
