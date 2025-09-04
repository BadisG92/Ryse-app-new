import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class RecipeImageService {
  static final SupabaseClient _supabase = SupabaseConfig.client;
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
    if (hasRecipeImage(imageUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: const Color(0xFFF8F8F8),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0B132B),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage(width: width, height: height);
          },
        ),
      );
    } else {
      return _buildFallbackImage(width: width, height: height);
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