import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'feedback.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// The one viewfinder the app has, whatever it is looking at.
///
/// Both scanners used to draw their own: the same black scrim, the same white
/// iPhone shutter, the same 12 pt pills, written twice and drifting apart. The
/// camera is the one surface where the paper cannot follow — the frame has to
/// be the whole screen — so the app's presence is what sits on top of it:
/// ink scrims instead of pure black, a paper shutter, one line of guidance
/// that fades once it has been read.
///
/// The shell owns nothing but the chrome. Its host keeps the controller, the
/// permissions and the meaning of a capture.
class RyzeCameraShell extends StatelessWidget {
  const RyzeCameraShell({
    super.key,
    required this.controller,
    required this.ready,
    required this.title,
    required this.hint,
    required this.onClose,
    this.frame,
    this.busy = false,
    this.shutter,
    this.leftAction,
    this.leftIcon,
    this.leftLabel,
    this.rightAction,
    this.rightIcon,
    this.rightLabel,
    this.overlay,
    this.footer,
  });

  final CameraController? controller;
  final bool ready;

  /// What the user is doing, in two or three words.
  final String title;

  /// The one line of guidance under it. It fades on its own.
  final String hint;

  final VoidCallback onClose;

  /// The reticle drawn over the preview, when the mode has one.
  final Widget? frame;

  /// True while the frame is being read: the shutter shows the wait.
  final bool busy;

  /// The capture. Null when the mode needs no shutter, which is the case once
  /// the barcode reads itself.
  final VoidCallback? shutter;

  final VoidCallback? leftAction;
  final IconData? leftIcon;
  final String? leftLabel;

  final VoidCallback? rightAction;
  final IconData? rightIcon;
  final String? rightLabel;

  /// Anything the mode wants between the preview and the chrome.
  final Widget? overlay;

  /// Replaces the whole control bar, for a mode that asks a question instead.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RyzeColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready && controller != null)
            _Focusable(controller: controller!, child: _Preview(controller: controller!))
          else
            ColoredBox(color: RyzeColors.ink),

          // Le cadre est un dessin : il ne doit pas manger le doigt qui vise.
          if (frame != null) Center(child: IgnorePointer(child: frame!)),
          if (overlay != null) overlay!,

          // The scrims are ink, not black: on top of a photograph the
          // difference is small and the app is still itself.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: context.vw(34),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [RyzeColors.ink.withValues(alpha: 0.62), RyzeColors.ink.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(2.1), context.vw(4.1), 0),
                  child: Row(
                    children: [
                      _Round(icon: LucideIcons.x, onTap: onClose),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.vw(2.6)),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
                          ),
                        ),
                      ),
                      if (rightIcon != null)
                        _Round(icon: rightIcon!, onTap: rightAction, label: rightLabel)
                      else
                        SizedBox(width: context.vw(10.8)),
                    ],
                  ),
                ),
                const Spacer(),
                _Hint(text: hint),
                SizedBox(height: context.vw(4.6)),
                footer ??
                    _Controls(
                      busy: busy,
                      shutter: shutter,
                      leftAction: leftAction,
                      leftIcon: leftIcon,
                      leftLabel: leftLabel,
                    ),
                SizedBox(height: context.vw(5.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The preview, filled to the screen without stretching the picture. The
/// plugin gives an aspect ratio in its own orientation, so it is covered
/// rather than fitted: a squashed viewfinder makes aiming wrong.
class _Preview extends StatelessWidget {
  const _Preview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratio = controller.value.aspectRatio;
    if (ratio <= 0) return CameraPreview(controller);
    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: size.width, height: size.width * ratio, child: CameraPreview(controller)),
        ),
      ),
    );
  }
}

/// Le point que la caméra doit regarder.
///
/// Le viseur demandait « touchez l'écran pour faire la mise au point » et
/// personne n'écoutait : l'appareil restait sur son autofocus au centre, et
/// un code-barres tenu près, en bas du cadre, ne devenait jamais net. Un
/// appui vise, et le carré blanc dit où.
class _Focusable extends StatefulWidget {
  const _Focusable({required this.controller, required this.child});

