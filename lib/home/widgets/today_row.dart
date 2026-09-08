import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';

/// Today's five slots, right under the number they explain.
///
/// It used to sit at the very bottom, under the week band, where the day it
/// describes arrived after the whole rest of the page. Here it reads as the
/// caption of the instrument: what is left of the goal, and the five places
/// that fill it. Each tile says its state in a word, so nothing has to be
/// decoded from a fill.
class TodayRow extends StatelessWidget {
  const TodayRow({
    super.key,
    required this.lang,
    required this.today,
    required this.onSlotTap,
  });

  final String lang;
  final DaySlots today;
  final void Function(WeekSlot slot) onSlotTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('home_today'.tr(lang), style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        Row(
          children: [
            // Les cinq créneaux, tout le temps, collation comprise. Elle
            // n'apparaissait qu'une fois prévue par le planificateur ou déjà
            // mangée — donc la collation improvisée, celle qu'on oublie le
            // plus, n'avait aucun bouton sur cette page. « Libre » n'invente
            // rien : il dit que la place est ouverte, comme pour les autres.
            for (final slot in WeekSlot.values) ...[
              Expanded(
                child: _Slot(
                  slot: slot,
                  state: today.state(slot),
                  label: 'slot_${slot.name}'.tr(lang),
                  lang: lang,
                  onTap: () {
                    RyzeFeedback.select();
                    onSlotTap(slot);
                  },
                ),
              ),
              if (slot != WeekSlot.sport) SizedBox(width: context.vw(1.5)),
            ],
          ],
        ),
      ],
    );
  }
}

/// One slot: planned is an ink edge, done an ink fill, free a white tile with
/// a light edge, which is the invitation to fill it. The session is a pill, a
/// meal a tile, as everywhere else in the app.
class _Slot extends StatelessWidget {
  const _Slot({required this.slot, required this.state, required this.label, required this.lang, required this.onTap});

  final WeekSlot slot;
  final SlotState state;
  final String label;
  final String lang;
  final VoidCallback onTap;

  static IconData _icon(WeekSlot s) => switch (s) {
        WeekSlot.breakfast => LucideIcons.sunrise,
        WeekSlot.lunch => LucideIcons.sun,
        WeekSlot.snack => LucideIcons.cookie,
        WeekSlot.dinner => LucideIcons.sunset,
        WeekSlot.sport => LucideIcons.dumbbell,
      };

  @override
  Widget build(BuildContext context) {
    final done = state == SlotState.done;
    final planned = state == SlotState.planned || state == SlotState.incoming;
    final fg = done ? RyzeColors.surf : (planned ? RyzeColors.ink : RyzeColors.mute);
    final fg2 = done ? RyzeColors.surf.withValues(alpha: 0.72) : RyzeColors.mute2;
    final word = done ? 'slot_done' : (planned ? 'slot_planned' : 'slot_free');

    return Pressable(
      onTap: onTap,
      // Le carre du creneau se pose quand il devient fait : c'est la marque la
      // plus regardee de l'application, et elle changeait de couleur sans qu'on
      // sente rien.
      child: RyzeLanding(
        on: done,
        amount: 0.06,
        child: AnimatedContainer(
        duration: RyzeDurations.fill,
        curve: RyzeCurves.spring,
        padding: EdgeInsets.symmetric(vertical: context.vw(2.3)),
        decoration: BoxDecoration(
          color: done ? RyzeColors.ink : RyzeColors.surf,
          borderRadius: BorderRadius.circular(slot == WeekSlot.sport ? RyzeRadius.pill : RyzeRadius.sm),
          border: Border.all(color: done || planned ? RyzeColors.ink : RyzeColors.line, width: planned && !done ? 1.4 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(done ? LucideIcons.check : _icon(slot), size: 16, color: fg),
            SizedBox(height: context.vw(1)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RyzeText.body(context, 2.7, weight: FontWeight.w600, color: fg, height: 1.1),
            ),
            Text(
              word.tr(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RyzeText.body(context, 2.4, color: fg2, height: 1.2),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
