import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/supabase_config.dart';
import 'config/env_config.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'services/analytics_service.dart';
import 'services/app_navigator.dart';
import 'components/ui/recipe_models.dart';
import 'pages/ryze_app.dart';
import 'services/offline_workout_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/settings_screen.dart';
import 'screens/pricing_screen.dart';
import 'services/preload_service.dart';
import 'services/fast_cache_service.dart';
import 'core/infrastructure/migration/migration_controller.dart';
import 'core/infrastructure/startup/priority_service_initializer.dart';
import 'services/global_state_manager.dart';
import 'services/navigation_preloader.dart';
import 'services/exercise_ai_analysis_service.dart';
import 'services/coach_ryze_nutrition_service.dart';
import 'services/unified_subscription_service.dart';
import 'services/notification_service.dart';
import 'package:app_links/app_links.dart';
import 'services/widget_deep_link_handler.dart';
import 'services/widget_water_handler.dart';
import 'services/meal_widget_data_provider.dart';
import 'services/haptic_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== FIREBASE ANALYTICS =====
  try {
    await Firebase.initializeApp();
    await AnalyticsService.initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    // L'app continue même si Firebase échoue
  }
  // ==============================

  // NOUVEAU: Initialize deep link handler for iOS widgets
  final navigatorKey = GlobalKey<NavigatorState>();
  WidgetDeepLinkHandler.initialize(navigatorKey);

  // Initialize AppNavigator service for global access to navigator context
  AppNavigator().initialize(navigatorKey);

  // NOUVEAU: Handle deep links for iOS/Android widgets
  final appLinks = AppLinks();

  // Handle initial link (app opened from widget)
  try {
    final initialLink = await appLinks.getInitialLinkString();
    if (initialLink != null) {
      debugPrint('🔗 Initial deep link detected: $initialLink');
      // Le lien sera géré après que l'app soit complètement initialisée
      Future.delayed(const Duration(seconds: 2), () {
        WidgetDeepLinkHandler.handleDeepLink(Uri.parse(initialLink));
      });
    }
  } catch (e) {
    debugPrint('❌ Error getting initial link: $e');
  }

  // Listen for incoming links (widget tapped while app is running)
  appLinks.stringLinkStream.listen((String? link) {
    if (link != null) {
      debugPrint('🔗 Deep link received: $link');
      WidgetDeepLinkHandler.handleDeepLink(Uri.parse(link));
    }
  }, onError: (err) {
    debugPrint('❌ Deep link error: $err');
  });

  // ✅ VALIDATION DE LA CONFIGURATION AU DÉMARRAGE
  try {
    EnvConfig.validateConfiguration();
    EnvConfig.logConfiguration();
  } catch (e) {
    debugPrint('❌ Configuration Error: $e');
    // En production, on pourrait afficher un écran d'erreur
    // Pour l'instant, on continue (mode dégradé)
  }

  // OPTIMISATION: Initialisation par priorités pour performance maximale
  final initializer = PriorityServiceInitializer.instance;

  // Phase 1: Services critiques SEULEMENT (1s max en mode avion, bloquant)
  // CRITICAL: Timeout global pour éviter tout blocage en mode avion
  await initializer.initializeCriticalServices().timeout(
    const Duration(seconds: 1),
    onTimeout: () {
      debugPrint('⚠️ Critical services timeout - app continues in offline mode');
    },
  );

  // NOUVEAU: Initialiser le state manager global
  await GlobalStateManager.instance.initialize().timeout(
    const Duration(milliseconds: 500),
    onTimeout: () {
      debugPrint('⚠️ GlobalStateManager timeout - using defaults');
    },
  );

  // Initialiser le service de retour haptique
  await HapticService.instance.initialize();
  // Mettre les données widget à jour dès que le state global est prêt avec les VRAIES valeurs
  await MealWidgetDataProvider.forceWidgetUpdate();

  // Initialiser les services d'analyse IA avec Gemini
  ExerciseAiAnalysisService.initialize();
  CoachRyzeNutritionService.initialize();

  // Initialiser le service d'abonnement unifié (gère RevenueCat + DB)
  await UnifiedSubscriptionService().initialize().timeout(
    const Duration(seconds: 2),
    onTimeout: () {
      debugPrint('⚠️ UnifiedSubscriptionService timeout - defaulting to free tier');
    },
  );

  // Initialiser le service de notifications (non-bloquant)
  unawaited(NotificationService().initialize().then((_) async {
    // Demander les permissions iOS
    await NotificationService().requestPermissions();
    // Planifier les notifications selon les préférences
    await NotificationService().scheduleAllNotifications();
    debugPrint('✅ Notification service initialized and scheduled');
  }).catchError((e) {
    debugPrint('⚠️ Notification service error: $e');
  }));

  // OFFLINE WORKOUT: Initialiser le service offline (non-bloquant)
  unawaited(OfflineWorkoutService().initialize().then((_) {
    debugPrint('✅ Offline workout service initialized');
  }).catchError((e) {
    debugPrint('⚠️ Offline workout service error: $e');
  }));

  // Phases 2 & 3: Non-bloquantes, en arrière-plan
  unawaited(initializer.initializeImportantServices());
  unawaited(initializer.initializeOptionalServices());

  // NOUVEAU: Précharger les données du dashboard au démarrage
  unawaited(NavigationPreloader.instance.preloadForRoute('/dashboard'));

  // Lancer l'app immédiatement après les services critiques
  runApp(MyApp(navigatorKey: navigatorKey));
  
  // Démarrer la vérification des actions d'eau depuis le widget (iOS 17+ App Intents)
  WidgetWaterHandler.startChecking();
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: LocalizationService.instance),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // NOUVEAU: Pour les deep links
        title: 'Ryze',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              final currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
                currentFocus.unfocus();
              }
            },
            child: child ?? const SizedBox.shrink(),
          );
        },
        theme: ThemeData(
          textTheme: GoogleFonts.interTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0B132B),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0B132B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        home: const AppInitializer(),
        routes: {
          '/settings': (context) => const SettingsScreen(),
          '/pricing': (context) => const PricingScreen(),
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _animationController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _splashFadeOutAnimation;

  @override
  void initState() {
    super.initState();

    // Précharger la police Inter avant de démarrer les animations
    _preloadFont();

    // Animation ultra-rapide style AAA (500ms total)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Logo : apparition instantanée (0ms -> 100ms)
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // Disparition rapide (300ms -> 500ms)
    _splashFadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
    _initializeApp();
  }

  /// Précharger la police Inter pour éviter le changement de police visible
  Future<void> _preloadFont() async {
    try {
      await Future.wait([
        GoogleFonts.pendingFonts([
          GoogleFonts.inter(fontWeight: FontWeight.w400),
          GoogleFonts.inter(fontWeight: FontWeight.w500),
          GoogleFonts.inter(fontWeight: FontWeight.w600),
          GoogleFonts.inter(fontWeight: FontWeight.w700),
          GoogleFonts.inter(fontWeight: FontWeight.w800),
          GoogleFonts.inter(fontWeight: FontWeight.w900),
        ]),
      ]);
    } catch (e) {
      debugPrint('⚠️ Erreur préchargement police Inter: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Initialiser l'auth en parallèle de l'animation
    final authService = Provider.of<AuthService>(context, listen: false);

    // Démarrer l'auth
    final authFuture = _performAuthInitialization(authService);

    // Durée minimum de l'animation (300ms pour voir le logo)
    final minDuration = Future.delayed(const Duration(milliseconds: 300));

    // Attendre que l'auth ET l'animation minimum soient terminées
    await Future.wait([authFuture, minDuration]);

    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  Future<void> _performAuthInitialization(AuthService authService) async {
    try {
      // Délai pour éviter le freeze pendant build
      await Future.delayed(const Duration(milliseconds: 100));

      // CRITICAL: Timeout court pour mode avion (3s max)
      await authService.initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⚠️ Auth initialization timeout - app continues in offline mode');
        },
      );

      debugPrint('✅ Auth initialized successfully');
    } catch (e) {
      debugPrint('❌ Auth initialization failed (app continues): $e');
      // L'app continue même si l'auth échoue
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return _buildAnimatedSplash();
    }

    // Après le splash, afficher le contenu
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return _buildAnimatedSplash(); // Continuer le splash si auth en cours
        }

        return const RyzeApp();
      },
    );
  }

  Widget _buildAnimatedSplash() {
    return Scaffold(
      body: FadeTransition(
        opacity: _splashFadeOutAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Logo seul au centre
                Expanded(
                  child: Center(
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/logo_solo.svg',
                              width: 72,
                              height: 72,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Texte "Ryze" en bas
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: const Text(
                    'Ryze',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
