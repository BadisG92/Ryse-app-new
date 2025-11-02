-- =======================
-- ADD ON DELETE CASCADE FOR USER RELATIONS
-- Migration to ensure all user data is deleted when a user is deleted
-- Created: 2025-01-30
-- =======================

-- This migration adds foreign key constraints with ON DELETE CASCADE
-- to all tables that reference users, ensuring data integrity and
-- automatic cleanup when a user account is deleted.

-- =======================
-- STEP 1: Add foreign key constraints to tables
-- =======================

-- Foods table (optional user_id for custom foods)
ALTER TABLE foods
DROP CONSTRAINT IF EXISTS fk_foods_user,
ADD CONSTRAINT fk_foods_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Custom foods table (user-created foods)
ALTER TABLE custom_foods
DROP CONSTRAINT IF EXISTS fk_custom_foods_user,
ADD CONSTRAINT fk_custom_foods_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Food entries table (nutrition journal)
ALTER TABLE food_entries
DROP CONSTRAINT IF EXISTS fk_food_entries_user,
ADD CONSTRAINT fk_food_entries_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Barcode foods table (scanned products)
ALTER TABLE barcode_foods
DROP CONSTRAINT IF EXISTS fk_barcode_foods_user,
ADD CONSTRAINT fk_barcode_foods_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Recipes table (user-created recipes)
ALTER TABLE recipes
DROP CONSTRAINT IF EXISTS fk_recipes_user,
ADD CONSTRAINT fk_recipes_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Exercises table (custom exercises)
ALTER TABLE exercises
DROP CONSTRAINT IF EXISTS fk_exercises_user,
ADD CONSTRAINT fk_exercises_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Workout sessions table
ALTER TABLE workout_sessions
DROP CONSTRAINT IF EXISTS fk_workout_sessions_user,
ADD CONSTRAINT fk_workout_sessions_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Workout templates table
ALTER TABLE workout_templates
DROP CONSTRAINT IF EXISTS fk_workout_templates_user,
ADD CONSTRAINT fk_workout_templates_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Workout programs table
ALTER TABLE workout_programs
DROP CONSTRAINT IF EXISTS fk_workout_programs_user,
ADD CONSTRAINT fk_workout_programs_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- HIIT workouts table
ALTER TABLE hiit_workouts
DROP CONSTRAINT IF EXISTS fk_hiit_workouts_user,
ADD CONSTRAINT fk_hiit_workouts_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- HIIT sessions table
ALTER TABLE hiit_sessions
DROP CONSTRAINT IF EXISTS fk_hiit_sessions_user,
ADD CONSTRAINT fk_hiit_sessions_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Cardio activities table
ALTER TABLE cardio_activities
DROP CONSTRAINT IF EXISTS fk_cardio_activities_user,
ADD CONSTRAINT fk_cardio_activities_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Cardio sessions table
ALTER TABLE cardio_sessions
DROP CONSTRAINT IF EXISTS fk_cardio_sessions_user,
ADD CONSTRAINT fk_cardio_sessions_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- GPS tracking sessions table
ALTER TABLE gps_tracking_sessions
DROP CONSTRAINT IF EXISTS fk_gps_tracking_sessions_user,
ADD CONSTRAINT fk_gps_tracking_sessions_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Community ratings table
ALTER TABLE community_ratings
DROP CONSTRAINT IF EXISTS fk_community_ratings_user,
ADD CONSTRAINT fk_community_ratings_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- User collections table
ALTER TABLE user_collections
DROP CONSTRAINT IF EXISTS fk_user_collections_user,
ADD CONSTRAINT fk_user_collections_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- External API logs table
ALTER TABLE external_api_logs
DROP CONSTRAINT IF EXISTS fk_external_api_logs_user,
ADD CONSTRAINT fk_external_api_logs_user
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Content reports table (reported_by field)
ALTER TABLE content_reports
DROP CONSTRAINT IF EXISTS fk_content_reports_reported_by,
ADD CONSTRAINT fk_content_reports_reported_by
FOREIGN KEY (reported_by) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Content reports table (reviewed_by field - SET NULL instead of CASCADE)
ALTER TABLE content_reports
DROP CONSTRAINT IF EXISTS fk_content_reports_reviewed_by,
ADD CONSTRAINT fk_content_reports_reviewed_by
FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- =======================
-- STEP 2: Add indexes for foreign keys (performance optimization)
-- =======================

CREATE INDEX IF NOT EXISTS idx_foods_user_id ON foods(user_id);
CREATE INDEX IF NOT EXISTS idx_barcode_foods_user_id ON barcode_foods(user_id);
CREATE INDEX IF NOT EXISTS idx_recipes_user_id ON recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_exercises_user_id ON exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_templates_user_id ON workout_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_programs_user_id ON workout_programs(user_id);
CREATE INDEX IF NOT EXISTS idx_hiit_workouts_user_id ON hiit_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_cardio_activities_user_id ON cardio_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_gps_tracking_sessions_user_id ON gps_tracking_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_community_ratings_user_id ON community_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_collections_user_id ON user_collections(user_id);
CREATE INDEX IF NOT EXISTS idx_external_api_logs_user_id ON external_api_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_reported_by ON content_reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_content_reports_reviewed_by ON content_reports(reviewed_by);

-- =======================
-- VERIFICATION QUERY
-- =======================

-- Run this query after migration to verify all constraints are in place:
--
-- SELECT
--   conname AS constraint_name,
--   conrelid::regclass AS table_name,
--   confdeltype AS on_delete_action
-- FROM pg_constraint
-- WHERE confrelid = 'auth.users'::regclass
--   AND contype = 'f'
-- ORDER BY table_name;
--
-- on_delete_action codes:
-- 'c' = CASCADE
-- 'n' = SET NULL
-- 'r' = RESTRICT
-- 'a' = NO ACTION
