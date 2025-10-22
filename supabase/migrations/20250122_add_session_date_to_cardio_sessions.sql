-- Migration: Add session_date column to cardio_sessions
-- This column stores the date (without time) for easier weekly filtering

-- Add session_date column
ALTER TABLE cardio_sessions
ADD COLUMN IF NOT EXISTS session_date DATE;

-- Populate session_date from start_time for existing records
UPDATE cardio_sessions
SET session_date = start_time::date
WHERE session_date IS NULL;

-- Create index for efficient filtering by date
CREATE INDEX IF NOT EXISTS idx_cardio_sessions_session_date
ON cardio_sessions(session_date);

-- Add trigger to automatically set session_date when start_time is set
CREATE OR REPLACE FUNCTION set_cardio_session_date()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.start_time IS NOT NULL THEN
    NEW.session_date := NEW.start_time::date;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trg_set_cardio_session_date ON cardio_sessions;

CREATE TRIGGER trg_set_cardio_session_date
BEFORE INSERT OR UPDATE OF start_time ON cardio_sessions
FOR EACH ROW
EXECUTE FUNCTION set_cardio_session_date();

-- Add comment
COMMENT ON COLUMN cardio_sessions.session_date IS 'Date of the session (extracted from start_time) for efficient date-based filtering';
