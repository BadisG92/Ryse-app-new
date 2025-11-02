# 📊 Firebase Analytics - Résumé de l'intégration

## ✅ Ce qui a été fait

### 1. Dépendances ajoutées ✅
```yaml
# pubspec.yaml
firebase_core: ^2.24.2
firebase_analytics: ^10.8.0
firebase_crashlytics: ^3.4.9
```

### 2. Service Analytics créé ✅
**Fichier** : [`lib/services/analytics_service.dart`](lib/services/analytics_service.dart)

**Fonctionnalités** :
- ✅ Initialisation Firebase
- ✅ User ID tracking
- ✅ Custom events (50+ events prédéfinis)
- ✅ Screen tracking
- ✅ Error tracking avec Crashlytics
- ✅ User properties

**Events implémentés** :
- 🍽️ **Nutrition** : `food_scan_camera`, `food_scan_barcode`, `manual_food_entry`, `recipe_created`, `water_logged`
- 💪 **Workout** : `workout_completed`, `workout_started`, `cardio_completed`
- 📈 **Progress** : `weight_updated`, `streak_achieved`, `goal_achieved`
- 📱 **Widget** : `meal_widget_interaction`
- 🔐 **Auth** : `login`, `sign_up`

### 3. Intégration dans l'app ✅

#### Main.dart
```dart
// lib/main.dart (lignes 35-43)
await Firebase.initializeApp();
await AnalyticsService.initialize();
```

#### Barcode Scanner
```dart
// lib/screens/barcode_scanner_screen.dart
// ✅ Track scan camera success/failure
// ✅ Track manual barcode entry
```

#### Workout Session
```dart
// lib/screens/workout_session_screen.dart
// ✅ Track workout completed with details
```

#### Auth Service
```dart
// lib/services/auth_service.dart
// ✅ Track login (email/google/apple)
// ✅ Track sign up
// ✅ Set user ID
```

### 4. Sécurité ✅
**Fichier** : [`.gitignore`](.gitignore)

```gitignore
# Firebase - NEVER COMMIT CONFIG FILES
**/GoogleService-Info.plist
**/google-services.json
firebase-debug.log
.firebase/
```

---

## 🚀 Prochaines étapes

### Étape 1 : Configuration Firebase Console (OBLIGATOIRE)
**⚠️ Sans cette étape, l'app va crash au démarrage !**

Suivez le guide complet : **[`FIREBASE_SETUP.md`](FIREBASE_SETUP.md)**

**Résumé rapide** :
1. Créer un projet Firebase sur https://console.firebase.google.com
2. Ajouter l'app iOS :
   - Bundle ID : **`com.BadisG.ryzeApp`** ⚠️ (bundle exact de votre app)
   - Télécharger `GoogleService-Info.plist`
   - **Ajouter dans XCode** : Runner > Add Files to "Runner"
3. Ajouter l'app Android :
   - Package : **`com.example.ryze_app`** ⚠️ (package exact de votre app)
   - Télécharger `google-services.json`
   - Placer dans `android/app/google-services.json`
4. Activer Analytics & Crashlytics dans la console

### Étape 2 : Configuration Android (si pas déjà fait)

**`android/build.gradle`** :
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**`android/app/build.gradle`** (à la fin) :
```gradle
apply plugin: 'com.google.gms.google-services'
```

### Étape 3 : Build & Test

```bash
# iOS
flutter run --dart-define-from-file=.env.local

# Android
flutter run --dart-define-from-file=.env.local

# Vérifier les logs
# Vous devriez voir :
# ✅ Firebase Analytics initialized
```

### Étape 4 : Test en production (TestFlight)

```bash
# Build iOS
flutter build ios --release --dart-define-from-file=.env.production

# Archive dans XCode
# Product > Archive > Distribute to App Store Connect

# Testeurs TestFlight peuvent installer
# Les analytics seront visibles dans Firebase Console ! 🎉
```

---

## 📊 Events trackés automatiquement

| Écran / Action | Event | Paramètres |
|---------------|-------|------------|
| **Barcode Scanner** | `food_scan_barcode` | `meal_type`, `success`, `source` (camera/manual) |
| **Workout Session** | `workout_completed` | `workout_type`, `duration_minutes`, `exercise_count`, `calories_burned` |
| **Login** | `login` | `method` (email/google/apple) |
| **Sign up** | `sign_up` | `method` (email/google/apple) |

