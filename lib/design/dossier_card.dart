import 'package:flutter/material.dart';

import '../ai/dossier.dart';
import '../onboarding/widgets/onb_widgets.dart' show OnbButton;
import 'mark.dart';
import 'share_card.dart';
import 'stamp.dart';
import 'tokens.dart';
import 'type.dart';

/// Les mots de la carte, résolus par l'écran dans la langue du compte. La
/// carte ne lit pas le dictionnaire : comme le reste du mobilier du chat,
/// elle reçoit ses libellés.
class RyzeDossierStrings {
  const RyzeDossierStrings({
    required this.kicker,
    required this.title,
    required this.of,
    required this.facts,
    required this.share,
    required this.fix,
  });

  /// « Dossier », en petites capitales au-dessus du titre.
  final String kicker;

  /// « Ce que Ryze a retenu ».
  final String title;

  /// « de Badis », en ambre à la suite du titre. Vide quand le prénom manque.
  final String of;

  /// « faits retenus. », après le grand nombre.
  final String facts;

  final String share;
  final String fix;
}

/// Le dossier dans le fil de la conversation.
///
/// Une copie d'école : le papier, la grille fine, les faits en lignes à puce
/// ambre, un seul grand nombre, la phrase du coach, et le tampon qui tombe en
/// travers. Puis deux boutons : partager, corriger.
///
/// [animate] vrai quand la carte vient d'arriver : elle se pose, le nombre
/// monte, le tampon claque. Faux pour un dossier relu dans l'historique, qui
/// n'a pas à retomber.
class RyzeDossierCard extends StatefulWidget {
  const RyzeDossierCard({
    super.key,
    required this.dossier,
    required this.strings,
    this.animate = false,
    this.onShare,
    this.onFix,
  });

  final RyzeDossier dossier;
  final RyzeDossierStrings strings;
  final bool animate;
  final VoidCallback? onShare;
  final VoidCallback? onFix;

  @override
  State<RyzeDossierCard> createState() => _RyzeDossierCardState();
}

class _RyzeDossierCardState extends State<RyzeDossierCard> with SingleTickerProviderStateMixin {
  /// Le choc encaissé par la carte quand le tampon touche.
  late final AnimationController _jolt = AnimationController(vsync: this, duration: const Duration(milliseconds: 170));

  @override
  void dispose() {
    _jolt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dossier;
    final s = widget.strings;

    final card = AnimatedBuilder(
      animation: _jolt,
      builder: (context, child) {
        final t = _jolt.value;
        final bump = t == 0 || t == 1 ? 0.0 : (t < 0.5 ? t * 2 : (1 - t) * 2);
        return Transform.translate(
          offset: Offset(0, 2 * bump),
          child: Transform.scale(scale: 1 - 0.006 * bump, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.only(top: context.vw(2.1)),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: RyzeColors.paper,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: RyzeGridPainter(spacing: context.vw(5.6), color: RyzeColors.text.withValues(alpha: 0.05)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(context.vw(4.1)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        s.kicker.toUpperCase(),
                        style: RyzeText.body(context, 2.8, weight: FontWeight.w600, color: RyzeColors.mute, height: 1.2)
                            .copyWith(letterSpacing: context.vw(0.22)),
                      ),
                      const Spacer(),
                      RyzeMark(size: context.vw(3.9), color: RyzeColors.mute2),
                    ],
                  ),
                  SizedBox(height: context.vw(1.3)),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: s.title),
                        if (s.of.isNotEmpty) TextSpan(text: ' ${s.of}', style: TextStyle(color: RyzeColors.accInk)),
                      ],
                    ),
                    style: RyzeText.display(context, 5.4, weight: FontWeight.w800),
                  ),
                  SizedBox(height: context.vw(3.1)),
                  for (final line in d.lines)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.vw(1.8)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: context.vw(2.0),
                            height: context.vw(2.0),
                            margin: EdgeInsets.only(top: context.vw(1.5)),
                            decoration: BoxDecoration(color: RyzeColors.acc, borderRadius: BorderRadius.circular(1)),
                          ),
                          SizedBox(width: context.vw(2.6)),
                          Expanded(child: Text(line, style: RyzeText.body(context, 3.6, height: 1.35))),
                        ],
                      ),
                    ),
                  SizedBox(height: context.vw(2.1)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Count(count: d.count, label: s.facts, animate: widget.animate),
                            if (d.verdict.trim().isNotEmpty) ...[
                              SizedBox(height: context.vw(2.1)),
                              if (d.personaLabel.trim().isNotEmpty)
                                Text(
                                  d.personaLabel.toUpperCase(),
                                  style: RyzeText.body(context, 2.7, weight: FontWeight.w600, color: RyzeColors.mute, height: 1.2)
                                      .copyWith(letterSpacing: context.vw(0.2)),
                                ),
                              SizedBox(height: context.vw(0.5)),
                              Text(d.verdict, style: RyzeText.body(context, 3.5, height: 1.4)),
                            ],
                          ],
                        ),
                      ),
                      // La place du tampon, pour que le verdict ne passe pas dessous.
                      SizedBox(width: context.vw(27)),
                    ],
                  ),
                  SizedBox(height: context.vw(3.6)),
                  Row(
                    children: [
                      Expanded(child: OnbButton(label: s.share, onPressed: widget.onShare)),
                      SizedBox(width: context.vw(2.1)),
                      Expanded(child: OnbButton(label: s.fix, ghost: true, onPressed: widget.onFix)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: context.vw(3.6),
              bottom: context.vw(19.5),
              child: RyzeStampSlam(
                play: widget.animate,
                delay: const Duration(milliseconds: 700),
                onImpact: () {
                  if (mounted) _jolt.forward(from: 0);
                },
                child: RyzeStamp(word: d.stampWord, height: context.vw(10.8)),
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.animate) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
      ),
      child: card,
    );
  }
}

