# 🏋️ RYZE APP - Coach Nutrition & Fitness IA

Application mobile iOS de coaching nutrition et fitness propulsée par l'intelligence artificielle.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/yourusername/ryze-app)
[![Flutter](https://img.shields.io/badge/Flutter-3.4.3-02569B?logo=flutter)](https://flutter.dev)
[![iOS](https://img.shields.io/badge/iOS-16.0+-000000?logo=apple)](https://www.apple.com/ios/)

---

## 🚀 Fonctionnalités Principales

### 🍎 Nutrition Intelligente
- **Scanner IA**: Photographiez votre assiette, obtenez calories et macros instantanément
- **Scanner code-barres**: Base OpenFoodFacts de 500,000+ produits
- **Journal alimentaire**: Suivi quotidien complet
- **Recettes**: 1000+ recettes saines avec valeurs nutritionnelles
- **Hydratation**: Suivi de l'eau avec rappels

### 💪 Entraînements
- **Musculation**: Tracking répétitions, séries, poids
- **Cardio GPS**: Course, vélo, marche avec parcours
- **HIIT**: Timer intégré et exercices guidés
- **Programmes IA**: Séances générées selon vos objectifs
- **Commandes vocales**: Enregistrement mains-libres

### 📊 Progression
- **Graphiques**: Évolution poids et performances
- **Streaks**: Système de motivation quotidienne
- **Dashboard unifié**: Vue d'ensemble nutrition + sport
- **Objectifs**: Définir et suivre vos cibles

### 🤖 Intelligence Artificielle
- **Google Gemini**: Analyse nutritionnelle avancée
- **Google Vision**: Reconnaissance d'images
- **Coach 24/7**: Recommandations personnalisées

---

## 📱 Captures d'Écran

_(À ajouter: 8 screenshots iPhone 15 Pro Max - 1290x2796)_

---

## 🛠️ Stack Technique

### Framework & Langage
- **Flutter** 3.4.3+ (Dart)
- **iOS** 16.0+ minimum

### Backend & Services
- **Supabase**: Base de données PostgreSQL, Auth, Storage
- **Google Gemini 2.0**: Analyse IA nutritionnelle
- **Google Cloud Vision**: Reconnaissance d'images
- **OpenFoodFacts**: API nutrition

### State Management
- **Provider**: Gestion d'état
- **Offline-first**: Mode hors ligne complet

### Packages Clés
```yaml
supabase_flutter: ^2.10.3    # Backend
google_generative_ai: ^0.4.6  # Gemini IA
camera: ^0.11.2               # Scanner
geolocator: ^12.0.0           # GPS tracking
fl_chart: ^0.68.0             # Graphiques
google_fonts: ^6.2.1          # Typographie
```

---

## 🏗️ Architecture

```
lib/
├── config/                # Configuration & secrets
│   ├── env_config.dart   # Variables d'environnement
│   └── *_config.dart     # Configs spécifiques
├── core/                 # Infrastructure
│   ├── cache/           # Système de cache
│   ├── data/            # Data layer
│   └── infrastructure/   # Services bas niveau
├── models/              # Data models
├── services/            # Business logic
│   ├── auth_service.dart
│   ├── food_entries_service.dart
│   ├── workout_service.dart
│   └── ...
├── screens/             # Écrans de l'app (26)
├── components/          # Composants réutilisables
├── providers/           # State management
└── main.dart            # Entry point
```

**Pattern**: Clean Architecture avec séparation Domain/Data/Presentation

---

## 🚀 Installation & Build

### Prérequis

1. **Flutter SDK**: Installer depuis [flutter.dev](https://flutter.dev/docs/get-started/install)
2. **Xcode**: Version récente pour iOS
3. **CocoaPods**: Pour dépendances iOS

### Clone & Dépendances

```bash
# Cloner le repo
git clone https://github.com/yourusername/ryze-app.git
cd ryze-app

# Installer dépendances Flutter
flutter pub get

# Installer pods iOS
cd ios && pod install && cd ..
```

### Configuration Environnement

1. **Copier le template**:
   ```bash
   cp .env.example .env.local
   ```

2. **Obtenir les clés API**:

   **Supabase**:
   - Créer projet sur [supabase.com](https://supabase.com)
   - Copier URL et Anon Key

   **Google Cloud**:
   - Créer projet sur [console.cloud.google.com](https://console.cloud.google.com)
   - Activer Gemini AI & Cloud Vision APIs
   - Créer clés API avec restrictions iOS

3. **Éditer `.env.local`**:
   ```bash
   SUPABASE_URL=https://votre-projet.supabase.co
   SUPABASE_ANON_KEY=votre_anon_key
   GEMINI_API_KEY=votre_gemini_key
   GOOGLE_VISION_API_KEY=votre_vision_key

   # OAuth
   GOOGLE_CLIENT_ID=votre_client_id.apps.googleusercontent.com

   # Config
   TEST_MODE=true
   ENVIRONMENT=development
   ```

### Run Development

```bash
# Avec variables d'environnement
flutter run --dart-define-from-file=.env.local

# Sur device spécifique
flutter devices
flutter run -d <device-id> --dart-define-from-file=.env.local
```

### Build Production

```bash
# Clean
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Build iOS
flutter build ios --release --dart-define-from-file=.env.production

# Archive dans Xcode
open ios/Runner.xcworkspace
# Product > Archive
```

**Voir [BUILD_GUIDE.md](BUILD_GUIDE.md) pour instructions complètes.**

---

## 🔐 Sécurité

### Variables d'Environnement

**IMPORTANT**: Les clés API ne sont JAMAIS hardcodées.

Fichiers sensibles (ignorés par git):
- `.env.local` - Development
- `.env.production` - Production
- `lib/config/API_KEYS_BACKUP.txt` - Backup (à supprimer après migration)

### Configuration iOS

- **Entitlements**: Séparés dev/production
- **Signing**: Automatique via Xcode
- **Permissions**: Justifiées dans Info.plist

### Données Utilisateur

- **Chiffrement**: HTTPS + bcrypt passwords
- **Storage**: Supabase (RGPD compliant)
- **Offline**: Cache local chiffré
- **RGPD**: Droit à l'effacement implémenté

---

## 📄 Documentation

| Document | Description |
|----------|-------------|
| [AUDIT_APP_STORE_MVP.md](AUDIT_APP_STORE_MVP.md) | Audit complet App Store (91 pages) |
| [BUILD_GUIDE.md](BUILD_GUIDE.md) | Guide de build avec env variables |
| [IOS_CONFIGURATION_GUIDE.md](IOS_CONFIGURATION_GUIDE.md) | Configuration Xcode |
| [LEGAL_TEMPLATES.md](LEGAL_TEMPLATES.md) | Privacy Policy & Terms |
| [MIGRATION_COMPLETE_SUMMARY.md](MIGRATION_COMPLETE_SUMMARY.md) | Résumé migrations sécurité |
| [CLAUDE.md](CLAUDE.md) | Documentation technique complète |

---

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Analyse statique
flutter analyze
```

**Couverture actuelle**: ~3% (27 tests)
**Objectif**: 60%+ sur services critiques

---

## 📦 Releases

### Version 1.0.0 (En cours)
- ✅ Scanner IA nutrition
- ✅ Tracking musculation & cardio
- ✅ Graphiques progression
- ✅ Mode offline complet
- ✅ OAuth (Google, Apple)
- ⏳ Abonnement Premium (StoreKit)
- ⏳ Soumission App Store

### Roadmap 1.1.0
- [ ] HealthKit sync
- [ ] Apple Watch companion
- [ ] Partage social
- [ ] Défis communautaires
- [ ] Mode sombre

---

## 🤝 Contribution

### Guidelines

1. **Fork** le repo
2. **Create branch**: `git checkout -b feature/ma-feature`
3. **Commit**: `git commit -m 'feat: ajout feature X'`
4. **Push**: `git push origin feature/ma-feature`
5. **Pull Request**: Décrire les changements

### Commit Convention

```
feat: nouvelle fonctionnalité
fix: correction bug
refactor: refactoring code
docs: documentation
test: ajout tests
chore: maintenance
```

---

## 📞 Support

### Contact

- **Email**: support@ryze-app.com
- **Website**: https://ryze-app.com
- **Issues**: [GitHub Issues](https://github.com/yourusername/ryze-app/issues)

### FAQ

**Q: Comment annuler mon abonnement ?**
R: Réglages iPhone > [Votre Nom] > Abonnements > Ryze Premium > Annuler

**Q: Le scanner ne fonctionne pas ?**
R: Vérifier permissions caméra dans Réglages > Ryze > Caméra

**Q: Mes données sont sauvegardées ?**
R: Oui, automatiquement sur cloud (si connecté) et cache local

---

## 📜 Licence

Copyright © 2025 [Votre Nom/Société]

Tous droits réservés. Ce projet est propriétaire.

---

## 🙏 Remerciements

- **Flutter Team**: Framework exceptionnel
- **Supabase**: Backend puissant et simple
- **Google AI**: Gemini & Vision APIs
- **OpenFoodFacts**: Base de données nutrition
- **Communauté open-source**: Packages utilisés

---

## 📊 Stats

- **26 écrans** implémentés
- **113 services** business logic
- **1.5MB** assets (images)
- **35 packages** production
- **iOS 16.0+** support
- **FR + EN** localization

---

## 🔥 Démarrage Rapide

### 5 Minutes Setup

```bash
# 1. Clone
git clone https://github.com/yourusername/ryze-app.git && cd ryze-app

# 2. Install
flutter pub get && cd ios && pod install && cd ..

# 3. Configure
cp .env.example .env.local
# Éditer .env.local avec vos clés

# 4. Run
flutter run --dart-define-from-file=.env.local
```

### Première Utilisation

1. **Créer compte** (email ou Google/Apple)
2. **Compléter profil** (poids, taille, objectifs)
3. **Scanner un repas** avec la caméra
4. **Démarrer un workout** dans l'onglet Sport
5. **Voir progression** dans le dashboard

---

**Made with ❤️ and 💪 by Ryze Team**

**Version**: 1.0.0 | **iOS**: 16.0+ | **Status**: 🚀 Pre-launch
