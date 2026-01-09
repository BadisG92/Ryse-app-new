import 'package:flutter/material.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    // Dashboard
    'dashboard_title': {
      'fr': 'Tableau de bord',
      'en': 'Dashboard',
      'de': 'Dashboard',
    },
    'dashboard_daily_goals': {
      'fr': 'Objectifs du jour',
      'en': 'Daily Goals',
      'de': 'Tagesziele',
    },
    'nutrition_sport_tracking': {
      'fr': 'Suivi Nutrition & Sport',
      'en': 'Nutrition & Sport Tracking',
      'de': 'Ernährungs- & Sport-Tracking',
    },
    'quick_actions': {
      'fr': 'Actions rapides',
      'en': 'Quick Actions',
      'de': 'Schnellaktionen',
    },
    'weight_recording': {
      'fr': 'Enregistrement du poids',
      'en': 'Weight Recording',
      'de': 'Gewichtseintrag',
    },
    'detailed_progress': {
      'fr': 'Progression détaillée',
      'en': 'Detailed Progress',
      'de': 'Detaillierter Fortschritt',
    },
    'what_today': {
      'fr': 'Que faisons-nous aujourd\'hui ?',
      'en': 'What are we doing today?',
      'de': 'Was machen wir heute?',
    },
    'community_ryze': {
      'fr': 'Communauté Ryze',
      'en': 'Ryze Community',
      'de': 'Ryze-Gemeinschaft',
    },
    'active_members': {
      'fr': 'membres actifs',
      'en': 'active members',
      'de': 'aktive Mitglieder',
    },
    'goals_achieved': {
      'fr': 'objectifs atteints',
      'en': 'goals achieved',
      'de': 'erreichte Ziele',
    },
    'popular_challenge': {
      'fr': 'Challenge populaire :',
      'en': 'Popular challenge:',
      'de': 'Beliebte Challenge:',
    },
    'premium_feature': {
      'fr': 'Fonctionnalité disponible avec Premium',
      'en': 'Feature available with Premium',
      'de': 'Funktion mit Premium verfügbar',
    },
    'unlock_badge': {
      'fr': 'UPGRADE',
      'en': 'UPGRADE',
      'de': 'UPGRADE',
    },
    'trial_badge': {
      'fr': 'ESSAI GRATUIT',
      'en': 'TRY FREE',
      'de': 'GRATIS TESTEN',
    },
    'must_be_connected': {
      'fr': 'Vous devez être connecté pour enregistrer l\'hydratation',
      'en': 'You must be logged in to record hydration',
      'de': 'Sie müssen angemeldet sein, um die Flüssigkeitszufuhr zu erfassen',
    },
    'water_add_error': {
      'fr': 'Erreur lors de l\'ajout d\'eau',
      'en': 'Error adding water',
      'de': 'Fehler beim Hinzufügen von Wasser',
    },
    'water_added': {
      'fr': 'ml d\'eau ajoutés ! 💧',
      'en': 'ml of water added! 💧',
      'de': 'ml Wasser hinzugefügt! 💧',
    },
    'good_morning': {
      'fr': 'Bonjour',
      'en': 'Good morning',
      'de': 'Guten Morgen',
    },
    'good_afternoon': {
      'fr': 'Bon après-midi',
      'en': 'Good afternoon',
      'de': 'Guten Nachmittag',
    },
    'good_evening': {
      'fr': 'Bonsoir',
      'en': 'Good evening',
      'de': 'Guten Abend',
    },
    'today': {
      'fr': 'Aujourd\'hui',
      'en': 'Today',
      'de': 'Heute',
    },
    'calories': {
      'fr': 'Calories',
      'en': 'Calories',
      'de': 'Kalorien',
    },
    'carbs': {
      'fr': 'Glucides',
      'en': 'Carbs',
      'de': 'Kohlenhydrate',
    },
    'fats': {
      'fr': 'Lipides',
      'en': 'Fats',
      'de': 'Fette',
    },
    'kcal': {
      'fr': 'kcal',
      'en': 'kcal',
      'de': 'kcal',
    },
    'g': {
      'fr': 'g',
      'en': 'g',
      'de': 'g',
    },
    'water_intake': {
      'fr': 'Hydratation',
      'en': 'Water Intake',
      'de': 'Wasserzufuhr',
    },
    'glasses': {
      'fr': 'verres',
      'en': 'glasses',
      'de': 'Gläser',
    },
    'goal': {
      'fr': 'Objectif',
      'en': 'Goal',
      'de': 'Ziel',
    },
    'workout': {
      'fr': 'Entraînement',
      'en': 'Workout',
      'de': 'Training',
    },
    'nutrition': {
      'fr': 'Nutrition',
      'en': 'Nutrition',
      'de': 'Ernährung',
    },
    'progress': {
      'fr': 'Progression',
      'en': 'Progress',
      'de': 'Fortschritt',
    },
    'weight': {
      'fr': 'Poids',
      'en': 'Weight',
      'de': 'Gewicht',
    },
    'kg': {
      'fr': 'kg',
      'en': 'kg',
      'de': 'kg',
    },
    'lb': {
      'fr': 'lb',
      'en': 'lb',
      'de': 'lb',
    },
    'lbs': {
      'fr': 'lbs',
      'en': 'lbs',
      'de': 'lbs',
    },
    'km': {
      'fr': 'km',
      'en': 'km',
      'de': 'km',
    },
    'mi': {
      'fr': 'mi',
      'en': 'mi',
      'de': 'mi',
    },
    'kmh': {
      'fr': 'km/h',
      'en': 'km/h',
      'de': 'km/h',
    },
    'mph': {
      'fr': 'mph',
      'en': 'mph',
      'de': 'mph',
    },
    'per_km': {
      'fr': '/km',
      'en': '/km',
      'de': '/km',
    },
    'per_mi': {
      'fr': '/mi',
      'en': '/mi',
      'de': '/mi',
    },
    'cm': {
      'fr': 'cm',
      'en': 'cm',
      'de': 'cm',
    },
    'see_all': {
      'fr': 'Voir tout',
      'en': 'See all',
      'de': 'Alle anzeigen',
    },
    'add': {
      'fr': 'Ajouter',
      'en': 'Add',
      'de': 'Hinzufügen',
    },
    'edit': {
      'fr': 'Modifier',
      'en': 'Edit',
      'de': 'Bearbeiten',
    },
    'delete': {
      'fr': 'Supprimer',
      'en': 'Delete',
      'de': 'Löschen',
    },
    'delete_session': {
      'fr': 'Supprimer la séance',
      'en': 'Delete session',
      'de': 'Einheit löschen',
    },
    'delete_session_confirm': {
      'fr':
          'Êtes-vous sûr de vouloir supprimer cette séance ? Cette action est irréversible.',
      'en':
          'Are you sure you want to delete this session? This action cannot be undone.',
      'de':
          'Sind Sie sicher, dass Sie diese Einheit löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.',
    },
    'delete_session_success': {
      'fr': 'Séance supprimée avec succès',
      'en': 'Session deleted successfully',
      'de': 'Einheit erfolgreich gelöscht',
    },
    'delete_session_error': {
      'fr': 'Erreur lors de la suppression de la séance',
      'en': 'Error deleting session',
      'de': 'Fehler beim Löschen der Einheit',
    },
    'no_sessions_this_day': {
      'fr': 'Aucune séance ce jour',
      'en': 'No sessions this day',
      'de': 'Keine Einheiten an diesem Tag',
    },
    'save': {
      'fr': 'Sauvegarder',
      'en': 'Save',
      'de': 'Speichern',
    },
    'cancel': {
      'fr': 'Annuler',
      'en': 'Cancel',
      'de': 'Abbrechen',
    },
    'add_ingredient': {
      'fr': 'Ajouter un aliment',
      'en': 'Add a food',
      'de': 'Lebensmittel hinzufügen',
    },
    'ingredient_name': {
      'fr': 'Nom de l\'aliment',
      'en': 'Food name',
      'de': 'Lebensmittelname',
    },
    'ingredient_name_placeholder': {
      'fr': 'Ex: Poulet grillé',
      'en': 'Ex: Grilled chicken',
      'de': 'z.B.: Gegrilltes Hähnchen',
    },
    'ingredient_added_success': {
      'fr': 'Aliment ajouté',
      'en': 'Food added',
      'de': 'Lebensmittel hinzugefügt',
    },
    'ingredient_not_recognized': {
      'fr': 'Aliment non reconnu',
      'en': 'Food not recognized',
      'de': 'Lebensmittel nicht erkannt',
    },
    'quantity_required': {
      'fr': 'La quantité est obligatoire',
      'en': 'Quantity is required',
      'de': 'Menge ist erforderlich',
    },
    'name_required': {
      'fr': 'Le nom est obligatoire',
      'en': 'Name is required',
      'de': 'Name ist erforderlich',
    },
    'loading': {
      'fr': 'Chargement...',
      'en': 'Loading...',
      'de': 'Laden...',
    },
    'error': {
      'fr': 'Erreur',
      'en': 'Error',
      'de': 'Fehler',
    },
    'no_data': {
      'fr': 'Aucune donnée',
      'en': 'No data',
      'de': 'Keine Daten',
    },
    'recent_meals': {
      'fr': 'Repas récents',
      'en': 'Recent meals',
      'de': 'Letzte Mahlzeiten',
    },
    'breakfast': {
      'fr': 'Petit-déjeuner',
      'en': 'Breakfast',
      'de': 'Frühstück',
    },
    'lunch': {
      'fr': 'Déjeuner',
      'en': 'Lunch',
      'de': 'Mittagessen',
    },
    'dinner': {
      'fr': 'Dîner',
      'en': 'Dinner',
      'de': 'Abendessen',
    },
    'snack': {
      'fr': 'Collation',
      'en': 'Snack',
      'de': 'Snack',
    },
    'widget_meals_title': {
      'fr': 'Mes Repas',
      'en': 'My Meals',
      'de': 'Meine Mahlzeiten',
    },
    'widget_meals_description': {
      'fr': 'Voir vos repas et calories du jour',
      'en': 'See today\'s meals and calories',
      'de': 'Mahlzeiten und Kalorien von heute anzeigen',
    },
    'widget_placeholder_meal': {
      'fr': 'Repas',
      'en': 'Meal',
      'de': 'Mahlzeit',
    },
    'widget_short_breakfast': {
      'fr': 'Petit-déj.',
      'en': 'Breakfast',
      'de': 'Frühstück',
    },
    'widget_short_lunch': {
      'fr': 'Déjeuner',
      'en': 'Lunch',
      'de': 'Mittag',
    },
    'widget_short_dinner': {
      'fr': 'Dîner',
      'en': 'Dinner',
      'de': 'Abend',
    },
    'widget_short_snack': {
      'fr': 'Collation',
      'en': 'Snack',
      'de': 'Snack',
    },
    'widget_short_default': {
      'fr': 'Repas',
      'en': 'Meal',
      'de': 'Mahlzeit',
    },
    'widget_add_water_title': {
      'fr': 'Ajouter de l\'eau',
      'en': 'Add water',
      'de': 'Wasser hinzufügen',
    },
    'widget_add_water_description': {
      'fr': 'Ajoute de l\'eau à votre consommation quotidienne',
      'en': 'Add water to your daily intake',
      'de': 'Wasser zu Ihrer täglichen Aufnahme hinzufügen',
    },
    'widget_add_water_preset_format': {
      'fr': 'Ajouter {amount} ml',
      'en': 'Add {amount} ml',
      'de': '{amount} ml hinzufügen',
    },
    // Coach Widget - Lock Screen
    'widget_coach_title': {
      'fr': 'Coach Ryse',
      'en': 'Ryse Coach',
      'de': 'Ryse Coach',
    },
    'widget_coach_description': {
      'fr': 'Suivi calories avec conseils personnalisés',
      'en': 'Calorie tracking with personalized tips',
      'de': 'Kalorienverfolgung mit personalisierten Tipps',
    },
    // Coach Messages - Morning (before breakfast)
    'coach_morning_no_breakfast': {
      'fr': 'Bien dormi ? Commence ta journée ! 🌅',
      'en': 'Slept well? Start your day! 🌅',
      'de': 'Gut geschlafen? Starte deinen Tag! 🌅',
    },
    'coach_morning_has_breakfast': {
      'fr': 'Super début de journée ! 💪',
      'en': 'Great start to your day! 💪',
      'de': 'Toller Start in den Tag! 💪',
    },
    // Coach Messages - Lunch time
    'coach_lunch_on_track': {
      'fr': 'En bonne voie, continue ! 🎯',
      'en': 'On track, keep it up! 🎯',
      'de': 'Auf Kurs, weiter so! 🎯',
    },
    'coach_lunch_low_calories': {
      'fr': 'Pense à bien manger ce midi 🍽️',
      'en': 'Remember to eat well at lunch 🍽️',
      'de': 'Denk daran, mittags gut zu essen 🍽️',
    },
    // Coach Messages - Afternoon
    'coach_afternoon_good': {
      'fr': 'Belle progression aujourd\'hui ! ⭐',
      'en': 'Great progress today! ⭐',
      'de': 'Toller Fortschritt heute! ⭐',
    },
    'coach_afternoon_low_protein': {
      'fr': 'Plus de protéines serait idéal 🥩',
      'en': 'More protein would be ideal 🥩',
      'de': 'Mehr Protein wäre ideal 🥩',
    },
    // Coach Messages - Dinner time
    'coach_dinner_almost_goal': {
      'fr': 'Presque à l\'objectif ! 🏁',
      'en': 'Almost at your goal! 🏁',
      'de': 'Fast am Ziel! 🏁',
    },
    'coach_dinner_over_budget': {
      'fr': 'Dîner léger ce soir ? 🥗',
      'en': 'Light dinner tonight? 🥗',
      'de': 'Leichtes Abendessen heute? 🥗',
    },
    // Coach Messages - Evening
    'coach_evening_goal_reached': {
      'fr': 'Objectif atteint, bravo ! 🏆',
      'en': 'Goal reached, well done! 🏆',
      'de': 'Ziel erreicht, gut gemacht! 🏆',
    },
    'coach_evening_water_low': {
      'fr': 'N\'oublie pas de t\'hydrater 💧',
      'en': 'Don\'t forget to hydrate 💧',
      'de': 'Vergiss nicht, dich zu hydrieren 💧',
    },
    // Coach Messages - Streak milestones
    'coach_streak_7': {
      'fr': '7 jours de suite ! 🔥',
      'en': '7 days in a row! 🔥',
      'de': '7 Tage in Folge! 🔥',
    },
    'coach_streak_14': {
      'fr': '2 semaines, incroyable ! 🌟',
      'en': '2 weeks, incredible! 🌟',
      'de': '2 Wochen, unglaublich! 🌟',
    },
    'coach_streak_30': {
      'fr': '1 mois ! Tu es un champion ! 👑',
      'en': '1 month! You\'re a champion! 👑',
      'de': '1 Monat! Du bist ein Champion! 👑',
    },
    // Coach Messages - Default/Fallback
    'coach_default': {
      'fr': 'Continue comme ça ! 💪',
      'en': 'Keep it up! 💪',
      'de': 'Weiter so! 💪',
    },
    'total': {
      'fr': 'Total',
      'en': 'Total',
      'de': 'Gesamt',
    },
    'remaining': {
      'fr': 'Restant',
      'en': 'Remaining',
      'de': 'Verbleibend',
    },
    'exceeded': {
      'fr': 'Dépassé',
      'en': 'Exceeded',
      'de': 'Überschritten',
    },
    'localization_demo': {
      'fr': 'Démo Localisation',
      'en': 'Localization Demo',
      'de': 'Lokalisierungs-Demo',
    },
    'static_texts_demo': {
      'fr': 'Exemples de textes traduits',
      'en': 'Translated text examples',
      'de': 'Beispiele für übersetzte Texte',
    },
    'current_language_info': {
      'fr': 'Langue actuelle: Français 🇫🇷',
      'en': 'Current language: English 🇺🇸',
      'de': 'Aktuelle Sprache: Deutsch 🇩🇪',
    },
    'search_foods': {
      'fr': 'Rechercher des aliments',
      'en': 'Search foods',
      'de': 'Lebensmittel suchen',
    },
    'search_foods_hint': {
      'fr': 'Tapez le nom d\'un aliment...',
      'en': 'Type a food name...',
      'de': 'Lebensmittelnamen eingeben...',
    },
    // Settings screen
    'upgrade_to_premium': {
      'fr': 'Passer à Premium',
      'en': 'Upgrade to Premium',
      'de': 'Auf Premium upgraden',
    },
    'unlock_all_features': {
      'fr': 'Débloquez toutes les fonctionnalités',
      'en': 'Unlock all features',
      'de': 'Alle Funktionen freischalten',
    },
    'settings_profile': {
      'fr': 'Profil',
      'en': 'Profile',
      'de': 'Profil',
    },
    'settings_objectives': {
      'fr': 'Objectifs',
      'en': 'Objectives',
      'de': 'Ziele',
    },
    'settings_notifications': {
      'fr': 'Notifications',
      'en': 'Notifications',
      'de': 'Benachrichtigungen',
    },
    'settings_preferences': {
      'fr': 'Préférences',
      'en': 'Preferences',
      'de': 'Einstellungen',
    },
    'settings_dietary_restrictions': {
      'fr': 'Restrictions alimentaires',
      'en': 'Dietary restrictions',
      'de': 'Ernährungseinschränkungen',
    },
    'settings_account': {
      'fr': 'Compte',
      'en': 'Account',
      'de': 'Konto',
    },
    // Settings content translations
    'settings_header_title': {
      'fr': 'Paramètres',
      'en': 'Settings',
      'de': 'Einstellungen',
    },
    'age_years': {
      'fr': 'ans',
      'en': 'years old',
      'de': 'Jahre alt',
    },
    'gender': {
      'fr': 'Genre',
      'en': 'Gender',
      'de': 'Geschlecht',
    },
    'male': {
      'fr': 'Homme',
      'en': 'Male',
      'de': 'Männlich',
    },
    'female': {
      'fr': 'Femme',
      'en': 'Female',
      'de': 'Weiblich',
    },
    'other': {
      'fr': 'Autre',
      'en': 'Other',
      'de': 'Andere',
    },
    'target_weight': {
      'fr': 'Poids cible',
      'en': 'Target weight',
      'de': 'Zielgewicht',
    },
    'target_weight_question_lose': {
      'fr': 'Quel est votre poids objectif ?',
      'en': 'What is your target weight?',
      'de': 'Was ist Ihr Zielgewicht?',
    },
    'target_weight_question_gain': {
      'fr': 'Quel poids souhaitez-vous atteindre ?',
      'en': 'What weight would you like to reach?',
      'de': 'Welches Gewicht möchten Sie erreichen?',
    },
    'loading_personalized_coaching': {
      'fr': 'Préparation de votre coaching personnalisé...',
      'en': 'Preparing your personalized coaching...',
      'de': 'Ihr persönliches Coaching wird vorbereitet...',
    },
    'loading_activity_level': {
      'fr': 'Prise en compte de votre niveau d\'activité...',
      'en': 'Taking into account your activity level...',
      'de': 'Ihr Aktivitätsniveau wird berücksichtigt...',
    },
    'loading_metabolism': {
      'fr': 'Calcul de votre métabolisme de base...',
      'en': 'Calculating your base metabolism...',
      'de': 'Ihr Grundumsatz wird berechnet...',
    },
    'loading_adjustment': {
      'fr': 'Ajustement selon votre objectif principal...',
      'en': 'Adjusting according to your main goal...',
      'de': 'Anpassung an Ihr Hauptziel...',
    },
    'loading_nutritional_analysis': {
      'fr': 'Analyse de vos besoins nutritionnels...',
      'en': 'Analyzing your nutritional needs...',
      'de': 'Analyse Ihrer Ernährungsbedürfnisse...',
    },
    'loading_macronutrients': {
      'fr': 'Personnalisation de vos apports en macronutriments...',
      'en': 'Customizing your macronutrient intake...',
      'de': 'Personalisierung Ihrer Makronährstoffzufuhr...',
    },
    'loading_preferences': {
      'fr': 'Vérification de vos préférences et restrictions...',
      'en': 'Checking your preferences and restrictions...',
      'de': 'Überprüfung Ihrer Vorlieben und Einschränkungen...',
    },
    'loading_plan_ready': {
      'fr': 'Votre plan est presque prêt !',
      'en': 'Your plan is almost ready!',
      'de': 'Ihr Plan ist fast fertig!',
    },
    'activity_level_question': {
      'fr': 'Quel est votre niveau d\'activité ?',
      'en': 'What is your activity level?',
      'de': 'Was ist Ihr Aktivitätsniveau?',
    },
    'goal_question': {
      'fr': 'Quel est votre objectif ?',
      'en': 'What is your goal?',
      'de': 'Was ist Ihr Ziel?',
    },
    'obstacles_question': {
      'fr': 'Qu\'est-ce qui vous empêche de garder une routine ?',
      'en': 'What prevents you from keeping a routine?',
      'de': 'Was hindert Sie daran, eine Routine beizubehalten?',
    },
    'dietary_restrictions_question': {
      'fr': 'Avez-vous des restrictions alimentaires ?',
      'en': 'Do you have any dietary restrictions?',
      'de': 'Haben Sie Ernährungseinschränkungen?',
    },
    'congratulations': {
      'fr': 'Félicitations !',
      'en': 'Congratulations!',
      'de': 'Herzlichen Glückwunsch!',
    },
    'your_plan_ready': {
      'fr': 'Votre plan est prêt',
      'en': 'Your plan is ready',
      'de': 'Ihr Plan ist fertig',
    },
    'daily_goal': {
      'fr': 'Ton objectif quotidien',
      'en': 'Your daily goal',
      'de': 'Ihr tägliches Ziel',
    },
    'calculated_specially': {
      'fr': 'Calculé spécialement pour toi',
      'en': 'Calculated specially for you',
      'de': 'Speziell für Sie berechnet',
    },
    'start_journey': {
      'fr': 'Commencer mon parcours',
      'en': 'Start my journey',
      'de': 'Meine Reise beginnen',
    },
    'calculation_details': {
      'fr': 'Détail du calcul',
      'en': 'Calculation details',
      'de': 'Berechnungsdetails',
    },
    'base_metabolism': {
      'fr': 'Métabolisme de base (BMR)',
      'en': 'Base metabolism (BMR)',
      'de': 'Grundumsatz (BMR)',
    },
    'physical_activity': {
      'fr': 'Activité physique',
      'en': 'Physical activity',
      'de': 'Körperliche Aktivität',
    },
    'goal_surplus': {
      'fr': 'Objectif (surplus)',
      'en': 'Goal (surplus)',
      'de': 'Ziel (Überschuss)',
    },
    'goal_deficit': {
      'fr': 'Objectif (déficit)',
      'en': 'Goal (deficit)',
      'de': 'Ziel (Defizit)',
    },
    'final_result': {
      'fr': 'Résultat final :',
      'en': 'Final result:',
      'de': 'Endergebnis:',
    },
    'kcal_per_day': {
      'fr': 'kcal/jour',
      'en': 'kcal/day',
      'de': 'kcal/Tag',
    },
    'modify_macronutrients': {
      'fr': 'Modifier les macronutriments',
      'en': 'Modify macronutrients',
      'de': 'Makronährstoffe anpassen',
    },
    'daily_calorie_goal': {
      'fr': 'Objectif calorique quotidien',
      'en': 'Daily calorie goal',
      'de': 'Tägliches Kalorienziel',
    },
    'recommended': {
      'fr': 'Recommandé:',
      'en': 'Recommended:',
      'de': 'Empfohlen:',
    },
    'macronutrient_distribution': {
      'fr': 'Répartition des macronutriments',
      'en': 'Macronutrient distribution',
      'de': 'Makronährstoffverteilung',
    },
    'proteins': {
      'fr': 'Protéines',
      'en': 'Proteins',
      'de': 'Proteine',
    },
    'apply': {
      'fr': 'Appliquer',
      'en': 'Apply',
      'de': 'Anwenden',
    },
    'personalization_in_progress': {
      'fr': 'Personnalisation en cours...',
      'en': 'Personalization in progress...',
      'de': 'Personalisierung läuft...',
    },
    'ryze_preparing_plan': {
      'fr': '🧠 Ryze prépare votre plan...',
      'en': '🧠 Ryze is preparing your plan...',
      'de': '🧠 Ryze bereitet Ihren Plan vor...',
    },
    'predefined_distributions': {
      'fr': 'Répartitions prédéfinies',
      'en': 'Predefined distributions',
      'de': 'Vordefinierte Verteilungen',
    },
    'balanced': {
      'fr': 'Équilibré',
      'en': 'Balanced',
      'de': 'Ausgewogen',
    },
    'macronutrients': {
      'fr': 'Macronutriments',
      'en': 'Macronutrients',
      'de': 'Makronährstoffe',
    },
    'recalculate_nutrition_plan': {
      'fr': 'Recalculer le plan nutritionnel',
      'en': 'Recalculate nutrition plan',
      'de': 'Ernährungsplan neu berechnen',
    },
    'weight_loss': {
      'fr': 'Perte',
      'en': 'Weight loss',
      'de': 'Abnehmen',
    },
    'maintenance': {
      'fr': 'Maintien',
      'en': 'Maintain',
      'de': 'Halten',
    },
    'weight_gain': {
      'fr': 'Prise de masse',
      'en': 'Weight gain',
      'de': 'Zunehmen',
    },
    'weight_loss_full': {
      'fr': 'Perte de poids',
      'en': 'Weight loss',
      'de': 'Gewichtsverlust',
    },
    'weight_gain_full': {
      'fr': 'Prise de masse',
      'en': 'Weight gain',
      'de': 'Gewichtszunahme',
    },
    'main_goal': {
      'fr': 'OBJECTIF PRINCIPAL',
      'en': 'MAIN GOAL',
      'de': 'HAUPTZIEL',
    },
    'age': {
      'fr': 'Âge',
      'en': 'Age',
      'de': 'Alter',
    },
    'height': {
      'fr': 'Taille',
      'en': 'Height',
      'de': 'Größe',
    },
    'years': {
      'fr': 'ans',
      'en': 'years',
      'de': 'Jahre',
    },
    'activity_level': {
      'fr': 'NIVEAU D\'ACTIVITÉ',
      'en': 'ACTIVITY LEVEL',
      'de': 'AKTIVITÄTSNIVEAU',
    },
    'low_active': {
      'fr': 'Peu actif',
      'en': 'Low active',
      'de': 'Wenig aktiv',
    },
    'moderate': {
      'fr': 'Modéré',
      'en': 'Moderate',
      'de': 'Moderat',
    },
    'very_active': {
      'fr': 'Très actif',
      'en': 'Very active',
      'de': 'Sehr aktiv',
    },
    'help_support': {
      'fr': 'Aide et support',
      'en': 'Help and support',
      'de': 'Hilfe und Support',
    },
    'about': {
      'fr': 'À propos',
      'en': 'About',
      'de': 'Über',
    },
    'test_onboarding': {
      'fr': 'Tester l\'onboarding',
      'en': 'Test onboarding',
      'de': 'Onboarding testen',
    },
    'test_onboarding_translations': {
      'fr': 'Tester traductions onboarding',
      'en': 'Test onboarding translations',
      'de': 'Onboarding-Übersetzungen testen',
    },
    'test_onboarding_confirmation': {
      'fr': 'Voulez-vous vraiment relancer l\'onboarding ?',
      'en': 'Do you really want to restart the onboarding?',
      'de': 'Möchten Sie das Onboarding wirklich neu starten?',
    },
    'logout': {
      'fr': 'Déconnexion',
      'en': 'Logout',
      'de': 'Abmelden',
    },
    'logout_confirmation': {
      'fr': 'Êtes-vous sûr de vouloir vous déconnecter ?',
      'en': 'Are you sure you want to log out?',
      'de': 'Sind Sie sicher, dass Sie sich abmelden möchten?',
    },
    'error_during_logout': {
      'fr': 'Erreur lors de la déconnexion',
      'en': 'Error during logout',
      'de': 'Fehler beim Abmelden',
    },
    'daily_reminder': {
      'fr': 'Rappel quotidien',
      'en': 'Daily reminder',
      'de': 'Tägliche Erinnerung',
    },
    'daily_reminder_subtitle': {
      'fr': 'Rappel pour vos objectifs du jour',
      'en': 'Reminder for your daily goals',
      'de': 'Erinnerung für Ihre täglichen Ziele',
    },
    'workout_reminder': {
      'fr': 'Rappel entraînement',
      'en': 'Workout reminder',
      'de': 'Trainingserinnerung',
    },
    'workout_reminder_subtitle': {
      'fr': 'Notification avant vos séances',
      'en': 'Notification before your sessions',
      'de': 'Benachrichtigung vor Ihren Trainingseinheiten',
    },
    'meal_reminder': {
      'fr': 'Rappel repas',
      'en': 'Meal reminder',
      'de': 'Mahlzeiterinnerung',
    },
    'meal_reminder_subtitle': {
      'fr': 'Notification pour vos repas',
      'en': 'Notification for your meals',
      'de': 'Benachrichtigung für Ihre Mahlzeiten',
    },
    'progress_notifications': {
      'fr': 'Notifications de progrès',
      'en': 'Progress notifications',
      'de': 'Fortschrittsbenachrichtigungen',
    },
    'progress_notifications_subtitle': {
      'fr': 'Mises à jour hebdomadaires',
      'en': 'Weekly updates',
      'de': 'Wöchentliche Aktualisierungen',
    },
    'language': {
      'fr': 'Langue',
      'en': 'Language',
      'de': 'Sprache',
    },
    'sound_effects_subtitle': {
      'fr': 'Sons dans l\'application',
      'en': 'Sounds in the app',
      'de': 'Töne in der App',
    },
    'haptic_feedback_subtitle': {
      'fr': 'Vibrations lors des interactions',
      'en': 'Vibrations during interactions',
      'de': 'Vibrationen bei Interaktionen',
    },
    'no_restrictions': {
      'fr': 'Aucune restriction',
      'en': 'No restrictions',
      'de': 'Keine Einschränkungen',
    },
    'restrictions_count': {
      'fr': 'restriction(s)',
      'en': 'restriction(s)',
      'de': 'Einschränkung(en)',
    },
    'classic': {
      'fr': 'Classique',
      'en': 'Classic',
      'de': 'Klassisch',
    },
    'vegetarian': {
      'fr': 'Végétarien',
      'en': 'Vegetarian',
      'de': 'Vegetarisch',
    },
    'vegan': {
      'fr': 'Végétalien',
      'en': 'Vegan',
      'de': 'Vegan',
    },
    'pescetarian': {
      'fr': 'Pescetarien',
      'en': 'Pescetarian',
      'de': 'Pescetarisch',
    },
    'account_management': {
      'fr': 'Gestion du compte',
      'en': 'Account management',
      'de': 'Kontoverwaltung',
    },
    'email_password': {
      'fr': 'Mot de passe',
      'en': 'Password',
      'de': 'Passwort',
    },
    'privacy': {
      'fr': 'Confidentialité',
      'en': 'Privacy',
      'de': 'Datenschutz',
    },
    'all_notifications_disabled': {
      'fr': 'Toutes désactivées',
      'en': 'All disabled',
      'de': 'Alle deaktiviert',
    },
    'all_notifications_enabled': {
      'fr': 'Toutes activées',
      'en': 'All enabled',
      'de': 'Alle aktiviert',
    },
    'notifications_enabled': {
      'fr': 'activée',
      'en': 'enabled',
      'de': 'aktiviert',
    },
    'notifications_enabled_plural': {
      'fr': 'activées',
      'en': 'enabled',
      'de': 'aktiviert',
    },
    'language_selection': {
      'fr': 'Langue',
      'en': 'Language',
      'de': 'Sprache',
    },
    'measurement_system': {
      'fr': 'Système de mesure',
      'en': 'Measurement system',
      'de': 'Maßeinheiten',
    },
    'sound_effects': {
      'fr': 'Effets sonores',
      'en': 'Sound effects',
      'de': 'Soundeffekte',
    },
    'haptic_feedback': {
      'fr': 'Retour haptique',
      'en': 'Haptic feedback',
      'de': 'Haptisches Feedback',
    },
    'french': {
      'fr': 'Français',
      'en': 'French',
      'de': 'Französisch',
    },
    'english': {
      'fr': 'Anglais',
      'en': 'English',
      'de': 'Englisch',
    },
    'dietary_restrictions': {
      'fr': 'Restrictions alimentaires',
      'en': 'Dietary restrictions',
      'de': 'Ernährungseinschränkungen',
    },
    'metric': {
      'fr': 'Métrique',
      'en': 'Metric',
      'de': 'Metrisch',
    },
    'imperial': {
      'fr': 'Impérial',
      'en': 'Imperial',
      'de': 'Imperial',
    },
    'close': {
      'fr': 'Fermer',
      'en': 'Close',
      'de': 'Schließen',
    },
    // Complete demo
    'complete_demo_title': {
      'fr': 'Démo Localisation Complète',
      'en': 'Complete Localization Demo',
      'de': 'Vollständige Lokalisierungs-Demo',
    },
    'overview': {
      'fr': 'Aperçu',
      'en': 'Overview',
      'de': 'Übersicht',
    },
    'exercises': {
      'fr': 'Exercices',
      'en': 'Exercises',
      'de': 'Übungen',
    },
    'exercise': {
      'fr': 'Exercice',
      'en': 'Exercise',
      'de': 'Übung',
    },
    'foods': {
      'fr': 'Aliments',
      'en': 'Foods',
      'de': 'Lebensmittel',
    },
    'language_info': {
      'fr': 'Informations sur la langue',
      'en': 'Language Information',
      'de': 'Sprachinformationen',
    },
    'current_language': {
      'fr': 'Langue actuelle',
      'en': 'Current Language',
      'de': 'Aktuelle Sprache',
    },
    'language_code': {
      'fr': 'Code langue',
      'en': 'Language Code',
      'de': 'Sprachcode',
    },
    'database_suffix': {
      'fr': 'Suffixe BDD',
      'en': 'DB Suffix',
      'de': 'DB-Suffix',
    },
    'language_tip': {
      'fr': 'Utilisez le sélecteur en haut à droite pour changer de langue',
      'en': 'Use the selector at the top right to change language',
      'de': 'Verwenden Sie den Selektor oben rechts, um die Sprache zu ändern',
    },
    'static_texts_examples': {
      'fr': 'Exemples de textes statiques',
      'en': 'Static text examples',
      'de': 'Statische Textbeispiele',
    },
    'formatting_examples': {
      'fr': 'Exemples de formatage',
      'en': 'Formatting examples',
      'de': 'Formatierungsbeispiele',
    },
    'water_consumption': {
      'fr': 'Consommation d\'eau',
      'en': 'Water consumption',
      'de': 'Wasserverbrauch',
    },
    'macro_distribution': {
      'fr': 'Répartition des macros',
      'en': 'Macro distribution',
      'de': 'Makroverteilung',
    },
    'measurement_units': {
      'fr': 'Unités de mesure',
      'en': 'Measurement units',
      'de': 'Maßeinheiten',
    },
    'how_to_use': {
      'fr': 'Comment utiliser',
      'en': 'How to use',
      'de': 'Anleitung',
    },
    'instruction_1': {
      'fr': 'Changez la langue avec le sélecteur en haut à droite',
      'en': 'Change language with the selector at the top right',
      'de': 'Sprache mit dem Selektor oben rechts ändern',
    },
    'instruction_2': {
      'fr': 'Observez comment tous les textes sont traduits automatiquement',
      'en': 'Notice how all texts are automatically translated',
      'de': 'Beobachten Sie, wie alle Texte automatisch übersetzt werden',
    },
    'instruction_3': {
      'fr':
          'Les onglets Exercices et Aliments utilisent les vraies données de la base',
      'en': 'The Exercises and Foods tabs use real database data',
      'de': 'Die Tabs Übungen und Lebensmittel verwenden echte Datenbankdaten',
    },
    'instruction_4': {
      'fr':
          'La langue sélectionnée est sauvegardée et persiste entre les sessions',
      'en': 'The selected language is saved and persists between sessions',
      'de':
          'Die ausgewählte Sprache wird gespeichert und bleibt zwischen Sitzungen erhalten',
    },
    'exercises_database_demo': {
      'fr': 'Démonstration avec la vraie base de données d\'exercices',
      'en': 'Demo with real exercises database',
      'de': 'Demo mit echter Übungsdatenbank',
    },
    'foods_database_demo': {
      'fr': 'Démonstration avec la vraie base de données d\'aliments',
      'en': 'Demo with real foods database',
      'de': 'Demo mit echter Lebensmitteldatenbank',
    },
    // Dashboard additional texts
    'welcome_join_us': {
      'fr': 'Rejoins-nous',
      'en': 'Join us',
      'de': 'Mach mit',
    },
    'onboarding_lets_meet': {
      'fr': 'Faisons connaissance',
      'en': 'Let\'s get to know each other',
      'de': 'Lass uns kennenlernen',
    },
    'welcome_premium': {
      'fr': 'Bienvenue dans Ryze Premium ! 🎉',
      'en': 'Welcome to Ryze Premium! 🎉',
      'de': 'Willkommen bei Ryze Premium! 🎉',
    },
    'navigate_to': {
      'fr': 'Navigation vers',
      'en': 'Navigate to',
      'de': 'Navigieren zu',
    },
    'user_profile': {
      'fr': 'Profil utilisateur',
      'en': 'User profile',
      'de': 'Benutzerprofil',
    },
    'loading_profile': {
      'fr': 'Chargement du profil...',
      'en': 'Loading profile...',
      'de': 'Profil wird geladen...',
    },
    'error_loading_profile': {
      'fr': 'Erreur lors du chargement du profil',
      'en': 'Error loading profile',
      'de': 'Fehler beim Laden des Profils',
    },
    'hello': {
      'fr': 'Salut',
      'en': 'Hello',
      'de': 'Hallo',
    },
    'daily_objectives': {
      'fr': 'Objectifs quotidiens',
      'en': 'Daily objectives',
      'de': 'Tägliche Ziele',
    },
    'completed': {
      'fr': 'complété',
      'en': 'completed',
      'de': 'abgeschlossen',
    },
    'goals_completed': {
      'fr': 'objectifs complétés',
      'en': 'goals completed',
      'de': 'Ziele erreicht',
    },
    'view_all': {
      'fr': 'Voir tout',
      'en': 'View all',
      'de': 'Alle anzeigen',
    },
    'open_advanced_analytics': {
      'fr': 'Ouverture des analytics avancés',
      'en': 'Opening advanced analytics',
      'de': 'Erweiterte Analysen öffnen',
    },
    'feature_premium_only': {
      'fr': 'Fonctionnalité disponible avec Premium',
      'en': 'Feature available with Premium',
      'de': 'Funktion nur mit Premium verfügbar',
    },
    'starting_workout': {
      'fr': 'Démarrage d\'entraînement',
      'en': 'Starting workout',
      'de': 'Training wird gestartet',
    },
    'adding_meal': {
      'fr': 'Ajout de repas',
      'en': 'Adding meal',
      'de': 'Mahlzeit hinzufügen',
    },
    'adding_hydration': {
      'fr': 'Ajout d\'hydratation',
      'en': 'Adding hydration',
      'de': 'Flüssigkeit hinzufügen',
    },
    'food_scanner': {
      'fr': 'Scanner d\'aliments',
      'en': 'Food scanner',
      'de': 'Lebensmittelscanner',
    },
    'starting_session': {
      'fr': 'Démarrage de la séance',
      'en': 'Starting session',
      'de': 'Einheit wird gestartet',
    },
    // Header dashboard
    'current_series': {
      'fr': 'séries en cours',
      'en': 'current series',
      'de': 'aktuelle Serie',
    },
    'day': {
      'fr': 'jour',
      'en': 'day',
      'de': 'Tag',
    },
    'days': {
      'fr': 'jours',
      'en': 'days',
      'de': 'Tage',
    },
    // Objectifs
    'track_meals_today': {
      'fr': 'Suivre mes repas aujourd\'hui',
      'en': 'Track my meals today',
      'de': 'Meine Mahlzeiten heute verfolgen',
    },
    'drink_water_goal': {
      'fr': 'Boire',
      'en': 'Drink',
      'de': 'Trinken',
    },
    'complete_workout': {
      'fr': 'Faire une séance aujourd\'hui',
      'en': 'Do a workout today',
      'de': 'Heute ein Training absolvieren',
    },
    'track_weight': {
      'fr': 'Suivre mon poids',
      'en': 'Track my weight',
      'de': 'Mein Gewicht verfolgen',
    },
    'mindful_eating': {
      'fr': 'Pratiquer une alimentation consciente',
      'en': 'Practice mindful eating',
      'de': 'Achtsames Essen praktizieren',
    },
    // Actions rapides
    'add_meal': {
      'fr': 'Ajouter un repas',
      'en': 'Add meal',
      'de': 'Mahlzeit hinzufügen',
    },
    'scan_food': {
      'fr': 'Scanner un aliment',
      'en': 'Scan food',
      'de': 'Lebensmittel scannen',
    },
    'scan_food_subtitle': {
      'fr': 'Choisissez votre méthode de scan',
      'en': 'Choose your scanning method',
      'de': 'Wählen Sie Ihre Scan-Methode',
    },
    'scan_dish': {
      'fr': 'Prendre en photo',
      'en': 'Take a photo',
      'de': 'Foto aufnehmen',
    },
    'scan_dish_subtitle': {
      'fr': 'Analyse automatique',
      'en': 'Automatic analysis',
      'de': 'Automatische Analyse',
    },
    'start_workout': {
      'fr': 'S\'entraîner',
      'en': 'Workout',
      'de': 'Training',
    },
    'weight_tracking': {
      'fr': 'Poids',
      'en': 'Weight',
      'de': 'Gewicht',
    },
    'track_weight_short': {
      'fr': 'Suivre poids',
      'en': 'Track weight',
      'de': 'Gewicht verfolgen',
    },
    'view_progress': {
      'fr': 'Voir progrès',
      'en': 'View progress',
      'de': 'Fortschritt ansehen',
    },
    // Nutrition et sport
    'current_session': {
      'fr': 'Session en cours',
      'en': 'Current session',
      'de': 'Aktuelle Einheit',
    },
    'last_workout': {
      'fr': 'Dernier entraînement',
      'en': 'Last workout',
      'de': 'Letztes Training',
    },
    'no_recent_meals': {
      'fr': 'Aucun repas récent',
      'en': 'No recent meals',
      'de': 'Keine aktuellen Mahlzeiten',
    },
    'no_active_workout': {
      'fr': 'Aucun entraînement actif',
      'en': 'No active workout',
      'de': 'Kein aktives Training',
    },
    'start_first_workout': {
      'fr': 'Commencer votre premier entraînement',
      'en': 'Start your first workout',
      'de': 'Starten Sie Ihr erstes Training',
    },
    // Communauté
    'ryze_community': {
      'fr': 'Communauté Ryze',
      'en': 'Ryze Community',
      'de': 'Ryze Community',
    },
    'goals_achieved_today': {
      'fr': 'objectifs atteints aujourd\'hui',
      'en': 'goals achieved today',
      'de': 'heute erreichte Ziele',
    },
    'join_community': {
      'fr': 'Rejoindre la communauté',
      'en': 'Join community',
      'de': 'Community beitreten',
    },
    // Coach Ryze
    'ai_coach': {
      'fr': 'Coach Ryze',
      'en': 'Coach Ryze',
      'de': 'Coach Ryze',
    },
    'personalized_recommendations': {
      'fr': 'Recommandations personnalisées',
      'en': 'Personalized recommendations',
      'de': 'Personalisierte Empfehlungen',
    },
    'based_on_progress': {
      'fr': 'Basées sur vos progrès',
      'en': 'Based on your progress',
      'de': 'Basierend auf Ihrem Fortschritt',
    },
    'talk_to_coach': {
      'fr': 'Parler au coach',
      'en': 'Talk to coach',
      'de': 'Mit dem Coach sprechen',
    },
    'ai_insights': {
      'fr': 'Analyses du Coach',
      'en': 'Coach Insights',
      'de': 'Coach-Analysen',
    },
    'sugar_free_challenge': {
      'fr': '30 jours sans sucre',
      'en': '30 days sugar free',
      'de': '30 Tage zuckerfrei',
    },
    'advertisements': {
      'fr': 'Publicités',
      'en': 'Advertisements',
      'de': 'Werbung',
    },
    'training': {
      'fr': 'Entraînement',
      'en': 'Training',
      'de': 'Training',
    },
    'hydration': {
      'fr': 'Hydratation',
      'en': 'Hydration',
      'de': 'Hydratation',
    },
    'water': {
      'fr': 'Eau',
      'en': 'Water',
      'de': 'Wasser',
    },
    'weighing': {
      'fr': 'Pesée',
      'en': 'Weighing',
      'de': 'Wiegen',
    },
    'sessions': {
      'fr': 'Séances',
      'en': 'Sessions',
      'de': 'Einheiten',
    },
    'session': {
      'fr': 'Séance',
      'en': 'Session',
      'de': 'Einheit',
    },
    'sessions_count': {
      'fr': '{count} séances',
      'en': '{count} sessions',
      'de': '{count} Einheiten',
    },
    'no_sessions_in_period': {
      'fr': 'Pas de séances sur la période',
      'en': 'No sessions in period',
      'de': 'Keine Einheiten im Zeitraum',
    },
    'recent_sessions': {
      'fr': 'Dernières séances',
      'en': 'Recent sessions',
      'de': 'Letzte Einheiten',
    },
    // Empty journal panda message
    'what_eating_today': {
      'fr': 'Qu\'est-ce qu\'on mange aujourd\'hui ?',
      'en': 'What are we eating today?',
      'de': 'Was essen wir heute?',
    },
    // Recipe details translations
    'nutritional_facts': {
      'fr': 'Bilan nutritionnel',
      'en': 'Nutritional facts',
      'de': 'Nährwertangaben',
    },
    'nutritional_facts_per_serving': {
      'fr': 'Bilan nutritionnel (par portion)',
      'en': 'Nutritional facts (per serving)',
      'de': 'Nährwertangaben (pro Portion)',
    },
    'ingredients_title': {
      'fr': 'Ingrédients',
      'en': 'Ingredients',
      'de': 'Zutaten',
    },
    'add_to_meal': {
      'fr': 'Ajouter à un repas',
      'en': 'Add to a meal',
      'de': 'Zu einer Mahlzeit hinzufügen',
    },
    'modify_ingredients': {
      'fr': 'Modifier les aliments',
      'en': 'Modify ingredients',
      'de': 'Zutaten anpassen',
    },
    'tracked_exercises': {
      'fr': 'Exercices suivis',
      'en': 'Tracked exercises',
      'de': 'Verfolgte Übungen',
    },
    'select_exercise_to_view_progress': {
      'fr': 'Sélectionnez un exercice pour voir sa progression',
      'en': 'Select an exercise to view its progress',
      'de': 'Wählen Sie eine Übung, um den Fortschritt anzuzeigen',
    },
    'exercise_details': {
      'fr': 'Détails de l\'exercice',
      'en': 'Exercise details',
      'de': 'Übungsdetails',
    },
    'this_month': {
      'fr': 'Ce mois-ci',
      'en': 'This month',
      'de': 'Diesen Monat',
    },
    'three_months': {
      'fr': '3 mois',
      'en': '3 months',
      'de': '3 Monate',
    },
    'six_months': {
      'fr': '6 mois',
      'en': '6 months',
      'de': '6 Monate',
    },
    'progression': {
      'fr': 'Progression',
      'en': 'Progression',
      'de': 'Fortschritt',
    },
    'best_set': {
      'fr': 'Meilleure série',
      'en': 'Best set',
      'de': 'Bester Satz',
    },
    'max_weight': {
      'fr': 'Charge Max',
      'en': 'Max Weight',
      'de': 'Max. Gewicht',
    },
    'set_number': {
      'fr': 'Série {number}',
      'en': 'Set {number}',
      'de': 'Satz {number}',
    },
    'no_sessions_found': {
      'fr': 'Aucune séance trouvée',
      'en': 'No sessions found',
      'de': 'Keine Einheiten gefunden',
    },
    // Progress/Weight Evolution translations
    'evolution_poids': {
      'fr': 'Évolution du poids',
      'en': 'Weight Evolution',
      'de': 'Gewichtsentwicklung',
    },
    'select_weight_period': {
      'fr': 'Sélectionnez une période',
      'en': 'Select a period',
      'de': 'Zeitraum auswählen',
    },
    'enter_weight': {
      'fr': 'Saisir le poids',
      'en': 'Enter weight',
      'de': 'Gewicht eingeben',
    },
    'current_weight': {
      'fr': 'Poids actuel',
      'en': 'Current weight',
      'de': 'Aktuelles Gewicht',
    },
    'this_month_short': {
      'fr': 'Ce mois',
      'en': 'This month',
      'de': 'Diesen Monat',
    },
    '3_months': {
      'fr': '3 mois',
      'en': '3 months',
      'de': '3 Monate',
    },
    '6_months': {
      'fr': '6 mois',
      'en': '6 months',
      'de': '6 Monate',
    },
    'evolution': {
      'fr': 'Evolution',
      'en': 'Evolution',
      'de': 'Entwicklung',
    },
    'weight_history': {
      'fr': 'Historique des pesées',
      'en': 'Weight history',
      'de': 'Gewichtsverlauf',
    },
    'add_first_weight': {
      'fr': 'Ajoutez votre première pesée pour voir l\'évolution',
      'en': 'Add your first weight entry to see evolution',
      'de':
          'Fügen Sie Ihren ersten Gewichtseintrag hinzu, um die Entwicklung zu sehen',
    },
    'no_weight_recorded': {
      'fr': 'Aucune pesée enregistrée',
      'en': 'No weight recorded',
      'de': 'Kein Gewicht eingetragen',
    },
    'add_weight': {
      'fr': 'Ajouter une pesée',
      'en': 'Add weight',
      'de': 'Gewicht hinzufügen',
    },
    'weight_example': {
      'fr': 'Ex: 70.5',
      'en': 'e.g. 70.5',
      'de': 'z.B. 70,5',
    },
    'weight_added_success': {
      'fr': 'Pesée ajoutée avec succès',
      'en': 'Weight added successfully',
      'de': 'Gewicht erfolgreich hinzugefügt',
    },
    'weight_loading_error': {
      'fr': 'Erreur lors du chargement: {error}',
      'en': 'Loading error: {error}',
      'de': 'Ladefehler: {error}',
    },
    'start': {
      'fr': 'Début',
      'en': 'Start',
      'de': 'Start',
    },
    'target': {
      'fr': 'Objectif',
      'en': 'Target',
      'de': 'Ziel',
    },
    'period': {
      'fr': 'Période',
      'en': 'Period',
      'de': 'Zeitraum',
    },
    'weight_kg': {
      'fr': 'Poids (kg)',
      'en': 'Weight (kg)',
      'de': 'Gewicht (kg)',
    },
    'weight_label': {
      'fr': 'Poids',
      'en': 'Weight',
      'de': 'Gewicht',
    },
    'save_weight': {
      'fr': 'Enregistrer',
      'en': 'Save',
      'de': 'Speichern',
    },
    'weight_saved': {
      'fr': 'Poids enregistré avec succès',
      'en': 'Weight saved successfully',
      'de': 'Gewicht erfolgreich gespeichert',
    },
    'error_saving_weight': {
      'fr': 'Erreur lors de l\'enregistrement',
      'en': 'Error saving weight',
      'de': 'Fehler beim Speichern des Gewichts',
    },
    'no_weight_data': {
      'fr': 'Aucune donnée de poids disponible',
      'en': 'No weight data available',
      'de': 'Keine Gewichtsdaten verfügbar',
    },
    'weight_trend': {
      'fr': 'Tendance',
      'en': 'Trend',
      'de': 'Trend',
    },
    'stable_weight': {
      'fr': 'Stable',
      'en': 'Stable',
      'de': 'Stabil',
    },
    'last_7_days': {
      'fr': '7 derniers jours',
      'en': 'Last 7 days',
      'de': 'Letzte 7 Tage',
    },
    'last_30_days': {
      'fr': '30 derniers jours',
      'en': 'Last 30 days',
      'de': 'Letzte 30 Tage',
    },
    'last_90_days': {
      'fr': '90 derniers jours',
      'en': 'Last 90 days',
      'de': 'Letzte 90 Tage',
    },
    'all_time': {
      'fr': 'Depuis le début',
      'en': 'All time',
      'de': 'Gesamter Zeitraum',
    },
    'weight_difference': {
      'fr': 'Différence: {diff} kg',
      'en': 'Difference: {diff} kg',
      'de': 'Differenz: {diff} kg',
    },
    'average_weight': {
      'fr': 'Poids moyen: {avg} kg',
      'en': 'Average weight: {avg} kg',
      'de': 'Durchschnittsgewicht: {avg} kg',
    },
    'add_weight_entry': {
      'fr': 'Ajouter une pesée',
      'en': 'Add weight entry',
      'de': 'Gewichtseintrag hinzufügen',
    },
    'edit_weight_entry': {
      'fr': 'Modifier la pesée',
      'en': 'Edit weight entry',
      'de': 'Gewichtseintrag bearbeiten',
    },
    'delete_weight_entry': {
      'fr': 'Supprimer la pesée',
      'en': 'Delete weight entry',
      'de': 'Gewichtseintrag löschen',
    },
    'confirm_delete_weight': {
      'fr': 'Êtes-vous sûr de vouloir supprimer cette pesée ?',
      'en': 'Are you sure you want to delete this weight entry?',
      'de': 'Sind Sie sicher, dass Sie diesen Gewichtseintrag löschen möchten?',
    },
    'weight_chart_title': {
      'fr': 'Évolution du poids',
      'en': 'Weight progression',
      'de': 'Gewichtsentwicklung',
    },
    'loading_weight_data': {
      'fr': 'Chargement des données...',
      'en': 'Loading data...',
      'de': 'Daten werden geladen...',
    },
    'error_loading_weight': {
      'fr': 'Erreur lors du chargement des données',
      'en': 'Error loading data',
      'de': 'Fehler beim Laden der Daten',
    },
    'retry': {
      'fr': 'Réessayer',
      'en': 'Retry',
      'de': 'Erneut versuchen',
    },
    // Progress KPI translations
    'progress_overview': {
      'fr': 'Aperçu des progrès',
      'en': 'Progress overview',
      'de': 'Fortschrittsübersicht',
    },
    'this_week_progress': {
      'fr': 'Cette semaine',
      'en': 'This week',
      'de': 'Diese Woche',
    },
    'this_month_progress': {
      'fr': 'Ce mois-ci',
      'en': 'This month',
      'de': 'Diesen Monat',
    },
    'weight_goal': {
      'fr': 'Objectif de poids',
      'en': 'Weight goal',
      'de': 'Gewichtsziel',
    },
    'calories_burned': {
      'fr': 'Calories brûlées',
      'en': 'Calories burned',
      'de': 'Verbrannte Kalorien',
    },
    'workouts_completed': {
      'fr': 'Séances terminées',
      'en': 'Workouts completed',
      'de': 'Abgeschlossene Trainings',
    },
    'steps_taken': {
      'fr': 'Pas effectués',
      'en': 'Steps taken',
      'de': 'Zurückgelegte Schritte',
    },
    'water_consumed': {
      'fr': 'Eau consommée',
      'en': 'Water consumed',
      'de': 'Verbrauchtes Wasser',
    },
    'progress_percentage': {
      'fr': '{percent}% de l\'objectif',
      'en': '{percent}% of goal',
      'de': '{percent}% des Ziels',
    },
    'goal_achieved': {
      'fr': 'Objectif atteint !',
      'en': 'Goal achieved!',
      'de': 'Ziel erreicht!',
    },
    'goal_exceeded': {
      'fr': 'Objectif dépassé !',
      'en': 'Goal exceeded!',
      'de': 'Ziel übertroffen!',
    },
    // Month abbreviations for charts
    'jan': {
      'fr': 'Jan',
      'en': 'Jan',
      'de': 'Jan',
    },
    'feb': {
      'fr': 'Fév',
      'en': 'Feb',
      'de': 'Feb',
    },
    'mar': {
      'fr': 'Mar',
      'en': 'Mar',
      'de': 'Mär',
    },
    'apr': {
      'fr': 'Avr',
      'en': 'Apr',
      'de': 'Apr',
    },
    'may': {
      'fr': 'Mai',
      'en': 'May',
      'de': 'Mai',
    },
    'jun': {
      'fr': 'Jun',
      'en': 'Jun',
      'de': 'Jun',
    },
    'jul': {
      'fr': 'Jul',
      'en': 'Jul',
      'de': 'Jul',
    },
    'aug': {
      'fr': 'Aoû',
      'en': 'Aug',
      'de': 'Aug',
    },
    'sep': {
      'fr': 'Sep',
      'en': 'Sep',
      'de': 'Sep',
    },
    'oct': {
      'fr': 'Oct',
      'en': 'Oct',
      'de': 'Okt',
    },
    'nov': {
      'fr': 'Nov',
      'en': 'Nov',
      'de': 'Nov',
    },
    'dec': {
      'fr': 'Déc',
      'en': 'Dec',
      'de': 'Dez',
    },
    // AI Recommendations
    'ai_recommendations': {
      'fr': 'Conseils du Coach Ryze',
      'en': 'Coach Ryze Tips',
      'de': 'Coach Ryze Tipps',
    },
    'smart_recommendation': {
      'fr': 'Conseil intelligent',
      'en': 'Smart recommendation',
      'de': 'Intelligente Empfehlung',
    },
    'no_recommendations': {
      'fr': 'Aucune recommandation disponible',
      'en': 'No recommendations available',
      'de': 'Keine Empfehlungen verfügbar',
    },
    'recommendation_loading': {
      'fr': 'Génération de recommandations...',
      'en': 'Generating recommendations...',
      'de': 'Empfehlungen werden generiert...',
    },
    'recommendation_error': {
      'fr': 'Erreur lors de la génération des recommandations',
      'en': 'Error generating recommendations',
      'de': 'Fehler bei der Generierung von Empfehlungen',
    },
    'excellent_rhythm_message': {
      'fr': 'Excellent rythme ! Maintenez cette cadence sportive.',
      'en': 'Excellent rhythm! Maintain this sports pace.',
      'de': 'Ausgezeichneter Rhythmus! Halten Sie dieses Sporttempo bei.',
    },
    'excellent_rhythm_continue': {
      'fr':
          'Excellent rythme ! Continuez comme ça pour maintenir votre progression.',
      'en': 'Excellent rhythm! Keep it up to maintain your progress.',
      'de':
          'Ausgezeichneter Rhythmus! Weiter so, um Ihren Fortschritt zu halten.',
    },
    'increase_protein_intake': {
      'fr':
          'Augmentez votre apport en protéines pour atteindre vos objectifs plus facilement.',
      'en': 'Increase your protein intake to reach your goals more easily.',
      'de':
          'Erhöhen Sie Ihre Proteinzufuhr, um Ihre Ziele leichter zu erreichen.',
    },
    'distribute_meals_advice': {
      'fr': 'Pensez à bien répartir vos repas tout au long de la journée.',
      'en': 'Remember to distribute your meals well throughout the day.',
      'de': 'Denken Sie daran, Ihre Mahlzeiten gut über den Tag zu verteilen.',
    },
    'sleep_recovery_importance': {
      'fr': 'N\'oubliez pas l\'importance du sommeil dans votre récupération.',
      'en': 'Don\'t forget the importance of sleep in your recovery.',
      'de': 'Vergessen Sie nicht die Bedeutung des Schlafs für Ihre Erholung.',
    },
    'continue_nutrition_efforts': {
      'fr': 'Continuez vos efforts en nutrition, vous êtes sur la bonne voie !',
      'en': 'Continue your nutrition efforts, you\'re on the right track!',
      'de':
          'Machen Sie weiter mit Ihrer Ernährung, Sie sind auf dem richtigen Weg!',
    },
    'good_hydration_continue': {
      'fr': 'Bonne hydratation, continuez à boire régulièrement.',
      'en': 'Good hydration, keep drinking regularly.',
      'de': 'Gute Hydratation, trinken Sie weiterhin regelmäßig.',
    },
    'maintain_good_balance': {
      'fr': 'Maintenez ce bon équilibre entre nutrition et sport.',
      'en': 'Maintain this good balance between nutrition and sport.',
      'de': 'Halten Sie diese gute Balance zwischen Ernährung und Sport.',
    },
    'start_recording_meals': {
      'fr': 'Commencez par enregistrer vos repas pour un meilleur suivi.',
      'en': 'Start by recording your meals for better tracking.',
      'de':
          'Beginnen Sie damit, Ihre Mahlzeiten für eine bessere Verfolgung aufzuzeichnen.',
    },
    'stay_hydrated_daily': {
      'fr': 'N\'oubliez pas de rester hydraté tout au long de la journée.',
      'en': 'Don\'t forget to stay hydrated throughout the day.',
      'de': 'Vergessen Sie nicht, den ganzen Tag über hydriert zu bleiben.',
    },
    // Missing translations for progress cards
    'perfect_week': {
      'fr': 'Semaine parfaite',
      'en': 'Perfect week',
      'de': 'Perfekte Woche',
    },
    'calorie_target_reached': {
      'fr': 'Objectifs calories atteints',
      'en': 'Calorie targets reached',
      'de': 'Kalorienziele erreicht',
    },
    'hydration_validated': {
      'fr': 'Hydratation validée',
      'en': 'Hydration validated',
      'de': 'Hydratation bestätigt',
    },
    'meals_recorded': {
      'fr': 'Repas enregistrés',
      'en': 'Meals recorded',
      'de': 'Mahlzeiten aufgezeichnet',
    },
    'sport_sessions': {
      'fr': 'Séances sport',
      'en': 'Sport sessions',
      'de': 'Sporteinheiten',
    },
    'achieved': {
      'fr': 'Atteint',
      'en': 'Achieved',
      'de': 'Erreicht',
    },
    'partial': {
      'fr': 'Partiel',
      'en': 'Partial',
      'de': 'Teilweise',
    },
    'missed': {
      'fr': 'Manqué',
      'en': 'Missed',
      'de': 'Verpasst',
    },
    'weightlifting': {
      'fr': 'Musculation',
      'en': 'Workout',
      'de': 'Krafttraining',
    },
    'rest': {
      'fr': 'Repos',
      'en': 'Rest',
      'de': 'Ruhe',
    },
    'meals': {
      'fr': 'Repas',
      'en': 'Meals',
      'de': 'Mahlzeiten',
    },
    'weekly_global_summary': {
      'fr': 'Bilan global hebdomadaire',
      'en': 'Weekly global summary',
      'de': 'Wöchentliche Gesamtübersicht',
    },
    'this_week': {
      'fr': 'Cette semaine',
      'en': 'This week',
      'de': 'Diese Woche',
    },
    // Days of week abbreviations for calendar
    'day_l': {
      'fr': 'L',
      'en': 'M',
      'de': 'M',
    },
    'day_m': {
      'fr': 'M',
      'en': 'T',
      'de': 'D',
    },
    'day_m2': {
      'fr': 'M',
      'en': 'W',
      'de': 'M',
    },
    'day_j': {
      'fr': 'J',
      'en': 'T',
      'de': 'D',
    },
    'day_v': {
      'fr': 'V',
      'en': 'F',
      'de': 'F',
    },
    'day_s': {
      'fr': 'S',
      'en': 'S',
      'de': 'S',
    },
    'day_d': {
      'fr': 'D',
      'en': 'S',
      'de': 'S',
    },
    'take_photo': {
      'fr': 'Prendre une photo',
      'en': 'Take photo',
      'de': 'Foto aufnehmen',
    },
    'photos': {
      'fr': 'Photos',
      'en': 'Photos',
      'de': 'Fotos',
    },
    'cardio': {
      'fr': 'Cardio',
      'en': 'Cardio',
      'de': 'Cardio',
    },
    'musculation': {
      'fr': 'Musculation',
      'en': 'Muscle training',
      'de': 'Muskeltraining',
    },
    'reach_calorie_goal': {
      'fr': 'Atteindre mes calories',
      'en': 'Reach my calorie goal',
      'de': 'Mein Kalorienziel erreichen',
    },
    // Nutrition page texts
    'lipids': {
      'fr': 'Lipides',
      'en': 'Fats',
      'de': 'Fette',
    },
    'new_meal_type': {
      'fr': 'Nouveau',
      'en': 'New',
      'de': 'Neu',
    },
    'create_new_meal_block': {
      'fr': 'Créer un nouveau bloc de repas',
      'en': 'Create a new meal block',
      'de': 'Neuen Mahlzeitenblock erstellen',
    },
    'add_quickly': {
      'fr': 'Ajouter rapidement',
      'en': 'Add quickly',
      'de': 'Schnell hinzufügen',
    },
    'add_food': {
      'fr': 'Ajouter un repas',
      'en': 'Add meal',
      'de': 'Mahlzeit hinzufügen',
    },
    'kcal_consumed': {
      'fr': 'kcal consommées',
      'en': 'kcal consumed',
      'de': 'kcal verbraucht',
    },
    'objective': {
      'fr': 'Objectif',
      'en': 'Goal',
      'de': 'Ziel',
    },
    // Nutrition dashboard texts
    'choose_how_to_add_food': {
      'fr': 'Choisissez comment vous souhaitez ajouter votre repas',
      'en': 'Choose how you want to add your meal',
      'de': 'Wählen Sie, wie Sie Ihre Mahlzeit hinzufügen möchten',
    },
    // Meal selection titles for each action type
    'add_chat_meal_title': {
      'fr': 'Décrire mon repas',
      'en': 'Describe my meal',
      'de': 'Meine Mahlzeit beschreiben',
    },
    'add_chat_meal_subtitle': {
      'fr': 'Où souhaitez-vous ajouter ce repas ?',
      'en': 'Where would you like to add this meal?',
      'de': 'Wo möchten Sie diese Mahlzeit hinzufügen?',
    },
    'add_photo_meal_title': {
      'fr': 'Prendre en photo',
      'en': 'Take a photo',
      'de': 'Foto aufnehmen',
    },
    'add_photo_meal_subtitle': {
      'fr': 'Où souhaitez-vous ajouter ce repas ?',
      'en': 'Where would you like to add this meal?',
      'de': 'Wo möchten Sie diese Mahlzeit hinzufügen?',
    },
    'add_barcode_meal_title': {
      'fr': 'Scanner un code-barres',
      'en': 'Scan a barcode',
      'de': 'Barcode scannen',
    },
    'add_barcode_meal_subtitle': {
      'fr': 'Où souhaitez-vous ajouter ce produit ?',
      'en': 'Where would you like to add this product?',
      'de': 'Wo möchten Sie dieses Produkt hinzufügen?',
    },
    'add_search_meal_title': {
      'fr': 'Chercher dans la base',
      'en': 'Search in database',
      'de': 'In Datenbank suchen',
    },
    'add_search_meal_subtitle': {
      'fr': 'Où souhaitez-vous ajouter cet aliment ?',
      'en': 'Where would you like to add this food?',
      'de': 'Wo möchten Sie dieses Lebensmittel hinzufügen?',
    },
    'add_recipe_meal_title': {
      'fr': 'Choisir une recette',
      'en': 'Choose a recipe',
      'de': 'Ein Rezept wählen',
    },
    'add_recipe_meal_subtitle': {
      'fr': 'Où souhaitez-vous ajouter cette recette ?',
      'en': 'Where would you like to add this recipe?',
      'de': 'Wo möchten Sie dieses Rezept hinzufügen?',
    },
    'manual_entry': {
      'fr': 'Saisie manuelle',
      'en': 'Manual entry',
      'de': 'Manuelle Eingabe',
    },
    'search_and_add_manually': {
      'fr': 'Rechercher et ajouter manuellement',
      'en': 'Search and add manually',
      'de': 'Manuell suchen und hinzufügen',
    },
    'ai_scanner': {
      'fr': 'Scanner avec Coach Ryze',
      'en': 'Scan with Coach Ryze',
      'de': 'Mit Coach Ryze scannen',
    },
    'take_photo_of_dish': {
      'fr': 'Prenez une photo de votre plat',
      'en': 'Take a photo of your dish',
      'de': 'Machen Sie ein Foto Ihres Gerichts',
    },
    'barcode': {
      'fr': 'Code-barres',
      'en': 'Barcode',
      'de': 'Barcode',
    },
    'scan_product_barcode': {
      'fr': 'Scanner le code-barres du produit',
      'en': 'Scan the product barcode',
      'de': 'Produkt-Barcode scannen',
    },
    'my_recipes': {
      'fr': 'Mes recettes',
      'en': 'My recipes',
      'de': 'Meine Rezepte',
    },
    'choose_from_saved_recipes': {
      'fr': 'Choisir parmi vos recettes sauvegardées',
      'en': 'Choose from your saved recipes',
      'de': 'Aus Ihren gespeicherten Rezepten wählen',
    },
    'add_recipe': {
      'fr': 'Ajouter une recette',
      'en': 'Add a recipe',
      'de': 'Ein Rezept hinzufügen',
    },
    'scan_barcode_subtitle': {
      'fr': 'Code-barre produit',
      'en': 'Product barcode',
      'de': 'Produkt-Barcode',
    },
    'manual_entry_subtitle': {
      'fr': 'Rechercher dans la base de données',
      'en': 'Search in the database',
      'de': 'In der Datenbank suchen',
    },
    'ai_scan_subtitle': {
      'fr': 'Le Coach Ryze analyse votre plat',
      'en': 'Coach Ryze analyzes your dish',
      'de': 'Coach Ryze analysiert Ihr Gericht',
    },
    'create_recipe_subtitle': {
      'fr': 'Créer une nouvelle recette',
      'en': 'Create a new recipe',
      'de': 'Ein neues Rezept erstellen',
    },
    'keep_going': {
      'fr': 'Continuez vos efforts !',
      'en': 'Keep going!',
      'de': 'Weiter so!',
    },
    'excellent_work': {
      'fr': 'Excellent travail !',
      'en': 'Excellent work!',
      'de': 'Ausgezeichnete Arbeit!',
    },
    'good_rhythm': {
      'fr': 'Bon rythme !',
      'en': 'Good rhythm!',
      'de': 'Guter Rhythmus!',
    },
    'start_your_week': {
      'fr': 'Commencez votre semaine',
      'en': 'Start your week',
      'de': 'Starten Sie Ihre Woche',
    },
    'goal_calories': {
      'fr': 'Atteindre mes calories',
      'en': 'Reach my calories',
      'de': 'Meine Kalorien erreichen',
    },
    'goal_water': {
      'fr': 'Boire',
      'en': 'Drink',
      'de': 'Trinken',
    },
    'goal_meals': {
      'fr': 'Suivre mes repas aujourd\'hui',
      'en': 'Track my meals today',
      'de': 'Meine Mahlzeiten heute verfolgen',
    },
    'goal_sport': {
      'fr': 'Faire du sport',
      'en': 'Exercise',
      'de': 'Sport treiben',
    },
    'add_to_existing_or_new_meal': {
      'fr':
          'Voulez-vous ajouter à un repas existant ou créer un nouveau repas ?',
      'en': 'Do you want to add to an existing meal or create a new meal?',
      'de':
          'Möchten Sie zu einer bestehenden Mahlzeit hinzufügen oder eine neue erstellen?',
    },
    // Premium CTA texts
    'try_3_days_free': {
      'fr': 'Essayer 3 jours gratuits',
      'en': 'Try 3 days free',
      'de': '3 Tage gratis testen',
    },
    'then_price_monthly': {
      'fr': 'Puis 15€/mois • Annulable à tout moment',
      'en': 'Then €15/month • Cancel anytime',
      'de': 'Dann 15€/Monat • Jederzeit kündbar',
    },
    // Nutrition units and labels
    'kcal_unit': {
      'fr': 'kcal',
      'en': 'kcal',
      'de': 'kcal',
    },
    'carbohydrates': {
      'fr': 'Glucides',
      'en': 'Carbs',
      'de': 'Kohlenhydrate',
    },
    'consumed': {
      'fr': 'Consommé',
      'en': 'Consumed',
      'de': 'Konsumiert',
    },
    'percent_of_goal_achieved': {
      'fr': '{percent}% de l\'objectif',
      'en': '{percent}% of goal',
      'de': '{percent}% des Ziels',
    },
    'dashboard': {
      'fr': 'Tableau de bord',
      'en': 'Dashboard',
      'de': 'Übersicht',
    },
    'journal': {
      'fr': 'Journal',
      'en': 'Diary',
      'de': 'Tagebuch',
    },
    'recipes': {
      'fr': 'Recettes',
      'en': 'Recipes',
      'de': 'Rezepte',
    },
    'add_to_existing_meal': {
      'fr': 'Ajouter à un repas existant',
      'en': 'Add to existing meal',
      'de': 'Zu bestehender Mahlzeit hinzufügen',
    },
    'choose_from_todays_meals': {
      'fr': 'Choisir parmi vos repas d\'aujourd\'hui',
      'en': 'Choose from your today\'s meals',
      'de': 'Aus heutigen Mahlzeiten wählen',
    },
    'create_new_meal': {
      'fr': 'Créer un nouveau repas',
      'en': 'Create new meal',
      'de': 'Neue Mahlzeit erstellen',
    },
    'choose_meal_type_to_create': {
      'fr': 'Choisir le type de repas à créer',
      'en': 'Choose meal type to create',
      'de': 'Wählen Sie den zu erstellenden Mahlzeittyp',
    },
    'choose_meal': {
      'fr': 'Choisir un repas',
      'en': 'Choose a meal',
      'de': 'Mahlzeit wählen',
    },
    'scan_barcode': {
      'fr': 'Scanner un code-barres',
      'en': 'Scan barcode',
      'de': 'Barcode scannen',
    },
    'food_items': {
      'fr': 'aliment(s)',
      'en': 'food item(s)',
      'de': 'Lebensmittel',
    },
    'ai_tip': {
      'fr': 'Conseil du Coach Ryze',
      'en': 'Coach Ryze Tip',
      'de': 'Coach Ryze Tipp',
    },
    'ai_tip_hydration': {
      'fr':
          '💡 Astuce : Buvez un verre d\'eau avant chaque repas pour une meilleure digestion et satiété.',
      'en':
          '💡 Tip: Drink a glass of water before each meal for better digestion and satiety.',
      'de':
          '💡 Tipp: Trinken Sie vor jeder Mahlzeit ein Glas Wasser für bessere Verdauung und Sättigung.',
    },
    'ai_tip_timing': {
      'fr':
          '⏰ Timing parfait : Consommez vos protéines dans les 30 minutes après l\'entraînement.',
      'en':
          '⏰ Perfect timing: Consume your proteins within 30 minutes after training.',
      'de':
          '⏰ Perfektes Timing: Nehmen Sie Ihre Proteine innerhalb von 30 Minuten nach dem Training zu sich.',
    },
    'ai_tip_balance': {
      'fr':
          '⚖️ Équilibre : Votre ratio protéines/glucides est optimal pour votre objectif.',
      'en': '⚖️ Balance: Your protein/carb ratio is optimal for your goal.',
      'de':
          '⚖️ Balance: Ihr Protein/Kohlenhydrat-Verhältnis ist optimal für Ihr Ziel.',
    },
    'add_water': {
      'fr': 'Ajouter de l\'eau',
      'en': 'Add water',
      'de': 'Wasser hinzufügen',
    },
    'custom_amount': {
      'fr': 'Quantité personnalisée',
      'en': 'Custom amount',
      'de': 'Benutzerdefinierte Menge',
    },
    'enter_amount_ml': {
      'fr': 'Entrez une quantité en ml',
      'en': 'Enter an amount in ml',
      'de': 'Geben Sie eine Menge in ml ein',
    },
    'one_glass': {
      'fr': '1 verre',
      'en': '1 glass',
      'de': '1 Glas',
    },
    'one_bottle': {
      'fr': '1 gourde',
      'en': '1 bottle',
      'de': '1 Flasche',
    },
    'one_liter': {
      'fr': '1 litre',
      'en': '1 liter',
      'de': '1 Liter',
    },
    'water_added_success': {
      'fr': '{amount} ml d\'eau ajoutés ! 💧',
      'en': '{amount} ml of water added! 💧',
      'de': '{amount} ml Wasser hinzugefügt! 💧',
    },
    'error_adding_water': {
      'fr': 'Erreur lors de l\'ajout d\'eau',
      'en': 'Error adding water',
      'de': 'Fehler beim Hinzufügen von Wasser',
    },
    'must_be_logged_in_water': {
      'fr': 'Vous devez être connecté pour enregistrer l\'hydratation',
      'en': 'You must be logged in to record hydration',
      'de': 'Sie müssen angemeldet sein, um die Flüssigkeitszufuhr zu erfassen',
    },
    'search_food': {
      'fr': 'Chercher dans la base',
      'en': 'Search database',
      'de': 'Datenbank durchsuchen',
    },
    'search_food_placeholder': {
      'fr': 'Rechercher un aliment...',
      'en': 'Search for food...',
      'de': 'Lebensmittel suchen...',
    },
    'create_food': {
      'fr': 'Créer un aliment',
      'en': 'Create food',
      'de': 'Lebensmittel erstellen',
    },
    'create_custom_food_desc': {
      'fr': 'Créez votre propre aliment personnalisé',
      'en': 'Create your own custom food',
      'de': 'Erstellen Sie Ihr eigenes Lebensmittel',
    },
    'frequently_used_foods': {
      'fr': 'Aliments fréquemment utilisés',
      'en': 'Frequently used foods',
      'de': 'Häufig verwendete Lebensmittel',
    },
    'no_food_found': {
      'fr': 'Aucun aliment trouvé pour "{query}"',
      'en': 'No food found for "{query}"',
      'de': 'Kein Lebensmittel gefunden für "{query}"',
    },
    'type_to_search': {
      'fr':
          'Tapez pour rechercher un aliment\nou créez votre propre aliment personnalisé',
      'en': 'Type to search for food\nor create your own custom food',
      'de':
          'Tippen Sie, um nach Lebensmitteln zu suchen\noder erstellen Sie Ihr eigenes Lebensmittel',
    },
    'no_food_available': {
      'fr': 'Aucun aliment disponible',
      'en': 'No food available',
      'de': 'Kein Lebensmittel verfügbar',
    },
    'start_adding_foods': {
      'fr':
          'Commencez à ajouter des aliments à vos repas\npour voir vos suggestions ici',
      'en': 'Start adding foods to your meals\nto see your suggestions here',
      'de':
          'Fügen Sie Lebensmittel zu Ihren Mahlzeiten hinzu\num Ihre Vorschläge hier zu sehen',
    },
    'enter_food_name': {
      'fr': 'Veuillez entrer un nom pour l\'aliment.',
      'en': 'Please enter a name for the food.',
      'de': 'Bitte geben Sie einen Namen für das Lebensmittel ein.',
    },
    'enter_nutrients': {
      'fr':
          'Veuillez entrer au moins une valeur nutritionnelle (protéines, glucides ou lipides).',
      'en':
          'Please enter at least one nutritional value (protein, carbs, or fats).',
      'de':
          'Bitte geben Sie mindestens einen Nährwert ein (Protein, Kohlenhydrate oder Fette).',
    },
    'error_creating_food': {
      'fr': 'Erreur lors de la création de l\'aliment',
      'en': 'Error creating food',
      'de': 'Fehler beim Erstellen des Lebensmittels',
    },
    'food_name': {
      'fr': 'Nom de l\'aliment',
      'en': 'Food name',
      'de': 'Lebensmittelname',
    },
    'food_name_placeholder': {
      'fr': 'Ex: Pomme, Pain complet...',
      'en': 'Ex: Apple, Whole wheat bread...',
      'de': 'z.B.: Apfel, Vollkornbrot...',
    },
    'nutritional_info': {
      'fr': 'Informations nutritionnelles',
      'en': 'Nutritional information',
      'de': 'Nährwertinformationen',
    },
    'per_100g': {
      'fr': 'pour 100g',
      'en': 'per 100g',
      'de': 'pro 100g',
    },
    'per_100ml': {
      'fr': 'pour 100ml',
      'en': 'per 100ml',
      'de': 'pro 100ml',
    },
    'per_serving': {
      'fr': 'par portion',
      'en': 'per serving',
      'de': 'pro Portion',
    },
    'per_spoon': {
      'fr': 'par cuillère',
      'en': 'per spoon',
      'de': 'pro Löffel',
    },
    'per_unit': {
      'fr': 'par unité',
      'en': 'per unit',
      'de': 'pro Stück',
    },
    'calculated_calories': {
      'fr': 'Calories calculées : {calories} kcal',
      'en': 'Calculated calories: {calories} kcal',
      'de': 'Berechnete Kalorien: {calories} kcal',
    },
    'serving': {
      'fr': 'portion',
      'en': 'serving',
      'de': 'Portion',
    },
    'spoon': {
      'fr': 'cuillère',
      'en': 'spoon',
      'de': 'Löffel',
    },
    'unit': {
      'fr': 'unité',
      'en': 'unit',
      'de': 'Stück',
    },
    'add_food_title': {
      'fr': 'Ajouter "{foodName}"',
      'en': 'Add "{foodName}"',
      'de': '"{foodName}" hinzufügen',
    },
    'where_add_food': {
      'fr': 'Où souhaitez-vous ajouter cet aliment ?',
      'en': 'Where would you like to add this food?',
      'de': 'Wo möchten Sie dieses Lebensmittel hinzufügen?',
    },
    'choose_from_daily_meals': {
      'fr': 'Choisir parmi vos repas du jour',
      'en': 'Choose from your daily meals',
      'de': 'Aus Ihren Tagesmahlzeiten wählen',
    },
    'meal_type_options': {
      'fr': 'Petit-déjeuner, déjeuner, dîner ou collation',
      'en': 'Breakfast, lunch, dinner or snack',
      'de': 'Frühstück, Mittagessen, Abendessen oder Snack',
    },
    'food_item_count': {
      'fr': '{count} aliment{plural}',
      'en': '{count} food item{plural}',
      'de': '{count} Lebensmittel',
    },
    'error_user_not_connected': {
      'fr': 'Erreur: utilisateur non connecté',
      'en': 'Error: user not connected',
      'de': 'Fehler: Benutzer nicht angemeldet',
    },
    'recipe_added_success': {
      'fr': 'Recette "{recipeName}" ajoutée avec succès !',
      'en': 'Recipe "{recipeName}" added successfully!',
      'de': 'Rezept "{recipeName}" erfolgreich hinzugefügt!',
    },
    'recipe_added_to_new_meal': {
      'fr': 'Recette "{recipeName}" ajoutée au nouveau {mealType} !',
      'en': 'Recipe "{recipeName}" added to new {mealType}!',
      'de': 'Rezept "{recipeName}" zu neuem {mealType} hinzugefügt!',
    },
    'food_added_to_meal': {
      'fr': '{foodName} ajouté au {mealName}',
      'en': '{foodName} added to {mealName}',
      'de': '{foodName} zu {mealName} hinzugefügt',
    },
    'food_added_success': {
      'fr': '{foodName} ajouté au repas avec succès !',
      'en': '{foodName} added to meal successfully!',
      'de': '{foodName} erfolgreich zur Mahlzeit hinzugefügt!',
    },
    'food_added_to_new_meal': {
      'fr': '{foodName} ajouté à un nouveau {mealType}',
      'en': '{foodName} added to new {mealType}',
      'de': '{foodName} zu neuem {mealType} hinzugefügt',
    },
    'error_creating_meal': {
      'fr': 'Erreur lors de la création du repas',
      'en': 'Error creating meal',
      'de': 'Fehler beim Erstellen der Mahlzeit',
    },
    'error_generating_meal_id': {
      'fr': 'Erreur lors de la génération de l\'ID du repas',
      'en': 'Error generating meal ID',
      'de': 'Fehler beim Generieren der Mahlzeit-ID',
    },
    'error_adding_recipe': {
      'fr': 'Erreur lors de l\'ajout de la recette',
      'en': 'Error adding recipe',
      'de': 'Fehler beim Hinzufügen des Rezepts',
    },
    'error_adding_food': {
      'fr': 'Erreur lors de l\'ajout de l\'aliment: {error}',
      'en': 'Error adding food: {error}',
      'de': 'Fehler beim Hinzufügen des Lebensmittels: {error}',
    },
    'back': {
      'fr': 'Retour',
      'en': 'Back',
      'de': 'Zurück',
    },
    'continue': {
      'fr': 'Continuer',
      'en': 'Continue',
      'de': 'Weiter',
    },
    'complete_profile_title': {
      'fr': 'Complétez votre profil',
      'en': 'Complete your profile',
      'de': 'Vervollständigen Sie Ihr Profil',
    },
    'complete_profile_subtitle': {
      'fr':
          'Nous avons besoin de votre nom pour personnaliser votre expérience',
      'en': 'We need your name to personalize your experience',
      'de': 'Wir benötigen Ihren Namen, um Ihr Erlebnis zu personalisieren',
    },
    'complete_profile_privacy': {
      'fr': 'Vos informations sont sécurisées et ne seront jamais partagées',
      'en': 'Your information is secure and will never be shared',
      'de': 'Ihre Daten sind sicher und werden niemals weitergegeben',
    },
    'create_new_meal_title': {
      'fr': 'Créer un nouveau repas',
      'en': 'Create new meal',
      'de': 'Neue Mahlzeit erstellen',
    },
    'ai_scanner_title': {
      'fr': 'Scanner avec Coach Ryze',
      'en': 'Scan with Coach Ryze',
      'de': 'Mit Coach Ryze scannen',
    },
    'coach_detected_dish_name': {
      'fr': 'Nom du plat détecté par Coach Ryze',
      'en': 'Dish name detected by Coach Ryze',
      'de': 'Von Coach Ryze erkannter Gerichtname',
    },
    'coach_detected_dish': {
      'fr': 'Plat détecté par Coach Ryze',
      'en': 'Dish detected by Coach Ryze',
      'de': 'Von Coach Ryze erkanntes Gericht',
    },
    'coach_analysis': {
      'fr': 'Analyse Coach Ryze',
      'en': 'Coach Ryze Analysis',
      'de': 'Coach Ryze Analyse',
    },
    'scan_lunch_with_coach': {
      'fr': 'C\'est l\'heure ! Scanne ton déjeuner avec Coach Ryze.',
      'en': 'It\'s time! Scan your lunch with Coach Ryze.',
      'de': 'Es ist Zeit! Scanne dein Mittagessen mit Coach Ryze.',
    },
    'unlimited_photos_coach': {
      'fr': 'Photos illimitées + Coach Ryze personnel',
      'en': 'Unlimited photos + Personal Coach Ryze',
      'de': 'Unbegrenzte Fotos + Persönlicher Coach Ryze',
    },
    // Meal descriptions
    'breakfast_description': {
      'fr': 'Repas du matin',
      'en': 'Morning meal',
      'de': 'Morgenmahlzeit',
    },
    'lunch_description': {
      'fr': 'Repas du midi',
      'en': 'Midday meal',
      'de': 'Mittagsmahlzeit',
    },
    'dinner_description': {
      'fr': 'Repas du soir',
      'en': 'Evening meal',
      'de': 'Abendmahlzeit',
    },
    'snack_description': {
      'fr': 'En-cas entre les repas',
      'en': 'Snack between meals',
      'de': 'Snack zwischen den Mahlzeiten',
    },
    // Food status badges
    'custom': {
      'fr': 'Personnalisé',
      'en': 'Custom',
      'de': 'Benutzerdefiniert',
    },
    'scanned': {
      'fr': 'Scanné',
      'en': 'Scanned',
      'de': 'Gescannt',
    },
    'modified': {
      'fr': 'Modifié',
      'en': 'Modified',
      'de': 'Geändert',
    },
    // Food details screen
    'quantity': {
      'fr': 'Quantité',
      'en': 'Quantity',
      'de': 'Menge',
    },
    'confirm': {
      'fr': 'Confirmer',
      'en': 'Confirm',
      'de': 'Bestätigen',
    },
    // Recipe filters modal
    'filters': {
      'fr': 'Filtres',
      'en': 'Filters',
      'de': 'Filter',
    },
    'clear_all': {
      'fr': 'Effacer tout',
      'en': 'Clear all',
      'de': 'Alles löschen',
    },
    'apply_filters': {
      'fr': 'Valider',
      'en': 'Apply',
      'de': 'Anwenden',
    },
    'recommended_recipes': {
      'fr': 'Recettes recommandées',
      'en': 'Recommended recipes',
      'de': 'Empfohlene Rezepte',
    },
    'results': {
      'fr': 'Résultats',
      'en': 'Results',
      'de': 'Ergebnisse',
    },
    'all_recipes': {
      'fr': 'Toutes les recettes',
      'en': 'All recipes',
      'de': 'Alle Rezepte',
    },
    'search_recipe_placeholder': {
      'fr': 'Rechercher une recette...',
      'en': 'Search for a recipe...',
      'de': 'Nach einem Rezept suchen...',
    },
    'preparation_steps': {
      'fr': 'Étapes de préparation',
      'en': 'Preparation steps',
      'de': 'Zubereitungsschritte',
    },
    'nutrition_tab': {
      'fr': 'Nutrition',
      'en': 'Nutrition',
      'de': 'Ernährung',
    },
    'home_tab': {
      'fr': 'Accueil',
      'en': 'Home',
      'de': 'Startseite',
    },
    'sport_tab': {
      'fr': 'Sport',
      'en': 'Sport',
      'de': 'Sport',
    },
    'sport': {
      'fr': 'Sport',
      'en': 'Sport',
      'de': 'Sport',
    },
    'progress_tab': {
      'fr': 'Progrès',
      'en': 'Progress',
      'de': 'Fortschritt',
    },
    'objectives': {
      'fr': 'objectifs',
      'en': 'goals',
      'de': 'Ziele',
    },
    'must_be_connected_add_food': {
      'fr': 'Vous devez être connecté pour ajouter un aliment',
      'en': 'You must be logged in to add food',
      'de': 'Sie müssen angemeldet sein, um Lebensmittel hinzuzufügen',
    },
    'add_food_to_meal': {
      'fr': 'Ajouter "%s" à un repas',
      'en': 'Add "%s" to a meal',
      'de': '"%s" zu einer Mahlzeit hinzufügen',
    },
    'no_meals_recorded': {
      'fr': 'Aucun repas enregistré',
      'en': 'No meals recorded',
      'de': 'Keine Mahlzeiten erfasst',
    },
    'add_first_meal_message': {
      'fr':
          'Ajoutez votre premier repas pour commencer à suivre votre nutrition.',
      'en': 'Add your first meal to start tracking your nutrition.',
      'de':
          'Fügen Sie Ihre erste Mahlzeit hinzu, um Ihre Ernährung zu verfolgen.',
    },
    'add_food_button': {
      'fr': 'Ajouter un aliment',
      'en': 'Add food',
      'de': 'Lebensmittel hinzufügen',
    },
    'yesterday': {
      'fr': 'Hier',
      'en': 'Yesterday',
      'de': 'Gestern',
    },
    'tomorrow': {
      'fr': 'Demain',
      'en': 'Tomorrow',
      'de': 'Morgen',
    },
    'calorie_summary': {
      'fr': 'Bilan calorique',
      'en': 'Calorie summary',
      'de': 'Kalorienbilanz',
    },
    // Page calendrier nutritionnel
    'nutrition_calendar': {
      'fr': 'Calendrier nutritionnel',
      'en': 'Nutrition calendar',
      'de': 'Ernährungskalender',
    },
    'successful_days': {
      'fr': 'Jours réussis',
      'en': 'Successful days',
      'de': 'Erfolgreiche Tage',
    },
    'average_calories': {
      'fr': 'Moy. calories',
      'en': 'Avg. calories',
      'de': 'Durchschn. Kalorien',
    },
    'daily_calorie_goal_reached': {
      'fr': 'Atteinte de l objectif calorique de la journée',
      'en': 'Daily calorie goal achievement',
      'de': 'Erreichung des täglichen Kalorienziels',
    },
    // Jours de la semaine abrégés
    'mon_short': {
      'fr': 'Lun',
      'en': 'Mon',
      'de': 'Mo',
    },
    'tue_short': {
      'fr': 'Mar',
      'en': 'Tue',
      'de': 'Di',
    },
    'wed_short': {
      'fr': 'Mer',
      'en': 'Wed',
      'de': 'Mi',
    },
    'thu_short': {
      'fr': 'Jeu',
      'en': 'Thu',
      'de': 'Do',
    },
    'fri_short': {
      'fr': 'Ven',
      'en': 'Fri',
      'de': 'Fr',
    },
    'sat_short': {
      'fr': 'Sam',
      'en': 'Sat',
      'de': 'Sa',
    },
    'sun_short': {
      'fr': 'Dim',
      'en': 'Sun',
      'de': 'So',
    },
    // Sport section translations
    'sport_dashboard_title': {
      'fr': 'Tableau de bord',
      'en': 'Dashboard',
      'de': 'Übersicht',
    },
    'sport_objectives_text': {
      'fr': 'objectifs',
      'en': 'goals',
      'de': 'Ziele',
    },
    'sport_days_text': {
      'fr': 'jours',
      'en': 'days',
      'de': 'Tage',
    },
    'sport_burned': {
      'fr': 'Brûlées',
      'en': 'Burned',
      'de': 'Verbrannt',
    },
    'sport_average_per_day': {
      'fr': 'Moyenne / jour',
      'en': 'Average / day',
      'de': 'Durchschnitt / Tag',
    },
    'sport_milestones_reached': {
      'fr': 'Paliers franchis',
      'en': 'Milestones reached',
      'de': 'Erreichte Meilensteine',
    },
    'sport_progress': {
      'fr': 'Progression',
      'en': 'Progress',
      'de': 'Fortschritt',
    },
    'sport_sessions_this_week': {
      'fr': 'Séances cette semaine',
      'en': 'Sessions this week',
      'de': 'Einheiten diese Woche',
    },
    'sport_consecutive_weeks': {
      'fr': 'Semaines consécutives',
      'en': 'Consecutive weeks',
      'de': 'Aufeinanderfolgende Wochen',
    },
    'sport_total_time_week': {
      'fr': 'Temps total cette semaine',
      'en': 'Total time this week',
      'de': 'Gesamtzeit diese Woche',
    },
    'sport_recent_sessions': {
      'fr': 'Séances récentes',
      'en': 'Recent sessions',
      'de': 'Letzte Trainingseinheiten',
    },
    'sport_todays_activities': {
      'fr': 'Activités du jour',
      'en': 'Today\'s activities',
      'de': 'Heutige Aktivitäten',
    },
    'sport_start_activity': {
      'fr': 'Démarrer une activité',
      'en': 'Start an activity',
      'de': 'Aktivität starten',
    },
    'sport_no_activity_today': {
      'fr': 'Aucune activité aujourd\'hui',
      'en': 'No activity today',
      'de': 'Heute keine Aktivität',
    },
    'sport_rest_day': {
      'fr': 'Repos',
      'en': 'Rest',
      'de': 'Ruhetag',
    },
    'sport_kcal_to_next_milestone': {
      'fr': 'Encore {kcal} kcal pour atteindre ton prochain palier',
      'en': 'Still {kcal} kcal to reach your next milestone',
      'de': 'Noch {kcal} kcal bis zum nächsten Meilenstein',
    },
    'sport_milestone_reached': {
      'fr': 'Palier atteint ! Félicitations 🎉',
      'en': 'Milestone reached! Congratulations 🎉',
      'de': 'Meilenstein erreicht! Herzlichen Glückwunsch 🎉',
    },
    'sport_muscle_training': {
      'fr': 'Musculation',
      'en': 'Workout',
      'de': 'Krafttraining',
    },
    'sport_cardio': {
      'fr': 'Cardio',
      'en': 'Cardio',
      'de': 'Cardio',
    },
    'sport_choose_activity': {
      'fr': 'Choisissez votre activité cardio',
      'en': 'Choose your cardio activity',
      'de': 'Wählen Sie Ihre Cardio-Aktivität',
    },
    'sport_choose_objective': {
      'fr': 'Choisissez votre objectif',
      'en': 'Choose your objective',
      'de': 'Wählen Sie Ihr Ziel',
    },
    'sport_free_session': {
      'fr': 'Séance libre',
      'en': 'Free session',
      'de': 'Freie Einheit',
    },
    'sport_no_specific_goal': {
      'fr': 'Pas d\'objectif spécifique',
      'en': 'No specific goal',
      'de': 'Kein bestimmtes Ziel',
    },
    'sport_time_objective': {
      'fr': 'Objectif temps',
      'en': 'Time objective',
      'de': 'Zeitziel',
    },
    'sport_30_minutes': {
      'fr': '30 minutes',
      'en': '30 minutes',
      'de': '30 Minuten',
    },
    'sport_distance_objective': {
      'fr': 'Objectif distance',
      'en': 'Distance objective',
      'de': 'Entfernungsziel',
    },
    'sport_5_km': {
      'fr': '5 km',
      'en': '5 km',
      'de': '5 km',
    },
    'sport_choose_format': {
      'fr': 'Choisissez votre format',
      'en': 'Choose your format',
      'de': 'Wählen Sie Ihr Format',
    },
    'sport_hiit': {
      'fr': 'HIIT',
      'en': 'HIIT',
      'de': 'HIIT',
    },
    'sport_choose_hiit_workout': {
      'fr': 'Choisissez votre workout HIIT',
      'en': 'Choose your HIIT workout',
      'de': 'Wählen Sie Ihr HIIT-Training',
    },
    'sport_track_session': {
      'fr': 'Tracker ma séance',
      'en': 'Track my session',
      'de': 'Meine Einheit aufzeichnen',
    },
    'sport_declare_session': {
      'fr': 'Déclarer ma séance',
      'en': 'Log my session',
      'de': 'Meine Einheit eintragen',
    },
    'sport_beginner_hiit': {
      'fr': 'HIIT débutant',
      'en': 'Beginner HIIT',
      'de': 'HIIT für Anfänger',
    },
    'sport_intense_hiit': {
      'fr': 'HIIT intense',
      'en': 'Intense HIIT',
      'de': 'Intensives HIIT',
    },
    'sport_tabata': {
      'fr': 'Tabata',
      'en': 'Tabata',
      'de': 'Tabata',
    },
    'sport_15min_hiit_desc': {
      'fr': '15 min - 30s effort / 30s repos',
      'en': '15 min - 30s work / 30s rest',
      'de': '15 Min - 30s Arbeit / 30s Pause',
    },
    'sport_20min_hiit_desc': {
      'fr': '20 min - 45s effort / 15s repos',
      'en': '20 min - 45s work / 15s rest',
      'de': '20 Min - 45s Arbeit / 15s Pause',
    },
    'sport_4min_tabata_desc': {
      'fr': '4 min - 20s effort / 10s repos',
      'en': '4 min - 20s work / 10s rest',
      'de': '4 Min - 20s Arbeit / 10s Pause',
    },
    'sport_loading_data_error': {
      'fr': 'Erreur de chargement des données',
      'en': 'Data loading error',
      'de': 'Fehler beim Laden der Daten',
    },
    // Sport calendar translations
    'sport_calendar_title': {
      'fr': 'Calendrier sportif',
      'en': 'Sports Calendar',
      'de': 'Sportkalender',
    },
    'sport_calendar_subtitle': {
      'fr': 'Suivi de vos activités sportives',
      'en': 'Track your sports activities',
      'de': 'Verfolgen Sie Ihre Sportaktivitäten',
    },
    'sport_active_days': {
      'fr': 'Jours actifs',
      'en': 'Active days',
      'de': 'Aktive Tage',
    },
    'sport_legend': {
      'fr': 'Légende',
      'en': 'Legend',
      'de': 'Legende',
    },
    'sport_rest': {
      'fr': 'Repos',
      'en': 'Rest',
      'de': 'Ruhe',
    },
    // Months for calendar
    'month_january': {
      'fr': 'Janvier',
      'en': 'January',
      'de': 'Januar',
    },
    'month_february': {
      'fr': 'Février',
      'en': 'February',
      'de': 'Februar',
    },
    'month_march': {
      'fr': 'Mars',
      'en': 'March',
      'de': 'März',
    },
    'month_april': {
      'fr': 'Avril',
      'en': 'April',
      'de': 'April',
    },
    'month_may': {
      'fr': 'Mai',
      'en': 'May',
      'de': 'Mai',
    },
    'month_june': {
      'fr': 'Juin',
      'en': 'June',
      'de': 'Juni',
    },
    'month_july': {
      'fr': 'Juillet',
      'en': 'July',
      'de': 'Juli',
    },
    'month_august': {
      'fr': 'Août',
      'en': 'August',
      'de': 'August',
    },
    'month_september': {
      'fr': 'Septembre',
      'en': 'September',
      'de': 'September',
    },
    'month_october': {
      'fr': 'Octobre',
      'en': 'October',
      'de': 'Oktober',
    },
    'month_november': {
      'fr': 'Novembre',
      'en': 'November',
      'de': 'November',
    },
    'month_december': {
      'fr': 'Décembre',
      'en': 'December',
      'de': 'Dezember',
    },
    // Days of week (full names)
    'day_monday': {
      'fr': 'Lundi',
      'en': 'Monday',
      'de': 'Montag',
    },
    'day_tuesday': {
      'fr': 'Mardi',
      'en': 'Tuesday',
      'de': 'Dienstag',
    },
    'day_wednesday': {
      'fr': 'Mercredi',
      'en': 'Wednesday',
      'de': 'Mittwoch',
    },
    'day_thursday': {
      'fr': 'Jeudi',
      'en': 'Thursday',
      'de': 'Donnerstag',
    },
    'day_friday': {
      'fr': 'Vendredi',
      'en': 'Friday',
      'de': 'Freitag',
    },
    'day_saturday': {
      'fr': 'Samedi',
      'en': 'Saturday',
      'de': 'Samstag',
    },
    'day_sunday': {
      'fr': 'Dimanche',
      'en': 'Sunday',
      'de': 'Sonntag',
    },
    // Short day abbreviations for calendar
    'day_mon': {
      'fr': 'Lun',
      'en': 'Mon',
      'de': 'Mo',
    },
    'day_tue': {
      'fr': 'Mar',
      'en': 'Tue',
      'de': 'Di',
    },
    'day_wed': {
      'fr': 'Mer',
      'en': 'Wed',
      'de': 'Mi',
    },
    'day_thu': {
      'fr': 'Jeu',
      'en': 'Thu',
      'de': 'Do',
    },
    'day_fri': {
      'fr': 'Ven',
      'en': 'Fri',
      'de': 'Fr',
    },
    'day_sat': {
      'fr': 'Sam',
      'en': 'Sat',
      'de': 'Sa',
    },
    'day_sun': {
      'fr': 'Dim',
      'en': 'Sun',
      'de': 'So',
    },
    // Cardio translations
    'cardio_this_week': {
      'fr': 'Cette semaine',
      'en': 'This week',
      'de': 'Diese Woche',
    },
    'cardio_distance': {
      'fr': 'Distance',
      'en': 'Distance',
      'de': 'Distanz',
    },
    'cardio_time': {
      'fr': 'Temps',
      'en': 'Time',
      'de': 'Zeit',
    },
    'cardio_calories': {
      'fr': 'Calories',
      'en': 'Calories',
      'de': 'Kalorien',
    },
    'cardio_no_data_available': {
      'fr': 'Aucune donnée disponible',
      'en': 'No data available',
      'de': 'Keine Daten verfügbar',
    },
    'cardio_choose_activity': {
      'fr': 'Choisir une activité',
      'en': 'Choose an activity',
      'de': 'Aktivität wählen',
    },
    'cardio_choose_recording_method': {
      'fr': 'Choisissez votre méthode d\'enregistrement',
      'en': 'Choose your recording method',
      'de': 'Wähle deine Aufnahmemethode',
    },
    'cardio_no_activities_available': {
      'fr': 'Aucune activité disponible',
      'en': 'No activities available',
      'de': 'Keine Aktivitäten verfügbar',
    },
    'cardio_no_activity_available': {
      'fr': 'Aucune activité disponible',
      'en': 'No activity available',
      'de': 'Keine Aktivität verfügbar',
    },
    'cardio_last_session': {
      'fr': 'Dernière séance',
      'en': 'Last session',
      'de': 'Letzte Sitzung',
    },
    'cardio_no_session_recorded': {
      'fr': 'Aucune séance enregistrée',
      'en': 'No session recorded',
      'de': 'Keine Sitzung aufgezeichnet',
    },
    'cardio_duration': {
      'fr': 'Durée',
      'en': 'Duration',
      'de': 'Dauer',
    },
    'cardio_pace': {
      'fr': 'Allure',
      'en': 'Pace',
      'de': 'Tempo',
    },
    'cardio_week_sessions': {
      'fr': 'Vos séances de la semaine',
      'en': 'Your sessions this week',
      'de': 'Deine Sitzungen diese Woche',
    },
    'cardio_no_session_this_week': {
      'fr': 'Aucune séance cette semaine',
      'en': 'No sessions this week',
      'de': 'Keine Einheiten diese Woche',
    },
    'cardio_view_journal': {
      'fr': 'Voir tout mon journal de séances',
      'en': 'View my full session log',
      'de': 'Mein vollständiges Trainingsprotokoll anzeigen',
    },
    'workout_view_journal': {
      'fr': 'Voir tout mon journal de séances',
      'en': 'View my full session log',
      'de': 'Mein vollständiges Trainingsprotokoll anzeigen',
    },
    'cardio_today': {
      'fr': 'Aujourd\'hui',
      'en': 'Today',
      'de': 'Heute',
    },
    'cardio_yesterday': {
      'fr': 'Hier',
      'en': 'Yesterday',
      'de': 'Gestern',
    },
    'cardio_days_ago': {
      'fr': 'Il y a {count} jours',
      'en': '{count} days ago',
      'de': 'Vor {count} Tagen',
    },
    'cardio_weeks_ago': {
      'fr': 'Il y a {count} semaine{plural}',
      'en': '{count} week{plural} ago',
      'de': 'Vor {count} Woche{plural}',
    },
    // Cardio modals
    'cardio_choose_session_format': {
      'fr': 'Choisir un format de séance',
      'en': 'Choose a session format',
      'de': 'Trainingsformat wählen',
    },
    'cardio_how_record_session': {
      'fr': 'Comment veux-tu enregistrer\nta séance ?',
      'en': 'How do you want to record\nyour session?',
      'de': 'Wie möchtest du deine\nEinheit aufzeichnen?',
    },
    'cardio_start_session': {
      'fr': 'Démarrer la séance',
      'en': 'Start session',
      'de': 'Einheit starten',
    },
    'cardio_declare_session': {
      'fr': 'Déclarer la séance',
      'en': 'Declare session',
      'de': 'Einheit eintragen',
    },
    'cardio_track_my_session': {
      'fr': 'Tracker ma séance',
      'en': 'Track my session',
      'de': 'Meine Einheit aufzeichnen',
    },
    'cardio_declare_my_session': {
      'fr': 'Déclarer ma séance',
      'en': 'Declare my session',
      'de': 'Meine Einheit eintragen',
    },
    'cardio_validate': {
      'fr': 'Valider',
      'en': 'Validate',
      'de': 'Bestätigen',
    },
    'tracking_web_limitation_title': {
      'fr': 'Suivi GPS limité sur web',
      'en': 'Limited GPS tracking on web',
      'de': 'Eingeschränktes GPS-Tracking im Web',
    },
    'tracking_web_limitation_description': {
      'fr':
          'Le suivi GPS en temps réel fonctionne mieux sur mobile. Sur web, l\'app utilise un mode simulation pour demo.',
      'en':
          'Real-time GPS tracking works better on mobile. On web, the app uses simulation mode for demo.',
      'de':
          'GPS-Tracking in Echtzeit funktioniert besser auf dem Handy. Im Web verwendet die App einen Simulationsmodus zur Demo.',
    },
    'tracking_web_recommendation': {
      'fr':
          'Pour un suivi précis, utilisez l\'app mobile ou la saisie manuelle après votre séance.',
      'en':
          'For accurate tracking, use the mobile app or manual entry after your session.',
      'de':
          'Für genaues Tracking nutze die mobile App oder die manuelle Eingabe nach deiner Einheit.',
    },
    'tracking_understood': {
      'fr': 'Compris',
      'en': 'Understood',
      'de': 'Verstanden',
    },
    'training_choose_type': {
      'fr': 'Choisissez votre type d\'entraînement',
      'en': 'Choose your training type',
      'de': 'Wähle deine Trainingsart',
    },
    'training_cardio': {
      'fr': 'Cardio',
      'en': 'Cardio',
      'de': 'Cardio',
    },
    'training_cardio_subtitle': {
      'fr': 'Course, vélo, HIIT...',
      'en': 'Running, biking, HIIT...',
      'de': 'Laufen, Radfahren, HIIT...',
    },
    'training_musculation': {
      'fr': 'Musculation',
      'en': 'Weight Training',
      'de': 'Krafttraining',
    },
    'training_musculation_subtitle': {
      'fr': 'Force, résistance...',
      'en': 'Strength, resistance...',
      'de': 'Kraft, Widerstand...',
    },
    // Activity configs
    'cardio_distance_question': {
      'fr': 'Quelle distance veux-tu parcourir ?',
      'en': 'What distance do you want to cover?',
      'de': 'Welche Distanz möchtest du zurücklegen?',
    },
    'cardio_duration_question': {
      'fr': 'Combien de temps veux-tu t\'entraîner ?',
      'en': 'How long do you want to train?',
      'de': 'Wie lange möchtest du trainieren?',
    },
    'cardio_hiit_params': {
      'fr': 'Paramètres de ton HIIT',
      'en': 'Your HIIT parameters',
      'de': 'Deine HIIT-Parameter',
    },
    'cardio_distance_hint': {
      'fr': 'Ex: 5',
      'en': 'Ex: 5',
      'de': 'z.B.: 5',
    },
    'cardio_duration_hint': {
      'fr': 'Ex: 30',
      'en': 'Ex: 30',
      'de': 'z.B.: 30',
    },
    'cardio_hiit_hint': {
      'fr': 'Durée totale en minutes',
      'en': 'Total duration in minutes',
      'de': 'Gesamtdauer in Minuten',
    },
    'cardio_km_unit': {
      'fr': 'km',
      'en': 'km',
      'de': 'km',
    },
    'cardio_min_unit': {
      'fr': 'min',
      'en': 'min',
      'de': 'Min',
    },
    // Cardio activity formats
    'cardio_free_session': {
      'fr': 'Course libre',
      'en': 'Free running',
      'de': 'Freies Laufen',
    },
    'cardio_free_session_desc': {
      'fr': 'Séance libre sans contrainte',
      'en': 'Free session without constraint',
      'de': 'Freies Training ohne Einschränkungen',
    },
    'cardio_distance_goal': {
      'fr': 'Objectif distance',
      'en': 'Distance goal',
      'de': 'Distanzziel',
    },
    'cardio_distance_goal_desc': {
      'fr': 'Atteindre une distance que tu définis',
      'en': 'Reach a distance you set',
      'de': 'Eine von dir festgelegte Distanz erreichen',
    },
    'cardio_duration_goal': {
      'fr': 'Objectif durée',
      'en': 'Duration goal',
      'de': 'Dauerziel',
    },
    'cardio_duration_goal_desc': {
      'fr': 'Courir pendant une durée que tu choisis',
      'en': 'Run for a duration you choose',
      'de': 'Laufen für eine Dauer deiner Wahl',
    },
    'cardio_interval_beginner': {
      'fr': 'Fractionné débutant',
      'en': 'Beginner intervals',
      'de': 'Anfänger-Intervalle',
    },
    'cardio_interval_beginner_desc': {
      'fr': '4x 1min rapide / 2min récup',
      'en': '4x 1min fast / 2min recovery',
      'de': '4x 1min schnell / 2min Erholung',
    },
    'cardio_interval_advanced': {
      'fr': 'Fractionné avancé',
      'en': 'Advanced intervals',
      'de': 'Fortgeschrittene Intervalle',
    },
    'cardio_interval_advanced_desc': {
      'fr': '6x 2min rapide / 1min récup',
      'en': '6x 2min fast / 1min recovery',
      'de': '6x 2min schnell / 1min Erholung',
    },
    'cardio_bike_free': {
      'fr': 'Vélo libre',
      'en': 'Free cycling',
      'de': 'Freies Radfahren',
    },
    'cardio_bike_free_desc': {
      'fr': 'Sortie vélo libre',
      'en': 'Free cycling session',
      'de': 'Freie Radfahrt',
    },
    'cardio_bike_distance': {
      'fr': 'Objectif distance',
      'en': 'Distance goal',
      'de': 'Distanzziel',
    },
    'cardio_bike_distance_desc': {
      'fr': 'Distance à atteindre que tu définis',
      'en': 'Distance to reach that you set',
      'de': 'Eine von dir festgelegte Distanz erreichen',
    },
    'cardio_bike_duration': {
      'fr': 'Objectif durée',
      'en': 'Duration goal',
      'de': 'Dauerziel',
    },
    'cardio_bike_duration_desc': {
      'fr': 'Durée que tu choisis',
      'en': 'Duration you choose',
      'de': 'Dauer deiner Wahl',
    },
    'cardio_hills': {
      'fr': 'Côtes',
      'en': 'Hills',
      'de': 'Hügel',
    },
    'cardio_hills_desc': {
      'fr': 'Entraînement en dénivelé',
      'en': 'Elevation training',
      'de': 'Höhentraining',
    },
    'cardio_walking_free': {
      'fr': 'Marche libre',
      'en': 'Free walking',
      'de': 'Freies Gehen',
    },
    'cardio_walking_free_desc': {
      'fr': 'Promenade libre',
      'en': 'Free walk',
      'de': 'Freier Spaziergang',
    },
    'cardio_walking_distance': {
      'fr': 'Objectif distance',
      'en': 'Distance goal',
      'de': 'Distanzziel',
    },
    'cardio_walking_distance_desc': {
      'fr': 'Distance à parcourir que tu définis',
      'en': 'Distance to cover that you set',
      'de': 'Eine von dir festgelegte Distanz zurücklegen',
    },
    'cardio_walking_duration': {
      'fr': 'Objectif durée',
      'en': 'Duration goal',
      'de': 'Dauerziel',
    },
    'cardio_walking_duration_desc': {
      'fr': 'Durée que tu choisis',
      'en': 'Duration you choose',
      'de': 'Dauer deiner Wahl',
    },
    'cardio_fast_walking': {
      'fr': 'Marche rapide',
      'en': 'Fast walking',
      'de': 'Schnelles Gehen',
    },
    'cardio_fast_walking_desc': {
      'fr': 'Allure soutenue',
      'en': 'Sustained pace',
      'de': 'Gleichmäßiges Tempo',
    },
    'cardio_hiit_beginner': {
      'fr': 'HIIT débutant',
      'en': 'Beginner HIIT',
      'de': 'HIIT für Anfänger',
    },
    'cardio_hiit_beginner_desc': {
      'fr': '15 min - 30s effort / 30s repos',
      'en': '15 min - 30s work / 30s rest',
      'de': '15 Min - 30s Arbeit / 30s Pause',
    },
    'cardio_hiit_intense': {
      'fr': 'HIIT intense',
      'en': 'Intense HIIT',
      'de': 'Intensives HIIT',
    },
    'cardio_hiit_intense_desc': {
      'fr': '20 min - 45s effort / 15s repos',
      'en': '20 min - 45s work / 15s rest',
      'de': '20 Min - 45s Arbeit / 15s Pause',
    },
    'cardio_tabata': {
      'fr': 'Tabata',
      'en': 'Tabata',
      'de': 'Tabata',
    },
    'cardio_tabata_desc': {
      'fr': '4 min - 20s effort / 10s repos',
      'en': '4 min - 20s work / 10s rest',
      'de': '4 Min - 20s Arbeit / 10s Pause',
    },
    'cardio_hiit_custom': {
      'fr': 'HIIT personnalisé',
      'en': 'Custom HIIT',
      'de': 'Benutzerdefiniertes HIIT',
    },
    'cardio_hiit_custom_desc': {
      'fr': 'Créer son propre timing',
      'en': 'Create your own timing',
      'de': 'Eigene Zeiten erstellen',
    },
    // Activity types
    'activity_running': {
      'fr': 'Course à pied',
      'en': 'Running',
      'de': 'Laufen',
    },
    'activity_bike': {
      'fr': 'Vélo',
      'en': 'Cycling',
      'de': 'Radfahren',
    },
    'activity_walking': {
      'fr': 'Marche',
      'en': 'Walking',
      'de': 'Gehen',
    },
    'activity_hiit': {
      'fr': 'HIIT',
      'en': 'HIIT',
      'de': 'HIIT',
    },
    // Session details
    'session_details_display': {
      'fr': 'Affichage des détails de la session',
      'en': 'Displaying session details',
      'de': 'Sitzungsdetails anzeigen',
    },
    'cardio_journal_opening': {
      'fr': 'Ouverture du journal cardio',
      'en': 'Opening cardio journal',
      'de': 'Cardio-Tagebuch öffnen',
    },
    // Manual entry screen
    'manual_entry_title': {
      'fr': 'Saisir',
      'en': 'Enter',
      'de': 'Eingeben',
    },
    'manual_session_date': {
      'fr': 'Date de la séance',
      'en': 'Session date',
      'de': 'Datum der Einheit',
    },
    'manual_session_duration': {
      'fr': 'Durée de la séance',
      'en': 'Session duration',
      'de': 'Dauer der Einheit',
    },
    'manual_distance_covered': {
      'fr': 'Distance parcourue',
      'en': 'Distance covered',
      'de': 'Zurückgelegte Distanz',
    },
    'manual_steps_count': {
      'fr': 'Nombre de pas',
      'en': 'Number of steps',
      'de': 'Anzahl der Schritte',
    },
    'manual_notes_optional': {
      'fr': 'Notes (optionnel)',
      'en': 'Notes (optional)',
      'de': 'Notizen (optional)',
    },
    'manual_hours': {
      'fr': 'Heures',
      'en': 'Hours',
      'de': 'Stunden',
    },
    'manual_minutes': {
      'fr': 'Minutes',
      'en': 'Minutes',
      'de': 'Minuten',
    },
    'manual_distance_km': {
      'fr': 'Distance',
      'en': 'Distance',
      'de': 'Distanz',
    },
    'manual_steps_label': {
      'fr': 'Nombre de pas',
      'en': 'Number of steps',
      'de': 'Anzahl der Schritte',
    },
    'manual_notes_placeholder': {
      'fr': 'Commentaires sur la séance...',
      'en': 'Comments about the session...',
      'de': 'Kommentare zur Einheit...',
    },
    'manual_save_session': {
      'fr': 'Enregistrer la séance',
      'en': 'Save session',
      'de': 'Einheit speichern',
    },
    'manual_unit_steps': {
      'fr': 'pas',
      'en': 'steps',
      'de': 'Schritte',
    },
    'manual_session_saved': {
      'fr': 'Séance enregistrée',
      'en': 'Session saved',
      'de': 'Einheit gespeichert',
    },
    'manual_activity_label': {
      'fr': 'Activité',
      'en': 'Activity',
      'de': 'Aktivität',
    },
    'manual_format_label': {
      'fr': 'Format',
      'en': 'Format',
      'de': 'Format',
    },
    'manual_duration_label': {
      'fr': 'Durée',
      'en': 'Duration',
      'de': 'Dauer',
    },
    'manual_distance_label': {
      'fr': 'Distance',
      'en': 'Distance',
      'de': 'Distanz',
    },
    'manual_steps_label_result': {
      'fr': 'Pas',
      'en': 'Steps',
      'de': 'Schritte',
    },
    'manual_steps_per_minute': {
      'fr': 'Pas par minute',
      'en': 'Steps per minute',
      'de': 'Schritte pro Minute',
    },
    'manual_avg_speed': {
      'fr': 'Vitesse moyenne',
      'en': 'Average speed',
      'de': 'Durchschnittsgeschwindigkeit',
    },
    'manual_estimated_calories': {
      'fr': 'Calories estimées',
      'en': 'Estimated calories',
      'de': 'Geschätzte Kalorien',
    },
    'manual_notes_label': {
      'fr': 'Notes',
      'en': 'Notes',
      'de': 'Notizen',
    },
    'manual_finish': {
      'fr': 'Terminer',
      'en': 'Finish',
      'de': 'Beenden',
    },
    'manual_intensity_moderate': {
      'fr': 'Modéré',
      'en': 'Moderate',
      'de': 'Moderat',
    },
    // Validation errors
    'error_duration_required': {
      'fr': 'Veuillez entrer une durée valide',
      'en': 'Please enter a valid duration',
      'de': 'Bitte geben Sie eine gültige Dauer ein',
    },
    'error_distance_required': {
      'fr': 'Veuillez entrer une distance valide',
      'en': 'Please enter a valid distance',
      'de': 'Bitte geben Sie eine gültige Distanz ein',
    },
    'error_duration_or_distance_required': {
      'fr': 'Veuillez entrer une durée ou une distance',
      'en': 'Please enter a duration or distance',
      'de': 'Bitte geben Sie eine Dauer oder Distanz ein',
    },
    'error_steps_required': {
      'fr': 'Veuillez entrer un nombre de pas valide',
      'en': 'Please enter a valid number of steps',
      'de': 'Bitte geben Sie eine gültige Schrittzahl ein',
    },
    // HIIT Config Screen
    'hiit_custom_title': {
      'fr': 'HIIT personnalisé',
      'en': 'Custom HIIT',
      'de': 'Benutzerdefiniertes HIIT',
    },
    'hiit_config_title': {
      'fr': 'Configure ton entraînement',
      'en': 'Configure your workout',
      'de': 'Konfiguriere dein Training',
    },
    'hiit_config_subtitle': {
      'fr': 'Définis les paramètres de ton HIIT personnalisé',
      'en': 'Set your custom HIIT parameters',
      'de': 'Lege deine benutzerdefinierten HIIT-Parameter fest',
    },
    'hiit_total_duration': {
      'fr': 'Durée totale',
      'en': 'Total duration',
      'de': 'Gesamtdauer',
    },
    'hiit_total_duration_desc': {
      'fr': 'Combien de temps veux-tu t\'entraîner ?',
      'en': 'How long do you want to work out?',
      'de': 'Wie lange möchtest du trainieren?',
    },
    'hiit_work_time': {
      'fr': 'Temps d\'effort',
      'en': 'Work time',
      'de': 'Arbeitszeit',
    },
    'hiit_work_time_desc': {
      'fr': 'Durée de la phase d\'effort',
      'en': 'Duration of the work phase',
      'de': 'Dauer der Arbeitsphase',
    },
    'hiit_rest_time': {
      'fr': 'Temps de repos',
      'en': 'Rest time',
      'de': 'Ruhezeit',
    },
    'hiit_rest_time_desc': {
      'fr': 'Durée de la phase de récupération',
      'en': 'Duration of the recovery phase',
      'de': 'Dauer der Erholungsphase',
    },
    'hiit_preview': {
      'fr': 'Aperçu de ton entraînement',
      'en': 'Workout preview',
      'de': 'Trainingsvorschau',
    },
    'hiit_preview_rounds': {
      'fr': 'Nombre de rounds',
      'en': 'Number of rounds',
      'de': 'Anzahl der Runden',
    },
    'hiit_preview_cycle': {
      'fr': 'Cycle complet',
      'en': 'Complete cycle',
      'de': 'Kompletter Zyklus',
    },
    'hiit_preview_total': {
      'fr': 'Durée totale estimée',
      'en': 'Estimated total duration',
      'de': 'Geschätzte Gesamtdauer',
    },
    'hiit_start_workout': {
      'fr': 'Commencer l\'entraînement',
      'en': 'Start workout',
      'de': 'Training starten',
    },
    'hiit_unit_min': {
      'fr': 'min',
      'en': 'min',
      'de': 'Min',
    },
    'hiit_unit_sec': {
      'fr': 'sec',
      'en': 'sec',
      'de': 'Sek',
    },
    'hiit_cycles_count': {
      'fr': 'cycles',
      'en': 'cycles',
      'de': 'Zyklen',
    },
    // Tracking screens
    'tracking_gps_title': {
      'fr': 'Géolocalisation',
      'en': 'GPS Location',
      'de': 'GPS-Standort',
    },
    'tracking_gps_description': {
      'fr':
          'Pour un suivi précis de votre distance et vitesse, autorisez l\'accès à votre position. Vous pouvez toujours utiliser le mode manuel dans les réglages.',
      'en':
          'For precise tracking of your distance and speed, allow access to your location. You can always use manual mode in settings.',
      'de':
          'Für genaue Distanz- und Geschwindigkeitsmessung erlauben Sie bitte den Zugriff auf Ihren Standort. Sie können auch den manuellen Modus in den Einstellungen verwenden.',
    },
    'tracking_later': {
      'fr': 'Plus tard',
      'en': 'Later',
      'de': 'Später',
    },
    'tracking_allow': {
      'fr': 'Autoriser',
      'en': 'Allow',
      'de': 'Erlauben',
    },
    'tracking_objective_reached': {
      'fr': 'Objectif atteint !',
      'en': 'Objective reached!',
      'de': 'Ziel erreicht!',
    },
    // HIIT Session
    'hiit_good_session': {
      'fr': 'Bonne séance !',
      'en': 'Good session!',
      'de': 'Gute Einheit!',
    },
    'hiit_session_interrupted': {
      'fr': 'Séance interrompue',
      'en': 'Session interrupted',
      'de': 'Einheit unterbrochen',
    },
    'hiit_good_objective': {
      'fr': 'Vous avez réalisé une bonne partie de l\'objectif !',
      'en': 'You achieved a good part of the objective!',
      'de': 'Sie haben einen guten Teil des Ziels erreicht!',
    },
    'hiit_effort_counts': {
      'fr': 'Pas de problème, chaque effort compte !',
      'en': 'No problem, every effort counts!',
      'de': 'Kein Problem, jede Anstrengung zählt!',
    },
    'hiit_time_completed': {
      'fr': 'Temps réalisé',
      'en': 'Time completed',
      'de': 'Absolvierte Zeit',
    },
    'hiit_objective': {
      'fr': 'Objectif',
      'en': 'Objective',
      'de': 'Ziel',
    },
    'hiit_complete_sets': {
      'fr': 'Séries complètes',
      'en': 'Complete sets',
      'de': 'Vollständige Sätze',
    },
    'hiit_calories': {
      'fr': 'Calories',
      'en': 'Calories',
      'de': 'Kalorien',
    },
    'hiit_finish': {
      'fr': 'Terminer la séance',
      'en': 'Finish session',
      'de': 'Einheit beenden',
    },

    // Meal description translations
    'ai_chat': {
      'fr': 'Décrire mon repas',
      'en': 'Describe my meal',
      'de': 'Meine Mahlzeit beschreiben',
    },
    'ai_chat_title': {
      'fr': 'Décrivez votre repas',
      'en': 'Describe your meal',
      'de': 'Beschreiben Sie Ihre Mahlzeit',
    },
    'ai_chat_subtitle': {
      'fr': 'Le coach analysera votre description',
      'en': 'Coach will analyze your description',
      'de': 'Der Coach wird Ihre Beschreibung analysieren',
    },
    'describe_meal': {
      'fr': 'Décrire mon repas',
      'en': 'Describe my meal',
      'de': 'Meine Mahlzeit beschreiben',
    },
    'coach_will_analyze': {
      'fr': 'Coach Ryze analysera votre description',
      'en': 'Coach Ryze will analyze your description',
      'de': 'Coach Ryze wird Ihre Beschreibung analysieren',
    },
    'ai_chat_hint': {
      'fr': 'Ex: 2 cafés, 1 croissant, salade césar...',
      'en': 'Ex: 2 coffees, 1 croissant, caesar salad...',
      'de': 'z.B.: 2 Kaffees, 1 Croissant, Caesar-Salat...',
    },
    'ai_chat_suggestions': {
      'fr': 'Suggestions',
      'en': 'Suggestions',
      'de': 'Vorschläge',
    },
    'analyze_meal': {
      'fr': 'Analyser le repas',
      'en': 'Analyze meal',
      'de': 'Mahlzeit analysieren',
    },
    'ai_chat_analyze': {
      'fr': 'Analyser le repas',
      'en': 'Analyze meal',
      'de': 'Mahlzeit analysieren',
    },
    'ai_chat_results': {
      'fr': 'Résultats de l\'analyse',
      'en': 'Analysis Results',
      'de': 'Analyseergebnisse',
    },
    'ai_analysis_results': {
      'fr': 'Résultats de l\'analyse',
      'en': 'Analysis Results',
      'de': 'Analyseergebnisse',
    },
    'add_all_foods': {
      'fr': 'Ajouter tous les aliments',
      'en': 'Add all foods',
      'de': 'Alle Lebensmittel hinzufügen',
    },
    'end_session': {
      'fr': 'Annuler',
      'en': 'End session',
      'de': 'Einheit beenden',
    },
    // Gemini Error Messages (friendly and playful)
    'gemini_not_configured': {
      'fr':
          '🤖 Oups ! Le coach a besoin de sa clé API pour analyser vos repas. Configurez Gemini dans les paramètres.',
      'en':
          '🤖 Oops! Coach needs his API key to analyze your meals. Configure Gemini in settings.',
      'de':
          '🤖 Hoppla! Der Coach braucht seinen API-Schlüssel, um Ihre Mahlzeiten zu analysieren. Konfigurieren Sie Gemini in den Einstellungen.',
    },
    'gemini_no_response': {
      'fr':
          '🤔 Le coach semble un peu dans la lune... Aucune réponse reçue. Réessayez dans un instant !',
      'en':
          '🤔 Coach seems a bit distracted... No response received. Try again in a moment!',
      'de':
          '🤔 Der Coach scheint etwas abgelenkt... Keine Antwort erhalten. Versuchen Sie es gleich noch einmal!',
    },
    'gemini_no_foods_detected': {
      'fr':
          '🍽️ Hmm, le coach n\'a pas détecté d\'aliments. Pouvez-vous être plus précis dans votre description ?',
      'en':
          '🍽️ Hmm, coach didn\'t detect any foods. Can you be more specific in your description?',
      'de':
          '🍽️ Hmm, der Coach hat keine Lebensmittel erkannt. Können Sie Ihre Beschreibung präzisieren?',
    },
    'gemini_analysis_failed': {
      'fr':
          '😅 Oh non ! Le coach a trébuché pendant l\'analyse. Vérifiez votre connexion et réessayez.',
      'en':
          '😅 Oh no! Coach stumbled during the analysis. Check your connection and try again.',
      'de':
          '😅 Oh nein! Der Coach ist bei der Analyse gestolpert. Überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.',
    },
    // Meal Selection for AI Chat
    'select_meal_for_chat': {
      'fr': 'À quel repas ?',
      'en': 'Which meal?',
      'de': 'Zu welcher Mahlzeit?',
    },
    'select_meal_hint': {
      'fr': 'Choisissez le repas pour ajouter vos aliments',
      'en': 'Choose the meal to add your foods',
      'de': 'Wählen Sie die Mahlzeit, um Ihre Lebensmittel hinzuzufügen',
    },
    'continue_btn': {
      'fr': 'Continuer',
      'en': 'Continue',
      'de': 'Weiter',
    },
    'chat_ai_meal': {
      'fr': 'Repas',
      'en': 'Meal',
      'de': 'Mahlzeit',
    },
    'your_meal': {
      'fr': 'Votre repas',
      'en': 'Your meal',
      'de': 'Ihre Mahlzeit',
    },
    'nutritional_summary': {
      'fr': 'Résumé nutritionnel',
      'en': 'Nutritional summary',
      'de': 'Nährwertzusammenfassung',
    },
    'meal_name': {
      'fr': 'Nom du plat',
      'en': 'Meal name',
      'de': 'Name des Gerichts',
    },
    // Cardio Tracking Screen
    'tracking_duration': {
      'fr': 'DURÉE',
      'en': 'DURATION',
      'de': 'DAUER',
    },
    'tracking_distance': {
      'fr': 'Distance',
      'en': 'Distance',
      'de': 'Distanz',
    },
    'tracking_steps': {
      'fr': 'Pas',
      'en': 'Steps',
      'de': 'Schritte',
    },
    'tracking_speed': {
      'fr': 'Vitesse',
      'en': 'Speed',
      'de': 'Geschwindigkeit',
    },
    'tracking_average': {
      'fr': 'Moy.',
      'en': 'Avg.',
      'de': 'Durchschn.',
    },
    'tracking_calories': {
      'fr': 'Calories',
      'en': 'Calories',
      'de': 'Kalorien',
    },
    'tracking_session_finished': {
      'fr': 'Séance terminée !',
      'en': 'Session completed!',
      'de': 'Einheit abgeschlossen!',
    },
    'tracking_session_finished_subtitle': {
      'fr': 'Excellent travail ! Voici le résumé de votre séance.',
      'en': 'Excellent work! Here\'s your session summary.',
      'de': 'Ausgezeichnete Arbeit! Hier ist Ihre Einheitszusammenfassung.',
    },
    'tracking_summary_duration': {
      'fr': 'Durée',
      'en': 'Duration',
      'de': 'Dauer',
    },
    'tracking_summary_distance': {
      'fr': 'Distance',
      'en': 'Distance',
      'de': 'Distanz',
    },
    'tracking_summary_steps': {
      'fr': 'Pas',
      'en': 'Steps',
      'de': 'Schritte',
    },
    'tracking_summary_average_speed': {
      'fr': 'Vitesse moy.',
      'en': 'Avg. speed',
      'de': 'Durchschn. Geschw.',
    },
    'tracking_summary_calories': {
      'fr': 'Calories',
      'en': 'Calories',
      'de': 'Kalorien',
    },
    'tracking_steps_per_minute': {
      'fr': 'Pas par minute',
      'en': 'Steps per minute',
      'de': 'Schritte pro Minute',
    },
    'tracking_steps_short': {
      'fr': 'Pas/min',
      'en': 'Steps/min',
      'de': 'Schritte/Min',
    },
    // HIIT Session Screen
    'hiit_session_effort': {
      'fr': 'EFFORT',
      'en': 'WORK',
      'de': 'ARBEIT',
    },
    'hiit_session_rest': {
      'fr': 'REPOS',
      'en': 'REST',
      'de': 'PAUSE',
    },
    'hiit_session_finished': {
      'fr': 'TERMINÉ',
      'en': 'FINISHED',
      'de': 'BEENDET',
    },
    'hiit_session_round': {
      'fr': 'Série',
      'en': 'Round',
      'de': 'Runde',
    },
    'hiit_session_total_time': {
      'fr': 'Temps total',
      'en': 'Total time',
      'de': 'Gesamtzeit',
    },
    'hiit_session_intensity': {
      'fr': 'Élevé',
      'en': 'High',
      'de': 'Hoch',
    },
    'hiit_session_completed_rounds': {
      'fr': 'Séries complètes',
      'en': 'Completed rounds',
      'de': 'Abgeschlossene Runden',
    },
    'hiit_session_work_duration': {
      'fr': 'Effort',
      'en': 'Work',
      'de': 'Arbeit',
    },
    'hiit_session_rest_duration': {
      'fr': 'Repos',
      'en': 'Rest',
      'de': 'Pause',
    },
    // Cardio objectives and misc
    'tracking_objective_distance_remaining': {
      'fr': 'Objectif',
      'en': 'Goal',
      'de': 'Ziel',
    },
    'tracking_distance_remaining': {
      'fr': 'km restants',
      'en': 'km remaining',
      'de': 'km übrig',
    },
    'tracking_objective_time_remaining': {
      'fr': 'Objectif',
      'en': 'Goal',
      'de': 'Ziel',
    },
    'tracking_time_remaining': {
      'fr': 'restants',
      'en': 'remaining',
      'de': 'übrig',
    },
    // Session stats labels
    'session_stat_duration': {
      'fr': 'Durée',
      'en': 'Duration',
      'de': 'Dauer',
    },
    'session_stat_distance': {
      'fr': 'Distance',
      'en': 'Distance',
      'de': 'Distanz',
    },
    'session_stat_pace': {
      'fr': 'Allure',
      'en': 'Pace',
      'de': 'Tempo',
    },
    'session_stat_calories': {
      'fr': 'Calories',
      'en': 'Calories',
      'de': 'Kalorien',
    },
    'session_last_session': {
      'fr': 'Dernière séance',
      'en': 'Last session',
      'de': 'Letzte Einheit',
    },
    'session_end_session': {
      'fr': 'Terminer la séance',
      'en': 'End session',
      'de': 'Einheit beenden',
    },
    // Workout/Musculation page
    'workout_session_type': {
      'fr': 'Type de séance',
      'en': 'Session type',
      'de': 'Einheitstyp',
    },
    'workout_upper_body': {
      'fr': 'Haut du corps',
      'en': 'Upper body',
      'de': 'Oberkörper',
    },
    'workout_lower_body': {
      'fr': 'Bas du corps',
      'en': 'Lower body',
      'de': 'Unterkörper',
    },
    'workout_full_body': {
      'fr': 'Full body',
      'en': 'Full body',
      'de': 'Ganzkörper',
    },
    'workout_manual_session': {
      'fr': 'Séance manuelle',
      'en': 'Manual session',
      'de': 'Manuelle Einheit',
    },
    'workout_guided_session': {
      'fr': 'Séance guidée',
      'en': 'Guided session',
      'de': 'Geführte Einheit',
    },
    'workout_new_session': {
      'fr': 'Nouvelle séance',
      'en': 'New session',
      'de': 'Neue Einheit',
    },
    'workout_create_manual_title': {
      'fr': 'Créer une séance manuellement',
      'en': 'Create a manual session',
      'de': 'Manuelle Einheit erstellen',
    },
    'workout_create_manual_subtitle': {
      'fr': 'Construire sa séance étape par étape',
      'en': 'Build your session step by step',
      'de': 'Ihre Einheit Schritt für Schritt aufbauen',
    },
    'workout_choose_program_menu_title': {
      'fr': 'Choisir un programme enregistré',
      'en': 'Choose a saved program',
      'de': 'Gespeichertes Programm wählen',
    },
    'workout_choose_program_subtitle': {
      'fr': 'Utiliser un programme existant',
      'en': 'Use an existing program',
      'de': 'Bestehendes Programm verwenden',
    },
    'workout_session_name': {
      'fr': 'Nom de la séance',
      'en': 'Session name',
      'de': 'Name der Einheit',
    },
    'workout_session_of': {
      'fr': 'Séance du',
      'en': 'Session of',
      'de': 'Einheit vom',
    },
    'workout_start_session': {
      'fr': 'Commencer la séance',
      'en': 'Start session',
      'de': 'Einheit starten',
    },
    'workout_session_exercises': {
      'fr': 'Exercices de la séance',
      'en': 'Session exercises',
      'de': 'Übungen der Einheit',
    },
    'workout_no_exercise_added': {
      'fr': 'Aucun exercice ajouté',
      'en': 'No exercise added',
      'de': 'Keine Übung hinzugefügt',
    },
    'workout_add_exercise': {
      'fr': 'Ajouter un exercice',
      'en': 'Add exercise',
      'de': 'Übung hinzufügen',
    },
    'workout_custom': {
      'fr': 'Personnalisé',
      'en': 'Custom',
      'de': 'Benutzerdefiniert',
    },
    'workout_save_session': {
      'fr': 'Sauvegarder cette séance',
      'en': 'Save this session',
      'de': 'Diese Einheit speichern',
    },
    'workout_save_session_question': {
      'fr': 'Souhaitez-vous ajouter cette séance aux séances guidées ?',
      'en': 'Do you want to add this session to guided sessions?',
      'de': 'Möchten Sie diese Einheit zu den geführten Einheiten hinzufügen?',
    },
    'workout_no': {
      'fr': 'Non',
      'en': 'No',
      'de': 'Nein',
    },
    'workout_yes': {
      'fr': 'Oui',
      'en': 'Yes',
      'de': 'Ja',
    },
    'workout_program_created_desc': {
      'fr': 'Programme créé à partir de votre séance',
      'en': 'Program created from your session',
      'de': 'Programm aus Ihrer Einheit erstellt',
    },
    'workout_session_added_programs': {
      'fr': 'Séance ajoutée aux programmes guidés !',
      'en': 'Session added to guided programs!',
      'de': 'Einheit zu geführten Programmen hinzugefügt!',
    },
    'workout_session_finished': {
      'fr': 'Séance terminée !',
      'en': 'Session completed!',
      'de': 'Einheit abgeschlossen!',
    },
    'workout_duration': {
      'fr': 'Durée',
      'en': 'Duration',
      'de': 'Dauer',
    },
    'workout_exercises_count': {
      'fr': 'Exercices',
      'en': 'Exercises',
      'de': 'Übungen',
    },
    'workout_sets_count': {
      'fr': 'Séries',
      'en': 'Sets',
      'de': 'Sätze',
    },
    'workout_kilos_lifted': {
      'fr': 'Kilos soulevés',
      'en': 'Kilos lifted',
      'de': 'Gehobene Kilos',
    },
    'workout_calories_burned': {
      'fr': 'Calories dépensées',
      'en': 'Calories burned',
      'de': 'Verbrannte Kalorien',
    },
    'workout_new_session_button': {
      'fr': 'Nouvelle séance',
      'en': 'New session',
      'de': 'Neue Einheit',
    },
    'workout_session_saved': {
      'fr': 'Séance enregistrée !',
      'en': 'Session saved!',
      'de': 'Einheit gespeichert!',
    },
    'workout_save': {
      'fr': 'Enregistrer',
      'en': 'Save',
      'de': 'Speichern',
    },
    // Workout widgets
    'workout_monday': {
      'fr': 'Lundi',
      'en': 'Monday',
      'de': 'Montag',
    },
    'workout_tuesday': {
      'fr': 'Mardi',
      'en': 'Tuesday',
      'de': 'Dienstag',
    },
    'workout_wednesday': {
      'fr': 'Mercredi',
      'en': 'Wednesday',
      'de': 'Mittwoch',
    },
    'workout_thursday': {
      'fr': 'Jeudi',
      'en': 'Thursday',
      'de': 'Donnerstag',
    },
    'workout_friday': {
      'fr': 'Vendredi',
      'en': 'Friday',
      'de': 'Freitag',
    },
    'workout_saturday': {
      'fr': 'Samedi',
      'en': 'Saturday',
      'de': 'Samstag',
    },
    'workout_sunday': {
      'fr': 'Dimanche',
      'en': 'Sunday',
      'de': 'Sonntag',
    },
    'workout_today': {
      'fr': 'Aujourd\'hui',
      'en': 'Today',
      'de': 'Heute',
    },
    'workout_one_day_ago': {
      'fr': 'Il y a 1 jour',
      'en': '1 day ago',
      'de': 'Vor 1 Tag',
    },
    'workout_days_ago': {
      'fr': 'Il y a {0} jours',
      'en': '{0} days ago',
      'de': 'Vor {0} Tagen',
    },
    'workout_week_history': {
      'fr': 'Historique de la semaine',
      'en': 'Week history',
      'de': 'Wochenverlauf',
    },
    'workout_no_session_this_week': {
      'fr': 'Aucune séance cette semaine',
      'en': 'No session this week',
      'de': 'Keine Einheit diese Woche',
    },
    'workout_exercise_progression': {
      'fr': 'Progression par exercice',
      'en': 'Progress by exercise',
      'de': 'Fortschritt nach Übung',
    },
    'workout_see_all': {
      'fr': 'Voir',
      'en': 'View',
      'de': 'Anzeigen',
    },
    'workout_no_exercise_found': {
      'fr': 'Aucun exercice trouvé',
      'en': 'No exercise found',
      'de': 'Keine Übung gefunden',
    },
    'workout_finish': {
      'fr': 'Terminer',
      'en': 'Finish',
      'de': 'Beenden',
    },
    'workout_start_session_button': {
      'fr': 'Commencer une séance',
      'en': 'Start a session',
      'de': 'Einheit starten',
    },
    // Workout session screen
    'workout_intensity_low': {
      'fr': 'Faible',
      'en': 'Low',
      'de': 'Niedrig',
    },
    'workout_intensity_moderate': {
      'fr': 'Modéré',
      'en': 'Moderate',
      'de': 'Moderat',
    },
    'workout_intensity_high': {
      'fr': 'Élevé',
      'en': 'High',
      'de': 'Hoch',
    },
    'workout_intensity_very_high': {
      'fr': 'Très élevé',
      'en': 'Very High',
      'de': 'Sehr hoch',
    },
    // Cardio intensity labels
    'cardio_intensity_label': {
      'fr': 'Intensité de l\'effort',
      'de': 'Anstrengungsintensität',
      'en': 'Effort Intensity',
    },
    'cardio_intensity_description': {
      'fr':
          'Sélectionnez l\'intensité de votre effort (utilisé si distance non fournie)',
      'en': 'Select your effort intensity (used if distance not provided)',
      'de':
          'Wähle deine Anstrengungsintensität (wird verwendet, wenn keine Distanz angegeben)',
    },
    'cardio_estimated_calories_realtime': {
      'fr': 'Calories estimées',
      'en': 'Estimated Calories',
      'de': 'Geschätzte Kalorien',
    },
    'cardio_based_on_speed': {
      'fr': 'Basé sur vitesse réelle',
      'en': 'Based on real speed',
      'de': 'Basierend auf tatsächlicher Geschwindigkeit',
    },
    'cardio_based_on_intensity': {
      'fr': 'Basé sur intensité',
      'en': 'Based on intensity',
      'de': 'Basierend auf Intensität',
    },
    'workout_validate_set_first': {
      'fr': 'Validez d\'abord la série {0} !',
      'en': 'Validate set {0} first!',
      'de': 'Zuerst Satz {0} bestätigen!',
    },
    'workout_set_validated': {
      'fr': 'Série {0} validée !',
      'en': 'Set {0} validated!',
      'de': 'Satz {0} bestätigt!',
    },
    'workout_enter_weight_reps': {
      'fr': 'Veuillez saisir le poids et les répétitions',
      'en': 'Please enter weight and repetitions',
      'de': 'Bitte geben Sie Gewicht und Wiederholungen ein',
    },
    'workout_how_many_sets': {
      'fr': 'Combien de séries ?',
      'en': 'How many sets?',
      'de': 'Wie viele Sätze?',
    },
    'workout_for_exercise': {
      'fr': 'Pour l\'exercice "{0}"',
      'en': 'For exercise "{0}"',
      'de': 'Für Übung "{0}"',
    },
    'workout_cancel': {
      'fr': 'Annuler',
      'en': 'Cancel',
      'de': 'Abbrechen',
    },
    'workout_create': {
      'fr': 'Créer',
      'en': 'Create',
      'de': 'Erstellen',
    },
    'workout_no_exercise_offline': {
      'fr':
          'Aucun exercice disponible hors ligne. Connectez-vous au moins une fois pour télécharger les exercices.',
      'en':
          'No exercises available offline. Connect at least once to download exercises.',
      'de':
          'Keine Übungen offline verfügbar. Verbinden Sie sich mindestens einmal, um Übungen herunterzuladen.',
    },
    'workout_search_create_exercise': {
      'fr': 'Rechercher ou créer un exercice...',
      'en': 'Search or create an exercise...',
      'de': 'Übung suchen oder erstellen...',
    },
    'workout_create_new_exercise': {
      'fr': 'Créer un nouvel exercice',
      'en': 'Create new exercise',
      'de': 'Neue Übung erstellen',
    },
    'workout_personal': {
      'fr': 'Perso',
      'en': 'Personal',
      'de': 'Persönlich',
    },
    'workout_hide': {
      'fr': 'Masquer',
      'en': 'Hide',
      'de': 'Ausblenden',
    },
    'workout_exercise_hidden': {
      'fr': 'Exercice masqué de la liste',
      'en': 'Exercise hidden from list',
      'de': 'Übung aus der Liste ausgeblendet',
    },
    'workout_save_session_question_detail': {
      'fr':
          'Souhaitez-vous ajouter la séance "{0}" à votre liste de séances guidées ?',
      'en': 'Do you want to add session "{0}" to your guided sessions list?',
      'de':
          'Möchten Sie die Einheit "{0}" zu Ihrer Liste der geführten Einheiten hinzufügen?',
    },
    'workout_create_manually': {
      'fr': 'Créer une séance manuellement',
      'en': 'Create session manually',
      'de': 'Einheit manuell erstellen',
    },
    'workout_create_manually_desc': {
      'fr': 'Construire sa séance étape par étape',
      'en': 'Build your session step by step',
      'de': 'Ihre Einheit Schritt für Schritt aufbauen',
    },
    'workout_choose_program': {
      'fr': 'Choisir un programme enregistré',
      'en': 'Choose saved program',
      'de': 'Gespeichertes Programm wählen',
    },
    'workout_choose_program_desc': {
      'fr': 'Utiliser un programme existant',
      'en': 'Use existing program',
      'de': 'Bestehendes Programm verwenden',
    },
    'workout_default_session_name': {
      'fr': 'Séance du {day}/{month}',
      'en': 'Session of {day}/{month}',
      'de': 'Einheit vom {day}/{month}',
    },
    'workout_session_name_hint': {
      'fr': 'Nom de la séance',
      'en': 'Session name',
      'de': 'Name der Einheit',
    },
    'workout_no_exercises_added': {
      'fr': 'Aucun exercice ajouté',
      'en': 'No exercises added',
      'de': 'Keine Übungen hinzugefügt',
    },
    'workout_custom_group': {
      'fr': 'Personnalisé',
      'en': 'Custom',
      'de': 'Benutzerdefiniert',
    },
    'workout_save_session_title': {
      'fr': 'Sauvegarder cette séance',
      'en': 'Save this session',
      'de': 'Diese Einheit speichern',
    },
    'workout_save_session_message': {
      'fr': 'Souhaitez-vous ajouter cette séance aux séances guidées ?',
      'en': 'Do you want to add this session to guided sessions?',
      'de': 'Möchten Sie diese Einheit zu den geführten Einheiten hinzufügen?',
    },
    'workout_program_from_session_desc': {
      'fr': 'Programme créé à partir de votre séance',
      'en': 'Program created from your session',
      'de': 'Programm aus Ihrer Einheit erstellt',
    },
    'workout_custom_type': {
      'fr': 'Personnalisé',
      'en': 'Custom',
      'de': 'Benutzerdefiniert',
    },
    'workout_session_saved_message': {
      'fr': 'Séance "{0}" ajoutée aux programmes guidés !',
      'en': '"{0}" session added to guided programs!',
      'de': 'Einheit "{0}" zu geführten Programmen hinzugefügt!',
    },
    'workout_session_completed': {
      'fr': 'Séance terminée !',
      'en': 'Session completed!',
      'de': 'Einheit abgeschlossen!',
    },
    'workout_session_summary': {
      'fr': 'Excellent travail ! Voici le résumé de votre séance.',
      'en': 'Excellent work! Here\'s your session summary.',
      'de': 'Ausgezeichnete Arbeit! Hier ist Ihre Einheitszusammenfassung.',
    },
    'no': {
      'fr': 'Non',
      'en': 'No',
      'de': 'Nein',
    },
    'yes': {
      'fr': 'Oui',
      'en': 'Yes',
      'de': 'Ja',
    },
    'workout_no_history': {
      'fr': 'Aucun historique',
      'en': 'No history',
      'de': 'Kein Verlauf',
    },
    'workout_no_history_description': {
      'fr':
          'C\'est votre première fois avec cet exercice !\nVos performances seront enregistrées pour vous guider lors des prochaines séances.',
      'en':
          'This is your first time with this exercise!\nYour performance will be recorded to guide you in future sessions.',
      'de':
          'Das ist Ihr erstes Mal mit dieser Übung!\nIhre Leistung wird aufgezeichnet, um Sie bei zukünftigen Einheiten zu unterstützen.',
    },
    'workout_custom_badge': {
      'fr': 'Perso',
      'en': 'Custom',
      'de': 'Eigen',
    },
    'workout_weight_kg': {
      'fr': 'Poids (kg)',
      'en': 'Weight (kg)',
      'de': 'Gewicht (kg)',
    },
    'workout_weight': {
      'fr': 'Poids',
      'en': 'Weight',
      'de': 'Gewicht',
    },
    'workout_reps': {
      'fr': 'Répétitions',
      'en': 'Reps',
      'de': 'Wiederholungen',
    },
    'workout_no_offline_exercises': {
      'fr':
          'Aucun exercice disponible hors ligne. Connectez-vous au moins une fois pour télécharger les exercices.',
      'en':
          'No exercises available offline. Connect at least once to download exercises.',
      'de':
          'Keine Übungen offline verfügbar. Verbinden Sie sich mindestens einmal, um Übungen herunterzuladen.',
    },
    'hide': {
      'fr': 'Masquer',
      'en': 'Hide',
      'de': 'Ausblenden',
    },
    'workout_session_saved_locally': {
      'fr': 'Séance sauvegardée localement',
      'en': 'Session saved locally',
      'de': 'Einheit lokal gespeichert',
    },
    'workout_sync_on_reconnect': {
      'fr': 'Elle sera synchronisée dès le retour du réseau',
      'en': 'It will be synchronized when network returns',
      'de': 'Sie wird synchronisiert, wenn das Netzwerk zurückkehrt',
    },
    'workout_save_failed': {
      'fr': 'Échec de la sauvegarde de la séance',
      'en': 'Failed to save workout session',
      'de': 'Speichern der Trainingseinheit fehlgeschlagen',
    },
    'workout_program_from_manual': {
      'fr': 'Programme créé à partir d\'une séance manuelle',
      'en': 'Program created from manual session',
      'de': 'Programm aus manueller Einheit erstellt',
    },
    'minutes': {
      'fr': 'Minutes',
      'en': 'Minutes',
      'de': 'Minuten',
    },
    'offline': {
      'fr': 'Hors ligne',
      'en': 'Offline',
      'de': 'Offline',
    },
    'set': {
      'fr': 'Série',
      'en': 'Set',
      'de': 'Satz',
    },
    'step': {
      'fr': 'Étape',
      'en': 'Step',
      'de': 'Schritt',
    },
    'on': {
      'fr': 'sur',
      'en': 'of',
      'de': 'von',
    },
    'finish': {
      'fr': 'Terminer',
      'en': 'Finish',
      'de': 'Beenden',
    },
    // Login page
    'welcome': {
      'fr': 'Bienvenue !',
      'en': 'Welcome!',
      'de': 'Willkommen!',
    },
    'welcome_back': {
      'fr': 'Bon retour !',
      'en': 'Welcome Back!',
      'de': 'Willkommen zurück!',
    },
    'sign_in_subtitle': {
      'fr': 'Connectez-vous pour continuer votre parcours fitness',
      'en': 'Sign in to continue your fitness journey',
      'de': 'Melden Sie sich an, um Ihre Fitness-Reise fortzusetzen',
    },
    'email': {
      'fr': 'Email',
      'en': 'Email',
      'de': 'E-Mail',
    },
    'password': {
      'fr': 'Mot de passe',
      'en': 'Password',
      'de': 'Passwort',
    },
    'sign_in': {
      'fr': 'Se connecter',
      'en': 'Sign In',
      'de': 'Anmelden',
    },
    'forgot_password': {
      'fr': 'Mot de passe oublié ?',
      'en': 'Forgot Password?',
      'de': 'Passwort vergessen?',
    },
    'or_continue_with': {
      'fr': 'Ou continuez avec',
      'en': 'Or continue with',
      'de': 'Oder fortfahren mit',
    },
    'dont_have_account': {
      'fr': 'Pas encore de compte ?',
      'en': 'Don\'t have an account?',
      'de': 'Noch kein Konto?',
    },
    'sign_up': {
      'fr': 'S\'inscrire',
      'en': 'Sign Up',
      'de': 'Registrieren',
    },
    // 🔐 Messages d'erreur authentification - Ludiques et clairs
    'auth_error_invalid_credentials': {
      'fr':
          'Oups ! Email ou mot de passe incorrect 🤔\nVérifie bien tes identifiants !',
      'en': 'Oops! Wrong email or password 🤔\nDouble-check your credentials!',
      'de':
          'Hoppla! Falsche E-Mail oder falsches Passwort 🤔\nÜberprüfe deine Anmeldedaten!',
    },
    'auth_error_user_not_found': {
      'fr':
          'On dirait que ce compte n\'existe pas encore 🧐\nEnvie de créer un compte ?',
      'en':
          'Looks like this account doesn\'t exist yet 🧐\nWant to create one?',
      'de':
          'Dieses Konto scheint noch nicht zu existieren 🧐\nMöchtest du eines erstellen?',
    },
    'auth_error_invalid_email': {
      'fr':
          'Cet email ne semble pas valide 📧\nVérifie qu\'il n\'y a pas de faute de frappe !',
      'en': 'This email doesn\'t look valid 📧\nCheck for typos!',
      'de': 'Diese E-Mail scheint ungültig zu sein 📧\nPrüfe auf Tippfehler!',
    },
    'auth_error_weak_password': {
      'fr':
          'Ce mot de passe est trop simple 💪\nUtilise au moins 8 caractères avec majuscules, minuscules et chiffres !',
      'en':
          'This password is too weak 💪\nUse at least 8 characters with uppercase, lowercase and numbers!',
      'de':
          'Dieses Passwort ist zu schwach 💪\nVerwende mindestens 8 Zeichen mit Groß-, Kleinbuchstaben und Zahlen!',
    },
    'auth_error_email_already_exists': {
      'fr':
          'Cet email est déjà utilisé 👀\nTu as déjà un compte ? Essaie de te connecter !',
      'en':
          'This email is already in use 👀\nAlready have an account? Try logging in!',
      'de':
          'Diese E-Mail wird bereits verwendet 👀\nHast du bereits ein Konto? Versuche dich anzumelden!',
    },
    'auth_error_too_many_requests': {
      'fr':
          'Wow, doucement ! 🛑\nTrop de tentatives. Attends quelques minutes avant de réessayer.',
      'en':
          'Whoa, slow down! 🛑\nToo many attempts. Wait a few minutes before trying again.',
      'de':
          'Wow, langsam! 🛑\nZu viele Versuche. Warte ein paar Minuten, bevor du es erneut versuchst.',
    },
    'auth_error_network': {
      'fr': 'Pas de connexion internet 📡\nVérifie ta connexion et réessaie !',
      'en': 'No internet connection 📡\nCheck your connection and try again!',
      'de':
          'Keine Internetverbindung 📡\nÜberprüfe deine Verbindung und versuche es erneut!',
    },
    'auth_error_google_cancelled': {
      'fr':
          'Connexion Google annulée 🚫\nPas de souci, tu peux réessayer quand tu veux !',
      'en':
          'Google sign-in cancelled 🚫\nNo worries, try again whenever you\'re ready!',
      'de':
          'Google-Anmeldung abgebrochen 🚫\nKein Problem, versuche es, wann immer du möchtest!',
    },
    'auth_error_google_failed': {
      'fr':
          'Connexion Google impossible 😅\nRéessaie ou utilise un autre moyen de connexion !',
      'en':
          'Google sign-in failed 😅\nTry again or use another sign-in method!',
      'de':
          'Google-Anmeldung fehlgeschlagen 😅\nVersuche es erneut oder nutze eine andere Anmeldemethode!',
    },
    'auth_error_apple_cancelled': {
      'fr': 'Connexion Apple annulée 🍎\nTu peux réessayer quand tu veux !',
      'en': 'Apple sign-in cancelled 🍎\nYou can try again anytime!',
      'de':
          'Apple-Anmeldung abgebrochen 🍎\nDu kannst es jederzeit erneut versuchen!',
    },
    'auth_error_apple_failed': {
      'fr':
          'Connexion Apple impossible 😅\nRéessaie ou utilise un autre moyen de connexion !',
      'en': 'Apple sign-in failed 😅\nTry again or use another sign-in method!',
      'de':
          'Apple-Anmeldung fehlgeschlagen 😅\nVersuche es erneut oder nutze eine andere Anmeldemethode!',
    },
    'auth_error_session_expired': {
      'fr': 'Ta session a expiré ⏰\nReconnecte-toi pour continuer !',
      'en': 'Your session expired ⏰\nSign in again to continue!',
      'de':
          'Deine Sitzung ist abgelaufen ⏰\nMelde dich erneut an, um fortzufahren!',
    },
    'auth_error_password_reset_failed': {
      'fr':
          'Impossible d\'envoyer l\'email de réinitialisation 📨\nVérifie que ton email est correct !',
      'en': 'Couldn\'t send reset email 📨\nMake sure your email is correct!',
      'de':
          'E-Mail zum Zurücksetzen konnte nicht gesendet werden 📨\nStelle sicher, dass deine E-Mail korrekt ist!',
    },
    'auth_error_unknown': {
      'fr':
          'Quelque chose s\'est mal passé 🤷\nRéessaie dans quelques instants !',
      'en': 'Something went wrong 🤷\nTry again in a moment!',
      'de': 'Etwas ist schief gelaufen 🤷\nVersuche es in einem Moment erneut!',
    },
    'auth_error_signup_disabled': {
      'fr':
          'Les inscriptions sont temporairement désactivées 🚧\nRéessaie plus tard !',
      'en': 'Sign-ups are temporarily disabled 🚧\nTry again later!',
      'de':
          'Registrierungen sind vorübergehend deaktiviert 🚧\nVersuche es später erneut!',
    },
    'auth_error_account_disabled': {
      'fr':
          'Ton compte a été désactivé 🔒\nContacte le support pour plus d\'infos.',
      'en': 'Your account has been disabled 🔒\nContact support for more info.',
      'de':
          'Dein Konto wurde deaktiviert 🔒\nKontaktiere den Support für weitere Infos.',
    },
    'login_failed': {
      'fr': 'Connexion impossible 😕\nVérifie tes identifiants !',
      'en': 'Login failed 😕\nCheck your credentials!',
      'de': 'Anmeldung fehlgeschlagen 😕\nÜberprüfe deine Anmeldedaten!',
    },
    'google_login_failed': {
      'fr':
          'Connexion Google impossible 🔴\nRéessaie ou utilise une autre méthode !',
      'en': 'Google login failed 🔴\nTry again or use another method!',
      'de':
          'Google-Anmeldung fehlgeschlagen 🔴\nVersuche es erneut oder nutze eine andere Methode!',
    },
    'apple_login_failed': {
      'fr':
          'Connexion Apple impossible 🍎\nRéessaie ou utilise une autre méthode !',
      'en': 'Apple login failed 🍎\nTry again or use another method!',
      'de':
          'Apple-Anmeldung fehlgeschlagen 🍎\nVersuche es erneut oder nutze eine andere Methode!',
    },
    'enter_email': {
      'fr': 'Veuillez saisir votre email',
      'en': 'Please enter your email',
      'de': 'Bitte geben Sie Ihre E-Mail ein',
    },
    'enter_valid_email': {
      'fr': 'Veuillez saisir un email valide',
      'en': 'Please enter a valid email',
      'de': 'Bitte geben Sie eine gültige E-Mail ein',
    },
    'enter_password': {
      'fr': 'Veuillez saisir votre mot de passe',
      'en': 'Please enter your password',
      'de': 'Bitte geben Sie Ihr Passwort ein',
    },
    'programs': {
      'fr': 'Programmes',
      'en': 'Programs',
      'de': 'Programme',
    },
    'created_by_you': {
      'fr': 'Créé par toi',
      'en': 'Created by you',
      'de': 'Von dir erstellt',
    },
    'exercise_count_plural': {
      'fr': '{0} exercice{1}',
      'en': '{0} exercise{1}',
      'de': '{0} Übung{1}',
    },
    'workout_weight_lifted': {
      'fr': 'Kilos soulevés',
      'en': 'Weight lifted',
      'de': 'Gehobenes Gewicht',
    },
    'workout_new_session_btn': {
      'fr': 'Nouvelle séance',
      'en': 'New session',
      'de': 'Neue Einheit',
    },
    'workout_session_recorded': {
      'fr': 'Séance enregistrée !',
      'en': 'Session recorded!',
      'de': 'Einheit gespeichert!',
    },
    'workout_this_week': {
      'fr': 'Cette semaine',
      'en': 'This week',
      'de': 'Diese Woche',
    },
    'workout_sessions_short': {
      'fr': 'Séances',
      'en': 'Sessions',
      'de': 'Einheiten',
    },
    'workout_lifted_short': {
      'fr': 'Soulevés',
      'en': 'Lifted',
      'de': 'Gehoben',
    },
    'workout_burned_short': {
      'fr': 'Brûlées',
      'en': 'Burned',
      'de': 'Verbrannt',
    },
    'workout_start_by_adding_exercise': {
      'fr': 'Commencez par ajouter un exercice',
      'en': 'Start by adding an exercise',
      'de': 'Beginne mit dem Hinzufügen einer Übung',
    },
    'workout_set': {
      'fr': 'Série',
      'en': 'Set',
      'de': 'Satz',
    },
    'workout_confirm_end_session': {
      'fr': 'Confirmer la fin de la séance',
      'en': 'Confirm end of session',
      'de': 'Ende der Einheit bestätigen',
    },
    'workout_confirm_end_session_message': {
      'fr': 'Êtes-vous sûr de vouloir terminer la séance ?',
      'en': 'Are you sure you want to end the session?',
      'de': 'Bist du sicher, dass du die Einheit beenden möchtest?',
    },
    'workout_programs_loading_error': {
      'fr': 'Erreur de chargement des programmes',
      'en': 'Error loading programs',
      'de': 'Fehler beim Laden der Programme',
    },
    'workout_choose_program_title': {
      'fr': 'Choisir un programme',
      'en': 'Choose a program',
      'de': 'Programm auswählen',
    },
    'workout_custom_and_predefined_programs': {
      'fr': 'Vos programmes personnalisés et programmes prédéfinis',
      'en': 'Your custom programs and predefined programs',
      'de': 'Deine benutzerdefinierten und vordefinierten Programme',
    },
    'workout_select_predefined_program': {
      'fr': 'Sélectionnez un programme avec exercices prédéfinis',
      'en': 'Select a program with predefined exercises',
      'de': 'Wähle ein Programm mit vordefinierten Übungen',
    },
    'validate': {
      'fr': 'Valider',
      'en': 'Validate',
      'de': 'Bestätigen',
    },
    'workout_exercise_counter': {
      'fr': 'Exercice {current}/{total}',
      'en': 'Exercise {current}/{total}',
      'de': 'Übung {current}/{total}',
    },
    // Exercise info bottom sheet
    'exercise_description': {
      'fr': 'Description',
      'en': 'Description',
      'de': 'Beschreibung',
    },
    'exercise_how_to_perform': {
      'fr': 'Comment effectuer',
      'en': 'How to perform',
      'de': 'Ausführung',
    },
    'exercise_watch_tutorial': {
      'fr': 'Voir des tutoriels',
      'en': 'Watch tutorials',
      'de': 'Tutorials ansehen',
    },
    'exercise_no_instructions': {
      'fr': 'Aucune instruction disponible pour cet exercice.',
      'en': 'No instructions available for this exercise.',
      'de': 'Keine Anleitung für diese Übung verfügbar.',
    },
    'exercise_loading': {
      'fr': 'Chargement...',
      'en': 'Loading...',
      'de': 'Laden...',
    },
    'exercise_error': {
      'fr': 'Erreur de chargement',
      'en': 'Loading error',
      'de': 'Ladefehler',
    },
    // Set options menu
    'set_voice_input': {
      'fr': 'Entrée vocale',
      'en': 'Voice input',
      'de': 'Spracheingabe',
    },
    'set_copy_to_next': {
      'fr': 'Copier vers suivante',
      'en': 'Copy to next',
      'de': 'Zum nächsten kopieren',
    },
    'set_delete': {
      'fr': 'Supprimer',
      'en': 'Delete',
      'de': 'Löschen',
    },
    'workout_volume': {
      'fr': 'Volume',
      'en': 'Volume',
      'de': 'Volumen',
    },
    'workout_intensity': {
      'fr': 'Intensité',
      'en': 'Intensity',
      'de': 'Intensität',
    },
    'workout_intensity_duration_title': {
      'fr': 'Intensité et durée',
      'en': 'Intensity and duration',
      'de': 'Intensität und Dauer',
    },
    'workout_effective_duration': {
      'fr': 'Durée effective (minutes)',
      'en': 'Effective duration (minutes)',
      'de': 'Effektive Dauer (Minuten)',
    },
    'workout_session_history': {
      'fr': 'Historique des séances',
      'en': 'Session History',
      'de': 'Einheitsverlauf',
    },
    'workout_max': {
      'fr': 'Max',
      'en': 'Max',
      'de': 'Max',
    },
    'workout_best_set': {
      'fr': 'Meilleur set',
      'en': 'Best set',
      'de': 'Bester Satz',
    },
    'workout_set_number': {
      'fr': 'S{number}',
      'en': 'S{number}',
      'de': 'S{number}',
    },
    'date': {
      'fr': 'Date',
      'en': 'Date',
      'de': 'Datum',
    },
    'workout_intensity_question': {
      'fr': 'Comment était l\'intensité de la séance ?',
      'en': 'How was the session intensity?',
      'de': 'Wie war die Intensität der Einheit?',
    },
    'exercise_name_placeholder': {
      'fr': 'Nom de l\'exercice',
      'en': 'Exercise name',
      'de': 'Übungsname',
    },
    'sets_count_placeholder': {
      'fr': 'Nombre de séries',
      'en': 'Number of sets',
      'de': 'Anzahl der Sätze',
    },
    'workout_search_exercise': {
      'fr': 'Rechercher un exercice...',
      'en': 'Search exercise...',
      'de': 'Übung suchen...',
    },
    'workout_add_exercise_not_in_list': {
      'fr': 'Ajouter un exercice qui ne figure pas dans la liste',
      'en': 'Add an exercise that is not in the list',
      'de': 'Übung hinzufügen, die nicht in der Liste ist',
    },

    // Muscle Groups
    'muscle_group_chest': {
      'fr': 'Pectoraux',
      'en': 'Chest',
      'de': 'Brust',
    },
    'muscle_group_back': {
      'fr': 'Dos',
      'en': 'Back',
      'de': 'Rücken',
    },
    'muscle_group_shoulders': {
      'fr': 'Épaules',
      'en': 'Shoulders',
      'de': 'Schultern',
    },
    'muscle_group_biceps': {
      'fr': 'Biceps',
      'en': 'Biceps',
      'de': 'Bizeps',
    },
    'muscle_group_triceps': {
      'fr': 'Triceps',
      'en': 'Triceps',
      'de': 'Trizeps',
    },
    'muscle_group_legs': {
      'fr': 'Jambes',
      'en': 'Legs',
      'de': 'Beine',
    },
    'muscle_group_glutes': {
      'fr': 'Fessiers',
      'en': 'Glutes',
      'de': 'Gesäß',
    },
    'muscle_group_abs': {
      'fr': 'Abdominaux',
      'en': 'Abs',
      'de': 'Bauchmuskeln',
    },
    'muscle_group_calves': {
      'fr': 'Mollets',
      'en': 'Calves',
      'de': 'Waden',
    },
    'muscle_group_forearms': {
      'fr': 'Avant-bras',
      'en': 'Forearms',
      'de': 'Unterarme',
    },
    'muscle_group_custom': {
      'fr': 'Personnalisé',
      'en': 'Custom',
      'de': 'Benutzerdefiniert',
    },

    // Onboarding
    'onboarding_welcome': {
      'fr': 'Bienvenue',
      'en': 'Welcome',
      'de': 'Willkommen',
    },
    'onboarding_personal_profile': {
      'fr': 'Profil personnel',
      'en': 'Personal profile',
      'de': 'Persönliches Profil',
    },
    'onboarding_choose_gender': {
      'fr': 'Choisissez votre genre',
      'en': 'Choose your gender',
      'de': 'Wähle dein Geschlecht',
    },
    'onboarding_calibrate_plan': {
      'fr': 'Cela sera utilisé pour calibrer votre plan personnalisé',
      'en': 'This will be used to calibrate your personalized plan',
      'de':
          'Dies wird verwendet, um deinen personalisierten Plan zu kalibrieren',
    },
    'onboarding_when_born': {
      'fr': 'Quand êtes-vous né',
      'en': 'When were you born',
      'de': 'Wann wurdest du geboren',
    },
    'onboarding_height_weight': {
      'fr': 'Quelle est votre Taille & Poids',
      'en': 'What is your Height & Weight',
      'de': 'Was ist deine Größe & dein Gewicht',
    },
    'onboarding_adjust_energy': {
      'fr': 'Pour ajuster vos besoins énergétiques',
      'en': 'To adjust your energy needs',
      'de': 'Um deinen Energiebedarf anzupassen',
    },
    'onboarding_height_label': {
      'fr': 'Taille',
      'en': 'Height',
      'de': 'Größe',
    },
    'onboarding_weight_label': {
      'fr': 'Poids',
      'en': 'Weight',
      'de': 'Gewicht',
    },
    'onboarding_activity_level': {
      'fr': 'Quel est votre niveau d\'activité ?',
      'en': 'What is your activity level?',
      'de': 'Was ist dein Aktivitätsniveau?',
    },
    'onboarding_goal': {
      'fr': 'Quel est votre objectif ?',
      'en': 'What is your goal?',
      'de': 'Was ist dein Ziel?',
    },
    'onboarding_obstacles': {
      'fr': 'Qu\'est-ce qui vous empêche de garder une routine ?',
      'en': 'What prevents you from keeping a routine?',
      'de': 'Was hindert dich daran, eine Routine beizubehalten?',
    },
    'onboarding_dietary_restrictions': {
      'fr': 'Avez-vous des restrictions alimentaires ?',
      'en': 'Do you have any dietary restrictions?',
      'de': 'Hast du Ernährungseinschränkungen?',
    },
    'onboarding_results': {
      'fr': 'Résultats',
      'en': 'Results',
      'de': 'Ergebnisse',
    },
    'onboarding_low_activity': {
      'fr': 'Peu actif',
      'en': 'Low activity',
      'de': 'Wenig aktiv',
    },
    'onboarding_moderate_activity': {
      'fr': 'Modérément actif',
      'en': 'Moderate activity',
      'de': 'Mäßig aktiv',
    },
    'onboarding_high_activity': {
      'fr': 'Très actif',
      'en': 'High activity',
      'de': 'Sehr aktiv',
    },
    'onboarding_low_activity_desc': {
      'fr': '0-2 jours par semaine',
      'en': '0-2 days per week',
      'de': '0-2 Tage pro Woche',
    },
    'onboarding_moderate_activity_desc': {
      'fr': '3-5 jours par semaine',
      'en': '3-5 days per week',
      'de': '3-5 Tage pro Woche',
    },
    'onboarding_high_activity_desc': {
      'fr': '6+ jours par semaine',
      'en': '6+ days per week',
      'de': '6+ Tage pro Woche',
    },
    'onboarding_lose_weight': {
      'fr': 'Perdre du poids',
      'en': 'Lose weight',
      'de': 'Gewicht verlieren',
    },
    'onboarding_maintain_weight': {
      'fr': 'Maintenir mon poids',
      'en': 'Maintain my weight',
      'de': 'Gewicht halten',
    },
    'onboarding_gain_weight': {
      'fr': 'Prendre du poids',
      'en': 'Gain weight',
      'de': 'Gewicht zunehmen',
    },
    'onboarding_lose_weight_desc': {
      'fr': 'Déficit calorique contrôlé',
      'en': 'Controlled caloric deficit',
      'de': 'Kontrolliertes Kaloriendefizit',
    },
    'onboarding_maintain_weight_desc': {
      'fr': 'Équilibre énergétique',
      'en': 'Energy balance',
      'de': 'Energiegleichgewicht',
    },
    'onboarding_gain_weight_desc': {
      'fr': 'Surplus calorique sain',
      'en': 'Healthy caloric surplus',
      'de': 'Gesunder Kalorienüberschuss',
    },
    'onboarding_lack_of_time': {
      'fr': 'Manque de temps',
      'en': 'Lack of time',
      'de': 'Zeitmangel',
    },
    'onboarding_lack_of_motivation': {
      'fr': 'Manque de motivation',
      'en': 'Lack of motivation',
      'de': 'Motivationsmangel',
    },
    'onboarding_fatigue': {
      'fr': 'Fatigue',
      'en': 'Fatigue',
      'de': 'Müdigkeit',
    },
    'onboarding_lack_of_knowledge': {
      'fr': 'Manque de connaissances',
      'en': 'Lack of knowledge',
      'de': 'Wissensmangel',
    },
    'onboarding_other_priorities': {
      'fr': 'Autres priorités',
      'en': 'Other priorities',
      'de': 'Andere Prioritäten',
    },
    'onboarding_next': {
      'fr': 'Suivant',
      'en': 'Next',
      'de': 'Weiter',
    },
    'onboarding_previous': {
      'fr': 'Précédent',
      'en': 'Previous',
      'de': 'Zurück',
    },
    'onboarding_profile_ready': {
      'fr': 'Votre profil est prêt !',
      'en': 'Your profile is ready!',
      'de': 'Dein Profil ist bereit!',
    },
    'onboarding_personalize_experience': {
      'fr': 'Cela nous permettra de personnaliser votre expérience',
      'en': 'This will allow us to personalize your experience',
      'de': 'Dies ermöglicht uns, dein Erlebnis zu personalisieren',
    },
    'onboarding_welcome_title': {
      'fr': 'Bienvenue dans Ryze',
      'en': 'Welcome to Ryze',
      'de': 'Willkommen bei Ryze',
    },
    'onboarding_welcome_tagline': {
      'fr': 'Votre partenaire bien-être',
      'en': 'Your wellness partner',
      'de': 'Dein Wellness-Partner',
    },
    'onboarding_welcome_subtitle': {
      'fr': 'Créez votre plan nutrition personnalisé en 5 minutes',
      'en': 'Create your personalized nutrition plan in 5 minutes',
      'de': 'Erstelle deinen personalisierten Ernährungsplan in 5 Minuten',
    },
    'onboarding_stats_success': {
      'fr': 'ont atteint leurs objectifs',
      'en': 'reached their goals',
      'de': 'haben ihre Ziele erreicht',
    },
    'onboarding_stats_users': {
      'fr': 'Utilisateurs',
      'en': 'Users',
      'de': 'Nutzer',
    },
    'onboarding_stats_rating': {
      'fr': 'Note App',
      'en': 'App Rating',
      'de': 'App-Bewertung',
    },

    // AI Analysis - Coach Ryze
    'analyze_with_ai': {
      'fr': 'Analyser avec le Coach Ryze',
      'en': 'Analyze with Coach Ryze',
      'de': 'Mit Coach Ryze analysieren',
    },
    'ai_analysis': {
      'fr': 'Coach Ryze',
      'en': 'Coach Ryze',
      'de': 'Coach Ryze',
    },
    'analysis_in_progress': {
      'fr': 'Analyse en cours...',
      'en': 'Analysis in progress...',
      'de': 'Analyse läuft...',
    },
    'refresh_analysis': {
      'fr': 'Rafraîchir l\'analyse',
      'en': 'Refresh analysis',
      'de': 'Analyse aktualisieren',
    },
    'new_analysis_available': {
      'fr': 'Nouvelle dispo',
      'en': 'New available',
      'de': 'Neu verfügbar',
    },
    'minimum_sessions_required': {
      'fr': 'Au moins 3 séances sont nécessaires pour une analyse',
      'en': 'At least 3 sessions are required for analysis',
      'de': 'Mindestens 3 Einheiten sind für eine Analyse erforderlich',
    },
    'ai_analysis_unavailable': {
      'fr': 'Disponible après 3 séances de cet exercice',
      'en': 'Available after 3 sessions of this exercise',
      'de': 'Verfügbar nach 3 Einheiten dieser Übung',
    },
    'ai_performance_analysis': {
      'fr': 'Conseil personnalisé du Coach Ryze',
      'en': 'Personalized advice from Coach Ryze',
      'de': 'KI-Leistungsanalyse',
    },
    'analysis_error': {
      'fr': 'Erreur lors de la génération de l\'analyse',
      'en': 'Error generating analysis',
      'de': 'Fehler bei der Analyse-Erstellung',
    },

    // AI Workout Generation
    'ai_workout_button': {
      'fr': 'Séance Coach Ryze',
      'en': 'Coach Ryze Session',
      'de': 'Coach Ryze Training',
    },
    'ai_workout_title': {
      'fr': 'Séance du Coach Ryze',
      'en': 'Coach Ryze Session',
      'de': 'Coach Ryze Training',
    },
    'ai_workout_generated_session': {
      'fr': 'Séance créée par Coach Ryze',
      'en': 'Coach Ryze Generated Workout',
      'de': 'Von Coach Ryze erstelltes Training',
    },
    'ai_workout_error_unknown': {
      'fr': 'Erreur lors de la génération de la séance',
      'en': 'Error generating workout',
      'de': 'Fehler bei der Trainings-Erstellung',
    },
    'coach_ryze_personalized': {
      'fr': 'Personnalisé',
      'en': 'Personalized',
      'de': 'Personalisiert',
    },

    // Barcode Scanner
    'fetching_product': {
      'fr': 'Récupération du produit...',
      'en': 'Fetching product...',
      'de': 'Produkt wird abgerufen...',
    },
    'scanning_barcode': {
      'fr': 'Scannez le code-barres',
      'en': 'Scan the barcode',
      'de': 'Barcode scannen',
    },
    'searching_database': {
      'fr': 'Recherche dans la base de données...',
      'en': 'Searching in database...',
      'de': 'Suche in Datenbank...',
    },
    'place_barcode_in_zone': {
      'fr': 'Placez le code-barres dans la zone de scan',
      'en': 'Place the barcode in the scan zone',
      'de': 'Barcode in den Scanbereich halten',
    },
    'analyzing': {
      'fr': 'Analyse en cours...',
      'en': 'Analyzing...',
      'de': 'Analysiere...',
    },
    'scan_barcode_button': {
      'fr': 'Scanner le code-barres',
      'en': 'Scan barcode',
      'de': 'Barcode scannen',
    },
    'enter_code_manually': {
      'fr': 'Saisir le code manuellement',
      'en': 'Enter code manually',
      'de': 'Code manuell eingeben',
    },
    'product_found': {
      'fr': 'Produit trouvé',
      'en': 'Product found',
      'de': 'Produkt gefunden',
    },

    // Progress page additional (only adding non-duplicate keys)
    'continue_your_efforts': {
      'fr': 'Continue tes efforts, tu es sur la bonne voie !',
      'en': 'Keep up the good work, you\'re on the right track!',
      'de': 'Weiter so, du bist auf dem richtigen Weg!',
    },
    'global_progress': {
      'fr': 'Progrès Global',
      'en': 'Global Progress',
      'de': 'Gesamtfortschritt',
    },
    'weekly_score': {
      'fr': 'Score hebdo',
      'en': 'Weekly score',
      'de': 'Wochenpunktzahl',
    },
    'edit_values_per_100g': {
      'fr': 'Modifier valeurs/100g',
      'en': 'Edit values/100g',
      'de': 'Werte/100g bearbeiten',
    },
    'per_portion_of': {
      'fr': 'par portion de',
      'en': 'per portion of',
      'de': 'pro Portion von',
    },

    // Tutorial / Feature Discovery
    'understood': {
      'fr': 'Compris',
      'en': 'Got it',
      'de': 'Verstanden',
    },
    'skip': {
      'fr': 'Passer',
      'en': 'Skip',
      'de': 'Überspringen',
    },

    // Tutorial Dashboard (tutoiement + pédagogique)
    'tutorial_dashboard_add_food_title': {
      'fr': 'Ajouter un repas',
      'en': 'Add a Meal',
      'de': 'Mahlzeit hinzufügen',
    },
    'tutorial_dashboard_add_food_desc': {
      'fr':
          'Ajoute tes repas avec 5 méthodes : description, photo, code-barres, recherche ou recettes.',
      'en':
          'Add your meals with 5 methods: description, photo, barcode, search or recipes.',
      'de':
          'Füge Mahlzeiten mit 5 Methoden hinzu: Beschreibung, Foto, Barcode, Suche oder Rezepte.',
    },
    'tutorial_dashboard_add_exercise_title': {
      'fr': 'Ajouter un exercice',
      'en': 'Add an Exercise',
      'de': 'Übung hinzufügen',
    },
    'tutorial_dashboard_add_exercise_desc': {
      'fr':
          'Enregistre tes séances : musculation, cardio, HIIT et plus encore.',
      'en': 'Log your sessions: weight training, cardio, HIIT and more.',
      'de': 'Erfasse deine Einheiten: Krafttraining, Cardio, HIIT und mehr.',
    },
    'tutorial_dashboard_calories_title': {
      'fr': 'Tes objectifs du jour',
      'en': 'Your Daily Goals',
      'de': 'Deine Tagesziele',
    },
    'tutorial_dashboard_calories_desc': {
      'fr':
          'Tes 4 objectifs quotidiens : calories, nutrition, sport et hydratation.',
      'en': 'Your 4 daily goals: calories, nutrition, sport and hydration.',
      'de': 'Deine 4 Tagesziele: Kalorien, Ernährung, Sport und Hydration.',
    },
    'tutorial_dashboard_nutrition_tab_title': {
      'fr': 'Onglet Nutrition',
      'en': 'Nutrition Tab',
      'de': 'Ernährungs-Tab',
    },
    'tutorial_dashboard_nutrition_tab_desc': {
      'fr':
          'Accède à la page nutrition : ajoute tes aliments, consulte ton journal et tes recettes.',
      'en':
          'Access the nutrition page: add foods, view your journal and recipes.',
      'de':
          'Zugriff auf die Ernährungsseite: Lebensmittel hinzufügen, Tagebuch und Rezepte ansehen.',
    },
    'tutorial_dashboard_sport_tab_title': {
      'fr': 'Onglet Sport',
      'en': 'Sport Tab',
      'de': 'Sport-Tab',
    },
    'tutorial_dashboard_sport_tab_desc': {
      'fr':
          'Gère tes entraînements, sessions de cardio et suis ta progression sportive.',
      'en':
          'Manage your workouts, cardio sessions and track your sports progress.',
      'de':
          'Verwalte deine Trainings, Cardio-Einheiten und verfolge deinen sportlichen Fortschritt.',
    },
    'tutorial_dashboard_add_water_title': {
      'fr': 'Ajouter de l\'eau',
      'en': 'Add water',
      'de': 'Wasser hinzufügen',
    },
    'tutorial_dashboard_add_water_desc': {
      'fr':
          'Enregistre ta consommation d\'eau pour suivre ton hydratation quotidienne.',
      'en': 'Record your water intake to track your daily hydration.',
      'de':
          'Erfasse deinen Wasserkonsum, um deine tägliche Hydration zu verfolgen.',
    },
    'tutorial_dashboard_progress_tab_title': {
      'fr': 'Onglet Progression',
      'en': 'Progress Tab',
      'de': 'Fortschritts-Tab',
    },
    'tutorial_dashboard_progress_tab_desc': {
      'fr':
          'Consulte ton évolution de poids, ton bilan hebdomadaire et ton suivi jour par jour.',
      'en': 'View your weight progress, weekly balance and daily tracking.',
      'de':
          'Sieh dir deine Gewichtsentwicklung, Wochenbilanz und tägliche Verfolgung an.',
    },
    'tutorial_dashboard_coach_fab_title': {
      'fr': 'Coach Ryze',
      'en': 'Coach Ryze',
      'de': 'Coach Ryze',
    },
    'tutorial_dashboard_coach_fab_desc': {
      'fr':
          'Ton coach IA personnel ! Pose-lui tes questions sur la nutrition, le sport ou ta progression.',
      'en':
          'Your personal AI coach! Ask questions about nutrition, fitness or your progress.',
      'de':
          'Dein persönlicher KI-Coach! Stelle ihm Fragen zu Ernährung, Sport oder deinem Fortschritt.',
    },

    // Tutorial Nutrition
    'tutorial_nutrition_dashboard_tab_title': {
      'fr': 'Tableau de bord',
      'en': 'Dashboard',
      'de': 'Übersicht',
    },
    'tutorial_nutrition_dashboard_tab_desc': {
      'fr':
          'Vue d\'ensemble de tes calories, macros et objectifs nutritionnels.',
      'en': 'Overview of your calories, macros and nutrition goals.',
      'de': 'Überblick über deine Kalorien, Makros und Ernährungsziele.',
    },
    'tutorial_nutrition_journal_tab_title': {
      'fr': 'Journal alimentaire',
      'en': 'Food Journal',
      'de': 'Ernährungstagebuch',
    },
    'tutorial_nutrition_journal_tab_desc': {
      'fr':
          'Historique de tes repas avec analyses du Coach Ryze en temps réel.',
      'en': 'Meal history with real-time Coach Ryze analyses.',
      'de': 'Mahlzeitenhistorie mit Echtzeit-Analysen von Coach Ryze.',
    },
    'tutorial_nutrition_recipes_tab_title': {
      'fr': 'Mes recettes',
      'en': 'My Recipes',
      'de': 'Meine Rezepte',
    },
    'tutorial_nutrition_recipes_tab_desc': {
      'fr': 'Tes recettes favorites à ajouter en un clic dans tes repas.',
      'en': 'Your favorite recipes to add with one click to your meals.',
      'de':
          'Deine Lieblingsrezepte zum Hinzufügen mit einem Klick zu deinen Mahlzeiten.',
    },

    // Tutorial Dashboard Nutrition - Éléments détaillés (tutoiement + pédagogique)
    'tutorial_nutrition_calories_title': {
      'fr': 'Ton objectif calorique',
      'en': 'Your calorie goal',
      'de': 'Dein Kalorienziel',
    },
    'tutorial_nutrition_calories_desc': {
      'fr':
          'Visualise en temps réel tes calories consommées, ce qu\'il te reste, et ton objectif quotidien.',
      'en':
          'See in real-time your consumed calories, what\'s left, and your daily goal.',
      'de':
          'Sieh in Echtzeit deine verbrauchten Kalorien, was übrig ist und dein Tagesziel.',
    },
    'tutorial_nutrition_macros_title': {
      'fr': 'Équilibre tes macros',
      'en': 'Balance your macros',
      'de': 'Deine Makros ausgleichen',
    },
    'tutorial_nutrition_macros_desc': {
      'fr':
          'Protéines pour les muscles, glucides pour l\'énergie, lipides pour la santé : je t\'aide à trouver le bon équilibre.',
      'en':
          'Proteins for muscles, carbs for energy, fats for health: I help you find the right balance.',
      'de':
          'Proteine für Muskeln, Kohlenhydrate für Energie, Fette für die Gesundheit: Ich helfe dir, die richtige Balance zu finden.',
    },
    'tutorial_nutrition_hydration_meals_title': {
      'fr': 'Hydratation & Repas',
      'en': 'Hydration & Meals',
      'de': 'Hydration & Mahlzeiten',
    },
    'tutorial_nutrition_hydration_meals_desc': {
      'fr':
          'Reste hydraté avec ton suivi d\'eau et organise tes repas pour mieux répartir tes calories.',
      'en':
          'Stay hydrated with water tracking and organize your meals to better distribute calories.',
      'de':
          'Bleib hydratisiert mit Wassertracking und organisiere deine Mahlzeiten für eine bessere Kalorienverteilung.',
    },
    'tutorial_nutrition_quick_actions_title': {
      'fr': '5 façons d\'ajouter tes aliments',
      'en': '5 ways to add your foods',
      'de': '5 Wege, Lebensmittel hinzuzufügen',
    },
    'tutorial_nutrition_quick_actions_desc': {
      'fr':
          'Décris ton repas, prends une photo de ton assiette, scanne un produit, cherche dans la base ou ajoute une recette.',
      'en':
          'Describe your meal, take a photo of your plate, scan a product, search the database, or add a recipe.',
      'de':
          'Beschreibe deine Mahlzeit, mach ein Foto deines Tellers, scanne ein Produkt, suche in der Datenbank oder füge ein Rezept hinzu.',
    },

    // Tutorial Sport
    'tutorial_sport_dashboard_tab_title': {
      'fr': 'Tableau de bord',
      'en': 'Dashboard',
      'de': 'Übersicht',
    },
    'tutorial_sport_dashboard_tab_desc': {
      'fr':
          'Tes statistiques sportives de la semaine : calories, séances et historique.',
      'en': 'Your weekly sports stats: calories, sessions and history.',
      'de':
          'Deine wöchentlichen Sportstatistiken: Kalorien, Einheiten und Verlauf.',
    },
    'tutorial_sport_cardio_tab_title': {
      'fr': 'Cardio',
      'en': 'Cardio',
      'de': 'Cardio',
    },
    'tutorial_sport_cardio_tab_desc': {
      'fr':
          'Tracke tes séances cardio en temps réel : course, vélo, marche, HIIT...',
      'en':
          'Track your cardio sessions in real time: running, cycling, walking, HIIT...',
      'de':
          'Tracke deine Cardio-Einheiten in Echtzeit: Laufen, Radfahren, Gehen, HIIT...',
    },
    'tutorial_sport_musculation_tab_title': {
      'fr': 'Musculation',
      'en': 'Strength Training',
      'de': 'Krafttraining',
    },
    'tutorial_sport_musculation_tab_desc': {
      'fr':
          'Séances personnalisées par Coach Ryze, exercices avec séries et reps.',
      'en':
          'Personalized sessions by Coach Ryze, exercises with sets and reps.',
      'de':
          'Personalisierte Einheiten von Coach Ryze, Übungen mit Sätzen und Wiederholungen.',
    },
    'tutorial_sport_calories_title': {
      'fr': 'Ton énergie dépensée',
      'en': 'Your energy burned',
      'de': 'Dein Energieverbrauch',
    },
    'tutorial_sport_calories_desc': {
      'fr':
          'Visualise toutes les calories brûlées cette semaine avec ta musculation et ton cardio.',
      'en':
          'See all calories burned this week with your strength training and cardio.',
      'de':
          'Sieh alle diese Woche verbrannten Kalorien durch dein Krafttraining und Cardio.',
    },
    'tutorial_sport_sessions_title': {
      'fr': 'Ta progression hebdo',
      'en': 'Your weekly progress',
      'de': 'Dein Wochenfortschritt',
    },
    'tutorial_sport_sessions_desc': {
      'fr':
          'Suis tes séances complétées, ton streak de semaines d\'entraînement et ton temps total d\'activité.',
      'en':
          'Track your completed sessions, training weeks streak, and total activity time.',
      'de':
          'Verfolge deine abgeschlossenen Einheiten, deine Trainingswochen-Serie und deine gesamte Aktivitätszeit.',
    },
    'tutorial_sport_split_title': {
      'fr': 'Tes activités du jour',
      'en': 'Your daily activities',
      'de': 'Deine Tagesaktivitäten',
    },
    'tutorial_sport_split_desc': {
      'fr':
          'Retrouve toutes tes activités réalisées aujourd\'hui : séances de muscu et cardio avec leurs détails.',
      'en':
          'Find all your completed activities for today: strength and cardio sessions with their details.',
      'de':
          'Finde alle deine heutigen Aktivitäten: Kraft- und Cardio-Einheiten mit ihren Details.',
    },
    'tutorial_sport_actions_title': {
      'fr': 'Lance ton entraînement',
      'en': 'Start your workout',
      'de': 'Starte dein Training',
    },
    'tutorial_sport_actions_desc': {
      'fr':
          'Démarre une séance de cardio (course, vélo, HIIT), de musculation ou un programme personnalisé par Coach Ryze.',
      'en':
          'Start a cardio session (running, cycling, HIIT), strength training, or a personalized program by Coach Ryze.',
      'de':
          'Starte eine Cardio-Einheit (Laufen, Radfahren, HIIT), Krafttraining oder ein personalisiertes Programm von Coach Ryze.',
    },

    // Tutorial Cardio
    'tutorial_cardio_stats_title': {
      'fr': 'Tes performances hebdo',
      'en': 'Your weekly performance',
      'de': 'Deine Wochenleistung',
    },
    'tutorial_cardio_stats_desc': {
      'fr':
          'Suis toutes tes stats cardio de la semaine : calories brûlées, distance parcourue et temps total d\'activité.',
      'en':
          'Track all your weekly cardio stats: calories burned, distance covered and total activity time.',
      'de':
          'Verfolge alle deine wöchentlichen Cardio-Statistiken: verbrannte Kalorien, zurückgelegte Distanz und gesamte Aktivitätszeit.',
    },
    'tutorial_cardio_activities_title': {
      'fr': 'Lance une activité',
      'en': 'Start an activity',
      'de': 'Aktivität starten',
    },
    'tutorial_cardio_activities_desc': {
      'fr':
          'Sélectionne ton activité cardio : course, vélo, marche, natation, HIIT ou autre, puis démarre ta séance.',
      'en':
          'Select your cardio activity: running, cycling, walking, swimming, HIIT or other, then start your session.',
      'de':
          'Wähle deine Cardio-Aktivität: Laufen, Radfahren, Gehen, Schwimmen, HIIT oder andere, dann starte deine Einheit.',
    },
    'tutorial_cardio_last_session_title': {
      'fr': 'Ta dernière séance',
      'en': 'Your last session',
      'de': 'Deine letzte Einheit',
    },
    'tutorial_cardio_last_session_desc': {
      'fr':
          'Retrouve tous les détails de ta dernière activité cardio : type d\'activité, durée, distance parcourue et calories brûlées.',
      'en':
          'Find all details of your last cardio activity: activity type, duration, distance covered and calories burned.',
      'de':
          'Finde alle Details deiner letzten Cardio-Aktivität: Aktivitätstyp, Dauer, zurückgelegte Distanz und verbrannte Kalorien.',
    },
    'tutorial_cardio_week_sessions_title': {
      'fr': 'Toutes tes séances',
      'en': 'All your sessions',
      'de': 'Alle deine Einheiten',
    },
    'tutorial_cardio_week_sessions_desc': {
      'fr':
          'Visualise toutes tes séances cardio complétées cette semaine pour suivre ta régularité.',
      'en':
          'View all your completed cardio sessions this week to track your consistency.',
      'de':
          'Sieh alle deine abgeschlossenen Cardio-Einheiten dieser Woche, um deine Konstanz zu verfolgen.',
    },
    'tutorial_cardio_history_title': {
      'fr': 'Ton historique complet',
      'en': 'Your full history',
      'de': 'Dein vollständiger Verlauf',
    },
    'tutorial_cardio_history_desc': {
      'fr':
          'Accède à l\'historique complet de toutes tes séances cardio passées pour analyser ta progression sur le long terme.',
      'en':
          'Access the complete history of all your past cardio sessions to analyze your long-term progress.',
      'de':
          'Greife auf den vollständigen Verlauf aller vergangenen Cardio-Einheiten zu, um deinen langfristigen Fortschritt zu analysieren.',
    },

    // Tutorial Musculation
    'tutorial_musculation_stats_title': {
      'fr': 'Tes performances hebdo',
      'en': 'Your weekly performance',
      'de': 'Deine Wochenleistung',
    },
    'tutorial_musculation_stats_desc': {
      'fr':
          'Retrouve ici tes statistiques de musculation : nombre de séances, volume total et calories brûlées cette semaine.',
      'en':
          'Find here your strength training stats: number of sessions, total volume and calories burned this week.',
      'de':
          'Finde hier deine Krafttraining-Statistiken: Anzahl der Einheiten, Gesamtvolumen und verbrannte Kalorien diese Woche.',
    },
    'tutorial_musculation_manual_title': {
      'fr': 'Séance manuelle',
      'en': 'Manual session',
      'de': 'Manuelle Einheit',
    },
    'tutorial_musculation_manual_desc': {
      'fr':
          'Crée ta séance librement en ajoutant les exercices de ton choix au fur et à mesure.',
      'en':
          'Create your session freely by adding exercises of your choice as you go.',
      'de':
          'Erstelle deine Einheit frei, indem du Übungen deiner Wahl nach und nach hinzufügst.',
    },
    'tutorial_musculation_guided_title': {
      'fr': 'Séance guidée',
      'en': 'Guided session',
      'de': 'Geführte Einheit',
    },
    'tutorial_musculation_guided_desc': {
      'fr':
          'Suis un programme prédéfini avec exercices, séries et répétitions suggérées.',
      'en':
          'Follow a predefined program with suggested exercises, sets and reps.',
      'de':
          'Folge einem vordefinierten Programm mit vorgeschlagenen Übungen, Sätzen und Wiederholungen.',
    },
    'tutorial_musculation_coach_title': {
      'fr': 'Coach Ryze',
      'en': 'Coach Ryze',
      'de': 'Coach Ryze',
    },
    'tutorial_musculation_coach_desc': {
      'fr':
          'Ton coach personnel qui peut analyser tes séances, créer un programme adapté et te guider pour progresser.',
      'en':
          'Your personal coach that can analyze your sessions, create a tailored program and guide you to progress.',
      'de':
          'Dein persönlicher Coach, der deine Einheiten analysieren, ein maßgeschneidertes Programm erstellen und dich beim Fortschritt begleiten kann.',
    },
    'tutorial_musculation_history_title': {
      'fr': 'Historique de la semaine',
      'en': 'Week history',
      'de': 'Wochenverlauf',
    },
    'tutorial_musculation_history_desc': {
      'fr':
          'Consulte toutes tes séances de musculation de la semaine : exercices effectués, séries et poids utilisés.',
      'en':
          'View all your strength training sessions of the week: exercises performed, sets and weights used.',
      'de':
          'Sieh dir alle deine Krafttrainingseinheiten der Woche an: durchgeführte Übungen, Sätze und verwendete Gewichte.',
    },
    'tutorial_musculation_journal_title': {
      'fr': 'Ton journal complet',
      'en': 'Your complete journal',
      'de': 'Dein vollständiges Tagebuch',
    },
    'tutorial_musculation_journal_desc': {
      'fr':
          'Accède à l\'historique complet de toutes tes séances passées pour suivre ta progression sur le long terme.',
      'en':
          'Access the complete history of all your past sessions to track your long-term progress.',
      'de':
          'Greife auf die vollständige Historie aller vergangenen Einheiten zu, um deinen langfristigen Fortschritt zu verfolgen.',
    },
    'tutorial_musculation_progress_title': {
      'fr': 'Progression par exercice',
      'de': 'Fortschritt pro Übung',
      'en': 'Progress by exercise',
    },
    'tutorial_musculation_progress_desc': {
      'fr':
          'Visualise ta progression sur chaque exercice : charge maximale, volume total et évolution. Coach Ryze peut analyser ces données pour te guider.',
      'en':
          'Visualize your progress on each exercise: maximum load, total volume and evolution. Coach Ryze can analyze this data to guide you.',
      'de':
          'Visualisiere deinen Fortschritt bei jeder Übung: maximale Last, Gesamtvolumen und Entwicklung. Coach Ryze kann diese Daten analysieren, um dich zu führen.',
    },

    // Tutorial Progression Globale
    'tutorial_global_progress_settings_title': {
      'fr': 'Paramètres',
      'de': 'Einstellungen',
      'en': 'Settings',
    },
    'tutorial_global_progress_settings_desc': {
      'fr':
          'Accède à tes paramètres pour modifier ton profil, tes objectifs et tes préférences.',
      'en':
          'Access your settings to modify your profile, goals and preferences.',
      'de':
          'Greife auf deine Einstellungen zu, um dein Profil, deine Ziele und Präferenzen zu ändern.',
    },
    'tutorial_global_progress_weight_title': {
      'fr': 'Évolution du poids',
      'en': 'Weight evolution',
      'de': 'Gewichtsentwicklung',
    },
    'tutorial_global_progress_weight_desc': {
      'fr':
          'Suis l\'évolution de ton poids avec un graphique et tes indicateurs clés. Clique pour voir plus de détails.',
      'en':
          'Track your weight progress with a chart and key metrics. Click to see more details.',
      'de':
          'Verfolge deine Gewichtsentwicklung mit einem Diagramm und wichtigen Kennzahlen. Klicke für mehr Details.',
    },
    'tutorial_global_progress_balance_title': {
      'fr': 'Bilan hebdomadaire',
      'en': 'Weekly balance',
      'de': 'Wochenbilanz',
    },
    'tutorial_global_progress_balance_desc': {
      'fr':
          'Retrouve ici ton bilan de la semaine : objectifs caloriques atteints, hydratation, repas enregistrés et séances de sport.',
      'en':
          'Find here your weekly balance: calorie targets achieved, hydration, meals recorded and sport sessions.',
      'de':
          'Finde hier deine Wochenbilanz: erreichte Kalorienziele, Hydration, erfasste Mahlzeiten und Sporteinheiten.',
    },
    'tutorial_global_progress_tracking_title': {
      'fr': 'Suivi par jour',
      'en': 'Daily tracking',
      'de': 'Tägliches Tracking',
    },
    'tutorial_global_progress_tracking_desc': {
      'fr':
          'Visualise ton activité jour par jour : nutrition enregistrée et séances de sport réalisées.',
      'en':
          'View your daily activity: recorded nutrition and completed sport sessions.',
      'de':
          'Sieh deine tägliche Aktivität: erfasste Ernährung und abgeschlossene Sporteinheiten.',
    },

    // Legacy nutrition tutorial (non utilisé mais conservé)
    'tutorial_nutrition_ai_scanner_title': {
      'fr': 'Scanner',
      'en': 'Scanner',
      'de': 'Scanner',
    },
    'tutorial_nutrition_ai_scanner_desc': {
      'fr':
          'Prenez une photo de votre assiette et l\'application analysera automatiquement les aliments et leurs calories.',
      'en':
          'Take a picture of your plate and the app will automatically analyze the foods and their calories.',
      'de':
          'Mach ein Foto von deinem Teller und die App analysiert automatisch die Lebensmittel und ihre Kalorien.',
    },
    'tutorial_nutrition_barcode_title': {
      'fr': 'Scanner barcode',
      'en': 'Barcode Scanner',
      'de': 'Barcode-Scanner',
    },
    'tutorial_nutrition_barcode_desc': {
      'fr':
          'Scannez le code-barres d\'un produit pour obtenir instantanément ses informations nutritionnelles.',
      'en':
          'Scan a product barcode to instantly get its nutritional information.',
      'de':
          'Scanne einen Produkt-Barcode, um sofort seine Nährwertinformationen zu erhalten.',
    },
    'tutorial_nutrition_manual_title': {
      'fr': 'Recherche manuelle',
      'en': 'Manual Search',
      'de': 'Manuelle Suche',
    },
    'tutorial_nutrition_manual_desc': {
      'fr':
          'Recherchez un aliment dans notre base de données et ajoutez-le à votre journal.',
      'en': 'Search for a food in our database and add it to your journal.',
      'de':
          'Suche ein Lebensmittel in unserer Datenbank und füge es deinem Tagebuch hinzu.',
    },
    'tutorial_nutrition_recipes_title': {
      'fr': 'Recettes',
      'en': 'Recipes',
      'de': 'Rezepte',
    },
    'tutorial_nutrition_recipes_desc': {
      'fr':
          'Créez et sauvegardez vos recettes favorites pour les ajouter rapidement.',
      'en': 'Create and save your favorite recipes to add them quickly.',
      'de':
          'Erstelle und speichere deine Lieblingsrezepte, um sie schnell hinzuzufügen.',
    },
    'tutorial_nutrition_water_title': {
      'fr': 'Suivi de l\'eau',
      'en': 'Water Tracking',
      'de': 'Wasser-Tracking',
    },
    'tutorial_nutrition_water_desc': {
      'fr':
          'Suivez votre hydratation quotidienne. Restez hydraté pour maximiser vos performances !',
      'en':
          'Track your daily hydration. Stay hydrated to maximize your performance!',
      'de':
          'Verfolge deine tägliche Hydration. Bleib hydriert, um deine Leistung zu maximieren!',
    },

    // Tutorial Sport
    'tutorial_sport_start_workout_title': {
      'fr': 'Démarrer un entraînement',
      'en': 'Start Workout',
      'de': 'Training starten',
    },
    'tutorial_sport_start_workout_desc': {
      'fr':
          'Lancez une session de musculation et enregistrez vos séries, répétitions et poids.',
      'en':
          'Start a weight training session and record your sets, reps and weights.',
      'de':
          'Starte eine Krafttrainingseinheit und erfasse deine Sätze, Wiederholungen und Gewichte.',
    },
    'tutorial_sport_add_cardio_title': {
      'fr': 'Ajouter du cardio',
      'en': 'Add Cardio',
      'de': 'Cardio hinzufügen',
    },
    'tutorial_sport_add_cardio_desc': {
      'fr':
          'Enregistrez vos sessions de cardio (course, vélo, natation...) avec durée et calories brûlées.',
      'en':
          'Record your cardio sessions (running, cycling, swimming...) with duration and calories burned.',
      'de':
          'Erfasse deine Cardio-Einheiten (Laufen, Radfahren, Schwimmen...) mit Dauer und verbrannten Kalorien.',
    },
    'tutorial_sport_history_title': {
      'fr': 'Historique',
      'en': 'History',
      'de': 'Verlauf',
    },
    'tutorial_sport_history_desc': {
      'fr':
          'Consultez l\'historique de vos entraînements et suivez votre progression au fil du temps.',
      'en': 'View your workout history and track your progress over time.',
      'de':
          'Sieh dir deinen Trainingsverlauf an und verfolge deinen Fortschritt im Laufe der Zeit.',
    },

    // Tutorial Welcome Screen (Écran de bienvenue Coach Ryze)
    'tutorial_welcome_title': {
      'fr': 'Bonjour, je suis Coach Ryze ! 👋',
      'en': 'Hello, I\'m Coach Ryze! 👋',
      'de': 'Hallo, ich bin Coach Ryze! 👋',
    },
    'tutorial_welcome_subtitle': {
      'fr':
          'Ton coach personnel pour t\'accompagner dans ta transformation physique.',
      'en':
          'Your personal coach to support you in your physical transformation.',
      'de':
          'Dein persönlicher Coach, um dich bei deiner körperlichen Transformation zu begleiten.',
    },
    'tutorial_welcome_capabilities': {
      'fr': 'Voici ce que je peux faire pour toi :',
      'en': 'Here\'s what I can do for you:',
      'de': 'Hier ist, was ich für dich tun kann:',
    },
    'tutorial_welcome_feature_1': {
      'fr': 'Analyser tes repas en photo et calculer les calories',
      'en': 'Analyze your meals from photos and calculate calories',
      'de': 'Deine Mahlzeiten auf Fotos analysieren und Kalorien berechnen',
    },
    'tutorial_welcome_feature_text': {
      'fr':
          'Et si tu n\'as pas de photo, décris-moi ton repas et je m\'en occupe',
      'en':
          'And if you don\'t have a photo, describe your meal and I\'ll handle it',
      'de':
          'Und wenn du kein Foto hast, beschreibe mir deine Mahlzeit und ich kümmere mich darum',
    },
    'tutorial_welcome_feature_2': {
      'fr': 'Te conseiller sur ta nutrition personnalisée',
      'en': 'Advise you on your personalized nutrition',
      'de': 'Dich zu deiner personalisierten Ernährung beraten',
    },
    'tutorial_welcome_feature_3': {
      'fr': 'Créer des séances de sport adaptées à ton niveau',
      'en': 'Create workout sessions adapted to your level',
      'de': 'Trainingseinheiten erstellen, die an dein Niveau angepasst sind',
    },
    'tutorial_welcome_feature_4': {
      'fr': 'Analyser tes performances et ta progression',
      'en': 'Analyze your performance and progress',
      'de': 'Deine Leistung und deinen Fortschritt analysieren',
    },
    'tutorial_welcome_feature_5': {
      'fr': 'T\'aider à t\'améliorer sur chaque exercice',
      'en': 'Help you improve on each exercise',
      'de': 'Dir helfen, dich bei jeder Übung zu verbessern',
    },
    'tutorial_welcome_start': {
      'fr': 'Commencer la visite',
      'en': 'Start the tour',
      'de': 'Tour starten',
    },
    'tutorial_skip_intro': {
      'fr': 'Passer l\'introduction',
      'en': 'Skip introduction',
      'de': 'Einführung überspringen',
    },

    // Register screen
    'register.title': {
      'fr': 'Rejoins l\'aventure !',
      'en': 'Join the adventure!',
      'de': 'Schließe dich dem Abenteuer an!',
    },
    'register.subtitle': {
      'fr': 'Rejoignez-nous et commencez votre parcours fitness aujourd\'hui',
      'en': 'Join us and start your fitness journey today',
      'de': 'Schließe dich uns an und starte deine Fitnessreise noch heute',
    },
    'register.firstName': {
      'fr': 'Prénom',
      'en': 'First Name',
      'de': 'Vorname',
    },
    'register.lastName': {
      'fr': 'Nom',
      'en': 'Last Name',
      'de': 'Nachname',
    },
    'register.email': {
      'fr': 'Email',
      'en': 'Email',
      'de': 'E-Mail',
    },
    'register.password': {
      'fr': 'Mot de passe',
      'en': 'Password',
      'de': 'Passwort',
    },
    'register.confirmPassword': {
      'fr': 'Confirmer le mot de passe',
      'en': 'Confirm Password',
      'de': 'Passwort bestätigen',
    },
    'register.firstNameRequired': {
      'fr': 'Veuillez entrer votre prénom',
      'en': 'Please enter your first name',
      'de': 'Bitte gib deinen Vornamen ein',
    },
    'register.lastNameRequired': {
      'fr': 'Veuillez entrer votre nom',
      'en': 'Please enter your last name',
      'de': 'Bitte gib deinen Nachnamen ein',
    },
    'register.nameMinLength': {
      'fr': 'Le nom doit contenir au moins 2 caractères',
      'en': 'Name must be at least 2 characters',
      'de': 'Der Name muss mindestens 2 Zeichen haben',
    },
    'register.emailRequired': {
      'fr': 'Veuillez entrer votre email',
      'en': 'Please enter your email',
      'de': 'Bitte gib deine E-Mail ein',
    },
    'register.emailInvalid': {
      'fr': 'Veuillez entrer un email valide',
      'en': 'Please enter a valid email',
      'de': 'Bitte gib eine gültige E-Mail ein',
    },
    'register.passwordRequired': {
      'fr': 'Veuillez entrer un mot de passe',
      'en': 'Please enter a password',
      'de': 'Bitte gib ein Passwort ein',
    },
    'register.passwordMinLength': {
      'fr': 'Le mot de passe doit contenir au moins 8 caractères',
      'en': 'Password must be at least 8 characters',
      'de': 'Das Passwort muss mindestens 8 Zeichen haben',
    },
    'register.passwordComplexity': {
      'fr':
          'Le mot de passe doit contenir une majuscule, une minuscule et un chiffre',
      'en': 'Password must contain uppercase, lowercase, and number',
      'de':
          'Das Passwort muss Großbuchstaben, Kleinbuchstaben und eine Zahl enthalten',
    },
    'register.confirmPasswordRequired': {
      'fr': 'Veuillez confirmer votre mot de passe',
      'en': 'Please confirm your password',
      'de': 'Bitte bestätige dein Passwort',
    },
    'register.passwordsDoNotMatch': {
      'fr': 'Les mots de passe ne correspondent pas',
      'en': 'Passwords do not match',
      'de': 'Die Passwörter stimmen nicht überein',
    },
    'register.iAgreeTo': {
      'fr': 'J\'accepte les ',
      'en': 'I agree to the ',
      'de': 'Ich stimme den ',
    },
    'register.termsOfService': {
      'fr': 'Conditions d\'utilisation',
      'en': 'Terms of Service',
      'de': 'Nutzungsbedingungen',
    },
    'register.and': {
      'fr': ' et la ',
      'en': ' and ',
      'de': ' und der ',
    },
    'register.privacyPolicy': {
      'fr': 'Politique de confidentialité',
      'en': 'Privacy Policy',
      'de': 'Datenschutzrichtlinie',
    },
    'register.pleaseAcceptTerms': {
      'fr': 'Veuillez accepter les conditions d\'utilisation',
      'en': 'Please accept the terms and conditions',
      'de': 'Bitte akzeptiere die Nutzungsbedingungen',
    },
    'register.createAccount': {
      'fr': 'C\'est parti !',
      'en': 'Let\'s go!',
      'de': 'Los geht\'s!',
    },
    'register.orSignUpWith': {
      'fr': 'Ou s\'inscrire avec',
      'en': 'Or sign up with',
      'de': 'Oder registrieren mit',
    },
    'register.alreadyHaveAccount': {
      'fr': 'Vous avez déjà un compte ? ',
      'en': 'Already have an account? ',
      'de': 'Hast du bereits ein Konto? ',
    },
    'register.signIn': {
      'fr': 'Se connecter',
      'en': 'Sign In',
      'de': 'Anmelden',
    },
    'register.successMessage': {
      'fr':
          'Bienvenue dans la team Ryze ! 🎉\nTon compte a été créé avec succès !',
      'en': 'Welcome to team Ryze! 🎉\nYour account was created successfully!',
      'de':
          'Willkommen im Team Ryze! 🎉\nDein Konto wurde erfolgreich erstellt!',
    },
    'register.registrationFailed': {
      'fr': 'L\'inscription a échoué',
      'en': 'Registration failed',
      'de': 'Registrierung fehlgeschlagen',
    },
    'register.googleFailed': {
      'fr': 'L\'inscription avec Google a échoué',
      'en': 'Google registration failed',
      'de': 'Google-Registrierung fehlgeschlagen',
    },
    'register.appleFailed': {
      'fr': 'L\'inscription avec Apple a échoué',
      'en': 'Apple registration failed',
      'de': 'Apple-Registrierung fehlgeschlagen',
    },

    // ========================================
    // ERROR MESSAGES - AI Scanner & Food
    // Standard AAA: Accessible, Actionable, Appropriate
    // ========================================
    'error_generic': {
      'fr': 'Une erreur est survenue',
      'en': 'An error occurred',
      'de': 'Ein Fehler ist aufgetreten',
    },
    'error_user_not_authenticated': {
      'fr': 'Connectez-vous pour continuer',
      'en': 'Please log in to continue',
      'de': 'Bitte melde dich an, um fortzufahren',
    },
    'error_adding_food_to_meal': {
      'fr': 'Impossible d\'ajouter l\'aliment. Vérifiez votre connexion.',
      'en': 'Could not add food. Check your connection.',
      'de':
          'Lebensmittel konnte nicht hinzugefügt werden. Überprüfe deine Verbindung.',
    },
    'error_displaying_meal_selection': {
      'fr': 'Impossible d\'afficher les repas',
      'en': 'Could not display meals',
      'de': 'Mahlzeiten konnten nicht angezeigt werden',
    },
    'error_adding_to_new_meal': {
      'fr': 'Impossible de créer le repas',
      'en': 'Could not create meal',
      'de': 'Mahlzeit konnte nicht erstellt werden',
    },
    'error_camera_not_available': {
      'fr': 'Caméra non disponible',
      'en': 'Camera not available',
      'de': 'Kamera nicht verfügbar',
    },
    'error_camera_generic': {
      'fr': 'Erreur d\'accès à la caméra',
      'en': 'Camera access error',
      'de': 'Kamerazugriffsfehler',
    },
    'select_image_from_files': {
      'fr': 'Sélectionner une image',
      'en': 'Select an image',
      'de': 'Bild auswählen',
    },

    // Food List - using existing 'no_food_found' at line 1747
    // Note: close already exists earlier
    'calories_label': {
      'fr': 'Calories',
      'en': 'Calories',
      'de': 'Kalorien',
    },
    'proteins_label': {
      'fr': 'Protéines',
      'en': 'Proteins',
      'de': 'Proteine',
    },
    'carbs_label': {
      'fr': 'Glucides',
      'en': 'Carbs',
      'de': 'Kohlenhydrate',
    },
    'fats_label': {
      'fr': 'Lipides',
      'en': 'Fats',
      'de': 'Fette',
    },
    // Note: per_100g already exists at line 1787

    // ========================================
    // ERROR MESSAGES - Supabase (Backend)
    // Standard AAA: Clear, actionnable, respectful
    // ========================================
    'error_network_connection': {
      'fr': 'Impossible de se connecter. Vérifiez votre connexion internet.',
      'en': 'Cannot connect. Check your internet connection.',
      'de': 'Verbindung nicht möglich. Überprüfe deine Internetverbindung.',
    },
    'error_session_expired': {
      'fr': 'Votre session a expiré. Reconnectez-vous.',
      'en': 'Your session expired. Please log in again.',
      'de': 'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.',
    },
    'error_permission_denied': {
      'fr': 'Action non autorisée. Vérifiez vos permissions.',
      'en': 'Action not allowed. Check your permissions.',
      'de': 'Aktion nicht erlaubt. Überprüfe deine Berechtigungen.',
    },
    'error_not_found': {
      'fr': 'Élément introuvable',
      'en': 'Item not found',
      'de': 'Element nicht gefunden',
    },
    'error_server': {
      'fr': 'Erreur serveur. Réessayez dans quelques instants.',
      'en': 'Server error. Try again in a few moments.',
      'de': 'Serverfehler. Versuche es in wenigen Augenblicken erneut.',
    },
    'error_unexpected': {
      'fr': 'Une erreur inattendue est survenue',
      'en': 'An unexpected error occurred',
      'de': 'Ein unerwarteter Fehler ist aufgetreten',
    },

    // ========================================
    // COACH RYZE MESSAGES - Ton ludique & motivant
    // ========================================
    'coach_ryze_food_added': {
      'fr': '🎯 Super ! Aliment ajouté à ton journal',
      'en': '🎯 Nice! Food added to your journal',
      'de': '🎯 Super! Lebensmittel zu deinem Tagebuch hinzugefügt',
    },
    'coach_ryze_keep_going': {
      'fr': '💪 Continue comme ça !',
      'en': '💪 Keep it up!',
      'de': '💪 Weiter so!',
    },
    'coach_ryze_scan_success': {
      'fr': '✨ Scan réussi ! Analyse en cours...',
      'en': '✨ Scan successful! Analyzing...',
      'de': '✨ Scan erfolgreich! Analyse läuft...',
    },
    'coach_ryze_try_again': {
      'fr': '🤔 Hmm, réessayons ensemble',
      'en': '🤔 Hmm, let\'s try again together',
      'de': '🤔 Hmm, lass es uns nochmal versuchen',
    },

    // ========================================
    // BARCODE SCANNER
    // ========================================
    'error_barcode_scan': {
      'fr': 'Erreur lors du scan du code-barres',
      'en': 'Error scanning barcode',
      'de': 'Fehler beim Scannen des Barcodes',
    },
    'error_barcode_product_not_found': {
      'fr': 'Produit non trouvé dans la base de données',
      'en': 'Product not found in database',
      'de': 'Produkt nicht in der Datenbank gefunden',
    },

    // ========================================
    // WORKOUT SESSION
    // ========================================
    'error_saving_workout': {
      'fr': 'Impossible de sauvegarder la séance',
      'en': 'Could not save workout',
      'de': 'Training konnte nicht gespeichert werden',
    },
    'workout_saved_success': {
      'fr': '✅ Séance sauvegardée avec succès !',
      'en': '✅ Workout saved successfully!',
      'de': '✅ Training erfolgreich gespeichert!',
    },
    'confirm_discard_workout': {
      'fr': 'Abandonner cette séance ?',
      'en': 'Discard this workout?',
      'de': 'Dieses Training verwerfen?',
    },
    'confirm_discard_workout_message': {
      'fr': 'Vos données seront perdues',
      'en': 'Your data will be lost',
      'de': 'Deine Daten gehen verloren',
    },
    // Note: yes, no, cancel, confirm already exist earlier in translations

    // Camera and scanner specific
    'camera_initializing': {
      'fr': 'Initialisation de la caméra...',
      'en': 'Initializing camera...',
      'de': 'Kamera wird initialisiert...',
    },
    'error_no_food_detected': {
      'fr': 'Aucun aliment détecté',
      'en': 'No food detected',
      'de': 'Kein Lebensmittel erkannt',
    },
    'analyzed_photo': {
      'fr': 'Photo analysée',
      'en': 'Analyzed photo',
      'de': 'Foto analysiert',
    },
    'add_details_optional': {
      'fr': 'Ajoute des précisions (optionnel)',
      'en': 'Add details (optional)',
      'de': 'Details hinzufügen (optional)',
    },
    'add_ingredients_hint': {
      'fr':
          'Ajoute les ingrédients, la cuisson ou la portion pour guider l\'analyse',
      'en': 'Add ingredients, cooking method or portion to guide the analysis',
      'de':
          'Füge Zutaten, Zubereitungsart oder Portion hinzu, um die Analyse zu unterstützen',
    },
    'hint_text_example': {
      'fr': 'Ex: Salade césar avec poulet grillé, portion moyenne',
      'en': 'E.g.: Caesar salad with grilled chicken, medium portion',
      'de': 'Z.B.: Caesar-Salat mit gegrilltem Hähnchen, mittlere Portion',
    },
    'meal_dish': {
      'fr': 'Plat',
      'en': 'Dish',
      'de': 'Gericht',
    },
    'preview': {
      'fr': 'Prévisualisation',
      'en': 'Preview',
      'de': 'Vorschau',
    },
    // Note: retry already exists earlier at line 1185
    'detected_foods': {
      'fr': 'Aliments détectés',
      'en': 'Detected foods',
      'de': 'Erkannte Lebensmittel',
    },
    'detected_foods_colon': {
      'fr': 'Aliments détectés :',
      'en': 'Detected foods:',
      'de': 'Erkannte Lebensmittel:',
    },
    'error_camera': {
      'fr': 'Erreur caméra',
      'en': 'Camera error',
      'de': 'Kamerafehler',
    },
    'error_meal_selection_display': {
      'fr': 'Impossible d\'afficher la sélection de repas',
      'en': 'Could not display meal selection',
      'de': 'Mahlzeitenauswahl konnte nicht angezeigt werden',
    },

    // Barcode scanner specific
    'barcode_not_readable': {
      'fr': 'Vérifiez que le code-barres est lisible et réessayez.',
      'en': 'Make sure the barcode is readable and try again.',
      'de':
          'Stelle sicher, dass der Barcode lesbar ist und versuche es erneut.',
    },
    'openfoodfacts_disclaimer': {
      'fr':
          'Les données proviennent d\'OpenFoodFacts et peuvent être inexactes. Vérifiez avec l\'emballage et modifiez si nécessaire.',
      'en':
          'Data comes from OpenFoodFacts and may be inaccurate. Check with packaging and modify if needed.',
      'de':
          'Daten stammen von OpenFoodFacts und können ungenau sein. Prüfe mit der Verpackung und ändere bei Bedarf.',
    },
    'for_indicated_quantity': {
      'fr': 'Pour la quantité indiquée',
      'en': 'For indicated quantity',
      'de': 'Für die angegebene Menge',
    },
    // Note: proteins_label defined at line 4773 (keeping this one, removing duplicate)
    'quantity_label': {
      'fr': 'Quantité',
      'en': 'Quantity',
      'de': 'Menge',
    },
    'no_additional_info': {
      'fr': 'Aucune information supplémentaire',
      'en': 'No additional information',
      'de': 'Keine zusätzlichen Informationen',
    },
    'no_barcode_detected': {
      'fr':
          'Aucun code-barres détecté. Touchez l\'écran pour faire la mise au point et réessayez.',
      'en': 'No barcode detected. Tap the screen to focus and try again.',
      'de':
          'Kein Barcode erkannt. Tippe auf den Bildschirm zum Fokussieren und versuche es erneut.',
    },
    'error_fetching_product': {
      'fr': 'Erreur lors de la récupération du produit',
      'en': 'Error fetching product',
      'de': 'Fehler beim Abrufen des Produkts',
    },
    'product_added_to_meal': {
      'fr': 'Produit ajouté au repas',
      'en': 'Product added to meal',
      'de': 'Produkt zur Mahlzeit hinzugefügt',
    },
    'product_already_in_custom_foods': {
      'fr': '{productName} est déjà dans vos aliments personnalisés',
      'en': '{productName} is already in your custom foods',
      'de': '{productName} ist bereits in deinen eigenen Lebensmitteln',
    },
    'add_to_custom_foods_question': {
      'fr':
          'Souhaitez-vous ajouter "{productName}" à vos aliments personnalisés ?',
      'en': 'Would you like to add "{productName}" to your custom foods?',
      'de':
          'Möchtest du "{productName}" zu deinen eigenen Lebensmitteln hinzufügen?',
    },
    'must_be_logged_in': {
      'fr': 'Vous devez être connecté pour sauvegarder un aliment',
      'en': 'You must be logged in to save a food',
      'de': 'Du musst angemeldet sein, um ein Lebensmittel zu speichern',
    },
    'scanned_product': {
      'fr': 'Produit scanné',
      'en': 'Scanned product',
      'de': 'Gescanntes Produkt',
    },
    'product_added_to_custom_foods': {
      'fr': '{productName} ajouté à vos aliments personnalisés',
      'en': '{productName} added to your custom foods',
      'de': '{productName} zu deinen eigenen Lebensmitteln hinzugefügt',
    },
    'this_product': {
      'fr': 'Ce produit',
      'en': 'This product',
      'de': 'Dieses Produkt',
    },

    // Workout session specific
    'complete_set_before': {
      'fr': 'Veuillez compléter la série {setIndex} avant',
      'en': 'Please complete set {setIndex} first',
      'de': 'Bitte beende zuerst Satz {setIndex}',
    },
    'exercise_found': {
      'fr': '{count} exercice{plural} trouvé{plural}',
      'en': '{count} exercise{plural} found',
      'de': '{count} Übung{plural} gefunden',
    },
    'series_empty': {
      'fr': '{count} série{plural} vide{plural}',
      'en': '{count} empty set{plural}',
      'de': '{count} leere{plural} Satz{plural}',
    },
    'series_incomplete': {
      'fr': 'Série {setNumber} (poids saisi mais pas de reps)',
      'en': 'Set {setNumber} (weight entered but no reps)',
      'de': 'Satz {setNumber} (Gewicht eingegeben aber keine Wdh.)',
    },
    'warning_attention': {
      'fr': '⚠️ Attention',
      'en': '⚠️ Warning',
      'de': '⚠️ Achtung',
    },
    'incomplete_sets_detected': {
      'fr': 'Séries incomplètes détectées :',
      'en': 'Incomplete sets detected:',
      'de': 'Unvollständige Sätze erkannt:',
    },
    'empty_sets_will_be_removed': {
      'fr': 'Séries vides seront supprimées :',
      'en': 'Empty sets will be removed:',
      'de': 'Leere Sätze werden entfernt:',
    },
    'want_to_finish_anyway': {
      'fr': 'Voulez-vous quand même terminer la séance ?',
      'en': 'Do you want to finish the session anyway?',
      'de': 'Möchtest du die Einheit trotzdem beenden?',
    },
    'values_copied_to_set': {
      'fr': 'Valeurs copiées vers série {setNumber}',
      'en': 'Values copied to set {setNumber}',
      'de': 'Werte zu Satz {setNumber} kopiert',
    },
    'new_set_added_same_values': {
      'fr': 'Nouvelle série ajoutée avec les mêmes valeurs',
      'en': 'New set added with same values',
      'de': 'Neuer Satz mit gleichen Werten hinzugefügt',
    },
    'error_microphone_check_permissions': {
      'fr': 'Erreur micro. Vérifiez les permissions.',
      'en': 'Microphone error. Check permissions.',
      'de': 'Mikrofonfehler. Überprüfe die Berechtigungen.',
    },
    'did_not_understand_retry': {
      'fr': 'Je n\'ai pas compris. Réessayez.',
      'en': 'Did not understand. Try again.',
      'de': 'Nicht verstanden. Versuche es erneut.',
    },
    'did_not_understand_press_mic_again': {
      'fr': 'Je n\'ai pas compris. Appuyez à nouveau sur le micro.',
      'en': 'Did not understand. Press mic again.',
      'de': 'Nicht verstanden. Drücke erneut auf das Mikrofon.',
    },
    'replacing_incomplete_set': {
      'fr': 'Remplacement série incomplète',
      'en': 'Replacing incomplete set',
      'de': 'Ersetze unvollständigen Satz',
    },
    'new_set_added': {
      'fr': 'Nouvelle série ajoutée',
      'en': 'New set added',
      'de': 'Neuer Satz hinzugefügt',
    },
    'cancelled': {
      'fr': 'Annulé',
      'en': 'Cancelled',
      'de': 'Abgebrochen',
    },

    // Settings screen specific
    // Note: vegetarian and vegan already exist earlier
    'french_language': {
      'fr': 'Français',
      'en': 'Français',
      'de': 'Français',
    },
    'english_language': {
      'fr': 'English',
      'en': 'English',
      'de': 'English',
    },
    'metric_unit': {
      'fr': 'Métrique',
      'en': 'Metric',
      'de': 'Metrisch',
    },
    'imperial_unit': {
      'fr': 'Impérial',
      'en': 'Imperial',
      'de': 'Imperial',
    },
    'error_save_changes_local': {
      'fr':
          'Erreur de sauvegarde. Les modifications sont enregistrées localement.',
      'en': 'Save error. Changes are saved locally.',
      'de': 'Speicherfehler. Änderungen werden lokal gespeichert.',
    },
    'test_architecture': {
      'fr': '🔧 Test Architecture',
      'en': '🔧 Test Architecture',
      'de': '🔧 Architektur testen',
    },
    'repository_pattern': {
      'fr': 'Repository Pattern',
      'en': 'Repository Pattern',
      'de': 'Repository-Muster',
    },
    'unified_cache': {
      'fr': 'Cache unifié',
      'en': 'Unified cache',
      'de': 'Einheitlicher Cache',
    },
    'performance_optimizations': {
      'fr': 'Optimisations performances',
      'en': 'Performance optimizations',
      'de': 'Leistungsoptimierungen',
    },
    'tests_running': {
      'fr': '🧪 Tests en cours...',
      'en': '🧪 Tests running...',
      'de': '🧪 Tests laufen...',
    },
    'tests_successful_architecture_ready': {
      'fr': '✅ Tests réussis! Architecture prête',
      'en': '✅ Tests successful! Architecture ready',
      'de': '✅ Tests erfolgreich! Architektur bereit',
    },
    'tests_failed': {
      'fr': '❌ Échec des tests',
      'en': '❌ Tests failed',
      'de': '❌ Tests fehlgeschlagen',
    },
    'new_architecture_activated': {
      'fr': '🎉 Nouvelle architecture activée!',
      'en': '🎉 New architecture activated!',
      'de': '🎉 Neue Architektur aktiviert!',
    },
    'pescatarian': {
      'fr': 'Pescétarien',
      'en': 'Pescatarian',
      'de': 'Pescetarier',
    },

    // Nutrition widgets
    'add_food_to_which_meal': {
      'fr': 'À quel repas voulez-vous ajouter cet aliment ?',
      'en': 'To which meal would you like to add this food?',
      'de': 'Zu welcher Mahlzeit möchtest du dieses Lebensmittel hinzufügen?',
    },
    'items_count': {
      'fr': '{count} aliment{plural}',
      'en': '{count} item{plural}',
      'de': '{count} Artikel{plural}',
    },
    'food_added_to_meal_name': {
      'fr': '{foodName} ajouté au {mealName}',
      'en': '{foodName} added to {mealName}',
      'de': '{foodName} zu {mealName} hinzugefügt',
    },
    'error_database_add_failed': {
      'fr': 'Impossible d\'ajouter l\'aliment. Réessayez.',
      'en': 'Could not add food. Try again.',
      'de': 'Lebensmittel konnte nicht hinzugefügt werden. Versuche es erneut.',
    },
    'selected_meal': {
      'fr': 'repas sélectionné',
      'en': 'selected meal',
      'de': 'ausgewählte Mahlzeit',
    },
    'create_custom_meal': {
      'fr': 'Créer un repas personnalisé',
      'en': 'Create custom meal',
      'de': 'Eigene Mahlzeit erstellen',
    },
    'or_create_new_meal': {
      'fr': 'Ou créer un nouveau repas',
      'en': 'Or create new meal',
      'de': 'Oder neue Mahlzeit erstellen',
    },
    'start_day_well': {
      'fr': 'Commencez bien votre journée',
      'en': 'Start your day right',
      'de': 'Starte gut in den Tag',
    },
    // Note: choose_from_todays_meals already exists at line 1651
    'existing_meals': {
      'fr': 'Repas existants',
      'en': 'Existing meals',
      'de': 'Vorhandene Mahlzeiten',
    },
    'cereals_category': {
      'fr': 'Céréales',
      'en': 'Cereals',
      'de': 'Getreide',
    },
    'program_created_from_manual_session': {
      'fr': 'Programme créé à partir d\'une séance manuelle',
      'en': 'Program created from manual session',
      'de': 'Programm aus manueller Einheit erstellt',
    },
    'custom_food': {
      'fr': 'Aliment personnalisé',
      'en': 'Custom food',
      'de': 'Eigenes Lebensmittel',
    },

    // Error messages - AAA Standard
    'error_save_failed': {
      'fr': 'Impossible de sauvegarder. Vérifiez votre connexion.',
      'en': 'Could not save. Check your connection.',
      'de': 'Speichern nicht möglich. Überprüfe deine Verbindung.',
    },
    'error_delete_failed': {
      'fr': 'Impossible de supprimer. Réessayez.',
      'en': 'Could not delete. Try again.',
      'de': 'Löschen nicht möglich. Versuche es erneut.',
    },
    'error_loading_recipe': {
      'fr': 'Impossible de charger la recette.',
      'en': 'Could not load recipe.',
      'de': 'Rezept konnte nicht geladen werden.',
    },
    'error_meal_creation': {
      'fr': 'Impossible de créer le repas. Réessayez.',
      'en': 'Could not create meal. Try again.',
      'de': 'Mahlzeit konnte nicht erstellt werden. Versuche es erneut.',
    },
    'error_meal_id_generation': {
      'fr': 'Erreur technique. Réessayez.',
      'en': 'Technical error. Try again.',
      'de': 'Technischer Fehler. Versuche es erneut.',
    },

    // Permission explanations
    'permission_camera_needed_title': {
      'fr': 'Accès à la caméra nécessaire',
      'en': 'Camera access needed',
      'de': 'Kamerazugriff erforderlich',
    },
    'permission_camera_needed_message': {
      'fr':
          'Pour scanner vos aliments et analyser vos repas, l\'app a besoin d\'accéder à votre caméra.\n\nVoulez-vous ouvrir les réglages ?',
      'en':
          'To scan your food and analyze your meals, the app needs access to your camera.\n\nOpen settings?',
      'de':
          'Um deine Lebensmittel zu scannen und deine Mahlzeiten zu analysieren, benötigt die App Zugriff auf deine Kamera.\n\nEinstellungen öffnen?',
    },
    'permission_location_denied_info': {
      'fr':
          'Sans accès à votre localisation, nous utilisons des suggestions alimentaires internationales.',
      'en': 'Without location access, we use international food suggestions.',
      'de':
          'Ohne Standortzugriff verwenden wir internationale Lebensmittelvorschläge.',
    },
    'open_settings': {
      'fr': 'Ouvrir les réglages',
      'en': 'Open Settings',
      'de': 'Einstellungen öffnen',
    },

    // ═══════════════════════════════════════════════════════
    // PAYWALL CONTEXTUAL TRANSLATIONS
    // ═══════════════════════════════════════════════════════

    // Paywall - Titres contextuels
    'paywall_title_scanner': {
      'fr': '📸 Arrête de Deviner tes Calories',
      'en': '📸 Stop Guessing Your Calories',
      'de': '📸 Hör auf, deine Kalorien zu raten',
    },
    'paywall_title_barcode': {
      'fr': '📊 Valeurs Nutritionnelles Exactes',
      'en': '📊 Accurate Nutritional Values',
      'de': '📊 Genaue Nährwerte',
    },
    'paywall_title_chat': {
      'fr': '💬 Mange, Parle, C\'est Compté',
      'en': '💬 Eat, Talk, It\'s Tracked',
      'de': '💬 Iss, Sprich, Es ist erfasst',
    },
    'paywall_title_workout': {
      'fr': '💪 Entraîne-toi comme un Pro',
      'en': '💪 Train Like a Pro',
      'de': '💪 Trainiere wie ein Profi',
    },
    'paywall_title_nutrition_analysis': {
      'fr': '📊 Comprends VRAIMENT ta Nutrition',
      'en': '📊 TRULY Understand Your Nutrition',
      'de': '📊 Verstehe WIRKLICH deine Ernährung',
    },
    'paywall_title_exercise_analysis': {
      'fr': '📈 Progresse sur Chaque Exercice',
      'en': '📈 Progress on Every Exercise',
      'de': '📈 Fortschritt bei jeder Übung',
    },
    'paywall_title_generic': {
      'fr': '🐼 Transforme ton Corps',
      'en': '🐼 Transform Your Body',
      'de': '🐼 Transformiere deinen Körper',
    },

    // Paywall - Bulles du Coach
    'paywall_bubble_scanner': {
      'fr': 'Prêt à débloquer tes résultats ?',
      'en': 'Ready to unlock your results?',
      'de': 'Bereit, deine Ergebnisse freizuschalten?',
    },
    'paywall_bubble_barcode': {
      'fr': 'Scanne et tracke instantanément !',
      'en': 'Scan and track instantly!',
      'de': 'Scanne und tracke sofort!',
    },
    'paywall_bubble_chat': {
      'fr': 'Parle-moi, je comprends tout !',
      'en': 'Talk to me, I understand everything!',
      'de': 'Sprich mit mir, ich verstehe alles!',
    },
    'paywall_bubble_workout': {
      'fr': 'Je vais créer ton programme parfait !',
      'en': 'I\'ll create your perfect program!',
      'de': 'Ich werde dein perfektes Programm erstellen!',
    },
    'paywall_bubble_nutrition_analysis': {
      'fr': 'Laisse-moi analyser ta journée !',
      'en': 'Let me analyze your day!',
      'de': 'Lass mich deinen Tag analysieren!',
    },
    'paywall_bubble_exercise_analysis': {
      'fr': 'Je vais booster tes performances !',
      'en': 'I\'ll boost your performance!',
      'de': 'Ich werde deine Leistung steigern!',
    },
    'paywall_bubble_limit': {
      'fr': 'Tu as atteint ta limite gratuite !',
      'en': 'You\'ve reached your free limit!',
      'de': 'Du hast dein kostenloses Limit erreicht!',
    },
    'paywall_bubble_generic': {
      'fr': 'Prêt à débloquer tes résultats ?',
      'en': 'Ready to unlock your results?',
      'de': 'Bereit, deine Ergebnisse freizuschalten?',
    },

    // Paywall - Bénéfices Scanner
    'paywall_benefit_scanner_1': {
      'fr': 'Prends une photo, obtiens les calories en 2 secondes',
      'en': 'Take a photo, get calories in 2 seconds',
      'de': 'Mach ein Foto, erhalte Kalorien in 2 Sekunden',
    },
    'paywall_benefit_scanner_2': {
      'fr': 'Fini les estimations approximatives qui ruinent tes progrès',
      'en': 'No more rough estimates ruining your progress',
      'de':
          'Keine ungenauen Schätzungen mehr, die deinen Fortschritt ruinieren',
    },
    'paywall_benefit_scanner_3': {
      'fr': 'Scanne tes 3 repas quotidiens en moins de 30 secondes',
      'en': 'Scan your 3 daily meals in under 30 seconds',
      'de': 'Scanne deine 3 täglichen Mahlzeiten in unter 30 Sekunden',
    },

    // Paywall - Bénéfices Barcode
    'paywall_benefit_barcode_1': {
      'fr': 'Scanne le code-barre, obtiens les vraies valeurs nutritionnelles',
      'en': 'Scan the barcode, get the real nutritional values',
      'de': 'Scanne den Barcode, erhalte die echten Nährwerte',
    },
    'paywall_benefit_barcode_2': {
      'fr': 'Calories, protéines, glucides, lipides 100% précis',
      'en': '100% accurate calories, protein, carbs, fats',
      'de': '100% genaue Kalorien, Protein, Kohlenhydrate, Fett',
    },
    'paywall_benefit_barcode_3': {
      'fr': 'Tracke tes aliments en 2 secondes chrono',
      'en': 'Track your food in 2 seconds flat',
      'de': 'Tracke dein Essen in 2 Sekunden',
    },

    // Paywall - Bénéfices Chat
    'paywall_benefit_chat_1': {
      'fr': 'Dis juste "j\'ai mangé une pizza" et c\'est tracké',
      'en': 'Just say "I ate a pizza" and it\'s tracked',
      'de': 'Sag einfach "Ich habe eine Pizza gegessen" und es ist erfasst',
    },
    'paywall_benefit_chat_2': {
      'fr': 'Le moyen le PLUS rapide de tracker (3 secondes chrono)',
      'en': 'The FASTEST way to track (3 seconds flat)',
      'de': 'Der SCHNELLSTE Weg zu tracken (3 Sekunden)',
    },
    'paywall_benefit_chat_3': {
      'fr': 'Déclare tes repas en vocal pendant que tu manges',
      'en': 'Declare meals by voice while you eat',
      'de': 'Erfasse Mahlzeiten per Sprache während du isst',
    },

    // Paywall - Bénéfices Workout
    'paywall_benefit_workout_1': {
      'fr': 'Ton Coach crée des séances adaptées à TON niveau',
      'en': 'Your Coach creates sessions adapted to YOUR level',
      'de': 'Dein Coach erstellt Einheiten angepasst an DEIN Level',
    },
    'paywall_benefit_workout_2': {
      'fr': 'Progression automatique basée sur tes performances',
      'en': 'Automatic progression based on your performance',
      'de': 'Automatische Progression basierend auf deiner Leistung',
    },
    'paywall_benefit_workout_3': {
      'fr': 'Génère un workout complet en 10 secondes',
      'en': 'Generate a complete workout in 10 seconds',
      'de': 'Generiere ein komplettes Workout in 10 Sekunden',
    },

    // Paywall - Bénéfices Nutrition Analysis
    'paywall_benefit_nutrition_analysis_1': {
      'fr': 'Bilan quotidien personnalisé de ta journée',
      'en': 'Personalized daily report of your day',
      'de': 'Personalisierter Tagesbericht',
    },
    'paywall_benefit_nutrition_analysis_2': {
      'fr': 'Sais EXACTEMENT quoi ajuster pour progresser',
      'en': 'Know EXACTLY what to adjust to progress',
      'de': 'Wisse GENAU, was du anpassen musst, um Fortschritte zu machen',
    },
    'paywall_benefit_nutrition_analysis_3': {
      'fr': 'Conseils adaptés à ton objectif (sèche, prise de masse...)',
      'en': 'Advice adapted to your goal (cut, bulk...)',
      'de': 'Tipps angepasst an dein Ziel (Diät, Muskelaufbau...)',
    },

    // Paywall - Bénéfices Exercise Analysis
    'paywall_benefit_exercise_analysis_1': {
      'fr': 'Analyse de tes perfs exercice par exercice',
      'en': 'Analysis of your performance exercise by exercise',
      'de': 'Analyse deiner Leistung Übung für Übung',
    },
    'paywall_benefit_exercise_analysis_2': {
      'fr': 'Vois tes points faibles et comment les corriger',
      'en': 'See your weak points and how to fix them',
      'de': 'Sieh deine Schwachstellen und wie du sie beheben kannst',
    },
    'paywall_benefit_exercise_analysis_3': {
      'fr': 'Recommandations pour ajouter 5-10kg sur chaque mouvement',
      'en': 'Recommendations to add 5-10kg on each movement',
      'de': 'Empfehlungen, um 5-10kg bei jeder Bewegung zuzulegen',
    },

    // Paywall - Bénéfices Generic
    'paywall_benefit_generic_1': {
      'fr': 'Scans illimités - Le Coach Ryze reconnaît tout',
      'en': 'Unlimited scans - Coach Ryze recognizes everything',
      'de': 'Unbegrenzte Scans - Coach Ryze erkennt alles',
    },
    'paywall_benefit_generic_2': {
      'fr': 'Workouts personnalisés générés par ton Coach',
      'en': 'Personalized workouts by your Coach',
      'de': 'Personalisierte Workouts von deinem Coach',
    },
    'paywall_benefit_generic_3': {
      'fr': 'Bilan quotidien et conseils sur-mesure',
      'en': 'Daily report and custom advice',
      'de': 'Täglicher Bericht und maßgeschneiderte Tipps',
    },

    // Paywall - Common
    'paywall_banner_trial': {
      'fr': '3 JOURS GRATUITS',
      'en': '3 DAYS FREE',
      'de': '3 TAGE KOSTENLOS',
    },
    'paywall_cta_button': {
      'fr': 'DÉBLOQUER MON COACH\n3 JOURS GRATUITS',
      'en': 'UNLOCK MY COACH\n3 DAYS FREE',
      'de': 'MEINEN COACH FREISCHALTEN\n3 TAGE KOSTENLOS',
    },
    'paywall_then_price': {
      'fr': 'Puis 9,99€/mois • Annule en 1 clic',
      'en': 'Then €9.99/month • Cancel in 1 click',
      'de': 'Dann 9,99€/Monat • Mit 1 Klick kündbar',
    },
    'paywall_skip': {
      'fr': 'Peut-être plus tard',
      'en': 'Maybe later',
      'de': 'Vielleicht später',
    },
    'paywall_badge_annual': {
      'fr': 'Meilleure valeur',
      'en': 'Best value',
      'de': 'Bester Wert',
    },
    'paywall_badge_monthly': {
      'fr': 'Le plus choisi',
      'en': 'Most popular',
      'de': 'Am beliebtesten',
    },
    'paywall_badge_weekly': {
      'fr': 'Pour tester',
      'en': 'Try it',
      'de': 'Zum Testen',
    },
    'paywall_savings_annual': {
      'fr': 'Économise 49%',
      'en': 'Save 49%',
      'de': '49% sparen',
    },
    'paywall_annual': {
      'fr': 'Annuel',
      'en': 'Annual',
      'de': 'Jährlich',
    },
    'paywall_monthly': {
      'fr': 'Mensuel',
      'en': 'Monthly',
      'de': 'Monatlich',
    },
    'paywall_weekly': {
      'fr': 'Hebdo',
      'en': 'Weekly',
      'de': 'Wöchentlich',
    },

    // Account Management Screen
    'current_email': {
      'fr': 'Email actuel',
      'en': 'Current email',
      'de': 'Aktuelle E-Mail',
    },
    'change_email': {
      'fr': 'Changer l\'email',
      'en': 'Change email',
      'de': 'E-Mail ändern',
    },
    'new_email': {
      'fr': 'Nouvel email',
      'en': 'New email',
      'de': 'Neue E-Mail',
    },
    'email_change_info': {
      'fr': 'Un email de confirmation sera envoyé à votre nouvelle adresse',
      'en': 'A confirmation email will be sent to your new address',
      'de': 'Eine Bestätigungs-E-Mail wird an deine neue Adresse gesendet',
    },
    'change_password': {
      'fr': 'Changer le mot de passe',
      'en': 'Change password',
      'de': 'Passwort ändern',
    },
    'current_password': {
      'fr': 'Mot de passe actuel',
      'en': 'Current password',
      'de': 'Aktuelles Passwort',
    },
    'new_password': {
      'fr': 'Nouveau mot de passe',
      'en': 'New password',
      'de': 'Neues Passwort',
    },
    'confirm_password': {
      'fr': 'Confirmer le mot de passe',
      'en': 'Confirm password',
      'de': 'Passwort bestätigen',
    },
    'current_password_incorrect': {
      'fr': 'Mot de passe actuel incorrect',
      'en': 'Current password is incorrect',
      'de': 'Aktuelles Passwort ist falsch',
    },
    'password_changed_success': {
      'fr': 'Mot de passe modifié avec succès',
      'en': 'Password changed successfully',
      'de': 'Passwort erfolgreich geändert',
    },
    'error_changing_password': {
      'fr': 'Erreur lors du changement de mot de passe',
      'en': 'Error changing password',
      'de': 'Fehler beim Ändern des Passworts',
    },
    'invalid_email': {
      'fr': 'Email invalide',
      'en': 'Invalid email',
      'de': 'Ungültige E-Mail',
    },
    'email_change_confirmation_sent': {
      'fr': 'Email de confirmation envoyé. Vérifiez votre boîte de réception.',
      'en': 'Confirmation email sent. Check your inbox.',
      'de': 'Bestätigungs-E-Mail gesendet. Überprüfe deinen Posteingang.',
    },
    'error_changing_email': {
      'fr': 'Erreur lors du changement d\'email',
      'en': 'Error changing email',
      'de': 'Fehler beim Ändern der E-Mail',
    },
    'field_required': {
      'fr': 'Ce champ est requis',
      'en': 'This field is required',
      'de': 'Dieses Feld ist erforderlich',
    },
    'password_min_length': {
      'fr': 'Le mot de passe doit contenir au moins 6 caractères',
      'en': 'Password must be at least 6 characters',
      'de': 'Das Passwort muss mindestens 6 Zeichen lang sein',
    },
    'passwords_dont_match': {
      'fr': 'Les mots de passe ne correspondent pas',
      'en': 'Passwords don\'t match',
      'de': 'Passwörter stimmen nicht überein',
    },

    // Privacy Screen
    'privacy_title': {
      'fr': 'Votre vie privée nous tient à cœur',
      'en': 'Your privacy matters to us',
      'de': 'Deine Privatsphäre ist uns wichtig',
    },
    'privacy_subtitle': {
      'fr': 'Consultez nos politiques et gérez vos données',
      'en': 'Review our policies and manage your data',
      'de': 'Überprüfe unsere Richtlinien und verwalte deine Daten',
    },
    'legal_documents': {
      'fr': 'Documents légaux',
      'en': 'Legal documents',
      'de': 'Rechtliche Dokumente',
    },
    'privacy_policy': {
      'fr': 'Politique de confidentialité',
      'en': 'Privacy Policy',
      'de': 'Datenschutzerklärung',
    },
    'privacy_policy_desc': {
      'fr': 'Comment nous protégeons vos données',
      'en': 'How we protect your data',
      'de': 'Wie wir deine Daten schützen',
    },
    'terms_of_service': {
      'fr': 'Conditions d\'utilisation',
      'en': 'Terms of Service',
      'de': 'Nutzungsbedingungen',
    },
    'terms_of_service_desc': {
      'fr': 'Les règles d\'utilisation de l\'app',
      'en': 'App usage guidelines',
      'de': 'App-Nutzungsrichtlinien',
    },
    'your_data': {
      'fr': 'Vos données',
      'en': 'Your data',
      'de': 'Deine Daten',
    },
    'data_we_collect': {
      'fr': 'Données collectées',
      'en': 'Data we collect',
      'de': 'Gesammelte Daten',
    },
    'data_we_collect_desc': {
      'fr': 'Quelles informations nous recueillons',
      'en': 'What information we gather',
      'de': 'Welche Informationen wir sammeln',
    },
    'data_security': {
      'fr': 'Sécurité des données',
      'en': 'Data security',
      'de': 'Datensicherheit',
    },
    'data_security_desc': {
      'fr': 'Comment nous protégeons vos informations',
      'en': 'How we protect your information',
      'de': 'Wie wir deine Informationen schützen',
    },
    'data_sharing': {
      'fr': 'Partage de données',
      'en': 'Data sharing',
      'de': 'Datenweitergabe',
    },
    'data_sharing_desc': {
      'fr': 'Avec qui nous partageons vos données',
      'en': 'Who we share your data with',
      'de': 'Mit wem wir deine Daten teilen',
    },
    'your_rights': {
      'fr': 'Vos droits',
      'en': 'Your rights',
      'de': 'Deine Rechte',
    },
    'export_data': {
      'fr': 'Exporter mes données',
      'en': 'Export my data',
      'de': 'Meine Daten exportieren',
    },
    'export_data_desc': {
      'fr': 'Télécharger toutes vos données',
      'en': 'Download all your data',
      'de': 'Alle deine Daten herunterladen',
    },
    'oauth_no_password': {
      'fr':
          'Vous êtes connecté avec Google ou Apple. La gestion du mot de passe se fait via votre compte Google/Apple.',
      'en':
          'You are signed in with Google or Apple. Password management is handled through your Google/Apple account.',
      'de':
          'Du bist mit Google oder Apple angemeldet. Die Passwortverwaltung erfolgt über dein Google/Apple-Konto.',
    },
    'delete_account': {
      'fr': 'Supprimer le compte',
      'en': 'Delete account',
      'de': 'Konto löschen',
    },
    'delete_account_desc': {
      'fr': 'Supprimer définitivement votre compte',
      'en': 'Permanently delete your account',
      'de': 'Dein Konto dauerhaft löschen',
    },
    'delete_account_from_settings': {
      'fr':
          'Accédez à cette fonctionnalité depuis Paramètres > Compte > Supprimer le compte',
      'en': 'Access this feature from Settings > Account > Delete Account',
      'de':
          'Zugriff auf diese Funktion über Einstellungen > Konto > Konto löschen',
    },
    'data_collection_details': {
      'fr':
          'Nous collectons :\n\n• Informations de profil (nom, email, âge, genre)\n• Données nutritionnelles (aliments, recettes, objectifs caloriques)\n• Données sportives (séances d\'entraînement, performances)\n• Données de progression (poids, mesures, photos)\n\nToutes ces données sont stockées de manière sécurisée et ne sont jamais vendues à des tiers.',
      'en':
          'We collect:\n\n• Profile information (name, email, age, gender)\n• Nutrition data (foods, recipes, calorie goals)\n• Fitness data (workout sessions, performance)\n• Progress data (weight, measurements, photos)\n\nAll this data is securely stored and never sold to third parties.',
      'de':
          'Wir erfassen:\n\n• Profilinformationen (Name, E-Mail, Alter, Geschlecht)\n• Ernährungsdaten (Lebensmittel, Rezepte, Kalorienziele)\n• Fitnessdaten (Trainingseinheiten, Leistung)\n• Fortschrittsdaten (Gewicht, Maße, Fotos)\n\nAlle diese Daten werden sicher gespeichert und niemals an Dritte verkauft.',
    },
    'data_security_details': {
      'fr':
          'Vos données sont protégées par :\n\n• Chiffrement SSL/TLS pour toutes les communications\n• Stockage sécurisé dans des bases de données chiffrées\n• Authentification à deux facteurs disponible\n• Accès strictement contrôlé aux serveurs\n• Sauvegardes régulières et redondantes\n\nNous suivons les meilleures pratiques de l\'industrie pour garantir la sécurité de vos informations.',
      'en':
          'Your data is protected by:\n\n• SSL/TLS encryption for all communications\n• Secure storage in encrypted databases\n• Two-factor authentication available\n• Strictly controlled server access\n• Regular and redundant backups\n\nWe follow industry best practices to ensure the security of your information.',
      'de':
          'Deine Daten werden geschützt durch:\n\n• SSL/TLS-Verschlüsselung für alle Kommunikationen\n• Sichere Speicherung in verschlüsselten Datenbanken\n• Zwei-Faktor-Authentifizierung verfügbar\n• Streng kontrollierter Serverzugriff\n• Regelmäßige und redundante Backups\n\nWir befolgen die besten Branchenpraktiken, um die Sicherheit deiner Informationen zu gewährleisten.',
    },
    'data_sharing_details': {
      'fr':
          'Nous ne partageons JAMAIS vos données personnelles avec des tiers à des fins commerciales.\n\nNous partageons uniquement avec :\n\n• Les services d\'infrastructure nécessaires (Supabase pour le stockage)\n• Les services d\'analyse (anonymisé)\n• Les autorités légales si requis par la loi\n\nVous gardez toujours le contrôle total de vos données.',
      'en':
          'We NEVER share your personal data with third parties for commercial purposes.\n\nWe only share with:\n\n• Necessary infrastructure services (Supabase for storage)\n• Analytics services (anonymized)\n• Legal authorities if required by law\n\nYou always maintain full control of your data.',
      'de':
          'Wir teilen NIEMALS deine persönlichen Daten mit Dritten zu kommerziellen Zwecken.\n\nWir teilen nur mit:\n\n• Notwendigen Infrastrukturdiensten (Supabase für Speicherung)\n• Analysediensten (anonymisiert)\n• Rechtlichen Behörden, wenn gesetzlich vorgeschrieben\n\nDu behältst immer die volle Kontrolle über deine Daten.',
    },
    'export_data_instructions': {
      'fr':
          'Voulez-vous télécharger une copie complète de toutes vos données ? Cela inclut votre profil, aliments, recettes, séances d\'entraînement et historique de progression.\n\nUn fichier JSON sera généré et envoyé à votre email.',
      'en':
          'Would you like to download a complete copy of all your data? This includes your profile, foods, recipes, workout sessions, and progress history.\n\nA JSON file will be generated and sent to your email.',
      'de':
          'Möchtest du eine vollständige Kopie aller deiner Daten herunterladen? Dies umfasst dein Profil, Lebensmittel, Rezepte, Trainingseinheiten und Fortschrittsverlauf.\n\nEine JSON-Datei wird generiert und an deine E-Mail gesendet.',
    },
    'export_data_started': {
      'fr': 'Export démarré. Vous recevrez un email avec vos données sous peu.',
      'en': 'Export started. You will receive an email with your data shortly.',
      'de':
          'Export gestartet. Du erhältst in Kürze eine E-Mail mit deinen Daten.',
    },
    'export': {
      'fr': 'Exporter',
      'en': 'Export',
      'de': 'Exportieren',
    },

    // Help & Support Screen
    'help_support_title': {
      'fr': 'Nous sommes là pour vous aider',
      'en': 'We\'re here to help',
      'de': 'Wir sind für dich da',
    },
    'help_support_subtitle': {
      'fr': 'Contactez-nous ou consultez notre FAQ',
      'en': 'Contact us or check our FAQ',
      'de': 'Kontaktiere uns oder schau in unsere FAQ',
    },
    'quick_contact': {
      'fr': 'Contact rapide',
      'en': 'Quick contact',
      'de': 'Schnellkontakt',
    },
    'contact_email': {
      'fr': 'Email de contact',
      'en': 'Contact email',
      'de': 'Kontakt-E-Mail',
    },
    'copy_email': {
      'fr': 'Copier l\'email',
      'en': 'Copy email',
      'de': 'E-Mail kopieren',
    },
    'email_copied': {
      'fr': 'Email copié dans le presse-papier',
      'en': 'Email copied to clipboard',
      'de': 'E-Mail in Zwischenablage kopiert',
    },
    'cannot_open_email': {
      'fr': 'Impossible d\'ouvrir l\'application email',
      'en': 'Cannot open email application',
      'de': 'E-Mail-Anwendung kann nicht geöffnet werden',
    },
    'support_email_subject': {
      'fr': 'Support Ryze',
      'en': 'Ryze Support',
      'de': 'Ryze Support',
    },
    'faq': {
      'fr': 'Questions fréquentes',
      'en': 'FAQ',
      'de': 'Häufige Fragen',
    },
    'view_faq': {
      'fr': 'Voir la FAQ complète',
      'en': 'View full FAQ',
      'de': 'Vollständige FAQ ansehen',
    },
    'view_faq_desc': {
      'fr': 'Consultez toutes nos questions fréquentes',
      'en': 'Browse all our frequently asked questions',
      'de': 'Alle unsere häufig gestellten Fragen durchsuchen',
    },
    'faq_scanner': {
      'fr': 'Comment utiliser le scanner ?',
      'en': 'How to use the scanner?',
      'de': 'Wie benutze ich den Scanner?',
    },
    'faq_scanner_desc': {
      'fr': 'Utilisation du scanner alimentaire',
      'en': 'Using the food scanner',
      'de': 'Verwendung des Lebensmittelscanners',
    },
    'faq_scanner_answer': {
      'fr':
          '1. Appuyez sur le bouton Scanner\n2. Prenez une photo de votre repas\n3. L\'application analyse automatiquement les aliments\n4. Vérifiez et ajustez les portions\n5. Ajoutez au repas souhaité\n\nAstuce : Prenez la photo à la lumière naturelle pour de meilleurs résultats.',
      'en':
          '1. Tap the Scanner button\n2. Take a photo of your meal\n3. The app automatically analyzes the foods\n4. Review and adjust portions\n5. Add to desired meal\n\nTip: Take the photo in natural light for best results.',
      'de':
          '1. Tippe auf die Scanner-Taste\n2. Mache ein Foto deiner Mahlzeit\n3. Die App analysiert automatisch die Lebensmittel\n4. Überprüfe und passe die Portionen an\n5. Füge zur gewünschten Mahlzeit hinzu\n\nTipp: Mache das Foto bei natürlichem Licht für beste Ergebnisse.',
    },
    'faq_workouts': {
      'fr': 'Comment créer un programme d\'entraînement ?',
      'en': 'How to create a workout program?',
      'de': 'Wie erstelle ich ein Trainingsprogramm?',
    },
    'faq_workouts_desc': {
      'fr': 'Création et gestion des séances',
      'en': 'Creating and managing sessions',
      'de': 'Erstellen und Verwalten von Einheiten',
    },
    'faq_workouts_answer': {
      'fr':
          '1. Allez dans Sport\n2. Créez une nouvelle séance\n3. Ajoutez des exercices\n4. Définissez séries et répétitions\n5. Lancez la séance\n\nVous pouvez sauvegarder vos séances favorites pour les réutiliser rapidement.',
      'en':
          '1. Go to Sport\n2. Create a new session\n3. Add exercises\n4. Set sets and reps\n5. Start the session\n\nYou can save your favorite sessions to reuse them quickly.',
      'de':
          '1. Gehe zu Sport\n2. Erstelle eine neue Einheit\n3. Füge Übungen hinzu\n4. Lege Sätze und Wiederholungen fest\n5. Starte die Einheit\n\nDu kannst deine Lieblingseinheiten speichern, um sie schnell wiederzuverwenden.',
    },
    'faq_goals': {
      'fr': 'Comment définir mes objectifs ?',
      'en': 'How to set my goals?',
      'de': 'Wie setze ich meine Ziele?',
    },
    'faq_goals_desc': {
      'fr': 'Configuration des objectifs caloriques',
      'en': 'Setting up calorie goals',
      'de': 'Kalorienziele einrichten',
    },
    'faq_goals_answer': {
      'fr':
          'Allez dans Paramètres > Profil et renseignez :\n\n• Votre poids actuel et objectif\n• Votre niveau d\'activité\n• Votre objectif (perte, maintien, prise de masse)\n\nL\'app calculera automatiquement vos besoins caloriques et macros optimaux.',
      'en':
          'Go to Settings > Profile and enter:\n\n• Your current and target weight\n• Your activity level\n• Your goal (loss, maintenance, gain)\n\nThe app will automatically calculate your optimal calorie needs and macros.',
      'de':
          'Gehe zu Einstellungen > Profil und gib ein:\n\n• Dein aktuelles und Zielgewicht\n• Dein Aktivitätslevel\n• Dein Ziel (Abnehmen, Halten, Zunehmen)\n\nDie App berechnet automatisch deinen optimalen Kalorienbedarf und Makros.',
    },
    'faq_premium': {
      'fr': 'Qu\'est-ce que le Premium ?',
      'en': 'What is Premium?',
      'de': 'Was ist Premium?',
    },
    'faq_premium_desc': {
      'fr': 'Fonctionnalités Premium disponibles',
      'en': 'Available Premium features',
      'de': 'Verfügbare Premium-Funktionen',
    },
    'faq_premium_answer': {
      'fr':
          'Le Premium débloque :\n\n• Scanner alimentaire illimité\n• Recettes personnalisées\n• Programmes d\'entraînement avancés\n• Statistiques détaillées\n• Support prioritaire\n\n3 jours d\'essai gratuit, puis 9,99€/mois.',
      'en':
          'Premium unlocks:\n\n• Unlimited food scanner\n• Custom recipes\n• Advanced workout programs\n• Detailed statistics\n• Priority support\n\n3-day free trial, then €9.99/month.',
      'de':
          'Premium schaltet frei:\n\n• Unbegrenzter Lebensmittelscanner\n• Individuelle Rezepte\n• Fortgeschrittene Trainingsprogramme\n• Detaillierte Statistiken\n• Prioritäts-Support\n\n3 Tage gratis testen, dann 9,99€/Monat.',
    },
    'guides': {
      'fr': 'Guides',
      'en': 'Guides',
      'de': 'Anleitungen',
    },
    'getting_started': {
      'fr': 'Démarrage rapide',
      'en': 'Getting started',
      'de': 'Erste Schritte',
    },
    'getting_started_desc': {
      'fr': 'Guide pour bien débuter',
      'en': 'Guide to get started',
      'de': 'Anleitung für den Einstieg',
    },
    'getting_started_content': {
      'fr':
          'Bienvenue sur Ryze ! Voici comment commencer :\n\n1. Complétez votre profil\n2. Définissez vos objectifs\n3. Scannez votre premier repas\n4. Créez votre première séance d\'entraînement\n5. Suivez vos progrès quotidiens\n\nN\'hésitez pas à explorer toutes les fonctionnalités !',
      'en':
          'Welcome to Ryze! Here\'s how to start:\n\n1. Complete your profile\n2. Set your goals\n3. Scan your first meal\n4. Create your first workout\n5. Track your daily progress\n\nFeel free to explore all features!',
      'de':
          'Willkommen bei Ryze! So fängst du an:\n\n1. Vervollständige dein Profil\n2. Setze deine Ziele\n3. Scanne deine erste Mahlzeit\n4. Erstelle dein erstes Training\n5. Verfolge deinen täglichen Fortschritt\n\nEntdecke alle Funktionen!',
    },
    'nutrition_guide': {
      'fr': 'Guide nutrition',
      'en': 'Nutrition guide',
      'de': 'Ernährungsleitfaden',
    },
    'nutrition_guide_desc': {
      'fr': 'Comprendre la nutrition',
      'en': 'Understanding nutrition',
      'de': 'Ernährung verstehen',
    },
    'nutrition_guide_content': {
      'fr':
          'Les macronutriments :\n\n• PROTÉINES : Construction musculaire (4 kcal/g)\n• GLUCIDES : Énergie rapide (4 kcal/g)\n• LIPIDES : Énergie durable (9 kcal/g)\n\nÉquilibrez vos macros selon votre objectif :\n\n• Perte de poids : Déficit calorique\n• Prise de masse : Surplus calorique\n• Maintien : Équilibre énergétique',
      'en':
          'Macronutrients:\n\n• PROTEIN: Muscle building (4 kcal/g)\n• CARBS: Quick energy (4 kcal/g)\n• FATS: Sustained energy (9 kcal/g)\n\nBalance your macros according to your goal:\n\n• Weight loss: Caloric deficit\n• Muscle gain: Caloric surplus\n• Maintenance: Energy balance',
      'de':
          'Makronährstoffe:\n\n• PROTEIN: Muskelaufbau (4 kcal/g)\n• KOHLENHYDRATE: Schnelle Energie (4 kcal/g)\n• FETTE: Anhaltende Energie (9 kcal/g)\n\nBalanciere deine Makros nach deinem Ziel:\n\n• Gewichtsverlust: Kaloriendefizit\n• Muskelaufbau: Kalorienüberschuss\n• Halten: Energiegleichgewicht',
    },
    'workout_guide': {
      'fr': 'Guide entraînement',
      'en': 'Workout guide',
      'de': 'Trainingsanleitung',
    },
    'workout_guide_desc': {
      'fr': 'Optimiser vos séances',
      'en': 'Optimize your workouts',
      'de': 'Optimiere deine Trainings',
    },
    'workout_guide_content': {
      'fr':
          'Principes de base :\n\n• SURCHARGE PROGRESSIVE : Augmentez progressivement\n• RÉCUPÉRATION : 48h entre les mêmes muscles\n• TECHNIQUE : Priorité sur la forme\n• VARIÉTÉ : Changez régulièrement\n\nStructure d\'une séance :\n1. Échauffement (10 min)\n2. Exercices principaux (30-40 min)\n3. Retour au calme (10 min)',
      'en':
          'Basic principles:\n\n• PROGRESSIVE OVERLOAD: Gradually increase\n• RECOVERY: 48h between same muscles\n• TECHNIQUE: Prioritize form\n• VARIETY: Change regularly\n\nSession structure:\n1. Warm-up (10 min)\n2. Main exercises (30-40 min)\n3. Cool-down (10 min)',
      'de':
          'Grundprinzipien:\n\n• PROGRESSIVE ÜBERLASTUNG: Schrittweise steigern\n• ERHOLUNG: 48h zwischen denselben Muskeln\n• TECHNIK: Priorität auf Form\n• ABWECHSLUNG: Regelmäßig wechseln\n\nEinheitsstruktur:\n1. Aufwärmen (10 Min)\n2. Hauptübungen (30-40 Min)\n3. Abkühlen (10 Min)',
    },
    'technical_issues': {
      'fr': 'Problèmes techniques',
      'en': 'Technical issues',
      'de': 'Technische Probleme',
    },
    'sync_issues': {
      'fr': 'Problèmes de synchronisation',
      'en': 'Sync issues',
      'de': 'Synchronisierungsprobleme',
    },
    'sync_issues_desc': {
      'fr': 'Les données ne se synchronisent pas',
      'en': 'Data not syncing',
      'de': 'Daten werden nicht synchronisiert',
    },
    'sync_issues_solution': {
      'fr':
          'Solutions :\n\n1. Vérifiez votre connexion Internet\n2. Déconnectez-vous et reconnectez-vous\n3. Forcez la fermeture de l\'app\n4. Vérifiez les mises à jour disponibles\n\nSi le problème persiste, contactez le support.',
      'en':
          'Solutions:\n\n1. Check your Internet connection\n2. Sign out and sign back in\n3. Force close the app\n4. Check for available updates\n\nIf the problem persists, contact support.',
      'de':
          'Lösungen:\n\n1. Überprüfe deine Internetverbindung\n2. Melde dich ab und wieder an\n3. Erzwinge das Schließen der App\n4. Prüfe auf verfügbare Updates\n\nWenn das Problem weiterhin besteht, kontaktiere den Support.',
    },
    'camera_issues': {
      'fr': 'Problèmes de caméra',
      'en': 'Camera issues',
      'de': 'Kameraprobleme',
    },
    'camera_issues_desc': {
      'fr': 'La caméra ne fonctionne pas',
      'en': 'Camera not working',
      'de': 'Kamera funktioniert nicht',
    },
    'camera_issues_solution': {
      'fr':
          'Solutions :\n\n1. Vérifiez les permissions dans Réglages\n2. Redémarrez l\'application\n3. Redémarrez votre appareil\n4. Réinstallez l\'app si nécessaire\n\nAssurez-vous d\'avoir autorisé l\'accès à la caméra dans les réglages de votre téléphone.',
      'en':
          'Solutions:\n\n1. Check permissions in Settings\n2. Restart the app\n3. Restart your device\n4. Reinstall the app if necessary\n\nMake sure you\'ve allowed camera access in your phone settings.',
      'de':
          'Lösungen:\n\n1. Überprüfe die Berechtigungen in den Einstellungen\n2. Starte die App neu\n3. Starte dein Gerät neu\n4. Installiere die App bei Bedarf neu\n\nStelle sicher, dass du den Kamerazugriff in den Telefoneinstellungen erlaubt hast.',
    },
    'report_bug': {
      'fr': 'Signaler un bug',
      'en': 'Report a bug',
      'de': 'Fehler melden',
    },
    'report_bug_desc': {
      'fr': 'Rapporter un problème technique',
      'en': 'Report a technical issue',
      'de': 'Ein technisches Problem melden',
    },
    'contact_support': {
      'fr': 'Contacter le support',
      'en': 'Contact support',
      'de': 'Support kontaktieren',
    },

    // About Screen
    'about_slogan': {
      'fr': 'Votre coach fitness & nutrition',
      'en': 'Your fitness & nutrition coach',
      'de': 'Dein Fitness- & Ernährungscoach',
    },
    'version': {
      'fr': 'Version',
      'en': 'Version',
      'de': 'Version',
    },
    'about_app': {
      'fr': 'À propos de l\'app',
      'en': 'About the app',
      'de': 'Über die App',
    },
    'about_description': {
      'fr':
          'Ryze est votre compagnon intelligent pour atteindre vos objectifs de santé et de fitness. Nous rendons le suivi nutritionnel et sportif simple, précis et motivant.',
      'en':
          'Ryze is your smart companion to achieve your health and fitness goals. We make nutrition and fitness tracking simple, accurate, and motivating.',
      'de':
          'Ryze ist dein intelligenter Begleiter, um deine Gesundheits- und Fitnessziele zu erreichen. Wir machen Ernährungs- und Fitness-Tracking einfach, genau und motivierend.',
    },
    'key_features': {
      'fr': 'Fonctionnalités principales',
      'en': 'Key features',
      'de': 'Hauptfunktionen',
    },
    'feature_ai_scanner': {
      'fr': 'Scanner : Reconnaissance instantanée des aliments',
      'en': 'Scanner: Instant food recognition',
      'de': 'Scanner: Sofortige Lebensmittelerkennung',
    },
    'feature_nutrition': {
      'fr': 'Nutrition : Suivi calories et macros détaillé',
      'en': 'Nutrition: Detailed calorie and macro tracking',
      'de': 'Ernährung: Detailliertes Kalorien- und Makro-Tracking',
    },
    'feature_workouts': {
      'fr': 'Sport : Programmes d\'entraînement personnalisés',
      'en': 'Sport: Personalized workout programs',
      'de': 'Sport: Personalisierte Trainingsprogramme',
    },
    'feature_goals': {
      'fr': 'Objectifs : Atteindre votre poids idéal',
      'en': 'Goals: Reach your ideal weight',
      'de': 'Ziele: Erreiche dein Idealgewicht',
    },
    'feature_progress': {
      'fr': 'Progression : Statistiques et graphiques détaillés',
      'en': 'Progress: Detailed statistics and charts',
      'de': 'Fortschritt: Detaillierte Statistiken und Diagramme',
    },
    'made_with_love': {
      'fr': 'Fait avec ❤️ pour votre santé',
      'en': 'Made with ❤️ for your health',
      'de': 'Mit ❤️ für deine Gesundheit gemacht',
    },

    // Health Disclaimer (Required by Apple App Store for health/fitness apps)
    'health_disclaimer_title': {
      'fr': 'Avertissement santé',
      'en': 'Health Disclaimer',
      'de': 'Gesundheitshinweis',
    },
    'health_disclaimer_text': {
      'fr':
          'Ryze est une application de suivi nutritionnel et fitness destinée à des fins d\'information générale uniquement. Elle ne constitue pas un avis médical, un diagnostic ou un traitement. Consultez toujours un professionnel de santé qualifié avant de commencer un nouveau programme alimentaire ou sportif, particulièrement si vous avez des conditions médicales préexistantes. Les informations nutritionnelles sont fournies à titre indicatif et peuvent varier.',
      'en':
          'Ryze is a nutrition and fitness tracking app intended for general informational purposes only. It does not constitute medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional before starting any new diet or exercise program, especially if you have pre-existing medical conditions. Nutritional information is provided for reference and may vary.',
      'de':
          'Ryze ist eine Ernährungs- und Fitness-Tracking-App, die nur allgemeinen Informationszwecken dient. Sie stellt keine medizinische Beratung, Diagnose oder Behandlung dar. Konsultiere immer einen qualifizierten Gesundheitsexperten, bevor du ein neues Diät- oder Trainingsprogramm beginnst, besonders wenn du bereits bestehende gesundheitliche Probleme hast. Nährwertangaben dienen als Referenz und können variieren.',
    },

    // Delete Account Screen
    'delete_account_warning': {
      'fr': '⚠️ ATTENTION : Action irréversible',
      'en': '⚠️ WARNING: Irreversible action',
      'de': '⚠️ WARNUNG: Unwiderrufliche Aktion',
    },
    'delete_account_warning_desc': {
      'fr':
          'La suppression de votre compte est définitive. Toutes vos données seront perdues sans possibilité de récupération.',
      'en':
          'Account deletion is permanent. All your data will be lost with no possibility of recovery.',
      'de':
          'Die Kontolöschung ist dauerhaft. Alle deine Daten gehen verloren ohne Möglichkeit der Wiederherstellung.',
    },
    'data_to_be_deleted': {
      'fr': 'Données qui seront supprimées',
      'en': 'Data that will be deleted',
      'de': 'Daten, die gelöscht werden',
    },
    'profile_data': {
      'fr': 'Données de profil',
      'en': 'Profile data',
      'de': 'Profildaten',
    },
    'nutrition_data': {
      'fr': 'Données nutritionnelles',
      'en': 'Nutrition data',
      'de': 'Ernährungsdaten',
    },
    'workout_data': {
      'fr': 'Données d\'entraînement',
      'en': 'Workout data',
      'de': 'Trainingsdaten',
    },
    'goals_data': {
      'fr': 'Objectifs',
      'en': 'Goals',
      'de': 'Ziele',
    },
    'progress_data': {
      'fr': 'Données de progression',
      'en': 'Progress data',
      'de': 'Fortschrittsdaten',
    },
    'health_data': {
      'fr': 'Données de santé',
      'en': 'Health data',
      'de': 'Gesundheitsdaten',
    },
    'achievements_data': {
      'fr': 'Récompenses',
      'en': 'Achievements',
      'de': 'Erfolge',
    },
    'subscription_info': {
      'fr':
          'Note : Votre abonnement doit être annulé séparément dans les réglages de l\'App Store',
      'en':
          'Note: Your subscription must be canceled separately in App Store settings',
      'de':
          'Hinweis: Dein Abonnement muss separat in den App Store-Einstellungen gekündigt werden',
    },
    'confirm_deletion': {
      'fr': 'Confirmer la suppression',
      'en': 'Confirm deletion',
      'de': 'Löschung bestätigen',
    },
    'understand_permanent': {
      'fr': 'Je comprends que cette action est permanente et irréversible',
      'en': 'I understand this action is permanent and irreversible',
      'de': 'Ich verstehe, dass diese Aktion dauerhaft und unwiderruflich ist',
    },
    'accept_data_loss': {
      'fr': 'J\'accepte de perdre toutes mes données définitivement',
      'en': 'I accept to permanently lose all my data',
      'de': 'Ich akzeptiere, alle meine Daten dauerhaft zu verlieren',
    },
    'type_delete_to_confirm': {
      'fr': 'Veuillez taper DELETE pour confirmer',
      'en': 'Please type DELETE to confirm',
      'de': 'Bitte gib DELETE ein, um zu bestätigen',
    },
    'type_delete_to_confirm_label': {
      'fr': 'Tapez "DELETE" pour confirmer :',
      'en': 'Type "DELETE" to confirm:',
      'de': 'Gib "DELETE" ein, um zu bestätigen:',
    },
    'confirm_checkboxes_required': {
      'fr': 'Veuillez cocher toutes les cases de confirmation',
      'en': 'Please check all confirmation boxes',
      'de': 'Bitte aktiviere alle Bestätigungsfelder',
    },
    'final_confirmation': {
      'fr': 'Confirmation finale',
      'en': 'Final confirmation',
      'de': 'Endgültige Bestätigung',
    },
    'final_confirmation_message': {
      'fr':
          'Êtes-vous absolument certain de vouloir supprimer votre compte ? Cette action ne peut pas être annulée.',
      'en':
          'Are you absolutely sure you want to delete your account? This action cannot be undone.',
      'de':
          'Bist du absolut sicher, dass du dein Konto löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.',
    },
    'delete_permanently': {
      'fr': 'Supprimer définitivement',
      'en': 'Delete permanently',
      'de': 'Dauerhaft löschen',
    },
    'delete_my_account': {
      'fr': 'Supprimer mon compte',
      'en': 'Delete my account',
      'de': 'Mein Konto löschen',
    },
    'account_deleted_success': {
      'fr':
          'Votre compte a été supprimé avec succès. Au revoir et bonne chance dans vos objectifs !',
      'en':
          'Your account has been successfully deleted. Goodbye and good luck with your goals!',
      'de':
          'Dein Konto wurde erfolgreich gelöscht. Auf Wiedersehen und viel Erfolg bei deinen Zielen!',
    },
    'error_deleting_account': {
      'fr':
          'Erreur lors de la suppression du compte. Veuillez réessayer ou contacter le support.',
      'en': 'Error deleting account. Please try again or contact support.',
      'de':
          'Fehler beim Löschen des Kontos. Bitte versuche es erneut oder kontaktiere den Support.',
    },

    // Subscription Management
    'manage_subscription': {
      'fr': 'Gérer mon abonnement',
      'en': 'Manage subscription',
      'de': 'Mein Abonnement verwalten',
    },
    'error_opening_subscriptions': {
      'fr': 'Impossible d\'ouvrir la gestion des abonnements',
      'en': 'Cannot open subscription management',
      'de': 'Abonnementverwaltung kann nicht geöffnet werden',
    },

    // Forgot Password
    'forgot_password_title': {
      'fr': 'Mot de passe oublié ?',
      'en': 'Forgot password?',
      'de': 'Passwort vergessen?',
    },
    'forgot_password_desc': {
      'fr': 'Recevez un lien par email pour réinitialiser votre mot de passe.',
      'en': 'Receive an email link to reset your password.',
      'de': 'Erhalte einen Link per E-Mail, um dein Passwort zurückzusetzen.',
    },
    'send_reset_link': {
      'fr': 'Envoyer le lien',
      'en': 'Send reset link',
      'de': 'Link senden',
    },
    'reset_link_sent': {
      'fr': 'Lien de réinitialisation envoyé ! Vérifiez votre boîte mail.',
      'en': 'Reset link sent! Check your inbox.',
      'de': 'Link zum Zurücksetzen gesendet! Überprüfe deinen Posteingang.',
    },
    'error_sending_reset_link': {
      'fr': 'Erreur lors de l\'envoi du lien',
      'en': 'Error sending reset link',
      'de': 'Fehler beim Senden des Links',
    },

    // ==================== COACH CHAT ====================
    'coach_ryze': {
      'fr': 'Coach Ryze',
      'en': 'Coach Ryze',
      'de': 'Coach Ryze',
    },
    'coach_chat_title': {
      'fr': 'Coach Ryze',
      'en': 'Coach Ryze',
      'de': 'Coach Ryze',
    },
    'coach_chat_subtitle': {
      'fr': 'Ton coach fitness & nutrition 24/7',
      'en': 'Your 24/7 fitness & nutrition coach',
      'de': 'Dein 24/7 Fitness- & Ernährungscoach',
    },
    'coach_chat_welcome': {
      'fr': 'Salut ! Je suis Coach Ryze',
      'en': 'Hi! I\'m Coach Ryze',
      'de': 'Hallo! Ich bin Coach Ryze',
    },
    'coach_chat_welcome_subtitle': {
      'fr':
          'Ton coach fitness et nutrition personnel, disponible 24/7. Pose-moi toutes tes questions !',
      'en':
          'Your personal fitness and nutrition coach, available 24/7. Ask me anything!',
      'de':
          'Dein persönlicher Fitness- und Ernährungscoach, 24/7 verfügbar. Frag mich alles!',
    },
    'coach_chat_how_can_i_help': {
      'fr': 'Comment puis-je t\'aider ?',
      'en': 'How can I help you?',
      'de': 'Wie kann ich dir helfen?',
    },
    'coach_chat_start_conversation': {
      'fr': 'Démarrer une conversation',
      'en': 'Start a conversation',
      'de': 'Gespräch starten',
    },
    'coach_chat_new_conversation': {
      'fr': 'Nouvelle conversation',
      'en': 'New conversation',
      'de': 'Neues Gespräch',
    },
    'coach_chat_message_placeholder': {
      'fr': 'Message Coach Ryze...',
      'en': 'Message Coach Ryze...',
      'de': 'Nachricht an Coach Ryze...',
    },
    'coach_chat_listening': {
      'fr': 'Écoute...',
      'en': 'Listening...',
      'de': 'Höre zu...',
    },
    'coach_chat_typing': {
      'fr': 'En train d\'écrire...',
      'en': 'Typing...',
      'de': 'Schreibt...',
    },
    'coach_chat_messages': {
      'fr': 'messages',
      'en': 'messages',
      'de': 'Nachrichten',
    },
    'coach_chat_free_messages_total': {
      'fr': '10 messages gratuits',
      'en': '10 free messages',
      'de': '10 kostenlose Nachrichten',
    },
    'coach_chat_remaining': {
      'fr': 'restants',
      'en': 'remaining',
      'de': 'übrig',
    },
    'coach_chat_limit_reached': {
      'fr': 'Limite atteinte',
      'en': 'Limit reached',
      'de': 'Limit erreicht',
    },
    'coach_chat_limit_reached_message': {
      'fr':
          'Tu as utilisé tes 10 messages gratuits. Passe à Premium pour des conversations illimitées avec Coach Ryze !',
      'en':
          'You\'ve used your 10 free messages. Upgrade to Premium for unlimited conversations with Coach Ryze!',
      'de':
          'Du hast deine 10 kostenlosen Nachrichten verwendet. Upgrade auf Premium für unbegrenzte Gespräche mit Coach Ryze!',
    },
    'coach_chat_upgrade_to_premium': {
      'fr': 'Passer à Premium',
      'en': 'Upgrade to Premium',
      'de': 'Auf Premium upgraden',
    },
    'coach_chat_later': {
      'fr': 'Plus tard',
      'en': 'Later',
      'de': 'Später',
    },
    'coach_chat_delete_conversation': {
      'fr': 'Supprimer la conversation ?',
      'en': 'Delete conversation?',
      'de': 'Gespräch löschen?',
    },
    'coach_chat_delete_irreversible': {
      'fr': 'Cette action est irréversible.',
      'en': 'This action cannot be undone.',
      'de': 'Diese Aktion kann nicht rückgängig gemacht werden.',
    },
    'coach_chat_cancel': {
      'fr': 'Annuler',
      'en': 'Cancel',
      'de': 'Abbrechen',
    },
    'coach_chat_delete': {
      'fr': 'Supprimer',
      'en': 'Delete',
      'de': 'Löschen',
    },
    'coach_chat_error': {
      'fr': 'Erreur',
      'en': 'Error',
      'de': 'Fehler',
    },
    'coach_chat_error_sending': {
      'fr': 'Erreur lors de l\'envoi du message',
      'en': 'Error sending message',
      'de': 'Fehler beim Senden der Nachricht',
    },
    'coach_chat_error_loading': {
      'fr': 'Erreur lors du chargement',
      'en': 'Error loading',
      'de': 'Fehler beim Laden',
    },
    'coach_chat_retry': {
      'fr': 'Réessayer',
      'en': 'Retry',
      'de': 'Erneut versuchen',
    },
    // Suggestions
    'coach_chat_suggestion_dinner': {
      'fr': 'Que manger pour le dîner ?',
      'en': 'What should I eat for dinner?',
      'de': 'Was soll ich zum Abendessen essen?',
    },
    'coach_chat_suggestion_leg_workout': {
      'fr': 'Un workout pour les jambes ?',
      'en': 'A leg workout?',
      'de': 'Ein Beintraining?',
    },
    'coach_chat_suggestion_macros': {
      'fr': 'Comment atteindre mes macros ?',
      'en': 'How to hit my macros?',
      'de': 'Wie erreiche ich meine Makros?',
    },
    'coach_chat_suggestion_snack': {
      'fr': 'Idée de snack protéiné',
      'en': 'Protein snack idea',
      'de': 'Protein-Snack-Idee',
    },
    'coach_chat_premium_unlimited': {
      'fr': 'Illimité',
      'en': 'Unlimited',
      'de': 'Unbegrenzt',
    },

    // Microphone permission dialog
    'mic_permission_title': {
      'fr': 'Parler au Coach',
      'en': 'Talk to Coach',
      'de': 'Mit Coach sprechen',
    },
    'mic_permission_description': {
      'fr':
          'Pour utiliser la commande vocale, Ryze a besoin d\'accéder au microphone de ton appareil.',
      'en':
          'To use voice commands, Ryze needs access to your device\'s microphone.',
      'de':
          'Um Sprachbefehle zu verwenden, benötigt Ryze Zugriff auf das Mikrofon deines Geräts.',
    },
    'mic_permission_feature_chat': {
      'fr': 'Dicter tes messages au coach au lieu de taper',
      'en': 'Dictate messages to coach instead of typing',
      'de': 'Nachrichten an den Coach diktieren statt tippen',
    },
    'mic_permission_feature_workout': {
      'fr': 'Enregistrer tes séries mains-libres pendant l\'entraînement',
      'en': 'Record your sets hands-free during workouts',
      'de': 'Sätze während des Trainings freihändig aufzeichnen',
    },
    'mic_permission_privacy': {
      'fr':
          'Ton audio n\'est jamais stocké. Il est traité en temps réel puis supprimé.',
      'en':
          'Your audio is never stored. It\'s processed in real-time then deleted.',
      'de':
          'Dein Audio wird nie gespeichert. Es wird in Echtzeit verarbeitet und dann gelöscht.',
    },
    'mic_permission_continue': {
      'fr': 'Continuer',
      'en': 'Continue',
      'de': 'Weiter',
    },
    'mic_permission_not_now': {
      'fr': 'Pas maintenant',
      'en': 'Not now',
      'de': 'Nicht jetzt',
    },
    // Weekly Bilan Settings
    'weekly_bilan_enabled': {
      'fr': 'Bilan hebdomadaire',
      'en': 'Weekly check-in',
      'de': 'Wöchentlicher Check-in',
    },
    'weekly_bilan_day': {
      'fr': 'Jour du bilan',
      'en': 'Check-in day',
      'de': 'Check-in Tag',
    },
    'weekly_bilan_hour': {
      'fr': 'Heure du bilan',
      'en': 'Check-in time',
      'de': 'Check-in Zeit',
    },
    'monday': {
      'fr': 'Lundi',
      'en': 'Monday',
      'de': 'Montag',
    },
    'tuesday': {
      'fr': 'Mardi',
      'en': 'Tuesday',
      'de': 'Dienstag',
    },
    'wednesday': {
      'fr': 'Mercredi',
      'en': 'Wednesday',
      'de': 'Mittwoch',
    },
    'thursday': {
      'fr': 'Jeudi',
      'en': 'Thursday',
      'de': 'Donnerstag',
    },
    'friday': {
      'fr': 'Vendredi',
      'en': 'Friday',
      'de': 'Freitag',
    },
    'saturday': {
      'fr': 'Samedi',
      'en': 'Saturday',
      'de': 'Samstag',
    },
    'sunday': {
      'fr': 'Dimanche',
      'en': 'Sunday',
      'de': 'Sonntag',
    },
  };

  /// Getter public pour accéder aux traductions (utilisé par TranslationChecker)
  static Map<String, Map<String, String>> get translations => _translations;

  static String get(String key, String languageCode) {
    final trans = _translations[key];
    if (trans == null) {
      return key; // Retourne la clé si pas de traduction trouvée
    }

    return trans[languageCode] ?? trans['fr'] ?? key;
  }
}

// Extension pour simplifier l'utilisation
extension StringTranslation on String {
  String tr(String languageCode) {
    return AppTranslations.get(this, languageCode);
  }
}

// Helper function to get translations with BuildContext
String tr(BuildContext context, String key) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return AppTranslations.get(key, languageCode);
}
