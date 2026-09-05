import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Building blocks of a proposal card in the planner chat: the coach proposes
/// meals, a program or a session; the user reads, browses and validates.
///
/// One visual system for the three proposals: white card, header with the
/// day and a short summary, rows with a tinted icon tile, actions at the
/// bottom of the same card.

const Color _ink = Color(0xFF0B132B);
const Color _mute = Color(0xFF64748B);
const Color _mute2 = Color(0xFF94A3B8);
const Color _line = Color(0xFFE2E8F0);
const Color _tile = Color(0xFFF1F5F9);
const Color _green = Color(0xFF10B981);
const Color _protein = Color(0xFF3B82F6);
const Color _carbs = Color(0xFFF59E0B);
const Color _fat = Color(0xFFEF4444);

class ProposalCard extends StatelessWidget {
  const ProposalCard({super.key, required this.body, required this.footer, this.margin = const EdgeInsets.fromLTRB(0, 4, 0, 8)});
  final Widget body;
  final Widget footer;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: [BoxShadow(color: _ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [body, footer],
      ),
    );
  }
}

/// Icon tile + title + summary, optional prev/next arrows for paged content.
class ProposalHeader extends StatelessWidget {
  const ProposalHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.canPrev = false,
    this.canNext = false,
    this.onPrev,
    this.onNext,
    this.paged = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool paged;
  final bool canPrev;
  final bool canNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData i, bool enabled, VoidCallback? onTap) => GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: enabled ? _tile : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Icon(i, size: 16, color: enabled ? _ink : _line),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink, height: 1.15)),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _mute, height: 1.2)),
                ],
              ],
            ),
          ),
          if (paged) ...[
            const SizedBox(width: 8),
            arrow(LucideIcons.chevronLeft, canPrev, onPrev),
            const SizedBox(width: 4),
            arrow(LucideIcons.chevronRight, canNext, onNext),
          ],
        ],
      ),
    );
  }
}

class ProposalPagerDots extends StatelessWidget {
  const ProposalPagerDots({super.key, required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final on = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: on ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(color: on ? _ink : _line, borderRadius: BorderRadius.circular(3)),
          );
        }),
      ),
    );
  }
}

/// A meal line: type label, dish, compact macros, chevron to the detail page.
class ProposalMealRow extends StatelessWidget {
  const ProposalMealRow({
    super.key,
    required this.icon,
    required this.typeLabel,
    required this.dishName,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.macroLetters,
    this.onTap,
  });

  final IconData icon;
  final String typeLabel;
  final String dishName;
  final int calories;
  final int proteins;
  final int carbs;
  final int fats;

  /// Localized initials for proteins / carbs / fats, e.g. ['P', 'G', 'L'].
  final List<String> macroLetters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _tile, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: _ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeLabel.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _mute2, letterSpacing: 0.6, height: 1.2)),
                  const SizedBox(height: 2),
                  Text(dishName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink, height: 1.2)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('$calories kcal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink, height: 1.2, fontFeatures: [FontFeature.tabularFigures()])),
                      const SizedBox(width: 8),
                      _MacroDot(color: _protein, value: proteins, letter: macroLetters[0]),
                      const SizedBox(width: 8),
                      _MacroDot(color: _carbs, value: carbs, letter: macroLetters[1]),
                      const SizedBox(width: 8),
                      _MacroDot(color: _fat, value: fats, letter: macroLetters[2]),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight, size: 16, color: _mute2),
          ],
        ),
      ),
    );
  }
}

class _MacroDot extends StatelessWidget {
  const _MacroDot({required this.color, required this.value, required this.letter});
  final Color color;
  final int value;
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text('$value$letter', style: const TextStyle(fontSize: 11.5, color: _mute, height: 1.2, fontFeatures: [FontFeature.tabularFigures()])),
      ],
    );
  }
}

/// Day totals under the meal rows: calories big, macros with full labels.
class ProposalDayTotals extends StatelessWidget {
  const ProposalDayTotals({
    super.key,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.totalLabel,
    required this.proteinLabel,
    required this.carbsLabel,
    required this.fatLabel,
  });

  final int calories;
  final int proteins;
  final int carbs;
  final int fats;
  final String totalLabel;
  final String proteinLabel;
  final String carbsLabel;
  final String fatLabel;

  @override
  Widget build(BuildContext context) {
    Widget macro(Color c, int v, String label) => Expanded(
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${v}g ', style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
                    TextSpan(text: label, style: const TextStyle(color: _mute)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, height: 1.2, fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(totalLabel.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _mute2, letterSpacing: 0.6, height: 1.2)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: '$calories', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
                  const TextSpan(text: ' kcal', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _mute)),
                ]),
                style: const TextStyle(height: 1.1, fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 30, color: _line),
          const SizedBox(width: 12),
          macro(_protein, proteins, proteinLabel),
          macro(_carbs, carbs, carbsLabel),
          macro(_fat, fats, fatLabel),
        ],
      ),
    );
  }
}

/// A workout line: weekday tile, type, duration and exercise count.
class ProposalWorkoutRow extends StatelessWidget {
  const ProposalWorkoutRow({super.key, required this.dayShort, required this.title, required this.subtitle, this.onTap, this.last = false});
  final String dayShort;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _tile, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(dayShort, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink, height: 1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink, height: 1.2)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _mute, height: 1.2)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight, size: 16, color: _mute2),
          ],
        ),
      ),
    );
  }
}

/// Cancel (ghost) + confirm (green), optional full-width tonal secondary action.
class ProposalActions extends StatelessWidget {
  const ProposalActions({
    super.key,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.busy = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool busy;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(top: BorderSide(color: _line))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: busy ? null : onCancel,
                    style: OutlinedButton.styleFrom(foregroundColor: _mute, backgroundColor: Colors.white, side: const BorderSide(color: _line), shape: shape, textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    child: Text(cancelLabel),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : onConfirm,
                    icon: busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.check, size: 18),
                    label: Text(confirmLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, elevation: 0, shape: shape, textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton.icon(
                onPressed: busy ? null : onSecondary,
                icon: const Icon(LucideIcons.checkCheck, size: 16),
                label: Text(secondaryLabel!),
                style: TextButton.styleFrom(foregroundColor: _ink, backgroundColor: _tile, shape: shape, textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
