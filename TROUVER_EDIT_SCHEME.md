# 📍 Comment trouver "Edit Scheme" dans Xcode

## Méthode 1 : Via le menu Scheme (Recommandé)

1. **En haut à gauche de Xcode**, vous voyez un menu déroulant avec le nom du scheme (probablement "Runner")
2. **Cliquez sur ce menu** (pas sur la flèche, mais sur le nom "Runner")
3. Dans le menu qui s'ouvre, **cliquez sur "Edit Scheme..."** (tout en bas)

## Méthode 2 : Via le menu Product

1. Dans la barre de menu en haut : **Product → Scheme → Edit Scheme...**
   - Ou raccourci clavier : **Cmd + <** (Cmd + virgule)

## Méthode 3 : Via la barre d'outils

1. **Clic droit** sur le bouton "Run" (le triangle vert) dans la barre d'outils
2. Sélectionner **"Edit Scheme..."**

## Une fois dans "Edit Scheme"

1. Dans la colonne de **gauche**, cliquez sur **"Build"**
2. Dans la liste à **droite**, vous verrez tous les targets
3. **Cochez la case** à côté de `RyseMealWidgetExtension` si elle est décochée
4. Cliquez sur **"Close"** en bas à droite

## Alternative : Vérifier directement dans les Build Phases

Si vous ne trouvez pas "Edit Scheme", vous pouvez vérifier directement :

1. Dans la barre latérale **gauche**, sélectionnez le projet **Runner** (l'icône bleue en haut)
2. Sélectionnez le **target "Runner"** (pas le projet, le target)
3. Cliquez sur l'onglet **"Build Phases"** en haut
4. Cherchez la section **"Dependencies"**
5. Vérifiez si `RyseMealWidgetExtension` est dans la liste
6. Si **absent**, cliquez sur le **"+"** en bas et ajoutez-le

## Si vous ne voyez toujours pas le widget dans le scheme

Il est possible que le widget ne soit pas ajouté comme dépendance. Dans ce cas :

1. **Target Runner** → **Build Phases** → **Dependencies**
2. Cliquez sur **"+"**
3. Sélectionnez **"RyseMealWidgetExtension"**
4. Cliquez sur **"Add"**

Ensuite, nettoyez et rebuild :
- **Product → Clean Build Folder** (Shift+Cmd+K)
- **Product → Build** (Cmd+B)


