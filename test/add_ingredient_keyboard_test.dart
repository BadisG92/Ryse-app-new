import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ryze_app/bottom_sheets/add_ingredient_bottom_sheet.dart';
import 'package:ryze_app/models/ai_analysis_models.dart';
import 'package:ryze_app/services/localization_service.dart';

/// La feuille d'ajout d'un aliment, clavier ouvert.
///
/// Elle monte au-dessus du clavier grâce à un `Padding` posé dans `show()`, et
/// son pied ajoutait la même hauteur une seconde fois. Sur un iPhone, un
/// clavier de 300 points retiré deux fois d'un écran qui en fait 844 ne
/// laissait plus rien au contenu : la liste — le nom, les unités, la quantité —
/// était écrasée à zéro, et il ne restait à l'écran que les deux boutons,
/// collés sous le titre, au-dessus d'un grand vide.
///
/// Le test reconstruit ce que `show()` monte, clavier compris, sur un écran de
/// téléphone — la taille par défaut du banc d'essai, 800 × 600, est trop
/// petite pour que la question ait un sens.
void main() {
  const keyboard = 300.0;
  const screen = Size(390, 844);

  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.devicePixelRatio = 1;
    view.physicalSize = screen;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('le contenu survit au clavier', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LocalizationService>.value(
        value: LocalizationService.instance,
        child: MaterialApp(
          // Material sans Scaffold : une feuille modale n'en a pas, et un
          // Scaffold retirerait le clavier du MediaQuery, donc effacerait le
          // bug qu'on veut voir.
          home: Material(
            color: const Color(0x00000000),
            child: MediaQuery(
              data: const MediaQueryData(size: screen, viewInsets: EdgeInsets.only(bottom: keyboard)),
              child: Builder(
                // ce que `show()` construit : la feuille, remontée du clavier
                builder: (context) => Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: AddIngredientBottomSheet(onIngredientAdded: (DetectedFood _) {}),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final sheet = tester.getRect(find.byType(AddIngredientBottomSheet));
    final list = tester.getSize(find.byType(ListView));

    expect(list.height, greaterThan(120), reason: 'le nom, les unités et la quantité doivent tenir à l’écran');
    expect(sheet.bottom, lessThanOrEqualTo(screen.height - keyboard + 0.5), reason: 'la feuille s’arrête au-dessus du clavier');
    expect(find.byType(TextField), findsWidgets, reason: 'le champ du nom est là');
  });
}
