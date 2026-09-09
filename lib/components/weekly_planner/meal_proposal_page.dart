import 'package:flutter/material.dart';

import '../../design/chat.dart';
import '../../design/recipe_view.dart';
import '../../design/tokens.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/translations.dart';

/// Le détail d'un repas proposé : ce qu'il pèse, ce qu'il apporte, et sa
/// recette.
///
/// Elle vivait à l'intérieur de l'écran du planificateur, en privé, avec son
/// propre découpeur de recette — un découpeur qui n'acceptait que
/// « INGRÉDIENTS: » en capitales avec le deux-points collé, quand le modèle
/// écrit « Ingrédients : » à la française. La recette retombait donc en un
/// seul bloc, sur l'écran même qui existe pour la montrer.
///
/// Elle est ici pour deux raisons : la conversation en avait besoin — Ryze y
/// propose les mêmes repas, avec les mêmes ingrédients — et le découpage
/// revient à [RecipeText], celui que le reste de l'application emploie déjà.
class MealProposalPage extends StatelessWidget {
  const MealProposalPage({super.key, required this.meal, required this.lang});

  final PendingMeal meal;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final typeName = 'meal_name_${meal.mealType.value}'.tr(lang);

    return Scaffold(
      backgroundColor: RyzeColors.paper,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: RyzeChatHeader(
              title: meal.dishName.isEmpty ? typeName : meal.dishName,
              subtitle: typeName,
              avatars: const [RyzeAssets.nutriAvatar],
              onBack: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: meal.mealType.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(meal.mealType.icon, size: 32, color: meal.mealType.color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.dishName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: RyzeColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '~${meal.estimatedQuantityG.toInt()} g',
                              style: TextStyle(fontSize: 14, color: RyzeColors.mute),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quatre chiffres nommés, de la même encre : une macro ne se
                  // reconnaît pas à sa couleur, ici pas plus qu'ailleurs.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RyzeColors.paper,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Macro('${meal.calories}', 'kcal'),
                        const _Divider(),
                        _Macro('${meal.proteins.toInt()} g', 'planner_proteins'.tr(lang)),
                        const _Divider(),
                        _Macro('${meal.carbs.toInt()} g', 'planner_carbs'.tr(lang)),
                        const _Divider(),
                        _Macro('${meal.fats.toInt()} g', 'planner_fats'.tr(lang)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  RecipeView(lang: lang, recipe: RecipeText.parse(meal.dishDescription)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RyzeColors.text),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: RyzeColors.mute)),
        ],
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: RyzeColors.line);
}
