# 🎯 Plan d'Implémentation - Système de Paywalls Contextuels

## ✅ État des Traductions

### Traductions Complètes (FR/EN)

Toutes les clés de traduction sont ajoutées dans `lib/services/translations.dart` :

#### 7 Paywalls Contextuels

| # | Contexte | Titre | Bulle | Bénéfices |
|---|----------|-------|-------|-----------|
| 1 | `scanner` | ✅ `paywall_title_scanner` | ✅ `paywall_bubble_scanner` | ✅ `paywall_benefit_scanner_1/2/3` |
| 2 | `barcodeScanner` | ✅ `paywall_title_barcode` | ✅ `paywall_bubble_barcode` | ✅ `paywall_benefit_barcode_1/2/3` |
| 3 | `chatInput` | ✅ `paywall_title_chat` | ✅ `paywall_bubble_chat` | ✅ `paywall_benefit_chat_1/2/3` |
| 4 | `workoutGenerator` | ✅ `paywall_title_workout` | ✅ `paywall_bubble_workout` | ✅ `paywall_benefit_workout_1/2/3` |
| 5 | `nutritionAnalysis` | ✅ `paywall_title_nutrition_analysis` | ✅ `paywall_bubble_nutrition_analysis` | ✅ `paywall_benefit_nutrition_analysis_1/2/3` |
| 6 | `exerciseAnalysis` | ✅ `paywall_title_exercise_analysis` | ✅ `paywall_bubble_exercise_analysis` | ✅ `paywall_benefit_exercise_analysis_1/2/3` |
| 7 | `genericUpgrade` | ✅ `paywall_title_generic` | ✅ `paywall_bubble_generic` | ✅ `paywall_benefit_generic_1/2/3` |

#### Éléments Communs

| Élément | Clé | Status |
|---------|-----|--------|
| Banner trial | `paywall_banner_trial` | ✅ |
| CTA Button | `paywall_cta_button` | ✅ |
| Prix mensuel | `paywall_then_price` | ✅ |
| Skip button | `paywall_skip` | ✅ |
| Badge Annuel | `paywall_badge_annual` | ✅ |
| Badge Mensuel | `paywall_badge_monthly` | ✅ |
| Badge Hebdo | `paywall_badge_weekly` | ✅ |
| Économies | `paywall_savings_annual` | ✅ |
| Période Annuel | `paywall_annual` | ✅ |
| Période Mensuel | `paywall_monthly` | ✅ |
| Période Hebdo | `paywall_weekly` | ✅ |

---

## 🔧 Implémentation Requise

### 1. Système de "1 Essai Gratuit"

**Règle** : Chaque feature Premium peut être utilisée **1 fois gratuitement**, puis paywall.

#### A. Ajouter un Service de Tracking

Créer `lib/services/feature_trial_service.dart` :

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour gérer les essais gratuits par feature
class FeatureTrialService {
  static final FeatureTrialService _instance = FeatureTrialService._internal();
  factory FeatureTrialService() => _instance;
  FeatureTrialService._internal();

  static FeatureTrialService get instance => _instance;

  final _supabase = Supabase.instance.client;

  // Clés pour les features premium
  static const String keyScanner = 'feature_scanner_used';
  static const String keyBarcode = 'feature_barcode_used';
  static const String keyChat = 'feature_chat_used';
  static const String keyWorkout = 'feature_workout_used';
  static const String keyNutritionAnalysis = 'feature_nutrition_analysis_used';
  static const String keyExerciseAnalysis = 'feature_exercise_analysis_used';

  /// Vérifier si l'utilisateur a déjà utilisé son essai gratuit
  Future<bool> hasUsedFreeTrial(String featureKey) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('user_feature_trials')
          .select('used')
          .eq('user_id', userId)
          .eq('feature_key', featureKey)
          .maybeSingle();

      return response?['used'] == true;
    } catch (e) {
      print('Error checking trial: $e');
      return false;
    }
  }

  /// Marquer la feature comme utilisée
  Future<void> markFeatureAsUsed(String featureKey) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('user_feature_trials').upsert({
        'user_id': userId,
        'feature_key': featureKey,
        'used': true,
        'used_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error marking feature as used: $e');
    }
  }

  /// Réinitialiser l'essai (pour testing ou support)
  Future<void> resetTrial(String featureKey) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('user_feature_trials')
          .delete()
          .eq('user_id', userId)
          .eq('feature_key', featureKey);
    } catch (e) {
      print('Error resetting trial: $e');
    }
  }
}
```

#### B. Créer la Table Supabase

```sql
-- Migration : user_feature_trials
CREATE TABLE IF NOT EXISTS user_feature_trials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  used_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, feature_key)
);