  final CameraController controller;
  final Widget child;

  @override
  State<_Focusable> createState() => _FocusableState();
}

class _FocusableState extends State<_Focusable> {
  Offset? _at;
  int _seq = 0;

  Future<void> _aim(Offset local, Size size) async {
    final c = widget.controller;
    if (!c.value.isInitialized) return;

    // L'aperçu couvre l'écran : il déborde en hauteur et on n'en voit qu'une
    // bande centrale. Le point rendu à la caméra est dans SES coordonnées, pas
    // dans celles de l'écran — sans cette conversion, viser le bas du cadre
    // faisait le point ailleurs.
    final ratio = c.value.aspectRatio;
    final previewH = ratio > 0 ? size.width * ratio : size.height;
    final visible = previewH <= 0 ? 1.0 : (size.height / previewH).clamp(0.0, 1.0);
    final nx = (local.dx / size.width).clamp(0.0, 1.0);
    final ny = (0.5 + (local.dy / size.height - 0.5) * visible).clamp(0.0, 1.0);

    final seq = ++_seq;
    setState(() => _at = local);
    try {
      await c.setFocusPoint(Offset(nx, ny));
      await c.setFocusMode(FocusMode.auto);
      await c.setExposurePoint(Offset(nx, ny));
    } catch (_) {
      // L'appareil ne sait pas viser : son autofocus continue de faire ce
      // qu'il peut, et le carré a au moins dit que le geste avait été reçu.
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted && seq == _seq) setState(() => _at = null);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final at = _at;
    final side = context.vw(18);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _aim(d.localPosition, size),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (at != null)
            Positioned(
              left: at.dx - side / 2,
              top: at.dy - side / 2,
              child: IgnorePointer(child: _Reticle(side: side)),
            ),
        ],
      ),
    );
  }
}

/// Le carré de visée : il arrive un peu trop grand et se pose. Rien de plus —
/// c'est un accusé de réception, pas une animation.
class _Reticle extends StatelessWidget {
  const _Reticle({required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.35, end: 1),
      duration: RyzeDurations.tap,
      curve: RyzeCurves.out,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: SizedBox(
        width: side,
        height: side,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: RyzeColors.surf.withValues(alpha: 0.9), width: 1.4),
            borderRadius: BorderRadius.circular(RyzeRadius.sm),
          ),
        ),
      ),
    );
  }
}

/// One line of guidance, held long enough to be read and then gone: a viewfinder
/// that keeps explaining itself is a viewfinder in the way.
class _Hint extends StatefulWidget {
  const _Hint({required this.text});

  final String text;

  @override
  State<_Hint> createState() => _HintState();
}

class _HintState extends State<_Hint> {
  bool _out = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_Hint old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      setState(() => _out = false);
      _schedule();
    }
  }

  void _schedule() {
    Future.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) setState(() => _out = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _out ? 0 : 1,
      duration: RyzeDurations.enter,
      curve: RyzeCurves.out,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.vw(10)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(2.3)),
          decoration: BoxDecoration(
            color: RyzeColors.ink.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(RyzeRadius.pill),
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: RyzeText.body(context, 3.4, color: RyzeColors.surf),
          ),
        ),
      ),
    );
  }
}

/// The shutter and its one companion. Nothing is centred by luck: the shutter
/// holds the middle and the side keeps its width even when empty.
class _Controls extends StatelessWidget {
  const _Controls({required this.busy, required this.shutter, this.leftAction, this.leftIcon, this.leftLabel});

  final bool busy;
  final VoidCallback? shutter;
  final VoidCallback? leftAction;
  final IconData? leftIcon;
  final String? leftLabel;

