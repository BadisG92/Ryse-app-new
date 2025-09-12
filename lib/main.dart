import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Localization Service first (no network needed)
    await LocalizationService.instance.initialize();
    
    // Initialize Supabase (non-blocking)
    await SupabaseConfig.initialize();
    
    // Initialize Recipe Data from Supabase (en arrière-plan, non-blocking)
    try {
      RecipeData.initialize();
      print('✅ Recipe data initialization started');
    } catch (e) {
      print('⚠️ Recipe data initialization failed (offline): $e');
    }
    
    // Initialize Offline Service pour la musculation
    final offlineService = OfflineWorkoutService();
    await SharedPreferencesSync().init(); // Pour les vérifications rapides
    await offlineService.initialize().catchError((e) {
      print('⚠️ Offline service initialization failed: $e');
    });
    
  } catch (e) {
    print('⚠️ Main initialization error: $e');
    // Continue même si certaines initialisations échouent
  }
  
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
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initialize();
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