/// Le grand nombre, qui monte depuis zéro quand la carte arrive.
class _Count extends StatelessWidget {
  const _Count({required this.count, required this.label, required this.animate});

  final int count;
  final String label;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : count.toDouble(), end: count.toDouble()),
      duration: animate ? const Duration(milliseconds: 650) : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${v.round()}',
              style: RyzeText.display(context, 8.2, weight: FontWeight.w800).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            TextSpan(text: '  $label', style: RyzeText.body(context, 3.3, weight: FontWeight.w600, color: RyzeColors.mute)),
          ],
        ),
      ),
    );
  }
}

/// Le dossier en carte à partager : la story 9:16, même papier, même tampon,
/// la marque et le site en bas. Rendu hors écran par [RyzeShare].
class RyzeDossierPoster extends StatelessWidget {
  const RyzeDossierPoster({super.key, required this.dossier, required this.strings});

  final RyzeDossier dossier;
  final RyzeDossierStrings strings;

  @override
  Widget build(BuildContext context) {
    final d = dossier;
    final s = strings;
    return RyzeShareFrame(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.kicker.toUpperCase(), style: RyzeShareText.label(11)),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: s.title),
                    if (s.of.isNotEmpty) TextSpan(text: ' ${s.of}', style: TextStyle(color: RyzeColors.accInk)),
                  ],
                ),
                style: RyzeShareText.display(30),
              ),
              const SizedBox(height: 24),
              for (final line in d.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(color: RyzeColors.acc, borderRadius: BorderRadius.circular(1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(line, style: RyzeShareText.body(15.5, height: 1.35))),
                    ],
                  ),
                ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${d.count}',
                          style: RyzeShareText.display(56, height: 0.95).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                        const SizedBox(height: 4),
                        Text(s.facts, style: RyzeShareText.body(13, weight: FontWeight.w600, color: RyzeColors.mute)),
                        if (d.verdict.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          if (d.personaLabel.trim().isNotEmpty) Text(d.personaLabel.toUpperCase(), style: RyzeShareText.label(10.5)),
                          const SizedBox(height: 3),
                          Text(d.verdict, style: RyzeShareText.body(15, height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 112),
                ],
              ),
            ],
          ),
          Positioned(
            right: 6,
            bottom: 86,
            child: RyzeStamp(word: d.stampWord, height: 56),
          ),
        ],
      ),
    );
  }
}
