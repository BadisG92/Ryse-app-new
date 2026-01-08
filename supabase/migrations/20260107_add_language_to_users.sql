-- Add language column to users table
-- Stores the user's preferred language (fr, en, de)

ALTER TABLE users ADD COLUMN IF NOT EXISTS language TEXT DEFAULT 'fr';

-- Add comment
COMMENT ON COLUMN users.language IS 'User preferred language: fr, en, de';
