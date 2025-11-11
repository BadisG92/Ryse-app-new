# 📱 Widget iOS "Smart Meal" - Documentation Complète

## 🎯 Vue d'Ensemble

Le **Widget "Smart Meal"** est un widget iOS intelligent qui affiche le repas contextuel selon l'heure de la journée et permet d'ajouter rapidement des aliments depuis l'écran d'accueil.

### Fonctionnalités Principales

✅ **Détection Contextuelle** : Affiche automatiquement le bon repas selon l'heure
  - 7h-10h → Petit-déjeuner 🌅
  - 11h-14h → Déjeuner 🌤️
  - 18h-21h → Dîner 🌙
  - Autre → Snack 🍎

✅ **Progression Calories** : Visualisation instantanée des calories du jour

✅ **5 Actions Rapides** : Accès direct aux modes d'ajout
  - 📝 Recherche manuelle
  - 📸 Scanner IA
  - 🔍 Code-barres
  - 🍳 Recettes
  - 💬 Chat IA

✅ **2 Tailles** : Small (Lock Screen) et Medium (Home Screen)

✅ **Refresh Intelligent** : Mise à jour plus fréquente aux heures de repas

## 📁 Fichiers Créés

### Flutter / Dart

1. **`lib/services/widget_deep_link_handler.dart`**
   - Gère les deep links depuis les widgets iOS
   - Navigue vers les bonnes fonctionnalités de l'app
   - Supporte les flux pré-sélectionnés (repas + mode)

2. **`lib/services/meal_widget_data_provider.dart`**
   - Synchronise les données entre Flutter et iOS
   - Sauvegarde dans SharedPreferences (accessible par widgets)
   - Appelé automatiquement après chaque modification de repas

3. **Modifications dans `lib/services/food_entries_service.dart`**
   - Ajout de l'import : `import 'meal_widget_data_provider.dart';`
   - Appel de `MealWidgetDataProvider.updateWidgetData()` après :
     - `addFoodEntry()` (ligne 376)
     - `deleteFoodEntry()` (ligne 522)
     - `addScannedFoodEntry()` (ligne 757)

### iOS / Swift

4. **`ios/RyseMealWidget/RyseMealWidget.swift`**
   - Widget principal avec 2 vues (Small + Medium)
   - Timeline Provider avec stratégie de refresh intelligente
   - Parseur JSON pour les données Flutter
   - Gestion des deep links

### Documentation

5. **`WIDGET_INSTALLATION_GUIDE.md`**
   - Guide pas-à-pas complet pour installer le widget
   - Configuration Xcode (App Groups, Deep Links)
   - Tests et résolution de problèmes

6. **`WIDGET_README.md`** (ce fichier)
   - Vue d'ensemble technique
   - Architecture et flux de données

## 🏗️ Architecture

### Flux de Données

```
Flutter App (ajout/suppression repas)
    ↓
FoodEntriesService.addFoodEntry()
    ↓
MealWidgetDataProvider.updateWidgetData()
    ↓
SharedPreferences (group.com.ryze.app)
    ↓
iOS Widget (Timeline Provider)
    ↓
Affichage Widget sur Home Screen / Lock Screen
```

### Flux Deep Links

```
User tape sur widget action
    ↓
iOS génère deep link (ryse://add-food?meal=dejeuner&mode=camera)
    ↓
Flutter reçoit via uni_links
    ↓
WidgetDeepLinkHandler.handleDeepLink()
    ↓
Navigation vers fonctionnalité (ex: AIScannerScreen)
```

## 📊 Format des Données

### Structure JSON Partagée

```json
{
  "contextualMeal": {
    "type": "dejeuner",
    "name": "Déjeuner",
    "emoji": "🌤️",
    "calories": 650,
    "hasItems": true,
    "itemCount": 3
  },
  "allMeals": [
    {
      "type": "petit-dejeuner",
      "name": "Petit-déjeuner",
      "emoji": "🌅",
      "calories": 420,
      "hasItems": true,
      "itemCount": 2
    },
    // ... autres repas
  ],
  "totals": {
    "current": 1070,
    "goal": 2000,
    "percentage": 54
  },
  "macros": {
    "protein": 85,
    "carbs": 120,
    "fats": 45
  },
  "lastUpdate": "2025-10-30T12:47:00.000Z"
}
```

## 🔗 Deep Links Supportés

### Format Général
```
ryse://add-food[?meal={mealType}][&mode={mode}]
```

### Exemples

**Flux normal (sélection repas → mode)**
```
ryse://add-food
```

**Repas pré-sélectionné (affiche les 5 modes)**
```
ryse://add-food?meal=dejeuner
```

**Mode pré-sélectionné (sélection repas puis mode)**
```
ryse://add-food?mode=camera
```

**Les deux pré-sélectionnés (ouvre directement)**
```
ryse://add-food?meal=dejeuner&mode=camera
```

### Paramètres

**meal** (types de repas)
- `petit-dejeuner` → Petit-déjeuner
- `dejeuner` → Déjeuner
- `diner` → Dîner
- `snack` → Snack

