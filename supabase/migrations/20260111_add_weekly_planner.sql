-- =====================================================
-- Weekly Planner Tables Migration
-- Feature: AI-powered weekly planning (Premium only)
-- =====================================================

-- Table: planned_activities (meals + cardio)
CREATE TABLE IF NOT EXISTS planned_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  planned_date DATE NOT NULL,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'cardio')),
  activity_data JSONB DEFAULT '{}',
  -- Cardio: {"activity_name": "Course", "target_minutes": 30, "target_km": 5, "activity_key": "running"}
  -- Meals: {"food_description": "4 oeufs", "linked_entry_id": "uuid", "calories": 280, "proteins": 24}
  status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'completed', 'missed')),
  is_ai_generated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table: planned_workouts (AI-generated workouts stored for later)
CREATE TABLE IF NOT EXISTS planned_workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  planned_date DATE NOT NULL,
  workout_name TEXT NOT NULL,
  duration_minutes INT,
  exercises_json JSONB NOT NULL,
  -- Structure: [{"exercise": {...}, "sets": [...], "suggestedRepsMin": 8, "suggestedRepsMax": 12}]
  user_prompt TEXT, -- Original user request for context
  status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'completed', 'missed')),
  linked_session_id UUID REFERENCES workout_session_summaries(id) ON DELETE SET NULL,
  is_ai_generated BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- Indexes for performance
-- =====================================================

-- Index for fetching week data efficiently
CREATE INDEX IF NOT EXISTS idx_planned_activities_user_week
ON planned_activities(user_id, planned_date);

CREATE INDEX IF NOT EXISTS idx_planned_workouts_user_week
ON planned_workouts(user_id, planned_date);

-- Index for status filtering (cleanup queries)
CREATE INDEX IF NOT EXISTS idx_planned_activities_status
ON planned_activities(user_id, status, planned_date);

CREATE INDEX IF NOT EXISTS idx_planned_workouts_status
ON planned_workouts(user_id, status, planned_date);

-- =====================================================
-- Row Level Security (RLS)
-- =====================================================

ALTER TABLE planned_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE planned_workouts ENABLE ROW LEVEL SECURITY;

-- Policies for planned_activities
CREATE POLICY "Users can view own planned activities"
ON planned_activities FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own planned activities"
ON planned_activities FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own planned activities"
ON planned_activities FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own planned activities"
ON planned_activities FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Policies for planned_workouts
CREATE POLICY "Users can view own planned workouts"
ON planned_workouts FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own planned workouts"
ON planned_workouts FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own planned workouts"
ON planned_workouts FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own planned workouts"
ON planned_workouts FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- =====================================================
-- Trigger for updated_at
-- =====================================================

-- Function to update timestamp (reuse if exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
DROP TRIGGER IF EXISTS update_planned_activities_updated_at ON planned_activities;
CREATE TRIGGER update_planned_activities_updated_at
BEFORE UPDATE ON planned_activities
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_planned_workouts_updated_at ON planned_workouts;
CREATE TRIGGER update_planned_workouts_updated_at
BEFORE UPDATE ON planned_workouts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Comments for documentation
-- =====================================================

COMMENT ON TABLE planned_activities IS 'Weekly planner - planned meals and cardio sessions';
COMMENT ON TABLE planned_workouts IS 'Weekly planner - AI-generated workouts stored for later execution';

COMMENT ON COLUMN planned_activities.activity_type IS 'Type: breakfast, lunch, dinner, snack, or cardio';
COMMENT ON COLUMN planned_activities.activity_data IS 'JSON data specific to activity type';
COMMENT ON COLUMN planned_activities.status IS 'planned (default), completed (done), missed (past due)';

COMMENT ON COLUMN planned_workouts.exercises_json IS 'Full workout structure from AI generation';
COMMENT ON COLUMN planned_workouts.linked_session_id IS 'Links to actual session after completion';
COMMENT ON COLUMN planned_workouts.user_prompt IS 'Original user request for AI context';
