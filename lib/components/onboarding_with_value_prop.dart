import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/video_welcome_screen.dart';
import 'ui/onboarding_video_screen.dart';
import 'onboarding_gamified_hybrid.dart';
import 'onboarding_planner_demo.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding_chat_screen.dart';
import '../screens/weekly_contract_screen.dart';

/// Widget qui encapsule Video Welcome + Onboarding
/// Flow:
/// - Non connecté: Video Welcome → Login/Signup
/// - Connecté mais pas onboardé: Video Welcome → Video Onboarding → Onboarding IA → Contract → Onboarding classique → Planner Demo
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
  // 0: Video Welcome, 1: Video Onboarding, 2: Onboarding IA, 3: Contract/Pacte, 4: Onboarding classique, 5: Planner Demo
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Toujours commencer par la vidéo welcome (sauf si skipValueProp pour des cas spéciaux)
    // Si skipValueProp, on saute directement à la vidéo onboarding (étape 1)
    _currentStep = widget.skipValueProp ? 1 : 0;

    // Precache the chat background image for smooth transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/onboarding_chat_background.png'),
        context,
      );
    });
  }

  /// Callback quand l'utilisateur clique sur le bouton "Rejoins-nous" de la vidéo
  void _onVideoWelcomeComplete() async {
    // Marquer que l'utilisateur a vu l'intro
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true);

    if (!mounted) return;

    // Si l'utilisateur est connecté → Video Onboarding
    if (widget.isUserLoggedIn) {
      setState(() {
        _currentStep = 1; // Passer à la vidéo onboarding
      });
    } else {
      // Si non connecté → Login/Signup
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  /// Callback quand la vidéo onboarding est terminée → passer au chat IA
  /// Chat screen handles its own reveal animation (middle to edges)
  void _onOnboardingVideoComplete() {
    if (mounted) {
      setState(() {
        _currentStep = 2; // Go directly to chat - it has its own reveal animation
      });
    }
  }

  /// Callback quand l'onboarding IA est terminé → passer au contrat
  void _onOnboardingIAComplete() {
    if (mounted) {
      setState(() {
        _currentStep = 3; // Passer au contrat/pacte
      });
    }
  }

  /// Callback quand le contrat est signé → passer à l'onboarding classique
  void _onContractComplete() {
    if (mounted) {
      setState(() {
        _currentStep = 4; // Passer à l'onboarding classique
      });
    }
  }

  /// Callback quand le questionnaire est terminé → passer à la démo planner
  void _onQuestionnaireComplete() {
    if (mounted) {
      setState(() {
        _currentStep = 5; // Passer à la démo planner
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
        // Vidéo onboarding (explique l'app avant le chat IA)
        return OnboardingVideoScreen(
          onContinue: _onOnboardingVideoComplete,
        );
      case 2:
        // Onboarding IA (chat avec Coach Ryze) - has its own reveal animation
        return OnboardingChatScreen(
          onComplete: _onOnboardingIAComplete,
        );
      case 3:
        // Contrat/Pacte avec Coach Ryze
        return WeeklyContractScreen(
          onComplete: _onContractComplete,
          onSkip: _onContractComplete, // Skip va aussi à l'étape suivante
        );
      case 4:
        // Onboarding classique (questions) → transitions vers planner demo
        return OnboardingGamifiedHybrid(
          onComplete: _onQuestionnaireComplete,
        );
      case 5:
      default:
        // Démo planner (meals → sport → hard paywall)
        return OnboardingPlannerDemo(
          onComplete: widget.onComplete,
        );
    }
  }
}
