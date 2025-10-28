import 'package:flutter/material.dart';

/// Bulle de tutorial personnalisée pour Nutrition avec avatar du panda
class NutritionStepBubble extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final bool isLastStep;

  const NutritionStepBubble({
    Key? key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onNext,
    this.onSkip,
    this.isLastStep = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne titre + avatar (avatar en haut à droite, 128x128)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre (limité pour laisser de la place à l'avatar)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),
              ),
              // Avatar du Coach Ryze à droite de la description (128x128)
              SizedBox(
                width: 128,
                height: 128,
                child: Image.asset(
                  'assets/images/coach_ryze_nutrition_avatar.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.restaurant,
                      size: 64,
                      color: Color(0xFF0B132B),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description (limitée pour ne pas aller trop à droite)
          Padding(
            padding: const EdgeInsets.only(right: 140),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Boutons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
