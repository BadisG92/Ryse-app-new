# RevenueCat - Architecture & Flow

## 🏗️ Architecture Globale

```
┌─────────────────────────────────────────────────────────────────┐
│                        RYSE APP                                 │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              UI Layer (Screens)                          │  │
│  │  • paywall_screen.dart                                   │  │
│  │  • ai_scanner_screen.dart                                │  │
│  │  • ai_analysis_screen.dart                               │  │
│  │  • etc.                                                   │  │
│  └──────────────────┬───────────────────────────────────────┘  │
│                     │                                           │
│                     ▼                                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │        UnifiedSubscriptionService                        │  │
│  │        (Test Mode + Production Mode)                     │  │
│  │                                                           │  │
│  │  • isPremium getter                                      │  │
│  │  • upgradeToPremium()                                    │  │
│  │  • initialize()                                          │  │
│  │  • login() / logout()                                    │  │
│  └──────┬────────────────────────────────────┬──────────────┘  │
│         │                                    │                 │
│         │ TEST_MODE=true                     │ TEST_MODE=false │
│         │                                    │                 │
│         ▼                                    ▼                 │
│  ┌──────────────────┐              ┌───────────────────────┐  │
│  │ SubscriptionSvc  │              │  RevenueCatService    │  │
│  │  (Test/Demo)     │              │  (Production)         │  │
│  │                  │              │                       │  │
│  │ • Simulations    │              │ • purchases_flutter   │  │
│  │ • Instant premium│              │ • Real purchases      │  │
│  └────────┬─────────┘              └──────────┬────────────┘  │
│           │                                   │                │
│           │                                   │                │
│           ▼                                   ▼                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              Supabase Database                          │  │
│  │  • user_subscriptions table                            │  │
│  │  • Subscription status sync                            │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
└────────────────────────────────┬───────────────────────────────┘
                                 │
                                 │ Production Mode Only
                                 ▼
┌────────────────────────────────────────────────────────────────┐
│                     RevenueCat Platform                        │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Products & Offerings                                    │ │
│  │  • ryse_premium_weekly                                   │ │
│  │  • ryse_premium_monthly                                  │ │
│  │  • ryse_premium_yearly                                   │ │
│  │  • Entitlement: "premium"                                │ │
│  └──────────────────┬───────────────────────────────────────┘ │
│                     │                                          │
│                     ▼                                          │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Customer Management                                     │ │
│  │  • User ID mapping (Supabase user ID)                    │ │
│  │  • Subscription status tracking                          │ │
│  │  • Trial management                                      │ │
│  └──────────────────┬───────────────────────────────────────┘ │
│                     │                                          │
└─────────────────────┼──────────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼                           ▼
┌───────────────────┐       ┌──────────────────┐
│  App Store        │       │  Google Play     │
│  Connect (iOS)    │       │  Console (Android)│
│                   │       │                  │
│ • Subscriptions   │       │ • Subscriptions  │
│ • Trial: 7 days   │       │ • Trial: 7 days  │
│ • P8 Key          │       │ • Service Account│
│ • Pricing Tiers   │       │ • Billing        │
└───────────────────┘       └──────────────────┘
```

---

## 🔄 User Flow - Purchase Journey

### 1. User Opens App (First Time)

```
User launches app
       │
       ▼
UnifiedSubscriptionService.initialize()
       │
       ├─> TEST_MODE=true  → SubscriptionService (local simulation)
       │
       └─> TEST_MODE=false → RevenueCatService.configure()
                                     │
                                     └─> Purchases.configure(apiKey)
```

### 2. User Tries Premium Feature (e.g., AI Scanner)

```
User clicks "AI Scanner"
       │
       ▼
Check: UnifiedSubscriptionService.isPremium
       │
       ├─> true  → Continue to AI Scanner
       │
       └─> false → Show PaywallScreen
                        │
                        ▼
                   User selects plan (Weekly/Monthly/Yearly)
                        │
                        ▼
                   UnifiedSubscriptionService.upgradeToPremium()
                        │
                        ├─> TEST_MODE=true
                        │        │
                        │        └─> SubscriptionService.upgradeToPremium()
                        │                  │
                        │                  └─> Insert into Supabase
                        │                           │
                        │                           └─> Premium ✅
                        │
                        └─> TEST_MODE=false
                                 │
                                 └─> RevenueCatService.purchase()
                                          │
                                          └─> Purchases.purchasePackage()
                                                   │
                                                   ├─> iOS → StoreKit → App Store
                                                   │
                                                   └─> Android → Google Play Billing
                                                            │
                                                            ▼
                                                   User confirms purchase
                                                            │
                                                            ▼
                                                   RevenueCat webhook
                                                            │
                                                            └─> Sync to Supabase
                                                                     │
                                                                     └─> Premium ✅
```

