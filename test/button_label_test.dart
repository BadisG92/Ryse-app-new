import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ryze_app/onboarding/widgets/onb_widgets.dart';

/// Un libellé de bouton ne se coupe pas au milieu d'un mot.
///
/// Dans la feuille d'une séance planifiée, « Démarrer » prend deux tiers de la
/// rangée : il ne restait pas la place d'écrire « Delete », qui se cassait en
/// « Dele » et « te » sur deux lignes.
void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(390, 844);
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Future<void> pump(WidgetTester tester, double width, String label) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: OnbButton(label: label, ghost: true, icon: LucideIcons.trash2, onPressed: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('le libellé tient sur une ligne, même à l’étroit', (tester) async {
    // la largeur du bouton « supprimer » dans la rangée d'une feuille de séance
    await pump(tester, 110, 'Delete');
    final text = tester.widget<Text>(find.text('Delete'));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
  });

  testWidgets('un mot long ne déborde pas non plus', (tester) async {
    await pump(tester, 110, 'Supprimer');
    expect(tester.takeException(), isNull);
  });

  testWidgets('au large, le libellé est toujours là', (tester) async {
    await pump(tester, 320, 'Delete');
    expect(find.text('Delete'), findsOneWidget);
  });
}
