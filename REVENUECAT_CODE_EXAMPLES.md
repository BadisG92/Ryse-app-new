# RevenueCat - Exemples de Code

Guide pratique avec des exemples concrets d'utilisation du système d'abonnement.

---

## 📋 Table des matières

1. [Initialisation](#initialisation)
2. [Vérification d'accès Premium](#vérification-daccès-premium)
3. [Afficher le Paywall](#afficher-le-paywall)
4. [Protéger les features IA](#protéger-les-features-ia)
5. [Afficher le statut Premium](#afficher-le-statut-premium)
6. [Restaurer les achats](#restaurer-les-achats)
7. [Gérer le trial](#gérer-le-trial)

---

## 1. Initialisation

### Dans `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/unified_subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // Initialiser le service d'abonnement unifié
  final subscriptionService = UnifiedSubscriptionService();
  await subscriptionService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ryse',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

## 2. Vérification d'accès Premium

### Méthode simple

```dart
import 'package:ryse_app/services/unified_subscription_service.dart';

void checkPremiumStatus() {
  final subscription = UnifiedSubscriptionService();

  if (subscription.isPremium) {
    print('✅ Utilisateur Premium');
  } else if (subscription.isInTrial) {
    print('🎁 En période d\'essai (${subscription.trialDaysRemaining} jours restants)');
  } else {
    print('❌ Utilisateur gratuit');
  }
}
```

### Avec écoute des changements

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _subscription = UnifiedSubscriptionService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _subscription,
      builder: (context, _) {
        return Text(
          _subscription.isPremium ? 'Premium Active' : 'Free Version',
          style: TextStyle(
            color: _subscription.isPremium ? Colors.green : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
```

---

## 3. Afficher le Paywall

### Modal Bottom Sheet (recommandé)

```dart
import 'package:flutter/material.dart';
import 'package:ryse_app/screens/paywall_screen.dart';
import 'package:ryse_app/models/subscription_models.dart';

Future<bool> showPremiumPaywall(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true, // Important pour le scroll
    backgroundColor: Colors.transparent,
    builder: (context) => PaywallScreen(
      context: PaywallContext.aiScanner,
      customTitle: 'Débloquez le Scanner IA',
      customMessage: 'Scannez et analysez vos repas instantanément',
    ),
  );

  return result ?? false; // true si upgrade réussi
}
```

### Contextes disponibles

```dart
enum PaywallContext {
  aiScanner,        // Scanner IA nourriture
  aiAnalysis,       // Analyse nutrition quotidienne
  aiWorkout,        // Générateur séances sport
  aiChat,           // Chat IA nutrition/sport
  recipeGenerator,  // Générateur recettes IA
  dataExport,       // Export de données
  advancedCharts,   // Graphiques avancés
  unlimitedHistory, // Historique illimité
}
```

### Avec titre et message personnalisés

```dart
Future<void> showCustomPaywall(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PaywallScreen(
      context: PaywallContext.aiAnalysis,
      customTitle: '🤖 Coach IA Personnel',
      customMessage: 'Recevez une analyse quotidienne personnalisée de votre nutrition et progression',
    ),
  );
}
```

---

## 4. Protéger les features IA

### Scanner IA Nourriture

```dart
import 'package:flutter/material.dart';
import 'package:ryse_app/services/unified_subscription_service.dart';
import 'package:ryse_app/screens/paywall_screen.dart';

class AiScannerScreen extends StatefulWidget {
  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
  final _subscription = UnifiedSubscriptionService();

  Future<void> _startScanning() async {
    // Vérifier si premium
    if (!_subscription.isPremium) {
      // Afficher le paywall
      final upgraded = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PaywallScreen(
          context: PaywallContext.aiScanner,
          customTitle: 'Scanner IA Premium',
          customMessage: 'Scannez vos repas et obtenez une analyse nutritionnelle instantanée',
        ),
      );

      if (upgraded != true) {
        // Utilisateur a refusé ou annulé
        return;
      }
    }

    // L'utilisateur est Premium, continuer avec le scan
    _performAiScan();
  }

  Future<void> _performAiScan() async {
    // Logique du scan IA
    print('🤖 Scanning with AI...');
    // ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scanner IA')),
      body: Center(
        child: ElevatedButton(
          onPressed: _startScanning,
          child: Text('Scanner un repas'),
        ),
      ),
    );
  }
}
```

### Analyse Nutrition Quotidienne

```dart
class DailyAnalysisWidget extends StatelessWidget {
  final _subscription = UnifiedSubscriptionService();

  Future<void> _requestAnalysis(BuildContext context) async {
    if (!_subscription.isPremium) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PaywallScreen(
          context: PaywallContext.aiAnalysis,
          customTitle: 'Analyse Quotidienne IA',
          customMessage: 'Obtenez des recommandations personnalisées de votre coach nutrition',
        ),
      );
      return;
    }

    // Générer l'analyse
    _generateAnalysis();
  }

  Future<void> _generateAnalysis() async {
    // Appel à Gemini API pour analyse
    print('🤖 Generating daily analysis...');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.analytics, color: Color(0xFF10B981)),
        title: Text('Analyse du jour'),
        subtitle: Text('Demandez votre analyse IA personnalisée'),
        trailing: Icon(Icons.chevron_right),
        onTap: () => _requestAnalysis(context),
      ),
    );
  }
}
```

### Chat IA Nutrition

```dart
class AiChatScreen extends StatefulWidget {
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _subscription = UnifiedSubscriptionService();
  bool _isAccessGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    if (!_subscription.isPremium) {
      // Afficher le paywall immédiatement
      final upgraded = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false, // Empêcher la fermeture accidentelle
        builder: (context) => WillPopScope(
          onWillPop: () async => false, // Désactiver le retour arrière
          child: PaywallScreen(
            context: PaywallContext.aiChat,
            customTitle: 'Chat IA Nutrition & Sport',
            customMessage: 'Posez toutes vos questions à votre coach IA personnel',
          ),
        ),
      );

      if (upgraded != true) {
        // Retour à l'écran précédent
        Navigator.pop(context);
        return;
      }
    }

    setState(() => _isAccessGranted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAccessGranted) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat IA'),
        actions: [
          // Badge Premium
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text('PREMIUM', style: TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
      body: ChatMessagesWidget(),
    );
  }
}
```

### Générateur Séances Sport

```dart
class WorkoutGeneratorButton extends StatelessWidget {
  final _subscription = UnifiedSubscriptionService();

