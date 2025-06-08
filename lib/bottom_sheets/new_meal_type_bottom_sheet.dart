import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NewMealTypeBottomSheet {
  static void show(
    BuildContext context, {
    required Function(String mealType, String time) onMealTypeSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
              
              // Title
              const Text(
                'Créer un nouveau repas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Choisissez le type de repas',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Options de repas
              _buildMealOption(
                context,
                title: 'Petit-déjeuner',
                description: 'Repas du matin',
                icon: LucideIcons.sunrise,
                onTap: () {
                  Navigator.pop(context);
                  onMealTypeSelected('Petit-déjeuner', '08:00');
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildMealOption(
                context,
                title: 'Déjeuner',
                description: 'Repas du midi',
                icon: LucideIcons.sun,
                onTap: () {
                  Navigator.pop(context);
                  onMealTypeSelected('Déjeuner', '12:30');
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildMealOption(
                context,
                title: 'Collation',
                description: 'En-cas entre les repas',
                icon: LucideIcons.milk,
                onTap: () {
                  Navigator.pop(context);
                  onMealTypeSelected('Collation', '16:00');
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildMealOption(
                context,
                title: 'Dîner',
                description: 'Repas du soir',
                icon: LucideIcons.sunset,
                onTap: () {
                  Navigator.pop(context);
                  onMealTypeSelected('Dîner', '19:30');
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMealOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
} 