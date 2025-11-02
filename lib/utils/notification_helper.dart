/// Helper pour déclencher des notifications de célébration depuis n'importe où dans l'app
library;

import '../services/notification_service.dart';
import '../services/localization_service.dart';

class NotificationHelper {
  /// Célébrer un jalon de série (7, 14, 30, 60, 100 jours)
  static Future<void> celebrateStreakMilestone(int streakDays) async {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

    // Seulement célébrer les jalons spécifiques
    if (![7, 14, 30, 60, 100].contains(streakDays)) return;

    String title;
    String body;

    if (streakDays == 7) {
      title = isFrench ? '🎉 7 jours d\'affilée !' : '🎉 7 days in a row!';
      body = isFrench
          ? 'Incroyable ! Tu construis une vraie routine'
          : 'Amazing! You\'re building a real habit';
    } else if (streakDays == 14) {
      title = isFrench ? '🔥 2 semaines parfaites !' : '🔥 2 perfect weeks!';
      body = isFrench
          ? 'Tu es sur la bonne voie. Continue comme ça !'
          : 'You\'re on the right track. Keep it up!';
    } else if (streakDays == 30) {
      title = isFrench ? '🏆 30 JOURS DE SÉRIE !' : '🏆 30-DAY STREAK!';
      body = isFrench
          ? 'Champion ! Coach Ryze est fier de toi 🐼'
          : 'Champion! Coach Ryze is proud of you 🐼';
    } else if (streakDays == 60) {
      title = isFrench ? '⚡ 2 MOIS CONSÉCUTIFS !' : '⚡ 2 MONTHS STRAIGHT!';
      body = isFrench
          ? 'Incroyable discipline ! Tu es une machine'
          : 'Incredible discipline! You\'re unstoppable';
    } else if (streakDays == 100) {
      title = isFrench ? '💯 CENTENAIRE LÉGENDAIRE !' : '💯 LEGENDARY 100 DAYS!';
      body = isFrench
          ? 'TU ES UNE LÉGENDE ! 🏆 Partage ton succès !'
          : 'YOU ARE A LEGEND! 🏆 Share your success!';
    } else {
      return;
    }

    await NotificationService().sendImmediateNotification(
      title: title,
      body: body,
    );
  }

  /// Célébrer une journée parfaite (4/4 objectifs)
  static Future<void> celebratePerfectDay({String? firstName}) async {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final name = firstName != null && firstName.isNotEmpty ? '$firstName, ' : '';

    final title = isFrench ? '${name}JOUR PARFAIT ! 💯' : '${name}PERFECT DAY! 💯';
    final body = isFrench
        ? '4/4 objectifs validés. Tu es une machine !'
        : '4/4 goals completed. You\'re unstoppable!';

    await NotificationService().sendImmediateNotification(
      title: title,
      body: body,
    );
  }

  /// Célébrer une semaine parfaite
  static Future<void> celebratePerfectWeek({String? firstName}) async {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final name = firstName != null && firstName.isNotEmpty ? '$firstName, ' : '';

    final title = isFrench ? '${name}SEMAINE PARFAITE ! 🎉' : '${name}PERFECT WEEK! 🎉';
    final body = isFrench
        ? '7/7 jours d\'objectifs complétés. Incroyable !'
        : '7/7 days of goals completed. Amazing!';

    await NotificationService().sendImmediateNotification(
      title: title,
      body: body,
    );
  }

  /// Célébrer un nouveau record de poids
  static Future<void> celebrateWeightGoal({
    required double targetWeight,
    required String goalType, // 'lose' ou 'gain'
    String? firstName,
  }) async {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final name = firstName != null && firstName.isNotEmpty ? '$firstName, ' : '';

    String title;
    String body;

    if (goalType == 'lose') {
      title = isFrench ? '${name}OBJECTIF POIDS ATTEINT ! 🎯' : '${name}WEIGHT GOAL REACHED! 🎯';
      body = isFrench
          ? 'Félicitations ! Tu as atteint ${targetWeight}kg'
          : 'Congratulations! You reached ${targetWeight}kg';
    } else {
      title = isFrench ? '${name}OBJECTIF POIDS ATTEINT ! 💪' : '${name}WEIGHT GOAL REACHED! 💪';
      body = isFrench
          ? 'Bravo ! Tu as atteint ${targetWeight}kg'
          : 'Well done! You reached ${targetWeight}kg';
    }

    await NotificationService().sendImmediateNotification(
      title: title,
      body: body,
    );
  }

  /// Message motivant si l'utilisateur n'a rien logué depuis X jours
  static Future<void> sendReengagementNotification(int daysInactive, {String? firstName}) async {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final name = firstName != null && firstName.isNotEmpty ? '$firstName, ' : '';

    String title;
    String body;

    if (daysInactive == 3) {
      title = isFrench ? '${name}tu nous manques ! 👋' : '${name}we miss you! 👋';
      body = isFrench
          ? '3 jours sans nouvelle. Reprends où tu en étais'
          : '3 days away. Pick up where you left off';
    } else if (daysInactive == 7) {
      title = isFrench ? '${name}Coach Ryze veut te revoir 🐼' : '${name}Coach Ryze wants to see you 🐼';
      body = isFrench
          ? 'Reviens quand tu veux. Ton objectif nutrition t\'attend'
          : 'Come back anytime. Your nutrition goal is waiting';
    } else if (daysInactive == 14) {
      title = isFrench ? '${name}prêt à recommencer ? 💪' : '${name}ready to restart? 💪';
      body = isFrench
          ? '14 jours sans log. On est là pour t\'aider à revenir'
          : '14 days away. We\'re here to help you get back on track';
    } else {
      return;
    }

    await NotificationService().sendImmediateNotification(
      title: title,
      body: body,
    );
  }
}
