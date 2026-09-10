import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/services/water_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La file de l'eau, sans réseau.
///
/// Rien ici ne touche Supabase : `flush` est le seul point qui le fait, et il
/// n'est pas appelé. Ce qui est vérifié est ce qui décide du compteur affiché
/// et de ce qui part quand le réseau revient.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final queue = WaterQueue.instance;
  final today = DateTime(2026, 9, 10, 14, 30);
  const user = 'u-1';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<String> keep(int amount, {DateTime? at}) => queue.keepAdd(
        userId: user,
        amount: amount,
        sourceType: amount == 250 ? 'glass' : 'manual',
        consumedAt: at ?? today,
      );

  group('Ce que la file ajoute au total du jour', () {
    test('un verre gardé compte', () async {
      await keep(250);
      expect(await queue.pendingMlOn(today), 250);
    });

    test('plusieurs verres s\'additionnent', () async {
      await keep(250);
      await keep(250);
      await keep(500);
      expect(await queue.pendingMlOn(today), 1000);
    });

    test('un verre d\'un autre jour ne compte pas dans celui-ci', () async {
      await keep(250, at: today.subtract(const Duration(days: 1)));
      await keep(250);
      expect(await queue.pendingMlOn(today), 250);
      expect(await queue.pendingMlOn(today.subtract(const Duration(days: 1))), 250);
    });

    test('une suppression en attente compte en négatif', () async {
      await queue.keepDelete(entryId: 'deja-en-base', amount: 250, at: today);
      expect(await queue.pendingMlOn(today), -250);
    });

    test('rien en attente vaut zéro', () async {
      expect(await queue.pendingMlOn(today), 0);
    });
  });

  group('Retirer un verre qui n\'est pas encore parti', () {
    test('le sort de la file au lieu de demander au serveur de le supprimer', () async {
      final id = await keep(250);
      expect(queue.pendingCount.value, 1);

      await queue.keepDelete(entryId: id, amount: 250, at: today);

      // Ni ajout ni suppression : la ligne n'a jamais existé côté serveur.
      expect(queue.pendingCount.value, 0);
      expect(await queue.pendingMlOn(today), 0);
    });

    test('une ligne déjà en base laisse bien une suppression à envoyer', () async {
      await keep(250);
      await queue.keepDelete(entryId: 'une-ligne-du-serveur', amount: 250, at: today);

      expect(queue.pendingCount.value, 2);
      expect(await queue.pendingMlOn(today), 0);
    });
  });

  group('Ce que les écrans voient', () {
    test('les verres gardés se listent comme les autres', () async {
      final first = await keep(250);
      final second = await keep(500);

      final glasses = await queue.pendingAddsOn(today);
      expect(glasses.map((g) => g.id), [first, second]);
      expect(glasses.map((g) => g.amount), [250, 500]);
    });

    test('la liste ne montre que le jour demandé', () async {
      await keep(250, at: today.subtract(const Duration(days: 2)));
      await keep(250);
      expect((await queue.pendingAddsOn(today)).length, 1);
    });

    test('une suppression en attente n\'est pas un verre à montrer', () async {
      await queue.keepDelete(entryId: 'x', amount: 250, at: today);
      expect(await queue.pendingAddsOn(today), isEmpty);
    });
  });

  group('Ce qui survit à une relecture du disque', () {
    test('la file se relit telle qu\'elle a été écrite', () async {
      final id = await keep(750);

      // Une nouvelle lecture passe par SharedPreferences, comme après un
      // redémarrage de l'application.
      final glasses = await queue.pendingAddsOn(today);
      expect(glasses.single.id, id);
      expect(glasses.single.amount, 750);
      expect(glasses.single.at, today);
    });

    test('l\'identifiant est celui que l\'appelant a fixé', () async {
      const chosen = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
      final id = await queue.keepAdd(
        userId: user,
        amount: 250,
        sourceType: 'glass',
        consumedAt: today,
        id: chosen,
      );
      expect(id, chosen);
      expect((await queue.pendingAddsOn(today)).single.id, chosen);
    });
  });
}
