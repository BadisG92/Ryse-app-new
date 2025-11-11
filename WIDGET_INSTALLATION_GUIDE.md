# 📱 Guide d'Installation du Widget iOS "Smart Meal"

Ce guide explique comment ajouter le widget iOS à votre application Ryse.

## 🎯 Vue d'Ensemble

Le widget "Smart Meal" affiche :
- Le repas contextuel selon l'heure (Petit-déj / Déjeuner / Dîner)
- Calories du repas et totales
- 5 boutons d'ajout rapide (📝 Manuel, 📸 Scan, 🔍 Barcode, 🍳 Recette, 💬 Chat)
- Progression calorique du jour

## 📋 Prérequis

- Xcode 14.0 ou supérieur
- iOS 16.0+ (pour les fonctionnalités complètes)
- Flutter configuré avec iOS

## 🛠️ Étapes d'Installation

### **Étape 1 : Créer le Widget Extension dans Xcode**

1. Ouvrez votre projet iOS dans Xcode :
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. Dans Xcode, allez à **File → New → Target...**

3. Sélectionnez **Widget Extension** et cliquez sur **Next**

4. Configurez le widget :
   - **Product Name** : `RyseMealWidget`
   - **Team** : Votre équipe de développement
   - **Include Configuration Intent** : ❌ **Décochez** (pas besoin pour notre widget)
   - Cliquez sur **Finish**

5. Xcode va créer un nouveau dossier `RyseMealWidget/` dans votre projet

### **Étape 2 : Configurer App Groups**

Pour partager les données entre Flutter et le widget, vous devez configurer les App Groups.

