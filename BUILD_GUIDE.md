# 🚀 GUIDE DE BUILD - RYZE APP

## ⚠️ IMPORTANT: MIGRATION VERS VARIABLES D'ENVIRONNEMENT

Les clés API ne sont plus hardcodées dans le code. Elles sont maintenant chargées via `--dart-define-from-file`.

---

## 📋 PRÉREQUIS

### 1. Révoquer les Anciennes Clés

**Google Cloud Console** (https://console.cloud.google.com):
```
APIs & Services > Credentials
1. Supprimer les anciennes clés Gemini et Google Vision
2. Créer de nouvelles clés avec restrictions:
   - Application: iOS (bundle: com.BadisG.ryzeApp)
   - APIs: Gemini API, Cloud Vision API
3. Noter les nouvelles clés
```

**Supabase Dashboard** (https://supabase.com/dashboard):
```
Project Settings > API
1. Cliquer "Reset anon key"
2. Confirmer
3. Noter la nouvelle clé
```

### 2. Configurer les Variables d'Environnement

**Éditer `.env.local` (Development)**:
```bash
# Ouvrir le fichier
code .env.local

# Remplacer les valeurs:
SUPABASE_URL=https://mfskwlzgxjhhknlwpblq.supabase.co
SUPABASE_ANON_KEY=VOTRE_NOUVELLE_CLE_SUPABASE

GEMINI_API_KEY=VOTRE_NOUVELLE_CLE_GEMINI

GOOGLE_VISION_API_KEY=VOTRE_NOUVELLE_CLE_VISION

# Garder les valeurs OAuth (déjà bonnes)
GOOGLE_CLIENT_ID=992101491811-meask250jrb56gkpmkqkqs4gu3i9isn6.apps.googleusercontent.com
```

**Éditer `.env.production` (Production)**:
```bash
# Ouvrir le fichier
code .env.production

# Même chose mais avec:
TEST_MODE=false   # ⚠️ IMPORTANT pour activer vrais paiements
ENABLE_DEBUG_LOGS=false
```

---

## 🏗️ BUILDS

### Development (Testing Local)

```bash
# Clean
flutter clean
flutter pub get

# Run avec variables d'environnement DEV
flutter run --dart-define-from-file=.env.local

# Vérifier dans les logs au démarrage:
# 🔧 Environment Configuration:
#   Environment: development
#   Test Mode: true
#   ...
```

### Staging (Pre-Production)

Si vous avez un environnement staging:

```bash
# Créer .env.staging (copie de .env.production)
cp .env.production .env.staging

# Build
flutter build ios --release --dart-define-from-file=.env.staging
```

### Production (App Store)

```bash
# 1. NETTOYER COMPLÈTEMENT
flutter clean
rm -rf ios/Pods
rm ios/Podfile.lock
rm -rf ios/.symlinks

# 2. RÉINSTALLER DÉPENDANCES
flutter pub get
cd ios
pod install
cd ..

# 3. BUILD IOS AVEC VARIABLES PRODUCTION
flutter build ios --release \
  --dart-define-from-file=.env.production \
  --no-codesign

# 4. ARCHIVE DANS XCODE
open ios/Runner.xcworkspace
```

**Dans Xcode**:
1. Product > Scheme > Edit Scheme
2. Run > Build Configuration > **Release**
3. Product > Clean Build Folder (Cmd+Shift+K)
4. Product > Archive
5. Attendre 5-10 min
6. Window > Organizer > Distribute App > App Store Connect
7. Upload

---

## 🧪 TESTER LA CONFIGURATION

### Test 1: Variables Chargées Correctement

```bash
flutter run --dart-define-from-file=.env.local
```

**Chercher dans les logs**:
```
✅ Supabase URL: ✅ https://...
✅ Supabase Key: ✅ eyJhbGci...
✅ Gemini Key: ✅ AIzaSy...
✅ Vision Key: ✅ AIzaSy...
```

Si vous voyez `❌ NOT SET` → Vérifiez votre `.env.local`

### Test 2: Test Mode Fonctionne

**En `.env.local`** (dev):
```bash
TEST_MODE=true
```
→ Trial gratuit donné automatiquement

**En `.env.production`**:
```bash
TEST_MODE=false
```
→ Vrais paiements via StoreKit

**Vérifier**:
```dart
// Dans l'app, aller dans Paramètres
// Devrait afficher: "Mode Test: OFF" en production
```

### Test 3: APIs Fonctionnent

1. **Scanner IA**:
   - Prendre photo d'un repas
   - Doit analyser et retourner calories

2. **Login**:
   - Se connecter avec email
   - Se connecter avec Google (si configuré)
   - Se connecter avec Apple

3. **Abonnement** (sandbox):
   - Aller dans Pricing
   - Tester achat Premium
   - Utiliser testeur sandbox

---

## 🔧 TROUBLESHOOTING

### "No such file: .env.local"

**Erreur**:
```
Error: Unable to load --dart-define-from-file at .env.local
```

**Solution**:
```bash
# Vérifier que le fichier existe
ls -la .env.local

# Si n'existe pas:
cp .env.example .env.local
# Puis éditer avec vos clés
```

### "Environment variables not set"

**Erreur**:
```
❌ Missing required environment variables: GEMINI_API_KEY
```

**Solution**:
```bash
# Vérifier le contenu de .env.local
cat .env.local

# S'assurer qu'il n'y a pas d'espaces:
# ✅ BON: GEMINI_API_KEY=AIza...
# ❌ MAUVAIS: GEMINI_API_KEY = AIza... (espaces)
```

### "Configuration Exception"

**Erreur**:
```
ConfigurationException: Missing required environment variables
```

**Solution**:
1. Ouvrir `lib/config/env_config.dart`
2. Vérifier quelles variables sont requises
3. Les ajouter dans `.env.local`

### Build iOS Échoue

**Erreur**:
```
Code Signing Error
```

**Solution**:
1. Ouvrir `ios/Runner.xcworkspace` dans Xcode
2. Target Runner > Signing & Capabilities
3. Sélectionner votre **Team**
4. Cocher "Automatically manage signing"

---

## 📱 TESTER SUR DEVICE PHYSIQUE

### Via Xcode (Recommandé)

```bash
# 1. Build
flutter build ios --release --dart-define-from-file=.env.local

# 2. Ouvrir Xcode
open ios/Runner.xcworkspace

# 3. Connecter iPhone via USB

# 4. Sélectionner votre iPhone en haut

# 5. Product > Run (ou Cmd+R)
```

### Via Flutter Directement

```bash
# Connecter iPhone

# Lister devices
flutter devices

# Run sur iPhone
flutter run --dart-define-from-file=.env.local -d <device-id>
```

---

## 🎯 CHECKLIST PRE-PRODUCTION

Avant de builder pour App Store:

### Environnement
- [ ] Fichier `.env.production` créé
- [ ] `TEST_MODE=false` dans `.env.production`
- [ ] `ENABLE_DEBUG_LOGS=false` dans `.env.production`
- [ ] Nouvelles clés API (révoquées les anciennes)
- [ ] Testé avec `.env.production` localement

### iOS
- [ ] Bundle ID tests corrigé dans Xcode
- [ ] Entitlements production configuré
- [ ] Team sélectionnée
- [ ] Certificats valides
- [ ] Build réussit sans erreurs

### App Store Connect
- [ ] App créée
- [ ] Métadonnées remplies
- [ ] Screenshots uploadés
- [ ] Privacy Policy en ligne
- [ ] Compte démo créé

---

## 📊 COMMANDES UTILES

### Analyser le Code

```bash
# Linter
flutter analyze

# Formater
flutter format lib/ --line-length 100

# Tests
flutter test

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Nettoyer

```bash
# Clean Flutter
flutter clean

# Clean iOS
cd ios
rm -rf Pods Podfile.lock .symlinks
pod cache clean --all
pod install
cd ..

# Clean tout
flutter clean && flutter pub get && cd ios && pod install && cd ..
```

### Vérifier Dépendances

```bash
# Outdated packages
flutter pub outdated

# Update (attention aux breaking changes)
flutter pub upgrade

# Specific package
flutter pub upgrade supabase_flutter
```

---

## 🚨 ERREURS COURANTES

### 1. "Supabase not initialized"

**Cause**: App lance sans connection, Supabase timeout

**Solution**: Normal en mode offline, l'app continue

### 2. "Invalid API key"

**Cause**: Clé révoquée ou mal copiée

**Solution**: Vérifier `.env.local`, regénérer clé

### 3. "Code signing failed"

**Cause**: Certificats/provisioning profiles

**Solution**: Xcode > Preferences > Accounts > Download Manual Profiles

### 4. "Build input file cannot be found"

**Cause**: Fichiers manquants après clean

**Solution**:
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

---

## 📚 RESSOURCES

**Documentation Flutter**:
- dart-define: https://flutter.dev/docs/deployment/flavors
- iOS build: https://docs.flutter.dev/deployment/ios

**Supabase**:
- Dashboard: https://supabase.com/dashboard
- Docs: https://supabase.com/docs

**Google Cloud**:
- Console: https://console.cloud.google.com
- Gemini API: https://ai.google.dev/
- Vision API: https://cloud.google.com/vision

---

**Version**: 2.0 (avec EnvConfig)
**Date**: Octobre 2025
**Auteur**: Ryze Team
