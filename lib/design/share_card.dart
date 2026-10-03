import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import 'logo_draw.dart';
import 'tokens.dart';

/// Ce qui sort de l'application.
///
/// L'app n'avait aucune porte de sortie : `share_plus` était dans le pubspec
/// et personne ne l'appelait. Une carte à partager se construit ici une fois,
/// et chaque carte suivante n'a plus qu'à dessiner son contenu.
///
/// Le rendu se fait hors écran, dans l'overlay, à une taille fixe : les
/// polices embarquées ne se chargent de façon fiable que dans un arbre monté,
/// et une carte qui dépendrait de la largeur du téléphone sortirait
/// différente d'un appareil à l'autre. Le format est celui d'une story,
/// 1080 × 1920, soit 360 × 640 points rendus à 3×.
class RyzeShare {
  RyzeShare._();

  /// Le format story, en points logiques. Rendu à [pixelRatio].
  static const Size story = Size(360, 640);

  /// Le carré, pour un fil.
  static const Size square = Size(360, 360);

  static const double pixelRatio = 3;

  /// Le site qui signe les cartes.
  static const String site = 'coach-ryze.com';

  /// Rend [card] hors écran et rend ses octets PNG, ou nul si l'overlay
  /// manque ou si le rendu échoue.
  static Future<Uint8List?> render(
    BuildContext context, {
    required Widget card,
    Size size = story,
  }) async {
    final overlay = Navigator.maybeOf(context, rootNavigator: true)?.overlay;
    if (overlay == null) return null;

    final key = GlobalKey();
    final media = MediaQuery.of(context).copyWith(
      size: size,
      textScaler: TextScaler.noScaling,
      disableAnimations: true,
    );

    // Hors champ, jamais invisible : un `Opacity(0)` ne peint pas son enfant,
    // et il n'y aurait rien à capturer.
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -size.width * 3,
        top: 0,
        child: IgnorePointer(
          child: MediaQuery(
            data: media,
            child: RepaintBoundary(
              key: key,
              child: SizedBox.fromSize(size: size, child: card),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    try {
      // Deux images : la première pose la mise en page, la seconde la peint.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundary = key.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RyzeShare: rendu impossible : $e');
      return null;
    } finally {
      entry.remove();
    }
  }

  /// Rend [card] et ouvre la feuille de partage du téléphone.
  ///
  /// Rend vrai si la feuille s'est ouverte, faux si la carte n'a pas pu être
  /// rendue. Fermer la feuille sans rien choisir n'est pas un échec.
  static Future<bool> share(
    BuildContext context, {
    required Widget card,
    required String fileName,
    Size size = story,
    String? text,
  }) async {
    final bytes = await render(context, card: card, size: size);
    if (bytes == null) return false;

    // iPad veut savoir d'où part la feuille ; le téléphone s'en moque.
    Rect? origin;
    if (context.mounted) {
      final box = context.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }
    }

    try {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        text: text,
        sharePositionOrigin: origin,
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RyzeShare: partage impossible : $e');
      return false;
    }
  }
}

/// Le sol d'une carte partagée : le papier, sa grille fine et l'auréole
/// chaude, puis la signature en bas. Le même sol que l'application, pour
/// qu'une carte se reconnaisse comme venant d'elle sans qu'on écrive le nom.
class RyzeShareFrame extends StatelessWidget {
  const RyzeShareFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(28, 34, 28, 26),
    this.footer = true,
  });

  final Widget child;
  final EdgeInsets padding;

  /// La marque et le site en bas de carte.
  final bool footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return DecoratedBox(
          decoration: BoxDecoration(gradient: RyzeColors.ground),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -w * 0.35,
                top: -w * 0.45,
                child: Container(
                  width: w * 1.4,
                  height: w * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [RyzeColors.glowWarm.withValues(alpha: 0.34), RyzeColors.glowWarm.withValues(alpha: 0)],
                      stops: const [0, 0.62],
                    ),
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black, Color(0x66000000)],
                  stops: [0, 0.55, 1],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: CustomPaint(
                  painter: RyzeGridPainter(spacing: w * 0.08, color: RyzeColors.text.withValues(alpha: 0.055)),
                ),
              ),
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: child),
                    if (footer) ...[
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RyzeLogoStill(height: 20, color: RyzeColors.ink),
                          const Spacer(),
                          Text(
                            RyzeShare.site,
                            style: TextStyle(
                              fontFamily: 'InstrumentSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontVariations: const [FontVariation('wght', 600), FontVariation('wdth', 100)],
                              color: RyzeColors.mute2,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// La grille fine du sol, en lignes de l'épaisseur d'un trait.
class RyzeGridPainter extends CustomPainter {
  const RyzeGridPainter({required this.spacing, required this.color});

  final double spacing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (spacing <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RyzeGridPainter old) => old.spacing != spacing || old.color != color;
}

/// Une taille de texte fixe, pour les cartes rendues à format constant.
///
/// `RyzeText` mesure en fraction de la largeur d'écran ; une carte partagée a
/// la sienne, et la même d'un appareil à l'autre.
class RyzeShareText {
  RyzeShareText._();

  static TextStyle display(double size, {FontWeight weight = FontWeight.w800, Color? color, double height = 1.04}) =>
      TextStyle(
        fontFamily: 'Archivo',
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', (weight.index + 1) * 100.0), const FontVariation('wdth', 100)],
        color: color ?? RyzeColors.text,
        height: height,
        letterSpacing: size * -0.028,
      );

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color, double height = 1.4}) =>
      TextStyle(
        fontFamily: 'InstrumentSans',
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', (weight.index + 1) * 100.0), const FontVariation('wdth', 100)],
        color: color ?? RyzeColors.text,
        height: height,
      );

  /// Une étiquette en capitales espacées.
  static TextStyle label(double size, {Color? color}) => body(size, weight: FontWeight.w600, color: color ?? RyzeColors.mute, height: 1.2)
      .copyWith(letterSpacing: size * 0.08);
}
