import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/design.dart';

/// The coach, in the bust and ring of the onboarding, saying one thing and
/// offering one button. The line is typed: three dots, then the sentence
/// wipes in, then the button arrives. When the sentence changes after an
/// action, it is typed again.
class CoachLine extends StatefulWidget {
  const CoachLine({
    super.key,
    required this.text,
    required this.sport,
    required this.cta,
    required this.onCta,
    this.ghost = false,
    this.delay = Duration.zero,
    this.animate = true,
    this.still = false,
  });

  final String text;

  /// The sport coach for a session, the nutrition coach otherwise.
  final bool sport;
  final String cta;
  final VoidCallback onCta;

  /// A secondary button, for when the next step is to look rather than to log.
  final bool ghost;

  /// How long after mounting the typing starts, for the page's entry.
  final Duration delay;

  /// False on a return to the page: the sentence and the button are simply
  /// there. The typing on a change of sentence is kept.
  final bool animate;

  /// Reduce-motion: no floating bust.
  final bool still;

  @override
  State<CoachLine> createState() => _CoachLineState();
}

class _CoachLineState extends State<CoachLine> {
  late bool _typing = widget.animate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _type(widget.delay + const Duration(milliseconds: 620));
  }

  @override
  void didUpdateWidget(CoachLine old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _type(const Duration(milliseconds: 520));
  }

  void _type(Duration wait) {
    _timer?.cancel();
    setState(() => _typing = true);
    _timer = Timer(wait, () {
      if (mounted) setState(() => _typing = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bust = CoachAvatar(widget.sport ? RyzeAssets.sportAvatar : RyzeAssets.nutriAvatar, sizeVw: 11.8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: RyzeDurations.enter,
              switchInCurve: RyzeCurves.out,
              switchOutCurve: RyzeCurves.out,
              child: KeyedSubtree(
                key: ValueKey(widget.sport),
                // the float never stops, so it repaints alone
                child: widget.still ? bust : RepaintBoundary(child: Bob(amplitude: 3, child: bust)),
              ),
            ),
            SizedBox(width: context.vw(3.2)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: context.vw(2.6)),
                // room for two lines so the button rarely moves; a third line
                // pushes it down rather than being cut
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: context.vw(11.2)),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _typing
                        ? Padding(padding: EdgeInsets.only(top: context.vw(1.6)), child: const TypingDots(color: RyzeColors.mute2))
                        : WipeText(widget.text, key: ValueKey(widget.text), style: RyzeText.body(context, 4.1, height: 1.35)),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.vw(2.4)),
        PopIn(
          delay: widget.delay + const Duration(milliseconds: 860),
          dy: 8,
          animate: widget.animate,
          child: AnimatedSwitcher(
            duration: RyzeDurations.enter,
            switchInCurve: RyzeCurves.out,
            switchOutCurve: RyzeCurves.out,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a), child: child),
            ),
            child: OnbButton(key: ValueKey('${widget.cta}|${widget.ghost}'), label: widget.cta, ghost: widget.ghost, onPressed: widget.onCta),
          ),
        ),
      ],
    );
  }
}
