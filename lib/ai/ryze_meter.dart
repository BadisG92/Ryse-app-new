import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

/// Ce qu'un tour d'IA a coûté, écrit là où on pourra le lire.
///
/// Gemini rend le compte de jetons dans `usageMetadata` à chaque réponse, et le
/// transport le lisait déjà — pour l'afficher en debug, et rien d'autre. La
/// table `ryze_ai_usage` existait, mais seule la fonction serveur pouvait y
/// écrire : comme l'application appelle encore Google en direct, elle est
/// restée vide. Personne ne savait ce que l'IA coûtait, ni globalement ni par
/// utilisateur.
///
/// L'écriture part sans être attendue et n'échoue jamais bruyamment : un
/// compteur ne doit pas pouvoir casser la réponse qu'il compte.
///
/// Le jour où `RYZE_VIA_EDGE` passe à `true`, c'est le serveur qui écrit la
/// ligne — et [record] se tait, sinon chaque tour serait compté deux fois. Le
/// mode est celui de la requête elle-même, pas un drapeau lu à part : les deux
/// ne peuvent pas diverger.
class RyzeMeter {
  RyzeMeter._();

  static void record({
    required String surface,
    required String model,
    required int promptTokens,
    required int outputTokens,

    /// Vrai quand la requête est passée par la fonction serveur : elle a déjà
    /// écrit la ligne, et compter ici la doublerait.
    required bool serverSide,
  }) {
    if (serverSide) return;
    // Zéro des deux côtés veut dire que le modèle n'a rien dit : on n'invente
    // pas une ligne.
    if (promptTokens <= 0 && outputTokens <= 0) return;

    // Rien de ce qui suit ne peut lever. `Supabase.instance` lève tant que
    // l'initialisation n'a pas abouti — ce qui arrive au lancement sans
    // réseau — et cet appel est fait depuis le `finally` du flux : une
    // exception ici emporterait la réponse que le compteur est censé compter.
    try {
      final client = SupabaseConfig.clientSafe;
      final user = client?.auth.currentUser;
      if (client == null || user == null) return;

      client
          .from('ryze_ai_usage')
          .insert({
            'user_id': user.id,
            'surface': surface,
            'model': model,
            'prompt_tokens': promptTokens,
            'output_tokens': outputTokens,
          })
          .timeout(const Duration(seconds: 10))
          .then((_) {
        if (kDebugMode) debugPrint('📊 IA: $surface/$model — $promptTokens + $outputTokens jetons');
      }).catchError((Object e) {
        // Un compteur muet vaut mieux qu'une réponse perdue.
        if (kDebugMode) debugPrint('⚠️ IA: comptage non écrit: $e');
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ IA: comptage impossible: $e');
    }
  }
}
