import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/ai/ryze_meter.dart';

/// Le compteur de jetons, sans Supabase.
///
/// C'est tout l'enjeu : `record` est appelé depuis le `finally` du flux, donc
/// une exception qui en sortirait emporterait la réponse que le compteur est
/// censé compter. `Supabase.instance` lève tant que l'initialisation n'a pas
/// abouti — au lancement sans réseau, par exemple — et ce test tourne
/// justement sans Supabase initialisé.
void main() {
  test('ne lève jamais, même sans Supabase initialisé', () {
    expect(
      () => RyzeMeter.record(
        surface: 'coach',
        model: 'gemini-2.5-flash',
        promptTokens: 1200,
        outputTokens: 340,
        serverSide: false,
      ),
      returnsNormally,
    );
  });

  test('ne compte rien quand le serveur a déjà compté', () {
    expect(
      () => RyzeMeter.record(
        surface: 'coach',
        model: 'gemini-2.5-flash',
        promptTokens: 1200,
        outputTokens: 340,
        serverSide: true,
      ),
      returnsNormally,
    );
  });

  test('un tour sans jeton ne crée pas de ligne', () {
    expect(
      () => RyzeMeter.record(
        surface: 'scan',
        model: 'gemini-2.5-flash',
        promptTokens: 0,
        outputTokens: 0,
        serverSide: false,
      ),
      returnsNormally,
    );
  });
}
