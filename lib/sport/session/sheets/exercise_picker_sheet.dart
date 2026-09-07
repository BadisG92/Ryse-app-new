import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design/design.dart';
import '../../../models/sport_models.dart';
import '../../../services/database_service.dart';
import '../../../services/translations.dart';

/// Choisir un exercice, en une feuille.
///
/// L'ancien écran empilait trois modales : 812 lignes de recherche, puis une
/// feuille de filtres, puis un dialogue « combien de séries ? ». Ici un champ
/// (le seul endroit où le clavier système a sa place), les groupes
/// musculaires en puces, les rangées, et — quand rien ne correspond — une
/// première rangée qui crée l'exercice tel qu'on l'a tapé. Le catalogue vient
/// de `getSystemExercises`, qui sait lire son cache hors ligne.
class ExercisePickerSheet {
  ExercisePickerSheet._();

  static Future<Exercise?> show(BuildContext context, {required String lang, Exercise? replacing}) {
    return showRyzeSheet<Exercise>(
      context,
      title: replacing == null ? 'session_add_exercise'.tr(lang) : 'session_replace'.tr(lang),
      subtitle: replacing?.name,
      keyboard: true,
      builder: (sheet) => _Picker(lang: lang),
    );
  }
}

class _Picker extends StatefulWidget {
  const _Picker({required this.lang});

  final String lang;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  final TextEditingController _query = TextEditingController();
  List<Exercise> _all = const [];
  bool _loading = true;
  String? _group;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await DatabaseService.getSystemExercises();
      if (mounted) setState(() => _all = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static String _fold(String s) {
    var out = s.toLowerCase();
    const map = {'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'à': 'a', 'â': 'a', 'î': 'i', 'ï': 'i', 'ô': 'o', 'ù': 'u', 'û': 'u', 'ç': 'c'};
    map.forEach((a, b) => out = out.replaceAll(a, b));
    return out;
  }

  List<Exercise> get _shown {
    final q = _fold(_query.text.trim());
    var list = _all;
    if (_group != null) list = list.where((e) => e.muscleGroup == _group).toList();
    if (q.isNotEmpty) {
      final words = q.split(RegExp(r'\s+'));
      list = list.where((e) {
        final name = _fold(e.name);
        return words.every(name.contains);
      }).toList()
        ..sort((a, b) {
          final an = _fold(a.name).startsWith(q) ? 0 : 1;
          final bn = _fold(b.name).startsWith(q) ? 0 : 1;
          return an != bn ? an.compareTo(bn) : a.name.compareTo(b.name);
        });
    }
    return list.take(80).toList();
  }

  List<String> get _groups {
    final set = <String>{};
    for (final e in _all) {
      if (e.muscleGroup.trim().isNotEmpty) set.add(e.muscleGroup);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _create() async {
    final name = _query.text.trim();
    if (name.isEmpty) return;
    RyzeFeedback.confirm();
    final created = await DatabaseService.createCustomExercise(name: name, muscleGroup: _group ?? '');
    if (!mounted) return;
    if (created == null) {
      RyzeUndo.failed(context, message: 'undo_offline'.tr(widget.lang));
      return;
    }
    Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final shown = _shown;
    final query = _query.text.trim();
    final exact = shown.any((e) => _fold(e.name) == _fold(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.pill),
            border: Border.all(color: RyzeColors.line),
          ),
          child: TextField(
            controller: _query,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: RyzeText.body(context, 3.9),
            cursorColor: RyzeColors.ink,
            decoration: InputDecoration(
              hintText: 'session_search_exercise'.tr(lang),
              hintStyle: RyzeText.body(context, 3.9, color: RyzeColors.mute2),
              prefixIcon: Icon(LucideIcons.search, size: context.vw(4.6), color: RyzeColors.mute),
              suffixIcon: query.isEmpty
                  ? null
                  : Pressable(
                      onTap: () {
                        RyzeFeedback.tap();
                        _query.clear();
                      },
                      child: Icon(LucideIcons.x, size: context.vw(4.6), color: RyzeColors.mute),
                    ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
            ),
          ),
        ),
        if (_groups.isNotEmpty) ...[
          SizedBox(height: context.vw(2.6)),
          SizedBox(
            height: context.vw(9.2),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _groups.length,
              separatorBuilder: (_, __) => SizedBox(width: context.vw(2.1)),
              itemBuilder: (_, i) {
                final g = _groups[i];
                final on = g == _group;
                return Pressable(
                  onTap: () {
                    RyzeFeedback.tap();
                    setState(() => _group = on ? null : g);
                  },
                  child: AnimatedContainer(
                    duration: RyzeDurations.tap,
                    curve: RyzeCurves.out,
                    padding: EdgeInsets.symmetric(horizontal: context.vw(3.6)),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? RyzeColors.ink : RyzeColors.surf,
                      borderRadius: BorderRadius.circular(RyzeRadius.pill),
                      border: Border.all(color: on ? RyzeColors.ink : RyzeColors.line),
                    ),
                    child: Text(g, style: RyzeText.body(context, 3.3, weight: FontWeight.w600, color: on ? RyzeColors.surf : RyzeColors.ink)),
                  ),
                );
              },
            ),
          ),
        ],
        SizedBox(height: context.vw(3.1)),
        if (_loading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(8)),
            child: const Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2)),
          )
        else
          RyzeSheetGroup(
            children: [
              if (query.isNotEmpty && !exact)
                RyzeSheetRow(
                  first: true,
                  icon: LucideIcons.plus,
                  label: 'session_create_exercise'.tr(lang).replaceAll('{q}', query),
                  hint: _group,
                  onTap: _create,
                ),
              if (shown.isEmpty && (query.isEmpty || exact))
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.vw(6)),
                  child: Center(
                    child: Text('recipe_none_found'.tr(lang), style: RyzeText.body(context, 3.6, color: RyzeColors.mute)),
                  ),
                ),
              for (var i = 0; i < shown.length; i++)
                RyzeSheetRow(
                  first: i == 0 && (query.isEmpty || exact),
                  icon: shown[i].isCustom ? LucideIcons.bookmark : LucideIcons.dumbbell,
                  label: shown[i].name,
                  hint: shown[i].muscleGroup.isEmpty ? null : shown[i].muscleGroup,
                  onTap: () => Navigator.pop(context, shown[i]),
                ),
            ],
          ),
      ],
    );
  }
}
