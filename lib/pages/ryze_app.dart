import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/onboarding_with_value_prop.dart';
import '../components/main_app.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/paywall_screen.dart';
import '../services/paywall_service.dart';

/// RyzeApp - Implémentation du flow AAA (style MyFitnessPal, Headspace, etc.)
///
/// Flow intelligent :
/// - Utilisateur connecté + onboardé → App directement (pas de slides)
/// - Utilisateur connecté + non onboardé → Onboarding
/// - Utilisateur non connecté + 1ère fois → Slides value prop → Login
/// - Utilisateur non connecté + déjà vu slides → Login directement
class RyzeApp extends StatefulWidget {
  const RyzeApp({super.key});

  @override
  State<RyzeApp> createState() => _RyzeAppState();
}

class _RyzeAppState extends State<RyzeApp> {
  bool _isLoading = true;
  Widget? _targetScreen;

  // Flag de debug pour forcer certains écrans (utile en développement)
  static const bool _forceOnboarding = false; // ✅ PRODUCTION: Onboarding normal
  static const bool _forceValueProp = false;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  /// Détermine quelle est la bonne page à afficher selon l'état de l'utilisateur
  /// C'est la logique centrale du flow AAA
  Future<void> _determineInitialRoute() async {
    // Délayer pour éviter freeze pendant build
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final prefs = await SharedPreferences.getInstance();

      Widget targetScreen;

      // 🔐 CAS 1 : UTILISATEUR CONNECTÉ
      if (session != null && !_forceValueProp) {
        debugPrint('✅ Session détectée pour: ${session.user.email}');

        // Vérifier si l'utilisateur a un nom complet
        final authService = Provider.of<AuthService>(context, listen: false);
        final hasCompleteName = authService.hasCompleteName;

        // Si pas de nom complet → écran de complétion de profil
        if (!hasCompleteName) {
          debugPrint('⚠️ Nom manquant → CompleteProfileScreen');
          targetScreen = CompleteProfileScreen(
            onComplete: () async {
              // Après avoir complété le nom, naviguer vers l'écran approprié
              if (!mounted) return;

              try {
                final response = await supabase
                    .from('users')
                    .select('is_onboarded')
                    .eq('id', session.user.id)
                    .single()
                    .timeout(const Duration(seconds: 5));

                final isOnboarded = response['is_onboarded'] ?? false;

                if (mounted) {
                  if (isOnboarded) {
                    debugPrint('🎯 Profil complété → App directement');
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const MainApp()),
                    );
                  } else {
                    debugPrint('📋 Profil complété → Onboarding (sans slides)');
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => OnboardingWithValueProp(
                          onComplete: _completeOnboarding,
                          isUserLoggedIn: true,
                          skipValueProp: true, // Skip les slides, direct onboarding
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('❌ Erreur navigation post-profile: $e');
                // En cas d'erreur, aller vers l'onboarding par défaut
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => OnboardingWithValueProp(
                        onComplete: _completeOnboarding,
                        isUserLoggedIn: true,
                        skipValueProp: true, // Skip les slides, direct onboarding
                      ),
                    ),
                  );
                }
              }
            },
          );
        } else {
          try {
            final response = await supabase
                .from('users')
                .select('is_onboarded')
                .eq('id', session.user.id)
                .single()
                .timeout(const Duration(seconds: 5));

            final isOnboarded = _forceOnboarding ? false : (response['is_onboarded'] ?? false);

            // Synchroniser avec SharedPreferences
            await prefs.setBool('is_onboarded', isOnboarded);

            if (isOnboarded) {
              // ✨ Utilisateur complet → APP DIRECTEMENT (jamais de slides)
              debugPrint('🎯 Utilisateur onboardé → App directement');
              targetScreen = const MainApp();
            } else {
              // ⚠️ Compte existe mais onboarding incomplet
              debugPrint('📋 Onboarding incomplet → Onboarding direct (sans slides)');
              targetScreen = OnboardingWithValueProp(
                onComplete: _completeOnboarding,
                isUserLoggedIn: true,
                skipValueProp: true, // IMPORTANT: Jamais de slides après login
              );
            }
          } catch (e) {
            debugPrint('❌ Erreur vérification onboarding: $e');

            // Fallback vers SharedPreferences
            final isOnboarded = prefs.getBool('is_onboarded') ?? false;

            if (isOnboarded && !_forceOnboarding) {
              targetScreen = const MainApp();
            } else {
              targetScreen = OnboardingWithValueProp(
                onComplete: _completeOnboarding,
                isUserLoggedIn: true,
                skipValueProp: true, // IMPORTANT: Jamais de slides après login
              );
            }
          }
        }
      }
      // ❌ CAS 2 : PAS DE SESSION (utilisateur non connecté)
      else {
        debugPrint('❌ Pas de session active');

        // Vérifier si c'est la PREMIÈRE ouverture de l'app
        final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;

        if (hasSeenIntro && !_forceValueProp) {
          // 🔄 Déjà vu l'intro → Login DIRECTEMENT (pas de slides)
          debugPrint('🔄 Utilisateur revient → Login direct (sans slides)');
          targetScreen = const LoginScreen();
        } else {
          // 🎬 PREMIÈRE FOIS → Welcome + Slides value proposition → Login
          debugPrint('🎬 Première ouverture → Welcome + Value proposition slides → Login');
          targetScreen = OnboardingWithValueProp(
            onComplete: _completeOnboarding,
            showValuePropFirst: false, // Toujours montrer le Welcome screen
            isUserLoggedIn: false, // Pas connecté → aller vers Login après slides
          );
        }
      }

      if (mounted) {
        setState(() {
          _targetScreen = targetScreen;
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('❌ Erreur lors de la détermination du routing: $e');

      // En cas d'erreur, aller vers le login par sécurité
      if (mounted) {
        setState(() {
          _targetScreen = const LoginScreen();
          _isLoading = false;
        });
      }
    }
  }

  /// Appelée quand l'onboarding est terminé
  /// Affiche le paywall, puis redirige vers MainApp quelle que soit l'issue
  Future<void> _completeOnboarding() async {
    debugPrint('🎯 _completeOnboarding appelé');
    debugPrint('🎯 Widget mounted: $mounted');

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    // Marquer que l'utilisateur a vu l'intro (local)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true);
    await prefs.setBool('is_onboarded', true);

    // IMPORTANT: Mettre à jour Supabase pour persister l'état
    if (user != null) {
      try {
        await supabase.from('users').update({
          'is_onboarded': true,
        }).eq('id', user.id);
        debugPrint('✅ Onboarding marqué comme terminé dans Supabase');
      } catch (e) {
        debugPrint('❌ Erreur mise à jour onboarding dans Supabase: $e');
        // Continue quand même, l'utilisateur a les SharedPreferences
      }
    }

    debugPrint('✅ Onboarding terminé');

    // Navigation directe sans PostFrameCallback pour éviter les race conditions
    // Le context est passé depuis le widget appelant qui est forcément mounted
    debugPrint('🚀 Navigation vers PaywallScreen...');
    try {
      // Utiliser un délai minimal pour laisser le temps au frame actuel de se terminer
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) {
        debugPrint('⚠️ Widget non mounted, navigation annulée');
        return;
      }

      // 🎯 Afficher le Paywall après l'onboarding
      // Quelle que soit l'issue (abonnement, plus tard, restauration), on va vers MainApp
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (ctx) => PaywallScreen(
            context: PaywallContext.genericUpgrade,
            customTitle: 'Débloquez Coach Ryze Premium',
            customMessage: 'Profitez de 7 jours d\'essai gratuit',
            onDismiss: () {
              // Appelé quand l'utilisateur ferme le paywall (peu importe la raison)
              debugPrint('🏠 Paywall fermé → Navigation vers MainApp');
              Navigator.of(ctx, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainApp()),
                (route) => false,
              );
            },
          ),
        ),
        (route) => false, // Supprimer toutes les routes précédentes
      );
      debugPrint('✅ Navigation réussie vers Paywall');
    } catch (e) {
      debugPrint('❌ Erreur navigation: $e');
      // En cas d'erreur, aller directement vers MainApp
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainApp()),
          (route) => false,
        );
      }
    }
  }

  /// Méthode utilitaire pour réinitialiser l'onboarding (développement)
  Future<void> resetOnboarding() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        await supabase.from('users').update({
          'is_onboarded': false,
        }).eq('id', user.id);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_onboarded', false);
        await prefs.setBool('has_seen_intro', false);

        debugPrint('✅ Onboarding réinitialisé');

        // Redémarrer le routing
        _determineInitialRoute();
      } catch (e) {
        debugPrint('❌ Erreur réinitialisation: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écran de chargement pendant la détermination du routing
    // IMPORTANT: On utilise un Container transparent pour que le SplashScreen
    // de main.dart continue d'être visible pendant le chargement
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC), // Même couleur que le splash
        body: SizedBox.shrink(), // Widget vide pour éviter le flash
      );
    }

    // Afficher l'écran cible déterminé
    return _targetScreen ?? const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SizedBox.shrink(),
    );
  }
}
