# 📱 Système d'Abonnement Ryze

## 🎯 Vue d'ensemble

Ryze utilise un système d'abonnement **Freemium** avec 2 tiers:
- **FREE**: Accès limité (3 scans IA/jour, 3 jours historique)
- **PREMIUM**: Accès illimité à toutes les features (9,99€/mois)

## 🧪 MODE TEST (Développement)

**⚠️ IMPORTANT:** Le mode TEST est **ACTIVÉ PAR DÉFAUT** dans `subscription_service.dart`:

```dart
static const bool TEST_MODE = true; // ← Change à false pour production
```

### En mode TEST:
- ✅ Les paywalls s'affichent normalement
- ✅ L'utilisateur peut cliquer "SIMULER PAIEMENT (TEST)"
- ✅ Il devient Premium instantanément **SANS paiement réel**
- ✅ Bouton vert "🧪 SIMULER PAIEMENT" pour identifier le mode test
- ✅ Parfait pour tester toutes les features Premium

### Pour passer en PRODUCTION:
1. Ouvrir `lib/services/subscription_service.dart`
2. Changer `TEST_MODE = true` → `TEST_MODE = false`
3. Intégrer RevenueCat/Stripe pour les vrais paiements

---

## 📋 Architecture

### Fichiers créés

```
lib/
├── models/
│   └── subscription_models.dart          # Modèles de données
│       ├─ UserSubscription               # État de l'abonnement user
│       ├─ SubscriptionTier (enum)        # free, premium
│       ├─ SubscriptionPeriod (enum)      # weekly, monthly, annual, lifetime
│       ├─ SubscriptionPlan               # Tarifs et descriptions
│       └─ PremiumFeature                 # Features pour affichage
│
├── services/
│   ├── subscription_service.dart         # Logique métier
│   │   ├─ initialize()                   # Charger l'abonnement au démarrage
│   │   ├─ isPremium                      # Vérifier si user est Premium
│   │   ├─ startTrial()                   # Démarrer trial 7 jours
│   │   ├─ upgradeToPremium()             # Upgrade (TEST ou vrai paiement)
│   │   ├─ canAccessFeature()             # Vérifier accès feature
│   │   └─ checkDailyLimit()              # Gérer limites quotidiennes
│   │
│   └── paywall_service.dart              # Gestion des paywalls
│       ├─ showPaywall()                  # Afficher paywall modal
│       ├─ PaywallContext (enum)          # Contextes de paywall
│       └─ getPaywallContent()            # Messages personnalisés
│
└── screens/
    ├── paywall_screen.dart               # Écran de paywall (bottom sheet)
    └── pricing_screen.dart               # Page tarifs complète
```

### Base de données

```sql
-- Table: user_subscriptions
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  tier TEXT ('free', 'premium'),
  period TEXT ('weekly', 'monthly', 'annual', 'lifetime'),
  start_date TIMESTAMPTZ,
  expiry_date TIMESTAMPTZ,
  is_test_mode BOOLEAN,
  is_trial BOOLEAN,
  trial_end_date TIMESTAMPTZ,
  ...
);
```

Migration: `supabase/migrations/20250125_user_subscriptions.sql`

---

## 🚀 Utilisation

### 1. Initialiser le service

```dart
// Dans main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(...);

  // Initialiser le service d'abonnement
  await SubscriptionService.instance.initialize();

  runApp(MyApp());
}
```

### 2. Vérifier si user est Premium

```dart
final subscriptionService = SubscriptionService.instance;

if (subscriptionService.isPremium) {
  // Accès total
} else {
  // Afficher paywall
}
```

### 3. Afficher un paywall

```dart
import '../services/paywall_service.dart';

// Vérifier limite quotidienne (ex: scans IA)
final canScan = await PaywallService.instance.checkDailyLimit(
  context: context,
  featureName: 'ai_scans',
  limit: 3, // 3 scans/jour en Free
  paywallContext: PaywallService.PaywallContext.aiScanLimit,
);

if (canScan) {
  // Faire le scan
  await doAIScan();
}
```

