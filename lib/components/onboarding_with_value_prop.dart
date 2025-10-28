import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/welcome_screen.dart';
import 'ui/value_proposition_slides.dart';
import 'onboarding_gamified_hybrid.dart';
import '../services/localization_service.dart';
import '../screens/auth/login_screen.dart';

/// Widget qui encapsule Welcome Screen + Value Proposition Slides + Onboarding
/// Flow: Welcome → 3 Slides de Value Prop → Onboarding
/// Ou: Value Prop → Login/Onboarding (si showValuePropFirst = true)
class OnboardingWithValueProp extends StatefulWidget {
  final VoidCallback onComplete;
  final bool showValuePropFirst;
  final bool isUserLoggedIn;

  const OnboardingWithValueProp({
    Key? key,
    required this.onComplete,
    this.showValuePropFirst = false,
    this.isUserLoggedIn = false,
  }) : super(key: key);

  @override
  State<OnboardingWithValueProp> createState() => _OnboardingWithValuePropState();
}

class _OnboardingWithValuePropState extends State<OnboardingWithValueProp>
    with TickerProviderStateMixin {
  late int _currentStep; // 0: Welcome, 1: Value Prop Slides, 2: Onboarding
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Si showValuePropFirst = true, sauter le Welcome et commencer directement aux slides
    _currentStep = widget.showValuePropFirst ? 1 : 0;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onWelcomeContinue() {
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentStep = 1;
        });
        _fadeController.forward();
      }
    });
  }

  Future<void> _onValuePropComplete() async {
    // Marquer que l'utilisateur a vu les slides (pour le flow AAA)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true);

    // Si l'utilisateur n'est PAS connecté → aller vers Login
    if (!widget.isUserLoggedIn) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    // Si l'utilisateur EST connecté → continuer vers Onboarding
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentStep = 2;
        });
        _fadeController.forward();
      }
    });
  }

  void _onSkipValueProp() {
    // Si l'utilisateur n'est PAS connecté → aller vers Login
    if (!widget.isUserLoggedIn) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    // Si l'utilisateur EST connecté → continuer vers Onboarding
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentStep = 2;
        });
        _fadeController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Provider.of<LocalizationService>(context).currentLanguageCode;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildCurrentStep(languageCode),
    );
  }

  Widget _buildCurrentStep(String languageCode) {
    // Step 0: Welcome Screen
    if (_currentStep == 0) {
      return WelcomeScreen(
        languageCode: languageCode,
        onContinue: _onWelcomeContinue,
      );
    }

    // Step 1: Value Proposition Slides
    if (_currentStep == 1) {
      return ValuePropositionSlides(
        languageCode: languageCode,
        onComplete: _onValuePropComplete,
        onSkip: _onSkipValueProp,
      );
    }

    // Step 2: Onboarding
    return OnboardingGamifiedHybrid(
      onComplete: widget.onComplete,
    );
  }
}
