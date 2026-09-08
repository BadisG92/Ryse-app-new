import 'package:flutter/material.dart';

import 'feedback.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// The sheet of the system: paper, a grabber, a title in Archivo, content that
/// sets its own height, and actions pinned to the bottom.
///
/// It is the one way a screen asks for something without leaving the page. The
/// page behind it stays visible and dims; dragging the grabber down or tapping
/// the dim closes it, the way iOS taught everyone.
Future<T?> showRyzeSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required WidgetBuilder builder,

  /// Buttons that stay reachable at the bottom, outside the scroll.
  List<Widget> actions = const [],

  /// False for a sheet the user must answer.
  bool dismissible = true,

  /// True for a sheet that holds a text field: it rises above the keyboard
  /// instead of being covered by it.
  bool keyboard = false,
}) {
  RyzeFeedback.confirm();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    barrierColor: RyzeColors.ink.withValues(alpha: 0.34),
    builder: (context) {
      final sheet = _RyzeSheet(title: title, subtitle: subtitle, actions: actions, child: builder(context));
      if (!keyboard) return sheet;
      return Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: sheet);
    },
  );
}

class _RyzeSheet extends StatelessWidget {
  const _RyzeSheet({required this.title, this.subtitle, required this.actions, required this.child});

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gutter = context.vw(5.1);
    return Container(
      constraints: BoxConstraints(maxHeight: context.vh(88)),
      decoration: BoxDecoration(
        color: RyzeColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 14),
              child: Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: RyzeText.display(context, 6.2)),
                  if (subtitle != null) ...[
                    SizedBox(height: context.vw(1)),
                    Text(subtitle!, style: RyzeText.body(context, 3.6, color: RyzeColors.mute)),
                  ],
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(gutter, context.vw(3.6), gutter, actions.isEmpty ? context.vw(6) : context.vw(2)),
                child: child,
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, context.vw(2), gutter, context.vw(4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) SizedBox(height: context.vw(2.4)),
                      actions[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A row of a sheet: a glyph in a paper circle, a label, a hint under it, and a
/// chevron. The shape every list in a sheet uses, so they all read as one thing.
class RyzeSheetRow extends StatelessWidget {
  const RyzeSheetRow({super.key, this.icon, this.leading, required this.label, this.hint, required this.onTap, this.first = false, this.danger = false})
      : assert(icon != null || leading != null, 'a row shows an icon or a leading widget');

  final IconData? icon;

  /// Takes the icon's place in the circle — the Ryze mark, when the row is
  /// Ryze speaking.
  final Widget? leading;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  /// The first row of a group draws no top edge.
  final bool first;

  /// A row that destroys something: same shape, the danger colour.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        RyzeFeedback.select();
        onTap();
      },
      child: Container(
        height: context.vw(14.9),
        padding: EdgeInsets.only(left: context.vw(2.6), right: context.vw(3.1)),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: RyzeColors.line)),
        ),
        child: Row(
          children: [
            Container(
              width: context.vw(9.7),
              height: context.vw(9.7),
              decoration: BoxDecoration(
                color: RyzeColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: RyzeColors.line),
              ),
              child: leading != null ? Center(child: leading) : Icon(icon, size: context.vw(4.6), color: danger ? RyzeColors.danger : RyzeColors.ink),
            ),
            SizedBox(width: context.vw(3.1)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: danger ? RyzeColors.danger : RyzeColors.ink)),
                  if (hint != null)
                    Text(hint!, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: RyzeColors.mute2),
          ],
        ),
      ),
    );
  }
}

/// The white card a group of [RyzeSheetRow] sits in.
class RyzeSheetGroup extends StatelessWidget {
  const RyzeSheetGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Column(children: children),
    );
  }
}
