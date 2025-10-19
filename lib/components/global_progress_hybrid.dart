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
  WeeklyBalance _weeklyBalance = const WeeklyBalance(items: []); // Initialiser vide pour éviter le flash
  List<TrackingDay> _trackingDays = const []; // Initialiser vide pour éviter le flash
  int _completedGoals = 0;
  int _totalGoals = 0;
  bool _dataLoaded = false;  // Flag pour savoir si les vraies données sont chargées

  // Clés de cache pour poids
  static const String _weightCacheKey = 'progress_weight_cache';
  static const String _weightCacheTimestampKey = 'progress_weight_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 24);

  @override
  void initState() {
    super.initState();

    // OPTIMISATION: Chargement instantané depuis GlobalStateManager
    _loadInitialDataSync();

    // Charger les vraies données immédiatement
    _loadProgressData();

    // Forcer la mise à jour du compteur d'objectifs (en arrière-plan)
    Future.delayed(const Duration(milliseconds: 200), () {
      DashboardService.refreshGoalsNotifier();
    });

    // Écouter les changements de poids
    WeightNotifier.instance.addListener(_onWeightChanged);
  }

  /// Helper pour obtenir le label du jour
  String _getDayLabel(int weekday) {
    const translationKeys = ['day_l', 'day_m', 'day_m2', 'day_j', 'day_v', 'day_s', 'day_d'];
    return translationKeys[weekday - 1].tr(LocalizationService.instance.currentLanguageCode);
  }

  /// NOUVEAU: Chargement synchrone instantané depuis GlobalStateManager et cache
  void _loadInitialDataSync() {
    final globalState = GlobalStateManager.instance;

    setState(() {
      // Charger les objectifs depuis GlobalStateManager
      final goals = globalState.getDailyGoalsForDashboard();
      _completedGoals = goals.where((g) => g['completed'] == true).length;
      _totalGoals = goals.length;

      // NOUVEAU: Utiliser les données hebdomadaires réelles si disponibles dans GlobalState
      if (globalState.weeklyDataValid &&
          globalState.weeklyBalance != null &&
          globalState.weeklyTracking != null) {

        // Utiliser les vraies données déjà chargées
        _weeklyBalance = globalState.weeklyBalance!;
        _trackingDays = globalState.weeklyTracking!;
        _dataLoaded = true;

        debugPrint('⚡ GlobalProgress: Données hebdomadaires récupérées du cache GlobalState');
      } else {
        // Pas de données, on les charge depuis Supabase
        _weeklyBalance = const WeeklyBalance(items: []);
        _trackingDays = const [];
        _dataLoaded = false;

        debugPrint('⚡ GlobalProgress: Pas de données hebdomadaires en cache, chargement requis');
      }
    });

    // Charger les données de poids depuis le cache de manière asynchrone mais non-bloquante
    _loadWeightFromCache();

    debugPrint('⚡ GlobalProgress: Initialisation complète');
    debugPrint('   - Objectifs: $_completedGoals/$_totalGoals');
    debugPrint('   - Bilan items: ${_weeklyBalance.items.length}');
    debugPrint('   - Tracking days: ${_trackingDays.length}');
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
      final globalState = GlobalStateManager.instance;

      // Si les données sont déjà en cache et valides, ne pas recharger
      if (globalState.weeklyDataValid &&
          globalState.weeklyBalance != null &&
          globalState.weeklyTracking != null) {
        debugPrint('📊 Données hebdomadaires déjà en cache, pas de rechargement nécessaire');
        return;
      }

      debugPrint('🔄 Chargement des données de progression depuis Supabase...');

      // Charger les données une par une pour un affichage progressif
      // D'abord le poids (le plus rapide)
      WeightService.getWeightProgress().then((weightProgress) {
        if (mounted) {
          setState(() {
            _weightProgress = weightProgress;
          });
          _saveWeightToCache(weightProgress);
        }
      });

      // Charger le bilan et le tracking en parallèle
      final results = await Future.wait([
        ProgressServiceV2.getWeeklyBalance(),
        ProgressServiceV2.getWeeklyTracking(),
      ]);

      final balance = results[0] as WeeklyBalance;
      final tracking = results[1] as List<TrackingDay>;

      // Stocker dans GlobalState pour réutilisation
      globalState.updateWeeklyData(balance, tracking);

      // Mettre à jour l'UI
      if (mounted) {
        setState(() {
          _weeklyBalance = balance;
          _trackingDays = tracking;
          _dataLoaded = true;
        });
      }

      debugPrint('✅ Données de progression chargées et mises en cache dans GlobalState');

    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des données de progression: $e');
      if (mounted) {
        setState(() {
          _dataLoaded = true;  // Même en cas d'erreur, on ne veut pas rester bloqué en chargement
        });
      }
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          top: false,
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
                        
                        // Section du bilan global hebdomadaire
                        const SizedBox(height: 16),
                        if (!_dataLoaded)
                          _buildBalanceLoadingSection()
                        else if (_weeklyBalance.items.isNotEmpty)
                          GlobalProgressSectionBuilder.buildBalanceSection(_weeklyBalance),

                        // Section de tracking hebdomadaire (nutrition + sport)
                        if (!_dataLoaded) ...[
                          const SizedBox(height: 16),
                          _buildBalanceLoadingSection(),  // Réutiliser le même skeleton
                        ] else if (_trackingDays.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          GlobalProgressSectionBuilder.buildTrackingSection(_trackingDays),
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
      ),
    );
  }

  /// Méthode de rafraîchissement pour le pull-to-refresh
  Future<void> _onRefresh() async {
    try {
      debugPrint('🔄 Rafraîchissement manuel des données de progression...');

      // Invalider le cache hebdomadaire dans GlobalState
      GlobalStateManager.instance.invalidateWeeklyData();

      // Forcer le rafraîchissement du cache dans ProgressServiceV2
      ProgressServiceV2.forceRefresh();

      // Recharger toutes les données
      await _loadProgressData();
    } catch (e) {
      debugPrint('❌ Erreur lors du rafraîchissement manuel: $e');
    }
  }

  Widget _buildHeader() {
    final topInset = MediaQuery.of(context).padding.top;
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
                top: topInset + 14,
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

  Widget _buildBalanceLoadingSection() {
    // Un skeleton loader qui imite la structure de la vraie section
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre skeleton
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          // Skeleton items
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
} 
