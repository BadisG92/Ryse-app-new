# 🚀 Guide de Build TestFlight avec Widget iOS

## Vue d'ensemble

Ce guide explique comment builder et uploader l'app Ryse sur TestFlight avec le widget iOS `RyseMealWidgetExtension` inclus.

## ✅ Prérequis

Avant de commencer, vérifiez que vous avez :

- [ ] Xcode installé (14.0+)
- [ ] Flutter SDK installé
- [ ] Certificats Apple Developer configurés
- [ ] Accès à App Store Connect
- [ ] Le fichier `.env.production` configuré avec les bonnes clés API
- [ ] CocoaPods installé (`sudo gem install cocoapods`)

## 📋 Configuration vérifiée

### 1. Scheme Xcode

Le widget est **déjà configuré** dans le scheme Xcode :
- Fichier : `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
- Le target `RyseMealWidgetExtension` est inclus pour :
  - ✅ Build
  - ✅ Archive
  - ✅ Distribution

### 2. Targets Xcode

Vérifiez que ces 3 targets existent :
```bash
xcodebuild -list -project ios/Runner.xcodeproj
```

Doit afficher :
- ✅ Runner (app principale)
- ✅ RunnerTests
- ✅ RyseMealWidgetExtension (widget)

### 3. Widget Extension

Le widget est dans : `ios/RyseMealWidget/`
- ✅ `RyseMealWidget.swift` (widget principal)
- ✅ `RyseMealWidgetBundle.swift` (bundle)
- ✅ `Assets.xcassets` (assets du widget)
- ✅ `Info.plist` (configuration)

## 🛠️ Méthode 1 : Build avec Script (Recommandé)

### Étape 1 : Préparer l'environnement

```bash
# S'assurer que les clés API sont sécurisées
./check_api_keys.sh

# Vérifier que .env.production existe et contient les bonnes valeurs
cat .env.production
```

### Étape 2 : Lancer le build

```bash
# Build complet avec widget inclus
./build_testflight.sh
```

Le script va :
1. ✅ Vérifier `.env.production`
2. ✅ Vérifier la sécurité des clés API
3. ✅ Nettoyer le projet (`flutter clean`)
4. ✅ Nettoyer le cache Xcode
5. ✅ Installer les dépendances (`flutter pub get`)
6. ✅ Builder l'IPA avec l'environnement de production
7. ✅ Vérifier que le widget est inclus dans l'IPA

### Étape 3 : Vérifier le build

Après le build, le script affiche :
```
✅ Build réussi!
✅ Widget RyseMealWidgetExtension inclus dans l'IPA!
```

Si le widget n'est pas trouvé, voir la section "Troubleshooting".

## 🛠️ Méthode 2 : Build Manuel avec Flutter CLI

### Build l'IPA manuellement

```bash
# Clean
flutter clean
cd ios && rm -rf build/ && cd ..

# Get dependencies
flutter pub get

# Build IPA
flutter build ipa --release \
    --dart-define-from-file=.env.production \
    --export-options-plist=ios/ExportOptions.plist
```

### Vérifier que le widget est inclus

```bash
# Extraire l'IPA et vérifier
unzip -l build/ios/ipa/ryze_app.ipa | grep -i widget

# Doit afficher quelque chose comme :
# Payload/Runner.app/PlugIns/RyseMealWidgetExtension.appex/
```

## 🛠️ Méthode 3 : Build avec Xcode (Alternative)

### Étape 1 : Ouvrir le workspace

```bash
open ios/Runner.xcworkspace
```

### Étape 2 : Configurer le build

1. Sélectionner le scheme **Runner**
2. Product → Destination → **Any iOS Device (arm64)**
3. Product → Scheme → Edit Scheme
4. Vérifier dans "Build" que `RyseMealWidgetExtension` est coché pour **Archive**

### Étape 3 : Archiver

1. Product → Clean Build Folder (⌘⇧K)
2. Product → Archive (⌘B)
3. Attendre la fin du build (~5-10 minutes)

### Étape 4 : Distribuer

1. L'Organizer s'ouvre automatiquement
2. Cliquer sur **Distribute App**
3. Sélectionner **App Store Connect**
4. Suivre les étapes de distribution

## 📤 Upload sur TestFlight

Une fois le build terminé, vous avez 3 options :

### Option 1 : Transporter (Recommandé)

```bash
# Ouvrir Transporter
open -a Transporter

# Drag & drop le fichier
# build/ios/ipa/ryze_app.ipa
```

### Option 2 : Xcode Organizer

```bash
# Ouvrir les archives
open ~/Library/Developer/Xcode/Archives/

# Dans Xcode
# Window → Organizer → Distribute App → App Store Connect
```

### Option 3 : Command Line (API Key requis)

```bash
xcrun altool --upload-app --type ios \
    --file build/ios/ipa/ryze_app.ipa \
    --apiKey YOUR_API_KEY \
    --apiIssuer YOUR_ISSUER_ID
