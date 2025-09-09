import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../components/ui/language_selector.dart';
import '../components/ui/localized_exercise_list.dart';
import '../components/ui/localized_food_list.dart';

/// Écran de démonstration complète du système de localisation
/// 
/// Montre l'utilisation de :
/// - Textes statiques traduits
/// - Données de base de données localisées 
/// - Changement de langue dynamique
/// - Interface adaptée selon la langue
class CompleteLocalizationDemo extends StatefulWidget {
  const CompleteLocalizationDemo({super.key});

  @override
  State<CompleteLocalizationDemo> createState() => _CompleteLocalizationDemoState();
}

class _CompleteLocalizationDemoState extends State<CompleteLocalizationDemo> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'complete_demo_title'.tr(locService.currentLanguageCode),
            ),
            elevation: 0,
            backgroundColor: const Color(0xFF0B132B),
            foregroundColor: Colors.white,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: LanguageSelector(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(
                  icon: const Icon(LucideIcons.info),
                  text: 'overview'.tr(locService.currentLanguageCode),
                ),
                Tab(
                  icon: const Icon(LucideIcons.dumbbell),
                  text: 'exercises'.tr(locService.currentLanguageCode),
                ),
                Tab(
                  icon: const Icon(LucideIcons.utensils),
                  text: 'foods'.tr(locService.currentLanguageCode),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(locService),
              _buildExercisesTab(locService),
              _buildFoodsTab(locService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(LocalizationService locService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations sur la langue actuelle
          _buildLanguageInfoCard(locService),
          
          const SizedBox(height: 16),
          
          // Exemples de textes statiques
          _buildStaticTextsCard(locService),
          
          const SizedBox(height: 16),
          
          // Exemples de formatage
          _buildFormattingExamplesCard(locService),
          
          const SizedBox(height: 16),
          
          // Instructions d'utilisation
          _buildInstructionsCard(locService),
        ],
      ),
    );
  }

  Widget _buildLanguageInfoCard(LocalizationService locService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.languages,
                    color: Color(0xFF0B132B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'language_info'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow(
              'current_language'.tr(locService.currentLanguageCode),
              locService.isFrench ? 'Français 🇫🇷' : 'English 🇺🇸',
            ),
            
            _buildInfoRow(
              'language_code'.tr(locService.currentLanguageCode),
              locService.currentLanguageCode.toUpperCase(),
            ),
            
            _buildInfoRow(
              'database_suffix'.tr(locService.currentLanguageCode),
              locService.getColumnSuffix(),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: locService.isFrench ? Colors.blue.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 16,
                    color: locService.isFrench ? Colors.blue.shade700 : Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'language_tip'.tr(locService.currentLanguageCode),
                      style: TextStyle(
                        fontSize: 12,
                        color: locService.isFrench ? Colors.blue.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticTextsCard(LocalizationService locService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'static_texts_examples'.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...[
              'dashboard_title',
              'good_morning', 
              'calories',
              'proteins',
              'progress',
              'loading',
              'save',
              'cancel',
            ].map((key) => _buildTranslationExample(key, locService)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattingExamplesCard(LocalizationService locService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'formatting_examples'.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildFormatExample(
              'water_consumption'.tr(locService.currentLanguageCode),
              '1500 ml → 1.5 L',
            ),
            
            _buildFormatExample(
              'macro_distribution'.tr(locService.currentLanguageCode),
              '150g ${'proteins'.tr(locService.currentLanguageCode)}, 200g ${'carbs'.tr(locService.currentLanguageCode)}',
            ),
            
            _buildFormatExample(
              'measurement_units'.tr(locService.currentLanguageCode),
              locService.isFrench ? '70 kg, 175 cm' : '154 lbs, 5\'9"',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(LocalizationService locService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'how_to_use'.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...[
              'instruction_1',
              'instruction_2', 
              'instruction_3',
              'instruction_4',
            ].map((key) => _buildInstruction(key, locService)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesTab(LocalizationService locService) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF8FAFC),
          child: Row(
            children: [
              Icon(
                LucideIcons.dumbbell,
                color: const Color(0xFF0B132B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'exercises_database_demo'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: LocalizedExerciseList(),
        ),
      ],
    );
  }

  Widget _buildFoodsTab(LocalizationService locService) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF8FAFC),
          child: Row(
            children: [
              Icon(
                LucideIcons.utensils,
                color: const Color(0xFF0B132B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'foods_database_demo'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: LocalizedFoodList(),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationExample(String key, LocalizationService locService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.arrowRight,
            size: 12,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              key.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatExample(String label, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              example,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF0B132B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String key, LocalizationService locService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF0B132B),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${[
                  'instruction_1',
                  'instruction_2',
                  'instruction_3', 
                  'instruction_4'
                ].indexOf(key) + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              key.tr(locService.currentLanguageCode),
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}