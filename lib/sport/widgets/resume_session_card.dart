import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/ryze_dates.dart';
import '../../services/translations.dart';
import '../../services/workout_session_store.dart';

/// « Séance de mardi en cours · Reprendre ».
///
/// Un brouillon existe : la séance a été mise en pause, ou l'app a été tuée.
/// La carte fait qu'un « Reprendre ? » refusé à l'ouverture n'est pas un
/// cul-de-sac.
class ResumeSessionCard extends StatelessWidget {
  const ResumeSessionCard({super.key, required this.lang, required this.draft, required this.onResume, required this.onDiscard});

  final String lang;
  final SessionDraft draft;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final started = DateTime.tryParse(draft.session['startedAt'] as String? ?? '') ?? draft.savedAt;
    final name = draft.session['name'] as String? ?? '';
    final exercises = (draft.session['exercises'] as List?)?.length ?? 0;

    return Pressable(
      onTap: () {
        RyzeFeedback.confirm();
        onResume();
      },
      child: Container(
        padding: EdgeInsets.all(context.vw(4.1)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.ink, width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: context.vw(10.8),
              height: context.vw(10.8),
              decoration: const BoxDecoration(color: RyzeColors.ink, shape: BoxShape.circle),
              child: Icon(LucideIcons.play, size: context.vw(4.6), color: RyzeColors.surf),
            ),
            SizedBox(width: context.vw(3.6)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'session_resume_card'.tr(lang).replaceAll('{day}', RyzeDates.full(started, lang)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
                  ),
                  SizedBox(height: context.vw(0.5)),
                  Text(
                    [if (name.isNotEmpty) name, '$exercises ${'exercises'.tr(lang).toLowerCase()}'].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.vw(2.1)),
            Pressable(
              onTap: () {
                RyzeFeedback.removed();
                onDiscard();
              },
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(LucideIcons.x, size: context.vw(4.1), color: RyzeColors.mute2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
