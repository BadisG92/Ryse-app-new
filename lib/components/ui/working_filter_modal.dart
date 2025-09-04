import 'package:flutter/material.dart';
import 'recipe_models.dart';

class WorkingFilterModal extends StatefulWidget {
  final Map<String, Set<String>> currentFilters;
  final Function(Map<String, Set<String>>) onFiltersChanged;

  const WorkingFilterModal({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<WorkingFilterModal> createState() => _WorkingFilterModalState();
}

class _WorkingFilterModalState extends State<WorkingFilterModal> {
  late Map<String, Set<String>> localFilters;

  @override
  void initState() {
    super.initState();
    print('💚 WORKING MODAL: initState');
    
    // Copier les filtres actuels
    localFilters = {};
    widget.currentFilters.forEach((key, value) {
      localFilters[key] = Set<String>.from(value);
    });
    
    print('💚 localFilters initialisé: $localFilters');
  }

  void _toggleTag(String category, String tag) {
    print('💚 _toggleTag: $tag dans $category');
    setState(() {
      localFilters[category] ??= <String>{};
      
      if (localFilters[category]!.contains(tag)) {
        localFilters[category]!.remove(tag);
        print('💚 RETIRÉ: $tag');
      } else {
        localFilters[category]!.add(tag);
        print('💚 AJOUTÉ: $tag');
      }
    });
    print('💚 État local: $localFilters');
  }

  @override
  Widget build(BuildContext context) {
    print('💚 BUILD modal avec RecipeFilters.advancedFilters');
    final availableFilters = RecipeFilters.advancedFilters;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCCCCCC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      localFilters.forEach((key, value) => value.clear());
                    });
                  },
                  child: const Text('Effacer tout'),
                ),
              ],
            ),
          ),
          
          // Liste des catégories et tags
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: availableFilters.entries.map((categoryEntry) {
                  final categoryName = categoryEntry.key;
                  final categoryData = categoryEntry.value;
                  // Les tags sont dans la première (et unique) valeur
                  final tags = categoryData.values.first;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map<Widget>((tag) {
                          final isSelected = localFilters[categoryName]?.contains(tag) ?? false;
                          
                          return GestureDetector(
                            onTap: () {
                              print('💚 GestureDetector tap: $tag');
                              _toggleTag(categoryName, tag);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Bouton Valider
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print('💚 VALIDER pressed, applying: $localFilters');
                  widget.onFiltersChanged(localFilters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Valider (${localFilters.values.fold(0, (sum, set) => sum + set.length)})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}