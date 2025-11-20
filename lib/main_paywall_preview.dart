import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/localization_service.dart';
import 'services/subscription_service.dart';
import 'screens/paywall_preview_screen.dart';

/// Point d'entrée pour la prévisualisation des paywalls
/// Lance avec: flutter run -t lib/main_paywall_preview.dart --dart-define-from-file=.env.local
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service d'abonnement (en mode TEST)
  await SubscriptionService.instance.initialize();

  runApp(const PaywallPreviewApp());
}

class PaywallPreviewApp extends StatelessWidget {
  const PaywallPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocalizationService.instance,
      child: MaterialApp(
        title: 'Paywall Preview',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF0B132B),
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'SF Pro Display',
        ),
        home: const PaywallPreviewScreen(),
      ),
    );
  }
}
