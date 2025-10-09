import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ui/global_progress_models.dart';
import 'ui/global_progress_widgets.dart';
import 'ui/global_state_header.dart';
import '../services/dashboard_service.dart';
import '../services/progress_service_v2.dart';
import '../services/weight_service.dart';
import '../screens/weight_evolution_screen.dart';
import '../providers/weight_notifier.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import '../services/global_state_manager.dart';

class GlobalProgress extends StatefulWidget {
  const GlobalProgress({super.key});

  @override
  State<GlobalProgress> createState() => _GlobalProgressState();
}

class _GlobalProgressState extends State<GlobalProgress> {

  // État des données (chargées depuis les services)
  WeightProgress? _weightProgress;
  WeeklyBalance _weeklyBalance = const WeeklyBalance(items: []); // OPTIMISATION: Initialiser vide pour éviter le flash
  List<TrackingDay> _trackingDays = const []; // OPTIMISATION: Initialiser vide pour éviter le flash
  int _completedGoals = 0;
  int _totalGoals = 0;
  bool _loadingProgress = false;    // OPTIMISATION: Changé de true à false

  // Clés de cache pour poids
  static const String _weightCacheKey = 'progress_weight_cache';
  static const String _weightCacheTimestampKey = 'progress_weight_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 24);

  @override
  void initState() {
    super.initState();

    // OPTIMISATION: Chargement instantané depuis GlobalStateManager
    _loadInitialDataSync();

    // Enrichissement en arrière-plan (non-bloquant)
    _loadProgressData();

    // Forcer la mise à jour du compteur d'objectifs
    DashboardService.refreshGoalsNotifier();

    // Écouter les changements de poids
    WeightNotifier.instance.addListener(_onWeightChanged);
  }

  /// NOUVEAU: Chargement synchrone instantané depuis GlobalStateManager et cache
  void _loadInitialDataSync() {
    final globalState = GlobalStateManager.instance;

    setState(() {
      // Charger les objectifs depuis GlobalStateManager
      final goals = globalState.getDailyGoalsForDashboard();
      _completedGoals = goals.where((g) => g['completed'] == true).length;
      _totalGoals = goals.length;
    });

    // Charger les données de poids depuis le cache de manière asynchrone mais non-bloquante
    _loadWeightFromCache();

    debugPrint('⚡ GlobalProgress: Données initiales chargées en mode synchrone');
    debugPrint('   - Objectifs: $_completedGoals/$_totalGoals');
  }

  /// Charger les données de poids depuis le cache SharedPreferences
  void _loadWeightFromCache() {
    SharedPreferences.getInstance().then((prefs) {
      final cachedData = prefs.getString(_weightCacheKey);
      final cachedTimestamp = prefs.getInt(_weightCacheTimestampKey);

      if (cachedData != null && cachedTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;

        // Utiliser le cache s'il est valide (moins de 24h)
        if (cacheAge < _cacheDuration.inMilliseconds) {
          try {
            final Map<String, dynamic> json = jsonDecode(cachedData);
            final weightProgress = WeightProgress(
              currentWeight: json['currentWeight'] ?? 0.0,
              previousWeight: json['previousWeight'] ?? 0.0,
              initialWeight: json['initialWeight'] ?? 0.0,
              targetWeight: json['targetWeight'] ?? 0.0,
              entries: (json['entries'] as List?)
                  ?.map((e) => WeightEntry(
                        date: DateTime.parse(e['date']),
                        weight: e['weight'],
                      ))
                  .toList() ?? [],
            );

            setState(() {
              _weightProgress = weightProgress;
            });

            debugPrint('⚡ GlobalProgress: Poids chargé depuis le cache (${weightProgress.entries.length} entrées)');
          } catch (e) {
            debugPrint('⚠️ Erreur lecture cache poids: $e');
          }
        }
      }
    });
  }
  
  @override
  void dispose() {
    // Arrêter d'écouter les changements
    WeightNotifier.instance.removeListener(_onWeightChanged);
    super.dispose();
  }
  
