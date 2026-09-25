import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/ai/ryze_access.dart';

/// La démo de l'onboarding passe des repas au sport en fondant un écran dans
/// l'autre. L'écran du sport s'ouvrait avant que celui des repas se ferme, et
/// la fermeture éteignait la démo pour tous : la première demande de sport
/// répondait « fait partie de Premium ».
void main() {
  setUp(RyzeAccess.resetDemo);

  test('un écran qui se ferme ne coupe pas celui qui vient de s\'ouvrir', () {
    RyzeAccess.setDemoMode(true); // les repas
    RyzeAccess.setDemoMode(true); // le sport s'ouvre
    RyzeAccess.setDemoMode(false); // les repas se ferment
    expect(RyzeAccess.demoMode, isTrue);

    RyzeAccess.setDemoMode(false); // le sport se ferme
    expect(RyzeAccess.demoMode, isFalse);
  });

  test('une fermeture de trop ne laisse pas de dette', () {
    RyzeAccess.setDemoMode(false);
    RyzeAccess.setDemoMode(true);
    expect(RyzeAccess.demoMode, isTrue);
    RyzeAccess.setDemoMode(false);
    expect(RyzeAccess.demoMode, isFalse);
  });
}
