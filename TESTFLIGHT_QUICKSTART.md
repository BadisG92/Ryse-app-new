# 🚀 TestFlight QuickStart - Widget iOS Inclus

## TL;DR - Build en 3 commandes

```bash
# 1. Vérifier que tout est prêt
./check_testflight_ready.sh

# 2. Builder l'IPA avec widget
./build_testflight.sh

# 3. Uploader sur TestFlight
open -a Transporter
# Drag & drop: build/ios/ipa/ryze_app.ipa
```

---

## ✅ Checklist Rapide

Avant de lancer le build :

- [ ] Fichier `.env.production` existe avec les bonnes clés
- [ ] Certificats Apple Developer valides
- [ ] Version incrémentée dans `pubspec.yaml`
- [ ] Tests passent : `flutter test`
- [ ] Analyse OK : `flutter analyze`

---

## 📝 Étapes Détaillées

### 1. Préparer l'environnement

```bash
# Vérifier la configuration complète
./check_testflight_ready.sh
```

**Attendu** : `✅ PRÊT POUR TESTFLIGHT!`

### 2. Build l'IPA

```bash
# Build complet (5-10 minutes)
./build_testflight.sh
```

**Le script fait** :
- ✅ Vérifie `.env.production`
- ✅ Clean le projet
- ✅ Build l'IPA avec environnement production
- ✅ Vérifie que le widget est inclus

**Sortie attendue** :
```
✅ Build réussi!
✅ Widget RyseMealWidgetExtension inclus dans l'IPA!
```

### 3. Upload sur TestFlight

**Option A - Transporter (Recommandé)** :
```bash
open -a Transporter
# Drag & drop: build/ios/ipa/ryze_app.ipa
```

**Option B - Xcode Organizer** :
```bash
open ~/Library/Developer/Xcode/Archives/
# Xcode → Window → Organizer → Distribute App
```

### 4. Vérifier sur App Store Connect

1. Aller sur [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → Ryse → TestFlight
3. Attendre le traitement (~10-30 minutes)
4. Vérifier que le build apparaît

---

## 🧪 Tester le Widget

Une fois installé depuis TestFlight :

1. **Ajouter le widget** :
   - Long press sur l'écran d'accueil
   - Appuyer sur **+** (en haut à gauche)
   - Rechercher "Ryse"
   - Sélectionner "Ryse Meal Widget"

2. **Tailles disponibles** :
   - **Small** : Pour Lock Screen
   - **Medium** : Pour Home Screen (recommandé)

3. **Fonctionnalités à tester** :
   - Affichage du repas contextuel (Petit-déjeuner/Déjeuner/Dîner)
   - Progression des calories
   - 5 boutons d'action (📝 Manuel, 📸 Scanner, etc.)
   - Deep links vers l'app
   - Synchronisation des données

---

## 🐛 Problèmes Courants

### Le widget n'apparaît pas dans l'IPA

```bash
# Ouvrir Xcode et vérifier le scheme
open ios/Runner.xcworkspace
# Product → Scheme → Edit Scheme → Build
# Vérifier que RyseMealWidgetExtension a "Archive" coché
```

### Erreur de signature

```bash
# Dans Xcode, sélectionner le target RyseMealWidgetExtension
# Signing & Capabilities → Automatically manage signing
# Sélectionner le bon Team
```

### Build échoue

```bash
# Clean complet
flutter clean
cd ios && rm -rf Pods/ Podfile.lock && pod install && cd ..

# Retry
./build_testflight.sh
```

---

## 📊 Temps Estimés

- **Vérification** : ~30 secondes
- **Build Flutter** : ~5-10 minutes
- **Upload** : ~5-10 minutes
- **Processing Apple** : ~10-30 minutes
- **Total** : ~30-60 minutes

---

## 🔧 Configuration Widget

Le widget est configuré pour :

- **Bundle ID** : `com.BadisG.ryzeApp.RyseMealWidgetExtension`
- **App Group** : `group.com.BadisG.ryzeApp`
- **Target iOS** : 16.0+
- **Tailles** : Small (Lock Screen) + Medium (Home Screen)

---

## 📚 Documentation Complète

Pour plus de détails, voir :

- **Guide complet** : [TESTFLIGHT_BUILD_GUIDE.md](TESTFLIGHT_BUILD_GUIDE.md)
- **Widget technique** : [WIDGET_README.md](WIDGET_README.md)
- **Widget installation** : [WIDGET_INSTALLATION_GUIDE.md](WIDGET_INSTALLATION_GUIDE.md)
- **Implémentation** : [WIDGET_IMPLEMENTATION_SUMMARY.md](WIDGET_IMPLEMENTATION_SUMMARY.md)

---

## ✅ Succès Final

Quand tout est OK, vous aurez :

- ✅ Build visible dans TestFlight
- ✅ Widget iOS fonctionnel
- ✅ Deep links opérationnels
- ✅ Synchronisation des données OK
- ✅ Prêt pour distribution aux testeurs !

---

**Pro Tips** :

💡 Lancez `./check_testflight_ready.sh` avant chaque build
💡 Incrémentez toujours le build number avant l'upload
💡 Testez le widget sur un vrai device (pas simulateur pour TestFlight)
💡 Gardez `.env.production` sécurisé (jamais dans git)

---

**Dernière mise à jour** : 2025-01-21
