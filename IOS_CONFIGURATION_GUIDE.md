# 📱 GUIDE DE CONFIGURATION iOS

## ⚠️ ACTIONS MANUELLES REQUISES DANS XCODE

Certaines modifications doivent être faites manuellement dans Xcode car elles touchent au fichier `.pbxproj` binaire.

---

## 1. 🔧 CORRIGER BUNDLE ID DES TESTS

### Problème Actuel
- **Production**: `com.BadisG.ryzeApp` ✅
- **Tests**: `com.example.ryzeApp.RunnerTests` ❌ (incohérent)

### Solution

1. **Ouvrir le projet dans Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Sélectionner le target RunnerTests**:
   - Cliquer sur le projet "Runner" dans la sidebar gauche
   - Sélectionner le target "RunnerTests" dans la liste

3. **Modifier le Bundle Identifier**:
   - Aller dans l'onglet "General"
   - Chercher "Bundle Identifier"
   - Changer de: `com.example.ryzeApp.RunnerTests`
   - À: `com.BadisG.ryzeApp.RunnerTests`

4. **Sauvegarder**: Cmd+S

---

## 2. 📜 CONFIGURER ENTITLEMENTS PRODUCTION

### Problème Actuel
- Les push notifications utilisent `development` même en production

### Solution

1. **Toujours dans Xcode**, sélectionner le target **Runner** (pas RunnerTests)

2. **Build Settings > Code Signing Entitlements**:

   **Pour Debug & Profile**:
   - Garder: `Runner/Runner.entitlements` (development)

   **Pour Release**:
   - Changer en: `Runner/Runner.production.entitlements` (production)

3. **Vérification**:
   - Debug: `Runner.entitlements` avec `aps-environment = development`
   - Release: `Runner.production.entitlements` avec `aps-environment = production`

---

## 3. 🔐 SIGNING & CAPABILITIES

### Vérifier la Configuration

1. **Target Runner > Signing & Capabilities**

2. **Automatic Signing** (Recommandé pour MVP):
   - ✅ Cocher "Automatically manage signing"
   - Sélectionner votre **Team** (Apple Developer Account)
   - Xcode générera automatiquement les profils

3. **Capabilities Activées** (déjà fait, juste vérifier):
   - ✅ Sign in with Apple
   - ✅ Push Notifications
   - ✅ HealthKit (si vous voulez utiliser)
   - ✅ Background Modes > Location updates
   - ✅ Associated Domains

4. **Si HealthKit pas utilisé**:
   - Décocher "HealthKit"
   - Supprimer les lignes HealthKit dans `Runner.entitlements`

---

## 4. 🏗️ BUILD CONFIGURATION

### Vérifier les Build Settings

1. **Product Bundle Identifier**:
   - Debug: `com.BadisG.ryzeApp`
   - Release: `com.BadisG.ryzeApp`

2. **Code Signing Identity**:
   - Debug: Apple Development
   - Release: Apple Distribution

3. **Provisioning Profile**:
   - Laisser "Automatic" si vous utilisez auto-signing
   - Sinon, sélectionner vos profils manuellement

---

## 5. ✅ CHECKLIST FINALE

Avant de builder pour production:

### Dans Xcode
- [ ] Bundle ID tests corrigé: `com.BadisG.ryzeApp.RunnerTests`
- [ ] Entitlements production configuré pour Release
- [ ] Team sélectionnée dans Signing
- [ ] Tous les capabilities nécessaires activées
- [ ] Build réussit sans erreurs

### Dans Terminal
- [ ] Variables d'environnement créées (`.env.local` et `.env.production`)
- [ ] Anciennes clés API révoquées
- [ ] Nouvelles clés générées et mises dans `.env.production`

---

## 6. 🚀 BUILD POUR PRODUCTION

### Commandes

```bash
# 1. Clean complet
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..

# 2. Build avec variables d'environnement PRODUCTION
flutter build ios --release \
  --dart-define-from-file=.env.production

# 3. Archiver dans Xcode
open ios/Runner.xcworkspace

# Dans Xcode:
# Product > Archive
# Attendre la fin (5-10 min)
# Distribute App > App Store Connect
```

### Build de Test (Development)

```bash
# Pour tester en mode dev
flutter run --dart-define-from-file=.env.local
```

---

## 7. 🆘 TROUBLESHOOTING

### "No such file or directory: .env.local"

**Problème**: Le fichier `.env.local` n'existe pas

**Solution**:
```bash
cp .env.example .env.local
# Puis éditer .env.local avec vos vraies clés
```

### "Code Signing Error"

**Problème**: Profils ou certificats manquants

**Solution**:
1. Xcode > Preferences > Accounts
2. Télécharger les profils manuels si besoin
3. Ou activer "Automatically manage signing"

### "Entitlements file not found"

**Problème**: Le fichier `Runner.production.entitlements` n'est pas trouvé

**Solution**:
1. Vérifier que le fichier existe dans `ios/Runner/`
2. Dans Xcode, faire "Add Files to Runner"
3. Sélectionner `Runner.production.entitlements`

---

## 8. 📝 NOTES IMPORTANTES

### Associated Domains

Si vous n'avez PAS le domaine `ryze-app.com`:
- Retirer la capability "Associated Domains"
- Ou changer pour un domaine que vous possédez

### HealthKit

Si vous n'utilisez PAS HealthKit:
- Décocher la capability
- Retirer les permissions dans `Info.plist`:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`
- Retirer l'entitlement `com.apple.developer.healthkit`

### Push Notifications

Si vous n'utilisez PAS encore les push:
- Garder la capability (pour plus tard)
- Juste ne pas envoyer de notifications

---

## 9. 🧪 TESTER LA CONFIGURATION

### Test 1: Variables d'Environnement

```bash
flutter run --dart-define-from-file=.env.local
```

Vérifier dans les logs au démarrage:
```
🔧 Environment Configuration:
  Environment: development
  Test Mode: true
  ...
```

### Test 2: Build Release

```bash
flutter build ios --release --dart-define-from-file=.env.production
```

Doit réussir sans erreurs.

### Test 3: Test Mode

En `.env.local` (dev): `TEST_MODE=true` → Trial gratuit
En `.env.production`: `TEST_MODE=false` → Vrais paiements

---

**Bon build! 🚀**
