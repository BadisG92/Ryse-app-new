import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/nutrition_models.dart';
import '../../components/ui/custom_card.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onAddFood;

  const MealCard({
    super.key,
    required this.meal,
    required this.onAddFood,
  });

  @override
  Widget build(BuildContext context) {
    int totalCalories = meal.items.fold(0, (sum, item) => sum + item.calories);
    
    return CustomCard(
      child: Column(
        children: [
          // Header du repas
          Container(
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
                      meal.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      meal.time,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$totalCalories kcal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des aliments
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...meal.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FoodItemWidget(item: item),
                )),
                
                const SizedBox(height: 8),
                
                // Bouton ajouter un aliment
                GestureDetector(
                  onTap: onAddFood,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: Color(0xFF0B132B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ajouter un aliment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                      ],
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
}

class FoodItemWidget extends StatelessWidget {
  final FoodItem item;

  const FoodItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  LucideIcons.moreHorizontal,
                  size: 16,
                  color: Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 