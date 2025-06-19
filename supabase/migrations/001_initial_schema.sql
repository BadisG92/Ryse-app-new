-- =======================
-- RYZE APP - REAL DATABASE SCHEMA
-- Based on actual Supabase production tables
-- Updated from production database structure
-- =======================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =======================
-- USER MANAGEMENT
-- =======================

-- Users table (extends Supabase auth.users with nutrition goals)
CREATE TABLE users (
  instance_id UUID,
  id UUID NOT NULL,
  aud VARCHAR(255),
  role VARCHAR(255),
  email VARCHAR(255),
  encrypted_password VARCHAR(255),
  email_confirmed_at TIMESTAMPTZ,
  invited_at TIMESTAMPTZ,
  confirmation_token VARCHAR(255),
  confirmation_sent_at TIMESTAMPTZ,
  recovery_token VARCHAR(255),
  recovery_sent_at TIMESTAMPTZ,
  email_change_token_new VARCHAR(255),
  email_change VARCHAR(255),
  email_change_sent_at TIMESTAMPTZ,
  last_sign_in_at TIMESTAMPTZ,
  raw_app_meta_data JSONB,
  raw_user_meta_data JSONB,
  is_super_admin BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  phone TEXT,
  phone_confirmed_at TIMESTAMPTZ,
  phone_change TEXT,
  phone_change_token VARCHAR(255),
  phone_change_sent_at TIMESTAMPTZ,
  confirmed_at TIMESTAMPTZ,
  email_change_token_current VARCHAR(255),
  email_change_confirm_status SMALLINT,
  banned_until TIMESTAMPTZ,
  reauthentication_token VARCHAR(255),
  reauthentication_sent_at TIMESTAMPTZ,
  is_sso_user BOOLEAN NOT NULL,
  deleted_at TIMESTAMPTZ,
  is_anonymous BOOLEAN NOT NULL,
  -- Custom profile fields
  email TEXT,
  is_onboarded BOOLEAN,
  first_name TEXT,
  last_name TEXT,
  gender TEXT,
  birth_date DATE,
  age INTEGER,
  height NUMERIC,
  weight NUMERIC,
  is_metric BOOLEAN,
  activity_level TEXT,
  fitness_goal TEXT,
  obstacles TEXT[],
  dietary_restrictions TEXT[],
  daily_calories INTEGER,
  daily_protein INTEGER,
  daily_carbs INTEGER,
  daily_fat INTEGER,
  bmr NUMERIC,
  PRIMARY KEY (id)
);

-- =======================
-- NUTRITION MODULE
-- =======================

