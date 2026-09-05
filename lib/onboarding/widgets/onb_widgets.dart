import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../onboarding_theme.dart';

/// Staggered entrance: fade + rise + slight scale, spring curve.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 550),
    this.dy = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double dy;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: OnbCurves.spring);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) {
        final t = _a.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.dy),
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Headline revealed by a left-to-right wipe with an amber bar at the front.
class WipeText extends StatefulWidget {
  const WipeText(this.text, {super.key, required this.style, this.delay = const Duration(milliseconds: 80), this.textAlign = TextAlign.left});

  final String text;
  final TextStyle style;
  final Duration delay;
  final TextAlign textAlign;

  @override
  State<WipeText> createState() => _WipeTextState();
}

class _WipeTextState extends State<WipeText> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: OnbCurves.snap);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _a,
          builder: (context, _) {
            final t = _a.value.clamp(0.0, 1.0);
            return Stack(
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: t == 0 ? 0.001 : t,
                    child: SizedBox(
                      width: width,
                      child: Text(widget.text, style: widget.style, textAlign: widget.textAlign),
                    ),
                  ),
                ),
                if (t < 1)
                  Positioned(
                    left: (width * t - 2).clamp(0.0, width - 3),
                    top: 0,
                    bottom: 0,
                    child: Container(width: 3, decoration: BoxDecoration(color: OnbColors.acc, borderRadius: BorderRadius.circular(2))),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Words appearing one after the other, for the coach tone preview.
class WordStream extends StatelessWidget {
  const WordStream(this.text, {super.key, required this.style, this.stepMs = 38});

  final String text;
  final TextStyle style;
  final int stepMs;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return Wrap(
      spacing: style.fontSize! * 0.28,
      runSpacing: 2,
      children: [
        for (var i = 0; i < words.length; i++)
          PopIn(
            key: ValueKey('$i-${words[i]}'),
            delay: Duration(milliseconds: i * stepMs),
            duration: const Duration(milliseconds: 400),
            dy: 6,
            child: Text(words[i], style: style),
          ),
      ],
    );
  }
}

