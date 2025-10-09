import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'ui/global_progress_models.dart';
import 'ui/global_progress_widgets.dart';
import 'ui/global_state_header.dart';
import '../services/dashboard_service.dart';
import '../services/progress_service_v2.dart';
import '../services/header_cache_service.dart';
import '../services/weight_service.dart';
import '../screens/weight_evolution_screen.dart';
import '../providers/goals_notifier.dart';
import '../providers/weight_notifier.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';

class GlobalProgress extends StatefulWidget {
  const GlobalProgress({super.key});

  @override
  State<GlobalProgress> createState() => _GlobalProgressState();
}

class _GlobalProgressState extends State<GlobalProgress> {
  
  // État des données (chargées depuis les services)
  WeightProgress? _weightProgress;
  WeeklyBalance _weeklyBalance = GlobalProgressData.weeklyBalance;
  List<TrackingDay> _trackingDays = GlobalProgressData.weeklyTracking;
  HeaderStats? _headerStats; // Pas d'initialisation par défaut
  int _completedGoals = 0;
  int _totalGoals = 0;
  bool _loadingObjectives = true;
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    
    // Essayer de charger depuis le cache d'abord
    _loadFromCache();
    
    _loadObjectives();
    _loadProgressData();
    // Forcer la mise à jour du compteur d'objectifs
    DashboardService.refreshGoalsNotifier();
    
    // Écouter les changements de poids
    WeightNotifier.instance.addListener(_onWeightChanged);
  }
  
  @override
  void dispose() {
    // Arrêter d'écouter les changements
    WeightNotifier.instance.removeListener(_onWeightChanged);
    super.dispose();
  }
  
  void _onWeightChanged() {
    print('🔄 GlobalProgress: Weight changed, reloading data');
    _loadProgressData();
  }
  
  void _loadFromCache() {
    final cachedStats = HeaderCacheService.getCachedHeaderStats();
    if (cachedStats != null) {
      setState(() {
        _headerStats = cachedStats;
      });
      print('⚡ Header chargé depuis le cache: ${cachedStats.dailyStreak}');
    }
  }

  Future<void> _loadObjectives() async {
    try {
      final goals = await DashboardService.getDailyGoals();
      final completed = goals.where((g) => g.completed).length;
      setState(() {
        _completedGoals = completed;
        _totalGoals = goals.length;
        _loadingObjectives = false;
      });
    } catch (e) {
      setState(() => _loadingObjectives = false);
    }
  }

  Future<void> _loadProgressData() async {
    try {
      print('🔄 Chargement des données de progression avec cache hebdomadaire...');
      
      // S'assurer que le cache est propre pour éviter les conflits de statut
      ProgressServiceV2.forceRefresh();
      
      // Charger avec le nouveau service optimisé pour les bilans hebdo + données de poids réelles
      final results = await Future.wait([
        WeightService.getWeightProgress(),
        ProgressServiceV2.getWeeklyBalance(),
        ProgressServiceV2.getWeeklyTracking(),
        ProgressServiceV2.getHeaderStats(),
      ]);
      
      final newHeaderStats = results[3] as HeaderStats;
      
      setState(() {
        _weightProgress = results[0] as WeightProgress;
        _weeklyBalance = results[1] as WeeklyBalance;
        _trackingDays = results[2] as List<TrackingDay>;
        _headerStats = newHeaderStats;
        _loadingProgress = false;
      });
      
      // Mettre à jour le cache pour les autres pages
      HeaderCacheService.updateCache(newHeaderStats);
      
      print('✅ Données de progression chargées avec cache hebdomadaire');
      print('   - Bilan hebdomadaire: ${_weeklyBalance.items.length} items');
      print('   - Tracking: ${_trackingDays.length} jours');
      
    } catch (e) {
      print('❌ Erreur lors du chargement des données de progression: $e');
      setState(() => _loadingProgress = false);
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
                      
                      const SizedBox(height: 16),
                      
                      // Section du bilan global hebdomadaire
                      _loadingProgress 
                        ? _buildLoadingSection() 
                        : GlobalProgressSectionBuilder.buildBalanceSection(_weeklyBalance),
                      
                      const SizedBox(height: 16),
                      
                      // Section de tracking hebdomadaire (nutrition + sport)
                      _loadingProgress 
                        ? _buildLoadingSection() 
                        : GlobalProgressSectionBuilder.buildTrackingSection(_trackingDays),
                      
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
      print('🔄 Rafraîchissement manuel des données de progression...');
      
      // Forcer le rafraîchissement du cache
      ProgressServiceV2.forceRefresh();
      
      // Recharger toutes les données
      await _loadProgressData();
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement manuel: $e');
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

  Widget _buildBannerItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBannerSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('•', style: TextStyle(color: Colors.white60, fontSize: 14)),
    );
  }

  Widget _buildBannerItemWithLogo(String text) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/logo_seul.svg',
          width: 16,
          height: 16,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
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
