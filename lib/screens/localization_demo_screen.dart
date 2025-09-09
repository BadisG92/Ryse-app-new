import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../components/ui/language_selector.dart';
import '../components/ui/localized_food_list.dart';

/// Écran de démonstration du système de localisation
/// 
/// Cet écran montre :
/// - Comment utiliser les traductions pour les textes codés en dur
/// - Comment changer de langue avec le widget LanguageSelector
/// - Comment afficher des données localisées depuis la base de données
class LocalizationDemoScreen extends StatefulWidget {
  const LocalizationDemoScreen({super.key});

  @override
  State<LocalizationDemoScreen> createState() => _LocalizationDemoScreenState();
}

class _LocalizationDemoScreenState extends State<LocalizationDemoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            'localization_demo'.tr(locService.currentLanguageCode),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: Consumer<LocalizationService>(
        builder: (context, locService, child) {
          return Column(
            children: [
              // Section des exemples de textes traduits
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'static_texts_demo'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTranslationExample(locService, 'good_morning'),
                    _buildTranslationExample(locService, 'dashboard_daily_goals'),
                    _buildTranslationExample(locService, 'nutrition_sport_tracking'),
                    _buildTranslationExample(locService, 'progress'),
                    _buildTranslationExample(locService, 'calories'),
                    _buildTranslationExample(locService, 'loading'),
                    const SizedBox(height: 8),
                    Text(
                      'current_language_info'.tr(locService.currentLanguageCode),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Section de recherche d'aliments
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'search_foods'.tr(locService.currentLanguageCode),
                    hintText: 'search_foods_hint'.tr(locService.currentLanguageCode),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchTerm = value;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Liste d'aliments localisés
              Expanded(
                child: LocalizedFoodList(
                  searchTerm: searchTerm.isEmpty ? null : searchTerm,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final locService = context.read<LocalizationService>();
          final currentLang = locService.currentLanguageCode;
          final newLang = currentLang == 'fr' ? 'en' : 'fr';
          locService.setLanguage(newLang);
        },
        child: const Icon(Icons.language),
        tooltip: 'Changer de langue',
      ),
    );
  }

  Widget _buildTranslationExample(LocalizationService locService, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '• $key:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              key.tr(locService.currentLanguageCode),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}