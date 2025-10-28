// ============================================================================
// 📱 EXEMPLE D'INTÉGRATION DU SYSTÈME DE PAYWALL
// ============================================================================
// Ce fichier montre comment intégrer les paywalls dans tes écrans existants
// ============================================================================

import 'package:flutter/material.dart';
import 'services/subscription_service.dart';
import 'services/paywall_service.dart';

// ============================================================================
// EXEMPLE 1: Vérifier limite quotidienne (Scanner IA)
// ============================================================================

class AIScannerScreenExample extends StatefulWidget {
  @override
  State<AIScannerScreenExample> createState() => _AIScannerScreenExampleState();
}

class _AIScannerScreenExampleState extends State<AIScannerScreenExample> {
  final _paywallService = PaywallService.instance;
  final _subscriptionService = SubscriptionService.instance;

  // Fonction de scan IA
  Future<void> _takePicture() async {
    // ✅ AVANT de scanner, vérifier la limite quotidienne
    final canScan = await _paywallService.checkDailyLimit(
      context: context,
      featureName: 'ai_scans',
      limit: 3, // 3 scans/jour en Free
      paywallContext: PaywallService.PaywallContext.aiScanLimit,
    );

    if (!canScan) {
      // Paywall affiché automatiquement
      // Si user clique "Passer" → return false
      // Si user upgrade → return true
      return;
    }

    // ✅ Limite OK, continuer le scan
    print('📸 Scanner le repas...');
    // ... ton code de scan existant ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scanner IA')),
      body: Center(
        child: ElevatedButton(
          onPressed: _takePicture,
          child: Text('Prendre une photo'),
        ),
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 2: Vérifier accès à une feature (Générateur Workout)
// ============================================================================

class WorkoutGeneratorExample extends StatelessWidget {
  final _paywallService = PaywallService.instance;

  Future<void> _openGenerator(BuildContext context) async {
    // ✅ Vérifier si user peut accéder au générateur
    final canAccess = await _paywallService.canAccessFeature(
      context: context,
      featureName: 'ai_workout_generator',
      paywallContext: PaywallService.PaywallContext.workoutGenerator,
    );

    if (!canAccess) {
      // Paywall affiché, user a refusé
      return;
    }

    // ✅ Accès OK, ouvrir le générateur
    Navigator.pushNamed(context, '/workout-generator');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _openGenerator(context),
      child: Text('Générer un workout IA'),
    );
  }
}

// ============================================================================
// EXEMPLE 3: Afficher badge Premium dans settings
// ============================================================================

class SettingsScreenExample extends StatelessWidget {
  final _subscriptionService = SubscriptionService.instance;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Badge Premium
        ListTile(
          leading: Icon(
            _subscriptionService.isPremium ? Icons.star : Icons.star_border,
            color: _subscriptionService.isPremium ? Colors.amber : Colors.grey,
          ),
          title: Text(
            _subscriptionService.isPremium ? 'Premium' : 'Version gratuite',
          ),
          subtitle: _subscriptionService.isInTrial
              ? Text('Essai: ${_subscriptionService.trialDaysRemaining} jours restants')
              : Text(_subscriptionService.isPremium
                  ? 'Toutes les fonctionnalités débloquées'
                  : 'Passe Premium pour plus de features'),
          trailing: _subscriptionService.isPremium
              ? null
              : ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/pricing');
                  },
                  child: Text('Upgrade'),
                ),
        ),

        // Autres settings...
      ],
    );
  }
}

// ============================================================================
// EXEMPLE 4: Vérifier Premium avant export
// ============================================================================

class ExportDataExample extends StatelessWidget {
  final _paywallService = PaywallService.instance;
  final _subscriptionService = SubscriptionService.instance;

  Future<void> _exportData(BuildContext context) async {
    // ✅ Méthode 1: Vérifier manuellement
    if (!_subscriptionService.isPremium) {
      await _paywallService.showPaywall(
        context: context,
        paywallContext: PaywallService.PaywallContext.exportData,
      );
      return;
    }

    // ✅ Export les données
    print('📄 Exporting data...');
  }

  // OU

  Future<void> _exportDataV2(BuildContext context) async {
    // ✅ Méthode 2: Utiliser canAccessFeature
    final canExport = await _paywallService.canAccessFeature(
      context: context,
      featureName: 'data_export',
      paywallContext: PaywallService.PaywallContext.exportData,
    );

    if (canExport) {
      print('📄 Exporting data...');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _exportData(context),
      child: Text('Exporter mes données'),
    );
  }
}

