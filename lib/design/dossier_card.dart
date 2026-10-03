import 'dart:async';

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
    this.appName = '',
    this.storeCta = '',
  });

  /// Le nom de la fiche sur le store, celui qu'on tape pour la trouver :
  /// « Ryze : Compteur Calories IA ». Sur la carte partagée seulement.
  final String appName;

  /// « Sur l'App Store », « On Google Play ». Sur la carte partagée seulement.
  final String storeCta;

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

  /// Le tampon attend la phrase du coach pour tomber dessus. S'il ne dit
  /// rien, il tombe quand même, un peu plus tard.
  Timer? _patience;
  bool _patienceOver = false;

  /// Combien de temps on attend la phrase avant de tamponner sans elle.
  static const Duration patience = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.dossier.verdict.trim().isEmpty) {
      _patience = Timer(patience, () {
        if (mounted) setState(() => _patienceOver = true);
      });
    }
  }

  @override
  void dispose() {
    _patience?.cancel();
    _jolt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dossier;
    final s = widget.strings;

    // Le tampon tombe sur la phrase, pas avant elle.
    final waiting = widget.animate && d.verdict.trim().isEmpty && !_patienceOver;

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
                mainAxisSize: MainAxisSize.min,
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
                  SizedBox(height: context.vw(1.6)),
                  // Le chiffre à gauche, le tampon à droite, sur leur ligne à
                  // eux : posé sur la vanne, le tampon la rendait illisible.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _Count(count: d.count, label: s.facts, animate: widget.animate)),
                      RyzeStampSlam(
                        play: widget.animate && !waiting,
                        hidden: waiting,
                        delay: const Duration(milliseconds: 450),
                        onImpact: () {
                          if (mounted) _jolt.forward(from: 0);
                        },
                        child: RyzeStamp(word: d.stampWord, height: context.vw(10.2), angle: -7),
                      ),
                    ],
                  ),
                  // La vanne : la phrase qu'on cite, en grand, sur toute la
                  // largeur, signée du ton du coach.
                  if (d.verdict.trim().isNotEmpty) ...[
                    SizedBox(height: context.vw(2.6)),
                    if (d.personaLabel.trim().isNotEmpty)
                      Text(
                        d.personaLabel.toUpperCase(),
                        style: RyzeText.body(context, 2.7, weight: FontWeight.w600, color: RyzeColors.mute, height: 1.2)
                            .copyWith(letterSpacing: context.vw(0.2)),
                      ),
                    SizedBox(height: context.vw(1.0)),
                    Text(d.verdict, style: RyzeText.display(context, 4.9, weight: FontWeight.w700, height: 1.18)),
                  ],
                  SizedBox(height: context.vw(4.1)),
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
/// et le bandeau de la marque en bas. Rendu hors écran par [RyzeShare].
///
/// Trois étages : les faits, puis le chiffre et le tampon sur une même ligne,
/// puis la vanne en grand, la phrase qu'on cite. Le tampon ne se pose jamais
/// sur la vanne : sur la première version il la recouvrait.
class RyzeDossierPoster extends StatelessWidget {
  const RyzeDossierPoster({super.key, required this.dossier, required this.strings});

  final RyzeDossier dossier;
  final RyzeDossierStrings strings;

  /// Une story se lit en trois secondes : au-delà, les faits ne sont plus lus.
  static const int maxLines = 6;

  /// Le corps des faits : plus petit quand ils sont longs, pour que la vanne
  /// garde sa place.
  static double factSize(List<String> lines) {
    final longest = lines.fold<int>(0, (m, l) => l.length > m ? l.length : m);
    final total = lines.fold<int>(0, (m, l) => m + l.length);
    if (total > 240 || longest > 52) return 14;
    if (total > 170 || longest > 40) return 15;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    final d = dossier;
    final s = strings;
    final lines = d.lines.take(maxLines).toList();
    final size = factSize(lines);

    final facts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.62),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  margin: EdgeInsets.only(top: size * 0.42),
                  decoration: BoxDecoration(color: RyzeColors.acc, borderRadius: BorderRadius.circular(1)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(line, style: RyzeShareText.body(size, height: 1.32))),
              ],
            ),
          ),
      ],
    );

    return RyzeShareFrame(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 22),
      footer: RyzeShareBrand(title: s.appName, cta: s.storeCta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Le haut prend la place libre : un dossier court laisse son vide
          // au milieu, et la vanne reste ancrée au-dessus du bandeau.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.kicker.toUpperCase(), style: RyzeShareText.label(11)),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: s.title),
                      if (s.of.isNotEmpty) TextSpan(text: ' ${s.of}', style: TextStyle(color: RyzeColors.accInk)),
                    ],
                  ),
                  style: RyzeShareText.display(29),
                ),
                const SizedBox(height: 20),
                // Les faits prennent ce qui reste ; s'ils débordent malgré
                // tout, ils se réduisent seuls, jamais la vanne ni le tampon.
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, box) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: box.maxWidth, child: facts),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${d.count}',
                      style: RyzeShareText.display(54, height: 0.95).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    const SizedBox(height: 4),
                    Text(s.facts, style: RyzeShareText.body(13, weight: FontWeight.w600, color: RyzeColors.mute)),
                  ],
                ),
              ),
              RyzeStamp(word: d.stampWord, height: 52, angle: -7),
            ],
          ),
          if (d.verdict.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            if (d.personaLabel.trim().isNotEmpty) Text(d.personaLabel.toUpperCase(), style: RyzeShareText.label(10.5)),
            const SizedBox(height: 5),
            Text(
              d.verdict,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: RyzeShareText.display(d.verdict.length > 90 ? 19 : 22, weight: FontWeight.w700, height: 1.16),
            ),
          ],
        ],
      ),
    );
  }
}