### 3. User Logs In

```
User logs in with email/password
       │
       ▼
AuthService.login()
       │
       └─> Supabase.auth.signInWithPassword()
                │
                └─> Success → UnifiedSubscriptionService.login(userId)
                                    │
                                    └─> TEST_MODE=false → RevenueCat.logIn(userId)
                                                                │
                                                                └─> Fetch subscription status
                                                                          │
                                                                          └─> Sync with Supabase
```

### 4. User Logs Out

```
User clicks logout
       │
       ▼
AuthService.logout()
       │
       ├─> UnifiedSubscriptionService.logout()
       │          │
       │          └─> TEST_MODE=false → RevenueCat.logOut()
       │
       └─> Supabase.auth.signOut()
```

---

## 📦 Service Responsibilities

### `UnifiedSubscriptionService`

**Rôle** : Orchestrateur principal (mode test + production)

**Responsabilités** :
- Déterminer le mode (test vs production)
- Router les appels vers le bon service
- Exposer une API unifiée simple

**Méthodes clés** :
```dart
Future<void> initialize()
Future<bool> upgradeToPremium({required SubscriptionPeriod period})
Future<void> login(String userId)
Future<void> logout()
bool get isPremium
```

---

### `RevenueCatService`

**Rôle** : Intégration SDK RevenueCat (production uniquement)

**Responsabilités** :
- Initialiser le SDK `purchases_flutter`
- Gérer les achats réels via App Store / Google Play
- Synchroniser l'état d'abonnement
- Restaurer les achats
- Gérer les webhooks (si nécessaire)

**Méthodes clés** :
```dart
Future<void> initialize({String? userId})
Future<bool> purchasePackage(Package package)
Future<List<Package>> getAvailablePackages()
Future<bool> restorePurchases()
bool get isPremium
```

---

### `SubscriptionService` (Existant)

**Rôle** : Service de test/simulation + Supabase sync

**Responsabilités** :
- Mode test : Simulations d'achat instantanées
- Gérer la table `user_subscriptions` dans Supabase
- Calculer l'expiration des abonnements
- Historique d'abonnement

**Méthodes clés** :
```dart
Future<bool> upgradeToPremium({required SubscriptionPeriod period, bool testBypass = false})
Future<bool> checkSubscriptionStatus()
Future<void> syncWithRevenueCat(...)
```

---

## 🔑 Configuration Files

### `subscription_config.dart`

**Rôle** : Configuration centralisée (single source of truth)

**Contient** :
```dart
// Pricing
static const double weeklyPrice = 2.99;
static const double monthlyPrice = 9.99;
static const double yearlyPrice = 69.99;

// Product IDs (must match stores)
static const String weeklyProductId = 'ryse_premium_weekly';
static const String monthlyProductId = 'ryse_premium_monthly';
static const String yearlyProductId = 'ryse_premium_yearly';

// RevenueCat IDs
static const String premiumEntitlementId = 'premium';
static const String defaultOfferingId = 'default';

// Trial
static const int trialDurationDays = 7;

// Features
static const List<String> freeFeatures = [...];
static const List<String> premiumOnlyFeatures = [...];

// Limits
static const int freeDailyAiScansLimit = 0;
static const int freeDailyNutritionAnalysisLimit = 0;
static const int freeDailyAiChatLimit = 0;
```

---

## 🎯 Product IDs Mapping

**CRITIQUE** : Les Product IDs doivent être **identiques** partout :

