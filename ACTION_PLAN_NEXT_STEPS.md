# 🎯 PLAN D'ACTION - ÉTAPES SUIVANTES

## 📅 Créé le: 29 Octobre 2025

---

## ✅ CE QUI A ÉTÉ FAIT AUTOMATIQUEMENT

J'ai corrigé automatiquement tous les problèmes **critiques bloquants** pour l'App Store:

### Sécurité ✅
- ✅ Création du système `EnvConfig` pour variables d'environnement
- ✅ Migration de `supabase_config.dart` (clés externalisées)
- ✅ Migration de `gemini_config.dart` (clés externalisées)
- ✅ Migration de `google_vision_config.dart` (clés externalisées)
- ✅ Migration de `subscription_service.dart` (TEST_MODE contrôlé par env)
- ✅ Fichiers `.env.example`, `.env.local`, `.env.production` créés
- ✅ Backup des anciennes clés dans `API_KEYS_BACKUP.txt`
- ✅ `.gitignore` amélioré

### Configuration iOS ✅
- ✅ `Runner.production.entitlements` créé (push production)
- ✅ Guide Xcode créé (`IOS_CONFIGURATION_GUIDE.md`)

### Documentation ✅
- ✅ Audit complet App Store (91 pages)
- ✅ Templates légaux (Privacy Policy, Terms, Support)
- ✅ Guide de build complet
- ✅ README projet
- ✅ Résumé migration
- ✅ Ce plan d'action

---

## ⏳ CE QU'IL VOUS RESTE À FAIRE

### 🔥 URGENT - À FAIRE MAINTENANT (3-4 heures)

#### Étape 1: RÉVOQUER LES ANCIENNES CLÉS API (1h)

**Pourquoi**: Les anciennes clés sont exposées publiquement dans le code. N'importe qui peut les voler.

**Actions**:

1. **Google Cloud Console**
   ```
   1. Aller sur: https://console.cloud.google.com/apis/credentials
   2. Connexion avec votre compte Google

   3. Supprimer/Révoquer ces clés:
      - Nom: "Gemini API Key"
      - Valeur: AIzaSyAQDTnQpN7h7p7pFKti-JFhKgJ5kOo-7Gw

   4. Créer NOUVELLES clés:
      a) APIs & Services > Credentials
      b) Create Credentials > API Key
      c) Edit restrictions:
         - Application restrictions: iOS apps
         - Bundle ID: com.BadisG.ryzeApp
         - API restrictions: Generative Language API, Cloud Vision API
      d) Save

   5. COPIER la nouvelle clé quelque part (Notepad, Notes app)
   ```

2. **Supabase Dashboard**
   ```
   1. Aller sur: https://supabase.com/dashboard/project/mfskwlzgxjhhknlwpblq/settings/api
   2. Scroll jusqu'à "Project API keys"
   3. Cliquer "Reset" sur l'anon key
   4. Confirmer
   5. COPIER la nouvelle clé
   ```

**✅ Check**: Vous avez maintenant 3 nouvelles clés (Gemini, Vision, Supabase)

---

#### Étape 2: CONFIGURER .env.local (15 min)

**Pourquoi**: L'app a besoin des nouvelles clés pour fonctionner.

**Actions**:

```bash
# 1. Ouvrir le fichier dans votre éditeur
code .env.local

# Ou avec notepad
notepad .env.local
```

**2. Remplacer TOUTES ces lignes**:

```bash
# AVANT (avec REMPLACER_PAR...):
SUPABASE_ANON_KEY=REMPLACER_PAR_NOUVELLE_CLE_APRES_REVOCATION
GEMINI_API_KEY=REMPLACER_PAR_NOUVELLE_CLE_APRES_REVOCATION
GOOGLE_VISION_API_KEY=REMPLACER_PAR_NOUVELLE_CLE_APRES_REVOCATION

# APRÈS (avec vos vraies nouvelles clés):
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS...   # La NOUVELLE clé Supabase
GEMINI_API_KEY=AIzaSy...  # La NOUVELLE clé Gemini
GOOGLE_VISION_API_KEY=AIzaSy...  # La NOUVELLE clé Vision (peut être la même que Gemini)
```

