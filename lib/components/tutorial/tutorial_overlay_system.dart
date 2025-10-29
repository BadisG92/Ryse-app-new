import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../services/translations.dart';

/// Système de tutorial qui affiche une page mockée avec tutorial_coach_mark par-dessus
/// Remplace complètement l'écran actuel pendant le tutorial
class TutorialOverlaySystem {
  TutorialCoachMark? _tutorialCoachMark;
  static ScrollController? _scrollController;

  /// Lance un tutorial avec une page mockée en arrière-plan
  Future<void> showTutorial({
    required BuildContext context,
    required Widget mockPage,
    required List<TargetFocus> targets,
    required VoidCallback onFinish,
    VoidCallback? onSkip,
    ScrollController? scrollController,
  }) async {
    // Stocker le ScrollController pour l'utiliser dans _ensureWidgetVisible
    _scrollController = scrollController;

    // Créer le tutorial avec les targets - avec scroll initial
    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0B132B),
      paddingFocus: 8,
      opacityShadow: 0.8, // Même opacité que la page d'accueil
      alignSkip: Alignment.topRight,
      hideSkip: false,
      textSkip: "Passer",
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      onSkip: () {
        if (onSkip != null) onSkip();
        // Fermer le mockup après skip
        Navigator.of(context).pop();
        return true;
      },
      onFinish: () {
        onFinish();
        // Fermer le mockup après finish
        Navigator.of(context).pop();
      },
    );

    // Afficher la page mockée en plein écran avec le tutorial par-dessus
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _TutorialScreen(
            mockPage: mockPage,
            tutorialCoachMark: _tutorialCoachMark!,
            scrollController: scrollController,
          ),
        ),
      );
    }
  }

  /// Crée un target (élément à mettre en évidence) avec le style de l'app
  static TargetFocus createTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String description,
    ContentAlign align = ContentAlign.bottom,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    double? radius,
    String? avatarPath,
    GlobalKey? nextTargetKey,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      alignSkip: Alignment.topRight,
      enableOverlayTab: true,
      shape: shape,
      radius: radius,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(12),
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
                  // Titre
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bouton "Compris" en bas
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        // Passer au prochain target (lance la transition plein écran)
                        controller.next();

                        // Si on a un prochain target, attendre que la transition plein écran commence
                        // puis scroller pendant que c'est en plein écran
                        if (nextTargetKey != null) {
                          // Attendre que la transition plein écran soit terminée
                          // (~500ms pour tutorial_coach_mark par défaut)
                          await Future.delayed(const Duration(milliseconds: 500));
                          // Vérifier que le widget est toujours monté avant d'utiliser context
                          if (context.mounted) {
                            // Scroller maintenant (pendant que c'est en plein écran)
                            await _ensureWidgetVisible(nextTargetKey, context);
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF0B132B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Compris',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Assure qu'un widget est visible en scrollant si nécessaire
  /// Retourne un Future qui se termine quand le scroll est fini
  /// Version ROBUSTE qui positionne la box EN BAS de l'écran pour que le texte soit visible
  static Future<void> _ensureWidgetVisible(GlobalKey key, BuildContext context) async {
    // Attendre que le prochain frame soit rendu (plus fiable que 50ms hardcodé)
    await Future.delayed(Duration.zero);

    // Vérifier que le context est toujours monté après le délai
    if (!context.mounted) {
      debugPrint('⚠️ Context démonté, annulation du scroll');
      return;
    }

    final currentContext = key.currentContext;
    if (currentContext == null) {
      debugPrint('⚠️ Widget context non trouvé pour le scroll');
      return;
    }

    // Utiliser Scrollable.ensureVisible avec un alignement EN BAS
    // 0.75 = positionne le haut du bloc à 75% du haut de l'écran
    // Résultat : la box est EN BAS avec le texte du tooltip VISIBLE AU-DESSUS
    // Cette méthode gère automatiquement :
    // - Les nested scrollables
    // - Les SliverAppBar qui se collapse
    // - Les calculs de position complexes
    try {
      await Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 400), // Animation smooth
        curve: Curves.easeInOut,
        alignment: 0.75, // Position à 75% = box en bas avec texte visible au-dessus
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );

      // Attendre la fin complète de l'animation + marge de sécurité
      await Future.delayed(const Duration(milliseconds: 450));

      debugPrint('✅ Widget scrollé avec succès (box en bas)');
    } catch (e) {
      debugPrint('⚠️ Erreur lors du scroll: $e');
    }
  }
}

/// Écran qui affiche la page mockée avec le tutorial par-dessus
class _TutorialScreen extends StatefulWidget {
  final Widget mockPage;
  final TutorialCoachMark tutorialCoachMark;
  final ScrollController? scrollController;

  const _TutorialScreen({
    required this.mockPage,
    required this.tutorialCoachMark,
    this.scrollController,
  });

  @override
  State<_TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<_TutorialScreen> {
  @override
  void initState() {
    super.initState();
    // Lancer le tutorial après que la page soit rendue
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Délai supplémentaire pour s'assurer que tout est bien rendu
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        widget.tutorialCoachMark.show(context: context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Afficher simplement la page mockée
    // Le tutorial s'affichera par-dessus automatiquement
    return widget.mockPage;
  }
}
