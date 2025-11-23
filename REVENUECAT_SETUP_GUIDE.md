# 🎯 Guide Configuration RevenueCat pour Ryse

Ce guide explique comment configurer RevenueCat pour tester les abonnements en environnement Sandbox.

## 📋 Prérequis

- ✅ Compte RevenueCat créé
- ✅ Projet Ryse créé dans RevenueCat
- ✅ Clé API RevenueCat : `test_deHjRXFqZzkmjDnmhLwgTEmxUzS`
- ✅ Produits créés dans App Store Connect

## 🏗️ Étape 1 : Vérifier les Produits dans App Store Connect

Va dans [App Store Connect](https://appstoreconnect.apple.com) :

1. **Mon App** → **Ryze**
2. **Fonctionnalités** → **Abonnements**
3. Vérifie que ces 3 produits existent :
   - `ryse_premium_weekly` (2,99€/semaine)
   - `ryse_premium_monthly` (9,99€/mois)
   - `ryse_premium_yearly` (69,99€/an)

4. Pour chaque produit, vérifie :
   - ✅ **Statut** : "Prêt à soumettre" ou "Approuvé"
   - ✅ **Essai gratuit** : 7 jours (optionnel mais recommandé)
   - ✅ **Prix** configurés pour tous les pays
   - ✅ **Renouvellement automatique** activé

**Important** : Les produits doivent être dans le groupe d'abonnements "Ryze Premium"

## 🎨 Étape 2 : Configurer RevenueCat Dashboard

Va sur [app.revenuecat.com](https://app.revenuecat.com) et connecte-toi.

### 2.1 Vérifier la Connexion App Store

1. Clique sur **⚙️ Settings** (en haut à droite)
2. **Project Settings** → **Apple App Store**
3. Vérifie que ton **Bundle ID** est bien configuré : `com.BadisG.ryzeApp`
4. Vérifie que **Shared Secret** est configuré (nécessaire pour les abonnements)

### 2.2 Créer l'Entitlement "premium"

1. Dans le menu de gauche, clique sur **Entitlements**
2. Clique sur **+ New** (en haut à droite)
3. Entre l'identifiant : **`premium`** (exactement comme ça, en minuscules)
4. Description : "Accès Premium Ryse avec toutes les fonctionnalités IA"
5. Clique **Save**

### 2.3 Ajouter les Produits

1. Dans le menu de gauche, clique sur **Products**
2. Pour chaque produit, clique **+ New** et configure :

**Produit 1 : Weekly**
   - **Store** : Apple App Store
   - **Product Identifier** : `ryse_premium_weekly`
   - **Type** : Subscription
   - Clique **Save**

**Produit 2 : Monthly**
   - **Store** : Apple App Store
   - **Product Identifier** : `ryse_premium_monthly`
   - **Type** : Subscription
   - Clique **Save**

**Produit 3 : Yearly**
   - **Store** : Apple App Store
   - **Product Identifier** : `ryse_premium_yearly`
   - **Type** : Subscription
   - Clique **Save**

### 2.4 Créer l'Offering "default"

1. Dans le menu de gauche, clique sur **Offerings**
2. Clique sur **+ New Offering**
3. **Identifier** : **`default`** (exactement comme ça, en minuscules)
4. **Description** : "Offre principale Ryse Premium"
5. Clique **Save**

### 2.5 Ajouter les Packages à l'Offering

Toujours dans la page de l'offering "default" :

1. Clique sur **+ Add Package**

**Package 1 : Weekly**
   - **Identifier** : `weekly` ou `$rc_weekly` (RevenueCat reconnaît automatiquement)
   - **Product** : Sélectionne `ryse_premium_weekly`
   - Clique **Save**

**Package 2 : Monthly**
   - **Identifier** : `monthly` ou `$rc_monthly`
   - **Product** : Sélectionne `ryse_premium_monthly`
   - Clique **Save**

**Package 3 : Yearly**
   - **Identifier** : `annual` ou `$rc_annual`
   - **Product** : Sélectionne `ryse_premium_yearly`
   - Clique **Save**

2. Définis l'offering "default" comme **Current** (toggle en haut à droite)

### 2.6 Lier l'Entitlement aux Produits

Pour chaque produit (weekly, monthly, yearly) :

1. Va dans **Products** (menu de gauche)
2. Clique sur le produit (ex: `ryse_premium_weekly`)
3. Dans la section **Entitlements**, clique **+ Add**
4. Sélectionne **`premium`**
5. Clique **Save**

Répète pour les 3 produits.

## 🔑 Étape 3 : Vérifier la Clé API

1. Va dans **⚙️ Settings** → **API Keys**
2. Vérifie que ta clé **Public Apple SDK** correspond à celle dans `.env.production` :
   ```
   test_deHjRXFqZzkmjDnmhLwgTEmxUzS
   ```
3. Si ce n'est pas la bonne clé, copie la clé correcte et mets à jour `.env.production`

**Note** : La clé `test_*` est une clé de développement, parfaite pour TestFlight.

## 📱 Étape 4 : Créer un Compte Sandbox Apple

1. Va dans [App Store Connect](https://appstoreconnect.apple.com)
2. **Utilisateurs et accès** → **Sandbox**
3. Clique **+ Testeur Sandbox**
4. Remplis les informations :
   - **Email** : `test-ryze@example.com` (n'importe quel email fictif)
   - **Mot de passe** : Crée un mot de passe fort
   - **Pays** : France
5. **Important** : Note bien le mot de passe !

## 🚀 Étape 5 : Tester sur TestFlight

### 5.1 Build et Upload

```bash
# Vérifier que TEST_MODE=false dans .env.production
cat .env.production | grep TEST_MODE

# Build pour TestFlight avec RevenueCat activé
./build_testflight.sh

# Upload vers App Store Connect
# (Xcode Organizer ouvrira automatiquement après le build)
```

### 5.2 Installer sur iPhone

1. Ouvre **TestFlight** sur ton iPhone
2. Installe le nouveau build (Build 13)
3. **Important** : Attends que le build soit "Prêt pour test"

### 5.3 Configuration iPhone pour Sandbox

1. **Déconnecte-toi de l'App Store** :
   - Réglages → App Store → Déconnexion
   - ⚠️ Ne pas se déconnecter d'iCloud, juste de l'App Store !

2. **Ne pas se connecter maintenant** avec le Sandbox
   - iOS demandera automatiquement lors de l'achat

### 5.4 Tester l'Abonnement

1. **Lance Ryze** depuis TestFlight
2. Connecte-toi avec ton compte Ryze (Supabase) → **C'est normal !**
3. Va dans **Settings** ou clique sur une feature Premium
4. Clique sur **"Passer à Premium"**
5. Tu devrais voir le **Paywall RevenueCat** avec les 3 options :
   - Weekly : 2,99€/semaine
   - Monthly : 9,99€/mois ⭐ (Le plus populaire)
   - Yearly : 69,99€/an (Économisez 42%)
6. Sélectionne une option et clique **"Continuer"**
7. iOS va afficher le popup natif Apple avec le prix
8. **C'est là qu'iOS demande de se connecter** → Entre ton compte **Sandbox** :
   - Email : `test-ryze@example.com`
   - Mot de passe : (celui créé dans App Store Connect)
9. iOS affiche **"Environnement Sandbox"** en haut → ✅ Bon signe !
10. Clique **"S'abonner"** → **L'achat est GRATUIT** (Sandbox)
11. Face ID / Touch ID pour confirmer
12. ✅ **Succès** : Tu es maintenant Premium !

## 🐛 Dépannage

### Erreur : "revenu cat configuration incomplete"

**Causes possibles** :
- ❌ L'offering "default" n'existe pas dans RevenueCat
- ❌ Les produits ne sont pas liés à l'offering
- ❌ L'entitlement "premium" n'est pas lié aux produits
- ❌ La clé API RevenueCat est incorrecte

**Solution** :
1. Vérifie l'Étape 2 de ce guide
2. Va dans RevenueCat Dashboard → Offerings → Vérifie que "default" existe et contient 3 packages
3. Active les logs dans l'app (ENABLE_DEBUG_LOGS=true) et regarde les logs Xcode

### Erreur : "Cannot connect to App Store"

**Cause** : L'iPhone n'arrive pas à contacter l'App Store Sandbox

**Solution** :
1. Vérifie que tu es bien déconnecté de l'App Store (pas d'iCloud)
2. Redémarre l'iPhone
3. Vérifie la connexion internet (WiFi recommandé pour Sandbox)

### Erreur : "This product is not available in your country"

**Cause** : Le produit n'est pas configuré pour la France dans App Store Connect

**Solution** :
1. Va dans App Store Connect → Produits → Vérifie les prix
2. Ajoute la France dans les territoires disponibles

### Les produits affichent "0,00€" au lieu de "2,99€"

**Cause** : Les prix ne sont pas encore synchronisés depuis App Store Connect

**Solution** :
1. Attends 10-15 minutes (synchronisation Apple)
2. Force-quit l'app et relance
3. Vérifie que les prix sont bien configurés dans App Store Connect

## ✅ Checklist Finale

Avant de tester, vérifie :

- [ ] Produits créés dans App Store Connect avec les bons IDs
- [ ] Entitlement "premium" créé dans RevenueCat
- [ ] Offering "default" créé et marqué comme "Current"
- [ ] Les 3 produits ajoutés comme packages dans "default"
- [ ] Les 3 produits liés à l'entitlement "premium"
- [ ] Clé API RevenueCat configurée dans .env.production
- [ ] TEST_MODE=false dans .env.production
- [ ] Compte Sandbox créé dans App Store Connect
- [ ] Déconnecté de l'App Store sur iPhone (pas d'iCloud)
- [ ] Build uploadé sur TestFlight

## 📊 Logs Utiles

Pour voir les logs RevenueCat pendant le test, connecte ton iPhone à Xcode :

1. Xcode → Window → Devices and Simulators
2. Sélectionne ton iPhone
3. Clique sur "Open Console"
4. Filtre : `RevenueCat` ou `Purchases`

Tu verras :
```
✅ RevenueCat initialisé en mode PRODUCTION
📦 3 packages disponibles
  - weekly: 2,99€/semaine
  - monthly: 9,99€/mois
  - annual: 69,99€/an
🛒 Achat de l'abonnement: monthly
✅ Abonnement activé avec succès!
```

## 🎉 Après le Test

Une fois que tout fonctionne :

1. **Pour révoquer l'abonnement Sandbox** :
   - Réglages iPhone → App Store → Sandbox Account → Gérer → Annuler

2. **Pour production réelle** :
   - Obtiens une clé API de production RevenueCat (commence par `appl_`)
   - Remplace dans `.env.production`
   - Les utilisateurs réels paieront avec leur compte App Store normal

## 📝 Notes Importantes

- **Sandbox ≠ Compte Réel** : N'utilise JAMAIS ton compte Apple réel pour tester
- **Achats Gratuits** : Tous les achats Sandbox sont gratuits
- **Délais** : Les achats Sandbox sont instantanés (pas de délai de validation)
- **Renouvellements** : En Sandbox, les abonnements se renouvellent très rapidement (1 mois = 5 minutes)
- **Expiration** : Les abonnements Sandbox expirent automatiquement après 6 renouvellements

## 🔗 Liens Utiles

- [RevenueCat Dashboard](https://app.revenuecat.com)
- [App Store Connect](https://appstoreconnect.apple.com)
- [RevenueCat Docs - iOS Setup](https://www.revenuecat.com/docs/getting-started/installation/ios)
- [Apple Sandbox Testing Guide](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
