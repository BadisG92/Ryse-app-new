# RevenueCat - Checklist de Configuration Complète

## ✅ Configuration Technique (Terminé)

### Code & Dependencies
- ✅ `purchases_flutter: ^8.3.3` ajouté à pubspec.yaml
- ✅ `lib/config/subscription_config.dart` créé (prix, IDs, features)
- ✅ `lib/services/revenuecat_service.dart` créé
- ✅ `lib/services/unified_subscription_service.dart` créé
- ✅ `lib/screens/paywall_screen.dart` mis à jour
- ✅ Dependencies installées (`flutter pub get`)

### iOS Configuration
- ✅ `ios/Runner/Info.plist` : SKAdNetwork items ajoutés (32 identifiants)
- ✅ `ios/Runner.xcodeproj` : StoreKit.framework déjà lié
- ⚠️ **À FAIRE** : Ajouter capability "In-App Purchase" dans Xcode
  ```bash
  open ios/Runner.xcworkspace
  # Runner > Signing & Capabilities > + Capability > In-App Purchase
  ```

### Android Configuration
- ✅ `android/app/src/main/AndroidManifest.xml` : Permission BILLING ajoutée
- ✅ Prêt pour Google Play Billing

---

## 🏪 Configuration des Stores

### RevenueCat Dashboard

#### 1. Projet & Apps
- [ ] Compte RevenueCat créé sur https://app.revenuecat.com
- [ ] Projet "Ryse" créé
- [ ] iOS App ajoutée → **Apple API Key** copié (`appl_xxxxxx`)
- [ ] Android App ajoutée → **Google API Key** copié (`goog_xxxxxx`)

#### 2. Entitlement
- [ ] Entitlement créé : `premium`
  - Display Name : "Premium Access"

#### 3. Products (IMPORTANT : Vérifier les IDs)
Créer 3 products avec ces identifiants **EXACTS** :

- [ ] Product 1 : `ryse_premium_weekly`
  - Type : Subscription
  - App Store Product ID : `ryse_premium_weekly`
  - Play Store Product ID : `ryse_premium_weekly`
  - Attach Entitlement : `premium`

- [ ] Product 2 : `ryse_premium_monthly`
  - Type : Subscription
  - App Store Product ID : `ryse_premium_monthly`
  - Play Store Product ID : `ryse_premium_monthly`
  - Attach Entitlement : `premium`

- [ ] Product 3 : `ryse_premium_yearly`
  - Type : Subscription
  - App Store Product ID : `ryse_premium_yearly`
  - Play Store Product ID : `ryse_premium_yearly`
  - Attach Entitlement : `premium`

**⚠️ ATTENTION** : Si vous aviez créé des products avec les IDs "monthly", "weekly", "yearly", **supprimez-les** et recréez avec les bons IDs ci-dessus.

#### 4. Offering
- [ ] Offering créé : `default`
  - Description : "Default Premium Offering"
  - Packages :
    - `$rc_weekly` → Product : `ryse_premium_weekly`
    - `$rc_monthly` → Product : `ryse_premium_monthly`
    - `$rc_annual` → Product : `ryse_premium_yearly`
  - **Make Current** activé

---

### App Store Connect (iOS)

#### 1. Subscription Group
- [ ] Subscription Group créé : `Ryse Premium`

#### 2. Subscriptions (3 à créer)

**Weekly** :
```
Reference Name: Ryse Premium Weekly
Product ID: ryse_premium_weekly
Subscription Group: Ryse Premium
Duration: 1 Week
Pricing: Tier 3 (2,99€)
```

**Monthly** :
```
Reference Name: Ryse Premium Monthly
Product ID: ryse_premium_monthly
Subscription Group: Ryse Premium
Duration: 1 Month
Pricing: Tier 10 (9,99€)
```

**Yearly** :
```
Reference Name: Ryse Premium Yearly
Product ID: ryse_premium_yearly
Subscription Group: Ryse Premium
Duration: 1 Year
Pricing: Tier 35 (69,99€)
```

#### 3. Free Trial (7 jours)
- [ ] Dans le **Subscription Group** "Ryse Premium"
- [ ] Section : **Introductory Offers** ou **Offers**
- [ ] Cliquer : **Set Up Introductory Offer**
- [ ] Configuration :
  ```
  Type: Free Trial
  Duration: 7 days
  Eligibility: New Subscribers
  Apply to: All subscriptions in this group
  ```

#### 4. Localisation (FR + EN)

**Pour chaque subscription**, ajouter :

**Français** :
```
Display Name (55 char max):
  - Weekly: "Premium hebdomadaire"
  - Monthly: "Premium mensuel"
  - Yearly: "Premium annuel"

Description:
Débloquez toutes les fonctionnalités IA de Ryse :
• Scanner IA illimité
• Analyse nutrition quotidienne
• Générateur de séances sport
• Chat nutrition & sport IA
• Recettes illimitées
• Historique complet
• Export de données
• Sans publicité

Essai gratuit de 7 jours. Annulable à tout moment.
```

