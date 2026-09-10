import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design/design.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/ryze_dates.dart';
import '../services/translations.dart';
import '../services/unit_service.dart';
import '../services/workout_cache_service.dart';
import '../widgets/exercise/exercise_detail_page.dart';
import 'sheets/session_recap_sheet.dart';
import 'sport_data.dart';
import 'widgets/session_timeline.dart';

/// L'historique : douze semaines de jours, chacun avec son anneau.
///
/// Le calque de l'historique Nutrition, porté à 84 jours parce que le sport
/// se lit sur plus long. Un jour porte un anneau navy (musculation), un
/// anneau à bord ambre (cardio), les deux, ou rien. Le jour choisi liste
/// ses séances ; en dessous, « Tes exercices » — les plus travaillés, avec
/// leur meilleure charge — ouvre la page de détail de chacun, là où
/// l'analyse guide. Plus de grille mensuelle.
class SportHistoryPage extends StatefulWidget {
  const SportHistoryPage({super.key});

  @override
  State<SportHistoryPage> createState() => _SportHistoryPageState();
}

class _SportHistoryPageState extends State<SportHistoryPage> with GlobalStateListener {
  static const int _days = 84;

  late DateTime _selected;
  Map<String, Set<SportKind>> _kinds = const {};
  List<SportSessionRow> _rows = const [];
  List<dynamic> _top = const [];
  bool _loadingDay = true;

