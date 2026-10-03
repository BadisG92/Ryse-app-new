import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:intl/intl.dart';

import '../../ai/ryze_context.dart';
import '../../ai/ryze_memory.dart';
import '../../design/design.dart';
import '../../models/coach_chat_models.dart';
import '../../screens/coach_chat_screen.dart';
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

  /// [dossierEntry] faux quand la feuille s'ouvre depuis la conversation
  /// elle-même : on n'ouvre pas une conversation par-dessus la conversation.
  static Future<void> show(BuildContext context, {required String lang, bool dossierEntry = true}) {
    return showRyzeSheet<void>(
      context,
      title: 'coach_memory_title'.tr(lang),
      subtitle: 'coach_memory_subtitle'.tr(lang),
      builder: (sheet) => _MemoryBody(lang: lang, dossierEntry: dossierEntry),
    );
  }
}

class _MemoryBody extends StatefulWidget {
  const _MemoryBody({required this.lang, required this.dossierEntry});

  final String lang;
  final bool dossierEntry;

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
      MemoryCategory.promise: 'coach_memory_cat_promises',
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
        MemoryCategory.promise => LucideIcons.handshake,
        MemoryCategory.dietaryRestriction => LucideIcons.salad,
        MemoryCategory.foodPreference => LucideIcons.heart,
        MemoryCategory.workoutTime => LucideIcons.clock,
        MemoryCategory.note => LucideIcons.stickyNote,
      };

  /// Le jour où le fait a été retenu, court, dans la langue du compte ; la
  /// date ISO si les données de locale manquent.
  String _since(DateTime d) {
    final lang = widget.lang;
    try {
      final locale = lang == 'fr' ? 'fr_FR' : (lang == 'de' ? 'de_DE' : 'en_US');
      return DateFormat.MMMd(locale).format(d);
    } catch (_) {
      return RyzeMemory.isoDay(d);
    }
  }

  String _rowHint(MemoryItem item) {
    final forget = 'coach_memory_forget'.tr(widget.lang);
    final d = item.date;
    if (d == null) return forget;
    return '${'coach_memory_since'.tr(widget.lang).replaceAll('{date}', _since(d))} · $forget';
  }

  /// Le dossier se demande au coach : la conversation s'ouvre par-dessus la
  /// feuille, la question déjà envoyée. La feuille attend derrière, on la
  /// retrouve en revenant.
  Future<void> _openDossier() async {
    final lang = widget.lang;
    await CoachChatScreen.open(context, initialMessage: 'coach_chat_suggestion_dossier'.tr(lang));
  }

  Widget _dossierRow(BuildContext context) {
    if (!widget.dossierEntry) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(1.0)),
      child: RyzeSheetGroup(
        children: [
          RyzeSheetRow(
            first: true,
            leading: RyzeMark(size: context.vw(4.6), color: RyzeColors.ink),
            label: 'dossier_entry'.tr(widget.lang),
            hint: 'dossier_entry_hint'.tr(widget.lang),
            onTap: _openDossier,
          ),
        ],
      ),
    );
  }

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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(6)),
            child: Text(
              'coach_memory_empty'.tr(lang),
              textAlign: TextAlign.center,
              style: RyzeText.body(context, 3.7, color: RyzeColors.mute, height: 1.5),
            ),
          ),
          _dossierRow(context),
          SizedBox(height: context.vw(2.1)),
        ],
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
        // Le dossier d'abord : c'est ce que tout ça devient quand le coach
        // le raconte.
        _dossierRow(context),
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
                  hint: _rowHint(item),
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