**Anglais** :
```
Display Name (55 char max):
  - Weekly: "Premium Weekly"
  - Monthly: "Premium Monthly"
  - Yearly: "Premium Yearly"

Description:
Unlock all Ryse AI features:
• Unlimited AI food scanner
• Daily nutrition analysis
• Sport workout generator
• Nutrition & sport AI chat
• Unlimited recipes
• Complete history
• Data export
• Ad-free

7-day free trial. Cancel anytime.
```

#### 5. P8 Key & RevenueCat Integration
- [ ] App Store Connect > Users and Access > Integrations
- [ ] Generate In-App Purchase Key (P8)
- [ ] Télécharger le fichier `.p8`
- [ ] Copier **Key ID** et **Issuer ID**
- [ ] RevenueCat > iOS App > App Store Connect > Upload P8 Key
- [ ] Coller Key ID et Issuer ID

#### 6. Sandbox Tester
- [ ] App Store Connect > Users and Access > Sandbox Testers
- [ ] Créer un testeur :
  ```
  First Name: Test
  Last Name: User
  Email: testuser1@ryse.test (fictif unique)
  Password: TestRyse2024!
  Country: France
  ```

---

### Google Play Console (Android)

#### 1. Subscriptions (3 à créer)

**Weekly** :
```
Product ID: ryse_premium_weekly
Name: Ryse Premium Weekly
Description: Weekly subscription to all Ryse Premium features
Billing period: 1 week
Free trial: 7 days
Price: 2,99€
```

**Monthly** :
```
Product ID: ryse_premium_monthly
Name: Ryse Premium Monthly
Description: Monthly subscription to all Ryse Premium features
Billing period: 1 month
Free trial: 7 days
Price: 9,99€
```

**Yearly** :
```
Product ID: ryse_premium_yearly
Name: Ryse Premium Yearly
Description: Yearly subscription to all Ryse Premium features (Save 42%)
Billing period: 1 year
Free trial: 7 days
Price: 69,99€
```

#### 2. Service Account (Pour RevenueCat)
- [ ] Google Cloud Console > IAM & Admin > Service Accounts
- [ ] Create Service Account : "RevenueCat"
- [ ] Role : Project > Viewer
- [ ] Keys > Add Key > Create new key (JSON)
- [ ] Télécharger `revenuecat-xxxxx.json`

#### 3. Lier Service Account à Google Play
- [ ] Google Play Console > Setup > API access
- [ ] Service accounts > Grant access
- [ ] Sélectionner "RevenueCat"
- [ ] App permissions :
  - Select app : Ryse
  - Financial data : View only
  - Orders and subscriptions : View only
- [ ] Apply

#### 4. Upload Service Account dans RevenueCat
- [ ] RevenueCat Dashboard > Android App > Service Credentials
- [ ] Upload JSON file (`revenuecat-xxxxx.json`)
- [ ] Save

#### 5. License Testing
- [ ] Google Play Console > Setup > License Testing
- [ ] Ajouter votre email de test
- [ ] Test response : RESPOND_NORMALLY

---

## 🔑 Variables d'Environnement

### Fichier `.env.production`
- [ ] Créer/modifier `.env.production` :

```bash
# Mode production (vrais achats)
TEST_MODE=false

# RevenueCat API Keys (à remplir avec vos vraies clés)
REVENUECAT_APPLE_API_KEY=appl_xxxxxxxxxxxxxxxx
REVENUECAT_GOOGLE_API_KEY=goog_xxxxxxxxxxxxxxxx

# Autres configs (déjà présentes)
GEMINI_API_KEY=...
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

### Fichier `.env.local` (Test)
- [ ] Vérifier `.env.local` :

```bash
# Mode test (pas de vrais achats)
TEST_MODE=true

# RevenueCat optionnel en mode test
# REVENUECAT_APPLE_API_KEY=
# REVENUECAT_GOOGLE_API_KEY=