-- Index pour performance
CREATE INDEX idx_user_feature_trials_user_id ON user_feature_trials(user_id);
CREATE INDEX idx_user_feature_trials_feature_key ON user_feature_trials(feature_key);

-- RLS Policies
ALTER TABLE user_feature_trials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own trials"
  ON user_feature_trials FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own trials"
  ON user_feature_trials FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own trials"
  ON user_feature_trials FOR UPDATE
  USING (auth.uid() = user_id);
```

#### C. Modifier PaywallService pour Gérer les Trials

Ajouter dans `lib/services/paywall_service.dart` :

```dart
import 'feature_trial_service.dart';

class PaywallService {
  // ... code existant ...

  /// Mapper PaywallContext vers clé de feature trial
  static String getFeatureTrialKey(PaywallContext context) {
    switch (context) {
      case PaywallContext.scanner:
        return FeatureTrialService.keyScanner;
      case PaywallContext.barcodeScanner:
        return FeatureTrialService.keyBarcode;
      case PaywallContext.chatInput:
        return FeatureTrialService.keyChat;
      case PaywallContext.workoutGenerator:
        return FeatureTrialService.keyWorkout;
      case PaywallContext.nutritionAnalysis:
        return FeatureTrialService.keyNutritionAnalysis;
      case PaywallContext.exerciseAnalysis:
        return FeatureTrialService.keyExerciseAnalysis;
      case PaywallContext.genericUpgrade:
        return ''; // Pas de trial pour générique
    }
  }