```

Pour obtenir l'API Key :
1. App Store Connect → Users and Access → Keys
2. Créer une clé avec le rôle "App Manager"
3. Télécharger le fichier `.p8`

## ✅ Vérification Post-Upload

### 1. App Store Connect

1. Se connecter à [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → Ryse → TestFlight
3. Attendre le traitement (~10-30 minutes)
4. Vérifier que le build apparaît avec le bon numéro de version

### 2. Vérifier le widget dans TestFlight

Une fois le build approuvé et installé :

1. Installer l'app depuis TestFlight sur un iPhone
2. Long press sur l'écran d'accueil → **+** (en haut à gauche)
3. Rechercher "Ryse"
4. Le widget **Ryse Meal Widget** doit apparaître en 2 tailles :
   - Small (pour Lock Screen)
   - Medium (pour Home Screen)

### 3. Tester le widget

1. Ajouter le widget Medium sur l'écran d'accueil
2. Vérifier que les données s'affichent correctement :
   - Nom du repas contextuel (Petit-déjeuner, Déjeuner, Dîner)
   - Progression des calories
   - 5 boutons d'action fonctionnels
3. Tester les deep links (taper sur les boutons)
4. Vérifier que les données se synchronisent avec l'app

## 🐛 Troubleshooting

### Le widget n'apparaît pas dans l'IPA

**Symptôme** : Le script affiche "⚠️ Warning: Widget non trouvé dans l'IPA!"

**Solutions** :
1. Ouvrir Xcode et vérifier le scheme :
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Product → Scheme → Edit Scheme
3. Onglet **Build**
4. Vérifier que `RyseMealWidgetExtension` a ces cases cochées :
   - [x] Build
   - [x] Archive
   - [x] Analyze

### Erreur "No profiles for 'com.BadisG.ryzeApp.RyseMealWidgetExtension'"

**Solution** :
1. Ouvrir Xcode
2. Sélectionner le target `RyseMealWidgetExtension`
3. Signing & Capabilities
4. Vérifier que "Automatically manage signing" est coché
5. Sélectionner le bon Team

### Le build Flutter échoue

**Solutions** :
```bash
# Clean complet
flutter clean
cd ios
rm -rf Pods/ Podfile.lock
pod deintegrate
pod install
cd ..

# Retry
./build_testflight.sh
```

### Le widget ne synchronise pas les données

**Solutions** :
1. Vérifier les App Groups dans Xcode :
   - Target `Runner` → Capabilities → App Groups → `group.com.BadisG.ryzeApp`
   - Target `RyseMealWidgetExtension` → Capabilities → App Groups → `group.com.BadisG.ryzeApp`

2. Vérifier le code de synchronisation :
   ```dart
   // lib/services/meal_widget_data_provider.dart
   ```

### Le build est trop lent

**Optimisations** :
```bash
# Utiliser plusieurs jobs
flutter build ipa --release --dart-define-from-file=.env.production -j 8

# Ou builder sans clean (si aucune modification majeure)
flutter build ipa --release --dart-define-from-file=.env.production --no-pub
```

## 📊 Checklist Complète

### Avant le build

- [ ] `.env.production` existe et contient les bonnes clés
- [ ] Tous les tests passent : `flutter test`
- [ ] Analyse statique OK : `flutter analyze`
- [ ] Version et build number incrémentés dans `pubspec.yaml`
- [ ] Certificats Apple Developer valides
- [ ] Xcode à jour

### Pendant le build

- [ ] Build réussit sans erreurs
- [ ] Widget trouvé dans l'IPA
- [ ] Taille de l'IPA raisonnable (~50-100 MB)

### Après l'upload

- [ ] Build apparaît dans App Store Connect
- [ ] Statut "Processing" → "Ready to Submit" / "Testing"
- [ ] Pas d'erreurs de validation
- [ ] Widget visible dans TestFlight
- [ ] Widget fonctionne correctement sur device

## 🔐 Sécurité

### Clés API

**IMPORTANT** : Ne jamais commiter les clés API !

```bash
# Vérifier avant chaque commit
./check_api_keys.sh

# S'assurer que .env.production est dans .gitignore
cat .gitignore | grep -i "env"
```

### Fichiers sensibles à exclure

- `.env.production`
- `.env.local`
- `ios/GoogleService-Info.plist` (si Firebase)
- `android/app/google-services.json` (si Firebase)
- Certificats `.p12`, `.mobileprovision`

## 📝 Notes

### Durée du build

- Flutter build : ~5-10 minutes
- Archive Xcode : ~10-15 minutes
- Upload : ~5-10 minutes
- Processing Apple : ~10-30 minutes

### Variables d'environnement

Le fichier `.env.production` doit contenir :
```bash
ENVIRONMENT=production
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
GEMINI_API_KEY=your_gemini_key
GOOGLE_VISION_API_KEY=your_vision_key
REVENUECAT_APPLE_API_KEY=your_revenuecat_key
```

### App Groups

Le widget utilise l'App Group pour partager les données :
- Group ID : `group.com.BadisG.ryzeApp`
- Partagé entre `Runner` et `RyseMealWidgetExtension`

## 🆘 Support

En cas de problème :

1. Vérifier les logs :
   ```bash
   flutter build ipa --release --dart-define-from-file=.env.production --verbose
   ```

2. Vérifier le scheme Xcode :
   ```bash
   cat ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme | grep -A 10 "RyseMealWidget"
   ```

3. Consulter la documentation :
   - [WIDGET_IMPLEMENTATION_SUMMARY.md](WIDGET_IMPLEMENTATION_SUMMARY.md)
   - [WIDGET_README.md](WIDGET_README.md)
   - [WIDGET_INSTALLATION_GUIDE.md](WIDGET_INSTALLATION_GUIDE.md)

## ✅ Succès !

Une fois le build uploadé avec succès, vous verrez :
- ✅ Build dans TestFlight prêt pour les tests
- ✅ Widget iOS fonctionnel
- ✅ Deep links opérationnels
- ✅ Synchronisation des données OK
- ✅ Prêt pour la distribution aux testeurs !

---

**Dernière mise à jour** : 2025-01-21
**Version** : 1.0.0
