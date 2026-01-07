import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/localization_service.dart';
import 'services/paywall_service.dart';
import 'config/supabase_config.dart';
import 'config/env_config.dart';

// Import final paywall screen
import 'screens/paywall_screen.dart';
import 'services/haptic_service.dart';

/// Test app to compare OLD vs NEW paywall designs
/// Run with: flutter run --dart-define-from-file=.env.local lib/main_paywall_preview_v2.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (required for SubscriptionService)
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase initialized for preview');
  } catch (e) {
    debugPrint('⚠️ Supabase initialization failed: $e');
    // Continue anyway for preview
  }

  // Initialize LocalizationService
  await LocalizationService.instance.initialize();

  // Note: TEST MODE is controlled by EnvConfig.testMode
  // Make sure .env.local has TEST_MODE=true
  debugPrint('🧪 TEST MODE: ${EnvConfig.testMode}');

  runApp(const PaywallPreviewAppV2());
}

class PaywallPreviewAppV2 extends StatelessWidget {
  const PaywallPreviewAppV2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: LocalizationService.instance),
      ],
      child: MaterialApp(
        title: 'Paywall Preview V2',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'SF Pro Display',
        ),
        home: const PaywallComparisonScreen(),
      ),
    );
  }
}

class PaywallComparisonScreen extends StatefulWidget {
  const PaywallComparisonScreen({Key? key}) : super(key: key);

  @override
  State<PaywallComparisonScreen> createState() => _PaywallComparisonScreenState();
}

class _PaywallComparisonScreenState extends State<PaywallComparisonScreen> {
  String _currentLanguage = 'fr';

  final List<PaywallContext> _availableContexts = [
    PaywallContext.scanner,
    PaywallContext.barcodeScanner,
    PaywallContext.chatInput,
    PaywallContext.workoutGenerator,
    PaywallContext.nutritionAnalysis,
    PaywallContext.exerciseAnalysis,
    PaywallContext.genericUpgrade,
  ];

  @override
  void initState() {
    super.initState();
    // Set system UI style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.compare,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paywall Preview',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0B132B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '7 contextes finaux',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Language toggle
                  Row(
                    children: [
                      const Text(
                        'Language:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildLanguageChip('FR', 'fr'),
                      const SizedBox(width: 8),
                      _buildLanguageChip('EN', 'en'),
                      const SizedBox(width: 8),
                      _buildLanguageChip('DE', 'de'),
                    ],
                  ),
                ],
              ),
            ),

            // Content - Liste simple des 7 paywalls
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _availableContexts.length,
                itemBuilder: (context, index) {
                  final paywallContext = _availableContexts[index];
                  return _buildPaywallCard(paywallContext, index + 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get paywall context name with translations
  String _getContextName(PaywallContext context) {
    final isFrench = _currentLanguage == 'fr';
    final isGerman = _currentLanguage == 'de';

    switch (context) {
      case PaywallContext.scanner:
        return isFrench ? '📸 Scanner automatique' : isGerman ? '📸 Automatischer Scanner' : '📸 AI Scanner';
      case PaywallContext.barcodeScanner:
        return isFrench ? '📱 Scanner codes-barres' : isGerman ? '📱 Barcode-Scanner' : '📱 Barcode Scanner';
      case PaywallContext.chatInput:
        return isFrench ? '💬 Chat Coach Ryze' : isGerman ? '💬 Chat mit KI-Coach' : '💬 Chat with Coach Ryze';
      case PaywallContext.workoutGenerator:
        return isFrench ? '🤖 Générateur workouts' : isGerman ? '🤖 Workout-Generator' : '🤖 Workout Generator';
      case PaywallContext.nutritionAnalysis:
        return isFrench ? '📊 Bilan nutritionnel' : isGerman ? '📊 Ernährungsanalyse' : '📊 Nutrition Analysis';
      case PaywallContext.exerciseAnalysis:
        return isFrench ? '💪 Analyse exercices' : isGerman ? '💪 Übungsanalyse' : '💪 Exercise Analysis';
      case PaywallContext.genericUpgrade:
        return isFrench ? '💎 Upgrade générique' : isGerman ? '💎 Allgemeines Upgrade' : '💎 Generic Upgrade';
    }
  }

  // Build single paywall card
  Widget _buildPaywallCard(PaywallContext paywallContext, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => PaywallScreen(
                context: paywallContext,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Context name
                Expanded(
                  child: Text(
                    _getContextName(paywallContext),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),

                // Arrow icon
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String label, String code) {
    final isSelected = _currentLanguage == code;
    return GestureDetector(
      onTap: () {
        setState(() => _currentLanguage = code);
        Provider.of<LocalizationService>(context, listen: false)
            .setLanguage(code);
        HapticService.instance.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B132B) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

}