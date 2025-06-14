# 🗄️ Ryze App - Supabase Database Setup

## 📋 Overview

This directory contains all the SQL files needed to set up the Supabase database for the Ryze app, based on the actual Flutter frontend models.

## 🏗️ Database Structure

The database is organized around the frontend modules:

### 📱 **User Management**
- `users` - User profiles and onboarding status

### 💪 **Sport Module**
- `exercises` - Exercise database (predefined + custom)
- `workout_sessions` - Workout tracking sessions
- `workout_exercises` - Exercises within workout sessions
- `exercise_sets` - Individual sets with reps/weight

### 🔥 **HIIT Module**
- `hiit_workouts` - HIIT workout templates
- `hiit_sessions` - HIIT session tracking

### 🏃 **Cardio Module**
- `cardio_sessions` - Cardio activity tracking
- `location_points` - GPS tracking data

### 🍎 **Nutrition Module**
- `foods` - Food database with nutritional info
- `meals` - User meal entries
- `meal_food_items` - Food items within meals

## 🚀 Setup Instructions

### 1. Create Supabase Project
1. Go to [Supabase](https://supabase.com)
2. Create a new project
3. Note your project URL and anon key

### 2. Run Database Migrations
Execute these files in order:

```sql
-- 1. Create all tables and security policies
\i 001_initial_schema.sql

-- 2. Populate with initial data
\i seed.sql
```

### 3. Verify Setup
Check that all tables were created:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';
```

## 📊 Key Features

- **Row Level Security (RLS)** - Users can only access their own data
- **UUID Primary Keys** - Optimized for distributed systems
- **Indexes** - Performance optimized for common queries
- **Triggers** - Automatic updated_at timestamps
- **Functions** - Nutritional calculations

## 🔐 Security

All tables have RLS enabled with policies that ensure:
- Users can only access their own data
- Public read access for shared data (exercises, foods)
- Proper authentication checks

## 📈 Performance Optimizations

- Indexes on frequently queried columns
- Efficient foreign key relationships
- Optimized for mobile app usage patterns

## 🔧 Useful Queries

### Get user's recent workouts
```sql
SELECT * FROM workout_sessions 
WHERE user_id = auth.uid() 
ORDER BY start_time DESC 
LIMIT 10;
```

### Calculate daily nutrition
```sql
SELECT calculate_meal_nutrition(meal_id) 
FROM meals 
WHERE user_id = auth.uid() 
AND date = CURRENT_DATE;
```

## 📝 Notes

- The schema follows the exact structure of the Flutter models
- All timestamps are in UTC
- Distance is stored in kilometers
- Weight is stored in kilograms
- Duration is stored in seconds 