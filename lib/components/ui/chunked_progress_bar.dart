import 'package:flutter/material.dart';

/// Widget de barre de progression par paliers (chunks)
/// Chaque palier correspond à un nombre de kcal défini (par défaut 500)
/// La couleur s'assombrit progressivement avec chaque palier franchi
class ChunkedProgressBar extends StatelessWidget {
  final int currentKcal;
  final int chunkSize;
  final double height;
  final double borderRadius;
  final bool animate;

  const ChunkedProgressBar({
    Key? key,
    required this.currentKcal,
    this.chunkSize = 500,
    this.height = 12.0,
    this.borderRadius = 12.0,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return _buildStaticBar();
    }

    // Animation avec TweenAnimationBuilder comme dans la nutrition
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: currentKcal.toDouble(),
      ),
      duration: const Duration(milliseconds: 1000), // Même durée que nutrition
      curve: Curves.easeOutExpo, // Même courbe que nutrition
      builder: (context, animatedValue, _) {
        return _buildProgressBar(animatedValue.round());
      },
    );
  }

  Widget _buildStaticBar() {
    return _buildProgressBar(currentKcal);
  }

  Widget _buildProgressBar(int kcalValue) {
    // Calculs des paliers pour la valeur animée
    final completedChunks = (kcalValue / chunkSize).floor();
    final currentChunkProgress = (kcalValue % chunkSize) / chunkSize;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: const Color(0xFFF8F8F8), // Base grise comme dans l'app
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Paliers complets
            ...List.generate(completedChunks, (index) {
              return _buildChunkLayer(
                progress: 1.0,
                opacity: _calculateChunkOpacity(index + 1),
              );
            }),
            
            // Palier partiel (en cours) - celui qui s'anime
            if (currentChunkProgress > 0)
              _buildChunkLayer(
                progress: currentChunkProgress,
                opacity: _calculateChunkOpacity(completedChunks + 1),
              ),
          ],
        ),
      ),
    );
  }

  /// Construit une couche de palier
  Widget _buildChunkLayer({
    required double progress,
    required double opacity,
  }) {
    return FractionallySizedBox(
      widthFactor: progress,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B).withOpacity(opacity), // Bleu de l'app
        ),
      ),
    );
  }

  /// Calcule l'opacité pour un palier donné
  /// Plus le palier est élevé, plus la couleur est opaque (effet de superposition)
  double _calculateChunkOpacity(int chunkNumber) {
    // Base opacity + increment per chunk
    // Commence à 0.2 et augmente de 0.15 par palier, plafonné à 1.0
    final baseOpacity = 0.2;
    final increment = 0.15;
    final opacity = baseOpacity + (increment * (chunkNumber - 1));
    
    return opacity.clamp(0.2, 1.0);
  }

  /// Calcule le nombre de kcal restantes pour le prochain palier
  int get kcalToNextChunk {
    if (currentKcal == 0) return chunkSize;
    
    final remainder = currentKcal % chunkSize;
    return remainder == 0 ? 0 : chunkSize - remainder;
  }

  /// Calcule le nombre de paliers franchis
  int get completedChunks => (currentKcal / chunkSize).floor();


}