  Future<void> _generateWorkout(BuildContext context) async {
    // Check Premium
    if (!_subscription.isPremium) {
      final upgraded = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PaywallScreen(
          context: PaywallContext.aiWorkout,
          customTitle: 'Générateur de Séances IA',
          customMessage: 'Créez des programmes d\'entraînement personnalisés avec l\'IA',
        ),
      );

      if (upgraded != true) return;
    }

    // Générer le workout
    _showWorkoutGenerator(context);
  }

  Future<void> _showWorkoutGenerator(BuildContext context) async {
    // Logique de génération
    print('🤖 Generating personalized workout...');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _generateWorkout(context),
      icon: Icon(Icons.fitness_center),
      label: Text('Générer une séance IA'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF10B981),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}
```

---

## 5. Afficher le statut Premium

### Badge Premium simple

```dart
class PremiumBadge extends StatelessWidget {
  final _subscription = UnifiedSubscriptionService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _subscription,
      builder: (context, _) {
        if (!_subscription.isPremium) return SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'PREMIUM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Card avec détails Trial/Premium

```dart
class SubscriptionStatusCard extends StatelessWidget {
  final _subscription = UnifiedSubscriptionService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _subscription,
      builder: (context, _) {
        if (_subscription.isPremium) {
          return _buildPremiumCard();
        } else if (_subscription.isInTrial) {
          return _buildTrialCard(_subscription.trialDaysRemaining);
        } else {
          return _buildFreeCard(context);
        }
      },
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Actif',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Toutes les fonctionnalités IA débloquées',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard(int daysRemaining) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Essai gratuit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Plus que $daysRemaining jour${daysRemaining > 1 ? 's' : ''} restant${daysRemaining > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF64748B), size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version Gratuite',
                  style: TextStyle(
                    color: Color(0xFF0B132B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Passez à Premium pour débloquer l\'IA',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showPaywall(context),
            icon: Icon(Icons.arrow_forward, color: Color(0xFF10B981)),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaywall(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallScreen(
        context: PaywallContext.aiScanner,
      ),
    );
  }
}
```

---

## 6. Restaurer les achats

### Bouton "Restaurer les achats" (iOS)

```dart
class RestorePurchasesButton extends StatefulWidget {
  @override
  State<RestorePurchasesButton> createState() => _RestorePurchasesButtonState();
}

class _RestorePurchasesButtonState extends State<RestorePurchasesButton> {
  final _subscription = UnifiedSubscriptionService();
  bool _isRestoring = false;

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);

    try {
      final success = await _subscription.restorePurchases();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Achats restaurés avec succès!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ℹ️ Aucun abonnement actif trouvé'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la restauration'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _isRestoring ? null : _restorePurchases,
      child: _isRestoring
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text('Restaurer les achats'),
    );
  }
}
```

---

## 7. Gérer le trial

### Démarrer le trial

```dart
Future<void> startFreeTrial(BuildContext context) async {
  final subscription = UnifiedSubscriptionService();

  final success = await subscription.startTrial();

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Essai gratuit activé ! 7 jours de Premium'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );

    // Afficher un message de bienvenue
    _showTrialWelcomeDialog(context);
  }
}

Future<void> _showTrialWelcomeDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('🎉 Bienvenue dans Premium !'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vous avez maintenant accès à :'),
          SizedBox(height: 12),
          _buildFeatureItem('Scanner IA illimité'),
          _buildFeatureItem('Analyse nutrition quotidienne'),
          _buildFeatureItem('Générateur séances sport'),
          _buildFeatureItem('Chat IA nutrition & sport'),
          _buildFeatureItem('Recettes illimitées'),
          SizedBox(height: 12),
          Text(
            'Votre essai gratuit se termine dans 7 jours.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Commencer !'),
        ),
      ],
    ),
  );
}

Widget _buildFeatureItem(String text) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
        SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
      ],
    ),
  );
}
```

### Afficher un rappel fin de trial

```dart
class TrialEndingBanner extends StatelessWidget {
  final _subscription = UnifiedSubscriptionService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _subscription,
      builder: (context, _) {
        // Afficher seulement si en trial avec 2 jours ou moins
        if (!_subscription.isInTrial || _subscription.trialDaysRemaining > 2) {
          return SizedBox.shrink();
        }

        final daysLeft = _subscription.trialDaysRemaining;

        return Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      daysLeft == 1
                          ? 'Dernier jour d\'essai gratuit !'
                          : 'Plus que $daysLeft jours d\'essai',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Continuez à profiter de toutes les fonctionnalités IA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showPaywall(context),
                icon: Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPaywall(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallScreen(
        context: PaywallContext.aiScanner,
        customTitle: 'Ne perdez pas vos avantages Premium',
        customMessage: 'Votre essai gratuit se termine bientôt. Continuez à profiter de toutes les fonctionnalités !',
      ),
    );
  }
}
```

---

## 🎯 Résumé

### Pattern général pour protéger une feature

```dart
Future<void> protectedFeature(BuildContext context) async {
  final subscription = UnifiedSubscriptionService();

  // 1. Vérifier si Premium
  if (!subscription.isPremium) {
    // 2. Afficher le paywall
    final upgraded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallScreen(
        context: PaywallContext.aiScanner,
      ),
    );

    // 3. Si pas d'upgrade, arrêter
    if (upgraded != true) return;
  }

  // 4. Exécuter la feature
  _executeFeature();
}
```

### Intégration Login/Logout

```dart
// Login
await UnifiedSubscriptionService().login(userId);

// Logout
await UnifiedSubscriptionService().logout();
```

### Debug

```dart
UnifiedSubscriptionService().debugPrintInfo();
```

Affiche :
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 UNIFIED SUBSCRIPTION INFO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test Mode: true
Is Premium: true
Is Trial: false
Trial Days: 0
Tier: premium
RevenueCat Initialized: false
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

**Bon code ! 🚀**
