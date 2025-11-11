# 🔧 Réactiver le Widget dans Xcode

## ✅ Étapes pour réactiver le widget dans les builds

### 1. Ouvrir Xcode

```bash
cd ios && open Runner.xcworkspace
```

### 2. Vérifier que le widget est dans le projet

Dans Xcode :
- Regardez la barre latérale gauche
- Vérifiez que `RyseMealWidgetExtension` apparaît dans la liste des targets
- Si absent, le widget n'est pas ajouté au projet

### 3. Réactiver le widget dans le scheme Runner

**Option A : Via les Build Phases**

1. Sélectionner le target **Runner** (pas le widget)
2. Aller dans l'onglet **Build Phases**
3. Chercher la section **"Dependencies"**
4. Vérifier que `RyseMealWidgetExtension` est listé
5. Si absent, cliquer sur `+` et ajouter `RyseMealWidgetExtension`

**Option B : Via le scheme**

1. En haut à gauche, cliquer sur le scheme **Runner**
2. Cliquer sur **Edit Scheme...**
3. Dans la colonne de gauche, sélectionner **Build**
4. Vérifier que `RyseMealWidgetExtension` est coché
5. Si décoché, cocher la case
6. Cliquer sur **Close**

### 4. Vérifier le script d'embedding

1. Sélectionner le target **Runner**
2. Aller dans **Build Phases**
3. Chercher **"Embed Widget Extension"** ou **"Run Script"**
4. Vérifier que le script `embed_widget.sh` est appelé
5. Si absent, ajouter un "Run Script Phase" :
   - Cliquer sur `+` → **New Run Script Phase**
   - Nom : "Embed Widget Extension"
   - Script : `"${SRCROOT}/embed_widget.sh"`
   - Input Files : `$(BUILT_PRODUCTS_DIR)/RyseMealWidgetExtension.appex`
   - Output Files : `$(BUILT_PRODUCTS_DIR)/$(WRAPPER_NAME)/PlugIns/RyseMealWidgetExtension.appex`

### 5. Nettoyer et rebuild

Dans Xcode :
- **Product → Clean Build Folder** (Shift+Cmd+K)
- **Product → Build** (Cmd+B)

### 6. Vérifier que ça fonctionne

1. Lancer l'app : **Product → Run** (Cmd+R)
2. Dans le simulateur :
   - Cmd+Shift+H (écran d'accueil)
   - Long press → `+`
   - Chercher "Mes Repas"

## 🔍 Vérification Rapide

Pour vérifier si le widget est activé dans le scheme :

```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -showBuildSettings \
  | grep -i widget
```

Si vous voyez des références au widget, il est activé.

## ⚠️ Si le widget n'apparaît toujours pas

1. Vérifier que le widget compile seul :
   - Scheme : `RyseMealWidgetExtension`
   - Product → Build
   
2. Vérifier les logs de build :
   - View → Navigators → Report Navigator
   - Chercher les erreurs liées au widget

3. Vérifier les App Groups :
   - Target Runner → Signing & Capabilities → App Groups
   - Target RyseMealWidgetExtension → Signing & Capabilities → App Groups
   - Les deux doivent avoir `group.com.ryze.app`


