# 🧪 Guide de Test - Système de Trials Premium

## 🎯 Objectif
Tester le système de trials en mode **non-Premium** pour vérifier:
1. Premier essai gratuit fonctionne
2. Deuxième tentative affiche le paywall
3. Utilisateur Premium a accès illimité

---

## 🔧 Option 1: Forcer Mode Non-Premium (Recommandé)

### Étape 1: Modifier SubscriptionService Temporairement

**Fichier**: `lib/services/subscription_service.dart`

**Modifier la ligne 28**:

```dart
// AVANT (ligne 28)
bool get isPremium => _currentSubscription?.isPremium ?? false;

// APRÈS (pour tester)
bool get isPremium => false; // ← Force NON-Premium pour test
```

### Étape 2: Lancer l'App

```bash
flutter run --dart-define-from-file=.env.local
```

### Étape 3: Tester le Flow

#### Test 1: Premier Essai Gratuit ✅
1. Aller dans **Nutrition** → Cliquer sur **"+"** d'un repas
2. Choisir **"Scanner avec l'IA"** (icône caméra 📸)
3. **Attendu**: Le scanner s'ouvre directement
4. **Logs console**:
   ```
   🎁 PaywallService: First free trial for scanner
   ✅ FeatureTrialService: Marked feature_scanner_used as used
   ```

#### Test 2: Deuxième Tentative → Paywall 🚫
1. Retourner au dashboard nutrition
2. Cliquer à nouveau sur **"Scanner avec l'IA"**
3. **Attendu**: Le paywall s'affiche avec:
   - Titre: "📸 Arrête de Deviner tes Calories"
   - Bulle du Coach: "Prêt à débloquer tes résultats ?"
   - 6 bénéfices spécifiques au scanner
   - 3 offres de prix (Hebdo/Mensuel/Annuel)
   - Badge "7 JOURS GRATUITS"
4. **Logs console**:
   ```
   🚫 PaywallService: Trial already used for scanner, showing paywall
   ```

#### Test 3: Toutes les Features
Répéter Test 1 et 2 pour:
- ✅ Scanner Barcode (🔍)
- ✅ Chat Coach (💬)
- ✅ Générateur Workouts (🤖)
- ✅ Bilan Nutrition (📊)
- ✅ Analyse Exercice (💪)

Chaque feature doit avoir son **propre trial indépendant**.

### Étape 4: Vérifier la Base de Données

**Via Supabase Dashboard**:
1. Ouvrir: https://supabase.com/dashboard/project/mfskwlzgxjhhknlwpblq/editor
2. Aller dans la table **`user_feature_trials`**
3. Vérifier les données:

| user_id | feature_key | used | used_at |
|---------|-------------|------|---------|
| abc123 | feature_scanner_used | true | 2025-01-15 14:30 |
| abc123 | feature_barcode_used | true | 2025-01-15 14:35 |

### Étape 5: Réinitialiser les Trials (Optionnel)

**Pour retester le 1er essai gratuit**:

```dart
// Ajouter temporairement dans un bouton de debug
await FeatureTrialService.instance.resetTrial(
  FeatureTrialService.keyScanner,
);

// Ou réinitialiser tous les trials
await FeatureTrialService.instance.resetAllTrials();
```

### ⚠️ IMPORTANT: Remettre en Production

**Après les tests, ANNULER les changements**:

```dart
// Remettre la ligne 28 à l'original
bool get isPremium => _currentSubscription?.isPremium ?? false;
```

**Ne JAMAIS commit avec `isPremium => false`!**

---

## 🔧 Option 2: Tester avec Compte Réel Non-Premium

### Étape 1: Créer un Compte Test

1. Créer un nouveau compte dans l'app
2. Ne PAS souscrire à Premium
3. Ce compte sera automatiquement en mode **Free**

### Étape 2: Suivre le Même Flow de Test

Suivre les Tests 1, 2 et 3 de l'Option 1.

### Avantage
- Plus réaliste (vraie expérience utilisateur)
- Pas besoin de modifier le code

