# 🚀 Déployer le Système d'Abonnement

## 📋 Checklist Déploiement

### 1. Migration Base de Données

```bash
# Aller dans le dossier du projet
cd "C:\rise app v2\ryze_app"

# Appliquer la migration Supabase
npx supabase db push

# Vérifier que la table existe
npx supabase db dump --schema public | grep user_subscriptions
```

### 2. Vérifier les Fichiers Créés

```
✅ lib/models/subscription_models.dart
✅ lib/services/subscription_service.dart
✅ lib/services/paywall_service.dart
✅ lib/screens/paywall_screen.dart
✅ lib/screens/pricing_screen.dart
✅ supabase/migrations/20250125_user_subscriptions.sql
```

### 3. Ajouter dans pubspec.yaml

```yaml
dependencies:
  # ... tes dépendances existantes ...
  shared_preferences: ^2.2.2  # Pour stocker limites quotidiennes
```

Installer:
```bash
flutter pub get
```

### 4. Initialiser dans main.dart

```dart
import 'services/subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase (déjà fait)
  await Supabase.initialize(...);

  // ✅ AJOUTER: Initialiser le service d'abonnement
  await SubscriptionService.instance.initialize();

  runApp(const MyApp());
}
```

### 5. Ajouter les Routes

```dart
// Dans MaterialApp
MaterialApp(
  routes: {
    // ... tes routes existantes ...
    '/pricing': (context) => const PricingScreen(),
  },
);
```

---

## 🧪 MODE TEST - Premiers Tests

### Test 1: Vérifier l'initialisation

```dart
// Dans n'importe quel écran
@override
void initState() {
  super.initState();
  SubscriptionService.instance.debugPrintSubscriptionInfo();
}
```

Console devrait afficher:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 SUBSCRIPTION INFO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tier: premium
Is Premium: true
Is Trial: true
Trial Days Remaining: 7
Period: null
Test Mode: true
Start Date: 2025-01-25...
Expiry Date: 2025-02-01...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Test 2: Afficher un Paywall

Dans ton scanner IA existant, ajoute avant le scan:

```dart
// ai_scanner_screen.dart
import '../services/paywall_service.dart';

Future<void> _takePicture() async {
  // ✅ AJOUTER CETTE VÉRIFICATION
  final canScan = await PaywallService.instance.checkDailyLimit(
    context: context,
    featureName: 'ai_scans',
    limit: 3,
    paywallContext: PaywallService.PaywallContext.aiScanLimit,
  );

  if (!canScan) {
    return; // Paywall affiché, user a refusé
  }

  // ✅ Continuer avec ton code existant
  // ... reste de ton code de scan ...
}
```

### Test 3: Simuler un Paiement

1. Être en mode Free (si besoin: `await SubscriptionService.instance.resetSubscription()`)
2. Déclencher un paywall (ex: 4ème scan du jour)
3. Voir le bouton vert "🧪 SIMULER PAIEMENT (TEST)"
4. Cliquer dessus
5. Vérifier qu'on devient Premium

Console:
```
🧪 TEST MODE: Upgrade to Premium (monthly)
✅ Subscription saved to database
```

### Test 4: Vérifier la Base de Données

```bash
# Ouvrir Supabase Studio
npx supabase start

# Aller sur http://localhost:54323
# Table Editor > user_subscriptions
# Vérifier qu'une ligne existe pour ton user
```

---

## 📊 Vérifications Importantes

### ✅ Mode TEST est activé

```dart
// subscription_service.dart
static const bool TEST_MODE = true; // ← Doit être true
```

### ✅ Trial auto pour nouveaux users

```dart
// subscription_service.dart, ligne ~45
if (_currentSubscription == null && TEST_MODE) {
  debugPrint('🧪 TEST MODE: Démarrage trial gratuit');
  await startTrial();
}
```

### ✅ Paywall affiche bouton TEST

```dart
// paywall_screen.dart, ligne ~145
if (SubscriptionService.TEST_MODE) ...[
  // Bouton vert "SIMULER PAIEMENT (TEST)"
```

---

## 🎯 Scénarios de Test Complets

### Scénario 1: Nouveau Utilisateur

```
1. Se connecter (nouveau compte)
2. Vérifier: debugPrintSubscriptionInfo()
   → Tier: premium
   → Is Trial: true
   → Trial Days: 7

3. Essayer features Premium
   → Scanner illimité: ✅ OK
   → Générateur workout: ✅ OK
   → Bilan nutrition: ✅ OK

4. Dans 7 jours (ou changer la date en DB)
   → Trial expire
   → Paywall "Ton essai se termine"
```

