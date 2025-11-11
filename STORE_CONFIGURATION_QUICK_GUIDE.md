# Quick Guide - Configuration des Stores (iOS & Android)

Guide rapide pour configurer les abonnements dans App Store Connect et Google Play Console.

---

## 🍎 App Store Connect - Configuration Rapide

### Étape 1 : Créer le Subscription Group

1. App Store Connect > My Apps > Votre App
2. Features > **Subscriptions** > **+** (Create Subscription Group)
3. **Reference Name** : `Ryse Premium`
4. Save

### Étape 2 : Créer les 3 Subscriptions

#### Subscription 1 - Weekly
```
Reference Name: Ryse Premium Weekly
Product ID: ryse_premium_weekly
Subscription Group: Ryse Premium
Duration: 1 Week
```

**Pricing (Tier 1)** :
- France : 2,99€
- US : $2.99

#### Subscription 2 - Monthly
```
Reference Name: Ryse Premium Monthly
Product ID: ryse_premium_monthly
Subscription Group: Ryse Premium
Duration: 1 Month
```

**Pricing (Tier 5)** :
- France : 9,99€
- US : $9.99

#### Subscription 3 - Yearly
```
Reference Name: Ryse Premium Yearly
Product ID: ryse_premium_yearly
Subscription Group: Ryse Premium
Duration: 1 Year
```

**Pricing (Tier 35)** :
- France : 69,99€
- US : $69.99

### Étape 3 : Configurer le Free Trial (7 jours)

1. Aller dans **Subscription Group** "Ryse Premium"
2. Section **Introductory Offers**
3. Type : **Free Trial**
4. Duration : **7 days**
5. Cocher : Apply to all subscriptions in this group
6. Save

### Étape 4 : Métadonnées pour Review

Pour chaque subscription, remplir :

#### Subscription Display Name
```
Weekly: Premium hebdomadaire
Monthly: Premium mensuel
Yearly: Premium annuel
```

