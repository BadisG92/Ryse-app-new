import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/ai/ryze_oneshot.dart';
import 'package:ryze_app/ai/ryze_transport.dart';
import 'package:ryze_app/onboarding/tone_test.dart';
import 'package:ryze_app/services/coach_personality_service.dart';

/// La meilleure excuse de l'onboarding.
///
/// Le coach qui répond doit être celui de l'app : le ton en cours de choix,
/// y compris celui qu'on vient d'écrire et qui n'est encore nulle part en
/// base, et l'excuse telle qu'elle a été donnée. Une panne ne doit rien
/// afficher d'inventé.
class _FakeTransport extends RyzeTransport {
  _FakeTransport(this.answer);

  final String? answer;
  String prompt = '';

  @override
  Future<Map<String, dynamic>> generate(
    Map<String, dynamic> payload, {
    String? model,
    required String surface,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    prompt = payload['contents'][0]['parts'][0]['text'] as String;
    if (answer == null) throw const RyzeTransportException('offline');
    return {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': answer}
            ]
          }
        }
      ]
    };
  }
}

void main() {
  test('le ton écrit à la main et l’excuse partent dans la question', () async {
    final fake = _FakeTransport('  Debout, soldat. La pluie, ça mouille, ça ne tue pas.  ');
    RyzeOneShot.transport = fake;

    final reply = await OnbToneTest.reply(
      type: CoachPersonalityType.custom,
      customText: 'Parle-moi comme un sergent instructeur qui veut mon bien.',
      excuse: 'Il pleut, flemme',
      lang: 'fr',
      name: 'Jake',
      gender: 'Homme',
      age: 34,
    );

    expect(reply, 'Debout, soldat. La pluie, ça mouille, ça ne tue pas.');
    expect(fake.prompt, contains('Parle-moi comme un sergent instructeur qui veut mon bien.'));
    expect(fake.prompt, contains('Son excuse : "Il pleut, flemme"'));
    expect(fake.prompt, contains('## CE MESSAGE'));
  });

  test('un ton maison passe par la même consigne que dans l’app', () async {
    final fake = _FakeTransport('No excuses.');
    RyzeOneShot.transport = fake;

    await OnbToneTest.reply(type: CoachPersonalityType.strict, customText: '', excuse: 'No energy tonight', lang: 'en');

    expect(fake.prompt, contains(CoachPersonalityService.instructionFor(CoachPersonalityType.strict, '', 'en').trim()));
    expect(fake.prompt, contains('Their excuse: "No energy tonight"'));
  });

  test('une excuse trop longue est coupée', () async {
    final fake = _FakeTransport('Ok.');
    RyzeOneShot.transport = fake;

    await OnbToneTest.reply(type: CoachPersonalityType.direct, customText: '', excuse: 'a' * 300, lang: 'en');

    expect(fake.prompt, contains('"${'a' * OnbToneTest.maxExcuseLength}"'));
    expect(fake.prompt, isNot(contains('a' * (OnbToneTest.maxExcuseLength + 1))));
  });

  test('pas de réseau, pas de réponse inventée', () async {
    RyzeOneShot.transport = _FakeTransport(null);

    final reply = await OnbToneTest.reply(type: CoachPersonalityType.friendly, customText: '', excuse: 'x', lang: 'de');

    expect(reply, isNull);
  });
}
