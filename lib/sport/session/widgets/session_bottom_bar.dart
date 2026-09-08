import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design/design.dart';
import '../../../services/translations.dart';
import '../rest_timer.dart';
import '../session_controller.dart';
import 'number_pad.dart';

/// Le bas de la séance, trois états pour une seule place.
///
/// Au repos : ajouter un exercice, terminer. Pendant le repos : le décompte.
/// En saisie : le pavé. Un seul `AnimatedSwitcher`, jamais deux choses à la
/// fois, et les deux actions principales restent sous le pouce — l'ancien
/// écran les mettait sous la liste, hors de vue dès qu'on avait des séries.
class SessionBottomBar extends StatelessWidget {
  const SessionBottomBar({
    super.key,
    required this.lang,
    required this.controller,
    required this.onAddExercise,
    required this.onFinish,
    required this.onMic,
  });

  final String lang;
  final SessionController controller;
  final VoidCallback onAddExercise;
  final VoidCallback onFinish;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RestState>(
      valueListenable: controller.rest,
      builder: (context, rest, _) {
        final Widget child;
        if (controller.editingField != null) {
          child = NumberPad(key: const ValueKey('pad'), controller: controller, lang: lang, onMic: onMic);
        } else if (rest.endsAt != null) {
          child = RestBar(key: const ValueKey('rest'), lang: lang, timer: controller.rest, state: rest);
        } else {
          child = _Actions(key: const ValueKey('actions'), lang: lang, onAddExercise: onAddExercise, onFinish: onFinish, canFinish: controller.session.doneSets > 0);
        }
        return AnimatedSwitcher(
          duration: RyzeDurations.tap,
          switchInCurve: RyzeCurves.out,
          switchOutCurve: RyzeCurves.out,
          transitionBuilder: (w, a) => FadeTransition(opacity: a, child: SizeTransition(sizeFactor: a, axisAlignment: 1, child: w)),
          child: SafeArea(top: false, child: child),
        );
      },
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({super.key, required this.lang, required this.onAddExercise, required this.onFinish, required this.canFinish});

  final String lang;
  final VoidCallback onAddExercise;
  final VoidCallback onFinish;
  final bool canFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.vw(5.1), context.vw(2.6), context.vw(5.1), context.vw(2.6)),
      decoration: BoxDecoration(
        color: RyzeColors.paper,
        border: Border(top: BorderSide(color: RyzeColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: onAddExercise,
              child: Container(
                height: context.vw(13.3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: RyzeColors.surf,
                  borderRadius: BorderRadius.circular(RyzeRadius.sm),
                  border: Border.all(color: RyzeColors.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.plus, size: context.vw(4.1), color: RyzeColors.ink),
                    SizedBox(width: context.vw(1.5)),
                    Flexible(
                      child: Text('exercise'.tr(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: context.vw(3.1)),
          Expanded(
            flex: 2,
            child: Pressable(
              onTap: canFinish ? onFinish : null,
              child: AnimatedContainer(
                duration: RyzeDurations.tap,
                height: context.vw(13.3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: canFinish ? RyzeColors.ink : RyzeColors.idle,
                  borderRadius: BorderRadius.circular(RyzeRadius.sm),
                  boxShadow: canFinish ? RyzeShadow.soft : null,
                ),
                child: Text(
                  'session_finish'.tr(lang),
                  style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: canFinish ? RyzeColors.surf : RyzeColors.mute),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le repos entre deux séries : la ligne ambre qui avance, le décompte, deux
/// pas de quinze secondes, et *Passer*. Taper le décompte passe aussi.
class RestBar extends StatelessWidget {
  const RestBar({super.key, required this.lang, required this.timer, required this.state});

  final String lang;
  final RestTimer timer;
  final RestState state;

  @override
  Widget build(BuildContext context) {
    final ended = state.justEnded;
    final s = state.remaining.inSeconds;
    final text = ended ? 'session_rest_done'.tr(lang) : '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: RyzeColors.paper,
        border: Border(top: BorderSide(color: RyzeColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 3,
            child: Stack(
              children: [
                Container(color: RyzeColors.idle),
                FractionallySizedBox(
                  widthFactor: ended ? 1 : state.progress,
                  heightFactor: 1,
                  child: Container(color: RyzeColors.acc),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(context.vw(5.1), context.vw(2.6), context.vw(5.1), context.vw(2.6)),
            child: Row(
              children: [
                _Step(label: 'session_minus15'.tr(lang), onTap: ended ? null : () => timer.extend(const Duration(seconds: -15))),
                Expanded(
                  child: Pressable(
                    onTap: timer.skip,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('session_rest'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
                        ended
                            ? Text(text, style: RyzeText.display(context, 6.2, weight: FontWeight.w600).copyWith(color: RyzeColors.accInk))
                            : RollingNumber(text, style: RyzeText.display(context, 9.2, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                _Step(label: 'session_plus15'.tr(lang), onTap: ended ? null : () => timer.extend(const Duration(seconds: 15))),
              ],
            ),
          ),
          if (!ended)
            Padding(
              padding: EdgeInsets.only(bottom: context.vw(2.1)),
              child: Pressable(
                onTap: timer.skip,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(1)),
                  child: Text('session_skip'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              RyzeFeedback.tap();
              onTap!();
            },
      child: Container(
        height: context.vw(10.8),
        padding: EdgeInsets.symmetric(horizontal: context.vw(3.6)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.pill),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Text(
          label,
          style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: onTap == null ? RyzeColors.mute2 : RyzeColors.ink)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}
