import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/arc/arc_state.dart';
import 'package:ryze_app/arc/arc_widget_data.dart';

void main() {
  final day = DateTime(2026, 10, 10, 18);

  ArcState state(Map<String, dynamic> extra) => ArcState.fromJson({
        'phase': 'open',
        'today': '2026-10-10',
        'streak': 3,
        'cells': 'hthp',
        'eligible': true,
        ...extra,
      });

  test('rien tant que l\'app ne connaît pas l\'arc', () {
    expect(ArcWidgetData.build(null, 'fr'), isNull);
  });

  test('avant le 1er octobre : le mot d\'ordre et la date', () {
    final a = ArcWidgetData.build(ArcState.fromJson({'phase': 'soon', 'today': '2026-09-29'}), 'fr', now: DateTime(2026, 9, 29, 9))!;
    expect(a['soon'], isTrue);
    expect(a['day'], 0);
    expect(a['tag'], 'FOCUS.');
    expect(a['status'], contains('1'));
  });

  test('une journée à tenir : ce qui manque, le mot d\'ordre de la langue', () {
    final s = state({
      'today_status': {'held': false, 'meals': 1, 'water_ml': 1500, 'water_goal': 2000, 'trained': false},
    });
    final fr = ArcWidgetData.build(s, 'fr', now: day)!;
    expect(fr['day'], 4);
    expect(fr['held'], isFalse);
    expect(fr['cells'], 'hthp');
    expect(fr['tag'], 'FOCUS.');
    expect(fr['status'], startsWith('Encore '));
    expect(fr['lock'], 'Jour 4 / 90');
    // Le même mot d'ordre dans les trois langues.
    expect(ArcWidgetData.build(s, 'en', now: day)!['tag'], 'FOCUS.');
    expect(ArcWidgetData.build(s, 'de', now: day)!['tag'], 'FOCUS.');
  });

  test('une journée tenue : la victoire, et le mot d\'ordre du lendemain gardé pour le widget', () {
    final s = state({
      'cells': 'hthh',
      'today_status': {'held': true, 'meals': 2, 'water_ml': 2000, 'water_goal': 2000, 'trained': false},
    });
    final en = ArcWidgetData.build(s, 'en', now: day)!;
    expect(en['held'], isTrue);
    expect(en['tag'], 'LOCKED IN.');
    expect(en['tag_open'], 'FOCUS.');
    expect(en['status'], 'Day locked in');
    // L'allemand dit au widget où couper le mot.
    expect(ArcWidgetData.build(s, 'de', now: day)!['tag'], 'GE\u00ADSCHAFFT.');
  });

  test('sans série, aujourd\'hui est la première case', () {
    final s = state({'streak': 0, 'cells': ''});
    final a = ArcWidgetData.build(s, 'fr', now: day)!;
    expect(a['cells'], 'p');
    expect(a['day'], 1);
  });

  test('un état gardé de la veille ne montre pas hier comme tenu', () {
    final s = state({
      'cells': 'hthh',
      'today_status': {'held': true, 'meals': 2, 'water_ml': 2000, 'water_goal': 2000, 'trained': false},
    });
    final a = ArcWidgetData.build(s, 'fr', now: DateTime(2026, 10, 11, 7))!;
    expect(a['held'], isFalse);
    expect(a['tag'], 'FOCUS.');
    expect(a['status'], 'Ouvre Ryze pour ta journée');
  });

  test('aucun tiret cadratin dans ce que le widget affiche', () {
    final s = state({
      'today_status': {'held': false, 'meals': 0, 'water_ml': 0, 'water_goal': 2000, 'trained': false},
    });
    for (final lang in ['fr', 'en', 'de']) {
      final a = ArcWidgetData.build(s, lang, now: day)!;
      for (final v in a.values.whereType<String>()) {
        expect(v.contains('\u2014') || v.contains('\u2013'), isFalse, reason: '$lang: $v');
      }
    }
  });
}
