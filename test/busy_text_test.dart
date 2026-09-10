import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/design/busy.dart';
import 'package:ryze_app/design/tokens.dart';

/// L'attente de Ryze s'écrit proprement, même sans Material au-dessus d'elle.
///
/// L'analyse de la journée montre cet écran dans un `OverlayEntry`, où il n'y a
/// pas de Material. Flutter y écrit alors ses textes avec son style de
/// secours : souligné d'un double trait jaune. C'est la tête qu'avait « Coach
/// Ryze lit ta journée… ».
void main() {
  testWidgets('aucun texte souligné dans un overlay nu', (tester) async {
    const message = 'Coach Ryze lit ta journée…';

    await tester.pumpWidget(
      MaterialApp(
        home: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => const RyzeBusy(
                message: message,
                trailing: Text('Jeudi 10 septembre'),
              ),
            ),
          ],
        ),
      ),
    );
    // L'onde tourne en boucle : on avance d'une image, on ne l'attend pas.
    await tester.pump();

    for (final texte in [message, 'Jeudi 10 septembre']) {
      final widget = tester.widget<Text>(find.text(texte));
      final ambiant = DefaultTextStyle.of(tester.element(find.text(texte))).style;
      final style = ambiant.merge(widget.style);
      expect(
        style.decoration ?? TextDecoration.none,
        TextDecoration.none,
        reason: '« $texte » ne doit pas être souligné',
      );
    }
  });

  testWidgets('le sol reste celui qu’on lui donne', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Overlay(
          initialEntries: [
            OverlayEntry(builder: (_) => RyzeBusy(message: 'x', background: RyzeColors.ink)),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ColoredBox), findsWidgets);
  });
}