### Inconvénient
- Plus long (création de compte)
- Nécessite un device/simulateur propre

---

## 🔧 Option 3: Tester Mode Premium

### Pour tester l'accès illimité Premium:

**Modifier temporairement la ligne 28**:

```dart
bool get isPremium => true; // ← Force Premium pour test
```

### Flow de Test Premium ✅

1. Cliquer sur n'importe quelle feature (scanner, barcode, etc.)
2. **Attendu**: Accès direct sans paywall, aucune limite
3. **Logs console**:
   ```
   ✅ PaywallService: User is Premium, granting access to scanner
   ```
4. **Base de données**: Aucune nouvelle ligne dans `user_feature_trials`

---

## 🧪 Scénarios de Test Complets

### Scénario 1: Utilisateur Non-Premium Essaie Toutes les Features

| Action | Feature | Résultat Attendu |
|--------|---------|------------------|
| 1ère fois | Scanner Photo | ✅ Accès direct |
| 2ème fois | Scanner Photo | 🚫 Paywall |
| 1ère fois | Scanner Barcode | ✅ Accès direct |
| 2ème fois | Scanner Barcode | 🚫 Paywall |
| 1ère fois | Chat Coach | ✅ Accès direct |
| 2ème fois | Chat Coach | 🚫 Paywall |
| 1ère fois | Générateur Workouts | ✅ Accès direct |
| 2ème fois | Générateur Workouts | 🚫 Paywall |
| 1ère fois | Bilan Nutrition | ✅ Accès direct |
| 2ème fois | Bilan Nutrition | 🚫 Paywall |
| 1ère fois | Analyse Exercice | ✅ Accès direct |
| 2ème fois | Analyse Exercice | 🚫 Paywall |

**Base de données finale**: 6 lignes dans `user_feature_trials`, toutes avec `used=true`

### Scénario 2: Utilisateur Premium

| Action | Feature | Résultat Attendu |
|--------|---------|------------------|
| N fois | Toutes features | ✅ Accès illimité |

**Base de données finale**: 0 ligne (pas de tracking pour Premium)

### Scénario 3: Utilisateur Passe de Free à Premium

1. **Free**: Utilise Scanner Photo (1er essai gratuit) → ✅
2. **Free**: Utilise Scanner Photo (2ème fois) → 🚫 Paywall
3. **Souscrit Premium**
4. **Premium**: Utilise Scanner Photo → ✅ Accès direct
5. **Premium**: Utilise toutes features → ✅ Accès illimité

**Base de données**: 1 ligne `feature_scanner_used` (du 1er essai en Free), mais n'affecte plus l'accès

---

## 📊 Vérification des Logs Console

### Logs à Surveiller

#### FeatureTrialService
```
✅ FeatureTrialService: hasUsedFreeTrial(feature_scanner_used) = false
✅ FeatureTrialService: Marked feature_scanner_used as used
✅ FeatureTrialService: hasUsedFreeTrial(feature_scanner_used) = true
```

#### PaywallService
```
🎁 PaywallService: First free trial for scanner
✅ PaywallService: Marked scanner trial as used
🚫 PaywallService: Trial already used for scanner, showing paywall
✅ PaywallService: User is Premium, granting access to scanner
```

### Erreurs à Surveiller

```
❌ FeatureTrialService: Error checking trial for feature_scanner_used: [error]
❌ FeatureTrialService: Error marking feature_scanner_used as used: [error]
⚠️ PaywallService: User not logged in
```

---

## 🗑️ Nettoyage Après Tests

### Réinitialiser les Trials d'un Utilisateur

**Via SQL dans Supabase**:

```sql
-- Réinitialiser tous les trials d'un user
DELETE FROM user_feature_trials
WHERE user_id = 'USER_ID_ICI';

-- Réinitialiser un trial spécifique
DELETE FROM user_feature_trials
WHERE user_id = 'USER_ID_ICI'
  AND feature_key = 'feature_scanner_used';
```

