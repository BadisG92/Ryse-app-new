-- =======================
-- MIGRATION: Add nutrition goals to users table
-- =======================

-- Add nutrition-related columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS daily_calories INTEGER DEFAULT 2000,
ADD COLUMN IF NOT EXISTS daily_protein INTEGER DEFAULT 150,
ADD COLUMN IF NOT EXISTS daily_carbs INTEGER DEFAULT 250,
ADD COLUMN IF NOT EXISTS daily_fat INTEGER DEFAULT 80,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS birth_date DATE,
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS height DECIMAL,
ADD COLUMN IF NOT EXISTS weight DECIMAL,
ADD COLUMN IF NOT EXISTS is_metric BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS activity_level TEXT,
ADD COLUMN IF NOT EXISTS fitness_goal TEXT,
ADD COLUMN IF NOT EXISTS obstacles TEXT[],
ADD COLUMN IF NOT EXISTS dietary_restrictions TEXT[],
ADD COLUMN IF NOT EXISTS bmr DECIMAL;

-- Create index for better performance on nutrition queries
CREATE INDEX IF NOT EXISTS idx_users_daily_calories ON users(daily_calories);
CREATE INDEX IF NOT EXISTS idx_users_fitness_goal ON users(fitness_goal);

-- Update the updated_at timestamp
UPDATE users SET updated_at = NOW() WHERE updated_at IS NULL; 