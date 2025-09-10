import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'sport_dashboard.dart';
import 'sport_cardio_hybrid.dart';
import 'sport_musculation_hybrid.dart';
import '../services/dashboard_service.dart';
import '../services/streak_service.dart';
import '../services/header_cache_service.dart';
import '../providers/goals_notifier.dart';
import 'ui/language_switch_buttons.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';
import 'ui/refresh_wrapper.dart';

class SportSection extends StatefulWidget {
  const SportSection({super.key});

  @override
  State<SportSection> createState() => _SportSectionState();
}

class _SportSectionState extends State<SportSection>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;
  int _currentIndex = 0;
  int _completedGoals = 0;
  int _totalGoals = 0;
  bool _loadingObjectives = true;
  int _currentStreak = 0;
  bool _loadingStreak = true;
  String _getObjectivesText(String languageCode) => _loadingObjectives ? '...' : '$_completedGoals/$_totalGoals ${'sport_objectives_text'.tr(languageCode)}';
  String _getStreakText(String languageCode) => _loadingStreak ? '...' : '$_currentStreak ${'sport_days_text'.tr(languageCode)}';

  List<String> _getPageNames(String languageCode) => [
    'sport_dashboard_title'.tr(languageCode),
    'sport_cardio'.tr(languageCode),
    'sport_muscle_training'.tr(languageCode)
  ];
  final List<IconData> _pageIcons = [
    LucideIcons.activity,
    LucideIcons.activity,
    LucideIcons.dumbbell,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 3, vsync: this);
    
    // Essayer de charger depuis le cache d'abord
    _loadFromCache();
    
    _loadObjectives();
    _loadStreak();
    // Forcer la mise à jour du compteur d'objectifs
    DashboardService.refreshGoalsNotifier();
  }
  
  void _loadFromCache() {
    final cachedStats = HeaderCacheService.getCachedHeaderStats();
    if (cachedStats != null) {
      setState(() {
        _currentStreak = int.tryParse(cachedStats.dailyStreak.split(' ')[0]) ?? 0;
        _loadingStreak = false;
      });
      print('⚡ Sport header chargé depuis le cache: ${cachedStats.dailyStreak}');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _tabController.animateTo(index);
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onRefresh() async {
    try {
      // Recharger les données de la section sport
      await Future.wait([
        _loadObjectives(),
        _loadStreak(),
      ]);
      
      // Vider le cache et forcer le rafraîchissement (méthodes void)
      HeaderCacheService.clearCache();
      DashboardService.refreshGoalsNotifier();
    } catch (e) {
      print('Erreur lors du rafraîchissement du sport: $e');
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

  Future<void> _loadStreak() async {
    try {
      final streak = await StreakService.getCurrentStreak();
      setState(() {
        _currentStreak = streak;
        _loadingStreak = false;
      });
    } catch (e) {
      setState(() {
        _loadingStreak = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header avec titre et indicateurs de page
                _buildHeader(),
                
                // Contenu principal avec PageView et RefreshIndicator
                Expanded(
                  child: RefreshWrapper(
                    onRefresh: _onRefresh,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: const [
                        SportDashboard(),
                        SportCardioHybrid(),
                        SportMusculationHybrid(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const LanguageSwitchButtons(),
          ],
        ),
      ),
    );
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
          // Bandeau streak/XP remplace le titre
          Container(
            width: double.infinity,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => 
                    _buildBannerItem(LucideIcons.flame, _getStreakText(locService.currentLanguageCode)),
                ),
                _buildBannerSeparator(),
                Consumer<LocalizationService>(
                  builder: (context, localizationService, _) {
                    return ValueListenableBuilder<GoalsSummary>(
                      valueListenable: GoalsNotifier.instance,
                      builder: (context, summary, _) {
                        return _buildBannerItem(LucideIcons.target, '${summary.completed}/${summary.total} ${'objectives'.tr(localizationService.currentLanguageCode)}');
                      },
                    );
                  },
                ),
                _buildBannerSeparator(),
                _buildBannerItemWithLogo('Sport'),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Navigation tabs avec trait sous l'onglet actuel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(3, (index) {
                final isSelected = _currentIndex == index;
                // Flex personnalisés : plus d'espace pour "Tableau de bord"
                final flex = index == 0 ? 3 : 2;
                
                return Expanded(
                  flex: flex,
                  child: GestureDetector(
                    onTap: () => _onTabTapped(index),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < 2 ? 4 : 0,
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _pageIcons[index],
                                  size: 16,
                                  color: isSelected 
                                      ? const Color(0xFF0B132B)
                                      : const Color(0xFF888888),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Consumer<LocalizationService>(
                                    builder: (context, locService, _) => Text(
                                      _getPageNames(locService.currentLanguageCode)[index],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected 
                                            ? const Color(0xFF0B132B)
                                            : const Color(0xFF888888),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Trait sous l'onglet actuel
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF0B132B) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
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
} 