/// Primary pill button. `gold` is reserved for the single trial button and
/// carries the periodic sheen of the prototype.
class OnbButton extends StatefulWidget {
  const OnbButton({super.key, required this.label, this.onPressed, this.gold = false, this.ghost = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool gold;
  final bool ghost;
  final IconData? icon;

  @override
  State<OnbButton> createState() => _OnbButtonState();
}

class _OnbButtonState extends State<OnbButton> with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));

  @override
  void initState() {
    super.initState();
    if (widget.gold) _sheen.repeat();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final Color bg = widget.ghost ? OnbColors.surf : (widget.gold ? OnbColors.acc : OnbColors.ink);
    final Color fg = widget.ghost ? OnbColors.ink : (widget.gold ? OnbColors.onAcc : Colors.white);

    final pill = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.vw(14)),
      padding: EdgeInsets.symmetric(horizontal: context.vw(6), vertical: context.vw(3.6)),
      decoration: BoxDecoration(
        gradient: widget.gold
            ? const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [OnbColors.accLight, OnbColors.acc, OnbColors.accDeep], stops: [0, 0.6, 1])
            : null,
        color: widget.gold ? null : bg,
        borderRadius: BorderRadius.circular(999),
        border: widget.ghost ? Border.all(color: OnbColors.line) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[Icon(widget.icon, size: context.vw(4.4), color: fg), SizedBox(width: context.vw(2))],
          Flexible(child: Text(widget.label, style: OnbText.body(context, 4.3, weight: FontWeight.w600, color: fg, height: 1.2), textAlign: TextAlign.center)),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 180),
        curve: OnbCurves.spring,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.28,
          duration: const Duration(milliseconds: 250),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                if (!widget.ghost)
                  BoxShadow(
                    color: (widget.gold ? OnbColors.acc : OnbColors.ink).withValues(alpha: widget.gold ? 0.45 : 0.35),
                    blurRadius: context.vw(4),
                    offset: Offset(0, context.vw(1.4)),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  pill,
                  if (widget.gold)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _sheen,
                          builder: (context, _) {
                            final p = (_sheen.value / 0.16).clamp(0.0, 1.0);
                            return FractionalTranslation(
                              translation: Offset(-1.2 + 2.4 * p, 0),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.skewX(-0.4),
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [Color(0x00FFFFFF), Color(0x48FFFFFF), Color(0x00FFFFFF)], stops: [0.3, 0.5, 0.7]),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back button + four chapter progress segments + chapter label.
class OnbTopBar extends StatelessWidget {
  const OnbTopBar({super.key, required this.fills, required this.chapter, required this.label, this.onBack, this.showProgress = true});

  /// Fill fraction per chapter (0..1), four entries.
  final List<double> fills;
  final int chapter;
  final String label;
  final VoidCallback? onBack;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final size = context.vw(9);
    return SizedBox(
      height: size,
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: OnbColors.surf,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.06), blurRadius: context.vw(2.4), offset: Offset(0, context.vw(0.8)))],
                  border: Border.all(color: OnbColors.line),
                ),
                child: Icon(LucideIcons.chevronLeft, size: context.vw(4.4), color: OnbColors.ink),
              ),
            )
          else
            SizedBox(width: size),
          SizedBox(width: context.vw(3)),
          Expanded(
            child: Visibility(
              visible: showProgress,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Row(
                children: [
                  for (var i = 0; i < fills.length; i++) ...[
                    if (i > 0) SizedBox(width: context.vw(1.4)),
                    Expanded(
                      child: Container(
                        height: context.vw(1),
                        decoration: BoxDecoration(color: OnbColors.ink.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(2)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 600),
                            curve: OnbCurves.out,
                            widthFactor: fills[i].clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: chapter > i + 1 ? OnbColors.ink : OnbColors.acc,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: context.vw(3)),
          // intrinsic width: "Ton pourquoi  2/3" must never wrap inside the 9vw bar
          Flexible(
            child: Text(
              showProgress ? label : '',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: OnbText.body(context, 3.1, weight: FontWeight.w600, color: OnbColors.mute, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

enum OnbCoach { sport, nutri, duo }

class CoachAvatar extends StatelessWidget {
  const CoachAvatar(this.asset, {super.key, this.sizeVw = 9.6, this.dim = false});
  final String asset;
  final double sizeVw;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final s = context.vw(sizeVw);
    Widget img = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: const Color(0xFFDFE4F2),
        shape: BoxShape.circle,
        border: Border.all(color: OnbColors.surf, width: 2),
        boxShadow: [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.12), blurRadius: context.vw(2.4), offset: Offset(0, context.vw(1)))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(asset, fit: BoxFit.cover, alignment: const Alignment(0, -0.6)),
    );
    if (dim) img = Opacity(opacity: 0.55, child: ColorFiltered(colorFilter: const ColorFilter.mode(Color(0x99F5F6F8), BlendMode.saturation), child: img));
    return img;
  }
}

/// Who is talking.
class SpeakerRow extends StatelessWidget {
  const SpeakerRow({super.key, required this.coach, required this.name, required this.role});
  final OnbCoach coach;
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final both = coach == OnbCoach.duo;
    return Row(
      children: [
        CoachAvatar(OnbAssets.sportAvatar, dim: !both && coach != OnbCoach.sport),
        Transform.translate(offset: Offset(-context.vw(3.6), 0), child: CoachAvatar(OnbAssets.nutriAvatar, dim: !both && coach != OnbCoach.nutri)),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: name, style: OnbText.body(context, 3.3, weight: FontWeight.w600)),
            if (!both) TextSpan(text: ', $role', style: OnbText.body(context, 3.3, color: OnbColors.mute)),
          ]),
        ),
        SizedBox(width: context.vw(2)),
        Pulse(
            child: Container(width: context.vw(1.6), height: context.vw(1.6), decoration: const BoxDecoration(color: OnbColors.green, shape: BoxShape.circle))),
      ],
    );
  }
}

/// The previous question (muted) and the answer as a pill on the right.
class PastExchange extends StatelessWidget {
  const PastExchange({super.key, required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.vw(68)),
          child: Text(question, style: OnbText.display(context, 3.7, weight: FontWeight.w600, color: OnbColors.mute, height: 1.3, letterSpacingEm: -0.01)),
        ),
        SizedBox(height: context.vh(1)),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(maxWidth: context.vw(74)),
            padding: EdgeInsets.symmetric(horizontal: context.vw(3.4), vertical: context.vw(2)),
            decoration: BoxDecoration(
              color: OnbColors.surf,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: OnbColors.line),
              boxShadow: [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.06), blurRadius: context.vw(2), offset: Offset(0, context.vw(0.6)))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(answer, style: OnbText.body(context, 3.5, weight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                SizedBox(width: context.vw(1.6)),
                Icon(LucideIcons.check, size: context.vw(3.4), color: OnbColors.ink),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Small white card used across the flow.
class OnbCard extends StatelessWidget {
  const OnbCard({super.key, required this.child, this.padding, this.color = OnbColors.surf, this.radiusVw = 4.6});
  final Widget child;
  final EdgeInsets? padding;
  final Color color;
  final double radiusVw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(context.vw(4.4)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.vw(radiusVw)),
        border: Border.all(color: OnbColors.line),
        boxShadow: [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.06), blurRadius: context.vw(4), offset: Offset(0, context.vw(1.4)))],
      ),
      child: child,
    );
  }
}

