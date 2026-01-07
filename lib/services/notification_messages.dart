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
    bool isGerman = false,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    final List<String> titles;
    if (isGerman) {
      titles = _mealTitlesDe[mealType] ?? _mealTitlesDe['lunch']!;
    } else if (isFrench) {
      titles = _mealTitlesFr[mealType] ?? _mealTitlesFr['lunch']!;
    } else {
      titles = _mealTitlesEn[mealType] ?? _mealTitlesEn['lunch']!;
    }

    return '$name${_pickRandom(titles)}';
  }

  static String getMealReminderBody({
    required String mealType,
    required bool isFrench,
    bool isGerman = false,
  }) {
    final List<String> bodies;
    if (isGerman) {
      bodies = _mealBodiesDe;
    } else if (isFrench) {
      bodies = _mealBodiesFr;
    } else {
      bodies = _mealBodiesEn;
    }
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

  static const _mealTitlesDe = {
    'breakfast': [
      "Frühstückszeit! 🍳",
      "Gut geschlafen? Zeit zu essen 🌅",
      "Dein Frühstück wartet! ☀️",
    ],
    'lunch': [
      "Mittagspause! 🥗",
      "Zeit zum Auftanken 🔋",
      "Dein Magen ruft 📢",
      "Zeit fürs Mittagessen! 🍽️",
      "Wohlverdiente Pause 😋",
    ],
    'dinner': [
      "Letzte Mahlzeit des Tages 🌙",
      "Abendessen-Zeit! 🍽️",
      "Beende den Tag stark 🌟",
    ],
  };

  static const _mealBodiesFr = [
    "Prends 10 sec pour scanner ton assiette 📸",
    "Coach Ryze veut savoir ce que tu manges 👀",
    "Un repas tracké = des progrès visibles 📈",
    "Décris-moi ton repas, je calcule tout pour toi",
    "Pas le temps ? Juste une photo suffit !",
    "Chaque repas compte pour ton objectif 🎯",
    "Curieux de voir tes macros ? 🧐",
    "Combien de calories dans ton assiette ? Découvre-le !",
  ];

  static const _mealBodiesEn = [
    "Take 10 sec to scan your plate 📸",
    "Coach Ryze wants to know what you're eating 👀",
    "A tracked meal = visible progress 📈",
    "Describe your meal, I'll calculate everything",
    "No time? Just a photo is enough!",
    "Every meal counts towards your goal 🎯",
    "Curious about your macros? 🧐",
    "How many calories in your plate? Find out!",
  ];

  static const _mealBodiesDe = [
    "Nimm dir 10 Sek. um deinen Teller zu scannen 📸",
    "Coach Ryze will wissen, was du isst 👀",
    "Eine getrackte Mahlzeit = sichtbarer Fortschritt 📈",
    "Beschreibe deine Mahlzeit, ich berechne alles",
    "Keine Zeit? Ein Foto reicht!",
    "Jede Mahlzeit zählt für dein Ziel 🎯",
    "Neugierig auf deine Makros? 🧐",
    "Wie viele Kalorien auf deinem Teller? Finde es heraus!",
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // RAPPELS D'HYDRATATION
  // ═══════════════════════════════════════════════════════════════════════════

  static String getWaterReminderTitle({
    required bool isFrench,
    bool isGerman = false,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';
    final List<String> titles;
    if (isGerman) {
      titles = _waterTitlesDe;
    } else if (isFrench) {
      titles = _waterTitlesFr;
    } else {
      titles = _waterTitlesEn;
    }
    return '$name${_pickRandom(titles)}';
  }

  static String getWaterReminderBody({
    required bool isFrench,
    bool isGerman = false,
  }) {
    final List<String> bodies;
    if (isGerman) {
      bodies = _waterBodiesDe;
    } else if (isFrench) {
      bodies = _waterBodiesFr;
    } else {
      bodies = _waterBodiesEn;
    }
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
    "As-tu bu assez aujourd'hui ? Vérifie dans l'app",
    "L'hydratation booste ton métabolisme 🚀",
  ];

  static const _waterBodiesEn = [
    "Fill up your glass to hit your water goal",
    "Water is 0 calories and 100% gains 💪",
    "Your body will thank you!",
    "One glass = one step towards your goal",
    "Stay hydrated, stay focused 🎯",
    "Have you had enough today? Check in the app",
    "Hydration boosts your metabolism 🚀",
  ];

  static const _waterTitlesDe = [
    "Hydrations-Check 💧",
    "Trinkzeit 💦",
    "Dein Körper hat Durst! 🚰",
    "Wasserpause 💧",
  ];

  static const _waterBodiesDe = [
    "Fülle dein Glas, um dein Wasserziel zu erreichen",
    "Wasser hat 0 Kalorien und 100% Gains 💪",
    "Dein Körper wird es dir danken!",
    "Ein Glas = ein Schritt zu deinem Ziel",
    "Bleib hydriert, bleib fokussiert 🎯",
    "Hast du heute genug getrunken? Check die App",
    "Hydration kurbelt deinen Stoffwechsel an 🚀",
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // PROTECTION DE SÉRIE (STREAK)
  // ═══════════════════════════════════════════════════════════════════════════

  static String getStreakProtectionTitle({
    required bool isFrench,
    bool isGerman = false,
    required int streakDays,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    if (isGerman) {
      final titles = [
        "deine $streakDays-Tage-Serie! 🔥",
        "$streakDays Tage am Stück! Gib nicht auf 🔥",
        "Serie in Gefahr: $streakDays Tage 🔥",
        "$streakDays Tage Feuer! 🔥🔥",
      ];
      return '$name${_pickRandom(titles)}';
    } else if (isFrench) {
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
    bool isGerman = false,
    required int streakDays,
  }) {
    if (isGerman) {
      final bodies = [
        "Logge eine Aktivität vor Mitternacht, um sie zu behalten",
        "Brich die Kette jetzt nicht!",
        "1 Aktion = Serie gerettet. Du schaffst das!",
        "Mahlzeit, Wasser oder Sport: wähl deine Waffe 💪",
      ];
      return _pickRandom(bodies);
    } else if (isFrench) {
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
    bool isGerman = false,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';
    final List<String> titles;
    if (isGerman) {
      titles = _workoutTitlesDe;
    } else if (isFrench) {
      titles = _workoutTitlesFr;
    } else {
      titles = _workoutTitlesEn;
    }
    return '$name${_pickRandom(titles)}';
  }

  static String getWorkoutReminderBody({
    required bool isFrench,
    bool isGerman = false,
  }) {
    final List<String> bodies;
    if (isGerman) {
      bodies = _workoutBodiesDe;
    } else if (isFrench) {
      bodies = _workoutBodiesFr;
    } else {
      bodies = _workoutBodiesEn;
    }
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

  static const _workoutTitlesDe = [
    "Zeit zu bewegen! 🏋️",
    "Workout-Zeit! 💪",
    "Dein Körper wartet 🔥",
    "Bereit zu schwitzen? 💦",
    "Heutige Einheit? 🏃",
  ];

  static const _workoutBodiesDe = [
    "Auch 20 Min machen einen Unterschied",
    "Coach Ryze kann dir eine maßgeschneiderte Einheit erstellen",
    "Cardio oder Kraft? Deine Entscheidung!",
    "Jede Einheit bringt dich näher an dein Ziel",
    "Keine Ausreden, nur Ergebnisse 💪",
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉSUMÉ QUOTIDIEN DES OBJECTIFS
  // ═══════════════════════════════════════════════════════════════════════════

  static String getDailyGoalsSummaryTitle({
    required bool isFrench,
    bool isGerman = false,
    required int completed,
    required int total,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    if (completed == total) {
      if (isGerman) {
        return "$name$completed/$total Ziele! 🏆";
      } else if (isFrench) {
        return "$name$completed/$total objectifs ! 🏆";
      } else {
        return "$name$completed/$total goals! 🏆";
      }
    } else if (completed >= total - 1) {
      if (isGerman) {
        return "${name}nur noch ein Ziel! 🎯";
      } else if (isFrench) {
        return "${name}plus qu'un objectif ! 🎯";
      } else {
        return "${name}just one goal left! 🎯";
      }
    } else {
      if (isGerman) {
        return "$name$completed/$total Ziele 🎯";
      } else if (isFrench) {
        return "$name$completed/$total objectifs 🎯";
      } else {
        return "$name$completed/$total goals 🎯";
      }
    }
  }

  static String getDailyGoalsSummaryBody({
    required bool isFrench,
    bool isGerman = false,
    required int completed,
    required int total,
    List<String>? missingGoals,
  }) {
    if (completed == total) {
      final List<String> bodies;
      if (isGerman) {
        bodies = ["Perfekter Tag! Weiter so 🔥", "Du rockst das! 💪", "Champion! 🏆"];
      } else if (isFrench) {
        bodies = ["Journée parfaite ! Continue comme ça 🔥", "Tu gères ! 💪", "Champion ! 🏆"];
      } else {
        bodies = ["Perfect day! Keep it up 🔥", "You're crushing it! 💪", "Champion! 🏆"];
      }
      return _pickRandom(bodies);
    }

    if (missingGoals != null && missingGoals.isNotEmpty) {
      final String separator;
      if (isGerman) {
        separator = ' oder ';
      } else if (isFrench) {
        separator = ' ou ';
      } else {
        separator = ' or ';
      }
      final missing = missingGoals.take(2).join(separator);
      if (isGerman) {
        return "Fast geschafft! Logge $missing";
      } else if (isFrench) {
        return "Tu y es presque ! Log $missing";
      } else {
        return "Almost there! Log $missing";
      }
    }

    final List<String> bodies;
    if (isGerman) {
      bodies = ["Fast geschafft! Stark beenden 💪", "Noch ein kleiner Einsatz!"];
    } else if (isFrench) {
      bodies = ["Tu y es presque ! Termine fort 💪", "Encore un petit effort !"];
    } else {
      bodies = ["Almost there! Finish strong 💪", "One last push!"];
    }
    return _pickRandom(bodies);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉSUMÉ HEBDOMADAIRE
  // ═══════════════════════════════════════════════════════════════════════════

  static String getWeeklyRecapTitle({
    required bool isFrench,
    bool isGerman = false,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';
    final List<String> titles;
    if (isGerman) {
      titles = _weeklyRecapTitlesDe;
    } else if (isFrench) {
      titles = _weeklyRecapTitlesFr;
    } else {
      titles = _weeklyRecapTitlesEn;
    }
    return '$name${_pickRandom(titles)}';
  }

  static String getWeeklyRecapBody({
    required bool isFrench,
    bool isGerman = false,
  }) {
    final List<String> bodies;
    if (isGerman) {
      bodies = _weeklyRecapBodiesDe;
    } else if (isFrench) {
      bodies = _weeklyRecapBodiesFr;
    } else {
      bodies = _weeklyRecapBodiesEn;
    }
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

  static const _weeklyRecapTitlesDe = [
    "Woche abgeschlossen! 📊",
    "Dein Wochenrückblick 📈",
    "7 weitere Tage geschafft! 🎉",
    "Wöchentliche Zusammenfassung 📊",
  ];

  static const _weeklyRecapBodiesDe = [
    "Sieh deinen Fortschritt in der App. Weiter so! 💪",
    "Noch eine Woche gewonnen! Check deine Statistiken",
    "Deine Bemühungen zahlen sich aus. Sieh deine Ergebnisse!",
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉENGAGEMENT (UTILISATEURS INACTIFS)
  // ═══════════════════════════════════════════════════════════════════════════

  static String getReengagementTitle({
    required bool isFrench,
    bool isGerman = false,
    required int daysInactive,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    if (daysInactive == 1) {
      // J+1 : Rappel doux + curiosite
      final List<String> titles;
      if (isGerman) {
        titles = ["wir vermissen dich! 👋", "wir warten auf dich! 🙂", "kommst du zurück? 👀", "hey, alles ok? 💭"];
      } else if (isFrench) {
        titles = ["tu nous manques ! 👋", "on t'attend ! 🙂", "de retour ? 👀", "hey, tout va bien ? 💭"];
      } else {
        titles = ["we miss you! 👋", "waiting for you! 🙂", "coming back? 👀", "hey, everything ok? 💭"];
      }
      return '$name${_pickRandom(titles)}';
    } else if (daysInactive == 2) {
      // J+2 : Un peu plus insistant + FOMO
      final List<String> titles;
      if (isGerman) {
        titles = ["Coach Ryze macht sich Sorgen 🐼", "alles gut? 🤔", "dein Fortschritt wartet! 📈", "schon 2 Tage... ⏰"];
      } else if (isFrench) {
        titles = ["Coach Ryze s'inquiète 🐼", "ça va ? 🤔", "ta progression t'attend ! 📈", "2 jours déjà... ⏰"];
      } else {
        titles = ["Coach Ryze is worried 🐼", "you okay? 🤔", "your progress is waiting! 📈", "2 days already... ⏰"];
      }
      return '$name${_pickRandom(titles)}';
    } else {
      // J+3+ : Urgence + motivation
      final List<String> titles;
      if (isGerman) {
        titles = ["deine Ziele warten! 🎯", "komm stark zurück! 💪", "gib jetzt nicht auf! 🔥", "Neustart? 🌟"];
      } else if (isFrench) {
        titles = ["tes objectifs t'attendent ! 🎯", "reviens en force ! 💪", "ne lâche pas maintenant ! 🔥", "nouveau départ ? 🌟"];
      } else {
        titles = ["your goals are waiting! 🎯", "come back strong! 💪", "don't give up now! 🔥", "fresh start? 🌟"];
      }
      return '$name${_pickRandom(titles)}';
    }
  }

  static String getReengagementBody({
    required bool isFrench,
    bool isGerman = false,
    required int daysInactive,
    int? previousStreak,
  }) {
    if (daysInactive == 1) {
      final List<String> bodies;
      if (isGerman) {
        bodies = [
          "Nur 30 Sekunden, um den Rhythmus zu halten 🎯",
          "1 Tap = du bleibst auf dem richtigen Weg",
          "Eine Mahlzeit scannen dauert kürzer als ein Kaffee ☕",
          "Dein zukünftiges Ich wird dir danken!",
        ];
      } else if (isFrench) {
        bodies = [
          "Juste 30 secondes pour garder le rythme 🎯",
          "1 tap = tu restes sur la bonne voie",
          "Scanner un repas prend moins de temps qu'un café ☕",
          "Ton futur toi te remerciera !",
        ];
      } else {
        bodies = [
          "Just 30 seconds to stay on track 🎯",
          "1 tap = you stay on the right path",
          "Scanning a meal takes less time than a coffee ☕",
          "Your future self will thank you!",
        ];
      }
      return _pickRandom(bodies);
    } else if (daysInactive == 2) {
      final List<String> bodies;
      if (isGerman) {
        bodies = [
          "Mach weiter, wo du aufgehört hast. Es ist einfach!",
          "Dein Fortschritt trackt sich nicht von selbst 😉",
          "Coach Ryze hat viele neue Funktionen für dich",
          "Ein kurzer Check-in und du bist wieder dabei 🚀",
        ];
      } else if (isFrench) {
        bodies = [
          "Reprends là où tu t'es arrêté. C'est facile !",
          "Ton progrès ne va pas se tracker tout seul 😉",
          "Coach Ryze a plein de nouvelles fonctionnalités pour toi",
          "Un petit check-in et tu repars de plus belle 🚀",
        ];
      } else {
        bodies = [
          "Pick up where you left off. It's easy!",
          "Your progress won't track itself 😉",
          "Coach Ryze has new features waiting for you",
          "A quick check-in and you're back on track 🚀",
        ];
      }
      return _pickRandom(bodies);
    } else {
      // Mentionner la serie perdue si elle etait significative
      if (previousStreak != null && previousStreak >= 5) {
        if (isGerman) {
          return "Du hattest eine $previousStreak-Tage-Serie! Bau sie heute wieder auf 🔥";
        } else if (isFrench) {
          return "Tu avais $previousStreak jours de série ! Reconstruis-la aujourd'hui 🔥";
        } else {
          return "You had a $previousStreak-day streak! Rebuild it today 🔥";
        }
      }
      final List<String> bodies;
      if (isGerman) {
        bodies = [
          "Heute ist der beste Tag, um neu zu starten 🌟",
          "Erinnere dich, warum du angefangen hast 💪",
          "Jeder Tag ist eine neue Chance, Fortschritte zu machen",
          "1 Aktion heute = 1 Schritt zu deinem Ziel",
        ];
      } else if (isFrench) {
        bodies = [
          "Aujourd'hui est le meilleur jour pour recommencer 🌟",
          "Rappelle-toi pourquoi tu as commencé 💪",
          "Chaque jour est une nouvelle chance de progresser",
          "1 action aujourd'hui = 1 pas vers ton objectif",
        ];
      } else {
        bodies = [
          "Today is the best day to start again 🌟",
          "Remember why you started 💪",
          "Every day is a new chance to progress",
          "1 action today = 1 step towards your goal",
        ];
      }
      return _pickRandom(bodies);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS "PROCHE DE L'OBJECTIF"
  // ═══════════════════════════════════════════════════════════════════════════

  static String getCloseToGoalTitle({
    required bool isFrench,
    bool isGerman = false,
    required String goalType, // 'calories', 'water', 'protein'
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    switch (goalType) {
      case 'calories':
        if (isGerman) {
          return "${name}fast geschafft! 🎯";
        } else if (isFrench) {
          return "${name}tu y es presque ! 🎯";
        } else {
          return "${name}almost there! 🎯";
        }
      case 'water':
        if (isGerman) {
          return "${name}Wasserziel in Sicht! 💧";
        } else if (isFrench) {
          return "${name}objectif eau en vue ! 💧";
        } else {
          return "${name}water goal in sight! 💧";
        }
      case 'protein':
        if (isGerman) {
          return "${name}Proteinziel fast erreicht! 💪";
        } else if (isFrench) {
          return "${name}protéines presque atteintes ! 💪";
        } else {
          return "${name}protein goal almost reached! 💪";
        }
      default:
        if (isGerman) {
          return "${name}Ziel in Sicht! 🎯";
        } else if (isFrench) {
          return "${name}objectif en vue ! 🎯";
        } else {
          return "${name}goal in sight! 🎯";
        }
    }
  }

  static String getCloseToGoalBody({
    required bool isFrench,
    bool isGerman = false,
    required String goalType,
    required int remaining,
    required String unit,
  }) {
    switch (goalType) {
      case 'calories':
        if (isGerman) {
          return "Nur noch $remaining $unit für dein Kalorienziel!";
        } else if (isFrench) {
          return "Plus que $remaining $unit pour ton objectif calories !";
        } else {
          return "Only $remaining $unit left for your calorie goal!";
        }
      case 'water':
        if (isGerman) {
          return "Noch $remaining $unit und du hast es geschafft!";
        } else if (isFrench) {
          return "Encore $remaining $unit et c'est validé !";
        } else {
          return "Just $remaining $unit more and you're done!";
        }
      case 'protein':
        if (isGerman) {
          return "Nur noch $remaining $unit Protein!";
        } else if (isFrench) {
          return "Plus que $remaining $unit de protéines !";
        } else {
          return "Only $remaining $unit of protein left!";
        }
      default:
        if (isGerman) {
          return "Nur noch $remaining $unit!";
        } else if (isFrench) {
          return "Plus que $remaining $unit !";
        } else {
          return "Only $remaining $unit left!";
        }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MILESTONES / CÉLÉBRATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static String getMilestoneTitle({
    required bool isFrench,
    bool isGerman = false,
    required String milestoneType, // 'streak', 'weight', 'workouts'
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';

    switch (milestoneType) {
      case 'streak':
        if (isGerman) {
          return "${name}neuer Rekord! 🏆";
        } else if (isFrench) {
          return "${name}nouveau record ! 🏆";
        } else {
          return "${name}new record! 🏆";
        }
      case 'weight':
        if (isGerman) {
          return "${name}Gewichtsziel erreicht! 🎉";
        } else if (isFrench) {
          return "${name}objectif poids atteint ! 🎉";
        } else {
          return "${name}weight goal reached! 🎉";
        }
      case 'workouts':
        if (isGerman) {
          return "${name}Meilenstein erreicht! 💪";
        } else if (isFrench) {
          return "${name}cap franchi ! 💪";
        } else {
          return "${name}milestone reached! 💪";
        }
      default:
        if (isGerman) {
          return "${name}Glückwunsch! 🎉";
        } else if (isFrench) {
          return "${name}félicitations ! 🎉";
        } else {
          return "${name}congratulations! 🎉";
        }
    }
  }

  static String getMilestoneBody({
    required bool isFrench,
    bool isGerman = false,
    required String milestoneType,
    required int value,
  }) {
    switch (milestoneType) {
      case 'streak':
        if (isGerman) {
          return "$value-Tage-Serie! Du bist eine Maschine 🔥";
        } else if (isFrench) {
          return "$value jours de série ! Tu es une machine 🔥";
        } else {
          return "$value-day streak! You're a machine 🔥";
        }
      case 'weight':
        if (isGerman) {
          return "Du hast dein Ziel von $value kg erreicht!";
        } else if (isFrench) {
          return "Tu as atteint ton objectif de $value kg !";
        } else {
          return "You've reached your goal of $value kg!";
        }
      case 'workouts':
        if (isGerman) {
          return "$value Einheiten abgeschlossen! Weiter so";
        } else if (isFrench) {
          return "$value séances complétées ! Continue comme ça";
        } else {
          return "$value workouts completed! Keep it up";
        }
      default:
        if (isGerman) {
          return "Bleib am Ball!";
        } else if (isFrench) {
          return "Continue sur cette lancée !";
        } else {
          return "Keep up the momentum!";
        }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION "RIEN LOGUÉ AUJOURD'HUI"
  // ═══════════════════════════════════════════════════════════════════════════

  static String getNothingLoggedTitle({
    required bool isFrench,
    bool isGerman = false,
    String? firstName,
  }) {
    final name = firstName?.isNotEmpty == true ? '$firstName, ' : '';
    final List<String> titles;
    if (isGerman) {
      titles = ["leerer Tag? 📝", "wir warten auf dich! 👀", "ruhiger Tag bisher 🤔"];
    } else if (isFrench) {
      titles = ["journée vide ? 📝", "on t'attend ! 👀", "c'est calme aujourd'hui 🤔"];
    } else {
      titles = ["empty day? 📝", "waiting for you! 👀", "quiet day so far 🤔"];
    }
    return '$name${_pickRandom(titles)}';
  }

  static String getNothingLoggedBody({
    required bool isFrench,
    bool isGerman = false,
  }) {
    final List<String> bodies;
    if (isGerman) {
      bodies = [
        "Du hast noch nichts geloggt. 1 Minute reicht!",
        "Selbst ein Glas Wasser zählt 💧",
        "Coach Ryze langweilt sich ohne Daten 😅",
        "Logge etwas, um den Rhythmus zu halten",
      ];
    } else if (isFrench) {
      bodies = [
        "Tu n'as encore rien logué. 1 minute suffit !",
        "Même un verre d'eau compte 💧",
        "Coach Ryze s'ennuie sans données 😅",
        "Log quelque chose pour garder le rythme",
      ];
    } else {
      bodies = [
        "You haven't logged anything yet. 1 minute is enough!",
        "Even a glass of water counts 💧",
        "Coach Ryze is bored without data 😅",
        "Log something to keep the momentum",
      ];
    }
    return _pickRandom(bodies);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGES MOTIVATIONNELS (pour utilisation occasionnelle)
  // ═══════════════════════════════════════════════════════════════════════════

  static String getMotivationalMessage({
    required bool isFrench,
    bool isGerman = false,
  }) {
    final List<String> messages;
    if (isGerman) {
      messages = [
        "Erinnere dich, warum du angefangen hast 💪",
        "Jeder kleine Schritt zählt",
        "Du bist stärker als deine Ausreden",
        "Beständigkeit schlägt Talent",
        "Heute machst du den Unterschied",
      ];
    } else if (isFrench) {
      messages = [
        "Rappelle-toi pourquoi tu as commencé 💪",
        "Chaque petit pas compte",
        "Tu es plus fort que tes excuses",
        "La constance bat le talent",
        "Aujourd'hui, tu fais la différence",
      ];
    } else {
      messages = [
        "Remember why you started 💪",
        "Every small step counts",
        "You're stronger than your excuses",
        "Consistency beats talent",
        "Today, you make the difference",
      ];
    }
    return _pickRandom(messages);
  }
}
