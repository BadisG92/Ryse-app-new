import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/weekly_planner_models.dart';
import '../../services/translations.dart';
import 'cardio_recap_bottom_sheet.dart';
import 'proposal_card.dart';
import 'workout_recap_bottom_sheet.dart';

/// La feuille de détail d'une séance proposée : son en-tête, son récapitulatif
/// défilant, ses pastilles de page et ses deux boutons.
///
/// Elle vivait en privé dans l'écran du planificateur. La conversation en
/// propose pourtant les mêmes séances, avec les mêmes objets : elle en a
/// ouvert une sans le cadre, donc sur fond transparent, sans hauteur bornée
/// et sans boutons. Plutôt que d'en écrire une seconde qui aurait dérivé dès
/// la première retouche, c'est celle-ci qui est partagée.
///
/// Elle lit son état par des accesseurs et se redessine quand [version]
/// change : c'est ce qui lui permet de suivre l'écran qui la porte, quel
/// qu'il soit.
class SessionProposalSheet extends StatefulWidget {
  const SessionProposalSheet({
    super.key,
    required this.version,
    required this.langCode,
    required this.sessions,
    required this.currentIndex,
    required this.dayName,
    this.cardBuilder,
    required this.isConfirming,
    required this.onConfirm,
    required this.onCancel,
    required this.onIndexChanged,
  });

  final ValueListenable<int> version;
  final String langCode;
  final List<PendingSession>? Function() sessions;
  final int Function() currentIndex;
  final String Function(DateTime) dayName;
  /// Ce qui se met sous l'en-tête. Par défaut, le récapitulatif de la séance,
  /// qui est ce que les deux surfaces y mettaient déjà.
  final Widget Function(PendingSession)? cardBuilder;
  final bool Function() isConfirming;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final ValueChanged<int> onIndexChanged;

  @override
  State<SessionProposalSheet> createState() => _SessionProposalSheetState();
}

class _SessionProposalSheetState extends State<SessionProposalSheet> {
  bool _popping = false;

  void _pop() {
    if (_popping) return;
    _popping = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.version,
      builder: (context, _) {
        final sessions = widget.sessions();
        if (sessions == null || sessions.isEmpty) {
          _pop();
          return const SizedBox.shrink();
        }
        final n = sessions.length;
        final index = widget.currentIndex().clamp(0, n - 1);
        final session = sessions[index];
        final lang = widget.langCode;
        final sessionWord = 'planner_session_word'.tr(lang);
        final thisOne = 'planner_this_session'.tr(lang);
        return ryzeSheetFrame(
          context,
          child: Column(
            children: [
              ProposalHeader(
                icon: session.isWorkout ? LucideIcons.dumbbell : LucideIcons.activity,
                title: widget.dayName(session.plannedDate),
                subtitle: n > 1 ? '$sessionWord ${index + 1}/$n · ${session.displayTitle}' : session.displayTitle,
                paged: n > 1,
                canPrev: index > 0,
                canNext: index < n - 1,
                onPrev: () => widget.onIndexChanged(index - 1),
                onNext: () => widget.onIndexChanged(index + 1),
              ),
              Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 8), child: widget.cardBuilder?.call(session) ?? sessionRecap(session))),
              if (n > 1) ProposalPagerDots(count: n, index: index),
              ProposalActions(
                cancelLabel: 'planner_cancel'.tr(lang),
                confirmLabel: '${'planner_validate'.tr(lang)} $thisOne',
                onCancel: widget.onCancel,
                onConfirm: widget.onConfirm,
                busy: widget.isConfirming(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Le récapitulatif d'une séance proposée, celui des deux surfaces.
Widget sessionRecap(PendingSession session) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: session.isWorkout
          ? WorkoutRecapBottomSheet(workout: session.workout!.toPlannedWorkout(), isPreview: true)
          : CardioRecapBottomSheet(activity: session.cardio!.toPlannedActivity(), isPreview: true),
    );