#### Description
```
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

### Étape 5 : Obtenir le Shared Secret

1. App Store Connect > My Apps > App Information
2. **App-Specific Shared Secret** > Generate
3. Copier la clé (format : `abcdef1234567890abcdef1234567890`)
4. Coller dans **RevenueCat Dashboard** > iOS App > Shared Secret

### Étape 6 : Créer un Sandbox Tester

1. App Store Connect > Users and Access
2. **Sandbox Testers** > **+**
3. Remplir :
   ```
   First Name: Test
   Last Name: User
   Email: testuser1@ryse.test (email fictif unique)
   Password: TestRyse2024!
   Country: France
   ```
4. Save

### Étape 7 : Status Review

Pour soumettre les subscriptions :

1. Chaque subscription doit avoir :
   - ✅ Pricing configuré
   - ✅ Display Name & Description
   - ✅ Screenshot (optionnel mais recommandé)

2. Submit for Review (avec la première version de l'app)

---

## 🤖 Google Play Console - Configuration Rapide

### Étape 1 : Accéder aux Subscriptions

1. Google Play Console > Votre App
2. Monetization > **Products** > **Subscriptions**
3. **Create subscription**

### Étape 2 : Créer les 3 Subscriptions

#### Subscription 1 - Weekly
```
Product ID: ryse_premium_weekly
Name: Ryse Premium Weekly
Description: Weekly subscription to all Ryse Premium features
```

**Subscription details** :
- Status : Active
- Billing period : 1 week
- Free trial : 7 days
- Grace period : 3 days (optionnel)

**Pricing** :
- France : 2,99€
- US : $2.99

#### Subscription 2 - Monthly
```
Product ID: ryse_premium_monthly
Name: Ryse Premium Monthly
Description: Monthly subscription to all Ryse Premium features
```

**Subscription details** :
- Billing period : 1 month
- Free trial : 7 days

**Pricing** :
- France : 9,99€
- US : $9.99

#### Subscription 3 - Yearly
```
Product ID: ryse_premium_yearly
Name: Ryse Premium Yearly
Description: Yearly subscription to all Ryse Premium features (Save 42%)
```

**Subscription details** :
- Billing period : 1 year
- Free trial : 7 days

**Pricing** :
- France : 69,99€
- US : $69.99

### Étape 3 : Créer un Base Plan pour chaque subscription

Pour chaque subscription :

1. **Base plans** > Create new base plan
2. **Billing period** : Correspond à la durée (weekly/monthly/yearly)
3. **Auto-renewing** : Yes
4. **Price** : Définir le prix
5. **Free trial** :
   - Eligibility : New customers
   - Duration : 7 days
6. Save

### Étape 4 : Service Account pour RevenueCat

#### Créer le Service Account

1. Google Cloud Console > IAM & Admin > **Service Accounts**
2. **Create Service Account**
   ```
   Name: RevenueCat
   ID: revenuecat
   Description: RevenueCat integration for subscriptions
   ```
3. **Grant Permissions** :
   - Role : **Project** > **Viewer**
4. Done

#### Créer la clé JSON

1. Cliquer sur le Service Account créé
2. **Keys** > **Add Key** > **Create new key**
3. Type : **JSON**
4. Download → fichier `revenuecat-xxxxx.json`

#### Lier à Google Play

1. Google Play Console > Setup > **API access**
2. **Service accounts** > Grant access
3. Sélectionner le service account "RevenueCat"
4. **App permissions** :
   - Select app : Votre app
   - **Financial data** : View only
   - **Orders and subscriptions** : View only
5. Apply

#### Upload dans RevenueCat

1. RevenueCat Dashboard > Apps > Android App
2. **Service Credentials** > Upload JSON file
3. Sélectionner `revenuecat-xxxxx.json`
4. Save

### Étape 5 : License Testing

Pour tester sans payer :

1. Google Play Console > Setup > **License Testing**
2. **License Testers** > Add tester emails
   ```
   your.email@gmail.com
   test.email@gmail.com
   ```
3. **Test response** : RESPOND_NORMALLY
4. Save

### Étape 6 : Internal Testing Track

Pour tester l'app complète :

1. Google Play Console > Testing > **Internal testing**
2. Create new release
3. Upload AAB (build production)
4. **Testers** > Add email list
5. Save > Review > Start rollout

---

## ⚙️ RevenueCat Dashboard - Configuration

### Étape 1 : Créer le Projet

1. [RevenueCat Dashboard](https://app.revenuecat.com)
2. **Create new project** : `Ryse`

### Étape 2 : Ajouter les Apps

#### iOS App
```
App Name: Ryse iOS
Bundle ID: com.yourcompany.ryseapp
Platform: iOS
```
→ Copier **Apple API Key** (format : `appl_xxxxxx`)

#### Android App
```
App Name: Ryse Android
Package Name: com.yourcompany.ryseapp
Platform: Android
```
→ Copier **Google API Key** (format : `goog_xxxxxx`)

### Étape 3 : Créer l'Entitlement

1. Dashboard > **Entitlements** > Create
   ```
   Identifier: premium
   Display Name: Premium Access
   ```

### Étape 4 : Créer les Products

1. Dashboard > **Products** > Create Product

#### Product 1 - Weekly
```
Identifier: ryse_premium_weekly
Type: Subscription
App Store Product ID: ryse_premium_weekly
Play Store Product ID: ryse_premium_weekly
```
→ Attach Entitlement : `premium`

#### Product 2 - Monthly
```
Identifier: ryse_premium_monthly
Type: Subscription
App Store Product ID: ryse_premium_monthly
Play Store Product ID: ryse_premium_monthly
```
→ Attach Entitlement : `premium`

#### Product 3 - Yearly
```
Identifier: ryse_premium_yearly
Type: Subscription
App Store Product ID: ryse_premium_yearly
Play Store Product ID: ryse_premium_yearly
```
→ Attach Entitlement : `premium`

### Étape 5 : Créer l'Offering

1. Dashboard > **Offerings** > Create Offering
   ```
   Identifier: default
   Description: Default Premium Offering
   ```

2. **Add Packages** :
   - Package Type : `$rc_weekly` → Product : `ryse_premium_weekly`
   - Package Type : `$rc_monthly` → Product : `ryse_premium_monthly`
   - Package Type : `$rc_annual` → Product : `ryse_premium_yearly`

3. **Make Current** (activer l'offering)

### Étape 6 : Lier aux Stores

#### iOS - App Store Connect
1. RevenueCat > iOS App > **App Store Connect**
2. **Shared Secret** : Coller le secret de App Store Connect
3. Save

#### Android - Google Play
1. RevenueCat > Android App > **Service Credentials**
2. Upload le fichier JSON du Service Account
3. Save

---

## 🧪 Tester que tout fonctionne

### iOS - Sandbox Testing

1. **iPhone Settings** > App Store > Sandbox Account
2. Sign out (si connecté)
3. Lancer l'app en mode production :
   ```bash
   flutter run --release --dart-define-from-file=.env.production
   ```
4. Dans l'app > Ouvrir le Paywall
5. Sélectionner un plan > Continuer
6. Apple vous demande de vous connecter : Utiliser le **Sandbox Tester**
7. Confirmer l'achat (gratuit avec trial)
8. ✅ Premium doit être activé

### Android - Internal Testing

1. Installer l'app via **Internal Testing track**
2. Utiliser un compte Google dans la **License Testing list**
3. Ouvrir l'app > Paywall
4. Sélectionner un plan > Continuer
5. Confirmer l'achat (gratuit avec trial)
6. ✅ Premium doit être activé

### Vérifier dans RevenueCat

1. RevenueCat Dashboard > **Customers**
2. Chercher votre user ID (Supabase user ID)
3. Vérifier :
   - ✅ Entitlement : `premium` (active)
   - ✅ Product : Le bon produit acheté
   - ✅ Expiration : Dans 7 jours (trial)

---

## 📋 Checklist Finale

### iOS
- [ ] 3 subscriptions créées dans App Store Connect
- [ ] Product IDs identiques à RevenueCat
- [ ] Subscription Group créé
- [ ] Free Trial 7 jours configuré
- [ ] Shared Secret copié dans RevenueCat
- [ ] Sandbox Tester créé
- [ ] Test en sandbox réussi

### Android
- [ ] 3 subscriptions créées dans Google Play Console
- [ ] Product IDs identiques à RevenueCat
- [ ] Base plans créés avec trial 7 jours
- [ ] Service Account créé et JSON uploadé dans RevenueCat
- [ ] License Testing configuré
- [ ] Internal Testing track créé
- [ ] Test avec compte test réussi

### RevenueCat
- [ ] Projet créé
- [ ] iOS App ajoutée (Apple API Key copié)
- [ ] Android App ajoutée (Google API Key copié)
- [ ] Entitlement `premium` créé
- [ ] 3 products créés et liés à `premium`
- [ ] Offering `default` créé et actif
- [ ] Shared Secret iOS configuré
- [ ] Service Account Android uploadé

### App
- [ ] `.env.production` contient les API Keys RevenueCat
- [ ] `TEST_MODE=false` en production
- [ ] Build avec `--dart-define-from-file=.env.production`
- [ ] Test en sandbox iOS OK
- [ ] Test en sandbox Android OK

---

## 🚀 Prêt pour production !

Une fois tous les tests validés :

1. **iOS** : Archive & Upload via Xcode
2. **Android** : Upload AAB via Google Play Console
3. **Submit for Review** sur les deux plateformes

**Note** : Les subscriptions doivent être approuvées par Apple/Google avant d'être actives pour les vrais utilisateurs.

---

## 📞 Support

- RevenueCat Support : support@revenuecat.com
- Apple Developer Support : https://developer.apple.com/contact/
- Google Play Support : https://support.google.com/googleplay/android-developer
