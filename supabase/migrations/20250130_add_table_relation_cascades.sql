-- =======================
-- ADD ON DELETE CASCADE FOR TABLE RELATIONS
-- Migration to ensure related data is deleted when parent records are deleted
-- Created: 2025-01-30
-- =======================

-- This migration adds foreign key constraints with ON DELETE CASCADE
-- for relationships between tables (non-user relations)

-- =======================
-- RECIPE RELATIONS
-- =======================

-- Recipe ingredients should be deleted when recipe is deleted
ALTER TABLE recipe_ingredients
DROP CONSTRAINT IF EXISTS fk_recipe_ingredients_recipe,
ADD CONSTRAINT fk_recipe_ingredients_recipe
FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;

-- Recipe ingredients can have optional food reference (SET NULL if food deleted)
ALTER TABLE recipe_ingredients
DROP CONSTRAINT IF EXISTS fk_recipe_ingredients_food,
ADD CONSTRAINT fk_recipe_ingredients_food
FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE SET NULL;

-- =======================
-- WORKOUT RELATIONS
-- =======================

-- Workout exercises should be deleted when session is deleted
ALTER TABLE workout_exercises
DROP CONSTRAINT IF EXISTS fk_workout_exercises_session,
ADD CONSTRAINT fk_workout_exercises_session
FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE;

-- Workout exercises reference (SET NULL if exercise deleted to preserve history)
ALTER TABLE workout_exercises
DROP CONSTRAINT IF EXISTS fk_workout_exercises_exercise,
ADD CONSTRAINT fk_workout_exercises_exercise
FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE SET NULL;

-- Exercise sets should be deleted when workout exercise is deleted
ALTER TABLE exercise_sets
DROP CONSTRAINT IF EXISTS fk_exercise_sets_workout_exercise,
ADD CONSTRAINT fk_exercise_sets_workout_exercise
FOREIGN KEY (workout_exercise_id) REFERENCES workout_exercises(id) ON DELETE CASCADE;

-- =======================
-- WORKOUT TEMPLATE RELATIONS
-- =======================

-- Template exercises should be deleted when template is deleted
ALTER TABLE workout_template_exercises
DROP CONSTRAINT IF EXISTS fk_template_exercises_template,
ADD CONSTRAINT fk_template_exercises_template
FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE;

-- Template exercises reference (SET NULL if exercise deleted)
ALTER TABLE workout_template_exercises
DROP CONSTRAINT IF EXISTS fk_template_exercises_exercise,
ADD CONSTRAINT fk_template_exercises_exercise
FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE SET NULL;

-- =======================
-- HIIT RELATIONS
-- =======================

-- HIIT sessions reference workout (SET NULL if workout deleted to preserve session data)
ALTER TABLE hiit_sessions
DROP CONSTRAINT IF EXISTS fk_hiit_sessions_workout,
ADD CONSTRAINT fk_hiit_sessions_workout
FOREIGN KEY (workout_id) REFERENCES hiit_workouts(id) ON DELETE SET NULL;

-- =======================
-- CARDIO & GPS RELATIONS
-- =======================

-- Location points should be deleted when cardio session is deleted
ALTER TABLE location_points
DROP CONSTRAINT IF EXISTS fk_location_points_session,
ADD CONSTRAINT fk_location_points_session
FOREIGN KEY (cardio_session_id) REFERENCES cardio_sessions(id) ON DELETE CASCADE;

-- GPS tracking points should be deleted when GPS session is deleted
ALTER TABLE gps_tracking_points
DROP CONSTRAINT IF EXISTS fk_gps_points_session,
ADD CONSTRAINT fk_gps_points_session
FOREIGN KEY (session_id) REFERENCES gps_tracking_sessions(id) ON DELETE CASCADE;

-- GPS tracking sessions can reference cardio session (SET NULL to preserve GPS data)
ALTER TABLE gps_tracking_sessions
DROP CONSTRAINT IF EXISTS fk_gps_sessions_cardio,
ADD CONSTRAINT fk_gps_sessions_cardio
FOREIGN KEY (cardio_session_id) REFERENCES cardio_sessions(id) ON DELETE SET NULL;

-- =======================
-- FOOD ENTRY RELATIONS
-- =======================

-- Food entries can reference different types of foods (all SET NULL to preserve entry)
ALTER TABLE food_entries
DROP CONSTRAINT IF EXISTS fk_food_entries_food,
ADD CONSTRAINT fk_food_entries_food
FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE SET NULL;

ALTER TABLE food_entries
DROP CONSTRAINT IF EXISTS fk_food_entries_custom_food,
ADD CONSTRAINT fk_food_entries_custom_food
FOREIGN KEY (custom_food_id) REFERENCES custom_foods(id) ON DELETE SET NULL;

ALTER TABLE food_entries
DROP CONSTRAINT IF EXISTS fk_food_entries_recipe,
ADD CONSTRAINT fk_food_entries_recipe
FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE SET NULL;

-- =======================
-- INDEXES FOR PERFORMANCE
-- =======================

CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_food_id ON recipe_ingredients(food_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_session_id ON workout_exercises(session_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_exercise_id ON workout_exercises(exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_sets_workout_exercise_id ON exercise_sets(workout_exercise_id);
CREATE INDEX IF NOT EXISTS idx_workout_template_exercises_template_id ON workout_template_exercises(template_id);
CREATE INDEX IF NOT EXISTS idx_workout_template_exercises_exercise_id ON workout_template_exercises(exercise_id);
CREATE INDEX IF NOT EXISTS idx_hiit_sessions_workout_id ON hiit_sessions(workout_id);
CREATE INDEX IF NOT EXISTS idx_location_points_session_id ON location_points(cardio_session_id);
CREATE INDEX IF NOT EXISTS idx_gps_points_session_id ON gps_tracking_points(session_id);
CREATE INDEX IF NOT EXISTS idx_gps_sessions_cardio_id ON gps_tracking_sessions(cardio_session_id);
CREATE INDEX IF NOT EXISTS idx_food_entries_food_id ON food_entries(food_id);
CREATE INDEX IF NOT EXISTS idx_food_entries_custom_food_id ON food_entries(custom_food_id);
CREATE INDEX IF NOT EXISTS idx_food_entries_recipe_id ON food_entries(recipe_id);

-- =======================
-- VERIFICATION QUERY
-- =======================

-- Run this query to see all cascade relationships:
--
-- SELECT
--   tc.table_name,
--   kcu.column_name,
--   ccu.table_name AS foreign_table_name,
--   ccu.column_name AS foreign_column_name,
--   rc.delete_rule
-- FROM information_schema.table_constraints AS tc
-- JOIN information_schema.key_column_usage AS kcu
--   ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.constraint_column_usage AS ccu
--   ON ccu.constraint_name = tc.constraint_name
-- JOIN information_schema.referential_constraints AS rc
--   ON tc.constraint_name = rc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY'
-- ORDER BY tc.table_name, kcu.column_name;
