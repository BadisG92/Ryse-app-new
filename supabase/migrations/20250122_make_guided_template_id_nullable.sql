-- Migration: Make guided_template_id nullable in workout_session_summaries
-- This allows AI-generated workouts to be saved without requiring a template in workout_templates

-- Drop the foreign key constraint
ALTER TABLE workout_session_summaries
DROP CONSTRAINT IF EXISTS workout_session_summaries_guided_template_id_fkey;

-- Make the column nullable (it may already be, but this ensures it)
ALTER TABLE workout_session_summaries
ALTER COLUMN guided_template_id DROP NOT NULL;

-- Recreate the foreign key constraint with ON DELETE SET NULL
-- This way if a template is deleted, the session summary just loses the reference
ALTER TABLE workout_session_summaries
ADD CONSTRAINT workout_session_summaries_guided_template_id_fkey
FOREIGN KEY (guided_template_id)
REFERENCES workout_templates(id)
ON DELETE SET NULL;

COMMENT ON CONSTRAINT workout_session_summaries_guided_template_id_fkey
ON workout_session_summaries
IS 'Optional reference to guided template. NULL for AI-generated or manual workouts.';
