import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import 'arc_state.dart';

/// Les 90 carrés.
///
/// L'ambre est ce que Ryze rend : une journée tenue se remplit d'ambre, plus
/// foncé quand elle a eu sa séance. Un jour sauvé par un joker est un jour de
/// gel, pâle, avec son flocon. Aujourd'hui est la case à faire, blanche au
/// bord d'encre, comme toute chose prévue dans l'app. Le reste est libre.
class ArcGrid extends StatelessWidget {
  const ArcGrid({
    super.key,
    required this.cells,
    this.columns = 10,
    this.gapFraction = 0.28,
    this.reveal,
    this.todayFirst = true,
  });

  /// La série, du premier jour à aujourd'hui.
  final List<ArcCell> cells;

  final int columns;

  /// L'espace entre deux carrés, en fraction d'un carré.
  final double gapFraction;

  /// L'index d'une case qui se remplit sous les yeux (la journée d'hier, le
  /// matin) ; null pour une grille posée.
  final int? reveal;

  /// Sans série, la première case est aujourd'hui, à faire. Faux avant
  /// l'ouverture de la saison : rien n'est encore à faire.
  final bool todayFirst;

  @override
  Widget build(BuildContext context) {
    final rows = (ArcSeason.length / columns).ceil();
    return LayoutBuilder(
      builder: (context, box) {
        // Un demi-point de marge : la somme des flottants ne doit jamais
        // dépasser la largeur, sinon la ligne déborde d'un cheveu.
        final size = (box.maxWidth - 0.5) / (columns + (columns - 1) * gapFraction);
        final gap = size * gapFraction;
        // Des lignes explicites plutôt qu'un Wrap : dix cases et neuf
        // espaces tombent pile sur la largeur, et un arrondi de trop
        // renverrait la dixième à la ligne.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) SizedBox(height: gap),
              Row(
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) SizedBox(width: gap),
                    if (r * columns + c < ArcSeason.length)
                      SizedBox.square(
                        dimension: size,
                        child: r * columns + c == reveal ? _Reveal(child: _cell(r * columns + c, size)) : _cell(r * columns + c, size),
                      )
                    else
                      SizedBox.square(dimension: size),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _cell(int i, double size) {
    final radius = BorderRadius.circular(size * 0.24);
    final cell = i < cells.length ? cells[i] : (cells.isEmpty && todayFirst && i == 0 ? ArcCell.pending : null);
    switch (cell) {
      case ArcCell.held:
        return DecoratedBox(decoration: BoxDecoration(color: RyzeColors.acc, borderRadius: radius));
      case ArcCell.trained:
        return DecoratedBox(decoration: BoxDecoration(color: RyzeColors.accDeep, borderRadius: radius));
      case ArcCell.joker:
        return DecoratedBox(
          decoration: BoxDecoration(color: RyzeColors.accTint, borderRadius: radius),
          child: size >= 14 ? Center(child: Icon(LucideIcons.snowflake, size: size * 0.6, color: RyzeColors.accInk)) : null,
        );
      case ArcCell.pending:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: radius,
            border: Border.all(color: RyzeColors.ink, width: size >= 14 ? 1.4 : 1),
          ),
        );
      case null:
        return DecoratedBox(decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: radius));
    }
  }
}

/// Une case qui passe du libre à sa couleur, avec un petit rebond.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.child});

  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: RyzeDurations.fill);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 520), () {
      if (!mounted) return;
      _c.forward();
      RyzeFeedback.success();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = RyzeCurves.spring.transform(_c.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(4))),
            Transform.scale(scale: 0.4 + 0.6 * t, child: Opacity(opacity: _c.value.clamp(0.0, 1.0), child: child)),
          ],
        );
      },
      child: widget.child,
    );
  }
}