### Events disponibles mais non utilisés encore
(À ajouter dans d'autres écrans selon vos besoins)

```dart
// Nutrition
AnalyticsService.logFoodScanCamera(mealType: 'lunch', success: true);
AnalyticsService.logManualFoodEntry(mealType: 'dinner', foodName: 'Poulet');
AnalyticsService.logRecipeCreated(ingredientCount: 5);
AnalyticsService.logWaterLogged(amountMl: 250);

// Workout
AnalyticsService.logCardioCompleted(
  activityType: 'running',
  durationMinutes: 30,
  distanceKm: 5.0,
  caloriesBurned: 300,
);

// Progress
AnalyticsService.logWeightUpdated(weightKg: 75.5);
AnalyticsService.logStreakAchieved(streakDays: 7);

// Widget iOS
AnalyticsService.logWidgetInteraction(action: 'scan', widgetSize: 'medium');

// Features
AnalyticsService.logFeatureUsed('voice_workout');
AnalyticsService.logScreenView('settings_screen');
```

---

## 🔍 Voir les statistiques

### Option 1 : Firebase Console (Production)
1. https://console.firebase.google.com
2. Sélectionner votre projet
3. **Analytics** > **Events**
4. Délai : 1-24h pour les premiers events

### Option 2 : Debug Mode (Temps réel)

**iOS** :
```bash
flutter run --dart-define-from-file=.env.local --debug
# Ou dans XCode Scheme : -FIRDebugEnabled
```

**Android** :
```bash
adb shell setprop debug.firebase.analytics.app com.ryse.app
flutter run --dart-define-from-file=.env.local
```

Puis : **Firebase Console** > **Analytics** > **DebugView**

---

## 📈 KPIs recommandés à suivre

### Engagement
- **Food tracking** : Ratio camera vs barcode vs manuel
- **Workouts** : Taux de complétion, durée moyenne
- **Widget iOS** : Interactions quotidiennes

### Retention
- **DAU** (Daily Active Users)
- **WAU** (Weekly Active Users)
- **Retention** : J1, J7, J30

### Features
- **Écrans** les plus visités
- **Fonctionnalités** les plus utilisées
- **Chemins** de navigation populaires

### Qualité
- **Crash-free users** : > 99.5% objectif
- **App performance** : Temps de chargement
- **Erreurs** récurrentes

---

## 🎯 Exemples d'insights possibles

Avec ces analytics, vous pourrez répondre à :

1. **"Est-ce que les utilisateurs préfèrent le scan camera ou barcode ?"**
   - Comparer `food_scan_camera` vs `food_scan_barcode`

2. **"Combien de temps durent les workouts en moyenne ?"**
   - Analyser le paramètre `duration_minutes` de `workout_completed`

3. **"Quelles fonctionnalités ne sont jamais utilisées ?"**
   - Identifier les events avec 0 occurrences

4. **"À quel moment les utilisateurs abandonnent l'app ?"**
   - Analyser les `screen_view` avant la désinstallation

5. **"Le widget iOS est-il efficace ?"**
   - Comparer `meal_widget_interaction` vs navigation classique

---

## 🔥 Crashlytics

Les crashes sont **automatiquement trackés** grâce à l'initialisation :

```dart
// lib/main.dart
await AnalyticsService.initialize();
```

### Enregistrer une erreur manuellement
```dart
try {
  // Code risqué
} catch (e, stack) {
  AnalyticsService.recordError(e, stack, reason: 'Description');
}
```

### Voir les crashes
**Console Firebase** > **Crashlytics** > **Issues**

---

## 📚 Documentation complète

- **Guide d'installation** : [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md)
- **Service Analytics** : [`lib/services/analytics_service.dart`](lib/services/analytics_service.dart)
- **Flutter Firebase Docs** : https://firebase.flutter.dev

---

## ⚠️ Notes importantes

1. **TestFlight vs Production** : Les analytics fonctionnent dès TestFlight ! Pas besoin d'attendre l'App Store.

2. **Confidentialité** : Firebase Analytics est conforme RGPD. Ajoutez les mentions légales dans vos CGU.

3. **Coûts** : Firebase Analytics est **100% gratuit** et illimité.

4. **Performance** : Impact minimal sur l'app (~1-2ms par event).

5. **Offline** : Les events sont mis en cache et envoyés lors de la reconnexion.

---

## ✅ Checklist de déploiement

- [ ] Créer projet Firebase
- [ ] Ajouter `GoogleService-Info.plist` (iOS)
- [ ] Ajouter `google-services.json` (Android)
- [ ] Configurer `android/build.gradle` (si nécessaire)
- [ ] Tester en debug mode (voir les events dans DebugView)
- [ ] Build TestFlight
- [ ] Vérifier les analytics dans Firebase Console
- [ ] Configurer les rapports personnalisés
- [ ] Documenter les KPIs dans votre équipe

---

**Bon tracking ! 📊🔥**

*Dernière mise à jour : 2025-11-02*
