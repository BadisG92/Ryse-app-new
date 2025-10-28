import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/supabase_config.dart';

class RecipeImageService {
  static SupabaseClient get _supabase => SupabaseConfig.client;
  static const String _bucketName = 'recipe_pictures';

  /// Vérifie si une image existe
  /// 
  /// [imageUrl] - L'URL de l'image
  /// Retourne true si l'URL est valide
  static bool hasRecipeImage(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty;
  }


  /// Widget helper pour afficher une image de recette avec fallback
  ///
  /// [imageUrl] - L'URL de l'image de la recette
  /// [width] - Largeur de l'image
  /// [height] - Hauteur de l'image
  /// [fit] - Mode d'ajustement de l'image
  static Widget buildRecipeImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    // Protection contre les valeurs infinies
    final safeWidth = (width != null && width.isFinite) ? width : null;
    final safeHeight = (height != null && height.isFinite) ? height : null;

    if (hasRecipeImage(imageUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: safeWidth,
          height: safeHeight,
          fit: fit,
          // Optimisation mémoire et disque
          memCacheWidth: safeWidth != null ? (safeWidth * 2).toInt() : 800,
          memCacheHeight: safeHeight != null ? (safeHeight * 2).toInt() : 800,
          maxWidthDiskCache: 1000,
          maxHeightDiskCache: 1000,
          // Indicateur de chargement
          placeholder: (context, url) => Container(
            width: safeWidth,
            height: safeHeight,
            color: const Color(0xFFF8F8F8),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0B132B),
              ),
            ),
          ),
          // Gestion des erreurs
          errorWidget: (context, url, error) {
            return _buildFallbackImage(width: safeWidth, height: safeHeight);
          },
        ),
      );
    } else {
      return _buildFallbackImage(width: safeWidth, height: safeHeight);
    }
  }

  /// Widget de fallback quand l'image n'est pas disponible
  static Widget _buildFallbackImage({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 24,
          color: Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}