# Autres configs
GEMINI_API_KEY=...
SUPABASE_URL=...
```

---

## 🧪 Tests

### Test Mode (Local)
- [ ] Lancer en mode test :
  ```bash
  flutter run --dart-define-from-file=.env.local
  ```
- [ ] Déclencher un paywall (ex: scanner IA)
- [ ] Vérifier bouton : "🧪 SIMULER PAIEMENT (TEST)"
- [ ] Cliquer → Premium activé instantanément
- [ ] Vérifier dans Supabase que `user_subscriptions` est mis à jour

### Sandbox iOS
- [ ] iPhone Settings > App Store > Sandbox Account
- [ ] Se connecter avec le Sandbox Tester
- [ ] Lancer :
  ```bash
  flutter run --release --dart-define-from-file=.env.production
  ```
- [ ] Ouvrir paywall > Sélectionner un plan
- [ ] Confirmer achat (gratuit avec trial)
- [ ] ✅ Premium activé
- [ ] Vérifier RevenueCat Dashboard > Customers > Votre user ID

### Sandbox Android
- [ ] Build :
  ```bash
  flutter build appbundle --release --dart-define-from-file=.env.production
  ```
- [ ] Upload sur Internal Testing
- [ ] Installer via lien de test
- [ ] Ouvrir paywall > Acheter
- [ ] ✅ Premium activé

---

## 🔗 Intégration dans l'App

### 1. Initialisation dans `main.dart`
- [ ] Ajouter dans `main()` :
```dart
import 'package:ryse_app/services/unified_subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(...); // Déjà présent

  // Initialiser le service d'abonnement
  final subscriptionService = UnifiedSubscriptionService();
  await subscriptionService.initialize();

  runApp(MyApp());
}
```

### 2. Login/Logout dans `auth_service.dart`
- [ ] Dans `login()` :
```dart
Future<void> login(String email, String password) async {
  final response = await supabase.auth.signInWithPassword(...);

  if (response.user != null) {
    final subscriptionService = UnifiedSubscriptionService();
    await subscriptionService.login(response.user!.id);
  }
}
```

- [ ] Dans `logout()` :
```dart
Future<void> logout() async {
  final subscriptionService = UnifiedSubscriptionService();
  await subscriptionService.logout();

  await supabase.auth.signOut();
}
```

### 3. Protéger les features IA
- [ ] Scanner IA (`ai_scanner_screen.dart`)
- [ ] Analyse nutrition (`ai_analysis_screen.dart`)
- [ ] Générateur séances sport
- [ ] Chat IA nutrition
- [ ] Chat IA sport
- [ ] Générateur recettes IA

**Template de code** :
```dart
import 'package:ryse_app/services/unified_subscription_service.dart';
import 'package:ryse_app/screens/paywall_screen.dart';

Future<void> _startAiFeature() async {
  final subscription = UnifiedSubscriptionService();

  if (!subscription.isPremium) {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallScreen(
        context: PaywallContext.aiScanner, // ou aiChat, aiAnalysis, etc.
      ),
    );

    if (result != true) return;
  }

  // Continuer avec la feature IA
}
```

---

## 📊 Récapitulatif des Product IDs

| Période | Product ID | Prix | Apple Tier | Trial |
|---------|-----------|------|------------|-------|
| Weekly | `ryse_premium_weekly` | 2,99€ | Tier 3 | 7 jours |
| Monthly | `ryse_premium_monthly` | 9,99€ | Tier 10 | 7 jours |
| Yearly | `ryse_premium_yearly` | 69,99€ | Tier 35 | 7 jours |

**⚠️ IMPORTANT** : Ces IDs doivent être **identiques** dans :
- RevenueCat Dashboard (Products)
- App Store Connect (Subscriptions)
- Google Play Console (Subscriptions)
- Code (`lib/config/subscription_config.dart`)

---

## 🚀 Checklist Finale Avant Production

- [ ] Compte RevenueCat créé et API Keys copiées
- [ ] App Store Connect : 3 subscriptions + trial 7j configurés
- [ ] Google Play Console : 3 subscriptions + Service Account
- [ ] P8 Key iOS uploadé dans RevenueCat
- [ ] Service Account Android uploadé dans RevenueCat
- [ ] `.env.production` contient les API Keys RevenueCat
- [ ] Xcode : Capability "In-App Purchase" ajoutée
- [ ] Test sandbox iOS réussi
- [ ] Test sandbox Android réussi
- [ ] Initialisation ajoutée dans `main.dart`
- [ ] Login/Logout intégrés avec RevenueCat
- [ ] Features IA protégées par check Premium
- [ ] Build production testé

---

## 📚 Ressources

- **RevenueCat Dashboard** : https://app.revenuecat.com
- **App Store Connect** : https://appstoreconnect.apple.com
- **Google Play Console** : https://play.google.com/console
- **RevenueCat Docs** : https://docs.revenuecat.com/
- **Flutter SDK** : https://sdk.revenuecat.com/flutter/

---

## ❓ Troubleshooting

### Erreur "Invalid Product ID"
→ Vérifier que les Product IDs sont identiques dans RevenueCat, App Store Connect, et Google Play Console

### Trial ne s'affiche pas
→ Le trial est configuré au niveau du **Subscription Group**, pas des subscriptions individuelles

### Sandbox Tester ne fonctionne pas
→ Se déconnecter du vrai App Store dans Settings > App Store avant de tester

### RevenueCat ne trouve pas les products
→ Attendre 24h après création dans App Store Connect / Google Play Console

### "Entitlement not found"
→ Vérifier que les 3 products ont bien l'entitlement `premium` attaché

---

**Bon courage ! 🚀**

Référez-vous à `REVENUECAT_SETUP.md` et `STORE_CONFIGURATION_QUICK_GUIDE.md` pour plus de détails.
