import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ai/ryze_tools/ryze_tool.dart';
import 'cardio_recap_bottom_sheet.dart';
import 'workout_recap_bottom_sheet.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/translations.dart';
import 'meal_proposal_page.dart';
import 'proposal_card.dart';

/// Les séances que Ryze propose dans la conversation, dans la carte du
/// planificateur.
///
/// La conversation en faisait une carte plate par séance : un titre, une
/// ligne, deux boutons. Trois séances donnaient trois cartes empilées, sans
/// moyen de voir ce qu'il y avait dedans avant de valider — alors que l'écran
/// du planificateur, avec exactement les mêmes objets, montrait une carte
/// unique, les jours en pastilles, et le détail complet au toucher.
///
/// C'est la même proposition et le même outil ; il n'y avait aucune raison
/// que ce soit deux objets à l'écran. Les composants viennent d'ailleurs du
/// planificateur : [ProposalCard], [ProposalHeader], [ProposalWorkoutRow].
class SessionProposalGroup extends StatelessWidget {
  const SessionProposalGroup({
    super.key,
    required this.lang,
    required this.pendings,
    required this.onConfirmAll,
    required this.onCancel,
    this.busy = false,
  });

  final String lang;

  /// Les propositions du tour, dans l'ordre où Ryze les a faites.
  final List<RyzePending> pendings;

  final VoidCallback onConfirmAll;
  final VoidCallback onCancel;
  final bool busy;

  /// Les séances derrière ces propositions, quand elles en portent une.
  static List<PendingSession> sessionsOf(List<RyzePending> pendings) =>
      [for (final p in pendings) if (p.payload is PendingSession) p.payload as PendingSession];

  /// Trois lettres pour la pastille, dans la langue du compte.
  static String _dayChip(DateTime date, String lang) {
    final locale = switch (lang) { 'fr' => 'fr_FR', 'de' => 'de_DE', _ => 'en_US' };
    final court = DateFormat('E', locale).format(date).replaceAll('.', '');
    return court.isEmpty ? '' : court[0].toUpperCase() + court.substring(1);
  }

  void _showDetail(BuildContext context, PendingSession session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: session.isWorkout
            ? WorkoutRecapBottomSheet(
                workout: session.workout!.toPlannedWorkout(),
                isPreview: true,
              )
            : CardioRecapBottomSheet(
                activity: session.cardio!.toPlannedActivity(),
                isPreview: true,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = sessionsOf(pendings);
    if (sessions.isEmpty) return const SizedBox.shrink();

    final n = sessions.length;
    final hint = 'planner_tap_session_detail'.tr(lang);

    return ProposalCard(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProposalHeader(
            icon: LucideIcons.dumbbell,
            title: 'planner_proposed_sessions'.tr(lang),
            subtitle: n > 1 ? '$n · $hint' : hint,
          ),
          for (final (i, session) in sessions.indexed)
            ProposalWorkoutRow(
              dayShort: _dayChip(session.plannedDate, lang),
              title: session.displayTitle,
              subtitle: session.dateLabel(lang),
              last: i == n - 1,
              onTap: () => _showDetail(context, session),
            ),
        ],
      ),
      footer: ProposalActions(
        cancelLabel: 'ryze_cancel'.tr(lang),
        // Une seule séance se valide ; plusieurs se valident ensemble. Les
        // faire valider une par une, c'est ce que l'écran du planificateur
        // impose, et ce n'est pas ce qu'on veut dans une conversation où Ryze
        // vient de proposer un lot.
        confirmLabel: n > 1 ? 'ryze_validate_all'.tr(lang) : 'ryze_validate'.tr(lang),
        onCancel: busy ? null : onCancel,
        onConfirm: busy ? null : onConfirmAll,
        busy: busy,
      ),
    );
  }
}

/// Les repas que Ryze propose dans la conversation, même principe.
class MealProposalGroup extends StatelessWidget {
  const MealProposalGroup({
    super.key,
    required this.lang,
    required this.pendings,
    required this.onConfirmAll,
    required this.onCancel,
    this.busy = false,
  });

  final String lang;
  final List<RyzePending> pendings;
  final VoidCallback onConfirmAll;
  final VoidCallback onCancel;
  final bool busy;

  static List<PendingMeal> mealsOf(List<RyzePending> pendings) =>
      [for (final p in pendings) if (p.payload is PendingMeal) p.payload as PendingMeal];

  /// Les initiales des macros, dans la langue du compte.
  static List<String> _letters(String lang) =>
      ['proteins'.tr(lang)[0], 'carbs'.tr(lang)[0], 'fats'.tr(lang)[0]];

  /// Le détail du repas, exactement celui du planificateur.
  ///
  /// Pas une feuille écrite pour la conversation : la même page, avec la
  /// quantité, les quatre chiffres et la recette entière. Deux mises en scène
  /// d'un même repas se seraient mises à diverger dès la première retouche.
  void _showRecipe(BuildContext context, PendingMeal meal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MealProposalPage(meal: meal, lang: lang)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals = mealsOf(pendings);
    if (meals.isEmpty) return const SizedBox.shrink();

    final n = meals.length;
    final hint = 'planner_tap_meal_detail'.tr(lang);
    final letters = _letters(lang);

    return ProposalCard(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProposalHeader(
            icon: LucideIcons.utensils,
            title: 'planner_proposed_meals'.tr(lang),
            subtitle: n > 1 ? '$n · $hint' : hint,
          ),
          for (final meal in meals)
            ProposalMealRow(
              icon: meal.mealType.icon,
              typeLabel: 'meal_name_${meal.mealType.value}'.tr(lang),
              dishName: meal.dishName,
              calories: ((meal.proteins * 4) + (meal.carbs * 4) + (meal.fats * 9)).round(),
              proteins: meal.proteins.toInt(),
              carbs: meal.carbs.toInt(),
              fats: meal.fats.toInt(),
              macroLetters: letters,
              onTap: () => _showRecipe(context, meal),
            ),
        ],
      ),
      footer: ProposalActions(
        cancelLabel: 'ryze_cancel'.tr(lang),
        confirmLabel: n > 1 ? 'ryze_validate_all'.tr(lang) : 'ryze_validate'.tr(lang),
        onCancel: busy ? null : onCancel,
        onConfirm: busy ? null : onConfirmAll,
        busy: busy,
      ),
    );
  }
}
