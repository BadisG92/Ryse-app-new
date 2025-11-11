# 🔧 Guide de Débogage - Widget iOS Non Visible

## ✅ Checklist Rapide

### 1. Vérifier que le widget est compilé

```bash
cd ios
xcodebuild -scheme RyseMealWidgetExtension -sdk iphonesimulator -configuration Debug build
```

**Si erreur** : Le widget n'est pas configuré correctement dans Xcode.

### 2. Vérifier que l'app est lancée avec le widget

**Méthode 1 : Script automatique**
```bash
./run_with_widget.sh
```

**Méthode 2 : Manuel**
```bash
# 1. Compiler le widget
cd ios
xcodebuild -scheme RyseMealWidgetExtension -sdk iphonesimulator -configuration Debug build

# 2. Lancer Flutter
cd ..
flutter run
```

### 3. Vérifier dans le simulateur

1. **Retourner à l'écran d'accueil** : `Cmd + Shift + H`
2. **Mode édition widgets** : Long press sur un espace vide
3. **Ajouter widget** : Cliquer sur `+` en haut à gauche
4. **Rechercher** : Taper "Mes Repas" ou "Ryse"

## 🔍 Problèmes Courants

### Problème 1 : Widget n'apparaît pas dans la galerie

**Cause** : Le widget extension n'est pas embarqué dans l'app

**Solution** :
1. Ouvrir Xcode : `cd ios && open Runner.xcworkspace`
2. Vérifier que le target `RyseMealWidgetExtension` est dans le projet
3. Vérifier que le script `embed_widget.sh` est appelé dans les Build Phases
4. Rebuild complet : `Product → Clean Build Folder` puis rebuild

### Problème 2 : Erreur de compilation

**Vérifier** :
- Le bundle identifier du widget : `com.BadisG.ryzeApp.RyseMealWidget`
- Les App Groups sont configurés : `group.com.ryze.app`
- Les entitlements sont corrects

### Problème 3 : Widget apparaît mais pas de données

**Vérifier** :
- L'app Group est bien configuré dans les deux targets (Runner + Widget)
- Les données sont sauvegardées : Vérifier les logs Flutter pour `📱 Mise à jour des données widget...`
- Le widget peut lire les données : Vérifier les logs Xcode

## 🚀 Solution Rapide

### Étape par étape pour voir le widget :

1. **Nettoyer et rebuild**
```bash
cd ios
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner
xcodebuild clean -workspace Runner.xcworkspace -scheme RyseMealWidgetExtension
cd ..
flutter clean
flutter pub get
```

2. **Compiler le widget**
```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme RyseMealWidgetExtension \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build \
  build
cd ..
```

3. **Lancer l'app**
```bash
flutter run
```

4. **Dans le simulateur**
   - Aller à l'écran d'accueil (`Cmd + Shift + H`)
   - Long press sur un espace vide
   - Cliquer sur `+`
   - Chercher "Mes Repas"

## 📱 Vérification dans Xcode

1. Ouvrir `ios/Runner.xcworkspace` dans Xcode
2. Vérifier que le scheme `RyseMealWidgetExtension` existe
3. Vérifier les Build Phases → Embed Widget Extension
4. Vérifier les Signing & Capabilities → App Groups

## 🐛 Logs Utiles

**Flutter logs** :
```bash
flutter logs | grep -i widget
```

**Xcode logs** :
- Ouvrir Xcode → Window → Devices and Simulators
- Sélectionner le simulateur
- Voir les logs système

## ⚠️ Si rien ne fonctionne

1. **Supprimer l'app du simulateur** et relancer
2. **Réinstaller le widget** : Supprimer et ré-ajouter depuis la galerie
3. **Vérifier iOS version** : Le widget nécessite iOS 14+


