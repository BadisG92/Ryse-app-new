import 'package:flutter/material.dart';

/// Composant réutilisable pour une scrollbar personnalisée avec le thème de l'app
/// 
/// Utilisation:
/// ```dart
/// CustomScrollbar(
///   child: SingleChildScrollView(
///     child: // votre contenu scrollable
///   ),
/// )
/// ```
class CustomScrollbar extends StatelessWidget {
  final Widget child;
  final bool showScrollbar;
  
  const CustomScrollbar({
    Key? key,
    required this.child,
    this.showScrollbar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showScrollbar) return child;
    
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        // Couleur du thumb (partie mobile) - bleu principal de l'app avec transparence
        thumbColor: WidgetStateProperty.all(const Color(0xFF0B132B).withOpacity(0.6)),
        // Couleur de la track (arrière-plan) - gris clair avec transparence
        trackColor: WidgetStateProperty.all(const Color(0xFFE2E8F0).withOpacity(0.3)),
        // Épaisseur fine et élégante
        thickness: WidgetStateProperty.all(4),
        // Bords arrondis
        radius: const Radius.circular(2),
        // Marges pour un aspect aéré
        crossAxisMargin: 8,
        mainAxisMargin: 8,
      ),
      child: Scrollbar(
        thickness: 4,
        radius: const Radius.circular(2),
        thumbVisibility: true,
        trackVisibility: false,
        child: child,
      ),
    );
  }
} 
