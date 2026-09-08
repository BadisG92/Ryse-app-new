import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/design.dart';
import '../services/localization_service.dart';
import '../services/localized_exercise_service.dart';
import '../services/translations.dart';

/// « Comment faire » un exercice : la description, les étapes, la vidéo.
///
/// Même contrat qu'avant (`show(context, exerciseId:, exerciseName:)` et le
/// cache mémoire par exercice) sur une `showRyzeSheet`. Les étapes arrivent
/// de Supabase séparées par des barres verticales ; on les numérote, ce qui
/// est la seule chose que l'utilisateur regarde entre deux séries.
class ExerciseInfoBottomSheet {
  ExerciseInfoBottomSheet._();

  static final Map<String, Map<String, dynamic>> _cache = {};

  static void show(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
  }) {
    final lang = LocalizationService.instance.currentLanguageCode;
    showRyzeSheet<void>(
      context,
      title: exerciseName,
      subtitle: 'exercise_how_to_perform'.tr(lang),
      builder: (_) => _Content(
        exerciseId: exerciseId,
        cached: _cache[exerciseId],
        onLoaded: (data) => _cache[exerciseId] = data,
      ),
    );
  }

  /// Vide le cache (au changement de langue).
  static void clearCache() => _cache.clear();
}

class _Content extends StatefulWidget {
  const _Content({required this.exerciseId, required this.cached, required this.onLoaded});

  final String exerciseId;
  final Map<String, dynamic>? cached;
  final ValueChanged<Map<String, dynamic>> onLoaded;

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.cached != null) {
      _data = widget.cached;
      _loading = false;
      return;
    }
    try {
      final data = await LocalizedExerciseService.getExerciseEnrichedDetails(widget.exerciseId);
      if (!mounted) return;
      if (data != null) widget.onLoaded(data);
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  static List<String> _steps(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _openTutorial(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    RyzeFeedback.tap();
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        if (mounted) RyzeUndo.failed(context, message: 'exercise_error'.tr(LocalizationService.instance.currentLanguageCode));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguageCode;

    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(10)),
        child: Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2)),
      );
    }
    if (_failed || _data == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(8)),
        child: Center(child: Text('exercise_error'.tr(lang), style: RyzeText.body(context, 3.6, color: RyzeColors.mute))),
      );
    }

    final d = _data!;
    final description = d['localized_description'] as String?;
    final muscleGroup = d['localized_muscle_group'] as String?;
    final equipment = d['equipment'] as String?;
    final steps = _steps(d['localized_instructions'] as String?);
    final url = d['localized_search_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if ((muscleGroup != null && muscleGroup.isNotEmpty) || (equipment != null && equipment.isNotEmpty)) ...[
          Wrap(
            spacing: context.vw(2.1),
            runSpacing: context.vw(1.5),
            children: [
              if (muscleGroup != null && muscleGroup.isNotEmpty) _Tag(text: muscleGroup),
              if (equipment != null && equipment.isNotEmpty) _Tag(text: equipment),
            ],
          ),
          SizedBox(height: context.vw(3.6)),
        ],
        if (description != null && description.trim().isNotEmpty) ...[
          Text(description, style: RyzeText.body(context, 3.6, color: RyzeColors.mute, height: 1.45)),
          SizedBox(height: context.vw(4.1)),
        ],
        if (steps.isEmpty)
          Text('exercise_no_instructions'.tr(lang), style: RyzeText.body(context, 3.6, color: RyzeColors.mute))
        else
          Container(
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: BorderRadius.circular(RyzeRadius.md),
              border: Border.all(color: RyzeColors.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++) _Step(number: i + 1, text: steps[i], first: i == 0),
              ],
            ),
          ),
        if (url != null && url.isNotEmpty) ...[
          SizedBox(height: context.vw(4.1)),
          Pressable(
            onTap: () => _openTutorial(url),
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
                  Icon(LucideIcons.play, size: context.vw(4.1), color: RyzeColors.ink),
                  SizedBox(width: context.vw(2.1)),
                  Text('exercise_watch_tutorial'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.vw(3.1), vertical: context.vw(1.3)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.pill),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Text(text, style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, required this.first});

  final int number;
  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
      decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: RyzeColors.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.vw(6.7),
            height: context.vw(6.7),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: RyzeColors.ink, shape: BoxShape.circle),
            child: Text('$number', style: RyzeText.body(context, 2.9, weight: FontWeight.w600, color: RyzeColors.surf)),
          ),
          SizedBox(width: context.vw(3.1)),
          Expanded(child: Text(text, style: RyzeText.body(context, 3.4, height: 1.4))),
        ],
      ),
    );
  }
}
