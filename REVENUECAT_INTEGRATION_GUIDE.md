# 🎯 Guide d'Intégration RevenueCat - Ryse App

## ✅ Modifications Effectuées

### 1. **PaywallScreen connecté à RevenueCat** (`lib/screens/paywall_screen.dart`)

**Changements:**
- ✅ Import de `revenuecat_service.dart` et `purchases_flutter`
- ✅ Ajout de `_isPurchasing`, `_availablePackages`, `_isLoadingPackages`
- ✅ Méthode `_loadPackages()` pour charger les packages RevenueCat
- ✅ Méthode `_handlePurchase()` pour gérer l'achat
- ✅ Bouton CTA connecté à `_handlePurchase()` au lieu de `Navigator.pop()`
- ✅ Loading indicator pendant l'achat
- ✅ Gestion des erreurs avec SnackBar
- ✅ Retourne `true` au parent si l'achat réussit

## 📋 Configuration Requise

### **Étape 1: Clés API RevenueCat**

Dans ton fichier `.env.production`, assure-toi d'avoir:

```bash
# Public SDK Key (trouvé dans RevenueCat Dashboard → Settings → API Keys → Public app-specific API keys)
REVENUECAT_APPLE_API_KEY=appl_xxxxxxxxxxxxxxxxx
```

**Où trouver la clé:**
1. Va sur https://app.revenuecat.com
2. Sélectionne ton projet Ryse
3. Settings → API Keys
4. Copie la **Public app-specific API key** (commence par `appl_`)
5. ⚠️ **NE PAS utiliser la Secret API Key** (celle-ci est pour le backend uniquement)

---

### **Étape 2: Configuration App Store Connect**

#### A. Créer les Produits d'Abonnement

