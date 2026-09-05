import '../services/localization_service.dart';

/// Copy of the v2 onboarding in FR / EN / DE.
///
/// Kept apart from the giant `translations.dart` map so the flow stays
/// self-contained. `t('key')` falls back to English, then to the key itself.
class OnbStrings {
  OnbStrings(this.lang);

  factory OnbStrings.current() => OnbStrings(LocalizationService.instance.currentLanguageCode);

  final String lang;

  String t(String key, [Map<String, String> params = const {}]) {
    final entry = _m[key];
    var value = entry?[lang] ?? entry?['en'] ?? key;
    params.forEach((k, v) => value = value.replaceAll('{$k}', v));
    return value;
  }

  /// Short and long localized day names, Monday first.
  List<String> get dayShort => _pick(['L', 'M', 'M', 'J', 'V', 'S', 'D'], ['M', 'T', 'W', 'T', 'F', 'S', 'S'], ['M', 'D', 'M', 'D', 'F', 'S', 'S']);
  List<String> get dayFull => _pick(
        ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
        ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'],
      );

  List<String> _pick(List<String> fr, List<String> en, List<String> de) => lang == 'fr' ? fr : (lang == 'de' ? de : en);

  static const Map<String, Map<String, String>> _m = {
    // ---------- Hello ----------
    'hello_title': {'fr': 'Salut {n}.', 'en': 'Hi {n}.', 'de': 'Hallo {n}.'},
    'hello_sub': {
      'fr': 'Deux coachs IA : un pour le sport, un pour l’assiette. Ils planifient ta semaine et font le point avec toi chaque semaine.',
      'en': 'Two AI coaches: one for training, one for food. They plan your week and check in with you every week.',
      'de': 'Zwei KI-Coaches: einer fürs Training, einer fürs Essen. Sie planen deine Woche und ziehen jede Woche mit dir Bilanz.',
    },
    'hello_punch1': {'fr': 'Les autres apps te font compter.', 'en': 'Other apps make you count.', 'de': 'Andere Apps lassen dich zählen.'},
    'hello_punch2': {'fr': 'Nous, on te coache.', 'en': 'We coach you.', 'de': 'Wir coachen dich.'},
    'hello_f1': {
      'fr': 'Ta semaine repas et sport, planifiée par chat avec les coachs',
      'en': 'Your meal and training week, planned by chatting with the coaches',
      'de': 'Deine Ess- und Trainingswoche, per Chat mit den Coaches geplant'
    },
    'hello_f2': {
      'fr': 'Tes séances de muscu, cardio et HIIT, guidées et enregistrées',
      'en': 'Your strength, cardio and HIIT sessions, guided and logged',
      'de': 'Deine Kraft-, Cardio- und HIIT-Einheiten, angeleitet und protokolliert'
    },
    'hello_f3': {
      'fr': 'Tes repas scannés en une photo, calories et macros',
      'en': 'Your meals scanned from one photo, calories and macros',
      'de': 'Deine Mahlzeiten mit einem Foto gescannt, Kalorien und Makros',
    },
    'hello_f4': {
      'fr': 'Un coach qui se souvient de toi et te relance',
      'en': 'A coach who remembers you and follows up',
      'de': 'Ein Coach, der sich an dich erinnert und nachhakt'
    },
    'hello_f5': {
      'fr': 'Ton poids, ta progression, et un bilan ensemble chaque semaine',
      'en': 'Your weight, your progress, and a weekly check-in together',
      'de': 'Dein Gewicht, dein Fortschritt und jede Woche eine gemeinsame Bilanz'
    },
    'hello_cta': {
      'fr': 'Quelques questions, puis ta semaine',
      'en': 'A few questions, then your week',
      'de': 'Ein paar Fragen, dann deine Woche',
    },

    // ---------- Chapters ----------
    'ch1_title': {'fr': 'Toi', 'en': 'You', 'de': 'Du'},
    'ch1_sub': {
      'fr': 'Quelques questions rapides. Aucun clavier.',
      'en': 'A few quick questions. No typing.',
      'de': 'Ein paar schnelle Fragen. Ohne Tippen.',
    },
    'ch2_title': {'fr': 'Ton pourquoi', 'en': 'Your why', 'de': 'Dein Warum'},
    'ch2_sub': {
      'fr': 'Deux questions, et ce qu’on en fait.',
      'en': 'Two questions, and what we do with them.',
      'de': 'Zwei Fragen, und was wir daraus machen.'
    },
    'ch3_title': {'fr': 'Ta semaine', 'en': 'Your week', 'de': 'Deine Woche'},
    'ch3_sub': {'fr': 'L’app, pour de vrai.', 'en': 'The app, for real.', 'de': 'Die App, in echt.'},
    'ch4_title': {'fr': 'Ton coach', 'en': 'Your coach', 'de': 'Dein Coach'},
    'ch4_sub': {'fr': 'Le ton, le jour, la signature.', 'en': 'The tone, the day, the signature.', 'de': 'Der Ton, der Tag, die Unterschrift.'},

    // ---------- Shell ----------
    'coach_name': {'fr': 'Coach Ryze', 'en': 'Coach Ryze', 'de': 'Coach Ryze'},
    'coach_sport': {'fr': 'sport', 'en': 'training', 'de': 'Sport'},
    'coach_nutri': {'fr': 'nutrition', 'en': 'nutrition', 'de': 'Ernährung'},
    'cta_continue': {'fr': 'Continuer', 'en': 'Continue', 'de': 'Weiter'},
    'back': {'fr': 'Retour', 'en': 'Back', 'de': 'Zurück'},

    // ---------- Chapter 1 ----------
    'q_goal': {'fr': 'Qu’est-ce qu’on vise ensemble ?', 'en': 'What are we aiming for together?', 'de': 'Was streben wir gemeinsam an?'},
    'goal_lose': {'fr': 'Perdre du gras', 'en': 'Lose fat', 'de': 'Fett verlieren'},
    'goal_lose_sub': {'fr': 'Sans régime de misère', 'en': 'No starvation diet', 'de': 'Ohne Hungerdiät'},
    'goal_gain': {'fr': 'Prendre du muscle', 'en': 'Build muscle', 'de': 'Muskeln aufbauen'},
    'goal_gain_sub': {'fr': 'Charger intelligemment', 'en': 'Load smart', 'de': 'Clever belasten'},
    'goal_maintain': {'fr': 'Rester en forme', 'en': 'Stay in shape', 'de': 'In Form bleiben'},
    'goal_maintain_sub': {'fr': 'Énergie, sommeil, santé', 'en': 'Energy, sleep, health', 'de': 'Energie, Schlaf, Gesundheit'},
    'react_lose': {
      'fr': 'Perdre du gras, propre et durable. Ça, on sait faire.',
      'en': 'Losing fat, clean and lasting. That, we know how to do.',
      'de': 'Fett verlieren, sauber und nachhaltig. Das können wir.'
    },
    'react_gain': {
      'fr': 'Prendre du muscle, on va charger juste.',
      'en': 'Building muscle, we’ll load it right.',
      'de': 'Muskeln aufbauen, wir belasten richtig.'
    },
    'react_maintain': {'fr': 'Le meilleur des objectifs.', 'en': 'The best goal there is.', 'de': 'Das beste Ziel überhaupt.'},
    'q_gender': {
      'fr': 'Pour calibrer tes besoins : tu es…',
      'en': 'So we get your numbers right, you are…',
      'de': 'Damit wir deinen Bedarf richtig berechnen: Du bist…',
    },
    'gender_m': {'fr': 'Homme', 'en': 'Man', 'de': 'Mann'},
    'gender_f': {'fr': 'Femme', 'en': 'Woman', 'de': 'Frau'},
    'q_age': {'fr': 'Ok. T’as quel âge ?', 'en': 'Ok. How old are you?', 'de': 'Ok. Wie alt bist du?'},
    'unit_years': {'fr': 'ans', 'en': 'years', 'de': 'Jahre'},
    'q_height': {'fr': 'Et tu mesures combien ?', 'en': 'And how tall are you?', 'de': 'Und wie groß bist du?'},
    'q_weight': {'fr': 'Ton poids, aujourd’hui ?', 'en': 'Your weight, today?', 'de': 'Dein Gewicht, heute?'},
    'q_target': {'fr': 'Et on vise quoi, comme poids ?', 'en': 'And what weight are we aiming for?', 'de': 'Und welches Gewicht streben wir an?'},
    'ruler_hint': {'fr': 'Glisse la règle', 'en': 'Slide the ruler', 'de': 'Schieb das Lineal'},
    'delta_same': {'fr': 'Même poids qu’aujourd’hui', 'en': 'Same weight as today', 'de': 'Gleiches Gewicht wie heute'},
    'delta_rate': {'fr': 'Rythme sain : environ {w} semaines', 'en': 'Healthy pace: about {w} weeks', 'de': 'Gesundes Tempo: etwa {w} Wochen'},
    'cta_projection': {'fr': 'Voir la projection', 'en': 'See the projection', 'de': 'Prognose ansehen'},
    'q_projection': {
      'fr': 'À un rythme sain, voilà où on t’emmène.',
      'en': 'At a healthy pace, this is where we take you.',
      'de': 'In gesundem Tempo bringen wir dich hierhin.'
    },
    'proj_today': {'fr': 'Aujourd’hui', 'en': 'Today', 'de': 'Heute'},
    'proj_on': {'fr': 'Le {d}', 'en': 'On {d}', 'de': 'Am {d}'},
    'proj_noplan': {'fr': 'Sans plan', 'en': 'No plan', 'de': 'Ohne Plan'},
    'legend_with': {'fr': 'Avec Ryze', 'en': 'With Ryze', 'de': 'Mit Ryze'},
    'legend_without': {'fr': 'En continuant comme avant', 'en': 'Continuing as before', 'de': 'Weiter wie bisher'},
    'stat_rate': {'fr': 'Rythme', 'en': 'Pace', 'de': 'Tempo'},
    'stat_duration': {'fr': 'Durée', 'en': 'Duration', 'de': 'Dauer'},
    'weeks': {'fr': '{w} semaines', 'en': '{w} weeks', 'de': '{w} Wochen'},
    'per_week': {'fr': '/ sem', 'en': '/ wk', 'de': '/ Wo'},
    'cta_go': {'fr': 'On y va', 'en': 'Let’s go', 'de': 'Los geht’s'},
    'q_activity': {
      'fr': 'Aujourd’hui, tu bouges combien de fois par semaine ?',
      'en': 'Today, how many times a week do you move?',
      'de': 'Wie oft pro Woche bewegst du dich heute?'
    },
    'act_low': {'fr': 'Presque jamais', 'en': 'Almost never', 'de': 'Fast nie'},
    'act_low_sub': {'fr': 'On part de là, aucun souci', 'en': 'We start from there, no problem', 'de': 'Da fangen wir an, kein Problem'},
    'act_light': {'fr': '1 à 2 fois', 'en': '1 to 2 times', 'de': '1 bis 2 Mal'},
    'act_light_sub': {'fr': 'Une base à solidifier', 'en': 'A base to build on', 'de': 'Eine Basis zum Festigen'},
    'act_moderate': {'fr': '3 à 4 fois', 'en': '3 to 4 times', 'de': '3 bis 4 Mal'},
    'act_moderate_sub': {'fr': 'Déjà une vraie routine', 'en': 'Already a real routine', 'de': 'Schon eine echte Routine'},
    'act_high': {
      'fr': '5 fois ou plus',
      'en': '5 times or more',
      'de': '5 Mal oder mehr',
    },
    'act_high_sub': {'fr': 'On optimise', 'en': 'We optimize', 'de': 'Wir optimieren'},
    'q_diet': {'fr': 'Des préférences dans l’assiette ?', 'en': 'Any preferences on your plate?', 'de': 'Vorlieben auf dem Teller?'},

    // ---------- Chapter 2 ----------
    'react_motivation': {
      'fr': 'Les chiffres, c’est fait. Maintenant le vrai sujet.',
      'en': 'Numbers done. Now the real subject.',
      'de': 'Zahlen erledigt. Jetzt das eigentliche Thema.'
    },
    'q_motivation': {
      'fr': 'Qu’est-ce qui t’a fait passer à l’action aujourd’hui ?',
      'en': 'What made you take action today?',
      'de': 'Was hat dich heute zum Handeln gebracht?'
    },
    'mot_event': {'fr': 'Un événement qui approche', 'en': 'An upcoming event', 'de': 'Ein Ereignis, das näher rückt'},
    'mot_health': {'fr': 'Ma santé', 'en': 'My health', 'de': 'Meine Gesundheit'},
    'mot_body': {'fr': 'Me sentir bien dans mon corps', 'en': 'Feeling good in my body', 'de': 'Mich in meinem Körper wohlfühlen'},
    'mot_energy': {'fr': 'Retrouver de l’énergie', 'en': 'Getting my energy back', 'de': 'Wieder Energie haben'},
    'mot_confidence': {'fr': 'Reprendre confiance', 'en': 'Regaining confidence', 'de': 'Selbstvertrauen zurückgewinnen'},
    'mot_placeholder': {
      'fr': 'Dis-le avec tes mots, si tu veux. On s’en souviendra.',
      'en': 'Say it in your own words, if you like. We’ll remember.',
      'de': 'Sag es in deinen Worten, wenn du willst. Wir merken es uns.'
    },
    'react_mot_event': {'fr': 'On va être prêts à temps.', 'en': 'We’ll be ready in time.', 'de': 'Wir werden rechtzeitig bereit sein.'},
    'react_mot_health': {'fr': 'La meilleure raison qui existe.', 'en': 'The best reason there is.', 'de': 'Der beste Grund, den es gibt.'},
    'react_mot_body': {'fr': 'On va y arriver, à ton rythme.', 'en': 'We’ll get there, at your pace.', 'de': 'Wir schaffen das, in deinem Tempo.'},
    'react_mot_energy': {'fr': 'Ça, c’est notre spécialité.', 'en': 'That’s our specialty.', 'de': 'Das ist unsere Spezialität.'},
    'react_mot_confidence': {
      'fr': 'Elle revient vite quand les résultats suivent.',
      'en': 'It comes back fast once results follow.',
      'de': 'Es kommt schnell zurück, wenn die Ergebnisse folgen.'
    },
    'q_obstacles': {
      'fr': 'Et avant, qu’est-ce qui t’a fait lâcher ?',
      'en': 'And before, what made you quit?',
      'de': 'Und früher, was hat dich aufgeben lassen?'
    },
    'obs_time': {'fr': 'Le manque de temps', 'en': 'Lack of time', 'de': 'Zu wenig Zeit'},
    'obs_time_a': {
      'fr': 'Séances à la durée que tu choisis, dès 20 minutes, chez toi ou en salle.',
      'en': 'Sessions as long as you choose, from 20 minutes, at home or at the gym.',
      'de': 'Einheiten so lang, wie du willst, ab 20 Minuten, zu Hause oder im Studio.',
    },
    'obs_motiv': {'fr': 'La motivation qui retombe', 'en': 'Motivation fading', 'de': 'Die Motivation lässt nach'},
    'obs_motiv_a': {
      'fr': 'Un bilan chaque semaine avec nous, plus les rappels du coach.',
      'en': 'A weekly check-in with us, plus coach reminders.',
      'de': 'Jede Woche eine Bilanz mit uns, plus Erinnerungen vom Coach.'
    },
    'obs_diet': {'fr': 'Les régimes trop stricts', 'en': 'Diets too strict', 'de': 'Zu strenge Diäten'},
    'obs_diet_a': {
      'fr': 'Aucun aliment interdit. Tu scannes ton assiette, on ajuste.',
      'en': 'No forbidden food. You scan your plate, we adjust.',
      'de': 'Kein verbotenes Essen. Du scannst deinen Teller, wir passen an.'
    },
    'obs_know': {'fr': 'Ne pas savoir quoi faire', 'en': 'Not knowing what to do', 'de': 'Nicht wissen, was zu tun ist'},
    'obs_know_a': {
      'fr': 'Programme guidé, chaque exercice expliqué.',
      'en': 'Guided program, every exercise explained.',
      'de': 'Angeleitetes Programm, jede Übung erklärt.'
    },
    'obs_slow': {'fr': 'Des résultats trop lents', 'en': 'Results too slow', 'de': 'Zu langsame Ergebnisse'},
    'obs_slow_a': {
      'fr': 'Poids suivi chaque semaine, projection en face.',
      'en': 'Weight tracked weekly, projection in front of you.',
      'de': 'Gewicht wöchentlich verfolgt, Prognose vor Augen.'
    },
    'obs_none': {'fr': 'Rien, je débute', 'en': 'Nothing, I’m starting out', 'de': 'Nichts, ich fange an'},
    'obs_none_a': {
      'fr': 'On part de zéro ensemble, au bon rythme.',
      'en': 'We start from scratch together, at the right pace.',
      'de': 'Wir starten gemeinsam bei null, im richtigen Tempo.'
    },
    'answers_title': {
      'fr': 'Ce qui t’a fait lâcher, on l’a prévu.',
      'en': 'What made you quit, we planned for it.',
      'de': 'Was dich aufgeben ließ, haben wir eingeplant.'
    },
    'duo_text': {
      'fr':
          'Pas une app de comptage : deux coachs. Le coach sport monte ton programme et suit chaque séance, le coach nutrition planifie ta semaine et lit ton assiette. Et ils se parlent. Tu vas le voir tout de suite, pour de vrai.',
      'en':
          'Not a counting app: two coaches. The training coach builds your program and tracks every session, the nutrition coach plans your week and reads your plate. And they talk to each other. You’ll see it right now, for real.',
      'de':
          'Keine Zähl-App: zwei Coaches. Der Sport-Coach baut dein Programm und verfolgt jede Einheit, der Ernährungs-Coach plant deine Woche und liest deinen Teller. Und sie sprechen miteinander. Du siehst es gleich, in echt.',
    },

    // ---------- Chapter 3 ----------
    'both_title': {
      'fr': 'Le même plan, chez des pros :',
      'en': 'The same plan, with real-life pros:',
      'de': 'Derselbe Plan, bei echten Profis:',
    },
    'both_caption': {'fr': 'sur {n} semaines · objectif {goal}', 'en': 'over {n} weeks · goal {goal}', 'de': 'über {n} Wochen · Ziel {goal}'},
    'both_goal_maintain': {'fr': 'maintien', 'en': 'maintain', 'de': 'halten'},
    'both_line_coach': {'fr': '{n} séances de coach · {p} €', 'en': '{n} coaching sessions · €{p}', 'de': '{n} Coaching-Einheiten · {p} €'},
    'both_line_nutri': {'fr': '{n} consultations nutrition · {p} €', 'en': '{n} nutrition consultations · €{p}', 'de': '{n} Ernährungsberatungen · {p} €'},
    'both_missing': {
      'fr': 'Coordination entre les deux : à toi de faire le lien',
      'en': 'Coordination between the two: up to you',
      'de': 'Abstimmung zwischen beiden: deine Aufgabe'
    },
    'both_bar_human': {'fr': 'Coach + nutri', 'en': 'Coach + nutrition', 'de': 'Coach + Ernährung'},
    'both_bar_ryze': {'fr': 'Ryze, un an', 'en': 'Ryze, one year', 'de': 'Ryze, ein Jahr'},
    'both_ratio': {'fr': '{x}× moins', 'en': '{x}× less', 'de': '{x}× weniger'},
    'both_keep': {'fr': 'restent dans ta poche', 'en': 'stay in your pocket', 'de': 'bleiben in deiner Tasche'},
    'both_keep_sub': {
      'fr': 'avec les deux coachs, toute l’année',
      'en': 'with both coaches, all year long',
      'de': 'mit beiden Coaches, das ganze Jahr'
    },
    'both_tick_talk': {
      'fr': 'Les deux se parlent : les jours de séance, ton assiette monte de 10 à 15 %',
      'en': 'They talk to each other: on training days your plate goes up 10 to 15 %',
      'de': 'Sie sprechen miteinander: an Trainingstagen gibt es 10 bis 15 % mehr auf dem Teller',
    },
    'both_tick_247': {
      'fr': 'Disponibles 24h/24, 7j/7, même le dimanche soir',
      'en': 'Available 24/7, even on a Sunday night',
      'de': 'Rund um die Uhr da, auch am Sonntagabend'
    },
    'both_tick_after': {
      'fr': 'Le suivi continue après l’objectif, sans rendez-vous',
      'en': 'Support continues after the goal, no appointments',
      'de': 'Die Begleitung geht nach dem Ziel weiter, ohne Termine'
    },
    'both_note': {
      'fr': 'Tarifs indicatifs, bas de fourchette : 40 à 70 € la séance, 50 à 80 € la consultation.',
      'en': 'Indicative low-end prices: €40 to 70 per session, €50 to 80 per consultation.',
      'de': 'Richtpreise, untere Spanne: 40 bis 70 € pro Einheit, 50 bis 80 € pro Beratung.'
    },
    // store price fallbacks, shown only while RevenueCat has not answered
    'price_default_annual': {'fr': '69,99 €', 'en': '€69.99', 'de': '69,99 €'},
    'price_default_monthly': {'fr': '9,99 €', 'en': '€9.99', 'de': '9,99 €'},
    'price_default_weekly': {'fr': '2,99 €', 'en': '€2.99', 'de': '2,99 €'},
    'price_default_monthly_equiv': {'fr': '5,83 €', 'en': '€5.83', 'de': '5,83 €'},
    'cta_see_app': {'fr': 'Voir l’app pour de vrai', 'en': 'See the app for real', 'de': 'Die App in echt sehen'},

    // ---------- Chapter 4 ----------
    'q_personality': {'fr': 'Comment tu veux qu’on te parle ?', 'en': 'How do you want us to talk to you?', 'de': 'Wie sollen wir mit dir reden?'},
    'pers_hint': {'fr': 'Choisis un ton, on te montre.', 'en': 'Pick a tone, we’ll show you.', 'de': 'Wähl einen Ton, wir zeigen es dir.'},
    'pers_friendly': {
      'fr': 'Yes {n} ! Séance à 18h, on y va ensemble. Tu vas kiffer.',
      'en': 'Yes {n}! Session at 6pm, we go together. You’ll love it.',
      'de': 'Yes {n}! Training um 18 Uhr, wir ziehen das zusammen durch. Wird dir gefallen.'
    },
    'pers_strict': {
      'fr': '18h, séance. Pas de négociation, {n}. On avance.',
      'en': '6pm, session. No negotiation, {n}. We move.',
      'de': '18 Uhr, Training. Keine Diskussion, {n}. Weiter geht’s.'
    },
    'pers_supportive': {
      'fr': 'Belle semaine, {n}. Ce soir on y va doucement, mais on y va.',
      'en': 'Good week, {n}. Tonight we go easy, but we go.',
      'de': 'Gute Woche, {n}. Heute Abend machen wir es ruhig, aber wir machen es.'
    },
    'pers_sassy': {
      'fr': 'Encore sur le canapé, {n} ? Le tapis de course s’ennuie sans toi.',
      'en': 'Still on the couch, {n}? The treadmill misses you.',
      'de': 'Noch auf dem Sofa, {n}? Das Laufband vermisst dich.'
    },
    'pers_direct': {'fr': 'Séance 18h. 45 min. Go.', 'en': 'Session 6pm. 45 min. Go.', 'de': 'Training 18 Uhr. 45 Min. Los.'},
    'cta_tone': {'fr': 'C’est ce ton-là', 'en': 'That’s the tone', 'de': 'Genau dieser Ton'},
    'q_bilan': {
      'fr': 'Chaque semaine, cinq minutes ensemble pour faire le point. Quel jour ?',
      'en': 'Every week, five minutes together to check in. Which day?',
      'de': 'Jede Woche fünf Minuten gemeinsam Bilanz ziehen. Welcher Tag?'
    },
    'pact_title': {'fr': 'Notre pacte.', 'en': 'Our pact.', 'de': 'Unser Pakt.'},
    'pact_h': {
      'fr': 'Nous, tes deux coachs Ryze,',
      'en': 'We, your two Ryze coaches,',
      'de': 'Wir, deine beiden Ryze-Coaches,',
    },
    'pact_p1': {
      'fr': 'on s’engage à te suivre, à te motiver, et à ne jamais te juger. Ni un écart, ni une semaine sans séance.',
      'en': 'commit to following you, motivating you, and never judging you. Not a slip, not a week without training.',
      'de': 'verpflichten uns, dich zu begleiten, zu motivieren und niemals zu verurteilen. Keinen Ausrutscher, keine Woche ohne Training.',
    },
    'pact_p2_pre': {'fr': 'En échange, tu nous donnes ', 'en': 'In exchange, you give us ', 'de': 'Im Gegenzug gibst du uns '},
    'pact_p2_bold': {'fr': 'cinq minutes chaque {day}', 'en': 'five minutes every {day}', 'de': 'fünf Minuten jeden {day}'},
    'pact_p2_post': {'fr': ' pour faire le point.', 'en': ' to check in.', 'de': ' für die Bilanz.'},
    'pact_signed_by': {'fr': 'Signé par', 'en': 'Signed by', 'de': 'Unterschrieben von'},
    'hold_label': {'fr': 'Maintiens pour signer', 'en': 'Hold to sign', 'de': 'Halten zum Unterschreiben'},
    'hold_done': {'fr': 'Pacte scellé', 'en': 'Pact sealed', 'de': 'Pakt besiegelt'},
    'stamp': {'fr': 'Signé', 'en': 'Signed', 'de': 'Signiert'},
    'cta_unlock': {'fr': 'Débloquer ma semaine', 'en': 'Unlock my week', 'de': 'Meine Woche freischalten'},

    // ---------- Paywall ----------
    'offer_title': {'fr': 'Ta semaine t’attend.', 'en': 'Your week is waiting.', 'de': 'Deine Woche wartet.'},
    'offer_veil': {'fr': 'Débloquée pendant l’essai', 'en': 'Unlocked during the trial', 'de': 'Während der Testphase freigeschaltet'},
    'offer_oneliner': {
      'fr': 'Tout Ryze, sport et nutrition : planificateur par chat, séances guidées, scan des repas, coach 24/7, bilan chaque {day}.',
      'en': 'All of Ryze, training and nutrition: chat planner, guided sessions, meal scan, 24/7 coach, check-in every {day}.',
      'de': 'Ganz Ryze, Sport und Ernährung: Chat-Planer, angeleitete Einheiten, Mahlzeiten-Scan, Coach rund um die Uhr, Bilanz jeden {day}.',
    },
    'tl_now': {'fr': 'Aujourd’hui', 'en': 'Today', 'de': 'Heute'},
    'tl_now_sub': {
      'fr': 'Ta semaine, le scan des repas, le programme et les deux coachs. Tout est ouvert.',
      'en': 'Your week, meal scan, program and both coaches. Everything is open.',
      'de': 'Deine Woche, Mahlzeiten-Scan, Programm und beide Coaches. Alles offen.'
    },
    'tl_2': {'fr': 'Dans 2 jours', 'en': 'In 2 days', 'de': 'In 2 Tagen'},
    'tl_2_sub': {
      'fr': '{store} te prévient avant la fin de l’essai. Annulation en un tap.',
      'en': '{store} reminds you before the trial ends. Cancel in one tap.',
      'de': '{store} erinnert dich vor Ende der Testphase. Kündigung mit einem Tipp.',
    },
    'tl_3': {'fr': 'Dans 3 jours', 'en': 'In 3 days', 'de': 'In 3 Tagen'},
    'tl_3_sub': {
      'fr': 'L’abonnement démarre, sauf si tu l’as annulé avant dans {store}.',
      'en': 'The subscription starts unless you cancelled in {store} first.',
      'de': 'Das Abo startet, außer du hast vorher in {store} gekündigt.',
    },
    'plan_annual': {'fr': 'Annuel', 'en': 'Annual', 'de': 'Jährlich'},
    'plan_annual_sub': {
      'fr': 'Le meilleur prix, et le seul avec l’essai gratuit',
      'en': 'Best price, and the only plan with a free trial',
      'de': 'Bester Preis, und der einzige Plan mit Gratis-Testphase',
    },
    'plan_annual_eq': {'fr': '{p} par mois', 'en': '{p} per month', 'de': '{p} pro Monat'},
    'plan_monthly': {'fr': 'Mensuel', 'en': 'Monthly', 'de': 'Monatlich'},
    'plan_monthly_sub': {'fr': 'Sans engagement', 'en': 'No commitment', 'de': 'Ohne Bindung'},
    'plan_monthly_unit': {'fr': 'par mois', 'en': 'per month', 'de': 'pro Monat'},
    'plan_weekly': {'fr': 'Hebdo', 'en': 'Weekly', 'de': 'Wöchentlich'},
    'plan_weekly_sub': {
      'fr': 'Semaine par semaine, facturé aujourd’hui',
      'en': 'Week by week, billed today',
      'de': 'Woche für Woche, heute abgerechnet',
    },
    'plan_weekly_unit': {'fr': 'par semaine', 'en': 'per week', 'de': 'pro Woche'},
    'badge_trial': {'fr': '3 jours gratuits', 'en': '3 days free', 'de': '3 Tage gratis'},
    'cta_trial': {'fr': 'Commencer mes 3 jours gratuits', 'en': 'Start my 3 free days', 'de': 'Meine 3 Gratistage starten'},
    'cta_monthly': {'fr': 'Continuer avec le mensuel', 'en': 'Continue with monthly', 'de': 'Weiter mit monatlich'},
    'cta_weekly': {'fr': 'Continuer avec l’hebdo', 'en': 'Continue with weekly', 'de': 'Weiter mit wöchentlich'},
    'foot_annual': {
      'fr': 'Gratuit pendant 3 jours, puis {p} par an. Annulable à tout moment.',
      'en': 'Free for 3 days, then {p} per year. Cancel anytime.',
      'de': '3 Tage gratis, dann {p} pro Jahr. Jederzeit kündbar.'
    },
    'foot_monthly': {'fr': '{p} par mois. Annulable à tout moment.', 'en': '{p} per month. Cancel anytime.', 'de': '{p} pro Monat. Jederzeit kündbar.'},
    'foot_weekly': {'fr': '{p} par semaine. Annulable à tout moment.', 'en': '{p} per week. Cancel anytime.', 'de': '{p} pro Woche. Jederzeit kündbar.'},
    'restore': {'fr': 'Restaurer un achat', 'en': 'Restore a purchase', 'de': 'Kauf wiederherstellen'},
    'restored_ok': {'fr': 'Achats restaurés.', 'en': 'Purchases restored.', 'de': 'Käufe wiederhergestellt.'},
    'restored_none': {'fr': 'Aucun achat à restaurer.', 'en': 'No purchase to restore.', 'de': 'Kein Kauf zum Wiederherstellen.'},
    'purchase_error': {
      'fr': 'L’achat n’a pas abouti. Réessaie.',
      'en': 'The purchase did not go through. Try again.',
      'de': 'Der Kauf ist nicht durchgegangen. Versuch es erneut.'
    },
    'store_unavailable': {
      'fr': 'Boutique indisponible pour le moment. Réessaie dans un instant.',
      'en': 'Store unavailable right now. Try again in a moment.',
      'de': 'Store gerade nicht verfügbar. Versuch es gleich noch einmal.'
    },
    'offer_veil_paid': {'fr': 'Débloquée dès l’abonnement', 'en': 'Unlocked as soon as you subscribe', 'de': 'Freigeschaltet, sobald du abonnierst'},
    'tl_paid_now_sub': {
      'fr': 'L’abonnement démarre aujourd’hui : {p}. Pas de période d’essai sur ce plan.',
      'en': 'Your subscription starts today: {p}. No trial on this plan.',
      'de': 'Dein Abo startet heute: {p}. Keine Testphase bei diesem Plan.'
    },
    'cta_annual_paid': {'fr': 'Continuer avec l’abonnement annuel', 'en': 'Continue with the annual plan', 'de': 'Weiter mit dem Jahresabo'},
    'foot_annual_paid': {
      'fr': '{p} par an, facturé aujourd’hui. Annulable à tout moment dans {store}.',
      'en': '{p} per year, billed today. Cancel anytime in {store}.',
      'de': '{p} pro Jahr, heute abgerechnet. Jederzeit in {store} kündbar.',
    },
    'legal_terms': {'fr': 'Conditions', 'en': 'Terms', 'de': 'AGB'},
    'legal_privacy': {'fr': 'Confidentialité', 'en': 'Privacy', 'de': 'Datenschutz'},
    'offer_goal': {
      'fr': '{goal} d’ici le {date}, avec les deux coachs. Bilan chaque {day}.',
      'en': '{goal} by {date}, with both coaches. Check-in every {day}.',
      'de': '{goal} bis {date}, mit beiden Coaches. Bilanz jeden {day}.',
    },
    'pact_goal': {
      'fr': 'Objectif : {target} le {date}.',
      'en': 'Goal: {target} by {date}.',
      'de': 'Ziel: {target} bis {date}.',
    },
    'pact_because': {
      'fr': 'Pour : « {why} »',
      'en': 'Because: “{why}”',
      'de': 'Dafür: „{why}“',
    },
    'hello_title_anon': {'fr': 'Salut.', 'en': 'Hi.', 'de': 'Hallo.'},
    'proj_adjust': {
      'fr': 'Une courbe ne tient pas toute seule. Chaque semaine, on fait le point ensemble et on ajuste le plan.',
      'en': 'A curve does not hold on its own. Every week we take stock together and adjust the plan.',
      'de': 'Eine Kurve hält nicht von allein. Jede Woche ziehen wir gemeinsam Bilanz und passen den Plan an.',
    },
    'stat_cap_kcal': {'fr': 'Ton cap', 'en': 'Your target', 'de': 'Dein Ziel'},
    'stat_cap_protein': {'fr': 'Protéines', 'en': 'Protein', 'de': 'Protein'},
    'insight_motivation': {'fr': 'Motivation principale', 'en': 'Main motivation', 'de': 'Hauptmotivation'},
    'insight_goal': {'fr': 'Objectif concret', 'en': 'Concrete goal', 'de': 'Konkretes Ziel'},
    'insight_blockers': {'fr': 'Blocages passés', 'en': 'Past blockers', 'de': 'Bisherige Hürden'},
    'insight_constraints': {'fr': 'Contraintes', 'en': 'Constraints', 'de': 'Einschränkungen'},
    'insight_tone': {'fr': 'Ton du coach choisi', 'en': 'Chosen coach tone', 'de': 'Gewählter Coach-Ton'},
    'retry': {'fr': 'Réessayer', 'en': 'Try again', 'de': 'Erneut versuchen'},
    'profile_save_failed_title': {'fr': 'Ton profil n’est pas encore enregistré', 'en': 'Your profile is not saved yet', 'de': 'Dein Profil ist noch nicht gespeichert'},
    'profile_save_failed': {
      'fr': 'Ton abonnement est bien actif. Il nous manque juste la connexion pour enregistrer tes réponses. Réessaie dans un instant.',
      'en': 'Your subscription is active. We just need a connection to save your answers. Try again in a moment.',
      'de': 'Dein Abo ist aktiv. Wir brauchen nur eine Verbindung, um deine Antworten zu speichern. Versuch es gleich noch einmal.'
    },
    'purchase_no_entitlement': {
      'fr': 'Le paiement est passé mais l’accès n’est pas encore actif. Utilise « Restaurer un achat » dans une minute, ou contacte-nous.',
      'en': 'The payment went through but access is not active yet. Use “Restore purchases” in a minute, or contact us.',
      'de': 'Die Zahlung ist durch, der Zugang aber noch nicht aktiv. Nutze in einer Minute „Käufe wiederherstellen“ oder kontaktiere uns.'
    },
    'demo_partial_save': {
      'fr': 'Données sauvegardées partiellement. Tu peux re-planifier depuis l’app.',
      'en': 'Data partially saved. You can re-plan from the app.',
      'de': 'Daten teilweise gespeichert. Du kannst in der App neu planen.',
    },
    'welcome_in': {'fr': 'Bienvenue dans Ryze', 'en': 'Welcome to Ryze', 'de': 'Willkommen bei Ryze'},
  };
}