  @override
  Widget build(BuildContext context) {
    final side = context.vw(13.3);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.vw(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: side,
            child: leftIcon == null ? null : _Round(icon: leftIcon!, onTap: leftAction, label: leftLabel, big: true),
          ),
          if (shutter != null) _Shutter(busy: busy, onTap: shutter!) else SizedBox(height: context.vw(19)),
          SizedBox(width: side),
        ],
      ),
    );
  }
}

/// Paper, not chrome white: the same surface the sheets are made of.
class _Shutter extends StatelessWidget {
  const _Shutter({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = context.vw(19);
    return Semantics(
      button: true,
      child: Pressable(
        onTap: busy
            ? null
            : () {
                RyzeFeedback.confirm();
                onTap();
              },
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: RyzeColors.surf.withValues(alpha: busy ? 0.5 : 0.9), width: 3),
                ),
              ),
              AnimatedContainer(
                duration: RyzeDurations.tap,
                curve: RyzeCurves.out,
                width: size - (busy ? 26 : 14),
                height: size - (busy ? 26 : 14),
                decoration: BoxDecoration(color: RyzeColors.paper, shape: BoxShape.circle),
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: RyzeColors.ink.withValues(alpha: 0.6)),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A control on glass: an ink disc that keeps its 44 pt target whatever the
/// icon inside it.
class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.onTap, this.label, this.big = false});

  final IconData icon;
  final VoidCallback? onTap;
  final String? label;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? context.vw(13.3) : context.vw(10.8);
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap == null
            ? null
            : () {
                RyzeFeedback.tap();
                onTap!();
              },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: RyzeColors.ink.withValues(alpha: 0.42),
            shape: BoxShape.circle,
            border: Border.all(color: RyzeColors.surf.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, size: size * 0.44, color: RyzeColors.surf),
        ),
      ),
    );
  }
}

/// The barcode reticle: four corners and a live rule, drawn in paper on the
/// scene. It is a window, not a box — nothing is dimmed outside it, because
/// the reader looks at the whole frame anyway.
class BarcodeFrame extends StatefulWidget {
  const BarcodeFrame({super.key, required this.found});

  /// True the moment a code is read: the corners close on it.
  final bool found;

  @override
  State<BarcodeFrame> createState() => _BarcodeFrameState();
}

class _BarcodeFrameState extends State<BarcodeFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = context.vw(74);
    final height = context.vw(40);
    final tint = widget.found ? RyzeColors.acc : RyzeColors.surf;

    return AnimatedScale(
      scale: widget.found ? 0.94 : 1,
      duration: RyzeDurations.tap,
      curve: RyzeCurves.spring,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            for (final corner in _Corner.values)
              Positioned(
                left: corner.left ? 0 : null,
                right: corner.left ? null : 0,
                top: corner.top ? 0 : null,
                bottom: corner.top ? null : 0,
                child: CustomPaint(size: Size(context.vw(8), context.vw(8)), painter: _CornerPainter(corner, tint)),
              ),
            if (!widget.found)
              AnimatedBuilder(
                animation: _sweep,
                builder: (context, _) => Positioned(
                  top: (height - 2) * Curves.easeInOut.transform(_sweep.value),
                  left: context.vw(3),
                  right: context.vw(3),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          RyzeColors.surf.withValues(alpha: 0),
                          RyzeColors.surf.withValues(alpha: 0.85),
                          RyzeColors.surf.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _Corner {
  topLeft(true, true),
  topRight(true, false),
  bottomLeft(false, true),
  bottomRight(false, false);

  const _Corner(this.top, this.left);

  final bool top;
  final bool left;
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.corner, this.color);

  final _Corner corner;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final x = corner.left ? 0.0 : size.width;
    final y = corner.top ? 0.0 : size.height;
    final dx = corner.left ? size.width : -size.width;
    final dy = corner.top ? size.height : -size.height;
    final path = Path()
      ..moveTo(x + dx, y)
      ..lineTo(x + dx * 0.34, y)
      ..quadraticBezierTo(x, y, x, y + dy * 0.34)
      ..lineTo(x, y + dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color || old.corner != corner;
}
