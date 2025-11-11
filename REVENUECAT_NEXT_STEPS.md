# RevenueCat - Prochaines Étapes

## ✅ Ce qui a été fait

### 1. Code implémenté
- ✅ Dépendance `purchases_flutter: ^8.3.3` ajoutée
- ✅ [subscription_config.dart](lib/config/subscription_config.dart) - Configuration centralisée (prix, IDs, features)
- ✅ [revenuecat_service.dart](lib/services/revenuecat_service.dart) - Service RevenueCat pour achats réels
- ✅ [unified_subscription_service.dart](lib/services/unified_subscription_service.dart) - Service unifié (test + production)
- ✅ [paywall_screen.dart](lib/screens/paywall_screen.dart) - Écran paywall mis à jour
- ✅ Dependencies installées avec `flutter pub get`

### 2. Documentation créée
- ✅ [REVENUECAT_SETUP.md](REVENUECAT_SETUP.md) - Guide complet d'implémentation
- ✅ [STORE_CONFIGURATION_QUICK_GUIDE.md](STORE_CONFIGURATION_QUICK_GUIDE.md) - Guide rapide stores
- ✅ Ce fichier - Next steps

### 3. Modèle d'abonnement défini
- ✅ Weekly : 2,99€/semaine
- ✅ Monthly : 9,99€/mois
- ✅ Yearly : 69,99€/an (économie 42%)
- ✅ Trial : 7 jours gratuits
- ✅ Gratuit : 0 accès IA après trial

---

## 🚧 Prochaines étapes (à faire par vous)

### Étape 1 : Créer un compte RevenueCat (15 min)

1. Aller sur https://app.revenuecat.com
2. Créer un compte gratuit
3. Créer un projet "Ryse"
4. Suivre : [STORE_CONFIGURATION_QUICK_GUIDE.md](STORE_CONFIGURATION_QUICK_GUIDE.md) section "RevenueCat Dashboard"

**Résultat attendu** :
- Apple API Key (format : `appl_xxxxxx`)
- Google API Key (format : `goog_xxxxxx`)

---

### Étape 2 : Configurer App Store Connect (30-45 min)

**Prérequis** : Compte Apple Developer actif

1. Suivre : [STORE_CONFIGURATION_QUICK_GUIDE.md](STORE_CONFIGURATION_QUICK_GUIDE.md) section "App Store Connect"
2. Créer 3 subscriptions :
   - `ryse_premium_weekly`
   - `ryse_premium_monthly`
   - `ryse_premium_yearly`
3. Configurer le trial 7 jours
4. Créer un Sandbox Tester
5. Copier le Shared Secret dans RevenueCat

**Résultat attendu** :
- 3 subscriptions créées avec les bons Product IDs
- Trial 7 jours configuré
- Sandbox Tester prêt

---

### Étape 3 : Configurer Google Play Console (30-45 min)

**Prérequis** : Compte Google Play Developer actif

1. Suivre : [STORE_CONFIGURATION_QUICK_GUIDE.md](STORE_CONFIGURATION_QUICK_GUIDE.md) section "Google Play Console"
2. Créer 3 subscriptions :
   - `ryse_premium_weekly`
   - `ryse_premium_monthly`
   - `ryse_premium_yearly`
3. Créer un Service Account
4. Télécharger la clé JSON
5. Uploader la clé JSON dans RevenueCat
6. Configurer License Testing

**Résultat attendu** :
- 3 subscriptions créées
- Service Account JSON uploadé dans RevenueCat
- Email de test ajouté

---

### Étape 4 : Configurer les variables d'environnement (5 min)

1. Créer/modifier `.env.production` :

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

2. Garder `.env.local` pour les tests :

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

**Important** : Ne jamais commit les fichiers `.env.*` (déjà dans `.gitignore`)

---

### Étape 5 : Tester en mode Test (local) (10 min)

```bash
# Lancer en mode test
flutter run --dart-define-from-file=.env.local
```

**Tests à faire** :
1. Ouvrir l'app
2. Déclencher un paywall (ex: scanner IA)
3. Vérifier que le bouton est "🧪 SIMULER PAIEMENT (TEST)"
4. Cliquer dessus
5. ✅ Premium doit être activé instantanément
6. Vérifier dans Supabase que `user_subscriptions` est mis à jour

---

### Étape 6 : Tester en Sandbox (iOS) (20 min)

**Prérequis** : Étapes 1-4 terminées

1. Sur votre iPhone :
   - Settings > App Store > Sandbox Account
   - Se connecter avec le Sandbox Tester créé

2. Lancer l'app en mode production :
   ```bash
   flutter run --release --dart-define-from-file=.env.production
   ```

3. Tests :
   - Ouvrir le paywall
   - Sélectionner un plan (ex: Monthly)
   - Cliquer sur "Continuer"
   - Se connecter avec le Sandbox Tester
   - Confirmer l'achat (gratuit avec trial)
   - ✅ Premium doit être activé

4. Vérifier :
   - RevenueCat Dashboard > Customers > Votre user ID
   - Entitlement `premium` doit être actif
   - Expiration dans 7 jours

---

### Étape 7 : Tester en Sandbox (Android) (20 min)

**Prérequis** : Étapes 1-4 terminées

1. Build l'app :
   ```bash
   flutter build appbundle --release --dart-define-from-file=.env.production
   ```

2. Upload sur Internal Testing :
   - Google Play Console > Testing > Internal testing
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Ajouter votre email dans les testeurs

3. Installer l'app via le lien de test

4. Tests :
   - Ouvrir le paywall
   - Sélectionner un plan
   - Confirmer l'achat
   - ✅ Premium doit être activé

---

### Étape 8 : Intégrer l'initialisation dans main.dart (10 min)

