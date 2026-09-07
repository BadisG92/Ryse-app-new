import 'dart:async';

import 'package:flutter/material.dart';

import 'feedback.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// What the app says after it has written something, and how the user takes it
/// back.
///
/// It replaces the snackbar on the redesigned surfaces: an ink pill that slides
/// up above the tab bar, says what happened, and offers one way out for four
/// seconds. It never covers the top of the page, where the numbers are, and it
/// never uses green, which the system reserves for confirmation buttons.
///
/// Use [RyzeUndo.show] right after an optimistic write. If the write fails,
/// call [RyzeUndo.failed] instead: the same pill, in the danger colour, saying
/// the entry is kept for later.
class RyzeUndo {
  RyzeUndo._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  /// How long the bar stays before leaving on its own.
  static const Duration life = Duration(seconds: 4);

  /// Height reserved above the bottom of the screen, so the bar clears the bar.
  static const double bottomInset = 96;

  static void show(BuildContext context, {required String message, required String undoLabel, required VoidCallback onUndo}) {
    _insert(context, message: message, action: undoLabel, onAction: onUndo, danger: false);
  }

  /// The write did not reach the server. Same place, same shape, danger colour.
  static void failed(BuildContext context, {required String message}) {
    RyzeFeedback.failure();
    _insert(context, message: message, action: null, onAction: null, danger: true);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static void _insert(
    BuildContext context, {
    required String message,
    required String? action,
    required VoidCallback? onAction,
    required bool danger,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    dismiss();

    final entry = OverlayEntry(
      builder: (context) => _UndoBar(
        message: message,
        action: action,
        danger: danger,
        onAction: onAction == null
            ? null
            : () {
                dismiss();
                RyzeFeedback.removed();
                onAction();
              },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(life, dismiss);
  }
}

class _UndoBar extends StatefulWidget {
  const _UndoBar({required this.message, required this.action, required this.onAction, required this.danger});

  final String message;
  final String? action;
  final VoidCallback? onAction;
  final bool danger;

  @override
  State<_UndoBar> createState() => _UndoBarState();
}

class _UndoBarState extends State<_UndoBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: RyzeDurations.enter)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.danger ? RyzeColors.danger : RyzeColors.ink;
    return Positioned(
      left: context.vw(5.1),
      right: context.vw(5.1),
      bottom: RyzeUndo.bottomInset + MediaQuery.paddingOf(context).bottom,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: RyzeCurves.out)),
        child: FadeTransition(
          opacity: _c,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 44,
              padding: EdgeInsets.only(left: context.vw(4.6), right: widget.action == null ? context.vw(4.6) : context.vw(1.5)),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(RyzeRadius.pill),
                boxShadow: RyzeShadow.lift,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 3.6, weight: FontWeight.w500, color: Colors.white),
                    ),
                  ),
                  if (widget.action != null)
                    Pressable(
                      onTap: widget.onAction,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.vw(3.1), vertical: 8),
                        child: Text(
                          widget.action!,
                          style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.acc),
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
