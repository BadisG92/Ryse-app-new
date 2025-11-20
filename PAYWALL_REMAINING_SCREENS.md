# 🔒 Guide d'implémentation des Paywalls restants

## ✅ DÉJÀ FAIT

1. ✅ **Trial Offer Screen** créé → Affiché après onboarding
2. ✅ **PaywallService** mis à jour → Nouveaux contextes Coach Ryze
3. ✅ **ai_scanner_screen.dart** → Bloqué avec `PaywallContext.scanner`
4. ✅ **barcode_scanner_screen.dart** → Bloqué avec `PaywallContext.barcodeScanner`
5. ✅ **RyzeApp** modifié → Navigation vers Trial Offer après onboarding

---

## 🔧 À FAIRE : 5 écrans restants

### **1. ai_chat_input_screen.dart**

**Fichier** : `lib/screens/ai_chat_input_screen.dart`

**Modifications** :

```dart
// 1. Ajouter les imports en haut du fichier
import '../services/subscription_service.dart';
import '../services/paywall_service.dart';

// 2. Dans initState(), ajouter AVANT tout le reste :
@override
void initState() {
  super.initState();
  _speech = stt.SpeechToText();
  _initSpeech();

  // 🔒 AJOUTER CETTE LIGNE
  _checkPremiumAccess();
}

// 3. Ajouter cette méthode après initState()
/// Vérifier si l'utilisateur a accès au chat (Premium uniquement)
Future<void> _checkPremiumAccess() async {
  final isPremium = SubscriptionService.instance.isPremium;

  if (!isPremium) {
    // Afficher le paywall
    final upgraded = await PaywallService.instance.showPaywall(
      context: context,
      paywallContext: PaywallContext.chatInput,
    );

    if (!upgraded && mounted) {
      // L'utilisateur n'a pas souscrit, fermer le bottom sheet
      Navigator.pop(context);
      return;
    }
  }
}
```

---

### **2. ai_workout_generator_screen.dart**

**Fichier** : `lib/screens/ai_workout_generator_screen.dart`

**Modifications** :

```dart
// 1. Ajouter les imports en haut du fichier
import '../services/subscription_service.dart';
import '../services/paywall_service.dart';

// 2. Dans initState(), ajouter APRÈS l'animation :
@override
void initState() {
  super.initState();

  // Initialiser l'animation (EXISTANT)
  _animationController = AnimationController(...);
  _fadeAnimation = ...;
  _slideAnimation = ...;
  _animationController.forward();

  // 🔒 AJOUTER CES LIGNES
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkPremiumAccess();
  });
}

// 3. Ajouter cette méthode après initState()
/// Vérifier si l'utilisateur a accès au générateur (Premium uniquement)
Future<void> _checkPremiumAccess() async {
  final isPremium = SubscriptionService.instance.isPremium;

  if (!isPremium) {
    // Afficher le paywall
    final upgraded = await PaywallService.instance.showPaywall(
      context: context,
      paywallContext: PaywallContext.workoutGenerator,
    );

    if (!upgraded && mounted) {
      // L'utilisateur n'a pas souscrit, retour
      Navigator.pop(context);
      return;
    }
  }
}
```

---

### **3. coach_ryze_nutrition_button.dart** (Bilan quotidien)

**Fichier** : `lib/components/coach_ryze_nutrition_button.dart`

**Ce widget est un bouton, donc on bloque au CLIC, pas dans initState**

**Modifications** :

```dart
// 1. Ajouter les imports en haut du fichier
import '../services/subscription_service.dart';
import '../services/paywall_service.dart';

// 2. Trouver la méthode onTap du bouton et REMPLACER par :
onTap: () async {
  // 🔒 VÉRIFIER PREMIUM AVANT D'OUVRIR
  final isPremium = SubscriptionService.instance.isPremium;

  if (!isPremium) {
    // Afficher le paywall
    final upgraded = await PaywallService.instance.showPaywall(
      context: context,
      paywallContext: PaywallContext.nutritionAnalysis,
    );

    if (!upgraded) {
      return; // Ne pas ouvrir l'écran si pas Premium
    }
  }

  // Si Premium ou upgrade réussi, ouvrir l'écran d'analyse
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NutritionAnalysisScreen(...),
    ),
  );
},
```

---

### **4. exercise_ai_analysis_widget.dart** (Analyse exercice)

**Fichier** : `lib/components/exercise_ai_analysis_widget.dart`

**Ce widget affiche un bouton "Générer l'analyse", bloquer ce bouton**

**Modifications** :