### Scénario 2: Utilisateur Free (après trial)

```
1. Reset: await resetSubscription()
2. Vérifier: debugPrintSubscriptionInfo()
   → Tier: free
   → Is Premium: false

3. Scanner 3 repas
   → 1er scan: ✅ OK
   → 2ème scan: ✅ OK
   → 3ème scan: ✅ OK
   → 4ème scan: ❌ Paywall "Limite atteinte"

4. Cliquer "SIMULER PAIEMENT (TEST)"
   → Devient Premium
   → 4ème scan: ✅ OK
```

### Scénario 3: Générateur Workout (Premium only)

```
1. Reset: await resetSubscription()
2. Cliquer générateur IA
   → ❌ Paywall "Générateur IA - Premium"

3. Cliquer "SIMULER PAIEMENT (TEST)"
   → Devient Premium
   → Générateur s'ouvre: ✅ OK
```

---

## 🐛 Debugging

### Problème: Paywall ne s'affiche pas

**Cause:** User déjà Premium

**Solution:**
```dart
// Vérifier
print('Is Premium: ${SubscriptionService.instance.isPremium}');

// Si true, reset
await SubscriptionService.instance.resetSubscription();
```

### Problème: "Table user_subscriptions doesn't exist"

**Cause:** Migration pas appliquée

**Solution:**
```bash
npx supabase db push
```

### Problème: Limite quotidienne ne fonctionne pas

**Cause:** Compteur pas incrémenté

**Solution:**
Vérifier que tu appelles bien:
```dart
await PaywallService.instance.checkDailyLimit(...);
// et PAS juste:
await SubscriptionService.instance.canUseDailyLimitedFeature(...);
```

`checkDailyLimit` fait les deux: vérifier + incrémenter

### Problème: Crash au lancement

**Cause:** Service pas initialisé

**Solution:**
```dart
// main.dart
await SubscriptionService.instance.initialize();
```

---

## 📈 Analytics à Ajouter (Futur)

```dart
// Tracker les événements
void trackPaywallShown(PaywallContext context) {
  // Firebase Analytics, Mixpanel, etc.
}

void trackPaywallConverted(SubscriptionPeriod period) {
  // User a payé
}

void trackPaywallDismissed() {
  // User a fermé sans payer
}
```

---

## 🔄 Migration vers Production

Quand tu es prêt:

### 1. Désactiver TEST_MODE

```dart
// subscription_service.dart
static const bool TEST_MODE = false; // ← Production!
```

### 2. Intégrer RevenueCat

```bash
flutter pub add purchases_flutter
```

```dart
// subscription_service.dart
import 'package:purchases_flutter/purchases_flutter.dart';

Future<bool> upgradeToPremium({...}) async {
  if (!TEST_MODE) {
    // Vrai paiement
    final offerings = await Purchases.getOfferings();
    final package = offerings.current?.monthly;

    try {
      final purchaserInfo = await Purchases.purchasePackage(package);

      if (purchaserInfo.entitlements.active.containsKey('premium')) {
        _currentSubscription = UserSubscription.premium(period: period);
        await _saveSubscriptionToDatabase();
        notifyListeners();
        return true;
      }
    } on PlatformException catch (e) {
      // Handle error
    }
    return false;
  }
  // ...
}
```

### 3. Configurer RevenueCat

1. Compte: https://app.revenuecat.com
2. Créer App
3. Produits:
   - `ryze_premium_weekly` → 2,99€
   - `ryze_premium_monthly` → 9,99€
   - `ryze_premium_annual` → 69,99€
4. Entitlement: `premium`
5. API keys → app

### 4. Tester en Sandbox

Apple/Google Sandbox pour tester vrais paiements sans charger.

---

## ✅ Checklist Finale

Avant de lancer:

- [ ] Migration DB appliquée
- [ ] Service initialisé dans main.dart
- [ ] Routes ajoutées
- [ ] Paywalls testés en mode TEST
- [ ] Limite quotidienne fonctionne
- [ ] Trial auto fonctionne
- [ ] Reset/Upgrade TEST fonctionnent
- [ ] RLS policies actives (Supabase)
- [ ] TEST_MODE = false (production)
- [ ] RevenueCat intégré (production)
- [ ] Produits configurés (App Store/Play Store)
- [ ] Sandbox testé

---

**Mode TEST :** ✅ Prêt à tester
**Documentation :** ✅ Complète
**Exemples :** ✅ Fournis
**Production :** ⏳ Après intégration paiements
