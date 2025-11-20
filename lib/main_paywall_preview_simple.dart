import 'package:flutter/material.dart';
import 'screens/paywall_preview_screen.dart';

/// Point d'entrée SIMPLIFIÉ pour la prévisualisation des paywalls
/// Lance avec: flutter run -t lib/main_paywall_preview_simple.dart
void main() {
  runApp(const PaywallPreviewApp());
}

class PaywallPreviewApp extends StatelessWidget {
  const PaywallPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paywall Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0B132B),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SF Pro Display',
      ),
      home: const PaywallPreviewScreen(),
    );
  }
}
