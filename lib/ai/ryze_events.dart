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
  const CoachAction(this.summary, {this.ok = true, this.toolName});

  final String summary;
  final bool ok;
  final String? toolName;
}

/// Une action qui attend un oui.
///
/// Elle n'est pas faite : le modèle a reçu « en attente de validation » et non
/// un succès, pour qu'il n'annonce pas ce qui n'a pas eu lieu.
class CoachAsk extends CoachEvent {
  const CoachAsk(this.pending);
  final RyzePending pending;
}

/// La réponse s'est arrêtée là.
class CoachFailure extends CoachEvent {
  const CoachFailure(this.message);
  final String message;
}
