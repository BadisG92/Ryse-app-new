# 🚀 Build TestFlight via Xcode (Méthode Recommandée pour Widget)

## Problème Identifié

`flutter build ipa` crée deux archives séparées au lieu d'embedder le widget dans l'app principale. Pour garantir que le widget est correctement inclus, utilisez Xcode directement.

## ✅ Solution : Build avec Xcode

### Étape 1 : Préparer le projet Flutter

```bash
# Clean et préparer
flutter clean
flutter pub get
flutter build ios --release --dart-define-from-file=.env.production --no-codesign
```

### Étape 2 : Ouvrir Xcode

```bash
open ios/Runner.xcworkspace
```

### Étape 3 : Configurer le Target

1. Dans Xcode, sélectionner le target **Runner** (pas RyseMealWidgetExtension)
2. Sélectionner **Any iOS Device** comme destination
3. Vérifier que le scheme est **Runner**

### Étape 4 : Vérifier la Configuration du Widget

1. Dans le navigateur de projet, sélectionner **Runner** (target)
2. Aller dans l'onglet **General**
3. Scroller jusqu'à **Frameworks, Libraries, and Embedded Content**
4. **Vérifier que `RyseMealWidgetExtension.appex` est présent et configuré comme "Embed & Sign"**

**Si le widget n'est PAS dans la liste :**
1. Cliquer sur le **+** en bas
2. Sélectionner **RyseMealWidgetExtension.appex**
3. Changer de "Do Not Embed" à **"Embed & Sign"**

### Étape 5 : Archiver

1. Dans le menu : **Product → Archive** (ou ⌘ + B puis ⌘ + Shift + B)
2. Attendre la fin du build (~5-10 minutes)
3. L'Organizer s'ouvrira automatiquement avec votre archive

### Étape 6 : Distribuer

1. Dans Organizer, sélectionner votre archive
2. Cliquer sur **Distribute App**
3. Sélectionner **App Store Connect**
4. Sélectionner **Upload**
5. Suivre les étapes de distribution

---

## 🛠️ Méthode Alternative : Script Automatique

Si vous préférez le command line, utilisez ce script :

```bash
./build_testflight_xcode.sh
```

Ce script :
- Prépare le projet Flutter
- Archive avec `xcodebuild` en utilisant le workspace
- Exporte l'IPA avec le widget correctement embedé
- Vérifie que le widget est présent

---

## 🔍 Vérification Post-Build

Une fois l'IPA créée, vérifiez le widget :

```bash
# Extraire et vérifier
unzip -l ios/build/ipa/ryze_app.ipa | grep RyseMealWidget

# Devrait afficher plusieurs fichiers du widget, pas juste un fichier de 91 bytes
```

---

## ❓ Pourquoi cette méthode ?

`flutter build ipa` a un problème connu avec les app extensions quand elles ne sont pas correctement configurées comme embedded content. Xcode gère mieux cette configuration automatiquement.

---

## 📝 Note Importante

Après avoir utilisé Xcode une fois pour archiver correctement, la configuration sera sauvegardée et `flutter build ipa` devrait fonctionner correctement par la suite.

---

**Prochaine étape** : Ouvrez Xcode et suivez les étapes ci-dessus, ou lancez `./build_testflight_xcode.sh`