// ============================================================================
// EXEMPLE 5: Dashboard avec compteur de scans
// ============================================================================

class DashboardExample extends StatefulWidget {
  @override
  State<DashboardExample> createState() => _DashboardExampleState();
}

class _DashboardExampleState extends State<DashboardExample> {
  final _subscriptionService = SubscriptionService.instance;
  int _scansUsedToday = 0;

  @override
  void initState() {
    super.initState();
    _loadScansCount();
  }

  Future<void> _loadScansCount() async {
    final count = await _subscriptionService.getDailyUsage('ai_scans');
    setState(() => _scansUsedToday = count);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _subscriptionService.isPremium;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Scans IA aujourd\'hui',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (isPremium)
              Text(
                '♾️ Illimité',
                style: TextStyle(fontSize: 24, color: Colors.green),
              )
            else
              Text(
                '$_scansUsedToday / 3',
                style: TextStyle(
                  fontSize: 24,
                  color: _scansUsedToday >= 3 ? Colors.red : Colors.blue,
                ),
              ),
            SizedBox(height: 8),
            if (!isPremium && _scansUsedToday >= 3)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/pricing');
                },
                child: Text('Passer Premium'),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 6: Initialiser dans main.dart
// ============================================================================

/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  // ✅ Initialiser le service d'abonnement
  await SubscriptionService.instance.initialize();

  runApp(MyApp());
}
*/

// ============================================================================
// EXEMPLE 7: Routes dans MaterialApp
// ============================================================================

/*
MaterialApp(
  routes: {
    '/': (context) => HomeScreen(),
    '/pricing': (context) => PricingScreen(),
    // ... autres routes
  },
);
*/

// ============================================================================
// EXEMPLE 8: Debug - Afficher infos abonnement
// ============================================================================

class DebugSubscriptionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Afficher toutes les infos dans la console
        SubscriptionService.instance.debugPrintSubscriptionInfo();
      },
      child: Text('Debug Subscription'),
    );
  }
}

// ============================================================================
// EXEMPLE 9: Reset subscription (pour tester)
// ============================================================================

class ResetSubscriptionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await SubscriptionService.instance.resetSubscription();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription reset to FREE')),
        );
      },
      child: Text('Reset to FREE (Debug)'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    );
  }
}

// ============================================================================
// EXEMPLE 10: Upgrade manuel (pour tester)
// ============================================================================

class UpgradeToPremiumButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await SubscriptionService.instance.upgradeToPremium(
          period: SubscriptionPeriod.monthly,
          testBypass: true, // MODE TEST
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🧪 TEST: Upgraded to Premium!')),
        );
      },
      child: Text('🧪 Upgrade to Premium (TEST)'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    );
  }
}

// ============================================================================
// 📚 RÉSUMÉ - CHEAT SHEET
// ============================================================================

/*

1. VÉRIFIER SI PREMIUM
   final isPremium = SubscriptionService.instance.isPremium;

2. VÉRIFIER LIMITE QUOTIDIENNE
   final canUse = await PaywallService.instance.checkDailyLimit(
     context: context,
     featureName: 'ai_scans',
     limit: 3,
     paywallContext: PaywallService.PaywallContext.aiScanLimit,
   );

3. VÉRIFIER ACCÈS FEATURE
   final canAccess = await PaywallService.instance.canAccessFeature(
     context: context,
     featureName: 'ai_workout_generator',
     paywallContext: PaywallService.PaywallContext.workoutGenerator,
   );

4. AFFICHER PAYWALL MANUELLEMENT
   await PaywallService.instance.showPaywall(
     context: context,
     paywallContext: PaywallService.PaywallContext.genericUpgrade,
   );

5. NAVIGUER VERS PRICING
   Navigator.pushNamed(context, '/pricing');

6. DÉBUG
   SubscriptionService.instance.debugPrintSubscriptionInfo();

7. RESET (TEST)
   await SubscriptionService.instance.resetSubscription();

8. UPGRADE (TEST)
   await SubscriptionService.instance.upgradeToPremium(
     period: SubscriptionPeriod.monthly,
     testBypass: true,
   );

*/
