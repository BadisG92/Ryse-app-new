import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/models/weekly_planner_models.dart';
import 'package:ryze_app/services/planner_ai_service.dart';

/// La fenêtre du planificateur : le reste de cette semaine et toute la
/// suivante, jusqu'à son dimanche.
///
/// Le coach ne voyait que la semaine en cours. Un dimanche soir, « prépare ma
/// semaine » ne pouvait rien poser nulle part.
void main() {
  tearDown(() => PlannerAIService.setPlanningWindow(null));

  // La semaine du 19 octobre 2026 finit sur le passage à l'heure d'hiver, le
  // dimanche 25. C'est là qu'un calcul par durée tombait un jour trop tôt.
  final lundi = DateTime(2026, 10, 19);

  group('Les jours de la semaine suivante', () {
    setUp(() => PlannerAIService.setPlanningWindow(lundi));

    test('un nom seul, c\'est cette semaine', () {
      expect(PlannerAIService.dateForDayName('monday'), DateTime(2026, 10, 19));
      expect(PlannerAIService.dateForDayName('sunday'), DateTime(2026, 10, 25));
    });

    test('next_, c\'est sept jours plus tard, changement d\'heure compris', () {
      expect(PlannerAIService.dateForDayName('next_monday'), DateTime(2026, 10, 26));
      expect(PlannerAIService.dateForDayName('next_sunday'), DateTime(2026, 11, 1));
      expect(PlannerAIService.dateForDayName('next monday'), DateTime(2026, 10, 26));
      expect(PlannerAIService.parseDay('next_wednesday'), DateTime(2026, 10, 28));
    });

    test('chaque date retrouve sa clé', () {
      for (var i = 0; i < 14; i++) {
        final d = calendarDay(lundi, i);
        final key = PlannerAIService.dayKeyFor(d);
        expect(key, PlannerAIService.dayKeys[i], reason: '$d');
        expect(PlannerAIService.dateForDayName(key), d, reason: key);
      }
    });

    test('la fenêtre se termine le dimanche d\'après', () {
      expect(PlannerAIService.planningWindowEnd, DateTime(2026, 11, 1));
    });

    test('une semaine entière, celle-ci ou la suivante', () {
      expect(PlannerAIService.weekDates(null), [for (var i = 0; i < 7; i++) calendarDay(lundi, i)]);
      expect(PlannerAIService.weekDates('next').first, DateTime(2026, 10, 26));
      expect(PlannerAIService.weekDates('next').last, DateTime(2026, 11, 1));
    });
  });

  group('Un jour sans précision, c\'est le prochain de ce nom', () {
    // « Fais-moi une séance mercredi », dit un mardi : c'est demain. « Lundi »,
    // dit un mardi : le lundi qui vient, pas celui d'hier.
    setUp(() => PlannerAIService.setPlanningWindow(getCurrentWeekStart()));

    final today = () {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }();

    test('chaque nom tombe entre aujourd\'hui et six jours plus tard', () {
      for (final nom in PlannerAIService.dayKeys.take(7)) {
        final d = PlannerAIService.dateForDayName(nom)!;
        expect(d.isBefore(today), isFalse, reason: nom);
        expect(d.isAfter(calendarDay(today, 6)), isFalse, reason: nom);
      }
    });

    test('le jour même, c\'est aujourd\'hui', () {
      final nom = PlannerAIService.dayKeys[today.weekday - 1];
      expect(PlannerAIService.dateForDayName(nom), today);
    });

    test('noter un repas prévu regarde la semaine en cours, passé compris', () {
      for (var i = 0; i < 7; i++) {
        final nom = PlannerAIService.dayKeys[i];
        expect(PlannerAIService.dateForDayName(nom, upcoming: false), calendarDay(getCurrentWeekStart(), i), reason: nom);
      }
    });

    test('next_ reste la semaine prochaine du calendrier', () {
      expect(PlannerAIService.dateForDayName('next_monday'), calendarDay(getCurrentWeekStart(), 7));
      expect(PlannerAIService.dateForDayName('next_sunday'), calendarDay(getCurrentWeekStart(), 13));
    });

    test('vider cette semaine ne touche que cette semaine', () {
      final dates = PlannerAIService.weekDates('this');
      expect(dates.first, getCurrentWeekStart());
      expect(dates.last, calendarDay(getCurrentWeekStart(), 6));
    });
  });

  group('Au-delà du dernier dimanche', () {
    test('le coach refuse, sans rien écrire', () async {
      // Une fenêtre de sept jours à partir de ce lundi : la semaine suivante
      // est dehors, et le garde-fou répond avant d'atteindre la base.
      PlannerAIService.setPlanningWindow(getCurrentWeekStart(), days: 7);

      final out = await PlannerAIService.executeToolCall('delete_workout', {'day': 'next_friday'}, 'fr');

      expect(out['success'], isFalse);
      expect(out['is_beyond_window'], isTrue);
      expect(out['message'], contains('trop loin'));
    });
  });

  group('La semaine du planificateur', () {
    test('quatorze jours distincts, changement d\'heure compris', () {
      final week = WeeklyPlannerData.fromLists(weekStart: lundi, activities: const [], workouts: const []);

      expect(week.dayCount, 14);
      expect(week.weekEnd, DateTime(2026, 11, 1));
      expect(week.dayPlans.keys.toSet(), hasLength(14));
      expect(week.weekDays[7], DateTime(2026, 10, 26));
    });

    test('sept jours quand on le demande', () {
      final week = WeeklyPlannerData.fromLists(weekStart: lundi, activities: const [], workouts: const [], days: 7);
      expect(week.dayCount, 7);
      expect(week.weekEnd, DateTime(2026, 10, 25));
    });

    test('le lundi de cette semaine, par le calendrier', () {
      final start = getCurrentWeekStart();
      expect(start.weekday, DateTime.monday);
      expect(start.hour, 0);
      expect(isInPlanningWindow(calendarDay(start, 13)), isTrue);
      expect(isInPlanningWindow(calendarDay(start, 14)), isFalse);
    });
  });
}
