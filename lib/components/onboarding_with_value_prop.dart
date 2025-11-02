import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/value_proposition_slides.dart';
import 'onboarding_gamified_hybrid.dart';
import '../services/localization_service.dart';
import '../screens/auth/login_screen.dart';

/// Widget qui encapsule Value Proposition Slides (4 slides incluant welcome) + Onboarding
/// Flow: 4 Slides de Value Prop (Welcome + 3 autres) → Onboarding/Login
class OnboardingWithValueProp extends StatefulWidget {
  final VoidCallback onComplete;
  final bool showValuePropFirst;
  final bool isUserLoggedIn;
  final bool skipValueProp; // Nouveau: pour aller directement à l'onboarding

  const OnboardingWithValueProp({
    Key? key,
    required this.onComplete,
    this.showValuePropFirst = false,
    this.isUserLoggedIn = false,
    this.skipValueProp = false, // Par défaut, afficher les slides
  }) : super(key: key);

  @override
  State<OnboardingWithValueProp> createState() => _OnboardingWithValuePropState();
}

class _OnboardingWithValuePropState extends State<OnboardingWithValueProp> {
  int _currentStep = 1; // 1: Value Prop Slides (4 slides), 2: Onboarding

  @override
  void initState() {
    super.initState();
    // Si skipValueProp est true, aller directement à l'onboarding
    _currentStep = widget.skipValueProp ? 2 : 1;
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
    if (mounted) {
      setState(() {
        _currentStep = 2; // Passer à l'onboarding
      });
    }
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
    if (mounted) {
      setState(() {
        _currentStep = 2; // Passer à l'onboarding
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Provider.of<LocalizationService>(context).currentLanguageCode;

    return Stack(
      children: [
        // Value Prop Slides (4 slides incluant welcome) - visible au step 1
        Offstage(
          offstage: _currentStep != 1,
          child: ValuePropositionSlides(
            languageCode: languageCode,
            onComplete: _onValuePropComplete,
            onSkip: _onSkipValueProp,
            onBack: null, // Pas de retour possible depuis la première slide
          ),
        ),

        // Onboarding - visible au step 2
        Offstage(
          offstage: _currentStep != 2,
          child: OnboardingGamifiedHybrid(
            onComplete: widget.onComplete,
          ),
        ),
      ],
    );
  }
}