  void _onWeightChanged() {
    debugPrint('🔄 GlobalProgress: Weight changed, reloading data');
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      debugPrint('🔄 Chargement des données de progression avec cache hebdomadaire...');

      // S'assurer que le cache est propre pour éviter les conflits de statut
      ProgressServiceV2.forceRefresh();

      // Charger avec le nouveau service optimisé pour les bilans hebdo + données de poids réelles
      final results = await Future.wait([
        WeightService.getWeightProgress(),
        ProgressServiceV2.getWeeklyBalance(),
        ProgressServiceV2.getWeeklyTracking(),
      ]);

      final weightProgress = results[0] as WeightProgress;

      setState(() {
        _weightProgress = weightProgress;
        _weeklyBalance = results[1] as WeeklyBalance;
        _trackingDays = results[2] as List<TrackingDay>;
        _loadingProgress = false;
      });

      // Sauvegarder le poids dans le cache
      await _saveWeightToCache(weightProgress);

      debugPrint('✅ Données de progression chargées avec cache hebdomadaire');
      debugPrint('   - Bilan hebdomadaire: ${_weeklyBalance.items.length} items');
      debugPrint('   - Tracking: ${_trackingDays.length} jours');

    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des données de progression: $e');
      setState(() => _loadingProgress = false);
    }
  }

  /// Sauvegarder les données de poids dans le cache
  Future<void> _saveWeightToCache(WeightProgress weightProgress) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final json = {
        'currentWeight': weightProgress.currentWeight,
        'previousWeight': weightProgress.previousWeight,
        'initialWeight': weightProgress.initialWeight,
        'targetWeight': weightProgress.targetWeight,
        'entries': weightProgress.entries.map((e) => {
          'date': e.date.toIso8601String(),
          'weight': e.weight,
        }).toList(),
      };

      await prefs.setString(_weightCacheKey, jsonEncode(json));
      await prefs.setInt(_weightCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('💾 Cache poids Progress sauvegardé (${weightProgress.entries.length} entrées)');
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde cache poids: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bandeau identique aux pages sport/nutrition
            _buildHeader(),
            
            // Corps principal avec scroll et pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFF0B132B),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Section d'évolution du poids avec graphique
                      _weightProgress != null 
                        ? GlobalProgressSectionBuilder.buildWeightSection(
                            _weightProgress!,
                            _onEditWeight,
                          )
                        : _buildLoadingSection(),
                      
                      // OPTIMISATION: Ne pas afficher les sections si elles sont vides pour éviter le flash
                      if (_weeklyBalance.items.isNotEmpty || _loadingProgress) ...[
                        const SizedBox(height: 16),

                        // Section du bilan global hebdomadaire
                        _loadingProgress
                          ? _buildLoadingSection()
                          : GlobalProgressSectionBuilder.buildBalanceSection(_weeklyBalance),
                      ],

                      if (_trackingDays.isNotEmpty || _loadingProgress) ...[
                        const SizedBox(height: 16),

                        // Section de tracking hebdomadaire (nutrition + sport)
                        _loadingProgress
                          ? _buildLoadingSection()
                          : GlobalProgressSectionBuilder.buildTrackingSection(_trackingDays),
                      ],
                      
                      // Espace en bas pour éviter que le contenu soit coupé
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Méthode de rafraîchissement pour le pull-to-refresh
  Future<void> _onRefresh() async {
    try {
      debugPrint('🔄 Rafraîchissement manuel des données de progression...');

      // Forcer le rafraîchissement du cache
      ProgressServiceV2.forceRefresh();

      // Recharger toutes les données
      await _loadProgressData();
    } catch (e) {
      debugPrint('❌ Erreur lors du rafraîchissement manuel: $e');
    }
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // NOUVEAU: Bandeau global avec GlobalStateManager (synchronisé instantanément)
          Stack(
            children: [
              const GlobalStateHeaderWidget(),
              Positioned(
                right: 12,
                top: 10,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  child: const Icon(
                    LucideIcons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Action d'édition du poids - naviguer vers la page dédiée
  void _onEditWeight() {
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeightEvolutionScreen(),
      ),
    );
  }


  Widget _buildLoadingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF0B132B),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'loading_weight_data'.tr(locService.currentLanguageCode),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
