/// Helper pour déclencher des notifications de célébration depuis n'importe où dans l'app
library;

import '../services/notification_service.dart';
import '../services/localization_service.dart';

class NotificationHelper {
  /// Célébrer un jalon de série (7, 14, 30, 60, 100 jours)
  static Future<void> celebrateStreakMilestone(int streakDays) async {
    final languageCode = LocalizationService.instance.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    // Seulement célébrer les jalons spécifiques
    if (![7, 14, 30, 60, 100].contains(streakDays)) return;

    String title;
    String body;

    if (streakDays == 7) {
      title = isFrench
          ? '🎉 7 jours d\'affilée !'
          : isGerman
              ? '🎉 7 Tage am Stück!'
              : '🎉 7 days in a row!';
      body = isFrench
          ? 'Incroyable ! Tu construis une vraie routine'
          : isGerman
              ? 'Unglaublich! Du baust eine echte Routine auf'
              : 'Amazing! You\'re building a real habit';
    } else if (streakDays == 14) {
      title = isFrench
          ? '🔥 2 semaines parfaites !'
          : isGerman
              ? '🔥 2 perfekte Wochen!'
              : '🔥 2 perfect weeks!';
      body = isFrench
          ? 'Tu es sur la bonne voie. Continue comme ça !'
          : isGerman
              ? 'Du bist auf dem richtigen Weg. Weiter so!'
              : 'You\'re on the right track. Keep it up!';
    } else if (streakDays == 30) {
      title = isFrench
          ? '🏆 30 JOURS DE SÉRIE !'
          : isGerman
              ? '🏆 30-TAGE-SERIE!'
              : '🏆 30-DAY STREAK!';
      body = isFrench
          ? 'Champion ! Coach Ryze est fier de toi 🐼'
          : isGerman
              ? 'Champion! Coach Ryze ist stolz auf dich 🐼'
              : 'Champion! Coach Ryze is proud of you 🐼';
    } else if (streakDays == 60) {
      title = isFrench
          ? '⚡ 2 MOIS CONSÉCUTIFS !'
          : isGerman
              ? '⚡ 2 MONATE AM STÜCK!'
              : '⚡ 2 MONTHS STRAIGHT!';
      body = isFrench
          ? 'Incroyable discipline ! Tu es une machine'
          : isGerman
              ? 'Unglaubliche Disziplin! Du bist unaufhaltsam'
              : 'Incredible discipline! You\'re unstoppable';
    } else if (streakDays == 100) {
      title = isFrench
          ? '💯 CENTENAIRE LÉGENDAIRE !'
          : isGerman
              ? '💯 LEGENDÄRE 100 TAGE!'
              : '💯 LEGENDARY 100 DAYS!';
      body = isFrench
          ? 'TU ES UNE LÉGENDE ! 🏆 Partage ton succès !'
          : isGerman
              ? 'DU BIST EINE LEGENDE! 🏆 Teile deinen Erfolg!'
              : 'YOU ARE A LEGEND! 🏆 Share your success!';
    } else {
      return;
    }

    await NotificationService().sendImmediateNotification(
      title: title,
      body: body,
    );
  }

  /// Célébrer une journée parfaite (3/3 objectifs)
  static Future<void> celebratePerfectDay({String? firstName}) async {
    final languageCode = LocalizationService.instance.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';
    final name = firstName != null && firstName.isNotEmpty ? '$firstName, ' : '';

    final title = isFrench
        ? '${name}JOUR PARFAIT ! 💯'
        : isGerman
            ? '${name}PERFEKTER TAG! 💯'
            : '${name}PERFECT DAY! 💯';
    final body = isFrench
        ? '3/3 objectifs validés. Tu es une machine !'
        : isGerman
            ? '3/3 Ziele erreicht. Du bist unaufhaltsam!'
            : '3/3 goals completed. You\'re unstoppable!';

    await NotificationService().sendImmediateNotification(
      title: title,
      body: body,
    );
  }