Actuellement, l'initialisation doit être ajoutée manuellement.

**Fichier à modifier** : `lib/main.dart`

```dart
import 'package:ryse_app/services/unified_subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase (déjà présent)
  await Supabase.initialize(...);

  // 🆕 AJOUTER : Initialiser le service d'abonnement
  final subscriptionService = UnifiedSubscriptionService();
  await subscriptionService.initialize();

  runApp(MyApp());
}
```

**Dans AuthService** (lors du login) :

```dart
Future<void> login(String email, String password) async {
  final response = await supabase.auth.signInWithPassword(...);

  if (response.user != null) {
    // 🆕 AJOUTER : Connecter à RevenueCat
    final subscriptionService = UnifiedSubscriptionService();
    await subscriptionService.login(response.user!.id);
  }
}

Future<void> logout() async {
  // 🆕 AJOUTER : Déconnecter de RevenueCat
  final subscriptionService = UnifiedSubscriptionService();
  await subscriptionService.logout();

  await supabase.auth.signOut();
}
```

---

### Étape 9 : Ajouter les checks d'abonnement dans les features IA (30 min)

Pour chaque feature IA, ajouter une vérification Premium :

**Exemple 1 : Scanner IA** (`ai_scanner_screen.dart`)

```dart
import 'package:ryse_app/services/unified_subscription_service.dart';
import 'package:ryse_app/screens/paywall_screen.dart';

Future<void> _startScanning() async {
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
        customTitle: 'Scanner IA Premium',
        customMessage: 'Scannez et analysez vos repas avec l\'IA',
      ),
    );

    if (result != true) return; // Utilisateur a refusé
  }

  // Continuer avec le scan IA
  // ...
}
```

**Exemple 2 : Chat IA Nutrition**

```dart
Future<void> _openAiChat() async {
  final subscription = UnifiedSubscriptionService();

  if (!subscription.isPremium) {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallScreen(
        context: PaywallContext.aiChat,
      ),
    );
    return;
  }

  // Ouvrir le chat IA
  // ...
}
```

**Features à protéger** :
- [ ] Scanner IA nourriture (`ai_scanner_screen.dart`)
- [ ] Analyse nutrition coach (`ai_analysis_screen.dart`)
- [ ] Générateur séances sport (à identifier)
- [ ] Chat IA nutrition (à identifier)
- [ ] Chat IA sport (à identifier)
- [ ] Générateur recettes IA (à identifier)

---

### Étape 10 : Build et déploiement Production (1h)

Une fois tous les tests validés :

#### iOS
```bash
# Build
flutter build ios --release --dart-define-from-file=.env.production

# Dans Xcode
# 1. Product > Archive
# 2. Distribute App > App Store Connect
# 3. Upload
# 4. Dans App Store Connect > TestFlight
# 5. Puis soumettre à Review
```

#### Android
```bash
# Build
flutter build appbundle --release --dart-define-from-file=.env.production

# Dans Google Play Console
# 1. Production > Create new release
# 2. Upload build/app/outputs/bundle/release/app-release.aab
# 3. Review > Start rollout to Production
```

---

## 📚 Ressources

### Documentation
- [REVENUECAT_SETUP.md](REVENUECAT_SETUP.md) - Guide complet
- [STORE_CONFIGURATION_QUICK_GUIDE.md](STORE_CONFIGURATION_QUICK_GUIDE.md) - Guide rapide

### Dashboards
- RevenueCat : https://app.revenuecat.com
- App Store Connect : https://appstoreconnect.apple.com
- Google Play Console : https://play.google.com/console

### Support
- RevenueCat Docs : https://docs.revenuecat.com/
- RevenueCat Flutter SDK : https://sdk.revenuecat.com/flutter/

---

## ⚠️ Important

### Mode Test vs Production

**Mode Test** (`TEST_MODE=true`) :
- Bouton "🧪 SIMULER PAIEMENT (TEST)"
- Pas d'appel à RevenueCat
- Premium activé instantanément
- Pour développement local uniquement

**Mode Production** (`TEST_MODE=false`) :
- Bouton "Continuer" normal
- Appel à RevenueCat SDK
- Vrais achats (sandbox ou prod)
- Pour builds TestFlight / Play Store

### Sécurité

**NE JAMAIS** commit :
- `.env.local`
- `.env.production`
- Les API Keys RevenueCat

Ces fichiers sont déjà dans `.gitignore`.

### Coûts API

Surveillez vos coûts d'API IA :
- Gemini API
- Google Vision API

Calculez si vos prix sont rentables :
- Si 1 user premium coûte 5€/mois en API
- Monthly à 9,99€ = 4,99€ de marge
- Yearly à 69,99€ = 6,66€/mois = 1,66€ de marge/mois

---

## 🎯 Checklist finale avant production

- [ ] Compte RevenueCat créé
- [ ] API Keys RevenueCat copiées dans `.env.production`
- [ ] App Store Connect : 3 subscriptions créées
- [ ] Google Play Console : 3 subscriptions créées
- [ ] Service Account Android uploadé dans RevenueCat
- [ ] Shared Secret iOS ajouté dans RevenueCat
- [ ] Test sandbox iOS réussi
- [ ] Test sandbox Android réussi
- [ ] Initialisation ajoutée dans `main.dart`
- [ ] Login/Logout connectés à RevenueCat
- [ ] Features IA protégées par check Premium
- [ ] Build production testé
- [ ] Documentation lue et comprise

---

**Bon courage pour l'implémentation ! 🚀**

Si vous avez des questions ou rencontrez des problèmes, référez-vous à [REVENUECAT_SETUP.md](REVENUECAT_SETUP.md) section Troubleshooting.
