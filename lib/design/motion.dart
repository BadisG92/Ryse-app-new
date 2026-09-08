import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

export '../components/ui/motion.dart' show PopIn, TypingDots, SlideSwapText;

/// Motion of the system. Three curves and a handful of durations; everything
/// else is a combination of them.
///
/// - `out` is the workhorse: fast start, soft landing. Page slides, fills,
///   the flight of a mark to its day, the odometer.
/// - `spring` overshoots a little: entrances of cards and the pop of a slot
///   taking an impact. Reserved for things that arrive, never for text.
/// - `snap` eases both ends: curtains and chapter cards.
///
/// Rules the onboarding settled:
/// - one orchestrated reveal per screen, not an effect on every element
/// - a fill that the user must read is at least 480 ms, and the screen waits
///   for it (plus a beat) before turning: 780 ms from tap to page change
/// - continuous animations (sheen, pulse, odometer) live in their own
///   repaint boundary
/// - a value that changes mid-animation retargets from where it is; it never
///   restarts from zero
class RyzeCurves {
  RyzeCurves._();

  static const Curve spring = Cubic(0.22, 1.12, 0.3, 1.02);
  static const Curve out = Cubic(0.2, 0.7, 0.2, 1);
  static const Curve snap = Cubic(0.7, 0, 0.2, 1);
}

class RyzeDurations {
  RyzeDurations._();

  /// A control reacting under the finger.
  static const Duration tap = Duration(milliseconds: 220);

  /// An entrance (PopIn) or a mark landing.
  static const Duration enter = Duration(milliseconds: 420);

  /// A fill the user must be able to read (the ink wipe of a choice).
  static const Duration fill = Duration(milliseconds: 480);

  /// The flight of a validated item to its day.
  static const Duration flight = Duration(milliseconds: 620);

  /// From a choice to the next screen: the fill plus a beat.
  static const Duration advance = Duration(milliseconds: 780);

  /// A chapter curtain; a tap skips it.
  static const Duration curtain = Duration(milliseconds: 1700);
}

/// Ce qui vient d'être fait se pose.
///
/// Une coche qui apparaît, un carré qui se remplit : le changement de couleur
/// dit que c'est fait, mais ne se sent pas. Un bref agrandissement à l'instant
/// exact du changement — 12 %, deux dixièmes de seconde, et c'est fini — rend
/// le geste physique. Il tombe avec l'haptique, et c'est cette coïncidence qui
/// fait la sensation, pas l'animation seule.
///
/// Ce n'est pas une fête : rien ne clignote, rien ne reste. Une fête, ça se
/// garde pour ce qui est rare.
class RyzeLanding extends StatefulWidget {
  const RyzeLanding({super.key, required this.on, required this.child, this.amount = 0.12});

  /// L'état de la chose. Le rebond part quand il passe de faux à vrai, et
  /// jamais à la construction : un écran qui s'ouvre sur dix choses déjà
  /// faites ne doit pas les fêter toutes.
  final bool on;

  final Widget child;

  /// L'ampleur du rebond, en fraction de la taille.
  final double amount;

  @override
  State<RyzeLanding> createState() => _RyzeLandingState();
}

class _RyzeLandingState extends State<RyzeLanding> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));

  @override
  void didUpdateWidget(RyzeLanding old) {
    super.didUpdateWidget(old);
    if (widget.on && !old.on) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if ((MediaQuery.maybeDisableAnimationsOf(context) ?? false)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Une bosse : on part de 1, on monte, on revient à 1. Rien ne reste
        // agrandi, donc rien n'a besoin d'être remis en place.
        final t = _c.value;
        final bump = t == 0 || t == 1 ? 0.0 : math.sin(t * math.pi);
        return Transform.scale(scale: 1 + widget.amount * bump, child: child);
      },
      child: widget.child,
    );
  }
}

/// L'onde d'un palier atteint : un anneau d'ambre qui part de la chose et se
/// dissipe, une seule fois.
///
/// C'est la seule fête de l'application, et elle est réservée à ce qui arrive
/// une fois par semaine au plus. Une célébration qui part à chaque geste cesse
/// d'être ressentie en huit jours, et pire : elle retire toute valeur au
/// signal. Celle-ci ne peut pas être déclenchée deux fois pour le même palier.
class RyzeWave extends StatefulWidget {
  const RyzeWave({super.key, required this.play, required this.child});

  /// Passe à vrai une fois, à l'instant où le palier est atteint.
  final bool play;

  final Widget child;

  @override
  State<RyzeWave> createState() => _RyzeWaveState();
}

class _RyzeWaveState extends State<RyzeWave> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.play) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(RyzeWave old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if ((MediaQuery.maybeDisableAnimationsOf(context) ?? false)) return widget.child;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                if (_c.value == 0 || _c.value == 1) return const SizedBox.shrink();
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final offset in const [0.0, 0.28])
                      Builder(
                        builder: (context) {
                          final t = ((_c.value - offset) / (1 - offset)).clamp(0.0, 1.0);
                          if (t <= 0) return const SizedBox.shrink();
                          final eased = Curves.easeOutCubic.transform(t);
                          return Opacity(
                            opacity: (1 - eased) * 0.5,
                            child: Transform.scale(
                              scale: 0.7 + eased * 1.5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: RyzeColors.acc, width: 1.6),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// A control reacting under the finger: it sinks a little while pressed and
/// springs back on release, the way OnbButton does. Wrap anything tappable
/// that is not a button; it is announced as one.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress});

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? 0.975 : 1,
          duration: const Duration(milliseconds: 180),
          curve: RyzeCurves.spring,
          child: widget.child,
        ),
      ),
    );
  }
}