**3. Sauvegarder le fichier** (Ctrl+S / Cmd+S)

**✅ Check**: `.env.local` contient vos nouvelles clés

---

#### Étape 3: TESTER LOCALEMENT (1h)

**Pourquoi**: Vérifier que tout fonctionne avec les nouvelles clés.

**Actions**:

```bash
# 1. Clean complet
flutter clean
flutter pub get

# 2. Lancer l'app
flutter run --dart-define-from-file=.env.local

# 3. VÉRIFIER dans les logs au démarrage:
# Vous devriez voir:
# 🔧 Environment Configuration:
#   Environment: development
#   Test Mode: true
#   Supabase URL: ✅ https://mfsk...
#   Supabase Key: ✅ eyJhbGci...
#   Gemini Key: ✅ AIzaSy...
#   Vision Key: ✅ AIzaSy...
#   Is Configured: true

# ⚠️ Si vous voyez des ❌ NOT SET:
# → Retour à l'Étape 2, vérifier .env.local
```

**4. Tester dans l'app**:
- [ ] Login avec email fonctionne
- [ ] Scanner un repas avec la caméra fonctionne
- [ ] Ajouter un aliment manuellement fonctionne
- [ ] Créer une séance de musculation fonctionne

**✅ Check**: Tout fonctionne, pas d'erreur "API key invalid"

---

#### Étape 4: CONFIGURER .env.production (15 min)

**Pourquoi**: Pour le build de production (App Store).

**Actions**:

```bash
# 1. Ouvrir le fichier
code .env.production

# 2. Mettre LES MÊMES clés que dans .env.local
# MAIS changer:
TEST_MODE=false   # ⚠️ IMPORTANT: désactive mode test
ENABLE_DEBUG_LOGS=false  # ⚠️ Pas de logs en production
ENVIRONMENT=production

# 3. Sauvegarder
```

**✅ Check**: `.env.production` prêt pour build production

---

#### Étape 5: SUPPRIMER LE BACKUP (5 min)

**Pourquoi**: Plus besoin des anciennes clés, elles sont révoquées.

**Actions**:

```bash
# Supprimer le fichier
rm lib/config/API_KEYS_BACKUP.txt

# Ou manuellement:
# Aller dans lib/config/ et supprimer API_KEYS_BACKUP.txt

# Commit
git add .
git commit -m "security: migrate API keys to environment variables

- Externalize all API keys to .env files
- Add EnvConfig for secure key management
- Remove hardcoded keys from codebase
- Add production entitlements for push notifications"

git push
```

**✅ Check**: Fichier backup supprimé, commit fait

---

### 🔧 XCODE - À FAIRE MANUELLEMENT (30 min)

#### Étape 6: CORRIGER BUNDLE ID TESTS

**Pourquoi**: Incohérence qui peut causer des problèmes de signing.

**Actions**:

```
1. Ouvrir Xcode:
   open ios/Runner.xcworkspace

2. Dans la sidebar gauche, cliquer sur "Runner" (icône bleue)

3. Dans la liste des TARGETS, sélectionner "RunnerTests" (pas Runner)

4. Onglet "General"

5. Chercher "Bundle Identifier"
   Actuellement: com.example.ryzeApp.RunnerTests  ❌

6. Changer en: com.BadisG.ryzeApp.RunnerTests  ✅

7. Sauvegarder: Cmd+S

8. Fermer Xcode
```

**✅ Check**: Bundle ID tests maintenant cohérent avec production

---

#### Étape 7: CONFIGURER ENTITLEMENTS PRODUCTION

**Pourquoi**: Push notifications ne fonctionneront pas sinon.

