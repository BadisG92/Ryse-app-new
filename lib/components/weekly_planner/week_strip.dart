import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/tokens.dart';
import '../../design/type.dart';

/// The week above the conversation, in two states.
///
/// Folded, it is a row of seven days, each carrying small marks: one square per
/// meal, a ring apart for the session. Unfolded, it shows a tile per planned
/// item, and nothing where nothing is planned.
///
/// One visual variable carries the state of a slot: the fill. Light grey means
/// free, a navy outline means planned, a navy fill means done. Sport is told
/// apart by its shape, never by a colour.

enum WeekSlot { breakfast, lunch, snack, dinner, sport }

enum SlotState { empty, incoming, planned, done }

const List<WeekSlot> kFoodSlots = [WeekSlot.breakfast, WeekSlot.lunch, WeekSlot.snack, WeekSlot.dinner];

IconData iconForSlot(WeekSlot slot) {
  switch (slot) {
    case WeekSlot.breakfast:
      return LucideIcons.sunrise;
    case WeekSlot.lunch:
      return LucideIcons.sun;
    case WeekSlot.snack:
      return LucideIcons.milk;
    case WeekSlot.dinner:
      return LucideIcons.sunset;
    case WeekSlot.sport:
      return LucideIcons.dumbbell;
  }
}

/// What one day holds: the state of each slot and a short label for the tile.
class DaySlots {
  const DaySlots({this.states = const {}, this.labels = const {}});
  final Map<WeekSlot, SlotState> states;
  final Map<WeekSlot, String> labels;

  SlotState state(WeekSlot s) => states[s] ?? SlotState.empty;
  bool get hasAny => states.values.any((s) => s != SlotState.empty);
}

