-- Migration: Add linked_session_id to planned_activities
-- This column links completed cardio activities to their cardio_sessions record

-- Add the column
ALTER TABLE planned_activities
ADD COLUMN IF NOT EXISTS linked_session_id UUID REFERENCES cardio_sessions(id) ON DELETE SET NULL;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_planned_activities_linked_session_id
ON planned_activities(linked_session_id)
WHERE linked_session_id IS NOT NULL;

-- Comment
COMMENT ON COLUMN planned_activities.linked_session_id IS 'Links completed cardio activities to their cardio_sessions record for bidirectional sync';
