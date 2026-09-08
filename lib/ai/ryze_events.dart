import '../models/weekly_planner_models.dart';
import 'ryze_tools/ryze_tool.dart';

/// Ce que l'écran reçoit pendant que Ryze répond.
///
/// La conversation ne rendait que du texte, parce que Ryze ne savait rien
/// faire d'autre. Elle rend maintenant aussi ce qu'il vient de faire et ce
/// qu'il demande la permission de faire.
sealed class CoachEvent {
  const CoachEvent();
}

/// Un morceau de phrase.
class CoachText extends CoachEvent {
  const CoachText(this.text);
  final String text;
}

/// Une action déjà faite, à afficher en une ligne.
class CoachAction extends CoachEvent {
  const CoachAction(this.summary, {this.ok = true, this.toolName, this.undo});

  final String summary;
  final bool ok;
  final String? toolName;

  /// De quoi la défaire, quand elle se défait proprement.
  ///
  /// C'est ce qui remplace la carte à valider pour ce qui se retire d'un
  /// geste : un verre d'eau se note tout de suite et se reprend par une barre
  /// d'annulation, plus rapide qu'un oui à donner avant.
  final Future<void> Function()? undo;
}

/// Une action qui attend un oui.
///
/// Elle n'est pas faite : le modèle a reçu « en attente de validation » et non
/// un succès, pour qu'il n'annonce pas ce qui n'a pas eu lieu.
class CoachAsk extends CoachEvent {
  const CoachAsk(this.pending);
  final RyzePending pending;
}

/// Tout ce que Ryze propose d'ajouter à la semaine, d'un seul tour.
///
/// Une demande peut en produire beaucoup — « planifie ma semaine » en fait une
/// douzaine — et l'écran du planificateur les feuillette par jour. Elles
/// arrivent donc groupées, à la fin, plutôt qu'une par une.
class CoachProposals extends CoachEvent {
  const CoachProposals({this.meals = const [], this.sessions = const []});

  final List<PendingMeal> meals;
  final List<PendingSession> sessions;

  bool get isEmpty => meals.isEmpty && sessions.isEmpty;
}

/// La réponse s'est arrêtée là.
class CoachFailure extends CoachEvent {
  const CoachFailure(this.message);
  final String message;
}
