import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/services/planner_ai_service.dart';

/// Ce que le planificateur promet au modèle.
///
/// Le test portait auparavant une copie des schémas d'outils, recopiée à la
/// main dans ce fichier ; elle avait déjà divergé du service sur deux points
/// (les activités de `create_cardio`, les arguments requis de
/// `modify_workout`) sans que rien ne le signale. Il lit maintenant les vraies
/// listes, donc une modification du service qui casse une de ces promesses
/// fait tomber un test.
void main() {
  Map<String, dynamic> tool(List<Map<String, dynamic>> tools, String name) =>
      tools.firstWhere((t) => t['name'] == name, orElse: () => <String, dynamic>{});

  // Certains schémas déclarent `'properties': {}`, que Dart type
  // `Map<dynamic, dynamic>` : on recopie plutôt que de convertir.
  Map<String, dynamic> props(Map<String, dynamic> t) =>
      Map<String, dynamic>.from((t['parameters'] as Map)['properties'] as Map);

  List<String> required(Map<String, dynamic> t) =>
      List<String>.from((t['parameters'] as Map)['required'] as List);

  group('Les outils du mode sport', () {
    final tools = PlannerAIService.plannerTools;
    final names = tools.map((t) => t['name'] as String).toList();

    test('les quatre actions existent pour la musculation', () {
      for (final name in ['create_workout', 'delete_workout', 'move_workout', 'modify_workout']) {
        expect(names, contains(name));
      }
    });

    test('les quatre actions existent pour le cardio', () {
      for (final name in ['create_cardio', 'delete_cardio', 'move_cardio', 'modify_cardio']) {
        expect(names, contains(name));
      }
    });

    test('la suppression en masse existe pour les deux types', () {
      for (final name in ['delete_all', 'delete_all_workouts', 'delete_all_cardio']) {
        expect(names, contains(name));
      }
    });

    test('chaque nom est unique', () {
      expect(names.toSet().length, names.length);
    });

    test('chaque outil déclare un schéma exploitable', () {
      for (final t in tools) {
        expect(t['description'], isA<String>(), reason: '${t['name']} sans description');
        expect((t['description'] as String).isNotEmpty, isTrue, reason: '${t['name']} description vide');
        final params = t['parameters'] as Map;
        expect(params['type'], 'object', reason: '${t['name']} paramètres non typés');
        expect(params['properties'], isA<Map>(), reason: '${t['name']} sans propriétés');
        expect(params['required'], isA<List>(), reason: '${t['name']} sans liste required');
      }
    });

    test('les jours sont toujours une énumération des sept jours', () {
      for (final t in tools) {
        props(t).forEach((key, value) {
          if (key == 'day' || key == 'current_day' || key == 'new_day') {
            final schema = value as Map<String, dynamic>;
            expect(schema['enum'], isNotNull, reason: '${t['name']}.$key sans énumération');
            expect(List<String>.from(schema['enum'] as List).length, 7,
                reason: '${t['name']}.$key ne couvre pas les sept jours');
          }
        });
      }
    });
  });

  group('Les activités cardio proposées au modèle', () {
    // L'application ne sait planifier que ces quatre-là. Le prompt le dit, les
    // schémas doivent le dire aussi : c'est ce qui empêche le modèle de
    // proposer de la natation, dont la conversion échouait après avoir
    // supprimé la séance.
    const supported = ['running', 'bike', 'walking'];

    test('create_cardio n\'accepte que les activités supportées', () {
      final schema = props(tool(PlannerAIService.plannerTools, 'create_cardio'))['activity'] as Map<String, dynamic>;
      final values = List<String>.from(schema['enum'] as List);
      expect(values, supported);
      expect(values, isNot(contains('swimming')));
    });

    test('modify_cardio n\'accepte que les activités supportées', () {
      final schema = props(tool(PlannerAIService.plannerTools, 'modify_cardio'))['new_activity'] as Map<String, dynamic>;
      final values = List<String>.from(schema['enum'] as List);
      for (final activity in supported) {
        expect(values, contains(activity));
      }
      expect(values, isNot(contains('swimming')));
    });
  });

  group('Les outils du mode repas', () {
    final tools = PlannerAIService.mealTools;
    final names = tools.map((t) => t['name'] as String).toList();

    test('créer, supprimer et modifier existent', () {
      for (final name in ['create_meal', 'delete_meal', 'delete_all_meals', 'modify_meal']) {
        expect(names, contains(name));
      }
    });

    test('create_meal exige le jour, le moment et les macros', () {
      final req = required(tool(tools, 'create_meal'));
      for (final arg in ['day', 'meal_type', 'dish_name', 'calories', 'proteins', 'carbs', 'fats']) {
        expect(req, contains(arg));
      }
    });

    test('les quatre moments de la journée sont proposés', () {
      final schema = props(tool(tools, 'create_meal'))['meal_type'] as Map<String, dynamic>;
      expect(List<String>.from(schema['enum'] as List), ['breakfast', 'lunch', 'dinner', 'snack']);
    });

    test('modify_meal peut désigner le plat à remplacer', () {
      // Sans cet argument, un jour portant deux collations faisait lever une
      // exception à la requête, rendue à l'utilisateur en anglais brut.
      expect(props(tool(tools, 'modify_meal')).containsKey('current_dish_name'), isTrue);
    });
  });

  group('La répartition des calories sur la journée', () {
    test('les quatre repas couvrent exactement la journée', () {
      final total = PlannerAIService.mealSplit.values.reduce((a, b) => a + b);
      expect(total, closeTo(1.0, 0.0001));
    });

    test('chaque moment de la journée a une part', () {
      for (final meal in ['breakfast', 'lunch', 'dinner', 'snack']) {
        expect(PlannerAIService.mealSplit.containsKey(meal), isTrue);
        expect(PlannerAIService.mealSplit[meal]! > 0, isTrue);
      }
    });
  });

  group('Le jour que le modèle a désigné', () {
    tearDown(() => PlannerAIService.setPlanningWindow(null));

    test('tombe dans la fenêtre affichée à l\'écran', () {
      // Une semaine qui commence le lundi 6 janvier 2025.
      PlannerAIService.setPlanningWindow(DateTime(2025, 1, 6));

      expect(PlannerAIService.dateForDayName('monday'), DateTime(2025, 1, 6));
      expect(PlannerAIService.dateForDayName('wednesday'), DateTime(2025, 1, 8));
      expect(PlannerAIService.dateForDayName('sunday'), DateTime(2025, 1, 12));
    });

    test('suit la fenêtre même quand elle ne commence pas un lundi', () {
      // La démo de l'onboarding plante sa fenêtre ailleurs qu'un lundi.
      PlannerAIService.setPlanningWindow(DateTime(2025, 1, 9)); // un jeudi

      expect(PlannerAIService.dateForDayName('thursday'), DateTime(2025, 1, 9));
      expect(PlannerAIService.dateForDayName('saturday'), DateTime(2025, 1, 11));
      // Le lundi de cette fenêtre est celui d'après, pas celui d'avant.
      expect(PlannerAIService.dateForDayName('monday'), DateTime(2025, 1, 13));
    });

    test('rend null sur un nom de jour inconnu', () {
      PlannerAIService.setPlanningWindow(DateTime(2025, 1, 6));
      expect(PlannerAIService.dateForDayName('funday'), isNull);
      expect(PlannerAIService.dateForDayName(''), isNull);
    });
  });
}
