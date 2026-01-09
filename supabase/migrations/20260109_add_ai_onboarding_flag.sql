-- Migration: Add ai_onboarding_completed flag to users table
-- Purpose: Track if existing users have completed the new AI onboarding chat
-- Existing users will have false by default, forcing them through AI onboarding

ALTER TABLE users ADD COLUMN IF NOT EXISTS ai_onboarding_completed BOOLEAN DEFAULT false;

-- Add comment for documentation
COMMENT ON COLUMN users.ai_onboarding_completed IS 'Indicates if user has completed the AI coach onboarding chat. Existing users get false to force them through the new AI onboarding flow.';
