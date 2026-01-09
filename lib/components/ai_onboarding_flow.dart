import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/onboarding_chat_screen.dart';
import '../screens/weekly_contract_screen.dart';

/// Flow simplifié pour les utilisateurs existants qui n'ont pas fait l'onboarding IA
/// Étapes: Chat IA → Contrat → MainApp
/// Pas de vidéo welcome ni d'onboarding classique (déjà fait)
class AIOnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const AIOnboardingFlow({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<AIOnboardingFlow> createState() => _AIOnboardingFlowState();
}

class _AIOnboardingFlowState extends State<AIOnboardingFlow> {
  // 0: Chat IA, 1: Contrat
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Precache the chat background image for smooth transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/onboarding_chat_background.png'),
        context,
      );
    });
  }

  /// Callback quand l'onboarding IA est terminé → passer au contrat
  void _onOnboardingIAComplete() {
    if (mounted) {
      setState(() {
        _currentStep = 1; // Passer au contrat
      });
    }
  }

  /// Callback quand le contrat est signé → marquer comme complété et aller à MainApp
  Future<void> _onContractComplete() async {
    // Marquer ai_onboarding_completed = true dans la base
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('users')
            .update({'ai_onboarding_completed': true})
            .eq('id', user.id);
      } catch (e) {
        debugPrint('❌ Error updating ai_onboarding_completed: $e');
      }
    }

    // Appeler le callback de complétion
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        // Chat IA avec Coach Ryze
        return OnboardingChatScreen(
          onComplete: _onOnboardingIAComplete,
        );
      case 1:
      default:
        // Contrat/Pacte avec Coach Ryze
        return WeeklyContractScreen(
          onComplete: _onContractComplete,
          onSkip: _onContractComplete, // Skip marque aussi comme complété
        );
    }
  }
}
