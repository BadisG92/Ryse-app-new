import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TestFilterScreen extends StatefulWidget {
  const TestFilterScreen({super.key});

  @override
  State<TestFilterScreen> createState() => _TestFilterScreenState();
}

class _TestFilterScreenState extends State<TestFilterScreen> {
  Set<String> selectedTags = {};
  
  final List<String> availableTags = [
    'sans gluten',
    'végétarien', 
    'végan',
    'prise de masse',
    'sèche',
    'petit-déjeuner',
    'déjeuner',
    'dîner',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TEST FILTRES'),
      ),
      body: Column(
        children: [
          // Afficher les filtres sélectionnés
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            width: double.infinity,
            child: Text(
              'Sélectionnés: ${selectedTags.isEmpty ? "AUCUN" : selectedTags.join(", ")}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Liste des tags
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableTags.map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  
                  return GestureDetector(
                    onTap: () {
                      debugPrint('CLIC SUR: $tag (actuellement: $isSelected)');
                      setState(() {
                        if (isSelected) {
                          selectedTags.remove(tag);
                          debugPrint('RETRAIT: $tag');
                        } else {
                          selectedTags.add(tag);
                          debugPrint('AJOUT: $tag');
                        }
                        debugPrint('ÉTAT ACTUEL: $selectedTags');
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Bouton pour ouvrir un modal de test
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _TestModal(
                    initialTags: selectedTags,
                    onApply: (newTags) {
                      setState(() {
                        selectedTags = newTags;
                        debugPrint('TAGS APPLIQUÉS DEPUIS MODAL: $selectedTags');
                      });
                    },
                  ),
                );
              },
              child: const Text('OUVRIR MODAL TEST'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestModal extends StatefulWidget {
  final Set<String> initialTags;
  final Function(Set<String>) onApply;
  
  const _TestModal({
    required this.initialTags,
    required this.onApply,
  });

  @override
  State<_TestModal> createState() => _TestModalState();
}

class _TestModalState extends State<_TestModal> {
  late Set<String> tempTags;
  
  final List<String> modalTags = [
    'test1',
    'test2', 
    'test3',
  ];
  
  @override
  void initState() {
    super.initState();
    tempTags = Set<String>.from(widget.initialTags);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('MODAL TEST', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 8,
            children: modalTags.map((tag) {
              final isSelected = tempTags.contains(tag);
              
              return GestureDetector(
                onTap: () {
                  debugPrint('MODAL CLIC: $tag');
                  setState(() {
                    if (isSelected) {
                      tempTags.remove(tag);
                    } else {
                      tempTags.add(tag);
                    }
                    debugPrint('MODAL ÉTAT: $tempTags');
                  });
                },
                child: Chip(
                  label: Text(tag),
                  backgroundColor: isSelected ? Colors.green : Colors.grey[300],
                ),
              );
            }).toList(),
          ),
          
          const Spacer(),
          
          ElevatedButton(
            onPressed: () {
              widget.onApply(tempTags);
              Navigator.pop(context);
            },
            child: const Text('APPLIQUER'),
          ),
        ],
      ),
    );
  }
}