import '../services/translations.dart';
import 'arc_state.dart';
import 'arc_words.dart';

/// Le bloc `arc` que l'app écrit pour le widget du Winter Arc.
///
/// Comme pour les autres widgets (WIDGET.md), l'app décide de tout et le
/// natif ne fait que poser : le jour, les cases, le mot d'ordre et la ligne
/// d'état arrivent déjà écrits, dans la langue de l'app. Null tant que l'app
/// ne connaît pas l'arc : le widget montre alors son état vide.
class ArcWidgetData {
  ArcWidgetData._();

  static const Map<ArcCell, String> _letters = {
    ArcCell.held: 'h',
    ArcCell.trained: 't',
    ArcCell.joker: 'j',
    ArcCell.pending: 'p',
  };

  static Map<String, dynamic>? build(ArcState? s, String lang, {DateTime? now}) {
    if (s == null) return null;
    final tagOpen = 'widget_arc_tag_open'.tr(lang);
    final stale = 'widget_arc_stale'.tr(lang);

    // Un état gardé d'un autre jour (le cache, avant la réponse de la base)
    // ne dit rien d'aujourd'hui : le widget attend, il ne montre pas hier
    // comme tenu. La réponse de la base réécrit dans la foulée.
    final d = now ?? DateTime.now();
    final fresh = s.today.year == d.year && s.today.month == d.month && s.today.day == d.day;

    if (s.isSoon) {
      return {
        'soon': true,
        'day': 0,
        'held': false,
        'won': false,
        'cells': '',
        'tag': tagOpen,
        'tag_open': tagOpen,
        'status': fresh ? 'arc_card_soon'.tr(lang).replaceAll('{date}', ArcWords.date(ArcSeason.opens, lang)) : stale,
        'lock': 'arc_name'.tr(lang),
        'stale': stale,
      };
    }

    final today = s.todayStatus;
    final held = s.won || (fresh && s.todayHeld);
    final day = s.won ? ArcSeason.length : s.dayNumber;
    final String status;
    if (s.isEnded) {
      status = 'arc_page_sub_ended'.tr(lang);
    } else if (s.won) {
      status = 'arc_card_won'.tr(lang);
    } else if (!fresh) {
      status = stale;
    } else if (held) {
      status = 'widget_arc_held'.tr(lang);
    } else if (today != null && (today.mealsMissing > 0 || today.waterMissingMl > 0)) {
      status = 'widget_arc_missing'
          .tr(lang)
          .replaceAll('{missing}', ArcWords.missing(meals: today.mealsMissing, waterMl: today.waterMissingMl, lang: lang));
    } else {
      status = 'widget_arc_start'.tr(lang);
    }

    // Sans série, aujourd'hui est la première case, encore à tenir.
    final cells = s.cells.isEmpty ? 'p' : s.cells.take(ArcSeason.length).map((c) => _letters[c]).join();
    return {
      'soon': false,
      'day': day,
      'held': held,
      'won': s.won,
      'cells': cells,
      'tag': held ? 'widget_arc_tag_held'.tr(lang) : tagOpen,
      // Le lendemain, tant que l'app n'a pas réécrit, le widget ne devine pas
      // si la veille a été tenue : il reprend le mot d'ordre et invite à
      // ouvrir l'app.
      'tag_open': tagOpen,
      'status': status,
      'lock': 'widget_arc_lock'.tr(lang).replaceAll('{n}', '$day'),
      'stale': stale,
    };
  }
}
