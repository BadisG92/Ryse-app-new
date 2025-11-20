# 🎯 Intégration des Badges Premium - Plan d'Action

## ✅ Migration Supabase

**Statut** : À appliquer manuellement via Dashboard

1. Ouvrir : https://supabase.com/dashboard/project/mfskwlzgxjhhknlwpblq/sql/new
2. Copier le contenu de `supabase/migrations/20250115_add_feature_trials.sql`
3. Coller et exécuter (Run ou Ctrl+Enter)
4. Vérifier la table : Table Editor → `user_feature_trials`

---

## 📍 Les 6 Boutons à Intégrer

### 1. Scanner Photo (📸)
**Fichier** : `lib/bottom_sheets/add_food_bottom_sheet.dart`
**Ligne** : ~104-117
**Bouton** : Scanner IA (camera icon)

**Action** : Remplacer le `onTap` actuel par un appel à `PaywallService.instance.canUseFeature()`

```dart
// AVANT (ligne 104)
onTap: () {
  Navigator.pop(bottomSheetContext);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AIScannerScreen(...),
    ),
  );
}

// APRÈS
onTap: () async {
  Navigator.pop(bottomSheetContext);

  final canUse = await PaywallService.instance.canUseFeature(
    context: context,
    paywallContext: PaywallContext.scanner,
  );

  if (canUse) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIScannerScreen(
          isFromDashboard: mealName == null && mealId == null,
          mealName: mealName,
          mealId: mealId,
        ),
      ),
    );
  }
}
```

**Badge PRO** : Ajouter un indicateur visuel sur le bouton si verrouillé (optionnel, car le bouton ouvre quand même le premier essai gratuit)

---

### 2. Scanner Barcode (🔍)
**Fichier** : `lib/bottom_sheets/add_food_bottom_sheet.dart`
**Ligne** : ~130-140
**Bouton** : Barcode (scan icon)

```dart
// APRÈS
onTap: () async {
  Navigator.pop(bottomSheetContext);

  final canUse = await PaywallService.instance.canUseFeature(
    context: context,
    paywallContext: PaywallContext.barcodeScanner,
  );

  if (canUse) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
  }
}
```

---

### 3. Chat Coach (💬)
**Fichier** : `lib/screens/ai_chat_input_screen.dart` (à vérifier)
**Contexte** : Déclarer repas au Coach Ryze (texte/voix)

**À localiser** : Le bouton qui ouvre le chat pour déclarer un repas

```dart
onTap: () async {
  final canUse = await PaywallService.instance.canUseFeature(
    context: context,
    paywallContext: PaywallContext.chatInput,
  );

  if (canUse) {
    // Ouvrir le chat
  }
}
```

---

### 4. Générateur de Workouts (🤖)
**Fichier** : `lib/components/sport_musculation_hybrid.dart`
**Contexte** : Coach Ryze génère un workout personnalisé

**À localiser** : Le bouton "Coach Ryze" ou "Générer un workout"

```dart
onTap: () async {
  final canUse = await PaywallService.instance.canUseFeature(
    context: context,
    paywallContext: PaywallContext.workoutGenerator,
  );

  if (canUse) {
    // Générer le workout
  }
}
```

---

### 5. Bilan Nutrition (📊)
**Fichier** : À déterminer (dashboard nutrition ou journal)
**Contexte** : Analyse quotidienne du Coach Ryze

**À localiser** : Le bouton "Analyse du Coach" ou "Bilan quotidien"

```dart
onTap: () async {
  final canUse = await PaywallService.instance.canUseFeature(
    context: context,
    paywallContext: PaywallContext.nutritionAnalysis,
  );

  if (canUse) {
    // Afficher l'analyse
  }
}
```

---

### 6. Analyse Exercice (💪)
**Fichier** : À déterminer (écran détail exercice)
**Contexte** : Analyse de progression par exercice

**À localiser** : Le bouton d'analyse dans le détail d'un exercice