**mode** (méthodes d'ajout)
- `manual` → Recherche manuelle
- `camera` / `scanner` → Scanner IA
- `barcode` → Scanner code-barres
- `recipe` → Sélection recettes
- `chat` → Chat IA

## ⚙️ Configuration Requise

### App Groups

**Obligatoire** pour partager les données entre Flutter et le widget.

**Runner target** :
```
Signing & Capabilities → App Groups → group.com.ryze.app
```

**RyseMealWidget target** :
```
Signing & Capabilities → App Groups → group.com.ryze.app
```

### URL Scheme

**Obligatoire** pour les deep links.

**`ios/Runner/Info.plist`** :
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ryse</string>
        </array>
    </dict>
</array>
```

### Dependencies

**`pubspec.yaml`** :
```yaml
dependencies:
  uni_links: ^0.5.1
  shared_preferences: ^2.2.2  # Déjà présent
```

## 🔄 Stratégie de Refresh

### Timeline Provider Intelligent

Le widget utilise une stratégie de refresh adaptative :

**Heures de repas (7-10h, 11-14h, 18-21h)** :
- Refresh toutes les **15 minutes**
- Idéal pour capturer les ajouts fréquents

**Autres heures** :
- Refresh toutes les **60 minutes**
- Économie de batterie

**Triggers manuels** :
- Après chaque ajout/suppression d'aliment dans l'app
- Via `WidgetKit.reloadAllTimelines()` (à implémenter)

## 🎨 Personnalisation

### Changer les Couleurs

**`RyseMealWidget.swift`** :
```swift
LinearGradient(
    colors: [
        Color(hex: "0B132B"),  // Bleu foncé Ryse
        Color(hex: "1C2951")   // Bleu moyen Ryse
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Modifier les Heures Contextuelles

**`meal_widget_data_provider.dart`** :
```dart
static String _getContextualMealType() {
  final hour = DateTime.now().hour;

  if (hour >= 6 && hour < 10) {      // Petit-déjeuner
    return 'petit-dejeuner';
  } else if (hour >= 11 && hour < 14) {  // Déjeuner
    return 'dejeuner';
  } else if (hour >= 18 && hour < 21) {  // Dîner
    return 'diner';
  } else {
    return 'snack';
  }
}
```

### Ajouter des Actions Rapides

**`RyseMealWidget.swift`** (dans `MediumWidgetView`) :
```swift
var quickActions: [(icon: String, mode: String)] {
    [
        ("pencil", "manual"),
        ("camera.fill", "camera"),
        ("barcode.viewfinder", "barcode"),
        ("fork.knife", "recipe"),
        ("message.fill", "chat"),
        // Ajoutez vos actions ici
        ("star.fill", "favorite")  // Exemple
    ]
}
```

## 🧪 Tests

### Test Manuel

1. **Test Détection Contextuelle**
   - Changez l'heure système de votre appareil
   - Vérifiez que le widget affiche le bon repas

2. **Test Données**
   - Ajoutez un repas dans l'app
   - Retournez à l'écran d'accueil
   - Vérifiez que les calories sont mises à jour

3. **Test Deep Links**
   - Tapez sur chaque bouton du widget
   - Vérifiez que l'app ouvre la bonne fonctionnalité

### Debug

**Flutter logs** :
```bash
flutter logs
```

Cherchez :
```
📱 Mise à jour des données widget...
✅ Données widget mises à jour: ...
🔗 Deep link reçu: ...
🎯 Flux direct: dejeuner → camera
```

**Xcode logs** :
```
⚠️ Impossible de charger les données du widget
```
→ Vérifiez l'App Group

```
🔗 Deep link reçu: ryse://...
```
→ Deep links fonctionnent

## 🚀 Améliorations Futures

### Phase 2 : Interactive Widgets (iOS 17+)

Permettre l'ajout d'eau directement depuis le widget sans ouvrir l'app.

```swift
// Exemple : Bouton interactif
Button(intent: AddWaterIntent(volume: 250)) {
    Text("+250ml")
}
```

### Phase 3 : Live Activities

Afficher un workout en cours sur le Lock Screen en temps réel.

### Phase 4 : Widget Large

Afficher tous les repas de la journée avec détails.

```
┌─────────────────────────────┐
│ 🍽️ Mes Repas du Jour        │
│                             │
│ 🌅 Petit-déj    420 kcal [+]│
│    Toast, café, œufs        │
│                             │
│ 🌤️ Déjeuner     0 kcal   [+]│
│    Aucun aliment            │
│                             │
│ 🌙 Dîner        0 kcal   [+]│
│    Aucun aliment            │
│                             │
│ 📊 1,070 / 2,000 kcal       │
│ ▓▓▓▓▓▓▓▓▓░░░░ 54%           │
└─────────────────────────────┘
```

### Phase 5 : Apple Watch Complication

Afficher les calories sur le cadran de l'Apple Watch.

## 📞 Support

### Problèmes Courants

**Widget affiche "0 kcal"**
→ Vérifiez App Groups dans les 2 targets

**Deep links ne fonctionnent pas**
→ Vérifiez CFBundleURLSchemes dans Info.plist

**Widget ne se rafraîchit pas**
→ Supprimez et ré-ajoutez le widget (force refresh)

### Logs Utiles

**Vérifier données partagées** :
```dart
// Dans Flutter
final data = await MealWidgetDataProvider.getWidgetData();
print(data);
```

**Vérifier App Group** :
```swift
// Dans Swift
if let userDefaults = UserDefaults(suiteName: "group.com.ryze.app") {
    print("✅ App Group accessible")
} else {
    print("❌ App Group non accessible")
}
```

## 🎉 Résultat Final

Une fois installé, vous aurez :

✅ **Widget Small** sur Lock Screen avec actions rapides
✅ **Widget Medium** sur Home Screen avec détails complets
✅ **Détection contextuelle** du repas selon l'heure
✅ **Deep links** vers toutes les fonctionnalités
✅ **Mise à jour temps réel** après chaque modification
✅ **Refresh intelligent** qui économise la batterie

**Votre app Ryse est maintenant au niveau AAA avec un widget iOS professionnel !** 🚀