/// Gentle opacity pulse (the coach's "live" dot).
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.period = const Duration(milliseconds: 1200)});
  final Widget child;
  final Duration period;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: Tween<double>(begin: 1, end: 0.4).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)), child: widget.child);
  }
}

/// Slow vertical float, used on the coach avatars of the first screen.
class Bob extends StatefulWidget {
  const Bob({super.key, required this.child, this.amplitude = 6, this.period = const Duration(milliseconds: 3200), this.phase = 0});
  final Widget child;
  final double amplitude;
  final Duration period;

  /// 0..1 offset in the cycle, so two avatars do not move in sync.
  final double phase;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

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
        final t = (_c.value + widget.phase) % 1.0;
        return Transform.translate(offset: Offset(0, -widget.amplitude * (0.5 - 0.5 * math.cos(t * 2 * math.pi))), child: child);
      },
      child: widget.child,
    );
  }
}

/// The prototype's ground: paper gradient, warm light top right, a faint cool
/// glow bottom left, the blurred gym scene, and the fine grid fading at both ends.
class OnbBackground extends StatelessWidget {
  const OnbBackground({super.key, this.scene = true});
  final bool scene;

  @override
  Widget build(BuildContext context) {
    final w = context.vw(100);
    // RepaintBoundary: the blurred scene must not be re-filtered on every animation frame
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: BoxDecoration(gradient: OnbColors.ground)),
            Positioned(
              right: -w * 0.35,
              top: -w * 0.45,
              child: Container(
                width: w * 1.4,
                height: w * 1.1,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x4DFFC478), Color(0x00FFC478)], stops: [0, 0.62]),
                ),
              ),
            ),
            Positioned(
              left: -w * 0.3,
              bottom: -w * 0.3,
              child: Container(
                width: w * 1.2,
                height: w * 0.9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x141B2A5B), Color(0x001B2A5B)], stops: [0, 0.6]),
                ),
              ),
            ),
            if (scene)
              Opacity(
                opacity: 0.16,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Color(0x8C000000), Colors.transparent],
                      stops: [0, 0.45, 0.8],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(OnbAssets.scene, fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
                  ),
                ),
              ),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.3, 0.7, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: CustomPaint(painter: _GridPainter(spacing: w * 0.08)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.spacing});
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OnbColors.ink.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.spacing != spacing;
}
