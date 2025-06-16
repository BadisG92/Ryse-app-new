-- =======================
-- MIGRATION: Add first_name and last_name fields to users table
-- =======================

-- Add first_name and last_name columns to users table
ALTER TABLE users 
ADD COLUMN first_name TEXT,
ADD COLUMN last_name TEXT;

-- Update existing users if they have a name field
-- Split the name field into first_name and last_name
UPDATE users 
SET 
  first_name = CASE 
    WHEN name IS NOT NULL AND name != '' THEN 
      SPLIT_PART(name, ' ', 1)
    ELSE NULL 
  END,
  last_name = CASE 
    WHEN name IS NOT NULL AND name != '' AND LENGTH(name) - LENGTH(REPLACE(name, ' ', '')) > 0 THEN 
      SUBSTRING(name FROM POSITION(' ' IN name) + 1)
    ELSE NULL 
  END
WHERE name IS NOT NULL;

-- Optional: Remove the old name column if no longer needed
-- ALTER TABLE users DROP COLUMN name;

-- Update the updated_at timestamp
UPDATE users SET updated_at = NOW(); 