import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/env_config.dart';
import 'config/supabase_config.dart';
import 'services/analytics_service.dart';
import 'services/revenuecat_service.dart';
import 'screens/paywall_screen.dart';
import 'services/paywall_service.dart';

/// Main de test pour afficher uniquement le paywall
/// Utile pour prendre des captures d'écran pour App Store Connect
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== FIREBASE ANALYTICS =====
  try {
    await Firebase.initializeApp();
    await AnalyticsService.initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
  }

  // ===== CONFIGURATION =====
  try {
    EnvConfig.validateConfiguration();
    EnvConfig.logConfiguration();
  } catch (e) {
    debugPrint('❌ Configuration Error: $e');
  }

  // ===== SUPABASE =====
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
  }

  // ===== REVENUECAT (Si TEST_MODE=false) =====
  if (!EnvConfig.testMode) {
    try {
      await RevenueCatService().initialize();
    } catch (e) {
      debugPrint('❌ RevenueCat initialization failed: $e');
    }
  }

  runApp(const PaywallTestApp());
}

class PaywallTestApp extends StatelessWidget {
  const PaywallTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ryze Paywall Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const PaywallTestScreen(),
    );
  }
}

class PaywallTestScreen extends StatelessWidget {
  const PaywallTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PaywallScreen(
          context: PaywallContext.genericUpgrade,
          customTitle: 'Débloquez Coach Ryze Premium',
          customMessage: 'Essai gratuit de 7 jours',
        ),
      ),
    );
  }
}