```
┌─────────────────────────────────────────────────────────────┐
│                    Product ID Mapping                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Code (subscription_config.dart):                          │
│    • ryse_premium_weekly                                   │
│    • ryse_premium_monthly                                  │
│    • ryse_premium_yearly                                   │
│                                                             │
│  ══════════════════════════════════════════════════════════│
│                                                             │
│  RevenueCat Dashboard > Products:                          │
│    • ryse_premium_weekly  ✅ (must match)                  │
│    • ryse_premium_monthly ✅ (must match)                  │
│    • ryse_premium_yearly  ✅ (must match)                  │
│                                                             │
│  ══════════════════════════════════════════════════════════│
│                                                             │
│  App Store Connect > Subscriptions:                        │
│    • ryse_premium_weekly  ✅ (must match)                  │
│    • ryse_premium_monthly ✅ (must match)                  │
│    • ryse_premium_yearly  ✅ (must match)                  │
│                                                             │
│  ══════════════════════════════════════════════════════════│
│                                                             │
│  Google Play Console > Subscriptions:                      │
│    • ryse_premium_weekly  ✅ (must match)                  │
│    • ryse_premium_monthly ✅ (must match)                  │
│    • ryse_premium_yearly  ✅ (must match)                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧪 Test Mode vs Production Mode

### Test Mode (`TEST_MODE=true`)

**Fichier** : `.env.local`

**Comportement** :
- Pas d'appel à RevenueCat SDK
- Bouton paywall : "🧪 SIMULER PAIEMENT (TEST)"
- Premium activé instantanément
- Données stockées dans Supabase uniquement
- Pour développement local

**Flow** :
```
User clicks "Upgrade"
       │
       └─> SubscriptionService.upgradeToPremium(testBypass: true)
                │
                └─> INSERT INTO user_subscriptions
                         │
                         └─> Premium ✅ (instant)
```

---

### Production Mode (`TEST_MODE=false`)

**Fichier** : `.env.production`

**Comportement** :
- Appels RevenueCat SDK
- Vrais achats (sandbox ou production selon build)
- Bouton paywall : "Continuer"
- Synchronisation RevenueCat ↔ Supabase
- Pour builds TestFlight / Play Store

**Flow** :
```
User clicks "Upgrade"
       │
       └─> RevenueCatService.purchase()
                │
                └─> Purchases.purchasePackage()
                         │
                         ├─> StoreKit (iOS) or Google Play Billing (Android)
                         │
                         └─> Success → RevenueCat webhook
                                  │
                                  └─> Sync to Supabase
                                           │
                                           └─> Premium ✅
```

---

## 🎨 Paywall UI Flow

```
┌────────────────────────────────────────┐
│         PaywallScreen                  │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │  Premium Benefits                │ │
│  │  • 🤖 IA illimitée                │ │
│  │  • 🏋️ Séances personnalisées     │ │
│  │  • 📊 Analyse quotidienne         │ │
│  │  • ... etc.                       │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │  Plans Selection                 │ │
│  │                                  │ │
│  │  ○ Weekly  - 2,99€/semaine      │ │
│  │  ● Monthly - 9,99€/mois         │ │ ← Selected
│  │  ○ Yearly  - 69,99€/an          │ │
│  │              (Économisez 42%)   │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │  🧪 SIMULER PAIEMENT (TEST)      │ │  ← TEST_MODE=true
│  │     ou                           │ │
│  │  Continuer                       │ │  ← TEST_MODE=false
│  └──────────────────────────────────┘ │
│                                        │
│  Essai gratuit de 7 jours             │
│  Annulable à tout moment              │
└────────────────────────────────────────┘
```

---

## 🔒 Premium Feature Protection

**Template de code pour protéger une feature IA** :

```dart
import 'package:ryse_app/services/unified_subscription_service.dart';
import 'package:ryse_app/screens/paywall_screen.dart';

class AiFeatureScreen extends StatefulWidget {
  // ...

  Future<void> _startAiFeature() async {
    final subscription = UnifiedSubscriptionService();

    // Check if user is premium
    if (!subscription.isPremium) {
      // Show paywall
      final upgraded = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PaywallScreen(
          context: PaywallContext.aiScanner, // ou aiChat, aiAnalysis, etc.
          customTitle: 'Feature IA Premium',
          customMessage: 'Cette fonctionnalité nécessite un abonnement Premium',
        ),
      );

      // User declined or cancelled
      if (upgraded != true) return;
    }

    // User is premium, continue with AI feature
    // ...
  }
}
```

**Features à protéger** :
- ✅ AI Food Scanner (`ai_scanner_screen.dart`)
- ✅ AI Nutrition Analysis (`ai_analysis_screen.dart`)
- ✅ AI Workout Generator
- ✅ AI Chat Nutrition
- ✅ AI Chat Sport
- ✅ AI Recipe Generator

---

## 📊 Data Flow - Subscription Status

### Création d'abonnement

```
User purchases subscription
       │
       ▼
RevenueCat receives purchase event
       │
       ├─> Creates Customer record
       │   • app_user_id: Supabase user ID
       │   • Entitlement: premium
       │   • Expiration: +7 days (trial)
       │
       └─> Webhook (optional) → Supabase
                │
                └─> INSERT/UPDATE user_subscriptions
                         │
                         ├─> user_id: Supabase user ID
                         ├─> subscription_period: 'monthly'
                         ├─> start_date: now
                         ├─> end_date: +1 month (after trial)
                         ├─> trial_end_date: +7 days
                         └─> status: 'active'