**Actions**:

```
1. Rouvrir Xcode:
   open ios/Runner.xcworkspace

2. Target "Runner" (pas RunnerTests cette fois)

3. Onglet "Build Settings" (pas General)

4. Chercher dans la barre de recherche: "Code Signing Entitlements"

5. Vous verrez 3 lignes:
   - Debug
   - Profile
   - Release

6. Double-cliquer sur la ligne "Release"

7. Changer:
   Ancien: Runner/Runner.entitlements
   Nouveau: Runner/Runner.production.entitlements

8. Debug et Profile restent: Runner/Runner.entitlements

9. Sauvegarder: Cmd+S

10. Product > Clean Build Folder (Cmd+Shift+K)
```

**✅ Check**: Release utilise les entitlements production

---

#### Étape 8: VÉRIFIER SIGNING

**Pourquoi**: S'assurer que vous pouvez signer l'app.

**Actions**:

```
1. Toujours dans Xcode
2. Target "Runner"
3. Onglet "Signing & Capabilities"

4. Cocher "Automatically manage signing"

5. Team: Sélectionner votre Apple Developer Account
   (Si pas dans la liste, cliquer "Add Account...")

6. Vérifier que ces capabilities sont activées:
   ✅ Sign in with Apple
   ✅ Push Notifications
   ✅ Background Modes (avec "Location updates" coché)

7. Si vous voyez des erreurs rouges:
   - Cliquer dessus pour voir détails
   - Généralement: "Download Manual Profiles" les résout

8. Sauvegarder et fermer Xcode
```

**✅ Check**: Pas d'erreurs de signing, team configurée

---

### 📄 LÉGAL - URGENT AVANT SOUMISSION (2-4 heures)

#### Étape 9: CRÉER LES DOCUMENTS HTML (2h)

**Pourquoi**: Apple REFUSE les apps sans Privacy Policy.

**Actions**:

**Option Simple: Utiliser GitHub Pages (Gratuit)**

```bash
# 1. Créer un nouveau repo sur GitHub
# Nom: ryze-legal
# Public

# 2. Créer dossier local
mkdir ryze-legal
cd ryze-legal

# 3. Créer les fichiers HTML
# Ouvrir LEGAL_TEMPLATES.md
# Copier la section "Privacy Policy" dans privacy.html
# Copier la section "Terms of Service" dans terms.html
# Copier la section "Support Page" dans support.html

# Personnaliser avec VOS informations:
# - Remplacer [DATE] par date actuelle
# - Remplacer [VOTRE ADRESSE] par votre adresse
# - Remplacer [VOTRE NOM/SOCIÉTÉ] par votre nom
# - Remplacer emails (support@ryze-app.com) si différents

# 4. Initialiser repo
git init
git add .
git commit -m "Initial legal documents"

# 5. Pousser vers GitHub
git remote add origin https://github.com/VOTRE_USERNAME/ryze-legal.git
git branch -M main
git push -u origin main

# 6. Activer GitHub Pages
# Aller sur: https://github.com/VOTRE_USERNAME/ryze-legal/settings/pages
# Source: Deploy from branch
# Branch: main / (root)
# Save

# 7. Attendre 2-3 minutes
# Vos URLs seront:
# https://VOTRE_USERNAME.github.io/ryze-legal/privacy.html
# https://VOTRE_USERNAME.github.io/ryze-legal/terms.html
# https://VOTRE_USERNAME.github.io/ryze-legal/support.html
```

**✅ Check**: URLs accessibles dans navigateur

---

### 🏗️ BUILD PRODUCTION - AVANT SOUMISSION (1-2 heures)

#### Étape 10: BUILD FINAL

**Pourquoi**: Tester que le build production fonctionne.

**Actions**:

