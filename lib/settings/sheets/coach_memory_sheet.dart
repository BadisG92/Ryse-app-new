import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ai/ryze_context.dart';
import '../../ai/ryze_memory.dart';
import '../../design/design.dart';
import '../../models/coach_chat_models.dart';
import '../../services/translations.dart';

/// Ce que Ryze retient de toi, et de quoi l'effacer.
///
/// La mémoire se remplissait toute seule, en relisant les conversations, et
/// personne ne pouvait la voir. Un coach qui retient une contrainte que
/// l'utilisateur ne s'explique pas, et qu'il ne peut pas retirer, ne peut pas
/// se corriger.
///
/// Ce que l'onboarding a recueilli s'affiche aussi, mais ne s'efface pas d'ici :
/// c'est le pourquoi de l'utilisateur, pas un détail alimentaire, et il se
/// change dans le profil.
class CoachMemorySheet {
  CoachMemorySheet._();

  static Future<void> show(BuildContext context, {required String lang}) {
    return showRyzeSheet<void>(
      context,
      title: 'coach_memory_title'.tr(lang),
      subtitle: 'coach_memory_subtitle'.tr(lang),
      builder: (sheet) => _MemoryBody(lang: lang),
    );
  }
}

class _MemoryBody extends StatefulWidget {
  const _MemoryBody({required this.lang});

  final String lang;

  @override
  State<_MemoryBody> createState() => _MemoryBodyState();
}

class _MemoryBodyState extends State<_MemoryBody> {
  UserCoachPreferences? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await RyzeMemory.instance.load(force: true);
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _forget(MemoryItem item) async {
    RyzeFeedback.removed();
    final ok = await RyzeMemory.instance.forget(item.category, item.text);
    if (!mounted) return;

    if (!ok) {
      RyzeUndo.failed(context, message: 'ryze_action_failed'.tr(widget.lang));
      return;
    }

    // Le bloc mémoire du prompt est refait au prochain envoi : la
    // conversation ouverte n'a pas à être reconstruite pour ça.
    RyzeContext.instance.invalidate({RyzeBlock.memory});
    await _load();

    if (!mounted) return;
    RyzeUndo.show(
      context,
      message: 'coach_memory_deleted'.tr(widget.lang).replaceAll('{fact}', item.text),
      undoLabel: 'undo'.tr(widget.lang),
      onUndo: () async {
        await RyzeMemory.instance.remember(item.category, item.text);
        RyzeContext.instance.invalidate({RyzeBlock.memory});
        await _load();
      },
    );
  }

  String _categoryLabel(MemoryCategory c) {
    const keys = {
      MemoryCategory.allergy: 'coach_memory_cat_allergies',
      MemoryCategory.fitnessConstraint: 'coach_memory_cat_fitness',
      MemoryCategory.dietaryRestriction: 'coach_memory_cat_dietary',
      MemoryCategory.foodPreference: 'coach_memory_cat_food',
      MemoryCategory.workoutTime: 'coach_memory_cat_times',
      MemoryCategory.note: 'coach_memory_cat_notes',
    };
    return keys[c]!.tr(widget.lang);
  }

  IconData _categoryIcon(MemoryCategory c) => switch (c) {
        MemoryCategory.allergy => LucideIcons.triangleAlert,
        MemoryCategory.fitnessConstraint => LucideIcons.heartPulse,
        MemoryCategory.dietaryRestriction => LucideIcons.salad,
        MemoryCategory.foodPreference => LucideIcons.heart,
        MemoryCategory.workoutTime => LucideIcons.clock,
        MemoryCategory.note => LucideIcons.stickyNote,
      };

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(8)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final items = RyzeMemory.itemsOf(_prefs);
    final insights = _prefs?.onboardingInsights?.trim() ?? '';

    if (items.isEmpty && insights.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(6)),
        child: Text(
          'coach_memory_empty'.tr(lang),
          textAlign: TextAlign.center,
          style: RyzeText.body(context, 3.7, color: RyzeColors.mute, height: 1.5),
        ),
      );
    }

    // Les tiroirs dans l'ordre où ils comptent : une allergie et une blessure
    // changent ce que Ryze a le droit de proposer, un goût ne fait qu'orienter.
    final byCategory = <MemoryCategory, List<MemoryItem>>{};
    for (final item in items) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(context.vw(1), context.vw(3.1), 0, context.vw(1.6)),
            child: Text(
              _categoryLabel(entry.key),
              style: RyzeText.body(context, 3.0, color: RyzeColors.mute, weight: FontWeight.w600),
            ),
          ),
          RyzeSheetGroup(
            children: [
              for (final item in entry.value)
                RyzeSheetRow(
                  first: item == entry.value.first,
                  icon: _categoryIcon(entry.key),
                  label: item.text,
                  hint: 'coach_memory_forget'.tr(lang),
                  danger: true,
                  onTap: () => _forget(item),
                ),
            ],
          ),
        ],
        if (insights.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(context.vw(1), context.vw(4.1), 0, context.vw(1.6)),
            child: Text(
              'coach_memory_cat_onboarding'.tr(lang),
              style: RyzeText.body(context, 3.0, color: RyzeColors.mute, weight: FontWeight.w600),
            ),
          ),
          Container(
            padding: EdgeInsets.all(context.vw(3.6)),
            decoration: BoxDecoration(
              color: RyzeColors.paper2,
              borderRadius: BorderRadius.circular(RyzeRadius.md),
              border: Border.all(color: RyzeColors.line),
            ),
            child: _Insights(text: insights),
          ),
          Padding(
            padding: EdgeInsets.only(top: context.vw(1.6), left: context.vw(1)),
            child: Text(
              'coach_memory_onboarding_hint'.tr(lang),
              style: RyzeText.body(context, 3.0, color: RyzeColors.mute),
            ),
          ),
        ],
        SizedBox(height: context.vw(2.1)),
      ],
    );
  }
}

/// Ce que l'onboarding a retenu, lisible.
///
/// C'était écrit en Markdown — « - **Objectif**: perdre du gras » — et posé
/// tel quel dans un `Text` : l'utilisateur voyait les tirets, les étoiles et
/// les deux-points. Ces lignes ne sont pas de la prose, ce sont des couples
/// intitulé/valeur : elles se rendent comme tels, et une ligne qui n'a pas
/// cette forme s'affiche telle quelle plutôt que de disparaître.
class _Insights extends StatelessWidget {
  const _Insights({required this.text});

  final String text;

  static final RegExp _line = RegExp(r'^\s*[-*]?\s*\*\*(.+?)\*\*\s*:?\s*(.*)$');

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value})>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = _line.firstMatch(line);
      if (m == null) {
        rows.add((label: '', value: line.replaceFirst(RegExp(r'^[-*]\s*'), '')));
      } else {
        rows.add((label: m.group(1)!.trim(), value: m.group(2)!.trim()));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) SizedBox(height: context.vw(3.1)),
          if (r.label.isNotEmpty)
            Text(
              r.label,
              style: RyzeText.body(context, 2.9, weight: FontWeight.w600, color: RyzeColors.mute2),
            ),
          if (r.label.isNotEmpty) SizedBox(height: context.vw(0.5)),
          Text(
            r.value,
            style: RyzeText.body(context, 3.4, height: 1.4),
          ),
        ],
      ],
    );
  }
}
