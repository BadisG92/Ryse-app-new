import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../design/design.dart';
import '../models/sport_models.dart';
import '../services/database_service.dart';
import '../services/localization_service.dart';
import '../services/offline_workout_service.dart';
import '../services/ryze_connectivity.dart';
import '../services/translations.dart';
import 'sheets/program_detail_sheet.dart';
import 'sport_start.dart';

/// La bibliothèque : tes programmes, puis ceux de Ryze.
///
/// Une carte par programme (nom, exercices, durée, qui l'a créé), la feuille
/// de détail au tap, « Commencer » dedans. En mode *choix* (depuis la feuille
/// de départ) la page rend le programme au lieu de le lancer. Hors ligne, le
/// cache du catalogue sert, puis les programmes de départ : jamais une page
/// vide parce que la salle n'a pas de signal.
class SportProgramsPage extends StatefulWidget {
  const SportProgramsPage({super.key, this.picker = false});

  final bool picker;

  /// Ouvre la bibliothèque en mode choix et rend le programme choisi.
  static Future<WorkoutProgram?> pick(BuildContext context) {
    return Navigator.of(context).push<WorkoutProgram>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          backgroundColor: RyzeColors.paper,
          body: Stack(
            children: [
              OnbBackground(scene: false),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _PickerHeader(),
                    Expanded(child: SportProgramsPage(picker: true)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<SportProgramsPage> createState() => _SportProgramsPageState();
}

class _SportProgramsPageState extends State<SportProgramsPage> {
  List<WorkoutProgram> _all = const [];
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lang = LocalizationService.instance.currentLanguageCode;
    List<WorkoutProgram> list = const [];
    var offline = false;
    if (RyzeConnectivity.instance.online.value) {
      try {
        list = await DatabaseService.getWorkoutTemplates(language: lang, includePublic: true).timeout(const Duration(seconds: 8));
      } catch (_) {
        list = const [];
      }
    }
    if (list.isEmpty) {
      offline = true;
      try {
        list = await OfflineWorkoutService().getCachedTemplates();
      } catch (_) {}
      if (list.isEmpty) {
        try {
          list = await DatabaseService.getWorkoutTemplatesInstant(language: lang);
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() {
      _all = list;
      _offline = offline && list.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _open(WorkoutProgram p) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    if (widget.picker) {
      final start = await ProgramDetailSheet.show(context, lang: lang, program: p);
      if (start && mounted) Navigator.of(context).pop(p);
      return;
    }
    final start = await ProgramDetailSheet.show(context, lang: lang, program: p);
    if (!start || !mounted) return;
    await SportStart.program(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final yours = _all.where((p) => p.isCustom).toList();
    final ryze = _all.where((p) => !p.isCustom).toList();

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2));
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, context.vw(2), gutter, 132),
      children: [
        if (_offline)
          Padding(
            padding: EdgeInsets.only(bottom: context.vw(3.1)),
            child: Text('sport_offline_programs'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
          ),
        if (_all.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(12), horizontal: context.vw(6)),
            child: Text('sport_no_programs'.tr(lang), textAlign: TextAlign.center, style: RyzeText.body(context, 3.6, color: RyzeColors.mute)),
          ),
        if (yours.isNotEmpty) ...[
          _Header(title: 'sport_programs_yours'.tr(lang), count: yours.length),
          for (var i = 0; i < yours.length; i++)
            PopIn(delay: Duration(milliseconds: 40 * i), dy: 8, child: ProgramCard(lang: lang, program: yours[i], onTap: () => _open(yours[i]))),
          SizedBox(height: context.vw(5)),
        ],
        if (ryze.isNotEmpty) ...[
          _Header(title: 'sport_programs_ryze'.tr(lang), count: ryze.length),
          for (var i = 0; i < ryze.length; i++)
            PopIn(delay: Duration(milliseconds: 40 * (i + yours.length)), dy: 8, child: ProgramCard(lang: lang, program: ryze[i], onTap: () => _open(ryze[i]))),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(2.6)),
      child: Row(
        children: [
          Expanded(child: Text(title, style: RyzeText.body(context, 3.9, weight: FontWeight.w600))),
          Text('$count', style: RyzeText.body(context, 3.4, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// Une carte de programme, sur le même dessin que les recettes.
class ProgramCard extends StatelessWidget {
  const ProgramCard({super.key, required this.lang, required this.program, required this.onTap});

  final String lang;
  final WorkoutProgram program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final groups = program.exercises.map((e) => e.exercise.muscleGroup).where((g) => g.isNotEmpty).toSet().take(3).join(' · ');
    final by = program.isFromAI ? 'sport_by_ryze'.tr(lang) : (program.isCustom ? 'sport_by_you'.tr(lang) : null);
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: context.vw(2.6)),
        padding: EdgeInsets.all(context.vw(4.1)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: context.vw(11.3),
              height: context.vw(11.3),
              decoration: BoxDecoration(
                color: program.isCustom ? RyzeColors.ink : RyzeColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: program.isCustom ? RyzeColors.ink : RyzeColors.line),
              ),
              child: Icon(
                program.isFromAI ? LucideIcons.sparkles : LucideIcons.dumbbell,
                size: context.vw(5.1),
                color: program.isCustom ? RyzeColors.surf : RyzeColors.ink,
              ),
            ),
            SizedBox(width: context.vw(3.6)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(program.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                  SizedBox(height: context.vw(0.5)),
                  Text(
                    [
                      'sport_program_exercises'.tr(lang).replaceAll('{n}', '${program.exercises.length}'),
                      if (program.estimatedDuration > 0) 'sport_program_minutes'.tr(lang).replaceAll('{n}', '${program.estimatedDuration}'),
                      if (by != null) by,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                  ),
                  if (groups.isNotEmpty) ...[
                    SizedBox(height: context.vw(0.5)),
                    Text(groups, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 2.9, color: RyzeColors.mute2)),
                  ],
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: context.vw(4.6), color: RyzeColors.mute2),
          ],
        ),
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  const _PickerHeader();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, context.vw(1.5), gutter, context.vw(2.1)),
      child: Row(
        children: [
          Pressable(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: context.vw(9.7),
              height: context.vw(9.7),
              decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
              child: Icon(LucideIcons.chevronLeft, size: context.vw(4.6), color: RyzeColors.ink),
            ),
          ),
          SizedBox(width: context.vw(3.1)),
          Expanded(child: Text('sport_pick_program'.tr(lang), style: RyzeText.body(context, 4.1, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}