1. Dans Xcode, sélectionnez le target **Runner** (l'app principale)

2. Allez dans l'onglet **Signing & Capabilities**

3. Cliquez sur **+ Capability** et ajoutez **App Groups**

4. Cliquez sur **+** pour ajouter un nouveau groupe :
   ```
   group.com.ryze.app
   ```

5. **IMPORTANT** : Répétez les étapes 1-4 pour le target **RyseMealWidget**
   - Utilisez le **même** App Group ID : `group.com.ryze.app`

### **Étape 3 : Remplacer le fichier Swift du Widget**

1. Dans Xcode, supprimez le fichier `RyseMealWidget.swift` auto-généré

2. Dans le Finder, copiez le fichier que j'ai créé :
   ```
   Ryse-app-new/ios/RyseMealWidget/RyseMealWidget.swift
   ```

3. Glissez-déposez ce fichier dans Xcode dans le dossier `RyseMealWidget/`

4. Assurez-vous que le fichier est bien ajouté au target **RyseMealWidget**

### **Étape 4 : Configurer Info.plist du Widget**

1. Ouvrez `RyseMealWidget/Info.plist` dans Xcode

2. Vérifiez/ajoutez ces clés :

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
<key>CFBundleDisplayName</key>
<string>Mes Repas</string>
```

### **Étape 5 : Configurer Deep Links dans l'App Principale**

1. Ouvrez `ios/Runner/Info.plist`

2. Ajoutez le schéma URL pour les deep links :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ryse</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.ryse.app</string>
    </dict>
</array>
```

### **Étape 6 : Intégrer le Deep Link Handler dans Flutter**

1. Ajoutez le package `uni_links` à votre `pubspec.yaml` :

```yaml
dependencies:
  uni_links: ^0.5.1
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. Dans votre fichier `main.dart`, ajoutez l'import et initialisez le handler :

```dart
import 'package:uni_links/uni_links.dart';
import 'services/widget_deep_link_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize deep link handler
  final navigatorKey = GlobalKey<NavigatorState>();
  WidgetDeepLinkHandler.initialize(navigatorKey);

  // Handle initial link (app opened from widget)
  try {
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      WidgetDeepLinkHandler.handleDeepLink(Uri.parse(initialLink));
    }
  } catch (e) {
    print('Error getting initial link: $e');
  }

  // Listen for incoming links
  linkStream.listen((String? link) {
    if (link != null) {
      WidgetDeepLinkHandler.handleDeepLink(Uri.parse(link));
    }
  });

  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({Key? key, required this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      // ... votre configuration existante
    );
  }
}
```

### **Étape 7 : Build et Test**

1. Dans Xcode, sélectionnez le target **Runner** (pas RyseMealWidget)

2. Sélectionnez un simulateur ou device iOS 16.0+

3. Build et run : **⌘ + R**

4. Une fois l'app lancée, retournez à l'écran d'accueil

5. **Long press** sur un espace vide de l'écran d'accueil

6. Appuyez sur le bouton **+** en haut à gauche

7. Cherchez **"Mes Repas"** dans la liste des widgets

8. Sélectionnez la taille (Small ou Medium) et ajoutez-le

## 🧪 Test du Widget

### Test des Données

1. Dans l'app, ajoutez un repas (ex: Petit-déjeuner avec 420 kcal)

2. Retournez à l'écran d'accueil

3. Le widget devrait afficher :
   - ✅ "Petit-déjeuner" avec l'emoji 🌅
   - ✅ "420 kcal"
   - ✅ Progression totale mise à jour

### Test des Deep Links

1. Sur le widget **Medium**, tapez sur le bouton **📸 Scan**

2. L'app devrait s'ouvrir directement sur le scanner avec le repas contextuel pré-sélectionné

3. Testez les autres boutons :
   - **📝 Manuel** → Recherche manuelle
   - **🔍 Barcode** → Scanner code-barres
   - **🍳 Recette** → Sélection recettes
   - **💬 Chat** → Chat IA

## 🐛 Résolution de Problèmes

### Le widget affiche "0 kcal" même après ajout de repas

**Solution** : Vérifiez que l'App Group est correctement configuré dans les deux targets (Runner et RyseMealWidget).

1. Dans Xcode, vérifiez **Signing & Capabilities** pour les deux targets
2. Assurez-vous que `group.com.ryze.app` est coché pour les deux
3. Clean et rebuild le projet (**⌘ + Shift + K** puis **⌘ + R**)

### Les deep links ne fonctionnent pas

**Solution** : Vérifiez que le schéma URL est bien configuré.

1. Ouvrez `ios/Runner/Info.plist`
2. Vérifiez que `CFBundleURLSchemes` contient `ryse`
3. Assurez-vous que `uni_links` est bien installé (`flutter pub get`)

### Le widget ne se rafraîchit pas

**Solution** : Le widget se rafraîchit automatiquement selon la stratégie définie dans `Timeline Provider`.

- **Heures de repas (7-10h, 11-14h, 18-21h)** : Toutes les 15 minutes
- **Autres heures** : Toutes les heures

Pour forcer un refresh immédiat (debug) :
1. Supprimez le widget de l'écran d'accueil
2. Ré-ajoutez-le

### Erreur "App Group not found"

**Solution** : L'App Group doit être créé dans votre compte développeur Apple.

1. Allez sur [developer.apple.com](https://developer.apple.com)
2. Certificates, Identifiers & Profiles → Identifiers → App Groups
3. Créez l'App Group `group.com.ryze.app`
4. Synchronisez dans Xcode (Signing & Capabilities → Refresh)

## 📊 Formats de Deep Links

Le widget utilise ces formats d'URL :

```
ryse://add-food                              → Flux normal (sélection repas + mode)
ryse://add-food?meal=dejeuner                → Repas pré-sélectionné
ryse://add-food?mode=camera                  → Mode pré-sélectionné
ryse://add-food?meal=dejeuner&mode=camera    → Les deux pré-sélectionnés
```

Types de repas supportés :
- `petit-dejeuner` → Petit-déjeuner
- `dejeuner` → Déjeuner
- `diner` → Dîner
- `snack` → Snack

Modes supportés :
- `manual` → Recherche manuelle
- `camera` / `scanner` → Scanner IA
- `barcode` → Scanner code-barres
- `recipe` → Sélection recettes
- `chat` → Chat IA

## 🎨 Personnalisation

### Changer les Couleurs

Dans `RyseMealWidget.swift`, modifiez les couleurs du gradient :

```swift
LinearGradient(
    colors: [Color(hex: "0B132B"), Color(hex: "1C2951")], // Vos couleurs
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Modifier la Fréquence de Refresh

Dans la fonction `getTimeline()` du `Provider` :

```swift
let refreshInterval: TimeInterval
if (7...10).contains(hour) || (11...14).contains(hour) || (18...21).contains(hour) {
    refreshInterval = 10 * 60  // 10 minutes au lieu de 15
} else {
    refreshInterval = 30 * 60  // 30 minutes au lieu de 60
}
```

## 🚀 Prochaines Étapes

Une fois le widget fonctionnel, vous pouvez :

1. **Ajouter un Widget Large** : Afficher tous les repas de la journée
2. **Live Activities** : Suivre un workout en temps réel sur le Lock Screen
3. **Interactive Widgets (iOS 17+)** : Ajouter de l'eau directement depuis le widget sans ouvrir l'app
4. **Complications Apple Watch** : Afficher les calories sur la Watch

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs Xcode (⌘ + Shift + Y pour ouvrir la console)
2. Vérifiez les logs Flutter (`flutter logs`)
3. Assurez-vous que tous les fichiers sont bien inclus dans les bons targets

Le widget devrait maintenant être opérationnel ! 🎉
