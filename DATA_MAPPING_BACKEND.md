# 🗄️ MAPPING COMPLET DES DONNÉES - RYZE APP

## 📋 ANALYSE PAGE PAR PAGE DES DONNÉES NÉCESSAIRES

### 🎯 OBJECTIF
Ce document identifie toutes les données nécessaires pour chaque page/composant de l'application Ryze afin de définir l'architecture backend et les tables de base de données requises.

---

## 🚀 1. ONBOARDING - Données Collectées

### 📊 Données Utilisateur de Base
```json
{
  "user_id": "string (UUID)",
  "gender": "string", // 'Homme', 'Femme', 'Autre'
  "birth_day": "string", // '1' à '31'
  "birth_month": "string", // '1' à '12' 
  "birth_year": "string", // ex: '2000'
  "age": "string", // calculé automatiquement
  "height": "string", // en cm ou inches selon isMetric
  "weight": "string", // en kg ou lbs selon isMetric
  "is_metric": "boolean", // true = métrique, false = impérial
  "activity_level": "string", // 'low', 'moderate', 'high'
  "goal": "string", // 'lose', 'maintain', 'gain'
  "obstacles": ["string"], // liste des obstacles sélectionnés
  "restrictions": ["string"], // liste des restrictions alimentaires
  "is_onboarded": "boolean",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### 📱 Macronutriments Calculés
```json
{
  "user_id": "string (FK)",
  "bmr": "double", // Métabolisme de base calculé
  "tdee": "double", // Dépense énergétique totale
  "daily_calories": "int", // Objectif calorique journalier
  "protein_percentage": "double", // 0.30 par défaut
  "carbs_percentage": "double", // 0.40 par défaut  
  "fat_percentage": "double", // 0.30 par défaut
  "protein_grams": "int", // Protéines en grammes
  "carbs_grams": "int", // Glucides en grammes
  "fat_grams": "int", // Lipides en grammes
  "has_custom_macros": "boolean",
  "calculated_at": "timestamp"
}
```

### 📋 Référentiels Statiques Nécessaires

#### Table: activity_levels
```json
{
  "id": "string", // 'low', 'moderate', 'high'
  "name": "string", // 'Peu actif', 'Modérément actif', 'Très actif'
  "description": "string", // '0-2 jours par semaine', etc.
  "factor": "double", // 1.2, 1.55, 1.8
  "icon": "string" // 'house', 'bike', 'dumbbell'
}
```

#### Table: goals
```json
{
  "id": "string", // 'lose', 'maintain', 'gain'
  "name": "string", // 'Perdre du poids', etc.
  "description": "string", // 'Déficit calorique contrôlé', etc.
  "calorie_adjustment": "int", // -500, 0, +300
  "icon": "string" // 'trendingDown', 'target', 'trendingUp'
}
```

#### Table: obstacles
```json
{
  "id": "string",
  "name": "string", // 'Manque de temps', etc.
  "icon": "string" // 'clock', 'battery', etc.
}
```

#### Table: dietary_restrictions
```json
{
  "id": "string",
  "name": "string", // 'Végétarien', 'Végétalien', etc.
  "icon": "string" // 'leaf', 'sprout', etc.
}
```

---

## 🏠 2. DASHBOARD PRINCIPAL - Données Affichées

### 👤 Profil Utilisateur Gamifié
```json
{
  "user_id": "string (FK)",
  "name": "string", // 'Rihab'
  "streak": "int", // Jours consécutifs
  "today_score": "int", // Score du jour (0-100)
  "today_xp": "int", // XP gagné aujourd'hui
  "total_xp": "int", // XP total accumulé
  "level": "int", // Niveau utilisateur
  "is_premium": "boolean",
  "photos_used_today": "int", // Compteur photos IA
  "avatar_url": "string?",
  "updated_at": "timestamp"
}
```

### 📈 Objectifs Journaliers
```json
{
  "goal_id": "string (UUID)",
  "user_id": "string (FK)",
  "date": "date", // Date du jour
  "goal_type": "string", // 'meals', 'water', 'calories', 'workout'
  "label": "string", // 'Suivre mes repas aujourd'hui'
  "current_value": "double", // Valeur actuelle
  "target_value": "double", // Valeur cible
  "unit": "string", // '', 'L', 'cal', etc.
  "progress": "int", // Pourcentage 0-100
  "xp_reward": "int", // XP à gagner
  "is_completed": "boolean",
  "completed_at": "timestamp?"
}
```

### ⚡ Actions Rapides
```json
{
  "action_id": "string",
  "user_id": "string (FK)",
  "action_type": "string", // 'add_meal', 'add_water', 'take_photo', etc.
  "label": "string",
  "icon": "string",
  "is_premium_required": "boolean",
  "is_disabled": "boolean",
  "usage_count": "int", // Compteur d'utilisation
  "last_used": "timestamp?"
}
```

### 🏆 Statistiques Communautaires
```json
{
  "stat_id": "string (UUID)",
  "active_users": "int", // 2847
  "top_challenge": "string", // '30 jours sans sucre'
  "completed_goals_today": "int", // 1250
  "updated_at": "timestamp"
}
```

---

## 🍎 3. SECTION NUTRITION - Données Complexes

### 📊 Profil Nutritionnel Journalier
```json
{
  "nutrition_day_id": "string (UUID)",
  "user_id": "string (FK)", 
  "date": "date",
  "target_calories": "int",
  "current_calories": "int",
  "target_protein": "int",
  "current_protein": "int", 
  "target_carbs": "int",
  "current_carbs": "int",
  "target_fat": "int",
  "current_fat": "int",
  "water_level": "double", // 0.0 à 1.0 (1.0 = 2L)
  "water_ml": "int", // Millilitres consommés
  "updated_at": "timestamp"
}
```

### 🍽️ Repas et Aliments
```json
// Table: meals
{
  "meal_id": "string (UUID)",
  "user_id": "string (FK)",
  "date": "date",
  "meal_type": "string", // 'breakfast', 'lunch', 'dinner', 'snack'
  "name": "string", // Nom du repas
  "time": "time?", // Heure du repas
  "total_calories": "int",
  "total_protein": "int",
  "total_carbs": "int", 
  "total_fat": "int",
  "is_completed": "boolean",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}

