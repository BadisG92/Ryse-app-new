import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ryze_app/ai/prompts/persona_de.dart';
import 'package:ryze_app/ai/prompts/persona_en.dart';
import 'package:ryze_app/ai/prompts/persona_fr.dart';
import 'package:ryze_app/ai/ryze_context.dart';
import 'package:ryze_app/arc/arc_daily.dart';
import 'package:ryze_app/arc/arc_state.dart';
import 'package:ryze_app/arc/arc_words.dart';
import 'package:ryze_app/services/global_state_manager.dart';

/// Une réponse de `arc_state()` telle que la base la rend, prise sur un
/// scénario joué contre la vraie fonction (WINTER_ARC.md).
Map<String, dynamic> _answer({
  String cells = 'hpp',
  int streak = 1,
  Map<String, dynamic>? grace,
  Map<String, dynamic>? lastBreak,
  String? lastJoker,
  String? wonOn,
  bool held = false,
}) =>
    {
      'phase': 'open',
      'today': '2026-10-06',
      'tz': 'Europe/Paris',
      'streak': streak,
      'streak_start': streak > 0 ? '2026-10-04' : null,
      'cells': cells,
      'jokers': 0,
      'best': 2,
      'won_on': wonOn,
      'eligible': wonOn == null,
      'last_valid': '2026-10-04',
      'last_break': lastBreak,
      'last_joker': lastJoker,
      'today_status': {'held': held, 'meals': 1, 'water_ml': 1000, 'water_goal': 2000, 'trained': false},
      'grace': grace,
    };

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
    await initializeDateFormatting('de');
  });

  group('ArcState', () {
    test('lit la réponse de la base, grâce comprise', () {
      final s = ArcState.fromJson(_answer(grace: {
        'day': '2026-10-05',
        'meals': 1,
        'water_ml': 2000,
        'water_goal': 2000,
        'deadline': '2026-10-06T10:00:00+00:00',
      }));
      expect(s.isOpen, isTrue);
      expect(s.cells, [ArcCell.held, ArcCell.pending, ArcCell.pending]);
      expect(s.dayNumber, 3);
      expect(s.yesterdayCell, ArcCell.pending);
      expect(s.rescuable, isTrue);
      expect(s.grace!.mealsMissing, 1);
      expect(s.grace!.waterMissingMl, 0);
      expect(s.grace!.deadline.toUtc(), DateTime.utc(2026, 10, 6, 10));
      expect(s.todayStatus!.mealsMissing, 1);
      expect(s.todayStatus!.waterMissingMl, 1000);
      expect(s.finishOn, DateTime(2027, 1, 1));
    });

    test('sans série, aujourd\'hui est le jour 1', () {
      final s = ArcState.fromJson(_answer(cells: '', streak: 0));
      expect(s.dayNumber, 1);
      expect(s.yesterdayCell, isNull);
      expect(s.rescuable, isFalse);
    });

    test('garde tout en passant par le cache', () {
      final s = ArcState.fromJson(_answer(
        cells: 'hthjp',
        streak: 4,
        lastBreak: {'day': '2026-10-01', 'lost': 3},
        lastJoker: '2026-10-05',
      ));
      final back = ArcState.fromJson(s.toJson());
      expect(back.toJson(), s.toJson());
      expect(back.cells, [ArcCell.held, ArcCell.trained, ArcCell.held, ArcCell.joker, ArcCell.pending]);
      expect(back.lastBreak!.lost, 3);
    });

    test('la démo tient la même série que la flamme de démo', () {
      final s = ArcState.demo(DateTime(2026, 11, 3, 9));
      expect(s.streak, 12);
      expect(s.dayNumber, 13);
      expect(s.cells.last, ArcCell.pending);
    });
  });

  group('ArcSeason', () {
    test('les bornes de la saison', () {
      expect(ArcSeason.isOpen(DateTime(2026, 9, 30, 23, 59)), isFalse);
      expect(ArcSeason.isOpen(DateTime(2026, 10, 1)), isTrue);
      expect(ArcSeason.isOpen(DateTime(2027, 3, 20, 22)), isTrue);
      expect(ArcSeason.isOpen(DateTime(2027, 3, 21)), isFalse);
      expect(ArcSeason.canStartToWin(DateTime(2026, 12, 21, 23)), isTrue);
      expect(ArcSeason.canStartToWin(DateTime(2026, 12, 22)), isFalse);
    });
  });

  group('ArcWords', () {
    test('dit ce qui manque dans les trois langues', () {
      expect(ArcWords.missing(meals: 1, waterMl: 500, lang: 'fr'), '1 repas et 0,5 L d\'eau');
      expect(ArcWords.missing(meals: 2, waterMl: 0, lang: 'en'), '2 meals');
      expect(ArcWords.missing(meals: 0, waterMl: 1250, lang: 'de'), '1,3 L Wasser');
      expect(ArcWords.missing(meals: 0, waterMl: 0, lang: 'fr'), '');
    });

    test('30 ml qui manquent ne s\'écrivent pas 0 L', () {
      expect(ArcWords.litres(30, 'fr'), '0,1 L');
    });
  });

  group('La feuille du matin', () {
    ArcMorning pick(ArcState s, {bool intro = true, bool won = false, DateTime? breakSeen, DateTime? jokerSeen}) =>
        ArcDaily.pick(s, introSeen: intro, wonSeen: won, breakSeen: breakSeen, jokerSeen: jokerSeen);

    test('la première fois, l\'arc s\'annonce', () {
      expect(pick(ArcState.fromJson(_answer(cells: 'hhp', streak: 2)), intro: false), ArcMorning.intro);
    });

    test('hier tenu : sa case se remplit', () {
      expect(pick(ArcState.fromJson(_answer(cells: 'hhp', streak: 2))), ArcMorning.held);
      expect(pick(ArcState.fromJson(_answer(cells: 'htp', streak: 2))), ArcMorning.held);
    });

    test('hier incomplet avant midi passe avant tout le reste', () {
      final s = ArcState.fromJson(_answer(
        cells: 'hpp',
        grace: {'day': '2026-10-05', 'meals': 1, 'water_ml': 0, 'water_goal': 2000, 'deadline': '2026-10-06T10:00:00Z'},
        lastJoker: '2026-10-03',
      ));
      expect(pick(s), ArcMorning.grace);
    });

    test('une série perdue se dit une fois, et pas pour un seul jour', () {
      final s = ArcState.fromJson(_answer(cells: '', streak: 0, lastBreak: {'day': '2026-10-05', 'lost': 12}));
      expect(pick(s), ArcMorning.broke);
      expect(pick(s, breakSeen: DateTime(2026, 10, 5)), ArcMorning.none);
      final court = ArcState.fromJson(_answer(cells: '', streak: 0, lastBreak: {'day': '2026-10-05', 'lost': 1}));
      expect(pick(court), ArcMorning.none);
    });

    test('un joker utilisé se dit une fois', () {
      final s = ArcState.fromJson(_answer(cells: 'hhjp', streak: 3, lastJoker: '2026-10-05'));
      expect(pick(s), ArcMorning.joker);
      // Vu, il ne reste qu'une case gelée hier : rien d'autre à dire.
      expect(pick(s, jokerSeen: DateTime(2026, 10, 5)), ArcMorning.none);
    });

    test('la victoire passe en premier, même après la saison', () {
      final s = ArcState.fromJson({..._answer(cells: 'h' * 90, streak: 90, wonOn: '2026-12-29'), 'phase': 'ended'});
      expect(pick(s), ArcMorning.won);
      expect(pick(s, won: true), ArcMorning.none);
    });
  });

  group('Le bloc du coach', () {
    test('dit le jour, ce qui manque et le prix, dans la langue', () {
      final fr = RyzeContext.renderArc(
        const PersonaFr(),
        day: 34,
        streak: 33,
        todayHeld: false,
        mealsMissing: 1,
        waterMissingMl: 500,
        jokers: 1,
        eligible: true,
        won: false,
        finishOn: DateTime(2026, 12, 29),
      );
      expect(fr, contains('Jour 34/90'));
      expect(fr, contains('1 repas, 500 ml d\'eau'));
      expect(fr, contains('2026-12-29'));
      expect(fr.split('\n').length, lessThanOrEqualTo(7));

      for (final s in [const PersonaEn(), const PersonaDe()]) {
        final t = RyzeContext.renderArc(s, day: 1, streak: 0, todayHeld: true, mealsMissing: 0, waterMissingMl: 0, jokers: 0, eligible: false, won: false);
        expect(t.toLowerCase(), isNot(contains('aujourd')));
        expect(t, isNot(contains('arc_')));
      }
    });

    test('le bloc passe avant les mouvements connus', () {
      expect(RyzeBlock.values.indexOf(RyzeBlock.arc), lessThan(RyzeBlock.values.indexOf(RyzeBlock.exercises)));
      expect(RyzeContext.blocksFor(ChangeType.streak), contains(RyzeBlock.arc));
    });
  });
}