### 4. Vérifier accès à une feature

```dart
// Vérifier si user peut accéder au générateur de workouts
final canAccess = await PaywallService.instance.canAccessFeature(
  context: context,
  featureName: 'ai_workout_generator',
  paywallContext: PaywallService.PaywallContext.workoutGenerator,
);

if (canAccess) {
  // Naviguer vers le générateur
  Navigator.push(...);
}
```

---

## 🎨 Paywalls Disponibles

```dart
enum PaywallContext {
  aiScanLimit,          // "🔥 Limite atteinte - 3 scans/jour"
  historyLimit,         // "⚠️ Historique limité - 3 jours"
  workoutGenerator,     // "🤖 Générateur IA - Premium"
  nutritionAnalysis,    // "📊 Bilan IA - Premium"
  trialEnded,          // "🎉 Fin du trial - Passe Premium"
  recipeLimit,         // "🍳 Limite recettes - 3 max"
  exportData,          // "📄 Export - Premium"
  advancedCharts,      // "📈 Graphiques - Premium"
  offlineMode,         // "✈️ Mode offline - Premium"
  genericUpgrade,      // "💎 Passe Premium"
}
```

Chaque contexte a un message personnalisé en FR/EN.

---

## 💎 Features Premium vs Free

### FREE (Gratuit)
- ✅ 3 scans IA/jour
- ✅ Tracking manuel illimité
- ✅ 3 jours d'historique
- ✅ 3 workouts pré-définis
- ✅ 3 recettes max
- ✅ Calcul calories/macros basique
- ⚠️ Bannière pub discrète

### PREMIUM (9,99€/mois)
- ✅ **Scans IA ILLIMITÉS** (Gemini 2.0 Flash)
- ✅ **Bilan nutritionnel quotidien** (Coach Ryze IA)
- ✅ **Générateur de séances IA** (personnalisé)
- ✅ **Chat nutrition IA** (texte/voix)
- ✅ Historique illimité
- ✅ Tous les workouts (HIIT/Cardio/Muscu)
- ✅ Recettes illimitées
- ✅ Export PDF/Excel
- ✅ Graphiques avancés
- ✅ Mode offline complet
- ✅ 0 pub

---

## 📊 Grille Tarifaire

| Plan | Prix | Prix/mois | Économie |
|------|------|-----------|----------|
| **Weekly** | 2,99€/sem | ~12,96€ | - |
| **Monthly** | 9,99€/mois | 9,99€ | - |
| **Annual** | 69,99€/an | 5,83€ | **-42%** ⭐ |
| **Lifetime** | 299€ | - | - |

---

## 🧪 Tests à Faire

### En mode TEST (TEST_MODE = true)

**Test 1: Trial gratuit**
```
1. Nouveau utilisateur se connecte
2. Vérifier qu'il a un trial de 7 jours auto
3. Vérifier qu'il voit "Trial - 7 jours restants"
4. Essayer features Premium → OK
```

**Test 2: Limite scans (Free)**
```
1. Downgrade vers Free: subscriptionService.downgradeToFree()
2. Scanner 3 repas → OK
3. Scanner 4ème repas → Paywall "Limite atteinte"
4. Cliquer "SIMULER PAIEMENT (TEST)"
5. Vérifier qu'il devient Premium
6. Scanner 4ème repas → OK
```

**Test 3: Générateur workouts (Premium only)**
```
1. Mode Free
2. Cliquer générateur IA → Paywall
3. Simuler paiement → Premium
4. Générateur IA → OK
```

**Test 4: Bilan nutritionnel (Premium only)**
```
1. Mode Free
2. Demander bilan → Paywall
3. Simuler paiement → Premium
4. Bilan généré → OK
```

### Commandes Debug

