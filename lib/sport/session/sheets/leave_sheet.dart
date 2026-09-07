import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../services/translations.dart';

/// Ce qu'on fait d'une séance qu'on quitte.
enum LeaveChoice { stay, pause, finish, abandon }

/// La réponse de `PopScope` : plus jamais une fermeture silencieuse.
///
/// *Continuer* ne fait rien. *Mettre en pause* garde le brouillon, qu'on
/// retrouve dans l'onglet Sport. *Terminer* n'apparaît que s'il y a au moins
/// une série validée. *Abandonner* efface le brouillon, en rouge.
class LeaveSheet {
  LeaveSheet._();

  static Future<LeaveChoice> show(BuildContext context, {required String lang, required int doneSets}) async {
    final choice = await showRyzeSheet<LeaveChoice>(
      context,
      title: 'session_leave_title'.tr(lang),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          RyzeSheetRow(
            first: true,
            icon: LucideIcons.play,
            label: 'session_continue'.tr(lang),
            onTap: () => Navigator.pop(sheet, LeaveChoice.stay),
          ),
          RyzeSheetRow(
            icon: LucideIcons.pause,
            label: 'session_pause'.tr(lang),
            hint: 'session_pause_hint'.tr(lang),
            onTap: () => Navigator.pop(sheet, LeaveChoice.pause),
          ),
          if (doneSets > 0)
            RyzeSheetRow(
              icon: LucideIcons.check,
              label: 'session_finish'.tr(lang),
              onTap: () => Navigator.pop(sheet, LeaveChoice.finish),
            ),
          RyzeSheetRow(
            icon: LucideIcons.trash2,
            label: 'session_abandon'.tr(lang),
            danger: true,
            onTap: () => Navigator.pop(sheet, LeaveChoice.abandon),
          ),
        ],
      ),
    );
    return choice ?? LeaveChoice.stay;
  }
}
