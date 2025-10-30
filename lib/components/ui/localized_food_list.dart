import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localized_database_service.dart';
import '../../services/localization_service.dart';

/// Exemple d'utilisation du service de base de données localisé
/// Ce widget affiche une liste d'aliments avec nom et description traduits
class LocalizedFoodList extends StatefulWidget {
  final String? searchTerm;
  
  const LocalizedFoodList({
    super.key,
    this.searchTerm,
  });

  @override
  State<LocalizedFoodList> createState() => _LocalizedFoodListState();
}

class _LocalizedFoodListState extends State<LocalizedFoodList> {
  List<Map<String, dynamic>> foods = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void didUpdateWidget(LocalizedFoodList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchTerm != widget.searchTerm) {
      _loadFoods();
    }
  }

  Future<void> _loadFoods() async {
    setState(() => isLoading = true);
    
    try {
      final result = await LocalizedDatabaseService.getFoods(
        searchTerm: widget.searchTerm,
        limit: 50,
      );
      
      setState(() {
        foods = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des aliments: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, child) {
        return Column(
          children: [
            // Header avec indicateur de langue
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Aliments disponibles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      locService.isFrench ? '🇫🇷 FR' : '🇺🇸 EN',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Liste des aliments
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : foods.isEmpty
                      ? Center(
                          child: Text('no_food_found'.tr(locService.currentLanguageCode)),
                        )
                      : ListView.builder(
                          itemCount: foods.length,
                          itemBuilder: (context, index) {
                            final food = foods[index];
                            return _buildFoodItem(food, locService);
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food, LocalizationService locService) {
    // Récupérer le nom et la description dans la langue actuelle
    final suffix = locService.getColumnSuffix();
    final name = food['name$suffix'] ?? 'Nom non disponible';
    final description = food['description$suffix'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              Text(description),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                _buildNutritionBadge('${food['calories_per_100g']} kcal'),
                const SizedBox(width: 8),
                _buildNutritionBadge('P: ${food['proteins_per_100g']}g'),
                const SizedBox(width: 8),
                _buildNutritionBadge('G: ${food['carbs_per_100g']}g'),
                const SizedBox(width: 8),
                _buildNutritionBadge('L: ${food['fats_per_100g']}g'),
              ],
            ),
          ],
        ),
        onTap: () {
          // Action lors du tap sur un aliment
          _showFoodDetails(food, locService);
        },
      ),
    );
  }

  Widget _buildNutritionBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showFoodDetails(Map<String, dynamic> food, LocalizationService locService) {
    final suffix = locService.getColumnSuffix();
    final name = food['name$suffix'] ?? 'Nom non disponible';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'calories_label'.tr(locService.currentLanguageCode)}: ${food['calories_per_100g']} kcal${'per_100g'.tr(locService.currentLanguageCode)}'),
            Text('${'proteins_label'.tr(locService.currentLanguageCode)}: ${food['proteins_per_100g']}g${'per_100g'.tr(locService.currentLanguageCode)}'),
            Text('${'carbs_label'.tr(locService.currentLanguageCode)}: ${food['carbs_per_100g']}g${'per_100g'.tr(locService.currentLanguageCode)}'),
            Text('${'fats_label'.tr(locService.currentLanguageCode)}: ${food['fats_per_100g']}g${'per_100g'.tr(locService.currentLanguageCode)}'),
            const SizedBox(height: 8),
            Text(
              'Langue actuelle: ${locService.isFrench ? "Français" : "English"}',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr(locService.currentLanguageCode)),
          ),
        ],
      ),
    );
  }
}