```

### Vérification d'abonnement (au lancement)

```
App launches
       │
       └─> UnifiedSubscriptionService.initialize()
                │
                └─> RevenueCatService.initialize(userId)
                         │
                         └─> Purchases.getCustomerInfo()
                                  │
                                  ├─> Entitlement 'premium' active?
                                  │        │
                                  │        ├─> Yes → isPremium = true
                                  │        │
                                  │        └─> No  → isPremium = false
                                  │
                                  └─> Sync with Supabase
                                           │
                                           └─> UPDATE user_subscriptions.status
```

---

## 🌍 Environment Variables

```
.env.local (Development)
├─> TEST_MODE=true
├─> No RevenueCat API Keys needed
└─> Local simulations only

.env.production (Staging/Production)
├─> TEST_MODE=false
├─> REVENUECAT_APPLE_API_KEY=appl_xxxxx
├─> REVENUECAT_GOOGLE_API_KEY=goog_xxxxx
└─> Real purchases via stores
```

**Build Commands** :

```bash
# Local development (test mode)
flutter run --dart-define-from-file=.env.local

# Sandbox testing (production mode with test accounts)
flutter run --release --dart-define-from-file=.env.production

# Production build
flutter build ios --release --dart-define-from-file=.env.production
flutter build appbundle --release --dart-define-from-file=.env.production
```

---

## 🔐 Security Best Practices

### ✅ DO
- Use environment variables for API keys
- Keep `.env.local` and `.env.production` in `.gitignore`
- Validate purchases server-side (RevenueCat does this)
- Use RevenueCat webhooks for real-time sync
- Implement restore purchases functionality

### ❌ DON'T
- Hardcode API keys in source code
- Commit `.env` files to Git
- Trust client-side subscription status alone
- Skip trial validation
- Expose Product IDs publicly (they're ok to be in code)

---

## 📈 Analytics & Monitoring

**RevenueCat Dashboard** fournit :
- Active subscriptions count
- Monthly Recurring Revenue (MRR)
- Churn rate
- Trial conversion rate
- Revenue by product
- Customer lifetime value (LTV)

**Intégrations possibles** :
- Slack notifications (trial expirations, new subscriptions)
- Amplitude / Mixpanel (product analytics)
- Segment (data pipeline)

---

## 🚀 Deployment Strategy

### Phase 1 : Configuration (Maintenant)
1. Créer compte RevenueCat
2. Configurer App Store Connect (iOS)
3. Configurer Google Play Console (Android)
4. Lier les comptes via P8 Key / Service Account
5. Créer Products + Offering + Entitlement

### Phase 2 : Tests (Sandbox)
1. Test mode local (`TEST_MODE=true`)
2. Sandbox iOS avec Sandbox Tester
3. Internal Testing Android
4. Vérifier webhooks RevenueCat
5. Valider synchronisation Supabase

### Phase 3 : Intégration App (Code)
1. Initialisation dans `main.dart`
2. Login/Logout dans `auth_service.dart`
3. Protéger features IA
4. Tester flows complets

### Phase 4 : Soft Launch
1. Build TestFlight (iOS)
2. Build Internal Testing (Android)
3. Tester avec vrais utilisateurs (beta)
4. Monitorer RevenueCat Dashboard
5. Ajuster si nécessaire

### Phase 5 : Production
1. Submit for Review (iOS + Android)
2. Approval (~1-7 jours)
3. Release graduel (10% → 50% → 100%)
4. Monitorer conversions & churn

---

## 🎯 Success Metrics

**Suivi à faire** :
- **Trial Start Rate** : % d'utilisateurs qui démarrent le trial
- **Trial Conversion Rate** : % de trials qui se convertissent en payants
- **Churn Rate** : % d'utilisateurs qui annulent par mois
- **ARPU** (Average Revenue Per User) : Revenu moyen par utilisateur
- **LTV** (Lifetime Value) : Revenu total par utilisateur sur sa durée de vie

**Objectifs suggérés** :
- Trial Start Rate : > 30% des nouveaux utilisateurs
- Trial Conversion : > 20% des trials → payants
- Churn Rate : < 5% par mois
- ARPU : > 5€/mois
- LTV : > 60€ (6 mois de rétention moyenne)

---

**Architecture RevenueCat prête ! 🚀**

Référez-vous à `REVENUECAT_CHECKLIST.md` pour la configuration complète.