```dart
onTap: () async {
  final canUse = await PaywallService.instance.canUseFeature(
    context: context,
    paywallContext: PaywallContext.exerciseAnalysis,
  );

  if (canUse) {
    // Afficher l'analyse
  }
}
```

---

## 🎨 Ajouter le Badge PRO (Optionnel)

Si tu veux afficher un badge "PRO" doré sur les boutons verrouillés :

```dart
// Import
import '../components/ui/premium_badge.dart';
import '../services/paywall_service.dart';

// Wrapper le bouton avec FutureBuilder
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
          // Ouvrir la feature
        }
      },
      child: FoodOptionWidget(
        icon: LucideIcons.camera,
        title: 'Scanner IA',
        subtitle: 'Prends une photo...',
      ),
    );
  },
)
```

---

## ✅ Checklist d'Intégration

### Phase 1 : Migration DB
- [ ] Appliquer la migration via Dashboard Supabase
- [ ] Vérifier que la table `user_feature_trials` existe
- [ ] Tester une insertion manuelle (optionnel)

### Phase 2 : Intégration Bottom Sheet (Nutrition)
- [ ] Modifier Scanner Photo (add_food_bottom_sheet.dart:104)
- [ ] Modifier Scanner Barcode (add_food_bottom_sheet.dart:130)
- [ ] Tester le flow : 1er essai gratuit → 2ème essai → paywall

### Phase 3 : Intégration Chat Coach
- [ ] Localiser le bouton Chat dans le code
- [ ] Ajouter `canUseFeature()` avec contexte `chatInput`
- [ ] Tester le flow

### Phase 4 : Intégration Sport
- [ ] Localiser le bouton Générateur Workout
- [ ] Ajouter `canUseFeature()` avec contexte `workoutGenerator`
- [ ] Localiser le bouton Analyse Exercice
- [ ] Ajouter `canUseFeature()` avec contexte `exerciseAnalysis`
- [ ] Tester le flow

### Phase 5 : Intégration Analyse Nutrition
- [ ] Localiser le bouton Bilan/Analyse quotidienne
- [ ] Ajouter `canUseFeature()` avec contexte `nutritionAnalysis`
- [ ] Tester le flow

### Phase 6 : Tests Finaux
- [ ] Tester en tant que non-Premium : 1er essai gratuit pour chaque feature
- [ ] Tester en tant que non-Premium : 2ème essai affiche paywall
- [ ] Tester en tant que Premium : accès illimité sans paywall
- [ ] Vérifier que les trials sont bien trackés dans la DB

---

## 🚀 Prochaines Étapes

1. **Maintenant** : Applique la migration Supabase
2. **Ensuite** : Je modifie le bottom sheet nutrition (Scanner + Barcode)
3. **Puis** : On localise les 4 autres boutons ensemble
4. **Enfin** : Tests complets du système

---

## 📝 Notes Importantes

- **Pas besoin de badge PRO systématiquement** : L'utilisateur non-Premium voit le bouton normalement, le paywall s'affiche au bon moment
- **Premium users** : Aucun changement pour eux, accès illimité direct
- **Analytics** : Possibilité d'ajouter du tracking Firebase pour voir combien d'essais gratuits sont utilisés
- **Support** : La fonction `resetTrial()` permet de réinitialiser un essai pour le support client

---

## 🔍 Debugging

Si un utilisateur ne voit pas le paywall ou a un comportement inattendu :

```dart
// Dans FeatureTrialService, les logs sont activés :
print('✅ FeatureTrialService: hasUsedFreeTrial($featureKey) = $hasUsed');
print('✅ FeatureTrialService: Marked $featureKey as used');

// Dans PaywallService :
print('✅ PaywallService: User is Premium, granting access');
print('🎁 PaywallService: First free trial for ${paywallContext.name}');
print('🚫 PaywallService: Trial already used, showing paywall');
```

Vérifier les logs dans la console Flutter pour comprendre le flow.

---

**Système prêt à l'emploi dès que la migration est appliquée!** 🎉
