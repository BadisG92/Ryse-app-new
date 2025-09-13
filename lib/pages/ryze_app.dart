import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  
  // Option de debug pour forcer l'affichage de l'onboarding
  static const bool _forceOnboarding = false; // Changez à true pour forcer l'onboarding

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // DÉLAYER pour éviter freeze pendant build
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      try {
        // CORRECTION: Ajouter timeout pour éviter blocage
        final response = await supabase
            .from('users')
            .select('is_onboarded')
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 5));
        
        final isOnboarded = response['is_onboarded'] ?? false;
        
        // Synchroniser avec SharedPreferences pour la compatibilité
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_onboarded', isOnboarded);
        
        if (mounted) {
          setState(() {
            // Forcer l'onboarding si _forceOnboarding est true
            _isOnboarded = _forceOnboarding ? false : isOnboarded;
            _isLoading = false;
          });
        }
        
        print('✅ Statut onboarding: $isOnboarded');
      } catch (e) {
        print('❌ Erreur lors de la vérification onboarding: $e');
        
        // Fallback vers SharedPreferences en cas d'erreur
        final prefs = await SharedPreferences.getInstance();
        final isOnboarded = prefs.getBool('is_onboarded') ?? false;
        
        if (mounted) {
          setState(() {
            // Forcer l'onboarding si _forceOnboarding est true
            _isOnboarded = _forceOnboarding ? false : isOnboarded;
            _isLoading = false;
          });
        }
      }
    } else {
      // Pas d'utilisateur connecté
      setState(() {
        _isOnboarded = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    // La sauvegarde en base est déjà gérée dans onboarding_gamified_hybrid.dart
    // On met juste à jour l'état local
    setState(() {
      _isOnboarded = true;
    });
  }

  /// Méthode utilitaire pour réinitialiser l'onboarding
  /// Utile pour le développement et les tests
  Future<void> resetOnboarding() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      try {
        // Réinitialiser dans Supabase
        await supabase.from('users').update({
          'is_onboarded': false,
        }).eq('id', user.id);
        
        // Réinitialiser dans SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_onboarded', false);
        
        // Mettre à jour l'état local
        setState(() {
          _isOnboarded = false;
        });
        
        print('✅ Onboarding réinitialisé avec succès');
      } catch (e) {
        print('❌ Erreur lors de la réinitialisation: $e');
      }
    }
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
