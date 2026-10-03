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
    'hello_title': {
      'fr': 'Bienvenue, {n}.',
      'en': 'Welcome, {n}.',
      'de': 'Willkommen, {n}.',
    },
    'hello_sub': {
      'fr': 'Ryze, c’est deux coachs IA : un pour le sport, un pour l’assiette. Ils planifient ta semaine avec toi et font le point chaque semaine.',
      'en': 'Ryze is two AI coaches: one for training, one for food. They plan your week with you and check in every week.',
      'de': 'Ryze sind zwei KI-Coaches: einer fürs Training, einer fürs Essen. Sie planen deine Woche mit dir und ziehen jede Woche Bilanz.',
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
    // the first screen, before any account: the door for people coming back
    'have_account': {'fr': 'Tu as déjà un compte ?', 'en': 'Already have an account?', 'de': 'Hast du schon ein Konto?'},
    'have_account_action': {'fr': 'Se connecter', 'en': 'Sign in', 'de': 'Anmelden'},
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
    'q_name': {
      'fr': 'Comment on t’appelle ?',
      'en': 'What should we call you?',
      'de': 'Wie sollen wir dich nennen?',
    },
    'name_placeholder': {
      'fr': 'Ton prénom',
      'en': 'Your first name',
      'de': 'Dein Vorname',
    },
    'name_hint': {
      'fr': 'C’est comme ça que les coachs t’appelleront, et c’est ce que tu signeras.',
      'en': 'That’s how the coaches will call you, and what you’ll sign with.',
      'de': 'So werden dich die Coaches nennen, und damit unterschreibst du.',
    },
    'react_name': {
      'fr': 'Enchanté, {n}.',
      'en': 'Nice to meet you, {n}.',
      'de': 'Freut uns, {n}.',
    },
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
    'both_line_coach': {'fr': '{n} séances de coach · {p}', 'en': '{n} coaching sessions · {p}', 'de': '{n} Coaching-Einheiten · {p}'},
    'both_line_nutri': {'fr': '{n} consultations nutrition · {p}', 'en': '{n} nutrition consultations · {p}', 'de': '{n} Ernährungsberatungen · {p}'},
    'both_missing': {
      'fr': 'Coordination entre les deux : à toi de faire le lien',
      'en': 'Coordination between the two: up to you',
      'de': 'Abstimmung zwischen beiden: deine Aufgabe'
    },
    'both_bar_human': {'fr': 'Coach + nutri', 'en': 'Coach + nutrition', 'de': 'Coach + Ernährung'},
    'both_bar_ryze': {'fr': 'Ryze, un an', 'en': 'Ryze, one year', 'de': 'Ryze, ein Jahr'},
    'both_ratio': {'fr': '{x}× moins', 'en': '{x}× less', 'de': '{x}× weniger'},
    'both_ratio_line': {
      'fr': 'Ryze coûte {x} fois moins cher, et c’est pour toute l’année.',
      'en': 'Ryze costs {x} times less, and that is for the whole year.',
      'de': 'Ryze kostet {x}-mal weniger, und das für das ganze Jahr.',
    },
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
      'fr': 'Tarifs indicatifs, bas de fourchette : {s1} à {s2} la séance, {c1} à {c2} la consultation.',
      'en': 'Indicative low-end prices: {s1} to {s2} per session, {c1} to {c2} per consultation.',
      'de': 'Richtpreise, untere Spanne: {s1} bis {s2} pro Einheit, {c1} bis {c2} pro Beratung.'
    },
    // store price fallbacks, shown only while RevenueCat has not answered
    'price_default_annual': {'fr': '69,99 €', 'en': '€69.99', 'de': '69,99 €'},
    'price_default_monthly': {'fr': '9,99 €', 'en': '€9.99', 'de': '9,99 €'},
    'price_default_weekly': {'fr': '2,99 €', 'en': '€2.99', 'de': '2,99 €'},
    'price_default_monthly_equiv': {'fr': '5,83 €', 'en': '€5.83', 'de': '5,83 €'},
    'cta_see_app': {'fr': 'Voir l’app pour de vrai', 'en': 'See the app for real', 'de': 'Die App in echt sehen'},

    // ---------- Chapter 4 ----------
    'q_personality': {'fr': 'Comment tu veux qu’on te parle ?', 'en': 'How do you want us to talk to you?', 'de': 'Wie sollen wir mit dir reden?'},
    // ---------- the tone: one excuse, theirs, and six ways to answer it ----------
    'tone_you': {
      'fr': 'Toi, ce soir',
      'en': 'You, tonight',
      'de': 'Du, heute Abend',
    },
    'tone_idle': {
      'fr': 'Choisis qui te répond.',
      'en': 'Pick who answers.',
      'de': 'Wähl, wer dir antwortet.',
    },
    'tone_where': {
      'fr': 'Tu l’entendras dans le chat, ton bilan de la semaine et l’avis du coach sur ta journée.',
      'en': 'You’ll hear it in the chat, your weekly check-in and the coach’s take on your day.',
      'de': 'Du hörst ihn im Chat, in deiner Wochenbilanz und im Kommentar des Coachs zu deinem Tag.',
    },
    // the excuse comes from the first reason ticked in chapter 2 (obs_*)
    'exc_time': {
      'fr': 'Pas le temps aujourd’hui.',
      'en': 'No time today.',
      'de': 'Heute keine Zeit.',
    },
    'exc_motiv': {
      'fr': 'Pas la force ce soir.',
      'en': 'No energy tonight.',
      'de': 'Heute Abend keine Kraft.',
    },
    'exc_diet': {
      'fr': 'J’ai craqué sur un burger.',
      'en': 'I caved for a burger.',
      'de': 'Ich bin beim Burger schwach geworden.',
    },
    'exc_know': {
      'fr': 'Je sais pas quoi faire, alors je fais rien.',
      'en': 'No idea what to do, so I’m doing nothing.',
      'de': 'Ich weiß nicht, was ich machen soll, also mach ich nichts.',
    },
    'exc_slow': {
      'fr': 'La balance bouge pas. À quoi bon ?',
      'en': 'The scale won’t move. What’s the point?',
      'de': 'Die Waage bewegt sich nicht. Wozu also?',
    },
    'exc_none': {
      'fr': 'Il pleut, flemme.',
      'en': 'It’s raining. Can’t be bothered.',
      'de': 'Es regnet, keine Lust.',
    },
    // written in advance: instant, and each tone makes its own move
    // (the buddy bargains, strict challenges, gentle allows, sassy teases,
    // no fluff orders). {n} is the first name, removed cleanly when unknown.
    'rep_time_friendly': {
      'fr': 'T’inquiète {n}. 15 minutes chrono, et je te rends ta soirée. Deal ?',
      'en': 'No stress {n}. 15 minutes flat, then your evening’s yours. Deal?',
      'de': 'Keine Sorge, {n}. 15 Minuten, dann gehört der Abend dir. Deal?',
    },
    'rep_time_strict': {
      'fr': 'Pas le temps, ou pas la priorité ? 20 minutes, {n}. Trouve-les.',
      'en': 'No time, or not a priority? 20 minutes, {n}. Find them.',
      'de': 'Keine Zeit oder keine Priorität? 20 Minuten, {n}. Finde sie.',
    },
    'rep_time_supportive': {
      'fr': 'Les journées pleines, ça arrive, {n}. Dix minutes ce soir, c’est déjà une victoire.',
      'en': 'Full days happen, {n}. Ten minutes tonight is already a win.',
      'de': 'Volle Tage passieren, {n}. Zehn Minuten heute Abend sind schon ein Sieg.',
    },
    'rep_time_sassy': {
      'fr': 'Pas le temps ? Ton téléphone, lui, en trouve. 😏',
      'en': 'No time? Your phone seems to find plenty. 😏',
      'de': 'Keine Zeit? Dein Handy findet jede Menge. 😏',
    },
    'rep_time_direct': {
      'fr': '15 min. Ce soir. Je te donne la séance.',
      'en': '15 min. Tonight. I’ll give you the session.',
      'de': '15 Min. Heute Abend. Ich geb dir die Einheit.',
    },
    'rep_motiv_friendly': {
      'fr': 'Je connais, {n}. 10 minutes ensemble, musique à fond, puis canapé. Deal ?',
      'en': 'Been there, {n}. 10 minutes together, music up, then couch. Deal?',
      'de': 'Kenn ich, {n}. 10 Minuten zusammen, Musik laut, dann Sofa. Deal?',
    },
    'rep_motiv_strict': {
      'fr': 'Pas la force, ou pas l’envie ? 20 minutes, {n}. Maintenant.',
      'en': 'No energy, or no will? 20 minutes, {n}. Now.',
      'de': 'Keine Kraft oder keine Lust? 20 Minuten, {n}. Jetzt.',
    },
    'rep_motiv_supportive': {
      'fr': 'Alors ce soir, on se repose, {n}. Une soirée calme ne défait rien.',
      'en': 'Then tonight we rest, {n}. One quiet evening undoes nothing.',
      'de': 'Dann ruhen wir uns heute aus, {n}. Ein ruhiger Abend macht nichts kaputt.',
    },
    'rep_motiv_sassy': {
      'fr': 'Pas la force de bouger, {n}, mais celle de scroller ? 😏',
      'en': 'No energy to move, {n}, but plenty to scroll? 😏',
      'de': 'Keine Kraft zum Bewegen, {n}, aber zum Scrollen schon? 😏',
    },
    'rep_motiv_direct': {
      'fr': '15 min de mobilité. Puis au lit.',
      'en': '15 min mobility. Then bed.',
      'de': '15 Min. Mobility. Dann ins Bett.',
    },
    'rep_diet_friendly': {
      'fr': 'Un burger, c’est pas un drame, {n}. Tu l’as kiffé au moins ?',
      'en': 'A burger’s no big deal, {n}. Did you at least enjoy it?',
      'de': 'Ein Burger ist kein Drama, {n}. Hat er wenigstens geschmeckt?',
    },
    'rep_diet_strict': {
      'fr': 'Un repas ne décide rien, {n}. Le suivant, si. Fais-le compter.',
      'en': 'One meal decides nothing, {n}. The next one does. Make it count.',
      'de': 'Eine Mahlzeit entscheidet nichts, {n}. Die nächste schon. Lass sie zählen.',
    },
    'rep_diet_supportive': {
      'fr': 'Tu as le droit de te faire plaisir, {n}. Rien n’est perdu.',
      'en': 'You’re allowed to enjoy a meal, {n}. Nothing is lost.',
      'de': 'Du darfst genießen, {n}. Nichts ist verloren.',
    },
    'rep_diet_sassy': {
      'fr': 'Et tu ne m’as même pas gardé une frite, {n} ? 😏',
      'en': 'And you didn’t even save me a fry, {n}? 😏',
      'de': 'Und mir hast du nicht mal eine Pommes aufgehoben, {n}? 😏',
    },
    'rep_diet_direct': {
      'fr': 'Noté. Prochain repas : légumes et protéines.',
      'en': 'Noted. Next meal: veggies and protein.',
      'de': 'Notiert. Nächste Mahlzeit: Gemüse und Protein.',
    },
    'rep_know_friendly': {
      'fr': 'C’est mon job, ça ! Je te prépare un truc simple, tu n’as qu’à suivre.',
      'en': 'That’s my job! I’ll set up something simple, you just follow.',
      'de': 'Das ist mein Job! Ich bau dir was Einfaches, du musst nur mitmachen.',
    },
    'rep_know_strict': {
      'fr': 'Ne rien faire, c’est aussi un choix, {n}. Moi je choisis : 3 exercices, ce soir.',
      'en': 'Doing nothing is a choice too, {n}. I’m choosing: 3 exercises, tonight.',
      'de': 'Nichts tun ist auch eine Entscheidung, {n}. Ich entscheide: 3 Übungen, heute Abend.',
    },
    'rep_know_supportive': {
      'fr': 'C’est normal de ne pas savoir par où commencer, {n}. On y va pas à pas.',
      'en': 'It’s normal not to know where to start, {n}. We go step by step.',
      'de': 'Es ist normal, nicht zu wissen, wo man anfängt, {n}. Wir gehen Schritt für Schritt.',
    },
    'rep_know_sassy': {
      'fr': 'Donc ton plan, c’est le canapé ? Audacieux, {n}. 😏',
      'en': 'So your plan is the couch? Bold, {n}. 😏',
      'de': 'Dein Plan ist also das Sofa? Mutig, {n}. 😏',
    },
    'rep_know_direct': {
      'fr': '3 exercices. 20 min. Je te les donne.',
      'en': '3 exercises. 20 min. I’ll give them to you.',
      'de': '3 Übungen. 20 Min. Ich geb sie dir.',
    },
    'rep_slow_friendly': {
      'fr': 'Je sais, c’est frustrant. Mais t’es là, {n}, et ça compte énormément.',
      'en': 'I know, it’s frustrating. But you’re here, {n}, and that counts for a lot.',
      'de': 'Ich weiß, das nervt. Aber du bist da, {n}, und das zählt viel.',
    },
    'rep_slow_strict': {
      'fr': 'La balance ment à court terme. Tes habitudes, non. On continue, {n}.',
      'en': 'The scale lies short term. Your habits don’t. Keep going, {n}.',
      'de': 'Die Waage lügt kurzfristig. Deine Gewohnheiten nicht. Weiter, {n}.',
    },
    'rep_slow_supportive': {
      'fr': 'Le corps change avant la balance, {n}. Laisse-lui le temps.',
      'en': 'Your body changes before the scale does, {n}. Give it time.',
      'de': 'Der Körper verändert sich vor der Waage, {n}. Gib ihm Zeit.',
    },
    'rep_slow_sassy': {
      'fr': 'Tu parles à la balance maintenant, {n} ? 😏 Moi je regarde ta semaine.',
      'en': 'Talking to the scale now, {n}? 😏 I’m looking at your week.',
      'de': 'Redest du jetzt mit der Waage, {n}? 😏 Ich schau auf deine Woche.',
    },
    'rep_slow_direct': {
      'fr': 'Une pesée ne dit rien. On regarde la tendance sur 4 semaines.',
      'en': 'One weigh-in means nothing. We watch the 4-week trend.',
      'de': 'Ein Wiegen sagt nichts. Wir schauen auf den 4-Wochen-Trend.',
    },
    'rep_none_friendly': {
      'fr': 'La pluie, l’ennemi juré ! Séance au salon, on y va ensemble ?',
      'en': 'Rain, our sworn enemy! Living room session, together?',
      'de': 'Regen, unser Erzfeind! Training im Wohnzimmer, zusammen?',
    },
    'rep_none_strict': {
      'fr': 'La pluie ne rentre pas dans ton salon, {n}. On y va.',
      'en': 'Rain doesn’t get into your living room, {n}. Let’s go.',
      'de': 'Der Regen kommt nicht in dein Wohnzimmer, {n}. Los.',
    },
    'rep_none_supportive': {
      'fr': 'Ce temps n’aide pas, je sais. Quelques étirements au chaud, ça compte aussi.',
      'en': 'This weather doesn’t help, I know. A few stretches somewhere warm count too.',
      'de': 'Das Wetter hilft nicht, ich weiß. Ein paar Dehnübungen im Warmen zählen auch.',
    },
    'rep_none_sassy': {
      'fr': 'Tu ne vas pas fondre, promis, {n}. 😏',
      'en': 'You won’t melt, I promise, {n}. 😏',
      'de': 'Du schmilzt schon nicht, versprochen, {n}. 😏',
    },
    'rep_none_direct': {
      'fr': 'Séance maison. 20 min. Go.',
      'en': 'Home session. 20 min. Go.',
      'de': 'Training zu Hause. 20 Min. Los.',
    },
    // "your way": the only keyboard of the flow, in a sheet
    'tone_sheet_title': {
      'fr': 'Dis-lui comment te parler.',
      'en': 'Tell your coach how to talk to you.',
      'de': 'Sag deinem Coach, wie er mit dir reden soll.',
    },
    'tone_sheet_sub': {
      'fr': 'Il s’y tiendra, à chaque message.',
      'en': 'It’ll stick to it, every message.',
      'de': 'Er hält sich daran, in jeder Nachricht.',
    },
    'tone_sheet_hint': {
      'fr': 'Ex. : comme une grande sœur, cash et drôle.',
      'en': 'E.g. like a big sister, blunt and funny.',
      'de': 'Z. B.: wie eine große Schwester, direkt und witzig.',
    },
    'tone_sheet_try': {
      'fr': 'Essayer ce ton',
      'en': 'Try this tone',
      'de': 'Diesen Ton testen',
    },
    // examples a preset tone cannot do
    'tone_ex_sister_label': {
      'fr': 'Grande sœur',
      'en': 'Big sister',
      'de': 'Große Schwester',
    },
    'tone_ex_sister': {
      'fr': 'Parle-moi comme une grande sœur : cash, drôle, toujours de mon côté.',
      'en': 'Talk to me like a big sister: blunt, funny, always on my side.',
      'de': 'Sprich mit mir wie eine große Schwester: direkt, witzig, immer auf meiner Seite.',
    },
    'tone_ex_caster_label': {
      'fr': 'Commentateur',
      'en': 'Commentator',
      'de': 'Kommentator',
    },
    'tone_ex_caster': {
      'fr': 'Commente mes journées comme un match, avec du suspense.',
      'en': 'Call my days like a live match, full of suspense.',
      'de': 'Kommentiere meine Tage wie ein Live-Spiel, voller Spannung.',
    },
    'tone_ex_butler_label': {
      'fr': 'Majordome',
      'en': 'Butler',
      'de': 'Butler',
    },
    'tone_ex_butler': {
      'fr': 'Parle-moi comme un majordome anglais, poli et pince-sans-rire.',
      'en': 'Talk to me like a British butler, polite and bone-dry.',
      'de': 'Sprich mit mir wie ein englischer Butler, höflich und trocken.',
    },
    // never an error message four screens before the paywall
    'tone_custom_fallback': {
      'fr': 'Noté. Je te parlerai comme ça, à chaque message.',
      'en': 'Noted. I’ll talk to you like this, every message.',
      'de': 'Notiert. So rede ich mit dir, in jeder Nachricht.',
    },
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
    // Winter Arc (WINTER_ARC.md) : montré jusqu’au 21 décembre, dernier jour
    // où une série peut commencer et gagner.
    'arc_offer': {
      'fr': 'Winter Arc : 90 jours d’affilée et ton année suivante est offerte.',
      'en': 'Winter Arc: go 90 days in a row and your next year is free.',
      'de': 'Winter Arc: Schaff 90 Tage am Stück und dein nächstes Jahr ist geschenkt.',
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
    // ---------- Accès offert ----------
    // Un compte à qui on a ouvert l'accès (entitlement promotionnel RevenueCat)
    // arrivait quand même sur le paywall et devait taper « Restaurer un achat »
    // pour un achat qu'il n'a jamais fait.
    'granted_title': {'fr': 'Ton accès est ouvert.', 'en': 'Your access is open.', 'de': 'Dein Zugang ist offen.'},
    'granted_sub': {
      'fr': 'Cet abonnement est déjà actif sur ton compte. Rien à payer, rien à restaurer.',
      'en': 'This subscription is already active on your account. Nothing to pay, nothing to restore.',
      'de': 'Dieses Abo ist auf deinem Konto bereits aktiv. Nichts zu zahlen, nichts wiederherzustellen.',
    },
    'granted_cta': {'fr': 'Entrer dans Ryze', 'en': 'Enter Ryze', 'de': 'Zu Ryze'},

    // ---------- La sortie du paywall ----------
    'exit_close': {'fr': 'Fermer', 'en': 'Close', 'de': 'Schließen'},
    'exit_title': {'fr': 'Avant de partir.', 'en': 'Before you go.', 'de': 'Bevor du gehst.'},
    'exit_sub': {
      'fr': 'Ton compte existe et ta semaine est gardée. Dis-moi juste ce qui bloque : ça prend un tap.',
      'en': 'Your account exists and your week is saved. Just tell me what’s in the way: one tap.',
      'de': 'Dein Konto existiert und deine Woche ist gespeichert. Sag mir nur, was dich stoppt: ein Tipp.',
    },
    'exit_r_price': {'fr': 'C’est trop cher', 'en': 'Too expensive', 'de': 'Zu teuer'},
    'exit_r_price_sub': {'fr': 'Le prix ne passe pas maintenant', 'en': 'The price doesn’t work right now', 'de': 'Der Preis passt gerade nicht'},
    'exit_r_try': {'fr': 'Je veux essayer avant', 'en': 'I want to try first', 'de': 'Ich will erst testen'},
    'exit_r_try_sub': {'fr': 'Voir ce que ça donne pour moi', 'en': 'See what it does for me', 'de': 'Sehen, was es mir bringt'},
    'exit_r_now': {'fr': 'Pas maintenant', 'en': 'Not right now', 'de': 'Gerade nicht'},
    'exit_r_now_sub': {'fr': 'J’y reviendrai plus tard', 'en': 'I’ll come back to it', 'de': 'Ich komme später darauf zurück'},
    'exit_a_price': {
      'fr': 'Le plan le plus court, c’est l’hebdo : {p}, facturé à la semaine, et il s’arrête quand tu veux dans {store}.',
      'en': 'The shortest plan is weekly: {p}, billed by the week, and it stops whenever you want in {store}.',
      'de': 'Der kürzeste Plan ist wöchentlich: {p}, wochenweise abgerechnet, jederzeit in {store} kündbar.',
    },
    'exit_cta_price': {'fr': 'Voir l’hebdo', 'en': 'See the weekly plan', 'de': 'Wöchentlich ansehen'},
    'exit_a_try': {
      'fr': 'Les 3 jours d’essai ne prélèvent rien. {store} te prévient avant la fin, et annuler prend un tap.',
      'en': 'The 3-day trial charges nothing. {store} warns you before it ends, and cancelling takes one tap.',
      'de': 'Die 3 Testtage kosten nichts. {store} warnt dich vor Ablauf, und Kündigen dauert einen Tipp.',
    },
    'exit_cta_try': {'fr': 'Commencer l’essai', 'en': 'Start the trial', 'de': 'Test starten'},
    'exit_a_try_used': {
      'fr': 'L’essai gratuit a déjà été utilisé avec ce compte {store} : il ne peut pas repartir. Le plus court sans engagement, c’est l’hebdo à {p}.',
      'en': 'The free trial was already used with this {store} account, so it can’t start again. The shortest plan is weekly at {p}.',
      'de': 'Die Gratis-Testphase wurde mit diesem {store}-Konto schon genutzt und kann nicht neu starten. Am kürzesten ist wöchentlich für {p}.',
    },
    'exit_a_now': {
      'fr': 'On ne touche à rien : ton compte, tes réponses et ta semaine restent là. Je te fais signe demain, une fois.',
      'en': 'Nothing moves: your account, your answers and your week stay put. I’ll ping you tomorrow, once.',
      'de': 'Nichts geht verloren: Konto, Antworten und Woche bleiben. Ich melde mich morgen, einmal.',
    },
    'exit_cta_now': {'fr': 'Me le rappeler demain', 'en': 'Remind me tomorrow', 'de': 'Morgen erinnern'},
    'exit_note': {'fr': 'Aucune de ces réponses ne t’engage.', 'en': 'None of these answers commits you to anything.', 'de': 'Keine dieser Antworten verpflichtet dich.'},
    'exit_reminder_ok': {'fr': 'Rappel posé. À demain.', 'en': 'Reminder set. See you tomorrow.', 'de': 'Erinnerung gesetzt. Bis morgen.'},
    'exit_reminder_off': {
      'fr': 'Les notifications sont coupées pour Ryze : le rappel ne peut pas partir. Tu peux les rouvrir dans les réglages du téléphone.',
      'en': 'Notifications are off for Ryze, so the reminder can’t be set. You can turn them back on in your phone settings.',
      'de': 'Mitteilungen sind für Ryze aus, die Erinnerung kann nicht gesetzt werden. Du kannst sie in den Einstellungen wieder erlauben.',
    },
    'wb1_title': {'fr': 'Ta semaine est gardée', 'en': 'Your week is still there', 'de': 'Deine Woche ist noch da'},
    'wb1_body': {
      'fr': 'Le plan que tu as construit avec les coachs t’attend. Reprends quand tu veux.',
      'en': 'The plan you built with the coaches is waiting. Pick it up whenever you want.',
      'de': 'Der Plan, den du mit den Coaches gebaut hast, wartet. Mach weiter, wann du willst.',
    },
    'wb3_title': {'fr': 'On garde ta place', 'en': 'Your place is kept', 'de': 'Dein Platz bleibt frei'},
    'wb3_body': {
      'fr': 'Tes deux coachs, ta semaine et ton bilan sont prêts à démarrer.',
      'en': 'Both coaches, your week and your check-in are ready to start.',
      'de': 'Beide Coaches, deine Woche und deine Bilanz sind startbereit.',
    },
    'winback_note': {'fr': 'Ton offre de retour', 'en': 'Your come-back offer', 'de': 'Dein Rückkehr-Angebot'},

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
    'hello_title_anon': {
      'fr': 'Bienvenue.',
      'en': 'Welcome.',
      'de': 'Willkommen.',
    },
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