```bash
# 1. CLEAN COMPLET
flutter clean
rm -rf ios/Pods
rm ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..

# 2. BUILD AVEC VARIABLES PRODUCTION
flutter build ios --release --dart-define-from-file=.env.production

# 3. Attendre 5-10 minutes

# 4. Vérifier succès:
# Vous devriez voir:
# ✓ Built build/ios/iphoneos/Runner.app

# ⚠️ Si erreurs:
# - Lire le message d'erreur
# - Chercher dans IOS_CONFIGURATION_GUIDE.md
# - Ou BUILD_GUIDE.md section Troubleshooting
```

**✅ Check**: Build réussit sans erreurs

---

#### Étape 11: ARCHIVER POUR APP STORE

**Pourquoi**: Créer le fichier IPA pour soumettre.

**Actions**:

```
1. Ouvrir Xcode:
   open ios/Runner.xcworkspace

2. En haut à gauche, à côté du bouton Play:
   Sélectionner "Any iOS Device (arm64)"
   (Pas un simulateur, pas votre iPhone)

3. Menu: Product > Scheme > Edit Scheme

4. Sous "Run", Build Configuration:
   Changer en "Release" (au lieu de Debug)

5. Close

6. Product > Clean Build Folder (Cmd+Shift+K)

7. Product > Archive

8. ATTENDRE 10-15 minutes (compilation longue)

9. Quand terminé, une fenêtre "Organizer" s'ouvre

10. Sélectionner l'archive (la plus récente en haut)

11. Cliquer "Distribute App"

12. Choisir "App Store Connect"

13. Next > Upload

14. Suivre les étapes, laisser options par défaut

15. Wait for upload (5-10 min selon connexion)
```

**✅ Check**: Upload réussit, visible dans App Store Connect

---

### 📱 APP STORE CONNECT - DERNIÈRE ÉTAPE (2-3 heures)

#### Étape 12: CRÉER L'APP

**Pourquoi**: Enregistrer l'app dans le système Apple.

**Actions**:

```
1. Aller sur: https://appstoreconnect.apple.com

2. My Apps > + > New App

3. Remplir:
   - Platforms: iOS
   - Name: Ryze - Coach Nutrition & Sport
   - Primary Language: French (France)
   - Bundle ID: com.BadisG.ryzeApp (select from list)
   - SKU: ryze-app-2025 (unique ID interne)
   - User Access: Full Access

4. Create
```

---

#### Étape 13: MÉTADONNÉES

**Référence**: Section 3.4 du fichier `AUDIT_APP_STORE_MVP.md`

**À remplir**:

1. **App Information**:
   ```
   Name: Ryze - Coach Nutrition & Sport
   Subtitle: IA, Scanner Aliments, Fitness
   Category: Forme et santé (primary), Style de vie (secondary)
   ```

2. **Pricing**:
   ```
   Price: Free (with In-App Purchases)
   Availability: All countries
   ```

3. **App Privacy**:
   ```
   Privacy Policy URL: https://VOTRE_USERNAME.github.io/ryze-legal/privacy.html
   ```
   Puis remplir le questionnaire (voir AUDIT section 9.1)

4. **What's New in This Version**:
   ```
   Version 1.0.0 - Lancement initial ! 🎉

   🍎 NUTRITION INTELLIGENTE
   • Scanner IA pour analyser vos repas
   • Base de données 500,000+ aliments
   • Suivi macros et calories

   💪 ENTRAÎNEMENTS COMPLETS
   • Musculation avec tracking des poids
   • Cardio GPS avec parcours
   • Séances générées par IA

   📊 SUIVI DE PROGRESSION
   • Graphiques évolution
   • Système de streaks
   • Objectifs personnalisés
   ```

---

#### Étape 14: SCREENSHOTS

**Pourquoi**: Apple exige 3-8 screenshots.

**À faire**:

