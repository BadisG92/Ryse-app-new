import 'package:flutter/material.dart';

/// Types d'avatar Coach Ryze
enum CoachRyzeAvatarType {
  workout,    // Panda coach sport
  nutrition,  // Panda docteur nutrition
}

/// Tailles prédéfinies pour l'avatar Coach Ryze
enum CoachRyzeAvatarSize {
  small,    // 32px - Pour badges, chips
  medium,   // 64px - Pour headers, cartes
  large,    // 96px - Pour pages principales
  xlarge,   // 128px - Pour splash, onboarding
  xxlarge,  // 160px - Pour header principal
  xxxlarge  // 180px - Pour panda docteur (compense la blouse blanche)
}

/// Widget réutilisable pour afficher l'avatar Coach Ryze de manière optimisée
class CoachRyzeAvatar extends StatelessWidget {
  /// Type d'avatar à afficher
  final CoachRyzeAvatarType type;

  /// Taille de l'avatar
  final CoachRyzeAvatarSize size;

  /// Afficher une ombre portée
  final bool withShadow;

  /// Afficher une bordure
  final bool withBorder;

  const CoachRyzeAvatar({
    Key? key,
    this.type = CoachRyzeAvatarType.workout,
    this.size = CoachRyzeAvatarSize.medium,
    this.withShadow = true,
    this.withBorder = false,
  }) : super(key: key);

  /// Convertit la taille enum en pixels
  double get _size {
    switch (size) {
      case CoachRyzeAvatarSize.small:
        return 32;
      case CoachRyzeAvatarSize.medium:
        return 64;
      case CoachRyzeAvatarSize.large:
        return 96;
      case CoachRyzeAvatarSize.xlarge:
        return 128;
      case CoachRyzeAvatarSize.xxlarge:
        return 160;
      case CoachRyzeAvatarSize.xxxlarge:
        return 180;
    }
  }

  /// Retourne le chemin de l'image selon le type
  String get _imagePath {
    switch (type) {
      case CoachRyzeAvatarType.workout:
        return 'assets/images/coach_ryze_workout_avatar.png';
      case CoachRyzeAvatarType.nutrition:
        return 'assets/images/coach_ryze_nutrition_avatar.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _imagePath,
      width: _size,
      height: _size,
      fit: BoxFit.contain,
      // Optimisation : limite la résolution en cache
      // 2x pour écrans haute densité (Retina, etc.)
      cacheWidth: (_size * 2).toInt(),
      // Bon compromis entre qualité et performance
      filterQuality: FilterQuality.medium,
      // Fallback en cas d'erreur de chargement
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.account_circle,
          color: const Color(0xFF64748B),
          size: _size,
        );
      },
    );
  }
}
