import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../components/onboarding_gamified_hybrid.dart';
import '../components/main_app.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';

class RyzeApp extends StatefulWidget {
  const RyzeApp({super.key});

  @override
  State<RyzeApp> createState() => _RyzeAppState();
}

class _RyzeAppState extends State<RyzeApp> {
  bool _isOnboarded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // TEMPORAIRE : Forcer la réinitialisation de l'onboarding pour les tests
    await prefs.setBool('is_onboarded', false);
    
    final isOnboarded = prefs.getBool('is_onboarded') ?? false;
    
    setState(() {
      _isOnboarded = isOnboarded;
      _isLoading = false;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    
    setState(() {
      _isOnboarded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0B132B),
          ),
        ),
      );
    }

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // If user is not authenticated, show login screen
        if (!authService.isAuthenticated) {
          return const LoginScreen();
        }

        // If user is authenticated but hasn't completed onboarding
        if (!_isOnboarded) {
          return OnboardingGamifiedHybrid(onComplete: _completeOnboarding);
        }

        // User is authenticated and onboarded, show main app
        return const MainApp();
      },
    );
  }
} 
