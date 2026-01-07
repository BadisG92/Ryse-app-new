const fs = require('fs');
const path = 'lib/services/translations.dart';
let content = fs.readFileSync(path, 'utf8');

// German translations dictionary
const deTranslations = {
  'add_to_existing_meal': 'Zu bestehender Mahlzeit hinzufügen',
  'choose_from_todays_meals': 'Aus heutigen Mahlzeiten wählen',
  'choose_meal_type_to_create': 'Wählen Sie den zu erstellenden Mahlzeittyp',
  'scan_barcode': 'Barcode scannen',
  'ai_tip_hydration': '💡 Tipp: Trinken Sie vor jeder Mahlzeit ein Glas Wasser für bessere Verdauung und Sättigung.',
  'ai_tip_timing': '⏰ Perfektes Timing: Nehmen Sie Ihre Proteine innerhalb von 30 Minuten nach dem Training zu sich.',
  'ai_tip_balance': '⚖️ Balance: Ihr Protein/Kohlenhydrat-Verhältnis ist optimal für Ihr Ziel.',
  'add_water': 'Wasser hinzufügen',
  'water_added_success': '{amount} ml Wasser hinzugefügt! 💧',
  'error_adding_water': 'Fehler beim Hinzufügen von Wasser',
  'must_be_logged_in_water': 'Sie müssen angemeldet sein, um die Flüssigkeitszufuhr zu erfassen',
  'type_to_search': 'Tippen Sie, um nach Lebensmitteln zu suchen\noder erstellen Sie Ihr eigenes Lebensmittel',
  'start_adding_foods': 'Fügen Sie Lebensmittel zu Ihren Mahlzeiten hinzu\num Ihre Vorschläge hier zu sehen',
  'enter_food_name': 'Bitte geben Sie einen Namen für das Lebensmittel ein.',
  'error_creating_food': 'Fehler beim Erstellen des Lebensmittels',
  'food_name': 'Lebensmittelname',
  'per_100g': 'pro 100g',
  'per_100ml': 'pro 100ml',
  'per_serving': 'pro Portion',
  'per_spoon': 'pro Löffel',
  'per_unit': 'pro Stück',
  'calculated_calories': 'Berechnete Kalorien: {calories} kcal',
  'serving': 'Portion',
  'spoon': 'Löffel',
  'unit': 'Stück',
  'add_food_title': '"{foodName}" hinzufügen',
  'where_add_food': 'Wo möchten Sie dieses Lebensmittel hinzufügen?',
  'choose_from_daily_meals': 'Aus Ihren Tagesmahlzeiten wählen',
  'meal_type_options': 'Frühstück, Mittagessen, Abendessen oder Snack',
  'food_item_count': '{count} Lebensmittel',
  'error_user_not_connected': 'Fehler: Benutzer nicht angemeldet',
  'recipe_added_success': 'Rezept "{recipeName}" erfolgreich hinzugefügt!',
  'recipe_added_to_new_meal': 'Rezept "{recipeName}" zu neuem {mealType} hinzugefügt!',
  'food_added_to_meal': '{foodName} zu {mealName} hinzugefügt',
  'food_added_success': '{foodName} erfolgreich zur Mahlzeit hinzugefügt!',
  'food_added_to_new_meal': '{foodName} zu neuem {mealType} hinzugefügt',
  'error_creating_meal': 'Fehler beim Erstellen der Mahlzeit',
  'error_generating_meal_id': 'Fehler beim Generieren der Mahlzeit-ID',
  'error_adding_recipe': 'Fehler beim Hinzufügen des Rezepts',
  'error_adding_food': 'Fehler beim Hinzufügen des Lebensmittels: {error}',
  'back': 'Zurück',
  'continue': 'Weiter',
  'complete_profile_title': 'Vervollständigen Sie Ihr Profil',
  'complete_profile_subtitle': 'Wir benötigen Ihren Namen, um Ihr Erlebnis zu personalisieren',
  'complete_profile_privacy': 'Ihre Daten sind sicher und werden niemals weitergegeben',
  'create_new_meal_title': 'Neue Mahlzeit erstellen',
  'ai_scanner_title': 'Mit Coach Ryze scannen',
  'coach_detected_dish_name': 'Von Coach Ryze erkannter Gerichtname',
  'coach_detected_dish': 'Von Coach Ryze erkanntes Gericht',
  'coach_analysis': 'Coach Ryze Analyse',
  'scan_lunch_with_coach': 'Es ist Zeit! Scanne dein Mittagessen mit Coach Ryze.',
  'unlimited_photos_coach': 'Unbegrenzte Fotos + Persönlicher Coach Ryze',
  'breakfast_description': 'Morgenmahlzeit',
  'lunch_description': 'Mittagsmahlzeit',
  'dinner_description': 'Abendmahlzeit',
  'snack_description': 'Snack zwischen den Mahlzeiten',
  'custom': 'Benutzerdefiniert',
  'scanned': 'Gescannt',
  'modified': 'Geändert',
  'quantity': 'Menge',
  'confirm': 'Bestätigen',
  'filters': 'Filter',
  'clear_all': 'Alles löschen',
  'apply_filters': 'Anwenden',
  'recommended_recipes': 'Empfohlene Rezepte',
  'results': 'Ergebnisse',
  'all_recipes': 'Alle Rezepte',
  'search_recipe_placeholder': 'Nach einem Rezept suchen...',
  'preparation_steps': 'Zubereitungsschritte',
  'nutrition_tab': 'Ernährung',
  'home_tab': 'Startseite',
  'sport_tab': 'Sport',
  'sport': 'Sport',
  'progress_tab': 'Fortschritt',
  'objectives': 'Ziele',
  'must_be_connected_add_food': 'Sie müssen angemeldet sein, um Lebensmittel hinzuzufügen',
  'add_food_to_meal': '"%s" zu einer Mahlzeit hinzufügen',
  'no_meals_recorded': 'Keine Mahlzeiten erfasst',
  'add_first_meal_message': 'Fügen Sie Ihre erste Mahlzeit hinzu, um Ihre Ernährung zu verfolgen.',
  'add_food_button': 'Lebensmittel hinzufügen',
  'yesterday': 'Gestern',
  'tomorrow': 'Morgen',
  'calorie_summary': 'Kalorienbilanz',
  'nutrition_calendar': 'Ernährungskalender',
  'successful_days': 'Erfolgreiche Tage',
  'average_calories': 'Durchschn. Kalorien',
  'daily_calorie_goal_reached': 'Erreichung des täglichen Kalorienziels',
  'mon_short': 'Mo',
  'tue_short': 'Di',
  'wed_short': 'Mi',
  'thu_short': 'Do',
  'fri_short': 'Fr',
  'sat_short': 'Sa',
  'sun_short': 'So',
  'sport_dashboard_title': 'Übersicht',
  'sport_objectives_text': 'Ziele',
  'sport_days_text': 'Tage',
  'sport_burned': 'Verbrannt',
  'sport_average_per_day': 'Durchschnitt / Tag',
  'sport_milestones_reached': 'Erreichte Meilensteine',
  'sport_progress': 'Fortschritt',
  'sport_sessions_this_week': 'Einheiten diese Woche',
  'sport_consecutive_weeks': 'Aufeinanderfolgende Wochen',
  'sport_total_time_week': 'Gesamtzeit diese Woche',
  'sport_recent_sessions': 'Letzte Trainingseinheiten',
  'sport_todays_activities': 'Heutige Aktivitäten',
  'sport_start_activity': 'Aktivität starten',
  'sport_no_activity_today': 'Heute keine Aktivität',
  'sport_rest_day': 'Ruhetag',
  'sport_kcal_to_next_milestone': 'Noch {kcal} kcal bis zum nächsten Meilenstein',
  'sport_milestone_reached': 'Meilenstein erreicht! Herzlichen Glückwunsch 🎉',
  'sport_muscle_training': 'Krafttraining',
  'sport_cardio': 'Cardio',
  'sport_choose_activity': 'Wählen Sie Ihre Cardio-Aktivität',
  'sport_choose_objective': 'Wählen Sie Ihr Ziel',
  'sport_free_session': 'Freie Einheit',
  'sport_no_specific_goal': 'Kein bestimmtes Ziel',
  'sport_time_objective': 'Zeitziel',
  'sport_30_minutes': '30 Minuten',
  'sport_distance_objective': 'Entfernungsziel',
  'sport_5_km': '5 km',
  'sport_choose_format': 'Wählen Sie Ihr Format',
  'sport_hiit': 'HIIT',
  'sport_choose_hiit_workout': 'Wählen Sie Ihr HIIT-Training',
  'sport_track_session': 'Meine Einheit aufzeichnen',
  'sport_declare_session': 'Meine Einheit eintragen',
  'sport_beginner_hiit': 'HIIT für Anfänger',
  'sport_intense_hiit': 'Intensives HIIT',
  'sport_tabata': 'Tabata',
  'sport_15min_hiit_desc': '15 Min - 30s Arbeit / 30s Pause',
  'sport_20min_hiit_desc': '20 Min - 45s Arbeit / 15s Pause',
  'sport_4min_tabata_desc': '4 Min - 20s Arbeit / 10s Pause',
  'sport_loading_data_error': 'Fehler beim Laden der Daten',
  'sport_calendar_title': 'Sportkalender',
  'sport_calendar_subtitle': 'Verfolgen Sie Ihre Sportaktivitäten',
  'sport_active_days': 'Aktive Tage',
  'sport_legend': 'Legende',
  'sport_rest': 'Ruhe',
  'month_january': 'Januar',
  'month_february': 'Februar',
  'month_march': 'März',
  'month_april': 'April',
  'month_may': 'Mai',
  'month_june': 'Juni',
  'month_july': 'Juli',
  'month_august': 'August',
  'month_september': 'September',
  'month_october': 'Oktober',
  'month_november': 'November',
  'month_december': 'Dezember',
  // Muscle groups
  'muscle_group_back': 'Rücken',
  'muscle_group_shoulders': 'Schultern',
  'muscle_group_biceps': 'Bizeps',
  'muscle_group_triceps': 'Trizeps',
  'muscle_group_legs': 'Beine',
  'muscle_group_glutes': 'Gesäß',
  'muscle_group_abs': 'Bauchmuskeln',
  'muscle_group_calves': 'Waden',
  'muscle_group_forearms': 'Unterarme',
  'muscle_group_custom': 'Benutzerdefiniert',
  // Onboarding
  'onboarding_welcome': 'Willkommen',
  'onboarding_personal_profile': 'Persönliches Profil',
  'onboarding_choose_gender': 'Wähle dein Geschlecht',
  'onboarding_calibrate_plan': 'Dies wird verwendet, um deinen personalisierten Plan zu kalibrieren',
  'onboarding_when_born': 'Wann wurdest du geboren',
  'onboarding_height_weight': 'Was ist deine Größe & dein Gewicht',
  'onboarding_adjust_energy': 'Um deinen Energiebedarf anzupassen',
  'onboarding_height_label': 'Größe',
  'onboarding_weight_label': 'Gewicht',
  'onboarding_activity_level': 'Was ist dein Aktivitätsniveau?',
  'onboarding_goal': 'Was ist dein Ziel?',
  'onboarding_obstacles': 'Was hindert dich daran, eine Routine beizubehalten?',
  'onboarding_dietary_restrictions': 'Hast du Ernährungseinschränkungen?',
  'onboarding_results': 'Ergebnisse',
  'onboarding_low_activity': 'Wenig aktiv',
  'onboarding_moderate_activity': 'Mäßig aktiv',
  'onboarding_high_activity': 'Sehr aktiv',
  'onboarding_low_activity_desc': '0-2 Tage pro Woche',
  'onboarding_moderate_activity_desc': '3-5 Tage pro Woche',
  'onboarding_high_activity_desc': '6+ Tage pro Woche',
  'onboarding_lose_weight': 'Gewicht verlieren',
  'onboarding_maintain_weight': 'Gewicht halten',
  'onboarding_gain_weight': 'Gewicht zunehmen',
  'onboarding_lose_weight_desc': 'Kontrolliertes Kaloriendefizit',
  'onboarding_maintain_weight_desc': 'Energiegleichgewicht',
  'onboarding_gain_weight_desc': 'Gesunder Kalorienüberschuss',
  'onboarding_lack_of_time': 'Zeitmangel',
  'onboarding_lack_of_motivation': 'Motivationsmangel',
  'onboarding_fatigue': 'Müdigkeit',
  'onboarding_lack_of_knowledge': 'Wissensmangel',
  'onboarding_other_priorities': 'Andere Prioritäten',
  'onboarding_next': 'Weiter',
  'onboarding_previous': 'Zurück',
  'onboarding_profile_ready': 'Dein Profil ist bereit!',
  'onboarding_personalize_experience': 'Dies ermöglicht uns, dein Erlebnis zu personalisieren',
  'onboarding_welcome_title': 'Willkommen bei Ryze',
  'onboarding_welcome_tagline': 'Dein Wellness-Partner',
  'onboarding_welcome_subtitle': 'Erstelle deinen personalisierten Ernährungsplan in 5 Minuten',
  'onboarding_stats_success': 'haben ihre Ziele erreicht',
  'onboarding_stats_users': 'Nutzer',
  'onboarding_stats_rating': 'App-Bewertung',
  // AI Analysis
  'analyze_with_ai': 'Mit Coach Ryze analysieren',
  'ai_analysis': 'Coach Ryze',
  'analysis_in_progress': 'Analyse läuft...',
  'refresh_analysis': 'Analyse aktualisieren',
  'new_analysis_available': 'Neu verfügbar',
  'minimum_sessions_required': 'Mindestens 3 Einheiten sind für eine Analyse erforderlich',
  'ai_analysis_unavailable': 'Verfügbar nach 3 Einheiten dieser Übung',
  'ai_performance_analysis': 'KI-Leistungsanalyse',
  // Workout
  'workout_search_exercise': 'Übung suchen...',
  'workout_add_exercise_not_in_list': 'Übung hinzufügen, die nicht in der Liste ist',
  'exercise_name_placeholder': 'Übungsname',
  'sets_count_placeholder': 'Anzahl der Sätze',
  'workout_effective_duration': 'Effektive Dauer (Minuten)',
  'workout_session_history': 'Einheitsverlauf',
  'workout_max': 'Max',
  'workout_best_set': 'Bester Satz',
  'workout_set_number': 'S{number}',
  'date': 'Datum',
  'workout_intensity_question': 'Wie war die Intensität der Einheit?',
  'programs': 'Programme',
  'created_by_you': 'Von dir erstellt',
  'exercise_count_plural': '{0} Übung{1}',
  'workout_weight_lifted': 'Gehobenes Gewicht',
  'workout_new_session_btn': 'Neue Einheit',
  'workout_session_recorded': 'Einheit gespeichert!',
  'workout_this_week': 'Diese Woche',
  'workout_sessions_short': 'Einheiten',
  'workout_lifted_short': 'Gehoben',
  'workout_burned_short': 'Verbrannt',
  'workout_start_by_adding_exercise': 'Beginne mit dem Hinzufügen einer Übung',
  'workout_set': 'Satz',
  'workout_confirm_end_session': 'Ende der Einheit bestätigen',
  'workout_confirm_end_session_message': 'Bist du sicher, dass du die Einheit beenden möchtest?',
  'workout_programs_loading_error': 'Fehler beim Laden der Programme',
  'workout_choose_program_title': 'Programm auswählen',
  'workout_custom_and_predefined_programs': 'Deine benutzerdefinierten und vordefinierten Programme',
  'workout_select_predefined_program': 'Wähle ein Programm mit vordefinierten Übungen',
  'validate': 'Bestätigen',
  'workout_exercise_counter': 'Übung {current}/{total}',
  'exercise_description': 'Beschreibung',
  'exercise_how_to_perform': 'Ausführung',
  'exercise_watch_tutorial': 'Tutorials ansehen',
  'exercise_no_instructions': 'Keine Anleitung für diese Übung verfügbar.',
  'exercise_loading': 'Laden...',
  'exercise_error': 'Ladefehler',
  'set_voice_input': 'Spracheingabe',
  'set_copy_to_next': 'Zum nächsten kopieren',
  'set_delete': 'Löschen',
  'workout_volume': 'Volumen',
  'workout_intensity': 'Intensität',
  'workout_intensity_duration_title': 'Intensität und Dauer',
};

