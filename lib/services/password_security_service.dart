import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service de vérification de sécurité des mots de passe
/// Utilise l'API HaveIBeenPwned pour détecter les mots de passe compromis
///
/// Conforme RGPD: utilise k-anonymity (seulement 5 premiers caractères SHA-1)
/// Référence: https://haveibeenpwned.com/API/v3#PwnedPasswords
class PasswordSecurityService {
  static const String _apiBaseUrl = 'https://api.pwnedpasswords.com/range';
  static const Duration _timeout = Duration(seconds: 3);

  /// Vérifie si un mot de passe a été compromis dans une fuite de données
  ///
  /// Retourne:
  /// - true: mot de passe compromis (trouvé dans base HaveIBeenPwned)
  /// - false: mot de passe sûr (non trouvé)
  /// - null: impossible de vérifier (API down, timeout, erreur réseau)
  ///
  /// Exemple:
  /// ```dart
  /// final isCompromised = await PasswordSecurityService.checkPasswordCompromised('Password123');
  /// if (isCompromised == true) {
  ///   // Avertir l'utilisateur
  /// }
  /// ```
  static Future<bool?> checkPasswordCompromised(String password) async {
    try {
      // Validation basique
      if (password.isEmpty) {
        debugPrint('⚠️ PasswordSecurity: Empty password provided');
        return null;
      }

      // Étape 1: Hash SHA-1 du mot de passe
      final bytes = utf8.encode(password);
      final sha1Hash = sha1.convert(bytes).toString().toUpperCase();

      // Étape 2: K-anonymity - Séparer prefix (5 chars) et suffix
      final prefix = sha1Hash.substring(0, 5);
      final suffix = sha1Hash.substring(5);

      debugPrint('🔍 PasswordSecurity: Checking prefix $prefix (suffix hidden)');

      // Étape 3: Appel API HaveIBeenPwned
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/$prefix'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        // Étape 4: Chercher le suffix dans la réponse
        final isFound = response.body.toUpperCase().contains(suffix);

        if (isFound) {
          debugPrint('❌ PasswordSecurity: Password found in breach database!');
        } else {
          debugPrint('✅ PasswordSecurity: Password is safe');
        }

        return isFound;
      } else if (response.statusCode == 429) {
        // Rate limit atteint
        debugPrint('⚠️ PasswordSecurity: Rate limit hit (429)');
        return null;
      } else {
        debugPrint('⚠️ PasswordSecurity: API returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Erreur réseau, timeout, ou autre
      debugPrint('⚠️ PasswordSecurity: Check failed - $e');
      // Fallback gracieux: on ne bloque pas l'inscription
      return null;
    }
  }

  /// Évalue la force d'un mot de passe
  ///
  /// Retourne un score de 0 à 4:
  /// - 0: Très faible (< 8 chars)
  /// - 1: Faible (8+ chars, pas de complexité)
  /// - 2: Moyen (8+ chars, 1-2 types de caractères)
  /// - 3: Bon (8+ chars, 3 types de caractères)
  /// - 4: Excellent (12+ chars, tous types de caractères)
  static int evaluatePasswordStrength(String password) {
    if (password.length < 8) return 0;

    int score = 1;

    // Bonus pour longueur
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // Vérifier types de caractères
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int varietyCount = 0;
    if (hasLowercase) varietyCount++;
    if (hasUppercase) varietyCount++;
    if (hasDigits) varietyCount++;
    if (hasSpecialChars) varietyCount++;

    // Bonus pour variété de caractères
    if (varietyCount >= 2) score++;
    if (varietyCount >= 3) score++;
    if (varietyCount == 4) score++;

    return score > 4 ? 4 : score;
  }

  /// Obtient un message descriptif pour le score de force
  static String getStrengthMessage(int score, String languageCode) {
    if (languageCode == 'fr') {
      switch (score) {
        case 0:
          return 'Très faible - Utilisez au moins 8 caractères';
        case 1:
          return 'Faible - Ajoutez des majuscules, chiffres ou symboles';
        case 2:
          return 'Moyen - Bon début, mais peut être amélioré';
        case 3:
          return 'Bon - Mot de passe sécurisé';
        case 4:
          return 'Excellent - Très sécurisé';
        default:
          return 'Inconnu';
      }
    } else {
      switch (score) {
        case 0:
          return 'Very weak - Use at least 8 characters';
        case 1:
          return 'Weak - Add uppercase, numbers or symbols';
        case 2:
          return 'Fair - Good start, but can be improved';
        case 3:
          return 'Good - Secure password';
        case 4:
          return 'Excellent - Very secure';
        default:
          return 'Unknown';
      }
    }
  }

  /// Message d'avertissement pour mot de passe compromis
  static String getCompromisedWarningMessage(String languageCode) {
    if (languageCode == 'fr') {
      return 'Ce mot de passe a été compromis dans une fuite de données. '
          'Il est fortement recommandé d\'en choisir un autre pour votre sécurité.';
    } else {
      return 'This password has been exposed in a data breach. '
          'We strongly recommend choosing a different one for your security.';
    }
  }
}
