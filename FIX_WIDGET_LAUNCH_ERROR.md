# 🔧 Fix : Flutter essaie de lancer le widget au lieu de l'app

## ❌ Erreur
```
Could not find the built application bundle at
build/ios/iphonesimulator/RyseMealWidgetExtension.app.
```

## 🔍 Cause
Flutter détecte le widget extension comme un target exécutable et essaie de le lancer au lieu de l'app Runner.

## ✅ Solution

### Option 1 : Lancer via Xcode (Recommandé)

1. **Ouvrir Xcode** :
```bash
cd ios && open Runner.xcworkspace
```

2. **S'assurer que le scheme "Runner" est sélectionné** (en haut à gauche)

3. **Lancer l'app** :
   - **Product → Run** (Cmd+R)
   - OU cliquer sur le bouton Play vert

4. **Le widget sera automatiquement compilé et embarqué**

### Option 2 : Nettoyer et relancer Flutter

```bash
# 1. Nettoyer
flutter clean
cd ios
rm -rf build DerivedData
cd ..

# 2. Compiler le widget d'abord dans Xcode
cd ios && open Runner.xcworkspace
# Dans Xcode : Scheme → RyseMealWidgetExtension → Build (Cmd+B)
# Puis : Scheme → Runner → Run (Cmd+R)

# 3. OU utiliser le script
cd ..
./build_and_run_widget.sh
```

### Option 3 : Spécifier explicitement le bundle identifier

```bash
flutter run --dart-define-from-file=.env.local \
  -d "iPhone 16 Pro" \
  --target=lib/main.dart
```

## 🎯 Solution Rapide

**La meilleure solution** : Utiliser Xcode directement pour lancer l'app :

1. `cd ios && open Runner.xcworkspace`
2. Dans Xcode : **Product → Run** (Cmd+R)
3. Le widget sera automatiquement compilé et embarqué si configuré dans le scheme

## ⚠️ Important

Le widget extension **ne doit jamais être lancé directement**. Il doit être :
- Compilé séparément
- Embarqué dans l'app Runner
- L'app Runner est lancée, pas le widget