// Table: meal_foods (relation many-to-many)
{
  "meal_food_id": "string (UUID)",
  "meal_id": "string (FK)",
  "food_id": "string (FK)",
  "quantity": "double", // Quantité consommée
  "unit": "string", // 'g', 'ml', 'portion', etc.
  "calories": "int", // Calories pour cette quantité
  "protein": "int",
  "carbs": "int",
  "fat": "int"
}
```

### 🥗 Base de Données Alimentaire
```json
// Table: foods
{
  "food_id": "string (UUID)",
  "name": "string",
  "brand": "string?", // Marque du produit
  "barcode": "string?", // Code-barres
  "category": "string", // 'fruits', 'légumes', 'viandes', etc.
  "calories_per_100g": "int",
  "protein_per_100g": "double",
  "carbs_per_100g": "double", 
  "fat_per_100g": "double",
  "fiber_per_100g": "double?",
  "sugar_per_100g": "double?",
  "sodium_per_100g": "double?",
  "default_serving_size": "double", // Taille de portion par défaut
  "default_serving_unit": "string", // 'g', 'ml', 'portion'
  "is_verified": "boolean", // Vérifié par l'équipe
  "is_custom": "boolean", // Créé par l'utilisateur
  "created_by": "string (FK)?", // user_id si custom
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### 🍳 Recettes
```json
// Table: recipes
{
  "recipe_id": "string (UUID)",
  "name": "string",
  "description": "string?",
  "image_url": "string?",
  "duration_minutes": "int", // Temps de préparation
  "difficulty": "string", // 'Facile', 'Moyen', 'Difficile'
  "servings": "int", // Nombre de portions
  "calories_per_serving": "int",
  "protein_per_serving": "int",
  "carbs_per_serving": "int",
  "fat_per_serving": "int",
  "instructions": "text", // Étapes de préparation
  "is_verified": "boolean",
  "is_custom": "boolean",
  "created_by": "string (FK)?",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}

// Table: recipe_ingredients
{
  "recipe_ingredient_id": "string (UUID)",
  "recipe_id": "string (FK)",
  "food_id": "string (FK)",
  "quantity": "double",
  "unit": "string",
  "order_index": "int" // Ordre dans la liste
}

// Table: recipe_tags
{
  "recipe_tag_id": "string (UUID)",
  "recipe_id": "string (FK)", 
  "tag": "string" // 'Végétarien', 'Sans gluten', etc.
}
```

### 📸 Scan IA et Photos
```json
// Table: ai_scans
{
  "scan_id": "string (UUID)",
  "user_id": "string (FK)",
  "image_url": "string",
  "detected_foods": "json", // Liste des aliments détectés
  "confidence_score": "double", // 0.0 à 1.0
  "is_validated": "boolean", // Validé par l'utilisateur
  "meal_id": "string (FK)?", // Si ajouté à un repas
  "created_at": "timestamp"
}
```

---

## 💪 4. SECTION SPORT - Données d'Entraînement

### 🏋️ Exercices
```json
// Table: exercises
{
  "exercise_id": "string (UUID)",
  "name": "string",
  "muscle_group": "string", // 'Pectoraux', 'Dos', etc.
  "equipment": "string", // Équipement nécessaire
  "description": "text?",
  "instructions": "text?",
  "image_url": "string?",
  "video_url": "string?", 
  "is_custom": "boolean",
  "created_by": "string (FK)?",
  "created_at": "timestamp"
}
```

### 🔥 Séances d'Entraînement
```json
// Table: workout_sessions
{
  "session_id": "string (UUID)",
  "user_id": "string (FK)",
  "name": "string",
  "workout_type": "string", // 'musculation', 'cardio', 'hiit'
  "start_time": "timestamp",
  "end_time": "timestamp?",
  "duration_seconds": "int?",
  "total_sets": "int",
  "completed_sets": "int",
  "calories_burned": "int?",
  "is_completed": "boolean",
  "notes": "text?",
  "created_at": "timestamp"
}

// Table: workout_exercises (exercices dans une séance)
{
  "workout_exercise_id": "string (UUID)",
  "session_id": "string (FK)",
  "exercise_id": "string (FK)",
  "order_index": "int", // Ordre dans la séance
  "rest_time_seconds": "int?", // Temps de repos après l'exercice
  "notes": "text?"
}

// Table: exercise_sets (séries d'un exercice)
{
  "set_id": "string (UUID)", 
  "workout_exercise_id": "string (FK)",
  "set_number": "int", // Numéro de la série
  "reps": "int", // Répétitions
  "weight": "double", // Poids en kg
  "rest_time_seconds": "int?",
  "is_completed": "boolean",
  "is_warmup": "boolean?",
  "rpe": "int?", // Rating of Perceived Exertion (1-10)
  "completed_at": "timestamp?"
}
```

### 🏃 Cardio et Activités
```json
// Table: cardio_sessions
{
  "cardio_id": "string (UUID)",
  "user_id": "string (FK)",
  "activity_type": "string", // 'course', 'vélo', 'natation', etc.
  "duration_minutes": "int",
  "distance_km": "double?",
  "calories_burned": "int?",
  "average_heart_rate": "int?",
  "max_heart_rate": "int?",
  "pace": "string?", // Format: 'mm:ss/km'
  "elevation_gain": "int?", // En mètres
  "notes": "text?",
  "is_outdoor": "boolean",
  "weather_conditions": "string?",
  "date": "date",
  "start_time": "timestamp",
  "end_time": "timestamp?",
  "created_at": "timestamp"
}
```

### 📋 Programmes d'Entraînement
```json
// Table: workout_programs
{
  "program_id": "string (UUID)",
  "name": "string",
  "description": "text?",
  "duration_weeks": "int", // Durée du programme
  "frequency_per_week": "int", // Séances par semaine
  "difficulty": "string", // 'Débutant', 'Intermédiaire', 'Avancé'
  "goal": "string", // 'force', 'endurance', 'hypertrophie', etc.
  "is_premium": "boolean",
  "is_custom": "boolean",
  "created_by": "string (FK)?",
  "image_url": "string?",
  "created_at": "timestamp"
}

// Table: program_workouts
{
  "program_workout_id": "string (UUID)",
  "program_id": "string (FK)",
  "week_number": "int",
  "day_number": "int", // Jour de la semaine (1-7)
  "workout_name": "string",
  "workout_type": "string",
  "estimated_duration": "int", // En minutes
  "exercises": "json" // Structure des exercices et séries
}
```

---

## 📊 5. SECTION PROGRÈS - Données de Suivi

### 📈 Évolution du Poids
```json
// Table: weight_entries
{
  "weight_entry_id": "string (UUID)",
  "user_id": "string (FK)",
  "weight": "double", // Poids en kg ou lbs
  "is_metric": "boolean",
  "date": "date",
  "time": "time",
  "notes": "text?",
  "body_fat_percentage": "double?",
  "muscle_mass": "double?",
  "water_percentage": "double?",
  "created_at": "timestamp"
}
```

### 📊 Statistiques Globales
```json
// Table: user_statistics
{
  "stat_id": "string (UUID)",
  "user_id": "string (FK)",
  "date": "date",
  "total_calories_consumed": "int",
  "total_calories_burned": "int",
  "workout_sessions_completed": "int",
  "cardio_sessions_completed": "int", 
  "total_workout_time_minutes": "int",
  "steps_count": "int?", // Si intégration fitness tracker
  "sleep_hours": "double?", // Si suivi du sommeil
  "water_glasses": "int", // Verres d'eau consommés
  "streak_days": "int", // Jours consécutifs actifs
  "xp_earned": "int", // XP gagné ce jour
  "goals_completed": "int", // Objectifs complétés
  "updated_at": "timestamp"
}
```

### 🏆 Accomplissements et Badges
```json
// Table: achievements
{
  "achievement_id": "string (UUID)",
  "name": "string",
  "description": "string",
  "icon": "string",
  "xp_reward": "int",
  "badge_color": "string",
  "criteria": "json", // Critères pour débloquer
  "is_hidden": "boolean", // Visible seulement une fois débloqué
  "category": "string" // 'nutrition', 'sport', 'général'
}

// Table: user_achievements
{
  "user_achievement_id": "string (UUID)",
  "user_id": "string (FK)",
  "achievement_id": "string (FK)",
  "unlocked_at": "timestamp",
  "progress": "int", // Progression vers l'accomplissement (0-100)
  "is_completed": "boolean"
}
```

---

## 🔔 6. SYSTÈME DE NOTIFICATIONS

### 📱 Notifications et Rappels
```json
// Table: notifications
{
  "notification_id": "string (UUID)",
  "user_id": "string (FK)",
  "type": "string", // 'reminder', 'achievement', 'tip', 'social'
  "title": "string",
  "message": "string",
  "action_url": "string?", // Lien profond dans l'app
  "is_read": "boolean",
  "is_push_sent": "boolean",
  "scheduled_for": "timestamp?", // Pour les rappels programmés
  "sent_at": "timestamp?",
  "created_at": "timestamp"
}
```

---

## 👥 7. SYSTÈME SOCIAL (FUTUR)

### 🤝 Amis et Communauté
```json
// Table: friendships
{
  "friendship_id": "string (UUID)",
  "user_id": "string (FK)",
  "friend_id": "string (FK)",
  "status": "string", // 'pending', 'accepted', 'blocked'
  "created_at": "timestamp",
  "accepted_at": "timestamp?"
}

// Table: community_challenges
{
  "challenge_id": "string (UUID)",
  "name": "string",
  "description": "text",
  "start_date": "date",
  "end_date": "date",
  "goal_type": "string", // 'steps', 'workouts', 'calories', etc.
  "target_value": "int",
  "participants_count": "int",
  "is_active": "boolean"
}
```

---

## 💳 8. SYSTÈME PREMIUM

### 💎 Abonnements et Facturation
```json
// Table: subscriptions
{
  "subscription_id": "string (UUID)",
  "user_id": "string (FK)",
  "plan_type": "string", // 'monthly', 'yearly'
  "status": "string", // 'active', 'cancelled', 'expired'
  "start_date": "date",
  "end_date": "date",
  "price": "decimal",
  "currency": "string",
  "payment_provider": "string", // 'stripe', 'apple', 'google'
  "external_subscription_id": "string",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

---

## 🔧 RÉSUMÉ ARCHITECTURE BACKEND

### 📊 TABLES PRINCIPALES IDENTIFIÉES

**Utilisateurs & Profil (5 tables):**
- `users` - Données utilisateur de base
- `user_macros` - Calculs nutritionnels
- `user_statistics` - Statistiques globales  
- `user_achievements` - Accomplissements
- `subscriptions` - Abonnements premium

**Nutrition (8 tables):**
- `nutrition_days` - Profil nutritionnel quotidien
- `meals` - Repas journaliers
- `meal_foods` - Aliments dans les repas
- `foods` - Base de données alimentaire
- `recipes` - Recettes
- `recipe_ingredients` - Ingrédients des recettes
- `recipe_tags` - Tags des recettes
- `ai_scans` - Scans IA

**Sport (7 tables):**
- `exercises` - Base d'exercices
- `workout_sessions` - Séances d'entraînement
- `workout_exercises` - Exercices dans les séances
- `exercise_sets` - Séries d'exercices
- `cardio_sessions` - Séances cardio
- `workout_programs` - Programmes d'entraînement
- `program_workouts` - Structure des programmes

**Système (8 tables):**
- `activity_levels` - Niveaux d'activité
- `goals` - Objectifs utilisateur
- `obstacles` - Obstacles comportementaux
- `dietary_restrictions` - Restrictions alimentaires
- `daily_goals` - Objectifs journaliers
- `achievements` - Accomplissements disponibles
- `notifications` - Système de notifications
- `weight_entries` - Suivi du poids

**Social & Communauté (3 tables):**
- `friendships` - Relations entre utilisateurs
- `community_challenges` - Défis communautaires
- `challenge_participations` - Participation aux défis

**TOTAL: ~31 tables principales**

### 🔄 RELATIONS CLÉS
- **One-to-Many**: User → Meals, Sessions, Goals
- **Many-to-Many**: Meals ↔ Foods, Recipes ↔ Ingredients
- **Hierarchical**: Programs → Workouts → Exercises → Sets

Cette architecture supportera parfaitement l'application actuelle et permettra une évolution future ! 🚀 