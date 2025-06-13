import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'sport_dashboard.dart';
import 'sport_cardio_hybrid.dart';
import 'sport_musculation_hybrid.dart';

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

  final List<String> _pageNames = ['Tableau de bord', 'Cardio', 'Musculation'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec titre et indicateurs de page
            _buildHeader(),
            
            // Contenu principal avec PageView
            Expanded(
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
                _buildBannerItem(LucideIcons.flame, '7 jours'),
                _buildBannerSeparator(),
                _buildBannerItem(LucideIcons.target, '4/5 objectifs'),
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
                                  child: Text(
                                    _pageNames[index],
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
