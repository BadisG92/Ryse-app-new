-- =======================
-- RYZE APP - INITIAL DATABASE SCHEMA
-- Based on Flutter frontend models
-- =======================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =======================
-- USER MANAGEMENT
-- =======================

-- Users table (extends Supabase auth.users)
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE,
  name TEXT,
  is_onboarded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================
-- SPORT MODULE
-- =======================

-- Exercises table
CREATE TABLE exercises (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  muscle_group TEXT NOT NULL,
  equipment TEXT DEFAULT '',
  description TEXT DEFAULT '',
  is_custom BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout sessions
CREATE TABLE workout_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  name TEXT NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout exercises (exercises in a session)
CREATE TABLE workout_exercises (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  session_id UUID REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_id UUID REFERENCES exercises(id),
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exercise sets
CREATE TABLE exercise_sets (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  workout_exercise_id UUID REFERENCES workout_exercises(id) ON DELETE CASCADE,
  reps INTEGER NOT NULL,
  weight DECIMAL NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  set_order INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================
-- HIIT MODULE
-- =======================

-- HIIT workouts (predefined and custom)
CREATE TABLE hiit_workouts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  work_duration INTEGER NOT NULL, -- seconds
  rest_duration INTEGER NOT NULL, -- seconds
  total_duration INTEGER NOT NULL, -- minutes
  total_rounds INTEGER NOT NULL,
  is_custom BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- HIIT sessions
CREATE TABLE hiit_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  workout_id UUID REFERENCES hiit_workouts(id),
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  current_phase TEXT DEFAULT 'work', -- work, rest, warmup, cooldown, finished
  current_round INTEGER DEFAULT 1,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================
-- CARDIO MODULE
-- =======================

-- Cardio sessions
CREATE TABLE cardio_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  activity_type TEXT NOT NULL, -- running, bike, walking
  activity_title TEXT NOT NULL,
  format_title TEXT NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  duration_seconds INTEGER DEFAULT 0,
  distance_km DECIMAL DEFAULT 0,
  target_distance_km DECIMAL,
  target_duration_seconds INTEGER,
  average_speed_kmh DECIMAL DEFAULT 0,
  current_speed_kmh DECIMAL DEFAULT 0,
  steps INTEGER DEFAULT 0,
  calories INTEGER DEFAULT 0,
  is_running BOOLEAN DEFAULT FALSE,
  is_paused BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Location points for GPS tracking
CREATE TABLE location_points (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  cardio_session_id UUID REFERENCES cardio_sessions(id) ON DELETE CASCADE,
  latitude DECIMAL NOT NULL,
  longitude DECIMAL NOT NULL,
  altitude DECIMAL,
  speed_kmh DECIMAL,
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================
-- NUTRITION MODULE
-- =======================

-- Foods database
CREATE TABLE foods (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  calories_per_100g INTEGER NOT NULL,
  protein_per_100g DECIMAL DEFAULT 0,
  carbs_per_100g DECIMAL DEFAULT 0,
  fat_per_100g DECIMAL DEFAULT 0,
  is_custom BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Meals
CREATE TABLE meals (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  meal_time TEXT NOT NULL, -- breakfast, lunch, dinner, snack
  name TEXT NOT NULL,
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Food items in meals
CREATE TABLE meal_food_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  meal_id UUID REFERENCES meals(id) ON DELETE CASCADE,
  food_id UUID REFERENCES foods(id),
  portion TEXT NOT NULL,
  calories INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================
-- INDEXES FOR PERFORMANCE
-- =======================

-- User-based queries
CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_hiit_sessions_user_id ON hiit_sessions(user_id);
CREATE INDEX idx_cardio_sessions_user_id ON cardio_sessions(user_id);
CREATE INDEX idx_meals_user_id ON meals(user_id);

-- Date-based queries
CREATE INDEX idx_cardio_sessions_date ON cardio_sessions(start_time::date);
CREATE INDEX idx_meals_date ON meals(date);

-- Exercise queries
CREATE INDEX idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX idx_exercises_custom ON exercises(is_custom, created_by);

-- =======================
-- ROW LEVEL SECURITY (RLS)
-- =======================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE hiit_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE hiit_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cardio_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_food_items ENABLE ROW LEVEL SECURITY;

-- Policies for users
CREATE POLICY "Users can read own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Policies for exercises (public read, user create/update)
CREATE POLICY "Anyone can read exercises" ON exercises FOR SELECT USING (true);
CREATE POLICY "Users can create custom exercises" ON exercises FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update own custom exercises" ON exercises FOR UPDATE USING (auth.uid() = created_by);

-- Policies for workout data
CREATE POLICY "Users can manage own workout sessions" ON workout_sessions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own workout exercises" ON workout_exercises FOR ALL USING (
  auth.uid() = (SELECT user_id FROM workout_sessions WHERE id = session_id)
);
CREATE POLICY "Users can manage own exercise sets" ON exercise_sets FOR ALL USING (
  auth.uid() = (
    SELECT ws.user_id FROM workout_sessions ws 
    JOIN workout_exercises we ON we.session_id = ws.id 
    WHERE we.id = workout_exercise_id
  )
);

-- Policies for HIIT data
CREATE POLICY "Anyone can read HIIT workouts" ON hiit_workouts FOR SELECT USING (true);
CREATE POLICY "Users can create custom HIIT workouts" ON hiit_workouts FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can manage own HIIT sessions" ON hiit_sessions FOR ALL USING (auth.uid() = user_id);

-- Policies for cardio data
CREATE POLICY "Users can manage own cardio sessions" ON cardio_sessions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own location points" ON location_points FOR ALL USING (
  auth.uid() = (SELECT user_id FROM cardio_sessions WHERE id = cardio_session_id)
);

-- Policies for nutrition data
CREATE POLICY "Anyone can read foods" ON foods FOR SELECT USING (true);
CREATE POLICY "Users can create custom foods" ON foods FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can manage own meals" ON meals FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own meal items" ON meal_food_items FOR ALL USING (
  auth.uid() = (SELECT user_id FROM meals WHERE id = meal_id)
);

-- =======================
-- UPDATED_AT TRIGGERS
-- =======================

CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at(); 