  final ScrollController _strip = ScrollController();

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _selected = _today;
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd(animated: false));
  }

  @override
  void dispose() {
    _strip.dispose();
    super.dispose();
  }

  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    switch (event.type) {
      case ChangeType.workout:
      case ChangeType.sport:
      case ChangeType.planner:
      case ChangeType.dayReset:
      case ChangeType.batch:
        _load();
      default:
        break;
    }
  }

  void _scrollToEnd({bool animated = true}) {
    if (!_strip.hasClients) return;
    final max = _strip.position.maxScrollExtent;
    if (animated) {
      _strip.animateTo(max, duration: RyzeDurations.enter, curve: RyzeCurves.out);
    } else {
      _strip.jumpTo(max);
    }
  }

  Future<void> _load() async {
    final from = _today.subtract(const Duration(days: _days - 1));
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final results = await Future.wait<Object?>([
      SportData.kinds(from: from, to: _today),
      userId == null ? Future.value(const <dynamic>[]) : WorkoutCacheService.getTopExercises(userId).catchError((_) => const <dynamic>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _kinds = results[0] as Map<String, Set<SportKind>>;
      _top = (results[1] as List<dynamic>).take(6).toList();
    });
    await _loadDay();
  }

  Future<void> _loadDay() async {
    setState(() => _loadingDay = true);
    final rows = await SportData.onDay(_selected);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loadingDay = false;
    });
  }

  void _select(DateTime d) {
    RyzeFeedback.tap();
    setState(() => _selected = d);
    _loadDay();
  }

  Future<void> _open(SportSessionRow row) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final action = await SessionRecapSheet.show(context, lang: lang, row: row);
    if (!mounted) return;
    if (action == RecapAction.delete) {
      setState(() => _rows = _rows.where((r) => r.id != row.id).toList());
      SessionDeletion.schedule(context, lang: lang, row: row, onRestore: _load, onDeleted: _load);
    } else if (action == RecapAction.edited) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final units = UnitService.instance;

    return ListView(
      padding: EdgeInsets.fromLTRB(0, context.vw(2), 0, 132),
      children: [
        SizedBox(
          height: DayChip.stripHeight(context),
          child: ListView.builder(
            controller: _strip,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: _days,
            itemBuilder: (context, i) {
              final d = _today.subtract(Duration(days: _days - 1 - i));
              final kinds = _kinds[SportData.dayKey(d)] ?? const <SportKind>{};
              return _DayChip(
                lang: lang,
                date: d,
                selected: d == _selected,
                kinds: kinds,
                monday: d.weekday == DateTime.monday,
                onTap: () => _select(d),
              );
            },
          ),
        ),
        SizedBox(height: context.vw(5)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(RyzeDates.full(_selected, lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600))),
                  if (_rows.isNotEmpty) Text('${_rows.length}', style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
                ],
              ),
              SizedBox(height: context.vw(2.6)),
              if (_loadingDay)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.vw(6)),
                  child: Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2)),
                )
              else if (_rows.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.vw(4), horizontal: context.vw(2)),
                  child: Text('sport_no_session_day'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
                )
              else
                SessionTimeline(lang: lang, rows: _rows, onTap: _open),
              if (_top.isNotEmpty) ...[
                SizedBox(height: context.vw(7)),
                Text('sport_your_exercises'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                SizedBox(height: context.vw(2.6)),
                Container(
                  decoration: BoxDecoration(
                    color: RyzeColors.surf,
                    borderRadius: BorderRadius.circular(RyzeRadius.md),
                    border: Border.all(color: RyzeColors.line),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _top.length; i++)
                        _ExerciseLine(
                          first: i == 0,
                          name: '${_top[i]['name'] ?? ''}',
                          times: _times(lang, (_top[i]['sessions'] as num?)?.toInt() ?? 0),
                          best: _best(_top[i], units, lang),
                          onTap: () {
                            RyzeFeedback.tap();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailPage(exerciseName: '${_top[i]['name'] ?? ''}')));
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// « 1 fois » a sa forme, comme partout ailleurs.
  static String _times(String lang, int n) =>
      n == 1 ? 'sport_times_one'.tr(lang) : 'sport_times_n'.tr(lang).replaceAll('{n}', '$n');

  static String? _best(dynamic e, UnitService units, String lang) {
    final w = (e['maxWeight'] as num?)?.toDouble() ?? 0;
    final r = (e['maxReps'] as num?)?.toInt() ?? 0;
    if (w <= 0) return null;
    final ws = units.weightText(w, lang);
    return r > 0 ? '$ws ${units.weightUnit} × $r' : '$ws ${units.weightUnit}';
  }
}

/// Un jour de la bande : la lettre, le numéro, et l'anneau qui dit ce qui
/// s'y est passé — la même forme que sur le rail.
class _DayChip extends StatelessWidget {
  const _DayChip({required this.lang, required this.date, required this.selected, required this.kinds, required this.monday, required this.onTap});

  final String lang;
  final DateTime date;
  final bool selected;
  final Set<SportKind> kinds;

  /// Un lundi ouvre une semaine : il prend un peu d'air a sa gauche. Sur
  /// douze semaines, c'est ce qui rend la bande lisible.
  final bool monday;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gap = DayChip.gap(context) / 2;
    return Padding(
      padding: EdgeInsets.only(left: monday ? gap * 3 : gap, right: gap),
      child: DayChip(
        day: date,
        lang: lang,
        selected: selected,
        onTap: onTap,
        marker: _Marks(kinds: kinds, selected: selected),
      ),
    );
  }
}

/// Ce que le jour a porte : la muscu remplit, le cardio cercle — la meme
/// forme que sur le rail de la semaine. Un point gris quand il n'y a rien.
class _Marks extends StatelessWidget {
  const _Marks({required this.kinds, required this.selected});

  final Set<SportKind> kinds;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final strength = kinds.contains(SportKind.strength);
    final cardio = kinds.contains(SportKind.cardio);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (strength)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: selected ? RyzeColors.surf : RyzeColors.ink, shape: BoxShape.circle),
          ),
        if (strength && cardio) const SizedBox(width: 3),
        if (cardio)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? RyzeColors.surf : RyzeColors.acc, width: 2),
            ),
          ),
        if (!strength && !cardio)
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: selected ? RyzeColors.surf.withValues(alpha: 0.35) : RyzeColors.idle, shape: BoxShape.circle),
          ),
      ],
    );
  }
}

class _ExerciseLine extends StatelessWidget {
  const _ExerciseLine({required this.first, required this.name, required this.times, required this.best, required this.onTap});

  final bool first;
  final String name;
  final String times;
  final String? best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: RyzeColors.line))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                  Text(times, style: RyzeText.body(context, 2.9, color: RyzeColors.mute)),
                ],
              ),
            ),
            if (best != null)
              Text(best!, style: RyzeText.body(context, 3.4, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            SizedBox(width: context.vw(2.1)),
            Icon(LucideIcons.trendingUp, size: context.vw(4.1), color: RyzeColors.mute2),
          ],
        ),
      ),
    );
  }
}