  /// Vérifier si l'utilisateur peut utiliser la feature (premium ou 1er essai)
  Future<bool> canUseFeature({
    required BuildContext context,
    required PaywallContext paywallContext,
    bool markAsUsed = true, // Marquer comme utilisé si c'est le 1er essai
  }) async {
    // Si Premium, accès illimité
    if (_subscriptionService.isPremium) {
      return true;
    }

    // Vérifier le trial gratuit
    final trialKey = getFeatureTrialKey(paywallContext);
    if (trialKey.isEmpty) return false;

    final hasUsed = await FeatureTrialService.instance.hasUsedFreeTrial(trialKey);

    if (!hasUsed) {
      // 1er essai gratuit
      if (markAsUsed) {
        await FeatureTrialService.instance.markFeatureAsUsed(trialKey);
      }
      return true;
    }

    // A déjà utilisé son essai, montrer le paywall
    await showPaywall(
      context: context,
      paywallContext: paywallContext,
    );

    return false;
  }
}
```

---

### 2. Badge Premium sur les Boutons

#### A. Créer le Widget Badge Premium

Créer `lib/components/ui/premium_badge.dart` :

```dart
import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final bool isLocked;
  final Widget child;
  final VoidCallback? onTap;

  const PremiumBadge({
    Key? key,
    required this.isLocked,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bouton avec overlay grisé si locked
        Opacity(
          opacity: isLocked ? 0.5 : 1.0,
          child: GestureDetector(
            onTap: onTap,
            child: child,
          ),
        ),

        // Badge Premium en haut à droite
        if (isLocked)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 10,
                    color: Colors.white,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

#### B. Exemple d'Utilisation

```dart
// Dans le bouton de scan
PremiumBadge(
  isLocked: !isPremium && hasUsedTrial,
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
    // Votre bouton existant
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.camera_alt),
  ),
)
```

---

### 3. Localisation des Boutons

#### Ajouter les Boutons dans les Endroits Spécifiques

| Bouton | Emplacement | Contexte Paywall |
|--------|-------------|------------------|
| 📸 Scan repas | `ai_scanner_screen.dart` ou bottom sheet nutrition | `PaywallContext.scanner` |
| 📱 Scan code-barre | `barcode_scanner_screen.dart` ou bottom sheet nutrition | `PaywallContext.barcodeScanner` |
| 💬 Chat Coach | Bottom sheet nutrition / Dashboard | `PaywallContext.chatInput` |
| 🤖 Coach Ryze workouts | `sport_musculation_hybrid.dart` | `PaywallContext.workoutGenerator` |
| 📊 Analyse nutrition | `journal_screen.dart` ou dashboard | `PaywallContext.nutritionAnalysis` |
| 💪 Analyse exercice | Détail d'un exercice | `PaywallContext.exerciseAnalysis` |

---

### 4. Migration Supabase

Créer le fichier `supabase/migrations/20250115_add_feature_trials.sql` :

```sql
-- Table pour tracker les essais gratuits par feature
CREATE TABLE IF NOT EXISTS user_feature_trials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  used_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, feature_key)
);

-- Index
CREATE INDEX idx_user_feature_trials_user_id ON user_feature_trials(user_id);
CREATE INDEX idx_user_feature_trials_feature_key ON user_feature_trials(feature_key);

-- RLS
ALTER TABLE user_feature_trials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own trials"
  ON user_feature_trials FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own trials"
  ON user_feature_trials FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own trials"
  ON user_feature_trials FOR UPDATE
  USING (auth.uid() = user_id);
```

---

## 📋 Checklist d'Implémentation

### Phase 1 : Backend (Supabase)
- [ ] Créer la migration `20250115_add_feature_trials.sql`
- [ ] Exécuter la migration sur Supabase
- [ ] Vérifier les policies RLS

### Phase 2 : Services
- [ ] Créer `feature_trial_service.dart`
- [ ] Modifier `paywall_service.dart` pour ajouter `canUseFeature()`
- [ ] Tester le service de trial

### Phase 3 : UI Components
- [ ] Créer `premium_badge.dart`
- [ ] Tester le badge sur un bouton

### Phase 4 : Intégration des Boutons
- [ ] ✅ Bouton Scan repas (scanner)
- [ ] ✅ Bouton Scan code-barre (barcodeScanner)
- [ ] ✅ Bouton Chat Coach (chatInput)
- [ ] ✅ Bouton Coach workouts (workoutGenerator)
- [ ] ✅ Bouton Analyse nutrition (nutritionAnalysis)
- [ ] ✅ Bouton Analyse exercice (exerciseAnalysis)

### Phase 5 : Tests
- [ ] Tester le 1er essai gratuit
- [ ] Vérifier le paywall au 2ème essai
- [ ] Tester avec compte Premium (accès illimité)
- [ ] Vérifier les traductions FR/EN

---

## 🎨 Design Pattern

### Logique Commune pour Tous les Boutons Premium

```dart
// 1. Check si Premium ou 1er essai
final canUse = await PaywallService.instance.canUseFeature(
  context: context,
  paywallContext: PaywallContext.scanner, // Adapter selon le bouton
);

// 2. Si true, utiliser la feature
if (canUse) {
  // Ouvrir le scanner / chat / générateur / etc.
  Navigator.push(...);
}

// 3. Si false, le paywall s'est affiché automatiquement
// L'utilisateur revient à la page précédente
```

### Widget Wrapper pour Boutons Premium

```dart
Widget buildPremiumButton({
  required BuildContext context,
  required PaywallContext paywallContext,
  required Widget buttonChild,
  required VoidCallback onAccessGranted,
}) {
  return FutureBuilder<bool>(
    future: Future.wait([
      SubscriptionService.instance.isPremium,
      FeatureTrialService.instance.hasUsedFreeTrial(
        PaywallService.getFeatureTrialKey(paywallContext),
      ),
    ]).then((results) => !results[0] && results[1]), // isLocked
    builder: (context, snapshot) {
      final isLocked = snapshot.data ?? false;

      return PremiumBadge(
        isLocked: isLocked,
        onTap: () async {
          final canUse = await PaywallService.instance.canUseFeature(
            context: context,
            paywallContext: paywallContext,
          );

          if (canUse) {
            onAccessGranted();
          }
        },
        child: buttonChild,
      );
    },
  );
}
```

---

## 📊 Résumé

✅ **Traductions** : Complètes pour les 7 paywalls (FR/EN)
✅ **Design** : Unifié avec bulle gradient bleu navy
✅ **Contextes** : 7 paywalls différents avec contenu adapté
⏳ **Service Trial** : À implémenter
⏳ **Badge Premium** : À créer
⏳ **Intégration Boutons** : À faire pour chaque écran

**Prochaine étape** : Implémenter le `FeatureTrialService` et créer la migration Supabase.