**Via Code Flutter** (ajouter bouton de debug):

```dart
// Réinitialiser tous les trials
ElevatedButton(
  onPressed: () async {
    await FeatureTrialService.instance.resetAllTrials();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tous les trials ont été réinitialisés')),
    );
  },
  child: Text('Reset All Trials (DEBUG)'),
)
```

---

## ✅ Checklist de Test

### Tests Fonctionnels
- [ ] Scanner Photo: 1er essai gratuit fonctionne
- [ ] Scanner Photo: 2ème essai affiche paywall
- [ ] Scanner Barcode: 1er essai gratuit fonctionne
- [ ] Scanner Barcode: 2ème essai affiche paywall
- [ ] Chat Coach: 1er essai gratuit fonctionne
- [ ] Chat Coach: 2ème essai affiche paywall
- [ ] Générateur Workouts: 1er essai gratuit fonctionne
- [ ] Générateur Workouts: 2ème essai affiche paywall
- [ ] Bilan Nutrition: 1er essai gratuit fonctionne
- [ ] Bilan Nutrition: 2ème essai affiche paywall
- [ ] Analyse Exercice: 1er essai gratuit fonctionne
- [ ] Analyse Exercice: 2ème essai affiche paywall

### Tests Premium
- [ ] Utilisateur Premium: Accès illimité à toutes features
- [ ] Utilisateur Premium: Aucune ligne dans user_feature_trials

### Tests UI
- [ ] Paywall s'affiche avec le bon titre contextuel
- [ ] Paywall affiche la bulle du Coach
- [ ] Paywall affiche 6 bénéfices spécifiques
- [ ] Paywall affiche 3 offres de prix
- [ ] Badge "7 JOURS GRATUITS" visible
- [ ] Bouton "Commencer l'essai gratuit" fonctionne

### Tests Base de Données
- [ ] Ligne créée dans user_feature_trials après 1er essai
- [ ] Colonne `used` = true après 1er essai
- [ ] Colonne `used_at` contient timestamp correct
- [ ] Constraint UNIQUE empêche doublons
- [ ] RLS policies fonctionnent (user voit uniquement ses trials)

### Tests Logs
- [ ] Logs "First free trial" affichés correctement
- [ ] Logs "Trial already used" affichés correctement
- [ ] Logs "User is Premium" affichés pour Premium
- [ ] Aucune erreur dans les logs

---

## 🚨 Erreurs Communes et Solutions

### Erreur 1: "User not logged in"
**Cause**: Utilisateur non authentifié
**Solution**: Se connecter avec un compte avant de tester

### Erreur 2: Paywall s'affiche même pour Premium
**Cause**: `isPremium` retourne `false` alors que l'user est Premium
**Solution**: Vérifier RevenueCat et SubscriptionService

### Erreur 3: Trial déjà utilisé alors que c'est la 1ère fois
**Cause**: Ligne déjà existante dans `user_feature_trials`
**Solution**: Réinitialiser les trials via `resetAllTrials()`

### Erreur 4: Table `user_feature_trials` n'existe pas
**Cause**: Migration Supabase non appliquée
**Solution**: Appliquer la migration `20250115_add_feature_trials.sql`

---

## 📝 Notes Importantes

1. **Ne JAMAIS commit** avec `isPremium => false` ou `isPremium => true` en dur
2. **Toujours tester** en mode non-Premium ET Premium
3. **Vérifier la DB** après chaque test pour confirmer le tracking
4. **Réinitialiser les trials** entre les tests si nécessaire
5. **Surveiller les logs** pour détecter les erreurs rapidement

---

## 🎯 Prochaines Étapes Après Tests

1. **Si tout fonctionne**: Déployer en production
2. **Si erreurs**: Corriger et retester
3. **Analytics**: Ajouter Firebase Analytics pour tracker conversions
4. **A/B Testing**: Tester différents messages de paywall
5. **Optimisation**: Ajuster les textes selon les taux de conversion

---

**Bon test! 🚀**