  /// Célébrer une semaine parfaite
  static Future<void> celebratePerfectWeek({String? firstName}) async {
    final languageCode = LocalizationService.instance.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';
    final name = firstName != null && firstName.isNotEmpty ? '$firstName, ' : '';

    final title = isFrench
        ? '${name}SEMAINE PARFAITE ! 🎉'
        : isGerman
            ? '${name}PERFEKTE WOCHE! 🎉'
            : '${name}PERFECT WEEK! 🎉';
    final body = isFrench
        ? '7/7 jours d\'objectifs complétés. Incroyable !'
        : isGerman
            ? '7/7 Tage Ziele erreicht. Unglaublich!'
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
    final languageCode = LocalizationService.instance.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';
    final name = firstName != null && firstName.isNotEmpty ? '$firstName, ' : '';

    String title;
    String body;

    if (goalType == 'lose') {
      title = isFrench
          ? '${name}OBJECTIF POIDS ATTEINT ! 🎯'
          : isGerman
              ? '${name}GEWICHTSZIEL ERREICHT! 🎯'
              : '${name}WEIGHT GOAL REACHED! 🎯';
      body = isFrench
          ? 'Félicitations ! Tu as atteint ${targetWeight}kg'
          : isGerman
              ? 'Herzlichen Glückwunsch! Du hast ${targetWeight}kg erreicht'
              : 'Congratulations! You reached ${targetWeight}kg';
    } else {
      title = isFrench
          ? '${name}OBJECTIF POIDS ATTEINT ! 💪'
          : isGerman
              ? '${name}GEWICHTSZIEL ERREICHT! 💪'
              : '${name}WEIGHT GOAL REACHED! 💪';
      body = isFrench
          ? 'Bravo ! Tu as atteint ${targetWeight}kg'
          : isGerman
              ? 'Gut gemacht! Du hast ${targetWeight}kg erreicht'
              : 'Well done! You reached ${targetWeight}kg';
    }

    await NotificationService().sendImmediateNotification(
      title: title,
      body: body,
    );
  }

  /// Message motivant si l'utilisateur n'a rien logué depuis X jours
  static Future<void> sendReengagementNotification(int daysInactive, {String? firstName}) async {
    final languageCode = LocalizationService.instance.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';
    final name = firstName != null && firstName.isNotEmpty ? '$firstName, ' : '';

    String title;
    String body;

    if (daysInactive == 3) {
      title = isFrench
          ? '${name}tu nous manques ! 👋'
          : isGerman
              ? '${name}wir vermissen dich! 👋'
              : '${name}we miss you! 👋';
      body = isFrench
          ? '3 jours sans nouvelle. Reprends où tu en étais'
          : isGerman
              ? '3 Tage weg. Mach weiter, wo du aufgehört hast'
              : '3 days away. Pick up where you left off';
    } else if (daysInactive == 7) {
      title = isFrench
          ? '${name}Coach Ryze veut te revoir 🐼'
          : isGerman
              ? '${name}Coach Ryze möchte dich wiedersehen 🐼'
              : '${name}Coach Ryze wants to see you 🐼';
      body = isFrench
          ? 'Reviens quand tu veux. Ton objectif nutrition t\'attend'
          : isGerman
              ? 'Komm zurück, wann du willst. Dein Ernährungsziel wartet'
              : 'Come back anytime. Your nutrition goal is waiting';
    } else if (daysInactive == 14) {
      title = isFrench
          ? '${name}prêt à recommencer ? 💪'
          : isGerman
              ? '${name}bereit neu zu starten? 💪'
              : '${name}ready to restart? 💪';
      body = isFrench
          ? '14 jours sans log. On est là pour t\'aider à revenir'
          : isGerman
              ? '14 Tage weg. Wir helfen dir wieder auf Kurs zu kommen'
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
