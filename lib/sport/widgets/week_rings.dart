import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/ryze_dates.dart';
import '../../services/translations.dart';
import '../sport_data.dart';

/// La semaine en cours, en haut de l'onglet : le compte, sept anneaux, et
/// l'objectif — s'il y en a un.
///
/// L'ancien instrument affichait « encore 2 séances » face à un objectif
/// déduit d'une question d'onboarding que personne n'avait posée comme un
/// but. Ici les faits d'abord : combien, combien de temps, combien de kcal,
/// et quel jour — sept anneaux qui se lisent sans texte, navy pour la
/// musculation, ambre pour le cardio, aujourd'hui cerclé. L'objectif est une
/// ligne, et n'apparaît que si l'utilisateur l'a fixé.
class WeekBlock extends StatelessWidget {
  const WeekBlock({
    super.key,
    required this.lang,
    required this.days,
    required this.kinds,
    required this.sessions,
    required this.minutes,
    required this.kcal,
    required this.streak,
    required this.goal,
    required this.loaded,
    required this.onDay,
    required this.onGoal,
    required this.onPlan,
  });

  final String lang;

  /// Lundi → dimanche.
  final List<DateTime> days;
  final Map<String, Set<SportKind>> kinds;
  final int sessions;
  final int minutes;
  final int kcal;
  final int streak;

  /// Nul tant que l'utilisateur n'en a pas fixé.
  final int? goal;

  /// Faux avant la première lecture : le compte roule depuis zéro.
  final bool loaded;

  /// Un jour qui a une séance se presse.
  final ValueChanged<DateTime> onDay;
  final VoidCallback onGoal;

  /// Planifier la semaine. Le bouton vivait dans la carte « rien de
  /// prevu » de la journee : le jour ou une seance etait prevue, il
  /// n'existait plus. Planifier appartient a la semaine, pas au jour.
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final numbers = NumberFormat.decimalPattern(lang);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final time = minutes >= 60 ? '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}' : '$minutes min';
    final count = sessions == 1 ? 'sport_session_one'.tr(lang) : 'sport_sessions_n'.tr(lang).replaceAll('{n}', '${loaded ? sessions : 0}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('sport_this_week'.tr(lang), style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
        SizedBox(height: context.vw(0.5)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RollingNumber('${loaded ? sessions : 0}', style: RyzeText.display(context, 13, weight: FontWeight.w600).copyWith(height: 1)),
            SizedBox(width: context.vw(2.1)),
            Padding(
              padding: EdgeInsets.only(bottom: context.vw(1.5)),
              child: Text(
                sessions == 1 ? count : count.replaceFirst('${loaded ? sessions : 0} ', ''),
                style: RyzeText.body(context, 3.9, color: RyzeColors.mute),
              ),
            ),
          ],
        ),
        if (sessions > 0) ...[
          SizedBox(height: context.vw(0.5)),
          Text(
            [
              '$time · ${numbers.format(kcal)} kcal',
              if (streak > 1) 'sport_week_streak'.tr(lang).replaceAll('{n}', '$streak'),
            ].join(' · '),
            style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
        SizedBox(height: context.vw(4.1)),
        Row(
          children: [
            for (final d in days)
              Expanded(
                child: _Day(
                  lang: lang,
                  date: d,
                  kinds: kinds[SportData.dayKey(d)] ?? const <SportKind>{},
                  isToday: d == today,
                  future: d.isAfter(today),
                  onTap: () => onDay(d),
                ),
              ),
          ],
        ),
        SizedBox(height: context.vw(3.1)),
        Pressable(
          onTap: () {
            RyzeFeedback.tap();
            onGoal();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(1)),
            child: Row(
              children: [
                if (goal == null) ...[
                  Icon(LucideIcons.target, size: context.vw(3.9), color: RyzeColors.mute),
                  SizedBox(width: context.vw(1.5)),
                  Text('sport_set_goal'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.ink)),
                ] else ...[
                  Text(
                    'sport_goal_progress'.tr(lang).replaceAll('{done}', '$sessions').replaceAll('{goal}', '$goal'),
                    style: RyzeText.body(context, 3.4, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  Text(
                    ' · ${sessions >= goal! ? 'sport_goal_met_short'.tr(lang) : 'sport_goal_left'.tr(lang).replaceAll('{n}', '${goal! - sessions}')}',
                    style: RyzeText.body(context, 3.4, color: sessions >= goal! ? RyzeColors.accInk : RyzeColors.mute),
                  ),
                  SizedBox(width: context.vw(2.1)),
                  Text('sport_goal_edit'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute2)),
                ],
                SizedBox(width: context.vw(1)),
                Icon(LucideIcons.chevronRight, size: context.vw(3.6), color: RyzeColors.mute2),
              ],
            ),
          ),
        ),
        Pressable(
          onTap: () {
            RyzeFeedback.tap();
            onPlan();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(1)),
            child: Row(
              children: [
                RyzeMark(size: context.vw(3.9)),
                SizedBox(width: context.vw(1.5)),
                Text('sport_plan_week'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                SizedBox(width: context.vw(1)),
                Icon(LucideIcons.chevronRight, size: context.vw(3.6), color: RyzeColors.mute2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Un jour de la semaine : la lettre, l'anneau. Le jour d'aujourd'hui est
/// cerclé ; un jour à venir est plus pâle ; un jour qui a une séance se presse.
class _Day extends StatelessWidget {
  const _Day({required this.lang, required this.date, required this.kinds, required this.isToday, required this.future, required this.onTap});

  final String lang;
  final DateTime date;
  final Set<SportKind> kinds;
  final bool isToday;
  final bool future;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strength = kinds.contains(SportKind.strength);
    final cardio = kinds.contains(SportKind.cardio);
    final has = strength || cardio;
    final size = context.vw(8.7);

    return Pressable(
      onTap: has ? onTap : null,
      child: Column(
        children: [
          Container(
            width: size + 8,
            height: size + 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isToday ? Border.all(color: RyzeColors.ink, width: 1.4) : null,
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: strength ? RyzeColors.ink : (future ? Colors.transparent : RyzeColors.surf),
                border: Border.all(
                  color: strength ? RyzeColors.ink : (cardio ? RyzeColors.acc : (future ? RyzeColors.idle : RyzeColors.line)),
                  width: cardio && !strength ? 2.5 : 1,
                ),
              ),
              // les deux le même jour : la muscu remplit, le cardio cercle
              foregroundDecoration: strength && cardio ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: RyzeColors.acc, width: 2.5)) : null,
            ),
          ),
          SizedBox(height: context.vw(1)),
          Text(
            RyzeDates.short(date, lang).substring(0, 1),
            style: RyzeText.body(context, 2.9, weight: FontWeight.w600, color: isToday ? RyzeColors.ink : RyzeColors.mute2),
          ),
        ],
      ),
    );
  }
}
