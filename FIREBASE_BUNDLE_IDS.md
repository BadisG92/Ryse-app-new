# 📦 Bundle IDs & Package Names - Ryse App

## iOS

**Bundle Identifier principal** :
```
com.BadisG.ryzeApp
```

**Widget iOS** :
```
com.BadisG.ryzeApp.RyseMealWidget
```

**Trouvé dans** : `ios/Runner.xcodeproj/project.pbxproj`

---

## Android

**Application ID** :
```
com.example.ryze_app
```

**Trouvé dans** : `android/app/build.gradle.kts`

---

## 🔥 Configuration Firebase

Lors de la création de vos apps dans Firebase Console, utilisez **exactement** ces identifiants :

### iOS App
- **iOS Bundle ID** : `com.BadisG.ryzeApp`
- **Surnom** : Ryse App iOS

### Android App
- **Android Package** : `com.example.ryze_app`
- **Surnom** : Ryse App Android

---

## ⚠️ IMPORTANT

**Ces identifiants doivent correspondre EXACTEMENT** entre :
1. Votre projet natif (iOS/Android)
2. Firebase Console
3. Les fichiers de configuration Firebase (`GoogleService-Info.plist` et `google-services.json`)

**Sinon, l'app va crash au démarrage !** 🔥

---

## 📍 Vérification rapide

### iOS
```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ios/Runner/Info.plist
# Devrait afficher : $(PRODUCT_BUNDLE_IDENTIFIER)

grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1
# Devrait contenir : com.BadisG.ryzeApp
```

### Android
```bash
grep "applicationId" android/app/build.gradle.kts
# Devrait afficher : applicationId = "com.example.ryze_app"
```

---

**Date de vérification** : 2025-11-02