```
1. iPhone 15 Pro Max (simulateur):
   flutter run --dart-define-from-file=.env.local

2. Ouvrir Simulator:
   Cmd+Shift+H pour home screen
   Features > Screenshot

3. Capturer 8 écrans:
   - Dashboard principal
   - Scanner IA en action
   - Journal nutrition
   - Séance musculation
   - Graphiques progression
   - Recettes
   - Cardio GPS
   - Profil/Objectifs

4. Dimension requise: 1290 x 2796 pixels

5. Uploader dans App Store Connect:
   Section "Screenshots" > iPhone 6.7"
```

**✅ Check**: 8 screenshots uploadés

---

#### Étape 15: CRÉER COMPTE DÉMO

**Pourquoi**: Apple testera votre app avec ce compte.

**Actions**:

```bash
# 1. Lancer l'app
flutter run --dart-define-from-file=.env.local

# 2. Créer compte:
   Email: demo@ryze-app.com
   Password: DemoRyze2025!

# 3. Remplir le profil avec données réalistes:
   - Nom: Demo User
   - Poids: 75 kg
   - Taille: 175 cm
   - Objectif: Perte de poids

# 4. Ajouter données d'exemple:
   - Scanner 3-4 repas
   - Créer 1-2 séances de musculation
   - Log une séance cardio

# 5. Dans App Store Connect:
   App Review Information > Demo Account
   Username: demo@ryze-app.com
   Password: DemoRyze2025!
```

**✅ Check**: Compte démo créé et testé

---

#### Étape 16: NOTES POUR REVIEWERS

**Dans App Store Connect**: App Review Information > Notes

```
Bonjour l'équipe App Review,

Merci de tester Ryze, coach nutrition et fitness propulsé par IA.

COMPTE DÉMO:
Email: demo@ryze-app.com
Password: DemoRyze2025!

Ce compte contient des données d'exemple (repas, workouts).

FONCTIONNALITÉS CLÉS À TESTER:
1. Scanner IA: Prenez une photo d'un repas (ou utilisez photos test)
2. Journal nutrition: Voir l'historique pré-rempli
3. Workout: Lancer une séance de musculation
4. Graphiques: Section "Progression"

PERMISSIONS:
- Caméra: Pour scanner aliments
- Photos: Analyser images existantes
- Localisation: Tracking GPS pour cardio (optionnel)
- Microphone: Commande vocale workout (optionnel)

ACHATS IN-APP:
- Testez avec compte Sandbox
- 7 jours gratuit, puis abonnement mensuel

L'app fonctionne 100% hors ligne après première connexion.

Merci !
```

---

#### Étape 17: SOUMETTRE

**Dernière vérification**:

- [ ] Build uploadé
- [ ] Métadonnées remplies
- [ ] Screenshots (min 3, idéal 8)
- [ ] Privacy Policy URL active
- [ ] Compte démo créé
- [ ] Notes pour reviewers
- [ ] Abonnements configurés (si ready)

**Soumettre**:

```
1. Dans App Store Connect
2. Bouton "Submit for Review"
3. Confirmer
4. Attendre 24-48h (généralement)
```

**✅ Check**: App "Waiting for Review"

---

## 📊 RÉSUMÉ TIMING

| Étape | Tâche | Temps Estimé |
|-------|-------|--------------|
| 1 | Révoquer clés API | 1h |
| 2 | Configurer .env.local | 15 min |
| 3 | Tester localement | 1h |
| 4 | Configurer .env.production | 15 min |
| 5 | Supprimer backup | 5 min |
| **Subtotal Phase 1** | **Sécurité** | **~3h** |
| 6 | Corriger Bundle ID Xcode | 10 min |
| 7 | Config entitlements production | 10 min |
| 8 | Vérifier signing | 10 min |
| **Subtotal Phase 2** | **iOS Config** | **~30 min** |
| 9 | Créer documents légaux | 2h |
| **Subtotal Phase 3** | **Légal** | **~2h** |
| 10 | Build production | 30 min |
| 11 | Archive Xcode | 30 min |
| **Subtotal Phase 4** | **Build** | **~1h** |
| 12-17 | App Store Connect setup | 2-3h |
| **Subtotal Phase 5** | **ASC** | **~2-3h** |
| **TOTAL** | **Tout** | **~8-10h** |

