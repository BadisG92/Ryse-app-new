# 🔧 Widget iOS - Guide de Résolution de Problèmes

## ❌ Problème : Le widget n'apparaît pas dans la galerie iOS

### Cause Principale
Le widget extension n'est **pas compilé** ou **pas embarqué** dans l'app quand vous lancez avec `flutter run`.

### ✅ Solution 1 : Script Automatique (Recommandé)

```bash
./build_and_run_widget.sh
```

Ce script :
1. ✅ Compile le widget extension
2. ✅ Vérifie le simulateur
3. ✅ Lance l'app Flutter avec le widget embarqué

### ✅ Solution 2 : Via Xcode (Manuel)

1. **Ouvrir Xcode** :
```bash
cd ios && open Runner.xcworkspace
```

2. **Compiler le widget** :
   - Sélectionner le scheme `RyseMealWidgetExtension` (en haut à gauche)
   - Product → Build (Cmd+B)
   - Attendre "Build Succeeded"

3. **Lancer l'app** :
   - Sélectionner le scheme `Runner`
   - Product → Run (Cmd+R)
   - OU utiliser Flutter : `flutter run`

4. **Dans le simulateur** :
   - Cmd+Shift+H (écran d'accueil)
   - Long press sur espace vide
   - Cliquer sur `+`
   - Chercher "Mes Repas"

### ✅ Solution 3 : Vérifier que le widget est embarqué

Vérifier que le widget extension est dans l'app :

```bash
# Trouver le bundle de l'app
APP_BUNDLE=$(find ~/Library/Developer/CoreSimulator/Devices -name "Runner.app" -path "*/iPhone*" | head -1)

# Vérifier si le widget est embarqué
if [ -d "$APP_BUNDLE/PlugIns/RyseMealWidgetExtension.appex" ]; then
    echo "✅ Widget embarqué"
else
    echo "❌ Widget NON embarqué - Il faut compiler le widget d'abord"
fi
```

## 🔍 Vérifications

### 1. Le widget est-il compilé ?

```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme RyseMealWidgetExtension \
  -sdk iphonesimulator \
  -configuration Debug \
  build
```

**Si erreur** : Le widget n'est pas configuré dans Xcode.

### 2. Le widget est-il dans le projet Xcode ?

```bash
cd ios && open Runner.xcworkspace
```

Dans Xcode :
- Vérifier que `RyseMealWidgetExtension` apparaît dans la liste des targets
- Vérifier que les fichiers Swift sont dans le target

### 3. Les App Groups sont-ils configurés ?

Dans Xcode :
- Target **Runner** → Signing & Capabilities → App Groups → `group.com.ryze.app`
- Target **RyseMealWidgetExtension** → Signing & Capabilities → App Groups → `group.com.ryze.app`

### 4. Le script d'embedding est-il appelé ?

Dans Xcode :
- Target **Runner** → Build Phases → "Embed Widget Extension"
- Vérifier que le script `embed_widget.sh` est appelé

## 🚨 Erreurs Courantes

### Erreur : "No such module 'WidgetKit'"
**Solution** : Vérifier que `import WidgetKit` est présent dans les fichiers Swift

### Erreur : "Widget extension not found"
**Solution** : Compiler le widget d'abord avec Xcode

### Erreur : "App Group not available"
**Solution** : Configurer les App Groups dans Xcode pour les deux targets

## 📱 Après avoir ajouté le widget

Si le widget apparaît mais affiche "0 kcal" ou des données vides :

1. **Vérifier les logs Flutter** :
```bash
flutter logs | grep widget
```

Vous devriez voir : `📱 Mise à jour des données widget...`

2. **Ajouter un repas dans l'app** pour générer des données

3. **Forcer le refresh du widget** :
   - Supprimer le widget de l'écran d'accueil
   - Le ré-ajouter

## 💡 Astuce

**Pour éviter ce problème à l'avenir** :
- Toujours compiler le widget avant de lancer l'app
- Utiliser le script `build_and_run_widget.sh` qui fait tout automatiquement