// Normalize line endings (handle Windows CRLF)
content = content.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

// Apply the translations by searching for entries that are missing 'de'
const lines = content.split('\n');
let updated = 0;
let newLines = [];
let i = 0;

while (i < lines.length) {
  const line = lines[i];

  // Check if this line starts an entry (e.g., "    'key': {")
  const keyMatch = line.match(/^(\s*)'([^']+)':\s*\{$/);

  if (keyMatch) {
    const indent = keyMatch[1];
    const key = keyMatch[2];

    // Collect all lines of this entry until we find the closing }
    let entryLines = [line];
    let hasDE = false;
    let enLineIndex = -1;
    i++;

    while (i < lines.length && !lines[i].match(/^\s*\},?$/)) {
      entryLines.push(lines[i]);
      if (lines[i].includes("'de':")) {
        hasDE = true;
      }
      if (lines[i].includes("'en':")) {
        enLineIndex = entryLines.length - 1;
      }
      i++;
    }

    // Add the closing line
    if (i < lines.length) {
      entryLines.push(lines[i]);
    }

    // If this entry is in our dictionary and doesn't have 'de', add it
    if (!hasDE && deTranslations[key] && enLineIndex !== -1) {
      const deValue = deTranslations[key].replace(/'/g, "\\'");
      // Insert 'de' line after 'en' line
      const deIndent = '      ';
      const deLine = deIndent + "'de': '" + deValue + "',";
      entryLines.splice(enLineIndex + 1, 0, deLine);
      updated++;
    }

    newLines = newLines.concat(entryLines);
  } else {
    newLines.push(line);
  }

  i++;
}

content = newLines.join('\n');
fs.writeFileSync(path, content, 'utf8');
console.log('Updated ' + updated + ' translations');
