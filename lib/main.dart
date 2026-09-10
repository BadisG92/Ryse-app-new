import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/env_config.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'services/theme_service.dart';
import 'services/analytics_service.dart';
import 'services/app_navigator.dart';
import 'pages/ryze_app.dart';
import 'services/offline_workout_service.dart';
import 'settings/settings_page.dart';
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
import 'services/widget_sync_service.dart';
import 'services/meal_widget_data_provider.dart';
import 'services/haptic_service.dart';
import 'design/tokens.dart';
import 'design/feedback.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/ryze_connectivity.dart';
import 'services/usage_stats.dart';
import 'services/workout_session_store.dart';

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

  // Handle initial link (app opened from widget). The handler itself waits
  // for the app to be ready — intro finished, tab bar mounted — and drops
  // the same link delivered twice, which the stream below also does with
  // the initial one.
  try {
    final initialLink = await appLinks.getInitialLinkString();
    if (initialLink != null) {
      debugPrint('🔗 Initial deep link detected: $initialLink');
      WidgetDeepLinkHandler.handleDeepLink(Uri.parse(initialLink));
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

  // Les symboles de date des trois langues, chargés une fois pour toutes.
  // Sans eux, un DateFormat avec une locale explicite lève une exception, et
  // en release une exception dans un build donne un écran gris.
  await initializeDateFormatting('fr');
  await initializeDateFormatting('en');
  await initializeDateFormatting('de');

  // La palette choisie par l'utilisateur, avant le premier rendu : sans quoi
  // l'application s'ouvrirait en Nuit puis changerait de couleur sous les yeux.
  await ThemeService.instance.load();

  // Initialiser le service de retour haptique
  await HapticService.instance.initialize();
  await RyzeFeedback.initialize();

  // Les widgets du telephone. Ce travail refait une lecture complete de l'etat
  // du jour et ecrit le fichier partage : sans reseau il n'aboutissait jamais,
  // et il bloquait le lancement — l'ecran restait bleu, sans animation, le
  // temps qu'il abandonne. Il part en arriere-plan, borne.
  unawaited(
    MealWidgetDataProvider.forceWidgetUpdate()
        .timeout(const Duration(seconds: 6))
        .catchError((Object e) => debugPrint('⚠️ Widgets non mis a jour: $e')),
  );

  // Initialiser les services d'analyse IA avec Gemini
  ExerciseAiAnalysisService.initialize();
  CoachRyzeNutritionService.initialize();

  // L'abonnement : rien du premier ecran n'en depend, et sans reseau ses deux
  // secondes s'ajoutaient a toutes les autres. Il part en arriere-plan.
  unawaited(
    UnifiedSubscriptionService()
        .initialize()
        .timeout(const Duration(seconds: 8))
        .catchError((Object e) => debugPrint('⚠️ Abonnement indisponible: $e')),
  );

  // Initialiser le service de notifications (non-bloquant)
  // La permission ne se demande plus ici : au premier lancement, elle arrive
  // avant que l'utilisateur ait quoi que ce soit à recevoir, et un refus est
  // definitif. Elle part apres le premier repas note — voir
  // NotificationService.requestAfterFirstEntry.
  unawaited(NotificationService().initialize().then((_) async {
    await NotificationService().scheduleAllNotifications();
    debugPrint('✅ Notification service initialized and scheduled');
  }).catchError((e) {
    debugPrint('⚠️ Notification service error: $e');
  }));

  // HORS LIGNE : une seule souscription réseau pour l'app, puis le catalogue
  // d'exercices, puis la file des séances (qui migre l'ancienne et rejoue ce
  // qui attend). Non bloquant : le lancement n'attend pas le réseau.
  // Les compteurs d'usage reprennent ce que la dernière exécution n'a pas eu
  // le temps d'envoyer.
  unawaited(UsageStats.start());

  unawaited(RyzeConnectivity.instance.start().then((_) async {
    await OfflineWorkoutService().initialize();
    await WorkoutSessionStore.instance.initialize();
    debugPrint('✅ Offline workout services initialized');
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
  
  // Les widgets : l'eau ajoutée depuis le widget iOS pendant que l'app était
  // fermée, lue au retour au premier plan ; et les changements de plan, de
  // séance ou de jour, qui redessinent les widgets sans passer par un repas.
  WidgetWaterHandler.startChecking();
  WidgetSyncService.start();
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
        ChangeNotifierProvider.value(value: ThemeService.instance),
      ],
      // Les jetons de couleur sont lus a chaque `build` : il suffit donc de
      // reconstruire depuis la racine pour que le choix d'une palette repeigne
      // l'application entiere, sans redemarrage et sans qu'aucun ecran ait a
      // savoir qu'un theme existe.
      child: Consumer2<ThemeService, LocalizationService>(
        builder: (context, theme, loc, _) => MaterialApp(
        navigatorKey: navigatorKey, // NOUVEAU: Pour les deep links
        title: 'Ryze',
        debugShowCheckedModeBanner: false,
        // Les widgets de Material parlaient anglais à tout le monde : rien ne
        // leur avait dit quelle langue l'app parle. Le sélecteur d'heure des
        // rappels était le dernier endroit où ça se voyait.
        locale: loc.currentLocale,
        supportedLocales: const [Locale('fr'), Locale('en'), Locale('de')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
            seedColor: RyzeColors.ink,
            brightness: RyzeColors.isDark ? Brightness.dark : Brightness.light,
          ),
          useMaterial3: true,
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: RyzeColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        home: const AppInitializer(),
        // La route '/pricing' menait a un ecran d'essai avec un bouton
        // « TEST: Premium active » cable sur un bypass d'achat. Rien n'y
        // naviguait, mais il etait enregistre dans l'application publiee.
        routes: {
          '/settings': (context) => const SettingsPage(),
        },
        ),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {

  @override
  void initState() {
    super.initState();

    // Précharger la police Inter avant de démarrer les animations
    _preloadFont();

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

  /// L'eveil de l'authentification part en arriere-plan : l'ouverture ne se
  /// retient plus derriere lui. Le routage l'attend lui-meme quand il a besoin
  /// du profil, et l'appel est mis en commun avec celui-ci.
  Future<void> _initializeApp() async {
    await _performAuthInitialization(Provider.of<AuthService>(context, listen: false));
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

  /// L'ouverture est l'ecran de chargement : le logo s'ecrit pendant que le
  /// routage se resout, et ne s'ouvre sur l'ecran qu'une fois qu'il y en a un.
  ///
  /// Un sol etait dessine ici en plus, le temps de l'eveil de l'authentification
  /// puis a chaque fois qu'elle repassait en chargement : deux ouvertures l'une
  /// sur l'autre, et depuis les editions deux bleus differents — le degrade de
  /// la marque choisie, puis le navy de l'ouverture. Il n'y a plus qu'une phase.
  @override
  Widget build(BuildContext context) => const RyzeApp();
}
