/// Pool de messages pour les notifications push
/// Chaque type a plusieurs variations pour éviter la fatigue des notifications
library;

import 'dart:math';

class NotificationMessages {
  static final _random = Random();

  /// Sélectionne un message aléatoire dans la liste
  static String _pickRandom(List<String> messages) {
    return messages[_random.nextInt(messages.length)];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RAPPELS DE REPAS
  // ═══════════════════════════════════════════════════════════════════════════

  static String getMealReminderTitle({
    required String mealType,
    required bool isFrench,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    final titles = isFrench
        ? _mealTitlesFr[mealType] ?? _mealTitlesFr['lunch']!
        : _mealTitlesEn[mealType] ?? _mealTitlesEn['lunch']!;

    return '$name${_pickRandom(titles)}';
  }

  static String getMealReminderBody({
    required String mealType,
    required bool isFrench,
  }) {
    final bodies = isFrench ? _mealBodiesFr : _mealBodiesEn;
    return _pickRandom(bodies);
  }

  static const _mealTitlesFr = {
    'breakfast': [
      "petit-déj time ! 🍳",
      "bien dormi ? C'est l'heure de manger 🌅",
      "ton petit-déjeuner t'attend ! ☀️",
    ],
    'lunch': [
      "pause déjeuner ! 🥗",
      "l'heure de recharger les batteries 🔋",
      "ton estomac t'appelle 📢",
      "c'est l'heure du lunch ! 🍽️",
      "pause bien méritée 😋",
    ],
    'dinner': [
      "dernier repas de la journée 🌙",
      "dîner time ! 🍽️",
      "on finit la journée en beauté 🌟",
    ],
  };

  static const _mealTitlesEn = {
    'breakfast': [
      "breakfast time! 🍳",
      "rise and dine! 🌅",
      "morning fuel awaits! ☀️",
    ],
    'lunch': [
      "lunch break! 🥗",
      "time to refuel 🔋",
      "your stomach is calling 📢",
      "midday munch time! 🍽️",
      "well-deserved break 😋",
    ],
    'dinner': [
      "last meal of the day 🌙",
      "dinner time! 🍽️",
      "end the day strong 🌟",
    ],
  };

  static const _mealBodiesFr = [
    "Prends 10 sec pour scanner ton assiette 📸",
    "Coach Ryze veut savoir ce que tu manges 👀",
    "Un repas tracké = des progrès visibles 📈",
    "Décris-moi ton repas, je m'occupe du reste",
    "Pas le temps ? Juste une photo suffit !",
    "Chaque repas compte pour ton objectif 🎯",
  ];

  static const _mealBodiesEn = [
    "Take 10 sec to scan your plate 📸",
    "Coach Ryze wants to know what you're eating 👀",
    "A tracked meal = visible progress 📈",
    "Describe your meal, I'll handle the rest",
    "No time? Just a photo is enough!",
    "Every meal counts towards your goal 🎯",
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // RAPPELS D'HYDRATATION
  // ═══════════════════════════════════════════════════════════════════════════

  static String getWaterReminderTitle({
    required bool isFrench,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';
    final titles = isFrench ? _waterTitlesFr : _waterTitlesEn;
    return '$name${_pickRandom(titles)}';
  }

  static String getWaterReminderBody({required bool isFrench}) {
    final bodies = isFrench ? _waterBodiesFr : _waterBodiesEn;
    return _pickRandom(bodies);
  }

  static const _waterTitlesFr = [
    "hydratation check 💧",
    "glou glou time 💦",
    "ton corps a soif ! 🚰",
    "pause eau 💧",
  ];

  static const _waterTitlesEn = [
    "hydration check 💧",
    "water break time 💦",
    "your body needs water! 🚰",
    "hydration station 💧",
  ];

  static const _waterBodiesFr = [
    "Remplis ton verre pour ton objectif eau",
    "L'eau c'est 0 calorie et 100% gains 💪",
    "Ton corps te remerciera !",
    "Un verre d'eau = un pas vers ton objectif",
    "Reste hydraté, reste focus 🎯",
  ];

  static const _waterBodiesEn = [
    "Fill up your glass to hit your water goal",
    "Water is 0 calories and 100% gains 💪",
    "Your body will thank you!",
    "One glass = one step towards your goal",
    "Stay hydrated, stay focused 🎯",
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // PROTECTION DE SÉRIE (STREAK)
  // ═══════════════════════════════════════════════════════════════════════════

  static String getStreakProtectionTitle({
    required bool isFrench,
    required int streakDays,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    if (isFrench) {
      final titles = [
        "ta série de $streakDays jours ! 🔥",
        "$streakDays jours de suite ! Ne lâche pas 🔥",
        "série en danger : $streakDays jours 🔥",
        "$streakDays jours de feu ! 🔥🔥",
      ];
      return '$name${_pickRandom(titles)}';
    } else {
      final titles = [
        "your $streakDays-day streak! 🔥",
        "$streakDays days strong! Don't stop 🔥",
        "streak alert: $streakDays days 🔥",
        "$streakDays days on fire! 🔥🔥",
      ];
      return '$name${_pickRandom(titles)}';
    }
  }

  static String getStreakProtectionBody({
    required bool isFrench,
    required int streakDays,
  }) {
    if (isFrench) {
      final bodies = [
        "Log une activité avant minuit pour la garder",
        "Ne casse pas la chaîne maintenant !",
        "1 action = série préservée. Tu peux le faire !",
        "Repas, eau ou sport : choisis ton arme 💪",
      ];
      return _pickRandom(bodies);
    } else {
      final bodies = [
        "Log any activity before midnight to keep it",
        "Don't break the chain now!",
        "1 action = streak saved. You got this!",
        "Meal, water, or workout: pick your weapon 💪",
      ];
      return _pickRandom(bodies);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RAPPELS D'ENTRAÎNEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  static String getWorkoutReminderTitle({
    required bool isFrench,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';
    final titles = isFrench ? _workoutTitlesFr : _workoutTitlesEn;
    return '$name${_pickRandom(titles)}';
  }

  static String getWorkoutReminderBody({required bool isFrench}) {
    final bodies = isFrench ? _workoutBodiesFr : _workoutBodiesEn;
    return _pickRandom(bodies);
  }

  static const _workoutTitlesFr = [
    "c'est l'heure de bouger ! 🏋️",
    "workout time ! 💪",
    "ton corps t'attend 🔥",
    "prêt à transpirer ? 💦",
    "séance du jour ? 🏃",
  ];

  static const _workoutTitlesEn = [
    "time to move! 🏋️",
    "workout time! 💪",
    "your body is waiting 🔥",
    "ready to sweat? 💦",
    "today's session? 🏃",
  ];

  static const _workoutBodiesFr = [
    "Même 20 min font la différence",
    "Coach Ryze peut te créer une séance sur mesure",
    "Cardio ou muscu ? À toi de jouer !",
    "Chaque séance te rapproche de ton objectif",
    "Pas d'excuses, que des résultats 💪",
  ];

  static const _workoutBodiesEn = [
    "Even 20 min makes a difference",
    "Coach Ryze can create a custom session for you",
    "Cardio or strength? Your call!",
    "Every session brings you closer to your goal",
    "No excuses, only results 💪",
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉSUMÉ QUOTIDIEN DES OBJECTIFS
  // ═══════════════════════════════════════════════════════════════════════════

  static String getDailyGoalsSummaryTitle({
    required bool isFrench,
    required int completed,
    required int total,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    if (completed == total) {
      return isFrench
          ? "$name$completed/$total objectifs ! 🏆"
          : "$name$completed/$total goals! 🏆";
    } else if (completed >= total - 1) {
      return isFrench
          ? "${name}plus qu'un objectif ! 🎯"
          : "${name}just one goal left! 🎯";
    } else {
      return isFrench
          ? "$name$completed/$total objectifs 🎯"
          : "$name$completed/$total goals 🎯";
    }
  }

  static String getDailyGoalsSummaryBody({
    required bool isFrench,
    required int completed,
    required int total,
    List<String>? missingGoals,
  }) {
    if (completed == total) {
      final bodies = isFrench
          ? ["Journée parfaite ! Continue comme ça 🔥", "Tu gères ! 💪", "Champion ! 🏆"]
          : ["Perfect day! Keep it up 🔥", "You're crushing it! 💪", "Champion! 🏆"];
      return _pickRandom(bodies);
    }

    if (missingGoals != null && missingGoals.isNotEmpty) {
      final missing = missingGoals.take(2).join(isFrench ? ' ou ' : ' or ');
      return isFrench
          ? "Tu y es presque ! Log $missing"
          : "Almost there! Log $missing";
    }

    final bodies = isFrench
        ? ["Tu y es presque ! Termine fort 💪", "Encore un petit effort !"]
        : ["Almost there! Finish strong 💪", "One last push!"];
    return _pickRandom(bodies);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉSUMÉ HEBDOMADAIRE
  // ═══════════════════════════════════════════════════════════════════════════

  static String getWeeklyRecapTitle({
    required bool isFrench,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';
    final titles = isFrench ? _weeklyRecapTitlesFr : _weeklyRecapTitlesEn;
    return '$name${_pickRandom(titles)}';
  }

  static String getWeeklyRecapBody({required bool isFrench}) {
    final bodies = isFrench ? _weeklyRecapBodiesFr : _weeklyRecapBodiesEn;
    return _pickRandom(bodies);
  }

  static const _weeklyRecapTitlesFr = [
    "semaine terminée ! 📊",
    "bilan de ta semaine 📈",
    "7 jours de plus ! 🎉",
    "récap' hebdo 📊",
  ];

  static const _weeklyRecapTitlesEn = [
    "week completed! 📊",
    "your weekly recap 📈",
    "7 more days done! 🎉",
    "weekly summary 📊",
  ];

  static const _weeklyRecapBodiesFr = [
    "Vois tes progrès dans l'app. Continue ! 💪",
    "Une autre semaine de gagnée ! Regarde tes stats",
    "Tes efforts paient. Découvre tes résultats !",
  ];

  static const _weeklyRecapBodiesEn = [
    "Check your progress in the app. Keep going! 💪",
    "Another week won! Check your stats",
    "Your efforts are paying off. See your results!",
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉENGAGEMENT (UTILISATEURS INACTIFS)
  // ═══════════════════════════════════════════════════════════════════════════

  static String getReengagementTitle({
    required bool isFrench,
    required int daysInactive,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    if (daysInactive == 1) {
      // J+1 : Rappel doux
      final titles = isFrench
          ? ["tu nous manques ! 👋", "on t'attend ! 🙂", "de retour ? 👀"]
          : ["we miss you! 👋", "waiting for you! 🙂", "coming back? 👀"];
      return '$name${_pickRandom(titles)}';
    } else if (daysInactive == 2) {
      // J+2 : Un peu plus insistant
      final titles = isFrench
          ? ["Coach Ryze s'inquiète 😅", "ça va ? 🤔", "on a besoin de toi ! 💪"]
          : ["Coach Ryze is worried 😅", "you okay? 🤔", "we need you! 💪"];
      return '$name${_pickRandom(titles)}';
    } else {
      // J+3+ : Urgence
      final titles = isFrench
          ? ["tes objectifs t'attendent ! 🎯", "reviens en force ! 💪", "ne lâche pas maintenant ! 🔥"]
          : ["your goals are waiting! 🎯", "come back strong! 💪", "don't give up now! 🔥"];
      return '$name${_pickRandom(titles)}';
    }
  }

  static String getReengagementBody({
    required bool isFrench,
    required int daysInactive,
    int? previousStreak,
  }) {
    if (daysInactive == 1) {
      final bodies = isFrench
          ? [
              "Tu n'as encore rien logué aujourd'hui",
              "1 minute suffit pour rester sur la bonne voie",
              "Juste un repas ou un verre d'eau ?",
            ]
          : [
              "You haven't logged anything today",
              "1 minute is all you need to stay on track",
              "Just a meal or a glass of water?",
            ];
      return _pickRandom(bodies);
    } else if (daysInactive == 2) {
      final bodies = isFrench
          ? [
              "2 jours sans nouvelles... Reviens dire bonjour !",
              "Ton progrès ne va pas se tracker tout seul 😉",
              "Un petit check-in ? Coach Ryze t'attend",
            ]
          : [
              "2 days without news... Come say hi!",
              "Your progress won't track itself 😉",
              "A quick check-in? Coach Ryze is waiting",
            ];
      return _pickRandom(bodies);
    } else {
      // Mentionner la série perdue si elle était significative
      if (previousStreak != null && previousStreak >= 5) {
        return isFrench
            ? "Tu avais une série de $previousStreak jours ! Recommence aujourd'hui"
            : "You had a $previousStreak-day streak! Start fresh today";
      }
      final bodies = isFrench
          ? [
              "C'est le moment de reprendre. 1 tap suffit !",
              "Rappelle-toi pourquoi tu as commencé 💪",
              "Chaque jour est une nouvelle chance",
            ]
          : [
              "Time to get back. 1 tap is all it takes!",
              "Remember why you started 💪",
              "Every day is a new chance",
            ];
      return _pickRandom(bodies);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS "PROCHE DE L'OBJECTIF"
  // ═══════════════════════════════════════════════════════════════════════════

  static String getCloseToGoalTitle({
    required bool isFrench,
    required String goalType, // 'calories', 'water', 'protein'
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    switch (goalType) {
      case 'calories':
        return isFrench
            ? "${name}tu y es presque ! 🎯"
            : "${name}almost there! 🎯";
      case 'water':
        return isFrench
            ? "${name}objectif eau en vue ! 💧"
            : "${name}water goal in sight! 💧";
      case 'protein':
        return isFrench
            ? "${name}protéines presque atteintes ! 💪"
            : "${name}protein goal almost reached! 💪";
      default:
        return isFrench
            ? "${name}objectif en vue ! 🎯"
            : "${name}goal in sight! 🎯";
    }
  }

  static String getCloseToGoalBody({
    required bool isFrench,
    required String goalType,
    required int remaining,
    required String unit,
  }) {
    switch (goalType) {
      case 'calories':
        return isFrench
            ? "Plus que $remaining $unit pour ton objectif calories !"
            : "Only $remaining $unit left for your calorie goal!";
      case 'water':
        return isFrench
            ? "Encore $remaining $unit et c'est validé !"
            : "Just $remaining $unit more and you're done!";
      case 'protein':
        return isFrench
            ? "Plus que $remaining $unit de protéines !"
            : "Only $remaining $unit of protein left!";
      default:
        return isFrench
            ? "Plus que $remaining $unit !"
            : "Only $remaining $unit left!";
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MILESTONES / CÉLÉBRATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static String getMilestoneTitle({
    required bool isFrench,
    required String milestoneType, // 'streak', 'weight', 'workouts'
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    switch (milestoneType) {
      case 'streak':
        return isFrench
            ? "${name}nouveau record ! 🏆"
            : "${name}new record! 🏆";
      case 'weight':
        return isFrench
            ? "${name}objectif poids atteint ! 🎉"
            : "${name}weight goal reached! 🎉";
      case 'workouts':
        return isFrench
            ? "${name}cap franchi ! 💪"
            : "${name}milestone reached! 💪";
      default:
        return isFrench
            ? "${name}félicitations ! 🎉"
            : "${name}congratulations! 🎉";
    }
  }

  static String getMilestoneBody({
    required bool isFrench,
    required String milestoneType,
    required int value,
  }) {
    switch (milestoneType) {
      case 'streak':
        return isFrench
            ? "$value jours de série ! Tu es une machine 🔥"
            : "$value-day streak! You're a machine 🔥";
      case 'weight':
        return isFrench
            ? "Tu as atteint ton objectif de $value kg !"
            : "You've reached your goal of $value kg!";
      case 'workouts':
        return isFrench
            ? "$value séances complétées ! Continue comme ça"
            : "$value workouts completed! Keep it up";
      default:
        return isFrench
            ? "Continue sur cette lancée !"
            : "Keep up the momentum!";
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION "RIEN LOGUÉ AUJOURD'HUI"
  // ═══════════════════════════════════════════════════════════════════════════

  static String getNothingLoggedTitle({
    required bool isFrench,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';
    final titles = isFrench
        ? ["journée vide ? 📝", "on t'attend ! 👀", "c'est calme aujourd'hui 🤔"]
        : ["empty day? 📝", "waiting for you! 👀", "quiet day so far 🤔"];
    return '$name${_pickRandom(titles)}';
  }

  static String getNothingLoggedBody({required bool isFrench}) {
    final bodies = isFrench
        ? [
            "Tu n'as encore rien logué. 1 minute suffit !",
            "Même un verre d'eau compte 💧",
            "Coach Ryze s'ennuie sans données 😅",
            "Log quelque chose pour garder le rythme",
          ]
        : [
            "You haven't logged anything yet. 1 minute is enough!",
            "Even a glass of water counts 💧",
            "Coach Ryze is bored without data 😅",
            "Log something to keep the momentum",
          ];
    return _pickRandom(bodies);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGES MOTIVATIONNELS (pour utilisation occasionnelle)
  // ═══════════════════════════════════════════════════════════════════════════

  static String getMotivationalMessage({required bool isFrench}) {
    final messages = isFrench
        ? [
            "Rappelle-toi pourquoi tu as commencé 💪",
            "Chaque petit pas compte",
            "Tu es plus fort que tes excuses",
            "La constance bat le talent",
            "Aujourd'hui, tu fais la différence",
          ]
        : [
            "Remember why you started 💪",
            "Every small step counts",
            "You're stronger than your excuses",
            "Consistency beats talent",
            "Today, you make the difference",
          ];
    return _pickRandom(messages);
  }
}
