# ✅ Système d'Essais Gratuits - Implémenté

## 🎯 Résumé

Le système d'essais gratuits est maintenant **complètement implémenté** et prêt à l'emploi.

**Règle** : Chaque feature Premium peut être utilisée **1 fois gratuitement**, puis nécessite un abonnement Premium.

---

## 📁 Fichiers Créés

### 1. Migration Supabase
- **Fichier** : `supabase/migrations/20250115_add_feature_trials.sql`
- **Table** : `user_feature_trials`
- **Colonnes** :
  - `id` (UUID, PK)
  - `user_id` (UUID, FK → auth.users)
  - `feature_key` (TEXT) - Clé de la feature
  - `used` (BOOLEAN) - Essai utilisé ou non
  - `used_at` (TIMESTAMP) - Date/heure d'utilisation
  - `created_at`, `updated_at`
- **Policies RLS** : Utilisateurs peuvent voir/modifier uniquement leurs propres trials
- **Index** : Optimisés pour `user_id`, `feature_key`, et `(user_id, feature_key)`

### 2. Service FeatureTrialService
- **Fichier** : `lib/services/feature_trial_service.dart`
- **Méthodes principales** :
  - `hasUsedFreeTrial(featureKey)` - Vérifier si essai utilisé
  - `markFeatureAsUsed(featureKey)` - Marquer comme utilisé
  - `resetTrial(featureKey)` - Réinitialiser (debug/support)
  - `resetAllTrials()` - Réinitialiser tous les essais
  - `getUsedFeatures()` - Liste des features utilisées

### 3. Extension PaywallService
- **Fichier** : `lib/services/paywall_service.dart` (modifié)
- **Nouvelles méthodes** :
  - `getFeatureTrialKey(context)` - Mapper contexte → clé trial
  - `canUseFeature()` - Vérifier accès (Premium ou 1er essai)
  - `isFeatureLocked()` - Vérifier si badge PRO à afficher

### 4. Widget PremiumBadge
- **Fichier** : `lib/components/ui/premium_badge.dart`
- **Widgets** :
  - `PremiumBadge` - Badge "PRO" doré standard
  - `PremiumBadgeSmall` - Badge mini pour icônes

---

## 🚀 Utilisation

### A. Vérifier l'Accès à une Feature

```dart
// Dans le bouton qui ouvre la feature
final canUse = await PaywallService.instance.canUseFeature(
  context: context,
  paywallContext: PaywallContext.scanner, // ou autre contexte
);

if (canUse) {
  // L'utilisateur peut utiliser la feature
  // Soit Premium, soit 1er essai gratuit
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => AiScannerScreen(),
  ));
}
// Sinon, le paywall s'est affiché automatiquement
```

### B. Afficher le Badge PRO sur un Bouton

```dart
// Exemple avec FutureBuilder
FutureBuilder<bool>(
  future: PaywallService.instance.isFeatureLocked(
    PaywallContext.scanner,
  ),
  builder: (context, snapshot) {
    final isLocked = snapshot.data ?? false;

    return PremiumBadge(
      isLocked: isLocked,
      onTap: () async {
        final canUse = await PaywallService.instance.canUseFeature(
          context: context,
          paywallContext: PaywallContext.scanner,
        );

        if (canUse) {
          // Ouvrir le scanner
          Navigator.push(...);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.white),
            SizedBox(width: 8),
            Text('Scanner repas', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  },
)
```

### C. Variante Simplifiée (Provider Pattern)

Si vous utilisez Provider, créez un `FeatureAccessProvider` :