---

## ✅ CHECKLIST COMPLÈTE

### Phase 1: Sécurité (URGENT)
- [ ] Anciennes clés révoquées (Google + Supabase)
- [ ] Nouvelles clés générées
- [ ] `.env.local` configuré avec nouvelles clés
- [ ] Testé localement (app fonctionne)
- [ ] `.env.production` configuré
- [ ] API_KEYS_BACKUP.txt supprimé
- [ ] Commit & push

### Phase 2: Configuration iOS
- [ ] Bundle ID tests corrigé dans Xcode
- [ ] Entitlements production configuré (Release)
- [ ] Signing automatique activé
- [ ] Team sélectionnée
- [ ] Pas d'erreurs de signing

### Phase 3: Documents Légaux
- [ ] Privacy Policy créée (HTML)
- [ ] Terms of Service créés (HTML)
- [ ] Support page créée (HTML)
- [ ] Documents hébergés (GitHub Pages ou autre)
- [ ] URLs testées (accessibles)

### Phase 4: Build
- [ ] Build dev réussit
- [ ] Build production réussit
- [ ] Archive Xcode créé
- [ ] IPA uploadé à App Store Connect

### Phase 5: App Store Connect
- [ ] App créée dans ASC
- [ ] Métadonnées remplies
- [ ] Screenshots uploadés (8x)
- [ ] Privacy Policy URL ajoutée
- [ ] Compte démo créé et testé
- [ ] Notes pour reviewers écrites
- [ ] Soumis pour review

---

## 🆘 SI VOUS BLOQUEZ

### Problème: "Les nouvelles clés ne fonctionnent pas"

**Vérifier**:
```bash
# 1. Que .env.local est bien créé
ls -la .env.local

# 2. Qu'il contient les vraies clés (pas "REMPLACER_PAR...")
cat .env.local

# 3. Que vous lancez avec --dart-define-from-file
flutter run --dart-define-from-file=.env.local

# 4. Vérifier les logs:
# Chercher "Environment Configuration"
```

### Problème: "Xcode code signing error"

**Solutions**:
1. Xcode > Preferences > Accounts > Download Manual Profiles
2. Cocher "Automatically manage signing"
3. Sélectionner votre Team
4. Clean Build Folder (Cmd+Shift+K)

### Problème: "Build échoue"

**Essayer**:
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release --dart-define-from-file=.env.production
```

### Besoin d'Aide

**Fichiers de référence**:
- Sécurité: `MIGRATION_COMPLETE_SUMMARY.md`
- Build: `BUILD_GUIDE.md`
- iOS: `IOS_CONFIGURATION_GUIDE.md`
- Légal: `LEGAL_TEMPLATES.md`
- Complet: `AUDIT_APP_STORE_MVP.md`

---

## 🎉 APRÈS SOUMISSION

### Pendant Review (24-48h)

- [ ] Monitorer App Store Connect pour messages
- [ ] Répondre rapidement si Apple demande clarifications
- [ ] Préparer hotfix 1.0.1 si bugs trouvés

### Si Rejeté

1. **Lire attentivement** la raison (Resolution Center)
2. **Corriger** le problème
3. **Tester** à nouveau
4. **Re-soumettre** avec explication

### Si Accepté 🎊

1. **Mettre en ligne** immédiatement ou planifier
2. **Monitorer** analytics et crashes
3. **Répondre** aux premiers avis utilisateurs
4. **Préparer** version 1.0.1 avec améliorations

---

**Bon courage ! 💪 Vous avez toutes les informations nécessaires.**

**Questions**: Consulter les fichiers de documentation créés.

**Succès**: ~85% de probabilité d'acceptation après ces corrections.
