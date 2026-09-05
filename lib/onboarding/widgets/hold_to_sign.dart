import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/haptic_service.dart';
import '../onboarding_theme.dart';

/// Press and hold for 1.3 s to sign. Fills with amber, then locks.
class HoldToSign extends StatefulWidget {
  const HoldToSign({super.key, required this.label, required this.doneLabel, required this.onDone, this.done = false});
  final String label;
  final String doneLabel;
  final VoidCallback onDone;
  final bool done;

  @override
  State<HoldToSign> createState() => _HoldToSignState();
}

class _HoldToSignState extends State<HoldToSign> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300), reverseDuration: const Duration(milliseconds: 250), value: widget.done ? 1 : 0);
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _done = widget.done;
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_done) {
        _done = true;
        HapticService.instance.heavyImpact();
        widget.onDone();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _start() {
    if (_done) return;
    HapticService.instance.lightImpact();
    _c.forward();
  }

  void _cancel() {
    if (_done) return;
    _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Raw pointer events: a GestureDetector would fire onTapCancel when the
    // long-press recognizer wins the arena, dipping the fill halfway through.
    return Listener(
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _cancel(),
      onPointerCancel: (_) => _cancel(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final fg = _done ? OnbColors.onAcc : Color.lerp(OnbColors.ink, OnbColors.onAcc, t)!;
          return Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: context.vw(15)),
            decoration: BoxDecoration(
              color: OnbColors.surf,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _done ? OnbColors.acc : OnbColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(widthFactor: _done ? 1 : t.clamp(0.0, 1.0), child: const ColoredBox(color: OnbColors.acc)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.vw(4)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_done ? LucideIcons.check : LucideIcons.fingerprint, size: context.vw(4.6), color: fg),
                      SizedBox(width: context.vw(2.4)),
                      Text(_done ? widget.doneLabel : widget.label, style: OnbText.body(context, 4.3, weight: FontWeight.w600, color: fg, height: 1.2)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A short burst of amber and ink particles, drawn once then gone.
class SparkBurst extends StatefulWidget {
  const SparkBurst({super.key, this.count = 22});
  final int count;

  @override
  State<SparkBurst> createState() => _SparkBurstState();
}

class _SparkBurstState extends State<SparkBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final List<_Spark> _sparks = List.generate(widget.count, (i) {
    final r = math.Random(i * 7919);
    final a = r.nextDouble() * math.pi * 2;
    final d = 40 + r.nextDouble() * 90;
    return _Spark(angle: a, dist: d, delay: r.nextDouble() * 0.12, ink: i.isOdd);
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _SparkPainter(_sparks, _c.value)),
      ),
    );
  }
}

class _Spark {
  const _Spark({required this.angle, required this.dist, required this.delay, required this.ink});
  final double angle;
  final double dist;
  final double delay;
  final bool ink;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.sparks, this.t);
  final List<_Spark> sparks;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final s in sparks) {
      final local = ((t - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final eased = Curves.easeOut.transform(local);
      final pos = center + Offset(math.cos(s.angle) * s.dist * eased, math.sin(s.angle) * s.dist * eased - 30 * eased);
      final radius = 3.2 * (1 - local);
      if (radius <= 0) continue;
      canvas.drawCircle(pos, radius, Paint()..color = (s.ink ? OnbColors.ink : OnbColors.acc).withValues(alpha: 1 - local));
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.t != t;
}
