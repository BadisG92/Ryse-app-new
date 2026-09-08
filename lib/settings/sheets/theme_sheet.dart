import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../design/palette.dart';
import '../../services/localization_service.dart';
import '../../services/theme_service.dart';
import '../../services/translations.dart';

/// Les cinq habits, essayés sur place.
///
/// Chaque rangée se dessine dans **sa propre** palette et non dans celle en
/// vigueur : on voit ce qu'on choisit avant de le choisir. Un aperçu qui
/// emprunterait les couleurs courantes ne montrerait rien.
class ThemeSheet {
  ThemeSheet._();

  static Future<void> show(BuildContext context, {required String lang}) {
    return showRyzeSheet<void>(
      context,
      title: 'settings_theme'.tr(lang),
      subtitle: 'settings_theme_hint'.tr(lang),
      builder: (sheet) => const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguageCode;
    final current = RyzeColors.palette.key;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in RyzePalettes.all)
          Padding(
            padding: EdgeInsets.only(bottom: context.vw(2.6)),
            child: _Row(
              palette: p,
              label: p.key.tr(lang),
              selected: p.key == current,
              onTap: () async {
                await ThemeService.instance.choose(p);
                if (mounted) setState(() {});
              },
            ),
          ),
      ],
    );
  }
}

/// Une palette : son nom, ses deux couleurs en pastilles, et l'état choisi.
class _Row extends StatelessWidget {
  const _Row({required this.palette, required this.label, required this.selected, required this.onTap});

  final RyzePalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        RyzeFeedback.select();
        onTap();
      },
      child: AnimatedContainer(
        duration: RyzeDurations.tap,
        curve: RyzeCurves.out,
        padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.6)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          // Le liseré de la ligne choisie est celui de *sa* palette, pas de
          // celle en vigueur : les deux sont la même à cet instant, mais la
          // règle reste vraie si l'aperçu sert un jour ailleurs.
          border: Border.all(
            color: selected ? palette.ink : RyzeColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            // Le primaire, et le secondaire dessus : c'est exactement ce que
            // l'application fera de ces deux couleurs.
            SizedBox(
              width: context.vw(13),
              height: context.vw(9.2),
              child: Stack(
                children: [
                  Container(
                    width: context.vw(9.2),
                    height: context.vw(9.2),
                    decoration: BoxDecoration(color: palette.ink, shape: BoxShape.circle),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: context.vw(6.2),
                      height: context.vw(6.2),
                      decoration: BoxDecoration(
                        color: palette.acc,
                        shape: BoxShape.circle,
                        border: Border.all(color: RyzeColors.surf, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.vw(3.1)),
            Expanded(
              child: Text(label, style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
            ),
            AnimatedScale(
              duration: RyzeDurations.enter,
              curve: RyzeCurves.spring,
              scale: selected ? 1 : 0,
              child: Container(
                width: context.vw(6.2),
                height: context.vw(6.2),
                decoration: BoxDecoration(color: palette.ink, shape: BoxShape.circle),
                child: Icon(LucideIcons.check, size: context.vw(3.6), color: RyzeColors.surf),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
