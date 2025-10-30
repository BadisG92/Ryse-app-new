import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/nutrition_models.dart';
import '../../components/ui/custom_card.dart';
import '../../services/food_entries_service.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
class MealCard extends StatefulWidget {
  final Meal meal;
  final VoidCallback onAddFood;
  final VoidCallback? onFoodRemoved; // Callback pour notifier la suppression

  const MealCard({
    super.key,
    required this.meal,
    required this.onAddFood,
    this.onFoodRemoved,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool isExpanded = false; // Par défaut, le repas est replié

  @override
  Widget build(BuildContext context) {
    int totalCalories = widget.meal.items.fold(0, (sum, item) => sum + item.calories);
    
    return CustomCard(
      child: Column(
        children: [
          // Header du repas (toujours visible)
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFF8F8F8),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        widget.meal.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                        widget.meal.time,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                  Row(
                    children: [
                Text(
                  '$totalCalories kcal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
              ],
              ),
            ),
          ),
          
          // Liste des aliments (masquable)
          if (isExpanded)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                  ...widget.meal.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                    child: FoodItemWidget(
                      item: item,
                      onRemove: () => _showDeleteConfirmation(item),
                    ),
                )),
                
                const SizedBox(height: 8),
                
                // Bouton ajouter un aliment
                GestureDetector(
                    onTap: widget.onAddFood,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    child: Consumer<LocalizationService>(
                      builder: (context, localizationService, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.plus,
                              size: 16,
                              color: Color(0xFF0B132B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'add_food'.tr(localizationService.currentLanguageCode),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0B132B),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(FoodItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Icône de suppression
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    LucideIcons.trash2,
                    size: 28,
                    color: Colors.red[600],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Titre
                const Text(
                  'Supprimer l\'aliment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Message de confirmation
                Text(
                  'Êtes-vous sûr de vouloir supprimer "${item.name}" de ce repas ?',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Boutons
                Row(
                  children: [
                    // Bouton Annuler
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Bouton Supprimer
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _removeFood(item);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeFood(FoodItem item) async {
    try {
      debugPrint('🗑️ Début suppression de: ${item.name} (ID: ${item.id})');
      
      // Vérifier que l'item a un ID
      if (item.id == null || item.id!.isEmpty) {
        throw Exception('L\'aliment "${item.name}" n\'a pas d\'identifiant valide');
      }
      
      // Supprimer l'aliment de la base de données
      final success = await FoodEntriesService.removeFoodEntry(item.id!);
      
      if (!success) {
        throw Exception('La suppression a échoué');
      }
      
      debugPrint('✅ Suppression réussie de: ${item.name}');
      
      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} supprimé du repas'),
            backgroundColor: const Color(0xFF0B132B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Notifier le parent qu'un aliment a été supprimé pour recharger les données
      if (widget.onFoodRemoved != null) {
        widget.onFoodRemoved!();
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de ${item.name}: $e');
      
      // Afficher une erreur si la suppression échoue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_delete_failed'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class FoodItemWidget extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onRemove;

  const FoodItemWidget({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Icône personnalisée ou espace réservé selon les nouvelles règles
                item.shouldShowCustomIcon
                  ? Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        item.displayIcon, // Utiliser la nouvelle méthode displayIcon
                        size: 12,
                        color: const Color(0xFF0B132B),
                      ),
                    )
                  : const SizedBox(width: 12),
                
                const SizedBox(width: 6),
                
                // Contenu texte (couleurs normales, plus de bleu)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        item.portion,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                '${item.calories} kcal',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0B132B),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton croix pour supprimer
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    LucideIcons.x,
                    size: 16,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 
