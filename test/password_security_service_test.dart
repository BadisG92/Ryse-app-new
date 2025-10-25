import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/services/password_security_service.dart';

void main() {
  group('PasswordSecurityService', () {
    test('Détecte mot de passe compromis connu - "password123"', () async {
      // Ce mot de passe est connu pour être dans HaveIBeenPwned
      final isCompromised = await PasswordSecurityService.checkPasswordCompromised('password123');

      expect(isCompromised, equals(true),
          reason: '"password123" devrait être détecté comme compromis');
    });

    test('Détecte mot de passe compromis connu - "qwerty"', () async {
      final isCompromised = await PasswordSecurityService.checkPasswordCompromised('qwerty');

      expect(isCompromised, equals(true),
          reason: '"qwerty" devrait être détecté comme compromis');
    });

    test('Ne détecte PAS un mot de passe fort et unique', () async {
      // Mot de passe fort et unique (ne devrait pas être dans la base)
      final uniquePassword = 'Ryze2025!SecureP@ssw0rd#UniqueTest';
      final isCompromised = await PasswordSecurityService.checkPasswordCompromised(uniquePassword);

      expect(isCompromised, equals(false),
          reason: 'Un mot de passe unique devrait être sûr');
    });

    test('Gère gracieusement un mot de passe vide', () async {
      final result = await PasswordSecurityService.checkPasswordCompromised('');

      expect(result, isNull,
          reason: 'Mot de passe vide devrait retourner null');
    });

    test('Évalue force mot de passe - très faible', () {
      final score = PasswordSecurityService.evaluatePasswordStrength('pass');

      expect(score, equals(0),
          reason: 'Mot de passe < 8 chars devrait avoir score 0');
    });

    test('Évalue force mot de passe - bon', () {
      final score = PasswordSecurityService.evaluatePasswordStrength('Ryze2025!');

      expect(score, greaterThanOrEqualTo(2),
          reason: 'Mot de passe avec majuscules, chiffres et symboles devrait avoir bon score');
    });

    test('Évalue force mot de passe - excellent', () {
      final score = PasswordSecurityService.evaluatePasswordStrength('Ryze2025!SecureP@ssw0rd');

      expect(score, greaterThanOrEqualTo(3),
          reason: 'Mot de passe long avec tous types de caractères devrait avoir excellent score');
    });

    test('Messages de force en français', () {
      final message0 = PasswordSecurityService.getStrengthMessage(0, 'fr');
      final message4 = PasswordSecurityService.getStrengthMessage(4, 'fr');

      expect(message0, contains('Très faible'));
      expect(message4, contains('Excellent'));
    });

    test('Messages de force en anglais', () {
      final message0 = PasswordSecurityService.getStrengthMessage(0, 'en');
      final message4 = PasswordSecurityService.getStrengthMessage(4, 'en');

      expect(message0, contains('Very weak'));
      expect(message4, contains('Excellent'));
    });

    test('Message warning compromis en français', () {
      final message = PasswordSecurityService.getCompromisedWarningMessage('fr');

      expect(message, contains('compromis'));
      expect(message, contains('fuite de données'));
    });

    test('Message warning compromis en anglais', () {
      final message = PasswordSecurityService.getCompromisedWarningMessage('en');

      expect(message, contains('exposed'));
      expect(message, contains('data breach'));
    });
  });
}