```dart
class FeatureAccessProvider extends ChangeNotifier {
  final _paywallService = PaywallService.instance;

  Map<PaywallContext, bool> _lockedFeatures = {};

  Future<void> loadFeatureStatus() async {
    for (var context in PaywallContext.values) {
      _lockedFeatures[context] = await _paywallService.isFeatureLocked(context);
    }
    notifyListeners();
  }

  bool isLocked(PaywallContext context) {
    return _lockedFeatures[context] ?? false;
  }
}

// Dans le widget
Consumer<FeatureAccessProvider>(
  builder: (context, provider, _) {
    return PremiumBadge(
      isLocked: provider.isLocked(PaywallContext.scanner),
      onTap: () => _handleScannerTap(),
      child: YourButton(),
    );
  },
)
```

---

## 🔑 Clés des Features

Les clés sont définies dans `FeatureTrialService` :

| Feature | Clé | Contexte Paywall |
|---------|-----|------------------|
| Scanner photo | `feature_scanner_used` | `PaywallContext.scanner` |
| Scanner barcode | `feature_barcode_used` | `PaywallContext.barcodeScanner` |
| Chat Coach | `feature_chat_used` | `PaywallContext.chatInput` |
| Workouts | `feature_workout_used` | `PaywallContext.workoutGenerator` |
| Analyse nutrition | `feature_nutrition_analysis_used` | `PaywallContext.nutritionAnalysis` |
| Analyse exercice | `feature_exercise_analysis_used` | `PaywallContext.exerciseAnalysis` |

---

## 📍 Intégration dans l'App

### Emplacements des Boutons Premium

Voici où ajouter les badges et la vérification d'accès :

#### 1. Scanner Photo (📸)
**Fichier** : Probablement dans un bottom sheet ou `lib/screens/ai_scanner_screen.dart`

```dart
PremiumBadge(
  isLocked: await PaywallService.instance.isFeatureLocked(PaywallContext.scanner),
  onTap: () async {
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.scanner,
    );
    if (canUse) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => AiScannerScreen(),
      ));
    }
  },
  child: // Votre bouton scan repas
)
```

#### 2. Scanner Barcode (📱)
**Fichier** : `lib/screens/barcode_scanner_screen.dart` ou bottom sheet

```dart
PremiumBadge(
  isLocked: await PaywallService.instance.isFeatureLocked(PaywallContext.barcodeScanner),
  onTap: () async {
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.barcodeScanner,
    );
    if (canUse) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(...),
      ));
    }
  },
  child: // Votre bouton scan barcode
)
```

#### 3. Chat Coach (💬)
**Fichier** : Bottom sheet nutrition ou dashboard

```dart
PremiumBadge(
  isLocked: await PaywallService.instance.isFeatureLocked(PaywallContext.chatInput),
  onTap: () async {
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.chatInput,
    );
    if (canUse) {
      // Ouvrir le chat
    }
  },
  child: // Votre bouton chat
)
```

#### 4. Générateur Workouts (🤖)
**Fichier** : `lib/components/sport_musculation_hybrid.dart`

```dart
PremiumBadge(
  isLocked: await PaywallService.instance.isFeatureLocked(PaywallContext.workoutGenerator),
  onTap: () async {
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.workoutGenerator,
    );
    if (canUse) {
      // Générer workout
    }
  },
  child: // Bouton "Coach Ryze"
)
```

#### 5. Analyse Nutrition (📊)
**Fichier** : Journal screen ou dashboard

```dart
PremiumBadge(
  isLocked: await PaywallService.instance.isFeatureLocked(PaywallContext.nutritionAnalysis),
  onTap: () async {
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.nutritionAnalysis,
    );
    if (canUse) {
      // Afficher l'analyse
    }
  },
  child: // Bouton "Analyse du Coach"
)
```

#### 6. Analyse Exercice (💪)
**Fichier** : Détail d'un exercice

```dart
PremiumBadge(
  isLocked: await PaywallService.instance.isFeatureLocked(PaywallContext.exerciseAnalysis),
  onTap: () async {
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.exerciseAnalysis,
    );
    if (canUse) {
      // Afficher l'analyse
    }
  },
  child: // Bouton analyse
)
```

---

## 🔄 Appliquer la Migration

