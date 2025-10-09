import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'components/ui/recipe_models.dart';
import 'pages/ryze_app.dart';
import 'services/offline_workout_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/settings_screen.dart';
import 'services/preload_service.dart';
import 'services/fast_cache_service.dart';
import 'core/infrastructure/migration/migration_controller.dart';
import 'core/infrastructure/startup/priority_service_initializer.dart';
import 'services/global_state_manager.dart';
import 'services/navigation_preloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // OPTIMISATION: Initialisation par priorités pour performance maximale
  final initializer = PriorityServiceInitializer.instance;

  // Phase 1: Services critiques SEULEMENT (2s max, bloquant)
  await initializer.initializeCriticalServices();

  // NOUVEAU: Initialiser le state manager global
  await GlobalStateManager.instance.initialize();

  // Phases 2 & 3: Non-bloquantes, en arrière-plan
  unawaited(initializer.initializeImportantServices());
  unawaited(initializer.initializeOptionalServices());

  // NOUVEAU: Précharger les données du dashboard au démarrage
  unawaited(NavigationPreloader.instance.preloadForRoute('/dashboard'));

  // Lancer l'app immédiatement après les services critiques
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: LocalizationService.instance),
      ],
      child: MaterialApp(
        title: 'Ryze App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.interTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0B132B),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const AppInitializer(),
        routes: {
          '/settings': (context) => const SettingsScreen(),
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

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // SOLUTION: Délayer l'auth pour éviter le freeze pendant build
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      debugPrint('🔄 AppInitializer: Starting auth initialization...');
      
      // Exécuter auth complètement hors du build cycle
      unawaited(_performAuthInitialization(authService));
      
      debugPrint('✅ AppInitializer: Auth initialization scheduled');
    } catch (e) {
      debugPrint('❌ AppInitializer: Auth scheduling error: $e');
    }
  }
  
  Future<void> _performAuthInitialization(AuthService authService) async {
    try {
      // Délai supplémentaire pour s'assurer qu'on est hors du build
      await Future.delayed(const Duration(milliseconds: 200));
      
      await authService.initialize().timeout(const Duration(seconds: 15));
      
      debugPrint('✅ Auth really initialized');
    } catch (e) {
      debugPrint('❌ Auth initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0B132B),
              ),
            ),
          );
        }

        return const RyzeApp();
      },
    );
  }
}