```dart
// 1. Ajouter les imports en haut du fichier
import '../services/subscription_service.dart';
import '../services/paywall_service.dart';

// 2. Trouver la méthode _generateAnalysis() et MODIFIER le début :
Future<void> _generateAnalysis() async {
  if (!mounted) return;

  // 🔒 VÉRIFIER PREMIUM AVANT DE GÉNÉRER
  final isPremium = SubscriptionService.instance.isPremium;

  if (!isPremium) {
    // Afficher le paywall
    final upgraded = await PaywallService.instance.showPaywall(
      context: context,
      paywallContext: PaywallContext.exerciseAnalysis,
    );

    if (!upgraded) {
      return; // Ne pas générer si pas Premium
    }
  }

  // RESTE DU CODE EXISTANT
  final locService = context.read<LocalizationService>();
  final languageCode = locService.currentLanguageCode;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  // ... suite du code existant
}
```

---

### **5. nutrition_analysis_screen.dart** (si accès direct)

**Fichier** : `lib/screens/nutrition_analysis_screen.dart`

**Si cet écran peut être ouvert directement (pas juste via le bouton), ajouter un check**

**Modifications** :

```dart
// 1. Ajouter les imports en haut du fichier
import '../services/subscription_service.dart';
import '../services/paywall_service.dart';

// 2. Dans initState(), ajouter :
@override
void initState() {
  super.initState();

  // 🔒 AJOUTER CETTE LIGNE
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkPremiumAccess();
  });
}

// 3. Ajouter cette méthode
Future<void> _checkPremiumAccess() async {
  final isPremium = SubscriptionService.instance.isPremium;

  if (!isPremium) {
    final upgraded = await PaywallService.instance.showPaywall(
      context: context,
      paywallContext: PaywallContext.nutritionAnalysis,
    );

    if (!upgraded && mounted) {
      Navigator.pop(context);
      return;
    }
  }
}
```

---

## 📊 RÉCAPITULATIF

| # | Écran/Widget | Fichier | Contexte | Type |
|---|-------------|---------|----------|------|
| ✅ | Scanner photo | `ai_scanner_screen.dart` | `PaywallContext.scanner` | Screen |
| ✅ | Scanner barcode | `barcode_scanner_screen.dart` | `PaywallContext.barcodeScanner` | Screen |
| ⏳ | Chat texte/voix | `ai_chat_input_screen.dart` | `PaywallContext.chatInput` | Bottom Sheet |
| ⏳ | Générateur workout | `ai_workout_generator_screen.dart` | `PaywallContext.workoutGenerator` | Screen |
| ⏳ | Bilan quotidien | `coach_ryze_nutrition_button.dart` | `PaywallContext.nutritionAnalysis` | Button → Screen |
| ⏳ | Analyse exercice | `exercise_ai_analysis_widget.dart` | `PaywallContext.exerciseAnalysis` | Widget Button |
| ⏳ | Écran analyse nutrition | `nutrition_analysis_screen.dart` | `PaywallContext.nutritionAnalysis` | Screen |

---

## 🎯 STRATÉGIE

### **Écrans complets (Screen)** :
- Vérifier dans `initState()` ou `didChangeDependencies()`
- Si pas Premium → Paywall → Si pas upgraded → `Navigator.pop()`

### **Bottom Sheets** :
- Vérifier dans `initState()`
- Si pas Premium → Paywall → Si pas upgraded → `Navigator.pop()`

### **Boutons (onTap)** :
- Vérifier AVANT d'ouvrir l'écran
- Si pas Premium → Paywall → Si upgraded → Ouvrir écran

---

## 🧪 TESTER

1. **Sans abonnement** :
   - ✅ Cliquer sur Scanner → Paywall apparaît
   - ✅ Cliquer sur Chat → Paywall apparaît
   - ✅ Cliquer sur Coach Ryze (workout) → Paywall apparaît
   - ✅ Cliquer sur Bilan → Paywall apparaît

2. **Après avoir souscrit** :
   - ✅ Toutes les features s'ouvrent normalement
   - ✅ Pas de paywall intempestif

3. **Mode TEST** :
   - ✅ Activer `SubscriptionService.TEST_MODE = true`
   - ✅ Bouton "Simuler paiement" fonctionne
   - ✅ Après simulation, toutes les features débloquées

---

## 💡 NOTES

- **RevenueCat** : `SubscriptionService.instance.isPremium` vérifie automatiquement le statut d'abonnement via RevenueCat
- **Trial 7 jours** : Géré par App Store, RevenueCat retourne `isPremium = true` pendant le trial
- **Wording** : Tous les messages utilisent "Coach Ryze" au lieu de "IA"
- **Contextes** : Chaque feature a son propre `PaywallContext` pour analytics

---

Voulez-vous que je continue l'implémentation des 5 écrans restants ? 🚀