// Les jetons du systeme, pas une copie : la bande suit le theme.

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.days,
    required this.dayLetters,
    required this.slots,
    required this.expanded,
    required this.onToggle,
    required this.slotKey,
    this.popped = const {},
    this.onSlotTap,
    this.onEmptyTap,
    this.onDayTap,
    this.openDay,
    this.page = 0,
    this.onPageChanged,
  });

  final List<DateTime> days;
  final List<String> dayLetters;
  final List<DaySlots> slots;
  final bool expanded;
  final VoidCallback onToggle;

  /// Anchor of a slot, used as the landing point of a validated item.
  final GlobalKey Function(int day, WeekSlot slot) slotKey;

  /// Slots ("2-lunch") something has just landed in: they take the impact.
  final Set<String> popped;
  final void Function(int day, WeekSlot slot)? onSlotTap;

  /// Un jour ou rien n'est prévu : la pastille en pointillés devient un
  /// bouton. Elle portait un « + » sur lequel il ne se passait rien.
  final void Function(int day)? onEmptyTap;

  /// Quand il est donné, chaque jour de la bande est un bouton à lui
  /// seul et c'est l'appelant qui décide de ce qui s'ouvre. Sans lui,
  /// toucher la bande la déplie entière, comme dans la conversation.
  final void Function(int day)? onDayTap;

  /// Le jour ouvert, s'il y en a un.
  final int? openDay;

  /// The week shown, when [days] holds more than seven: 0 is this week, 1 the
  /// next. Every index handed back (slots, taps, anchors) stays an index into
  /// [days], whatever the page.
  final int page;

  /// Given, the strip follows a horizontal swipe from one week to the other.
  final ValueChanged<int>? onPageChanged;

  int get _pages => (days.length + 6) ~/ 7;

  void _swipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (onPageChanged == null || v.abs() < 200) return;
    final next = (page + (v < 0 ? 1 : -1)).clamp(0, _pages - 1);
    if (next != page) onPageChanged!(next);
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isPast(DateTime d) {
    final now = DateTime.now();
    return d.isBefore(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    final current = page.clamp(0, _pages - 1);
    final first = current * 7;
    final shown = [for (var i = first; i < first + 7 && i < days.length; i++) i];

    // Une semaine à la fois. La suivante arrive par la droite, la courante
    // revient par la gauche.
    final week = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDayTap == null ? onToggle : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  for (final i in shown)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onDayTap == null ? null : () => onDayTap!(i),
                        child: _DayChip(
                          letter: dayLetters.isEmpty ? '' : dayLetters[i % dayLetters.length],
                          number: days[i].day,
                          slots: slots[i],
                          today: _isToday(days[i]),
                          past: _isPast(days[i]),
                          anchor: expanded ? null : slotKey,
                          popped: popped,
                          index: i,
                          open: openDay == i,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final i in shown)
                          Expanded(
                            child: _DayTiles(
                              index: i,
                              slots: slots[i],
                              anchor: slotKey,
                              popped: popped,
                              past: _isPast(days[i]),
                              onSlotTap: onSlotTap,
                              onEmptyTap: onEmptyTap,
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
      ],
    );

    return Container(
      color: RyzeColors.surf,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onHorizontalDragEnd: onPageChanged == null ? null : _swipe,
            child: ClipRect(child: _PageSlide(page: current, child: week)),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: SizedBox(
              height: 16,
              child: Stack(
                children: [
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: expanded ? 22 : 32,
                      height: 4,
                      decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  // Deux points à droite : il y a une autre semaine à côté.
                  if (onPageChanged != null && _pages > 1)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var p = 0; p < _pages; p++)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onPageChanged!(p),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: p == current ? RyzeColors.ink : RyzeColors.idle,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slides the week in from the side it comes from, only when the page
/// changes.
///
/// One child at a time, never two: the strip's anchors are GlobalKeys, and a
/// switcher keeping the old week on screen while the new one arrives would
/// mount the same key twice on a quick back-and-forth swipe.
class _PageSlide extends StatefulWidget {
  const _PageSlide({required this.page, required this.child});
  final int page;
  final Widget child;

  @override
  State<_PageSlide> createState() => _PageSlideState();
}

class _PageSlideState extends State<_PageSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1);
  double _side = 1;

  @override
  void didUpdateWidget(covariant _PageSlide old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page) {
      _side = widget.page > old.page ? 1 : -1;
      _c.forward(from: 0);
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
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = 1 - Curves.easeOutCubic.transform(_c.value);
        return FractionalTranslation(
          translation: Offset(_side * t * 0.4, 0),
          child: Opacity(opacity: 1 - t, child: child),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.letter,
    required this.number,
    required this.slots,
    required this.today,
    required this.past,
    required this.anchor,
    required this.popped,
    required this.index,
    this.open = false,
  });

  final String letter;
  final int number;
  final DaySlots slots;
  final bool today;
  final bool past;
  final GlobalKey Function(int day, WeekSlot slot)? anchor;
  final Set<String> popped;
  final int index;

  /// Le jour dont le contenu est déplié sous la bande.
  final bool open;

  @override
  Widget build(BuildContext context) {
    final dim = past && !today;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.fromLTRB(3, 6, 3, 7),
      decoration: BoxDecoration(
        // Deux marques distinctes, qui peuvent se cumuler : aujourd'hui porte
        // un liseré d'encre, le jour ouvert un fond. Le jour ouvert n'est pas
        // forcément aujourd'hui, et aujourd'hui reste reconnaissable même
        // quand on lit un autre jour.
        color: open ? RyzeColors.line.withValues(alpha: 0.55) : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: today ? RyzeColors.ink : Colors.transparent, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(letter, style: RyzeText.body(context, 2.8, weight: FontWeight.w600, color: dim ? RyzeColors.mute2 : RyzeColors.mute, height: 1)),
          const SizedBox(height: 2),
          Text('$number',
              style: RyzeText.body(context, 3.8, weight: FontWeight.w700, color: dim ? RyzeColors.mute : RyzeColors.ink, height: 1.1)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 6),
          SizedBox(
            height: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final slot in kFoodSlots)
                  if (slot != WeekSlot.snack || slots.state(slot) != SlotState.empty)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: _Mark(key: anchor?.call(index, slot), state: slots.state(slot), round: false, past: dim, pop: popped.contains('$index-${slot.name}')),
                    ),
                const SizedBox(width: 1),
                _Mark(
                    key: anchor?.call(index, WeekSlot.sport),
                    state: slots.state(WeekSlot.sport),
                    round: true,
                    past: dim,
                    pop: popped.contains('$index-${WeekSlot.sport.name}')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A meal is a square, a session a circle. Free is a light fill, planned an
/// outline, done a full navy.
class _Mark extends StatelessWidget {
  const _Mark({super.key, required this.state, required this.round, this.pop = false, this.past = false});
  final SlotState state;
  final bool round;
  final bool pop;

  /// Une journée écoulée : ce qui n'a pas été fait ne l'est plus, et se lit
  /// comme une case libre, pas comme une case en attente.
  final bool past;

  @override
  Widget build(BuildContext context) {
    final size = round ? 8.0 : 5.0;
    final done = state == SlotState.done;
    // incoming stays invisible: only the mark that lands is drawn
    final drawn = done || (state == SlotState.planned && !past);
    return AnimatedScale(
      scale: pop ? 1.9 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        // a free meal is a filled light square, a free session an empty ring:
        // shape tells the two apart, the fill tells free from planned from done
        // free is a light fill for both shapes, planned an outline, done a full navy
        color: done ? RyzeColors.ink : (drawn ? RyzeColors.surf : RyzeColors.idle),
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(1.5),
        border: drawn && !done ? Border.all(color: RyzeColors.ink, width: 1.4) : null,
      ),
      ),
    );
  }
}

class _DayTiles extends StatelessWidget {
  const _DayTiles({required this.index, required this.slots, required this.anchor, required this.popped, required this.past, this.onSlotTap, this.onEmptyTap});

  final int index;
  final DaySlots slots;
  final GlobalKey Function(int day, WeekSlot slot) anchor;
  final Set<String> popped;
  final bool past;
  final void Function(int day, WeekSlot slot)? onSlotTap;
  final void Function(int day)? onEmptyTap;

  @override
  Widget build(BuildContext context) {
    final drawn = [
      for (final slot in WeekSlot.values)
        if (slots.state(slot) != SlotState.empty) slot,
    ];
    if (drawn.isEmpty) {
      return SizedBox(
        height: 40,
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEmptyTap == null ? null : () => onEmptyTap!(index),
            child: const Padding(padding: EdgeInsets.all(6), child: _EmptyDot()),
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final slot in drawn)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 1, right: 1),
            child: _Tile(
              key: anchor(index, slot),
              pop: popped.contains('$index-${slot.name}'),
              slot: slot,
              state: slots.state(slot),
              onTap: onSlotTap == null ? null : () => onSlotTap!(index, slot),
            ),
          ),
      ],
    );
  }
}

class _EmptyDot extends StatelessWidget {
  const _EmptyDot();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorder(radius: 12),
      child: SizedBox(width: 24, height: 24, child: Icon(LucideIcons.plus, size: 12, color: RyzeColors.idle)),
    );
  }
}

