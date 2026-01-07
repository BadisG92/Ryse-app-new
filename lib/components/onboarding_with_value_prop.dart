import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/video_welcome_screen.dart';
import 'onboarding_gamified_hybrid.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding_chat_screen.dart';
import '../screens/weekly_contract_screen.dart';

/// Widget qui encapsule Video Welcome + Onboarding
/// Flow:
/// - Non connecté: Video Welcome → Login/Signup
/// - Connecté mais pas onboardé: Video Welcome → Onboarding IA → Contract → Onboarding classique
class OnboardingWithValueProp extends StatefulWidget {
  final VoidCallback onComplete;
  final bool showValuePropFirst;
  final bool isUserLoggedIn;
  final bool skipValueProp; // Pour aller directement à l'onboarding (skip vidéo)

  const OnboardingWithValueProp({
    Key? key,
    required this.onComplete,
    this.showValuePropFirst = false,
    this.isUserLoggedIn = false,
    this.skipValueProp = false,
  }) : super(key: key);

  @override
  State<OnboardingWithValueProp> createState() => _OnboardingWithValuePropState();
}

class _OnboardingWithValuePropState extends State<OnboardingWithValueProp> {
  // 0: Video Welcome, 1: Onboarding IA, 2: Contract/Pacte, 3: Onboarding classique
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Toujours commencer par la vidéo (sauf si skipValueProp pour des cas spéciaux)
    _currentStep = widget.skipValueProp ? 1 : 0;
  }

  /// Callback quand l'utilisateur clique sur le bouton "Rejoins-nous" de la vidéo
  void _onVideoWelcomeComplete() async {
    // Marquer que l'utilisateur a vu l'intro
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true);

    if (!mounted) return;

    // Si l'utilisateur est connecté → Onboarding IA
    if (widget.isUserLoggedIn) {
      setState(() {
        _currentStep = 1; // Passer à l'onboarding IA
      });
    } else {
      // Si non connecté → Login/Signup
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  /// Callback quand l'onboarding IA est terminé → passer au contrat
  void _onOnboardingIAComplete() {
    if (mounted) {
      setState(() {
        _currentStep = 2; // Passer au contrat/pacte
      });
    }
  }

  /// Callback quand le contrat est signé → passer à l'onboarding classique
  void _onContractComplete() {
    if (mounted) {
      setState(() {
        _currentStep = 3; // Passer à l'onboarding classique
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        // Vidéo de bienvenue
        return VideoWelcomeScreen(
          onContinue: _onVideoWelcomeComplete,
        );
      case 1:
        // Onboarding IA (chat avec Coach Ryze)
        return OnboardingChatScreen(
          onComplete: _onOnboardingIAComplete,
        );
      case 2:
        // Contrat/Pacte avec Coach Ryze
        return WeeklyContractScreen(
          onComplete: _onContractComplete,
          onSkip: _onContractComplete, // Skip va aussi à l'étape suivante
        );
      case 3:
      default:
        // Onboarding classique (questions)
        return OnboardingGamifiedHybrid(
          onComplete: widget.onComplete,
        );
    }
  }
}
