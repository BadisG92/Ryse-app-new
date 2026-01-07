-- Migration: Add weekly bilan and coach personality columns to users table
-- Date: 2026-01-04

-- Add weekly bilan columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS weekly_bilan_day INTEGER; -- 1=Monday, 7=Sunday
ALTER TABLE users ADD COLUMN IF NOT EXISTS weekly_bilan_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_bilan_week DATE; -- To track if bilan done this week
ALTER TABLE users ADD COLUMN IF NOT EXISTS weekly_bilan_hour INTEGER DEFAULT 19; -- Hour of day (0-23)

-- Add coach personality column
ALTER TABLE users ADD COLUMN IF NOT EXISTS coach_personality TEXT; -- Predefined key or custom text
ALTER TABLE users ADD COLUMN IF NOT EXISTS coach_personality_custom TEXT; -- Custom personality description

-- Add comment for clarity
COMMENT ON COLUMN users.weekly_bilan_day IS 'Day of week for weekly check-in (1=Monday, 7=Sunday)';
COMMENT ON COLUMN users.weekly_bilan_enabled IS 'Whether user has enabled weekly check-ins';
COMMENT ON COLUMN users.last_bilan_week IS 'Date of last completed weekly bilan (Monday of that week)';
COMMENT ON COLUMN users.weekly_bilan_hour IS 'Hour of day for weekly check-in (0-23, default 19)';
COMMENT ON COLUMN users.coach_personality IS 'Coach personality type: strict, friendly, supportive, sassy, direct, custom';
COMMENT ON COLUMN users.coach_personality_custom IS 'Custom personality description if coach_personality is custom';