Dans App Store Connect (https://appstoreconnect.apple.com):

1. **Aller dans ton app** → Features → In-App Purchases
2. **Créer 3 produits Auto-Renewable Subscription:**

**Produit 1: Abonnement Hebdomadaire**
- Product ID: `com.ryse.premium.weekly` (ou selon `SubscriptionConfig`)
- Reference Name: `Ryse Premium Weekly`
- Subscription Group: `Ryse Premium` (créer si n'existe pas)
- Subscription Duration: `1 Week`
- Price: `2,99€`
- Free Trial: `7 Days`

**Produit 2: Abonnement Mensuel**
- Product ID: `com.ryse.premium.monthly`
- Reference Name: `Ryse Premium Monthly`
- Subscription Group: `Ryse Premium` (même groupe)
- Subscription Duration: `1 Month`
- Price: `9,99€`
- Free Trial: `7 Days`

**Produit 3: Abonnement Annuel**
- Product ID: `com.ryse.premium.annual`
- Reference Name: `Ryse Premium Annual`
- Subscription Group: `Ryse Premium` (même groupe)
- Subscription Duration: `1 Year`
- Price: `69,99€`
- Free Trial: `7 Days`

#### B. Configurer les Métadonnées

Pour chaque produit:
- **Subscription Display Name**: "Ryse Premium"
- **Description**: Décris les features (Coach Ryze, analyses IA, etc.)
- **Review Screenshot**: Ajoute un screenshot de l'app
- **Review Notes**: Explique les features Premium

---

### **Étape 3: Configuration RevenueCat Dashboard**

1. **Connecter App Store Connect à RevenueCat:**
   - RevenueCat Dashboard → Apps → ton app iOS
   - Configuration → App Store Connect
   - Upload le **Shared Secret** d'App Store Connect

2. **Créer les Entitlements:**
   - Entitlements → Create New Entitlement
   - Identifier: `premium` (correspond à `SubscriptionConfig.premiumEntitlementId`)

3. **Créer les Products:**
   - Products → Add Product
   - Product ID pour weekly: `com.ryse.premium.weekly`
   - Product ID pour monthly: `com.ryse.premium.monthly`
   - Product ID pour annual: `com.ryse.premium.annual`
   - Attacher l'entitlement `premium` aux trois produits

4. **Créer une Offering:**
   - Offerings → Create New Offering
   - Identifier: `default`
   - Add Packages:
     - Weekly package → produit `weekly`
     - Monthly package → produit `monthly`
     - Annual package → produit `annual`

---

### **Étape 4: Tester l'Intégration**

#### Test en Mode Sandbox (Développement)

1. **Créer un compte Sandbox dans App Store Connect:**
   - Users and Access → Sandbox Testers
   - Créer un nouveau testeur avec un email unique

2. **Sur ton iPhone de test:**
   - Settings → App Store → Sandbox Account
   - Se connecter avec le compte sandbox créé

3. **Lancer l'app en mode debug:**
   ```bash
   flutter run --dart-define-from-file=.env.production
   ```

4. **Déclencher le paywall:**
   - Clique sur un bouton avec badge "ESSAI GRATUIT" (Scanner, Chat, etc.)
   - Le paywall devrait s'afficher
   - Clique sur "DÉBLOQUER MON COACH"

5. **Vérifications:**
   - ✅ Les packages s'affichent avec les bons prix
   - ✅ Le bouton montre un loading pendant l'achat
   - ✅ L'achat se lance (popup iOS d'achat)
   - ✅ Après confirmation, le paywall se ferme
   - ✅ Les badges disparaissent (deviennent Premium)
   - ✅ Les features sont débloquées

#### Vérification dans RevenueCat Dashboard

Après un achat:
1. Va sur RevenueCat Dashboard → Customers
2. Cherche ton User ID Supabase
3. Vérifie que l'abonnement apparaît
4. Vérifie que l'entitlement `premium` est actif

---

### **Étape 5: Commandes de Debug**

Pour vérifier les logs RevenueCat dans la console:

```bash
# Lancer avec logs détaillés
flutter run --dart-define-from-file=.env.production --verbose
```

Logs à surveiller:
- `✅ RevenueCat initialisé avec succès`
- `📦 X packages disponibles`
- `🛒 Purchasing package: monthly`
- `✅ Purchase successful`
- `📱 Statut abonnement mis à jour: Premium`

---

## 🐛 Troubleshooting

### Erreur: "RevenueCat API key non configurée"
**Solution:** Vérifie que `REVENUECAT_APPLE_API_KEY` est bien dans `.env.production` et que tu lances avec `--dart-define-from-file=.env.production`

### Erreur: "Aucune offre disponible"
**Solutions:**
1. Vérifie que les produits sont créés dans App Store Connect
2. Vérifie qu'ils sont dans le status "Ready to Submit"
3. Vérifie que l'offering `default` existe dans RevenueCat Dashboard
4. Attends 1-2 heures pour la synchronisation App Store → RevenueCat

### Erreur: "Purchase failed - Invalid product"
**Solutions:**
1. Vérifie que les Product IDs dans App Store Connect matchent exactement ceux dans `SubscriptionConfig`
2. Vérifie que les produits sont ajoutés dans RevenueCat Dashboard
3. Force une synchronisation: RevenueCat Dashboard → Products → Sync

### Paywall s'affiche mais pas de packages
**Solutions:**
1. Check les logs: cherche `❌ Error loading packages`
2. Vérifie la connexion internet
3. Vérifie que RevenueCat SDK est bien initialisé dans `main.dart`

### L'achat réussit mais le statut Premium ne change pas
**Solutions:**
1. Vérifie que `SubscriptionService` écoute bien les changements via `RevenueCatService.subscriptionStatusStream`
2. Force un refresh: appelle `RevenueCatService().refreshCustomerInfo()`
3. Vérifie les logs pour voir si `_onCustomerInfoUpdate` est appelé

---

## 📱 Checklist Pré-Production

Avant de soumettre à l'App Store:

- [ ] Les 3 produits d'abonnement sont créés et "Ready to Submit"
  - [ ] Weekly (2,99€/semaine)
  - [ ] Monthly (9,99€/mois)
  - [ ] Annual (69,99€/an)
- [ ] RevenueCat est connecté à App Store Connect
- [ ] Les entitlements sont configurés dans RevenueCat
- [ ] L'offering "default" contient les 3 packages
- [ ] La clé API RevenueCat est dans `.env.production`
- [ ] Testé en mode Sandbox avec succès pour les 3 périodes
- [ ] Les prices s'affichent correctement (2,99€/semaine, 9,99€/mois, 69,99€/an)
- [ ] Le trial de 7 jours fonctionne
- [ ] Après achat, toutes les features se débloquent
- [ ] Les badges disparaissent pour les utilisateurs Premium
- [ ] La restauration d'achat fonctionne (si implémenté)

---

## 🎨 UI/UX du Paywall

Le paywall est maintenant fonctionnel avec:
- ✅ Animation d'entrée fluide avec Coach Ryze
- ✅ 3 options de pricing (Weekly / Monthly / Annual)
- ✅ Badge "7 JOURS GRATUITS" visible
- ✅ Bouton CTA doré avec gradient
- ✅ Loading indicator pendant l'achat
- ✅ Messages d'erreur clairs si échec
- ✅ Retour au flow normal après achat réussi
- ✅ Détection automatique du package selon la période sélectionnée

---

## 📞 Support

**Problèmes RevenueCat:**
- Documentation: https://www.revenuecat.com/docs
- Support: support@revenuecat.com

**Problèmes App Store:**
- App Store Connect: https://appstoreconnect.apple.com
- Apple Developer Support: https://developer.apple.com/contact/

---

**Dernière mise à jour:** 2025-01-18
**Version:** 1.0
**Auteur:** Claude Code Assistant
