import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../models/sport_models.dart';
import '../../services/translations.dart';

enum StartKind { free, program, redo, coach, cardio, hiit, declare }

/// Ce que l'utilisateur a choisi dans la feuille de départ.
class StartChoice {
  const StartChoice(this.kind, {this.program});

  final StartKind kind;
  final WorkoutProgram? program;
}

/// L'analogue sportif de la feuille « ajouter un aliment » : une seule
/// feuille pour les huit anciennes façons de commencer.
///
/// En tête, *Refaire* — les derniers programmes de l'utilisateur en puces,
/// le « je remange la même chose » du sport. Puis les façons, en rangées.
class StartSessionSheet {
  StartSessionSheet._();

  static Future<StartChoice?> show(BuildContext context, {required String lang, List<WorkoutProgram> redo = const []}) {
    return showRyzeSheet<StartChoice>(
      context,
      title: 'sport_start_session'.tr(lang),
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (redo.isNotEmpty) ...[
            Text('sport_redo'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
            SizedBox(height: context.vw(2.1)),
            SizedBox(
              height: context.vw(9.7),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: redo.length,
                separatorBuilder: (_, __) => SizedBox(width: context.vw(2.1)),
                itemBuilder: (_, i) => Pressable(
                  onTap: () {
                    RyzeFeedback.select();
                    Navigator.pop(sheet, StartChoice(StartKind.redo, program: redo[i]));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.vw(3.6)),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RyzeColors.surf,
                      borderRadius: BorderRadius.circular(RyzeRadius.pill),
                      border: Border.all(color: RyzeColors.ink),
                    ),
                    child: Row(
                      children: [
                        Icon(redo[i].isFromAI ? LucideIcons.sparkles : LucideIcons.bookmark, size: context.vw(3.6), color: RyzeColors.ink),
                        SizedBox(width: context.vw(1.5)),
                        Text(redo[i].name, style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.vw(4.1)),
          ],
          RyzeSheetGroup(
            children: [
              RyzeSheetRow(
                first: true,
                icon: LucideIcons.dumbbell,
                label: 'sport_free_strength'.tr(lang),
                hint: 'sport_free_strength_hint'.tr(lang),
                onTap: () => Navigator.pop(sheet, const StartChoice(StartKind.free)),
              ),
              RyzeSheetRow(
                icon: LucideIcons.listChecks,
                label: 'sport_pick_program'.tr(lang),
                hint: 'sport_pick_program_hint'.tr(lang),
                onTap: () => Navigator.pop(sheet, const StartChoice(StartKind.program)),
              ),
              RyzeSheetRow(
                icon: LucideIcons.sparkles,
                label: 'sport_coach_ryze'.tr(lang),
                hint: 'sport_coach_ryze_hint'.tr(lang),
                onTap: () => Navigator.pop(sheet, const StartChoice(StartKind.coach)),
              ),
              RyzeSheetRow(
                icon: LucideIcons.footprints,
                label: 'sport_cardio'.tr(lang),
                hint: 'sport_cardio_hint'.tr(lang),
                onTap: () => Navigator.pop(sheet, const StartChoice(StartKind.cardio)),
              ),
              RyzeSheetRow(
                icon: LucideIcons.zap,
                label: 'sport_hiit'.tr(lang),
                hint: 'sport_hiit_hint'.tr(lang),
                onTap: () => Navigator.pop(sheet, const StartChoice(StartKind.hiit)),
              ),
              RyzeSheetRow(
                icon: LucideIcons.pencilLine,
                label: 'sport_declare_past'.tr(lang),
                hint: 'sport_declare_past_hint'.tr(lang),
                onTap: () => Navigator.pop(sheet, const StartChoice(StartKind.declare)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
