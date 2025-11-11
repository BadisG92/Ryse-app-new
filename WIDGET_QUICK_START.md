# 🚀 Widget iOS - Quick Start (5 Minutes)

**But** : Installer rapidement le widget "Smart Meal" dans votre app Ryse.

## ✅ Prérequis

- [ ] Xcode installé (14.0+)
- [ ] Projet iOS ouvert (`cd ios && open Runner.xcworkspace`)
- [ ] Compte développeur Apple configuré

## 📝 Checklist d'Installation (30 min)

### 1️⃣ Créer le Widget Extension (5 min)

```bash
# Ouvrir Xcode
cd ios
open Runner.xcworkspace
```

Dans Xcode :
- **File → New → Target...**
- Sélectionner **Widget Extension**
- Product Name : `RyseMealWidget`
- ❌ Décocher "Include Configuration Intent"
- Cliquer **Finish**

### 2️⃣ Configurer App Groups (5 min)

**Pour Runner** :
- Sélectionner target **Runner**
- **Signing & Capabilities → + Capability → App Groups**
- Ajouter groupe : `group.com.ryze.app`

**Pour RyseMealWidget** :
- Sélectionner target **RyseMealWidget**
- **Signing & Capabilities → + Capability → App Groups**
- Cocher le même groupe : `group.com.ryze.app`

### 3️⃣ Installer le Fichier Swift (2 min)

Dans Xcode :
- Supprimer `RyseMealWidget/RyseMealWidget.swift` (auto-généré)
- Glisser-déposer le fichier depuis `ios/RyseMealWidget/RyseMealWidget.swift`
- Vérifier qu'il est dans le target **RyseMealWidget**

### 4️⃣ Configurer Deep Links (3 min)

Ouvrir `ios/Runner/Info.plist` et ajouter :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ryse</string>
        </array>
    </dict>
</array>
```

### 5️⃣ Ajouter uni_links (3 min)

Dans `pubspec.yaml` :

```yaml
dependencies:
  uni_links: ^0.5.1
```

Installer :
```bash
flutter pub get
```

### 6️⃣ Modifier main.dart (10 min)

Ajouter en haut du fichier :

```dart
import 'package:uni_links/uni_links.dart';
import 'services/widget_deep_link_handler.dart';
```

Modifier la fonction `main()` :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOUVEAU: Initialize deep link handler
  final navigatorKey = GlobalKey<NavigatorState>();
  WidgetDeepLinkHandler.initialize(navigatorKey);

  // NOUVEAU: Handle initial link
  try {
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      WidgetDeepLinkHandler.handleDeepLink(Uri.parse(initialLink));
    }
  } catch (e) {
    print('❌ Error getting initial link: $e');
  }

  // NOUVEAU: Listen for incoming links
  linkStream.listen((String? link) {
    if (link != null) {
      WidgetDeepLinkHandler.handleDeepLink(Uri.parse(link));
    }
  });

  // Votre code existant
  await Supabase.initialize(...);

  runApp(MyApp(navigatorKey: navigatorKey));
}
```

Modifier votre widget `MyApp` :

```dart
class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({Key? key, required this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // NOUVEAU
      // ... votre configuration existante
    );
  }
}
```

### 7️⃣ Build & Test (2 min)

Dans Xcode :
- Sélectionner target **Runner**
- Sélectionner simulateur iOS 16.0+
- **⌘ + R** (Build and Run)

Sur le simulateur :
- Retourner à l'écran d'accueil (⌘ + Shift + H)
- Long press sur espace vide
- Appuyer sur **+**
- Chercher **"Mes Repas"**
- Ajouter le widget Medium

## 🧪 Tests Rapides

### Test 1 : Données Widget

1. Dans l'app, ajouter un petit-déjeuner (420 kcal)
2. Retourner à l'écran d'accueil
3. ✅ Widget affiche "Petit-déjeuner - 420 kcal"

### Test 2 : Deep Links

1. Sur le widget, taper le bouton **📸**
2. ✅ App s'ouvre sur le scanner avec repas pré-sélectionné

### Test 3 : Contexte Temps

1. Changer l'heure système à 12h00
2. ✅ Widget affiche "Déjeuner 🌤️"

## ⚠️ Si ça ne marche pas

### Widget affiche "0 kcal"
```
Cause : App Groups mal configuré
Solution : Vérifier que "group.com.ryze.app" est coché dans les 2 targets
```

### Deep links ne fonctionnent pas
```
Cause : URL Scheme manquant
Solution : Vérifier CFBundleURLSchemes dans Info.plist
```

### Erreur "App Group not found"
```
Cause : App Group pas créé dans compte développeur
Solution :
1. developer.apple.com → Identifiers → App Groups
2. Créer "group.com.ryze.app"
3. Xcode : Signing & Capabilities → Refresh
```

## 📊 Logs Utiles

**Dans Flutter** :
```bash
flutter logs | grep widget
```

Cherchez :
```
📱 Mise à jour des données widget...
✅ Données widget mises à jour
```

**Dans Xcode** (Console : ⌘ + Shift + Y) :
```
✅ App Group accessible
🔗 Deep link reçu: ryse://...
```

## 🎉 C'est Prêt !

Votre widget est maintenant fonctionnel !

**Next Steps** :
- Tester sur un device réel iOS
- Personnaliser les couleurs si besoin
- Lire [`WIDGET_README.md`](WIDGET_README.md) pour les détails techniques

**Questions ?** Consultez [`WIDGET_INSTALLATION_GUIDE.md`](WIDGET_INSTALLATION_GUIDE.md) pour le guide complet.

---

**Temps total : ~30 minutes**

✅ Widget Small + Medium
✅ Détection contextuelle
✅ Deep links
✅ Actions rapides
✅ Données temps réel

**Votre app est maintenant au niveau AAA !** 🚀
