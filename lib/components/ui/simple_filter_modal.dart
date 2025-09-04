import 'package:flutter/material.dart';
import 'recipe_models.dart';

class SimpleFilterModal extends StatefulWidget {
  final Map<String, Set<String>> initialFilters;
  final Function(Map<String, Set<String>>) onApply;

  const SimpleFilterModal({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<SimpleFilterModal> createState() => _SimpleFilterModalState();
}

class _SimpleFilterModalState extends State<SimpleFilterModal> {
  late Map<String, Set<String>> selectedFilters;

  @override
  void initState() {
    super.initState();
    print('🔵 MODAL INIT STATE');
    print('🔵 Initial filters from parent: ${widget.initialFilters}');
    
    // Copier les filtres initiaux
    selectedFilters = {};
    for (var entry in widget.initialFilters.entries) {
      selectedFilters[entry.key] = Set<String>.from(entry.value);
    }
    print('🔵 Local selectedFilters copy: $selectedFilters');
  }

  void _toggleFilter(String category, String option) {
    print('🔴 _toggleFilter CALLED: category=$category, option=$option');
    print('🔴 BEFORE setState: selectedFilters=$selectedFilters');
    
    setState(() {
      selectedFilters[category] ??= <String>{};
      
      if (selectedFilters[category]!.contains(option)) {
        selectedFilters[category]!.remove(option);
        print('🔴 REMOVED: $option from $category');
      } else {
        selectedFilters[category]!.add(option);
        print('🔴 ADDED: $option to $category');
      }
    });
    
    print('🔴 AFTER setState: selectedFilters=$selectedFilters');
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer les filtres disponibles
    final availableFilters = RecipeFilters.advancedFilters;
    
    print('🔴 MODAL BUILD: availableFilters = $availableFilters');
    print('🔴 MODAL BUILD: selectedFilters = $selectedFilters');
    
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
          Padding(
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
                      selectedFilters.forEach((key, value) {
                        value.clear();
                      });
                    });
                  },
                  child: const Text('Effacer tout'),
                ),
              ],
            ),
          ),
          
          // Filters
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: availableFilters.length,
              itemBuilder: (context, index) {
                final category = availableFilters.keys.elementAt(index);
                final categoryData = availableFilters[category]!;
                // Les options sont dans la première valeur du Map interne
                final options = categoryData.values.first;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
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
                      children: options.map((option) {
                        final isSelected = selectedFilters[category]?.contains(option) ?? false;
                        
                        print('🟣 Building tag: $option, isSelected=$isSelected');
                        
                        return InkWell(
                          onTap: () {
                            print('🔥 INKWELL TAP DETECTED: $option in $category');
                            print('🔥 Current isSelected: $isSelected');
                            _toggleFilter(category, option);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF0B132B) 
                                  : const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF0B132B) 
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              option,
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
              },
            ),
          ),
          
          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFF8F8F8),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print('🚀 APPLYING FILTERS: $selectedFilters');
                  widget.onApply(selectedFilters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Valider (${selectedFilters.values.fold(0, (sum, set) => sum + set.length)})',
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