```dart
// Afficher infos abonnement
SubscriptionService.instance.debugPrintSubscriptionInfo();

// Reset vers Free
await SubscriptionService.instance.resetSubscription();

// Upgrade manuel (TEST)
await SubscriptionService.instance.upgradeToPremium(
  period: SubscriptionPeriod.monthly,
  testBypass: true,
);
```

---

## 🔄 Flux Utilisateur

### Nouveau Utilisateur
```
1. Inscription/Login
2. initialize() → Trial 7 jours auto (si TEST_MODE)
3. Accès Premium pendant 7 jours
4. Jour 7 → Paywall "Ton essai se termine"
5. Upgrade ou Downgrade vers Free
```

### Utilisateur Free
```
1. Utilise features limitées
2. Hit limite (scan, historique, etc.)
3. Paywall s'affiche
4. Choice:
   - Upgrade Premium → Accès illimité
   - Continue Free → Limite reste
```

### Utilisateur Premium
```
1. Paie 9,99€/mois (ou autre)
2. Accès illimité à tout
3. Pas de paywalls
4. Peut downgrade n'importe quand
```

---

## 🛠️ Migration vers Production

Quand tu es prêt pour les vrais paiements:

### 1. Intégrer RevenueCat

```dart
// pubspec.yaml
dependencies:
  purchases_flutter: ^6.0.0

// subscription_service.dart
Future<bool> upgradeToPremium({...}) async {
  if (!TEST_MODE) {
    // Vrai paiement via RevenueCat
    final offerings = await Purchases.getOfferings();
    final package = offerings.current?.monthly;

    final purchaserInfo = await Purchases.purchasePackage(package);

    if (purchaserInfo.entitlements.active.containsKey('premium')) {
      _currentSubscription = UserSubscription.premium(period: period);
      await _saveSubscriptionToDatabase();
      notifyListeners();
      return true;
    }
  }
  ...
}
```

### 2. Configurer RevenueCat

1. Créer compte: https://app.revenuecat.com
2. Configurer App Store Connect / Google Play
3. Créer produits:
   - `ryze_premium_weekly` → 2,99€/sem
   - `ryze_premium_monthly` → 9,99€/mois
   - `ryze_premium_annual` → 69,99€/an
4. Créer entitlement: `premium`
5. Copier API keys dans l'app

### 3. Désactiver TEST_MODE

```dart
// subscription_service.dart
static const bool TEST_MODE = false; // ← Production!
```

### 4. Tester les vrais paiements

Utiliser le Sandbox d'Apple/Google pour tester.

---

## 📈 Analytics à Tracker

```dart
// Conversions
- Trial started
- Trial → Premium
- Free → Premium
- Premium → Canceled

// Paywalls
- Paywall shown (context)
- Paywall dismissed
- Paywall converted

// Revenue
- MRR (Monthly Recurring Revenue)
- ARR (Annual Recurring Revenue)
- ARPU (Average Revenue Per User)
- Churn rate
```

---

## 🐛 Troubleshooting

### "Abonnement null"
```dart
// Vérifier initialisation
await SubscriptionService.instance.initialize();
```

### "Paywall ne s'affiche pas"
```dart
// Vérifier si déjà Premium
final isPremium = SubscriptionService.instance.isPremium;
print('Is Premium: $isPremium'); // false = paywall devrait s'afficher
```

### "Mode TEST ne fonctionne pas"
```dart
// Vérifier la constante
print(SubscriptionService.TEST_MODE); // true = mode test activé
```

### "Limite quotidienne ne reset pas"
Les limites sont stockées par jour (YYYY-MM-DD) dans SharedPreferences.
Elles reset automatiquement à minuit.

---

## 📚 Ressources

- **RevenueCat Docs**: https://docs.revenuecat.com
- **Flutter IAP**: https://pub.dev/packages/in_app_purchase
- **Stripe**: https://stripe.com/docs/payments

---

**Mode TEST activé :** ✅
**Prêt pour tester :** ✅
**Production ready :** ⏳ (après intégration paiements)
