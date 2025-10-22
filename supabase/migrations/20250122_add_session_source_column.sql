-- Migration: Add session_source column to workout_session_summaries
-- This properly tracks the origin of workout sessions: manual, guided_template, or ai_coach
-- AI sessions are treated as manual sessions (user-specific, not template-based)

-- Add session_source column with CHECK constraint
ALTER TABLE workout_session_summaries
ADD COLUMN IF NOT EXISTS session_source VARCHAR(20) DEFAULT 'manual'
CHECK (session_source IN ('manual', 'guided_template', 'ai_coach'));

-- Update existing records based on guided_template_id
UPDATE workout_session_summaries
SET session_source = CASE
  WHEN guided_template_id IS NOT NULL THEN 'guided_template'
  ELSE 'manual'
END
WHERE session_source = 'manual';

-- Create index for efficient filtering by session source
CREATE INDEX IF NOT EXISTS idx_workout_session_summaries_session_source
ON workout_session_summaries(session_source);

-- Add comment
COMMENT ON COLUMN workout_session_summaries.session_source IS 'Origin of the workout session: manual (user-created), guided_template (from app template), or ai_coach (AI-generated but treated as manual)';
