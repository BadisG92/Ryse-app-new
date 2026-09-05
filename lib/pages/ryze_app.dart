import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/main_app.dart';
import '../components/ui/video_welcome_screen.dart';
import '../onboarding/onboarding_flow.dart';
import '../onboarding/onboarding_state.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../services/auth_service.dart';

/// RyzeApp - routing at launch.
///
/// - Not logged in, first time → welcome video → login
/// - Not logged in, seen the intro → login
/// - Logged in, no name → complete profile
/// - Logged in, not onboarded → onboarding v2 (resumes where the user left it)
/// - Logged in, onboarded but the v2 profile was saved without a purchase → onboarding resumes on the paywall
/// - Logged in, onboarded before the coach part existed → coach-only flow (tone, day, pact)
/// - Logged in, everything done → app
class RyzeApp extends StatefulWidget {
  const RyzeApp({super.key});

  @override
  State<RyzeApp> createState() => _RyzeAppState();
}

class _RyzeAppState extends State<RyzeApp> {
  bool _isLoading = true;
  Widget? _targetScreen;

  // Debug flags (development only)
  static const bool _forceOnboarding = true; // TEMP: emulator test, revert before commit
  static const bool _forceValueProp = false;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _determineInitialRouteInternal().timeout(
        const Duration(seconds: 10),
        onTimeout: () => _show(const LoginScreen()),
      );
    } catch (e) {
      debugPrint('❌ Routing error: $e');
      _show(const LoginScreen());
    }
  }

  void _show(Widget screen) {
    if (!mounted) return;
    setState(() {
      _targetScreen = screen;
      _isLoading = false;
    });
  }

  Future<void> _determineInitialRouteInternal() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // 🔐 Logged in
    if (session != null && !_forceValueProp) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) {
        await authService.initialize();
      }

      if (!authService.hasCompleteName) {
        debugPrint('⚠️ Nom manquant → CompleteProfileScreen');
        _show(CompleteProfileScreen(onComplete: _determineInitialRoute));
        return;
      }

      final firstName = authService.currentUser?.firstName;
      final resume = await OnbProgressStore.load();
      final profileSavedLocally = await OnbProgressStore.isProfileSaved();

      try {
        final response =
            await supabase.from('users').select('is_onboarded, ai_onboarding_completed').eq('id', session.user.id).single().timeout(const Duration(seconds: 5));

        final isOnboarded = _forceOnboarding ? false : (response['is_onboarded'] as bool? ?? false);
        final aiCompleted = response['ai_onboarding_completed'] as bool? ?? false;
        await prefs.setBool('is_onboarded', isOnboarded);

        if (!isOnboarded) {
          debugPrint('📋 Non onboardé → OnboardingFlow');
          _show(OnboardingFlow(firstName: firstName, resume: resume, onComplete: _goToApp));
        } else if (!aiCompleted) {
          if (profileSavedLocally || resume != null) {
            // v2 user who saved a profile but never reached the end (hard paywall)
            debugPrint('💳 Profil v2 sauvegardé sans achat → reprise de l’onboarding');
            final at = resume ?? (step: 'offer', answers: OnbAnswers());
            _show(OnboardingFlow(firstName: firstName, resume: at, onComplete: _goToApp));
          } else {
            debugPrint('🤖 Utilisateur existant sans partie coach → flow coach');
            _show(OnboardingFlow(mode: OnbMode.coachOnly, firstName: firstName, onComplete: _goToApp));
          }
        } else {
          debugPrint('🎯 Onboardé → App');
          _show(const MainApp());
        }
      } catch (e) {
        debugPrint('❌ Erreur vérification onboarding: $e');
        final isOnboarded = prefs.getBool('is_onboarded') ?? false;
        if (isOnboarded && !_forceOnboarding && !profileSavedLocally) {
          _show(const MainApp());
        } else {
          _show(OnboardingFlow(firstName: firstName, resume: resume, onComplete: _goToApp));
        }
      }
      return;
    }

    // ❌ Not logged in
    final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;
    if (hasSeenIntro && !_forceValueProp) {
      debugPrint('🔄 Intro déjà vue → Login');
      _show(const LoginScreen());
    } else {
      debugPrint('🎬 Première ouverture → vidéo welcome → Login');
      _show(VideoWelcomeScreen(
        onContinue: () async {
          final p = await SharedPreferences.getInstance();
          await p.setBool('has_seen_intro', true);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
        },
      ));
    }
  }

  /// The onboarding flow has persisted everything; just enter the app.
  Future<void> _goToApp() async {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainApp()),
      (route) => false,
    );
  }

  /// Development helper: replay the onboarding.
  Future<void> resetOnboarding() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        await supabase.from('users').update({'is_onboarded': false, 'ai_onboarding_completed': false}).eq('id', user.id);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_onboarded', false);
        await prefs.setBool('has_seen_intro', false);
        await OnbProgressStore.clear();
        _determineInitialRoute();
      } catch (e) {
        debugPrint('❌ Erreur réinitialisation: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0B132B))),
      );
    }
    return _targetScreen ?? const LoginScreen();
  }
}
