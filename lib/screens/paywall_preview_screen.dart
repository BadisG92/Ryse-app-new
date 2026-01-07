import 'package:flutter/material.dart';
import '../services/paywall_service.dart';
import '../services/localization_service.dart';
import 'paywall_preview_standalone.dart';

/// Écran de prévisualisation des paywalls
/// Pour tester tous les designs sans passer par l'app
class PaywallPreviewScreen extends StatelessWidget {
  const PaywallPreviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final isGerman = LocalizationService.instance.currentLanguageCode == 'de';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isFrench ? '🎨 Prévisualisation Paywalls' : isGerman ? '🎨 Paywall-Vorschau' : '🎨 Paywall Preview'),
        backgroundColor: const Color(0xFF0B132B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFrench
                        ? 'Clique sur une carte pour voir le paywall'
                        : isGerman
                            ? 'Tippe auf eine Karte, um die Paywall zu sehen'
                            : 'Tap a card to see the paywall',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════
          // NUTRITION PAYWALLS
          // ═══════════════════════════════════════════════════════
          _buildSectionTitle(
            isFrench ? '🍎 Nutrition' : isGerman ? '🍎 Ernährung' : '🍎 Nutrition',
          ),

          _buildPaywallCard(
            context: context,
            paywallContext: PaywallContext.scanner,
            title: isFrench ? '📸 Scanner Photo' : isGerman ? '📸 Foto-Scanner' : '📸 Photo Scanner',
            description: isFrench
                ? 'Titre: "Arrête de Deviner tes Calories"\n6 bénéfices + Avatar nutrition'
                : isGerman
                    ? 'Titel: "Hör auf, deine Kalorien zu raten"\n6 Vorteile + Ernährungs-Avatar'
                    : 'Title: "Stop Guessing Your Calories"\n6 benefits + Nutrition avatar',
            color: const Color(0xFF10B981),
          ),

          _buildPaywallCard(
            context: context,
            paywallContext: PaywallContext.barcodeScanner,
            title: isFrench ? '📱 Scanner Barcode' : isGerman ? '📱 Barcode-Scanner' : '📱 Barcode Scanner',
            description: isFrench
                ? 'Titre: "Fais tes Courses sans Stress"\n6 bénéfices + Avatar nutrition'
                : isGerman
                    ? 'Titel: "Stressfrei einkaufen"\n6 Vorteile + Ernährungs-Avatar'
                    : 'Title: "Shop Stress-Free"\n6 benefits + Nutrition avatar',
            color: const Color(0xFF3B82F6),
          ),

          _buildPaywallCard(
            context: context,
            paywallContext: PaywallContext.chatInput,
            title: isFrench ? '💬 Chat Texte/Vocal' : isGerman ? '💬 Text-/Sprach-Chat' : '💬 Text/Voice Chat',
            description: isFrench
                ? 'Titre: "Mange, Parle, C\'est Compté"\n6 bénéfices + Avatar nutrition'
                : isGerman
                    ? 'Titel: "Essen, Sprechen, Erfasst"\n6 Vorteile + Ernährungs-Avatar'
                    : 'Title: "Eat, Talk, It\'s Tracked"\n6 benefits + Nutrition avatar',
            color: const Color(0xFF8B5CF6),
          ),

          _buildPaywallCard(
            context: context,
            paywallContext: PaywallContext.nutritionAnalysis,
            title: isFrench ? '📊 Bilan Quotidien' : isGerman ? '📊 Tagesbericht' : '📊 Daily Report',
            description: isFrench
                ? 'Titre: "Comprends VRAIMENT ta Nutrition"\n6 bénéfices + Avatar nutrition'
                : isGerman
                    ? 'Titel: "Verstehe WIRKLICH deine Ernährung"\n6 Vorteile + Ernährungs-Avatar'
                    : 'Title: "TRULY Understand Your Nutrition"\n6 benefits + Nutrition avatar',
            color: const Color(0xFFF59E0B),
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════
          // SPORT PAYWALLS
          // ═══════════════════════════════════════════════════════
          _buildSectionTitle(
            isFrench ? '💪 Sport' : isGerman ? '💪 Sport' : '💪 Sport',
          ),

          _buildPaywallCard(
            context: context,
            paywallContext: PaywallContext.workoutGenerator,
            title: isFrench ? '🤖 Générateur Workout' : isGerman ? '🤖 Workout-Generator' : '🤖 Workout Generator',
            description: isFrench
                ? 'Titre: "Entraîne-toi comme un Pro"\n6 bénéfices + Avatar workout'
                : isGerman
                    ? 'Titel: "Trainiere wie ein Profi"\n6 Vorteile + Workout-Avatar'
                    : 'Title: "Train Like a Pro"\n6 benefits + Workout avatar',
            color: const Color(0xFFEF4444),
          ),

          _buildPaywallCard(
            context: context,
            paywallContext: PaywallContext.exerciseAnalysis,
            title: isFrench ? '📈 Analyse Progression' : isGerman ? '📈 Fortschrittsanalyse' : '📈 Progress Analysis',
            description: isFrench
                ? 'Titre: "Progresse sur Chaque Exercice"\n6 bénéfices + Avatar workout'
                : isGerman
                    ? 'Titel: "Fortschritt bei jeder Übung"\n6 Vorteile + Workout-Avatar'
                    : 'Title: "Progress on Every Exercise"\n6 benefits + Workout avatar',
            color: const Color(0xFFEC4899),
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════
          // GENERIC PAYWALL
          // ═══════════════════════════════════════════════════════
          _buildSectionTitle(
            isFrench ? '💎 Générique' : isGerman ? '💎 Generisch' : '💎 Generic',
          ),

          _buildPaywallCard(
            context: context,
            paywallContext: PaywallContext.genericUpgrade,
            title: isFrench ? '🚀 Paywall Générique' : isGerman ? '🚀 Generische Paywall' : '🚀 Generic Paywall',
            description: isFrench
                ? 'Titre: "Transforme ton Corps"\n6 bénéfices génériques + Avatar chef'
                : isGerman
                    ? 'Titel: "Transformiere deinen Körper"\n6 generische Vorteile + Chef-Avatar'
                    : 'Title: "Transform Your Body"\n6 generic benefits + Chef avatar',
            color: const Color(0xFF64748B),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0B132B),
        ),
      ),
    );
  }

  Widget _buildPaywallCard({
    required BuildContext context,
    required PaywallContext paywallContext,
    required String title,
    required String description,
    required Color color,
  }) {
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
              builder: (context) => PaywallPreviewStandalone(
                paywallContext: paywallContext,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icône colorée
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.payment,
                      color: color,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Flèche
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFCBD5E1),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
