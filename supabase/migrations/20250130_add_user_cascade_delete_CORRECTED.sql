-- =======================
-- ADD ON DELETE CASCADE FOR USER RELATIONS (CORRECTED)
-- Migration to ensure all user data is deleted when a user is deleted
-- Based on REAL schema from 001_initial_schema.sql
-- Created: 2025-01-30
-- =======================

-- IMPORTANT: This migration references public.users (not auth.users)
-- Supabase uses auth.users internally, but the FK should reference the actual table

-- =======================
-- STEP 1: Add foreign key constraints to tables
-- =======================

-- Foods table (optional user_id for custom foods)
ALTER TABLE public.foods
DROP CONSTRAINT IF EXISTS fk_foods_user,
ADD CONSTRAINT fk_foods_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Custom foods table (user-created foods)
ALTER TABLE public.custom_foods
DROP CONSTRAINT IF EXISTS fk_custom_foods_user,
ADD CONSTRAINT fk_custom_foods_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Food entries table (nutrition journal)
ALTER TABLE public.food_entries
DROP CONSTRAINT IF EXISTS fk_food_entries_user,
ADD CONSTRAINT fk_food_entries_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Barcode foods table (scanned products)
ALTER TABLE public.barcode_foods
DROP CONSTRAINT IF EXISTS fk_barcode_foods_user,
ADD CONSTRAINT fk_barcode_foods_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Recipes table (user-created recipes)
ALTER TABLE public.recipes
DROP CONSTRAINT IF EXISTS fk_recipes_user,
ADD CONSTRAINT fk_recipes_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Exercises table (custom exercises)
ALTER TABLE public.exercises
DROP CONSTRAINT IF EXISTS fk_exercises_user,
ADD CONSTRAINT fk_exercises_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Workout sessions table
ALTER TABLE public.workout_sessions
DROP CONSTRAINT IF EXISTS fk_workout_sessions_user,
ADD CONSTRAINT fk_workout_sessions_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Workout templates table
ALTER TABLE public.workout_templates
DROP CONSTRAINT IF EXISTS fk_workout_templates_user,
ADD CONSTRAINT fk_workout_templates_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Workout programs table
ALTER TABLE public.workout_programs
DROP CONSTRAINT IF EXISTS fk_workout_programs_user,
ADD CONSTRAINT fk_workout_programs_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- HIIT workouts table
ALTER TABLE public.hiit_workouts
DROP CONSTRAINT IF EXISTS fk_hiit_workouts_user,
ADD CONSTRAINT fk_hiit_workouts_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- HIIT sessions table
ALTER TABLE public.hiit_sessions
DROP CONSTRAINT IF EXISTS fk_hiit_sessions_user,
ADD CONSTRAINT fk_hiit_sessions_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Cardio activities table
ALTER TABLE public.cardio_activities
DROP CONSTRAINT IF EXISTS fk_cardio_activities_user,
ADD CONSTRAINT fk_cardio_activities_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Cardio sessions table
ALTER TABLE public.cardio_sessions
DROP CONSTRAINT IF EXISTS fk_cardio_sessions_user,
ADD CONSTRAINT fk_cardio_sessions_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- GPS tracking sessions table
ALTER TABLE public.gps_tracking_sessions
DROP CONSTRAINT IF EXISTS fk_gps_tracking_sessions_user,
ADD CONSTRAINT fk_gps_tracking_sessions_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Community ratings table
ALTER TABLE public.community_ratings
DROP CONSTRAINT IF EXISTS fk_community_ratings_user,
ADD CONSTRAINT fk_community_ratings_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- User collections table
ALTER TABLE public.user_collections
DROP CONSTRAINT IF EXISTS fk_user_collections_user,
ADD CONSTRAINT fk_user_collections_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- External API logs table
ALTER TABLE public.external_api_logs
DROP CONSTRAINT IF EXISTS fk_external_api_logs_user,
ADD CONSTRAINT fk_external_api_logs_user
FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Content reports table (reported_by field)
ALTER TABLE public.content_reports
DROP CONSTRAINT IF EXISTS fk_content_reports_reported_by,
ADD CONSTRAINT fk_content_reports_reported_by
FOREIGN KEY (reported_by) REFERENCES public.users(id) ON DELETE CASCADE;

-- Content reports table (reviewed_by field - SET NULL instead of CASCADE)
ALTER TABLE public.content_reports
DROP CONSTRAINT IF EXISTS fk_content_reports_reviewed_by,
ADD CONSTRAINT fk_content_reports_reviewed_by
FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL;

-- =======================
-- STEP 2: Add indexes for foreign keys (performance optimization)
-- =======================
-- Note: Some indexes already exist from 001_initial_schema.sql

CREATE INDEX IF NOT EXISTS idx_foods_user_id ON public.foods(user_id);
CREATE INDEX IF NOT EXISTS idx_barcode_foods_user_id ON public.barcode_foods(user_id);
CREATE INDEX IF NOT EXISTS idx_recipes_user_id ON public.recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_exercises_user_id ON public.exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_templates_user_id ON public.workout_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_programs_user_id ON public.workout_programs(user_id);
CREATE INDEX IF NOT EXISTS idx_hiit_workouts_user_id ON public.hiit_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_cardio_activities_user_id ON public.cardio_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_gps_tracking_sessions_user_id ON public.gps_tracking_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_community_ratings_user_id ON public.community_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_collections_user_id ON public.user_collections(user_id);
CREATE INDEX IF NOT EXISTS idx_external_api_logs_user_id ON public.external_api_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_reported_by ON public.content_reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_content_reports_reviewed_by ON public.content_reports(reviewed_by);

-- =======================
-- VERIFICATION QUERY
-- =======================

-- Run this query after migration to verify all constraints are in place:
SELECT
  conname AS constraint_name,
  conrelid::regclass AS table_name,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE confrelid = 'public.users'::regclass
  AND contype = 'f'
ORDER BY table_name;