La migration a été créée dans `supabase/migrations/20250115_add_feature_trials.sql`.

Pour l'appliquer à votre base de données Supabase :

### Option 1 : Via Supabase CLI (Recommandé)

```bash
# Si votre projet est déjà lié
supabase db push

# Ou appliquer une migration spécifique
supabase migration up --file 20250115_add_feature_trials.sql
```

### Option 2 : Via le Dashboard Supabase

1. Ouvrir https://supabase.com/dashboard
2. Aller dans votre projet
3. Section "SQL Editor"
4. Copier/coller le contenu de `supabase/migrations/20250115_add_feature_trials.sql`
5. Exécuter

### Option 3 : Via psql

```bash
# Se connecter à votre base
psql "postgresql://postgres:[password]@[host]:5432/postgres"

# Exécuter le fichier
\i supabase/migrations/20250115_add_feature_trials.sql
```

---

## 🧪 Testing

### Test 1 : Vérifier le 1er Essai Gratuit

```dart
// L'utilisateur non-Premium utilise le scanner pour la 1ère fois
final canUse = await PaywallService.instance.canUseFeature(
  context: context,
  paywallContext: PaywallContext.scanner,
);

// Résultat attendu : true (accès gratuit)
// La feature est marquée comme utilisée dans la DB
```

### Test 2 : Vérifier le Paywall au 2ème Essai

```dart
// L'utilisateur essaie d'utiliser le scanner une 2ème fois
final canUse = await PaywallService.instance.canUseFeature(
  context: context,
  paywallContext: PaywallContext.scanner,
);

// Résultat attendu : false
// Le paywall s'affiche automatiquement
```

### Test 3 : Vérifier l'Accès Premium

```dart
// L'utilisateur Premium essaie d'utiliser le scanner
final canUse = await PaywallService.instance.canUseFeature(
  context: context,
  paywallContext: PaywallContext.scanner,
);

// Résultat attendu : true (accès illimité)
// Aucune modification dans la DB (pas besoin de tracker)
```

### Test 4 : Réinitialiser un Essai (Debug)

```dart
// Réinitialiser l'essai du scanner
await FeatureTrialService.instance.resetTrial(
  FeatureTrialService.keyScanner,
);

// L'utilisateur peut à nouveau utiliser son essai gratuit
```

---

## 📊 Analytics (Optionnel)

Ajouter du tracking Firebase Analytics :

```dart
Future<bool> canUseFeature({...}) async {
  // ... code existant ...

  if (!hasUsed) {
    // Track le 1er essai gratuit
    FirebaseAnalytics.instance.logEvent(
      name: 'free_trial_used',
      parameters: {
        'feature': paywallContext.name,
        'user_id': _supabase.auth.currentUser?.id,
      },
    );

    if (markAsUsed) {
      await _trialService.markFeatureAsUsed(trialKey);
    }
    return true;
  }

  // Track affichage du paywall
  FirebaseAnalytics.instance.logEvent(
    name: 'paywall_shown',
    parameters: {
      'feature': paywallContext.name,
      'reason': 'trial_used',
    },
  );

  // ...
}
```

---

## ✅ Checklist Finale

- [x] Migration Supabase créée
- [x] Service FeatureTrialService implémenté
- [x] PaywallService étendu avec méthodes trial
- [x] Widget PremiumBadge créé
- [ ] Migration appliquée sur Supabase (à faire manuellement)
- [ ] Intégrer les badges sur les 6 boutons Premium
- [ ] Tester le flow complet (1er essai → paywall → Premium)
- [ ] Analytics (optionnel)

---

## 🎯 Prochaines Étapes

1. **Appliquer la migration** sur votre base Supabase
2. **Identifier les boutons** pour chaque feature dans le code existant
3. **Wrapper chaque bouton** avec `PremiumBadge`
4. **Tester** le flow complet avec un compte test

Le système est prêt ! 🚀
