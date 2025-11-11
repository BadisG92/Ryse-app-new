# RevenueCat Setup Guide - Ryse App

Guide complet pour configurer RevenueCat et les achats in-app dans l'application Ryse.

## 📋 Table des matières

1. [Modèle d'abonnement](#modèle-dabonnement)
2. [Architecture du code](#architecture-du-code)
3. [Configuration RevenueCat Dashboard](#configuration-revenuecat-dashboard)
4. [Configuration iOS (App Store Connect)](#configuration-ios)
5. [Configuration Android (Google Play Console)](#configuration-android)
6. [Configuration des variables d'environnement](#configuration-des-variables-denvironnement)
7. [Intégration dans l'app](#intégration-dans-lapp)
8. [Testing](#testing)
9. [Déploiement](#déploiement)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 Modèle d'abonnement

### Prix et périodes

| Période | Prix | Économie | Product ID |
|---------|------|----------|------------|
| **Weekly** | 2,99€/semaine | - | `ryse_premium_weekly` |
| **Monthly** | 9,99€/mois | - | `ryse_premium_monthly` |
| **Yearly** | 69,99€/an | 42% | `ryse_premium_yearly` |

### Trial gratuit
- **Durée** : 7 jours
- **Contenu** : Accès complet à toutes les fonctionnalités IA

### Features par tier

#### ❌ Gratuit (après trial)
- Suivi nutrition manuel (limité)
- Suivi workout manuel (basique)
- Historique 30 jours
- 10 recettes max
- **0 accès IA** (scan, analyse, chat, générateur)

#### ✅ Premium
- **Scan IA illimité** (nourriture)
- **Analyse nutrition quotidienne** par coach IA
- **Générateur de séances** sport IA
- **Chat nutrition & sport** IA illimité
- **Générateur de recettes** IA
- Historique complet illimité
- Recettes illimitées
- Graphiques avancés
- Export de données
- Mode hors ligne
- Sans publicité

---

## 🏗️ Architecture du code

### Fichiers créés/modifiés

```
lib/
├── config/
│   └── subscription_config.dart          # Configuration centralisée (prix, IDs, features)
├── services/
│   ├── revenuecat_service.dart          # Service RevenueCat (achats réels)
│   ├── unified_subscription_service.dart # Service unifié (RevenueCat + DB)
│   └── subscription_service.dart         # Service existant (logique métier)
└── screens/
    └── paywall_screen.dart              # Écran paywall (modifié pour RevenueCat)

pubspec.yaml                              # Ajout de purchases_flutter: ^8.3.3
```

### Flow de l'architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Application                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│           UnifiedSubscriptionService                         │
│  (Orchestrateur principal - mode test vs production)        │
└─────────────────────────────────────────────────────────────┘
              │                            │
              ▼                            ▼
┌────────────────────────┐    ┌──────────────────────────┐
│  SubscriptionService   │    │  RevenueCatService       │
│  (DB + logique métier) │    │  (Achats in-app réels)   │
└────────────────────────┘    └──────────────────────────┘
              │                            │
              ▼                            ▼
┌────────────────────────┐    ┌──────────────────────────┐
│    Supabase DB         │    │  RevenueCat SDK          │
│    (user_subscriptions)│    │  (App Store / Play Store)│
└────────────────────────┘    └──────────────────────────┘
```

---

## ⚙️ Configuration RevenueCat Dashboard

### 1. Créer un compte RevenueCat

1. Aller sur [https://app.revenuecat.com](https://app.revenuecat.com)
2. Créer un compte gratuit
3. Créer un nouveau projet : **"Ryse"**

### 2. Ajouter les apps

#### iOS App
1. Dashboard > Apps > Add iOS App
2. **App Name** : Ryse iOS
3. **Bundle ID** : `com.yourcompany.ryseapp` (votre bundle ID)
4. Copier la **Apple API Key** (commence par `appl_`)

#### Android App
1. Dashboard > Apps > Add Android App
2. **App Name** : Ryse Android
3. **Package Name** : `com.yourcompany.ryseapp` (votre package name)
4. Copier la **Google API Key** (commence par `goog_`)

### 3. Créer l'Entitlement

1. Dashboard > Entitlements > Create Entitlement
2. **Identifier** : `premium`
3. **Display Name** : Premium Access
4. Save

### 4. Créer les Products

1. Dashboard > Products > Create Product

#### Weekly Product
- **Identifier** : `ryse_premium_weekly`
- **Type** : Subscription
- **Duration** : 1 week

#### Monthly Product
- **Identifier** : `ryse_premium_monthly`
- **Type** : Subscription
- **Duration** : 1 month

#### Yearly Product
- **Identifier** : `ryse_premium_yearly`
- **Type** : Subscription
- **Duration** : 1 year

### 5. Créer l'Offering

1. Dashboard > Offerings > Create Offering
2. **Identifier** : `default`
3. **Display Name** : Default Offering
4. Ajouter les 3 packages :
   - **Package Type** : Weekly → Product: `ryse_premium_weekly`
   - **Package Type** : Monthly → Product: `ryse_premium_monthly`
   - **Package Type** : Annual → Product: `ryse_premium_yearly`
5. Make Current

### 6. Lier l'Entitlement aux Products

1. Pour chaque product (weekly, monthly, yearly)
2. Edit Product > Entitlements
3. Cocher `premium`
4. Save

---

## 🍎 Configuration iOS

### 1. App Store Connect - Créer les In-App Purchases

1. Aller sur [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps > Votre app > Features > In-App Purchases
3. Cliquer sur **+** pour créer un nouveau subscription

#### Weekly Subscription
- **Reference Name** : Ryse Premium Weekly
- **Product ID** : `ryse_premium_weekly` (exactement comme RevenueCat)
- **Subscription Group** : Créer un groupe "Ryse Premium"
- **Subscription Duration** : 1 week
- **Price** : 2,99€
- **Free Trial** : 7 days (à configurer dans le groupe)

#### Monthly Subscription
- **Reference Name** : Ryse Premium Monthly
- **Product ID** : `ryse_premium_monthly`
- **Subscription Group** : Ryse Premium (même groupe)
- **Subscription Duration** : 1 month
- **Price** : 9,99€

#### Yearly Subscription
- **Reference Name** : Ryse Premium Yearly
- **Product ID** : `ryse_premium_yearly`
- **Subscription Group** : Ryse Premium (même groupe)
- **Subscription Duration** : 1 year
- **Price** : 69,99€

### 2. Configurer le Subscription Group

1. App Store Connect > Subscription Group "Ryse Premium"
2. Introductory Offer : **7-day Free Trial**
3. Type : Free (gratuit)
4. Save

### 3. Lier RevenueCat à App Store Connect

1. RevenueCat Dashboard > Apps > iOS App
2. Shared Secret : Obtenir de App Store Connect > My Apps > App Information > App-Specific Shared Secret
3. Coller dans RevenueCat
4. Save

### 4. Configurer iOS app (Xcode)

Ouvrir `ios/Runner.xcodeproj` dans Xcode :

#### Capabilities
1. Signing & Capabilities > + Capability
2. Ajouter **In-App Purchase**

#### Info.plist
Ajouter si nécessaire :
```xml
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

---

## 🤖 Configuration Android

### 1. Google Play Console - Créer les In-App Products

1. Aller sur [Google Play Console](https://play.google.com/console)
2. Votre app > Monetization > Subscriptions
3. Create subscription

#### Weekly Subscription
- **Product ID** : `ryse_premium_weekly`
- **Name** : Ryse Premium Weekly
- **Description** : Weekly subscription to Ryse Premium
- **Billing period** : 1 week
- **Price** : 2,99€
- **Free trial** : 7 days

#### Monthly Subscription
- **Product ID** : `ryse_premium_monthly`
- **Name** : Ryse Premium Monthly
- **Billing period** : 1 month
- **Price** : 9,99€

#### Yearly Subscription
- **Product ID** : `ryse_premium_yearly`
- **Name** : Ryse Premium Yearly
- **Billing period** : 1 year
- **Price** : 69,99€

### 2. Lier RevenueCat à Google Play

1. Créer un Service Account :
   - Google Cloud Console > IAM & Admin > Service Accounts
   - Create Service Account > Name: "RevenueCat"
   - Grant permissions : Projet > Viewer

2. Télécharger la clé JSON

3. RevenueCat Dashboard :
   - Apps > Android App > Service Credentials
   - Upload le fichier JSON
   - Save

### 3. Configurer Android app

#### android/app/build.gradle
Vérifier que le billing est configuré :
```gradle
dependencies {
    // Déjà inclus dans purchases_flutter
    // implementation 'com.android.billingclient:billing:5.2.0'
}
```

#### AndroidManifest.xml
Ajouter la permission (normalement déjà présente) :
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

---

## 🔑 Configuration des variables d'environnement

### Créer/Modifier les fichiers .env

#### .env.local (développement / test)
```bash
# Mode test (pas de vrais achats)
TEST_MODE=true

# RevenueCat API Keys (optionnel en test)
REVENUECAT_APPLE_API_KEY=your_apple_api_key_here
REVENUECAT_GOOGLE_API_KEY=your_google_api_key_here

# Autres configs existantes
GEMINI_API_KEY=...
SUPABASE_URL=...
```

#### .env.production (production)
```bash
# Mode production (vrais achats via RevenueCat)
TEST_MODE=false

# RevenueCat API Keys (OBLIGATOIRE en production)
REVENUECAT_APPLE_API_KEY=appl_xxxxxxxxxxxxxxxx
REVENUECAT_GOOGLE_API_KEY=goog_xxxxxxxxxxxxxxxx

# Autres configs existantes
GEMINI_API_KEY=...
SUPABASE_URL=...
```

### Lancer l'app avec les bonnes variables

```bash
# Développement (mode test)
flutter run --dart-define-from-file=.env.local

# Production (vrais achats)
flutter run --release --dart-define-from-file=.env.production

# Build pour production
flutter build ios --release --dart-define-from-file=.env.production
flutter build appbundle --release --dart-define-from-file=.env.production
```

---

## 🔌 Intégration dans l'app

### 1. Initialisation au démarrage (main.dart)

```dart
import 'package:ryse_app/services/unified_subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await Supabase.initialize(...);

  // Initialiser le service d'abonnement
  final subscriptionService = UnifiedSubscriptionService();
  await subscriptionService.initialize();

  runApp(MyApp());
}
```

### 2. Connexion utilisateur (auth_service.dart)

```dart
// Lors du login
Future<void> login(String email, String password) async {
  final response = await supabase.auth.signInWithPassword(...);

  if (response.user != null) {
    // Connecter à RevenueCat
    final subscriptionService = UnifiedSubscriptionService();
    await subscriptionService.login(response.user!.id);
  }
}

// Lors du logout
Future<void> logout() async {
  final subscriptionService = UnifiedSubscriptionService();
  await subscriptionService.logout();

  await supabase.auth.signOut();
}
```

### 3. Vérification d'accès aux features IA

```dart
import 'package:ryse_app/services/unified_subscription_service.dart';
import 'package:ryse_app/screens/paywall_screen.dart';

// Exemple : Scanner IA
Future<void> scanFood() async {
  final subscription = UnifiedSubscriptionService();

  // Vérifier si premium
  if (!subscription.isPremium) {
    // Afficher le paywall
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallScreen(
        context: PaywallContext.aiScanner,
      ),
    );

    if (result != true) return; // Utilisateur a refusé
  }

  // Continuer avec le scan IA
  // ...
}
```

### 4. Afficher le statut Premium

```dart
Widget build(BuildContext context) {
  return ListenableBuilder(
    listenable: UnifiedSubscriptionService(),
    builder: (context, _) {
      final subscription = UnifiedSubscriptionService();

      return Column(
        children: [
          if (subscription.isPremium)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else if (subscription.isInTrial)
            Text('Trial: ${subscription.trialDaysRemaining} jours restants')
          else
            TextButton(
              onPressed: () => _showPaywall(),
              child: Text('Passer à Premium'),
            ),
        ],
      );
    },
  );
}
```

---

## 🧪 Testing

### Mode Test (TEST_MODE=true)

En mode test, pas besoin de RevenueCat configuré :

```bash
# Lancer en mode test
flutter run --dart-define-from-file=.env.local
```

**Comportement** :
- ✅ Bouton "SIMULER PAIEMENT (TEST)" dans le paywall
- ✅ Pas d'appel à RevenueCat SDK
- ✅ Premium activé instantanément sans paiement
- ✅ Données sauvegardées dans Supabase uniquement

### Sandbox Testing (iOS)

1. Créer un compte Sandbox dans App Store Connect :
   - Users and Access > Sandbox Testers > +
   - Email : test@example.com (fictif)
   - Password : TestPassword123

2. Sur votre appareil iOS :
   - Settings > App Store > Sandbox Account
   - Se connecter avec le compte sandbox

3. Lancer l'app en mode production :
   ```bash
   flutter run --release --dart-define-from-file=.env.production
   ```

4. Tester l'achat :
   - Le compte sandbox sera utilisé
   - Pas de vrai paiement
   - Validations instantanées

### Sandbox Testing (Android)

1. Google Play Console > License Testing
2. Ajouter des emails de test

3. Installer l'app via Internal Testing track

4. Utiliser un compte Google dans la liste de test

---

## 🚀 Déploiement

### Checklist avant production

- [ ] RevenueCat Dashboard configuré
- [ ] Entitlement "premium" créé
- [ ] 3 products créés (weekly, monthly, yearly)
- [ ] Offering "default" créé et actif
- [ ] App Store Connect : 3 subscriptions créées
- [ ] App Store Connect : Trial 7 jours configuré
- [ ] Google Play Console : 3 subscriptions créées
- [ ] Variables d'environnement production configurées
- [ ] `TEST_MODE=false` dans .env.production
- [ ] API Keys RevenueCat copiées dans .env.production
- [ ] Test en sandbox iOS réussi
- [ ] Test en sandbox Android réussi

### Build production

```bash
# iOS
flutter build ios --release --dart-define-from-file=.env.production

# Android
flutter build appbundle --release --dart-define-from-file=.env.production
```

### Upload

- **iOS** : Via Xcode > Product > Archive > Upload to App Store
- **Android** : Via Google Play Console > Production > Upload AAB

---

## 🔧 Troubleshooting

### Erreur : "RevenueCat API key non configurée"

**Cause** : API key manquante dans .env

**Solution** :
```bash
# Vérifier .env.production
cat .env.production | grep REVENUECAT

# Ajouter si manquant
echo "REVENUECAT_APPLE_API_KEY=appl_xxxxx" >> .env.production
echo "REVENUECAT_GOOGLE_API_KEY=goog_xxxxx" >> .env.production
```

### Erreur : "No products available"

**Cause** : Products pas encore synchronisés

**Solutions** :
1. Vérifier que les Product IDs sont identiques (App Store Connect / RevenueCat)
2. Attendre 2-3 heures pour synchronisation Apple
3. Vérifier dans RevenueCat Dashboard > Products > Status
4. Tester en sandbox avec un compte test valide

### Erreur : "Purchase cancelled"

**Cause** : Utilisateur a annulé ou erreur d'authentification

**Solutions** :
1. iOS : Vérifier compte sandbox connecté
2. Android : Vérifier licence de test
3. Vérifier que l'app utilise le bon bundle ID / package name

### Trial ne fonctionne pas

**Cause** : Trial déjà utilisé avec ce compte

**Solution** :
- iOS : Créer un nouveau compte sandbox
- Android : Utiliser un autre compte Google de test
- RevenueCat cache l'historique par Apple ID / Google Account

### Synchronisation DB <-> RevenueCat

Le service `UnifiedSubscriptionService` synchronise automatiquement :

```dart
// Forcer une synchronisation manuelle
final service = UnifiedSubscriptionService();
await service.initialize(); // Sync automatique
```

---

## 📊 Monitoring

### RevenueCat Dashboard

- **Overview** : Revenus, nouveaux abonnés, churns
- **Customers** : Liste des utilisateurs avec statut
- **Charts** : MRR, conversion rate, retention

### Supabase

Créer une table pour les logs d'abonnement :

```sql
CREATE TABLE subscription_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL, -- 'trial_start', 'purchase', 'cancel', 'renew'
  product_id TEXT,
  revenue_cat_transaction_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 📚 Ressources

- [RevenueCat Docs](https://docs.revenuecat.com/)
- [Flutter SDK Reference](https://sdk.revenuecat.com/flutter/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Google Play Billing Docs](https://developer.android.com/google/play/billing)

---

## ✅ Résumé rapide

### Pour tester (mode développement)
```bash
flutter run --dart-define-from-file=.env.local
# Utiliser le bouton "SIMULER PAIEMENT (TEST)"
```

### Pour déployer (mode production)
1. Configurer RevenueCat Dashboard
2. Créer les subscriptions dans App Store Connect & Google Play
3. Copier les API keys dans .env.production
4. Build avec `--dart-define-from-file=.env.production`
5. Upload sur les stores

**Modèle final** :
- 2,99€/semaine
- 9,99€/mois
- 69,99€/an (économie 42%)
- Trial 7 jours gratuit
- 0 IA en gratuit après trial