-- Foods database
CREATE TABLE foods (
  id UUID NOT NULL,
  name_en TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  calories INTEGER NOT NULL,
  proteins NUMERIC NOT NULL,
  carbs NUMERIC NOT NULL,
  fats NUMERIC NOT NULL,
  category TEXT,
  is_custom BOOLEAN,
  is_verified BOOLEAN,
  is_public BOOLEAN,
  user_id UUID,
  reference_unit_fr TEXT,
  reference_unit_en TEXT,
  tags TEXT[],
  rating_count INTEGER,
  community_rating NUMERIC,
  source_url TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Custom foods created by users
CREATE TABLE custom_foods (
  id BIGINT NOT NULL,
  name TEXT NOT NULL,
  calories INTEGER NOT NULL,
  proteins NUMERIC NOT NULL,
  carbs NUMERIC NOT NULL,
  fats NUMERIC NOT NULL,
  reference_quantity NUMERIC NOT NULL,
  reference_unit_fr TEXT,
  reference_unit_en TEXT,
  origin TEXT NOT NULL,
  barcode TEXT,
  user_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (id)
);

-- Food entries (nutrition journal)
CREATE TABLE food_entries (
  id UUID NOT NULL,
  user_id UUID NOT NULL,
  food_id UUID,
  custom_food_id BIGINT,
  recipe_id UUID,
  meal_type TEXT NOT NULL,
  quantity NUMERIC NOT NULL,
  unit TEXT NOT NULL,
  calories NUMERIC NOT NULL,
  proteins NUMERIC NOT NULL,
  carbs NUMERIC NOT NULL,
  fats NUMERIC NOT NULL,
  consumed_at TIMESTAMPTZ NOT NULL,
  meal_id TEXT,
  is_scanned BOOLEAN,
  scanned_food_name TEXT,
  has_modified_macros BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Barcode foods for scanner
CREATE TABLE barcode_foods (
  id UUID NOT NULL,
  barcode TEXT NOT NULL,
  product_name TEXT NOT NULL,
  brand TEXT,
  category TEXT,
  calories NUMERIC,
  proteins NUMERIC,
  carbs NUMERIC,
  fats NUMERIC,
  fiber NUMERIC,
  sodium NUMERIC,
  sugar NUMERIC,
  serving_size TEXT,
  serving_unit TEXT,
  ingredients TEXT,
  allergens TEXT[],
  data_source TEXT NOT NULL,
  is_verified BOOLEAN,
  quality_score INTEGER,
  image_url TEXT,
  product_url TEXT,
  scan_count INTEGER,
  last_scanned_at TIMESTAMPTZ,
  user_id UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Recipes
CREATE TABLE recipes (
  id UUID NOT NULL,
  name_en TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  steps_en TEXT[] NOT NULL,
  steps_fr TEXT[] NOT NULL,
  servings INTEGER,
  "calories per portion" INTEGER,
  "proteins per portion" REAL,
  "carbs per portion" NUMERIC,
  "fat per portion" NUMERIC,
  difficulty TEXT,
  duration TEXT,
  tags TEXT[],
  image_url TEXT,
  source_url TEXT,
  is_custom BOOLEAN,
  is_public BOOLEAN,
  is_verified BOOLEAN,
  user_id UUID,
  community_rating NUMERIC,
  rating_count INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Recipe ingredients
CREATE TABLE recipe_ingredients (
  id UUID NOT NULL,
  recipe_id UUID NOT NULL,
  food_id UUID NOT NULL,
  quantity NUMERIC NOT NULL,
  unit VARCHAR(20) NOT NULL,
  display_order INTEGER,
  preparation_note TEXT,
  is_optional BOOLEAN,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- =======================
-- SPORT MODULE
-- =======================

-- Exercises database
CREATE TABLE exercises (
  id UUID NOT NULL,
  name_en TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  muscle_group TEXT NOT NULL,
  equipment TEXT,
  description TEXT,
  instructions_en TEXT,
  instructions_fr TEXT,
  difficulty_level TEXT,
  video_url TEXT,
  image_url TEXT,
  is_custom BOOLEAN,
  is_public BOOLEAN,
  is_verified BOOLEAN,
  user_id UUID,
  tags TEXT[],
  community_rating NUMERIC,
  rating_count INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Workout sessions
CREATE TABLE workout_sessions (
  id UUID NOT NULL,
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  is_completed BOOLEAN,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Workout exercises
CREATE TABLE workout_exercises (
  id UUID NOT NULL,
  session_id UUID,
  exercise_id UUID,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Exercise sets
CREATE TABLE exercise_sets (
  id UUID NOT NULL,
  workout_exercise_id UUID,
  reps INTEGER NOT NULL,
  weight NUMERIC NOT NULL,
  set_order INTEGER NOT NULL,
  is_completed BOOLEAN,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Workout templates
CREATE TABLE workout_templates (
  id UUID NOT NULL,
  name_en TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  description_en TEXT,
  description_fr TEXT,
  difficulty_level TEXT,
  estimated_duration_minutes INTEGER,
  target_muscle_groups TEXT[],
  equipment_needed TEXT[],
  calories_burned_estimate INTEGER,
  is_custom BOOLEAN,
  is_public BOOLEAN,
  user_id UUID,
  created_from_session_id UUID,
  average_rating NUMERIC,
  usage_count INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Workout template exercises
CREATE TABLE workout_template_exercises (
  id UUID NOT NULL,
  template_id UUID NOT NULL,
  exercise_id UUID NOT NULL,
  order_index INTEGER NOT NULL,
  suggested_sets INTEGER,
  suggested_reps_min INTEGER,
  suggested_reps_max INTEGER,
  suggested_weight_percentage NUMERIC,
  suggested_rest_seconds INTEGER,
  notes_en TEXT,
  notes_fr TEXT,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Workout programs
CREATE TABLE workout_programs (
  id UUID NOT NULL,
  name_en TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  description_en TEXT,
  description_fr TEXT,
  duration_weeks INTEGER,
  sessions_per_week INTEGER,
  difficulty_level TEXT,
  is_custom BOOLEAN,
  user_id UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- =======================
-- HIIT MODULE
-- =======================

-- HIIT workouts
CREATE TABLE hiit_workouts (
  id UUID NOT NULL,
  title_en TEXT NOT NULL,
  title_fr TEXT NOT NULL,
  description_en TEXT,
  description_fr TEXT,
  work_duration INTEGER NOT NULL,
  rest_duration INTEGER NOT NULL,
  total_duration INTEGER NOT NULL,
  total_rounds INTEGER NOT NULL,
  is_custom BOOLEAN,
  is_public BOOLEAN,
  is_verified BOOLEAN,
  user_id UUID,
  tags TEXT[],
  community_rating NUMERIC,
  rating_count INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- HIIT sessions
CREATE TABLE hiit_sessions (
  id UUID NOT NULL,
  user_id UUID NOT NULL,
  workout_id UUID,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  current_phase TEXT,
  current_round INTEGER,
  is_completed BOOLEAN,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- =======================
-- CARDIO MODULE
-- =======================

-- Cardio activities
CREATE TABLE cardio_activities (
  id UUID NOT NULL,
  name_en TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  activity_type TEXT NOT NULL,
  description_en TEXT,
  description_fr TEXT,
  is_custom BOOLEAN,
  is_public BOOLEAN,
  is_verified BOOLEAN,
  user_id UUID,
  tags TEXT[],
  community_rating NUMERIC,
  rating_count INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Cardio sessions
CREATE TABLE cardio_sessions (
  id UUID NOT NULL,
  user_id UUID NOT NULL,
  activity_type TEXT NOT NULL,
  activity_title TEXT NOT NULL,
  format_title TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  duration_seconds INTEGER,
  distance_km NUMERIC,
  target_distance_km NUMERIC,
  target_duration_seconds INTEGER,
  average_speed_kmh NUMERIC,
  current_speed_kmh NUMERIC,
  steps INTEGER,
  calories INTEGER,
  is_running BOOLEAN,
  is_paused BOOLEAN,
  notes TEXT,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Location points for GPS tracking
CREATE TABLE location_points (
  id UUID NOT NULL,
  cardio_session_id UUID,
  latitude NUMERIC NOT NULL,
  longitude NUMERIC NOT NULL,
  altitude NUMERIC,
  speed_kmh NUMERIC,
  recorded_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- GPS tracking sessions
CREATE TABLE gps_tracking_sessions (
  id UUID NOT NULL,
  user_id UUID NOT NULL,
  cardio_session_id UUID,
  activity_type TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  duration_seconds INTEGER,
  total_distance_meters NUMERIC,
  elevation_gain_meters NUMERIC,
  elevation_loss_meters NUMERIC,
  average_speed_kmh NUMERIC,
  max_speed_kmh NUMERIC,
  pace_per_km_seconds INTEGER,
  calories_estimated INTEGER,
  status TEXT NOT NULL,
  tracking_accuracy TEXT,
  device_info JSONB,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- GPS tracking points
CREATE TABLE gps_tracking_points (
  id UUID NOT NULL,
  session_id UUID NOT NULL,
  latitude NUMERIC NOT NULL,
  longitude NUMERIC NOT NULL,
  altitude_meters NUMERIC,
  recorded_at TIMESTAMPTZ NOT NULL,
  sequence_number INTEGER NOT NULL,
  accuracy_meters NUMERIC,
  speed_mps NUMERIC,
  bearing_degrees NUMERIC,
  distance_from_previous_meters NUMERIC,
  time_from_previous_seconds INTEGER,
  signal_strength INTEGER,
  battery_level INTEGER,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- =======================
-- COMMUNITY & CONTENT
-- =======================

-- Content tags
CREATE TABLE content_tags (
  id UUID NOT NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  color TEXT,
  usage_count INTEGER,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Community ratings
CREATE TABLE community_ratings (
  id UUID NOT NULL,
  user_id UUID NOT NULL,
  content_type TEXT NOT NULL,
  content_id UUID NOT NULL,
  rating INTEGER NOT NULL,
  comment TEXT,
  is_helpful BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- Content reports
CREATE TABLE content_reports (
  id UUID NOT NULL,
  reported_by UUID NOT NULL,
  content_type TEXT NOT NULL,
  content_id UUID NOT NULL,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT,
  reviewed_by UUID,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- User collections
CREATE TABLE user_collections (
  id UUID NOT NULL,
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  collection_type TEXT NOT NULL,
  item_ids TEXT[],
  is_public BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- =======================
-- EXTERNAL SERVICES
-- =======================

-- External API configurations
CREATE TABLE external_api_configs (
  id UUID NOT NULL,
  service_name TEXT NOT NULL,
  api_url TEXT NOT NULL,
  api_key TEXT,
  rate_limit_per_minute INTEGER,
  timeout_seconds INTEGER,
  is_active BOOLEAN,
  health_status TEXT,
  last_health_check TIMESTAMPTZ,
  total_requests INTEGER,
  successful_requests INTEGER,
  failed_requests INTEGER,
  average_response_time_ms NUMERIC,
  config_params JSONB,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- External API logs
CREATE TABLE external_api_logs (
  id UUID NOT NULL,
  service_name TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  request_method TEXT NOT NULL,
  request_params JSONB,
  request_body JSONB,
  response_status INTEGER,
  response_time_ms INTEGER,
  response_size_bytes INTEGER,
  success BOOLEAN NOT NULL,
  error_message TEXT,
  user_id UUID,
  session_info JSONB,
  created_at TIMESTAMPTZ,
  PRIMARY KEY (id)
);

-- =======================
-- INDEXES FOR PERFORMANCE
-- =======================

-- User-based queries
CREATE INDEX idx_food_entries_user_id ON food_entries(user_id);
CREATE INDEX idx_food_entries_consumed_at ON food_entries(consumed_at);
CREATE INDEX idx_food_entries_meal_type ON food_entries(meal_type);

CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_hiit_sessions_user_id ON hiit_sessions(user_id);
CREATE INDEX idx_cardio_sessions_user_id ON cardio_sessions(user_id);

-- Date-based queries
CREATE INDEX idx_cardio_sessions_date ON cardio_sessions(start_time::date);

-- Exercise queries
CREATE INDEX idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX idx_exercises_custom ON exercises(is_custom, user_id);

-- Food queries
CREATE INDEX idx_foods_category ON foods(category);
CREATE INDEX idx_custom_foods_user_id ON custom_foods(user_id);
CREATE INDEX idx_barcode_foods_barcode ON barcode_foods(barcode);

-- =======================
-- ROW LEVEL SECURITY (RLS)
-- =======================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE barcode_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE hiit_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE hiit_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cardio_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE cardio_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_points ENABLE ROW LEVEL SECURITY;

-- Basic policies for users
CREATE POLICY "Users can read own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Policies for food data
CREATE POLICY "Anyone can read public foods" ON foods FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY "Users can manage own custom foods" ON custom_foods FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own food entries" ON food_entries FOR ALL USING (auth.uid() = user_id);

-- Policies for workout data
CREATE POLICY "Users can manage own workout sessions" ON workout_sessions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own HIIT sessions" ON hiit_sessions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own cardio sessions" ON cardio_sessions FOR ALL USING (auth.uid() = user_id);

-- Policies for exercises (public read, user create/update)
CREATE POLICY "Anyone can read public exercises" ON exercises FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY "Users can create custom exercises" ON exercises FOR INSERT WITH CHECK (auth.uid() = user_id);

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

CREATE TRIGGER handle_foods_updated_at
  BEFORE UPDATE ON foods
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_custom_foods_updated_at
  BEFORE UPDATE ON custom_foods
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at(); 