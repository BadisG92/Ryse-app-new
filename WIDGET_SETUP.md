# 📱 Widget iOS - Guide d'utilisation

## 🎯 Vue d'ensemble

Votre app Ryse dispose maintenant d'un widget iOS "Mes Repas" qui affiche vos calories consommées directement sur l'écran d'accueil.

## ✅ Ce qui a été implémenté

### Widget iOS Native
- **Fichier**: `ios/RyseMealWidget/RyseMealWidget.swift`
- **Tailles**: Small (2x2) et Medium (4x2)
- **Données affichées**:
  - Calories consommées / Objectif
  - Repas contextuel (petit-déj, déjeuner, dîner, collation)
  - Barre de progression visuelle
- **Rafraîchissement**: Automatique toutes les 15 minutes

### Services Flutter
- **`lib/services/meal_widget_data_provider.dart`**
  - Synchronise les données des repas vers le widget
  - Utilise SharedPreferences pour la communication inter-process
  - App Group: `group.com.ryze.app`

- **`lib/services/widget_deep_link_handler.dart`**
  - Gère les deep links depuis le widget
  - Ouvre automatiquement l'écran d'ajout de repas
  - URL scheme: `ryse://add-food?meal=X&mode=Y`

### Configuration
- **App Groups**: Configuré dans les entitlements iOS
- **Info.plist**: URL scheme `ryse://` ajouté
- **Podfile**: Compatibilité ML Kit avec simulateur

## 🚀 Utilisation

### Méthode recommandée : Script automatique

```bash
./run_with_widget.sh
```

Ce script fait TOUT automatiquement :
1. ✅ Compile le widget extension pour le simulateur
2. ✅ Détecte ou démarre un simulateur iOS
3. ✅ Lance l'app Flutter avec les bonnes variables d'environnement
4. ✅ Embarque le widget dans l'app

### Méthode manuelle

Si vous préférez contrôler chaque étape :

```bash
# 1. Compiler le widget
cd ios
xcodebuild -scheme RyseMealWidgetExtension \
    -sdk iphonesimulator \
    -configuration Debug \
    build

# 2. Lancer l'app Flutter
cd ..
flutter run -d SIMULATOR_ID --dart-define-from-file=.env.local
```

## 📱 Ajouter le widget à l'écran d'accueil

Une fois l'app lancée :

1. **Retour à l'écran d'accueil**: `Cmd + Shift + H`
2. **Mode édition**: Long press sur un espace vide
3. **Ajouter un widget**: Cliquez sur le bouton `+` en haut à gauche
4. **Rechercher**: Tapez "Mes Repas" ou "Ryse"
5. **Sélectionner**: Choisissez la taille (Small ou Medium)
6. **Confirmer**: Cliquez sur "Add Widget"

## 🔄 Comment ça fonctionne

### Synchronisation des données

```
Flutter App                Widget Extension
    │                           │
    ├─ Add Food Entry           │
    ├─ Update calories          │
    ├─ Save to Supabase         │
    ├─ Update SharedPreferences ─┼─→ Read SharedPreferences
    │   (App Group)             │   (App Group)
    │                           ├─ Update UI
    │                           └─ Show new calories
```

### Deep Links

Quand vous tapez sur le widget :
```
Widget → ryse://add-food?meal=breakfast&mode=quick
         ↓
App Launch/Resume
         ↓
WidgetDeepLinkHandler
         ↓
ManualFoodSearchBottomSheet
```

## 🛠️ Architecture technique

### Fichiers clés

```
ios/
├── RyseMealWidget/
│   ├── RyseMealWidget.swift          # Widget SwiftUI
│   ├── Info.plist                    # Configuration widget
│   └── Assets.xcassets/              # Assets widget
├── embed_widget.sh                    # Script d'intégration
├── Runner/
│   ├── Info.plist                    # URL scheme configuré
│   └── Runner.entitlements           # App Groups
└── RyseMealWidgetExtensionDebug.entitlements

lib/
├── services/
│   ├── meal_widget_data_provider.dart    # Sync données
│   ├── widget_deep_link_handler.dart     # Deep links
│   └── food_entries_service.dart         # Appelle updateWidgetData()
└── main.dart                               # Initialise deep links

run_with_widget.sh                         # Script tout-en-un
```

### App Groups

Les App Groups permettent le partage de données entre l'app et le widget :

- **Group ID**: `group.com.ryze.app`
- **Configured in**:
  - `ios/Runner/Runner.entitlements`
  - `ios/RyseMealWidgetExtensionDebug.entitlements`
  - Xcode → Signing & Capabilities

### Données partagées

```json
{
  "lastUpdate": "2025-01-30T10:30:00",
  "contextualMeal": {
    "name": "Petit-déjeuner",
    "id": "breakfast",
    "calories": 450
  },
  "totals": {
    "consumed": 1250,
    "target": 2000
  }
}
```

## 🐛 Dépannage

### Le widget n'apparaît pas dans la galerie

**Cause**: Le widget extension n'a pas été compilé ou embarqué.

**Solution**:
```bash
# Vérifier si le widget est compilé
ls -la ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphonesimulator/RyseMealWidgetExtension.appex

# Recompiler
./run_with_widget.sh
```

### Le widget affiche 0 kcal

**Cause**: Les données ne sont pas synchronisées ou l'app n'a pas été lancée.

**Solution**:
1. Ouvrez l'app
2. Ajoutez un repas
3. Le widget se mettra à jour automatiquement

### Erreur "Widget compilation failed"

**Cause**: xcodebuild échoue ou le widget n'est pas trouvé.

**Solution**:
```bash
# Nettoyer et recompiler
flutter clean
cd ios
rm -rf Pods Podfile.lock
cd ..
./run_with_widget.sh
```

### Le widget ne se rafraîchit pas

**Cause**: Le widget utilise un timeline avec rafraîchissement différé.

**Solution**:
- Le widget se rafraîchit automatiquement toutes les 15 minutes
- Ou quand vous ajoutez un repas dans l'app

## 📊 Améliorations futures possibles

- [ ] Support des complications watchOS
- [ ] Widget Large (4x4) avec graphiques
- [ ] Lock Screen widgets (iOS 16+)
- [ ] Live Activities pour le suivi en temps réel
- [ ] Intents pour configuration personnalisée
- [ ] Support iPad avec tailles adaptées
- [ ] Thème sombre automatique

## 🔗 Ressources

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [App Groups Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Deep Links in Flutter](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [SharedPreferences for iOS](https://pub.dev/packages/shared_preferences)

## ✅ Checklist avant commit

- [ ] Widget compile sans erreur
- [ ] App lance avec `./run_with_widget.sh`
- [ ] Widget apparaît dans la galerie iOS
- [ ] Données se synchronisent correctement
- [ ] Deep links fonctionnent (tap sur widget)
- [ ] Tests sur device physique (optionnel)

---

**Créé le**: 30 Octobre 2025
**Auteur**: Claude Code
**Version**: 1.0.0
