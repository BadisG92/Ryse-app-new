# 🔥 Firebase Analytics Setup Guide

## Vue d'ensemble

Ce guide vous explique comment configurer Firebase Analytics et Crashlytics pour l'app Ryse.

**Prérequis** :
- Compte Google/Firebase
- Accès à la console Firebase (https://console.firebase.google.com)
- XCode et Android Studio installés

---

## Étape 1 : Créer un projet Firebase

1. Allez sur https://console.firebase.google.com
2. Cliquez sur **"Ajouter un projet"** (ou "Add project")
3. Nom du projet : `Ryse App` (ou `ryse-app`)
4. Activez Google Analytics : **Oui** ✅
5. Créez ou sélectionnez un compte Google Analytics
6. Cliquez sur **"Créer le projet"**

---

## Étape 2 : Ajouter l'app iOS

### Dans la console Firebase :

1. Cliquez sur l'icône **iOS** (⚙️ Paramètres du projet > Vos apps)
2. Renseignez les informations :
   - **iOS Bundle ID** : `com.BadisG.ryzeApp` ⚠️ **IMPORTANT : Utilisez exactement ce Bundle ID**
   - **Surnom de l'app** (optionnel) : `Ryse App iOS`
   - **App Store ID** (optionnel) : Laissez vide pour l'instant
3. Cliquez sur **"Enregistrer l'app"**

### Télécharger GoogleService-Info.plist :

4. Téléchargez le fichier `GoogleService-Info.plist`
5. **IMPORTANT** : Ouvrez XCode et ajoutez ce fichier :
   ```
   XCode > Projet Runner > Clic droit sur "Runner" (dossier racine)
   > Add Files to "Runner"
   > Sélectionnez GoogleService-Info.plist
   ✅ Cochez "Copy items if needed"
   ✅ Cochez "Runner" dans Targets
   ```

6. Vérifiez que le fichier apparaît dans **Runner > Runner** (pas dans un sous-dossier)

### Configuration iOS (Info.plist) :

7. Le fichier `ios/Runner/Info.plist` doit déjà contenir les permissions camera, mais vérifiez :
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Nous avons besoin de la caméra pour scanner vos aliments</string>
   ```

---

## Étape 3 : Ajouter l'app Android

### Dans la console Firebase :

1. Cliquez sur l'icône **Android**
2. Renseignez les informations :
   - **Package name** : `com.example.ryze_app` ⚠️ **IMPORTANT : Utilisez exactement ce package name**
   - **Surnom de l'app** (optionnel) : `Ryse App Android`
   - **SHA-1** (optionnel pour Analytics) : Laissez vide pour l'instant
3. Cliquez sur **"Enregistrer l'app"**

### Télécharger google-services.json :

4. Téléchargez le fichier `google-services.json`
5. Placez-le dans : `android/app/google-services.json`

### Configuration Android :

6. Ouvrez `android/build.gradle` et vérifiez/ajoutez :
   ```gradle
   buildscript {
       dependencies {
           // ... autres dépendances
           classpath 'com.google.gms:google-services:4.4.0'  // ← Ajoutez cette ligne
       }
   }
   ```

7. Ouvrez `android/app/build.gradle` et vérifiez/ajoutez à la fin :
   ```gradle
   apply plugin: 'com.google.gms.google-services'  // ← Ajoutez à la toute fin
   ```

---

## Étape 4 : Activer Analytics & Crashlytics

### Dans la console Firebase :

1. **Analytics** : Déjà activé lors de la création du projet ✅

2. **Crashlytics** :
   - Menu gauche : Cliquez sur **"Crashlytics"**
   - Cliquez sur **"Activer Crashlytics"**
   - Suivez les instructions (les dépendances sont déjà ajoutées dans pubspec.yaml)

---

## Étape 5 : Initialiser Firebase dans l'app

### Modifier main.dart :

Ouvrez `lib/main.dart` et ajoutez l'initialisation :

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:ryze_app/services/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== INITIALISER FIREBASE =====
  await Firebase.initializeApp();
  await AnalyticsService.initialize();
  // ================================

  // ... reste du code existant
  runApp(MyApp());
}
```

---

## Étape 6 : Installer les dépendances

```bash
# Installer les packages Flutter
flutter pub get

# Clean build (recommandé)
flutter clean

# iOS : Installer les pods
cd ios
pod install
cd ..

# Android : Gradle sync automatique
```

---

## Étape 7 : Tester l'intégration

### Test rapide :

```bash
# iOS
flutter run --dart-define-from-file=.env.local

# Android
flutter run --dart-define-from-file=.env.local
```

### Vérifier les logs :

Dans votre terminal, vous devriez voir :
```
✅ Firebase Analytics & Crashlytics initialized
```

### Tester un event :

Ajoutez temporairement dans votre code (par exemple dans `login_screen.dart` après login) :

```dart
import 'package:ryze_app/services/analytics_service.dart';

// Test
await AnalyticsService.logEvent('test_event', parameters: {
  'user': 'test_user',
  'timestamp': DateTime.now().toIso8601String(),
});
```

### Vérifier dans Firebase Console :

1. Console Firebase > Analytics > Events
2. Sélectionnez les dernières 30 minutes
3. Vous devriez voir vos events apparaître (délai : 1-24h pour la première fois)

### Mode Debug (temps réel) :

Pour voir les events immédiatement :

**iOS** :
```bash
# Activer le mode debug
flutter run --dart-define-from-file=.env.local --debug

# Ou via XCode scheme: Edit Scheme > Run > Arguments
# Add: -FIRDebugEnabled
```

**Android** :
```bash
# Activer le mode debug
adb shell setprop debug.firebase.analytics.app com.ryse.app

# Désactiver
adb shell setprop debug.firebase.analytics.app .none.
```

Ensuite, allez dans : Console Firebase > Analytics > **DebugView**

---

## Étape 8 : Tracking des events clés

Les events sont déjà configurés dans `analytics_service.dart`. Voici comment les utiliser :

### Exemple : Scanner un aliment

```dart
// Dans ai_scanner_screen.dart
await AnalyticsService.logFoodScanCamera(
  mealType: 'lunch',
  success: true,
);
```

### Exemple : Workout complété

```dart
// Dans workout_session_screen.dart
await AnalyticsService.logWorkoutCompleted(
  workoutType: 'strength',
  durationMinutes: 45,
  exerciseCount: 8,
  caloriesBurned: 320,
);
```

### Exemple : Widget interaction

```dart
// Dans widget_deep_link_handler.dart
await AnalyticsService.logWidgetInteraction(
  action: 'scan',
  widgetSize: 'medium',
);
```

---

## Étape 9 : Sécurité

### ⚠️ IMPORTANT : Ne pas commit les fichiers Firebase !

Vérifiez que `.gitignore` contient :

```gitignore
# Firebase
**/GoogleService-Info.plist
**/google-services.json
```

**Vérification** :
```bash
git status

# GoogleService-Info.plist et google-services.json ne doivent PAS apparaître
```

Si ils apparaissent :
```bash
git rm --cached ios/Runner/GoogleService-Info.plist
git rm --cached android/app/google-services.json
git commit -m "security: remove Firebase config files from tracking"
```

---

## Étape 10 : Déploiement TestFlight

### Build iOS avec Firebase :

```bash
# Build release
flutter build ios --release --dart-define-from-file=.env.production

# Archive dans XCode
# Product > Archive
# Upload to App Store Connect
```

### Vérifier les analytics :

1. Distribuez via TestFlight
2. Testeurs installent l'app
3. Console Firebase > Analytics > Events
4. Vous verrez les données des testeurs en temps réel ! 🎉

---

## Dashboard Analytics recommandés

### KPIs à suivre dans Firebase :

1. **Engagement** :
   - `food_scan_camera` vs `food_scan_barcode` vs `manual_food_entry`
   - `workout_completed` (par type)
   - `meal_widget_interaction` (nouvellement ajouté!)

2. **Retention** :
   - Utilisateurs actifs quotidiens (DAU)
   - Utilisateurs actifs hebdomadaires (WAU)
   - Taux de retention J1, J7, J30

3. **Features populaires** :
   - Écrans les plus visités (screen_view)
   - Features les plus utilisées (feature_used)

4. **Qualité** :
   - Crash-free users (Crashlytics)
   - Erreurs récurrentes

---

## Troubleshooting

### iOS : "FirebaseCore module not found"

```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### Android : "google-services.json not found"

Vérifiez le chemin : `android/app/google-services.json` (pas `android/`)

### Events n'apparaissent pas

- Attendez 24h pour la première synchro
- Utilisez DebugView pour le temps réel
- Vérifiez les logs : `flutter run` doit afficher "Firebase initialized"

### "Firebase not initialized"

Vérifiez que `Firebase.initializeApp()` est appelé AVANT `runApp()`

---

## Support & Ressources

- **Console Firebase** : https://console.firebase.google.com
- **Docs Flutter Firebase** : https://firebase.flutter.dev
- **Analytics Events Reference** : https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event

---

## Prochaines étapes

Une fois Firebase configuré :

1. ✅ Voir les statistics dans Firebase Console
2. ✅ Configurer des notifications basées sur les events
3. ✅ Créer des segments d'utilisateurs (power users, churned users, etc.)
4. ✅ Exporter les données vers BigQuery pour analyses avancées
5. ✅ Intégrer A/B testing avec Firebase Remote Config

**Bon tracking ! 📊🔥**