/// Dashed outline of a slot waiting to be filled, drawn like the prototype's
/// dashed CSS border rather than a solid rule.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RyzeColors.idle
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, (d + 3.5).clamp(0, metric.length)), paint);
        d += 6.5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) => old.radius != radius;
}

class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.slot, required this.state, this.pop = false, this.onTap});

  final bool pop;
  final WeekSlot slot;
  final SlotState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // a slot waiting for a mark keeps its place and draws nothing: an outline
    // sitting at the landing point makes the flight look like it changes
    // nothing when it arrives
    if (state == SlotState.incoming) {
      return const SizedBox(height: 40, width: double.infinity);
    }
    final done = state == SlotState.done;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: pop ? 1.12 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: done ? RyzeColors.ink : RyzeColors.surf,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: done || slot == WeekSlot.sport ? RyzeColors.ink : RyzeColors.line, width: slot == WeekSlot.sport && !done ? 1.5 : 1),
        ),
        // the icon alone: a dish name under it crowded a 40 pt tile for no gain
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // the icon keeps its original size: without a label the tile is
            // meant to read as a quiet mark, not as a button
            Center(child: Icon(iconForSlot(slot), size: 14, color: done ? RyzeColors.surf : RyzeColors.ink)),
            if (done)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.ink, width: 1.5)),
                  child: Icon(LucideIcons.check, size: 8, color: RyzeColors.ink),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
