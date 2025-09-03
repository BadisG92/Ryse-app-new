-- =======================
-- MIGRATION: Recreate User Workout Templates Tables
-- Description: Creates user_workout_templates and user_workout_template_exercises tables
-- =======================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom_exercises table if it doesn't exist
-- (Referenced in the codebase but might not exist yet)
CREATE TABLE IF NOT EXISTS custom_exercises (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  muscle_group TEXT,
  equipment TEXT,
  description TEXT,
  visible_list BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT fk_custom_exercises_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create user_workout_templates table
CREATE TABLE user_workout_templates (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_custom BOOLEAN DEFAULT true,
  estimated_duration_minutes INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT fk_user_workout_templates_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create user_workout_template_exercises table
CREATE TABLE user_workout_template_exercises (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL,
  exercise_id UUID,
  custom_exercise_id UUID,
  order_index INTEGER NOT NULL,
  suggested_sets INTEGER,
  suggested_reps_min INTEGER,
  suggested_reps_max INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT fk_template_exercises_template FOREIGN KEY (template_id) REFERENCES user_workout_templates(id) ON DELETE CASCADE,
  CONSTRAINT fk_template_exercises_exercise FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE SET NULL,
  CONSTRAINT fk_template_exercises_custom_exercise FOREIGN KEY (custom_exercise_id) REFERENCES custom_exercises(id) ON DELETE SET NULL,
  -- Constraint to ensure either exercise_id or custom_exercise_id is set, but not both
  CONSTRAINT chk_exercise_reference CHECK (
    (exercise_id IS NOT NULL AND custom_exercise_id IS NULL) OR 
    (exercise_id IS NULL AND custom_exercise_id IS NOT NULL)
  )
);

-- =======================
-- INDEXES FOR PERFORMANCE
-- =======================

-- User-based queries
CREATE INDEX idx_custom_exercises_user_id ON custom_exercises(user_id);
CREATE INDEX idx_custom_exercises_visible ON custom_exercises(user_id, visible_list) WHERE visible_list = true;

CREATE INDEX idx_user_workout_templates_user_id ON user_workout_templates(user_id);
CREATE INDEX idx_user_workout_templates_created ON user_workout_templates(user_id, created_at DESC);

CREATE INDEX idx_template_exercises_template ON user_workout_template_exercises(template_id);
CREATE INDEX idx_template_exercises_order ON user_workout_template_exercises(template_id, order_index);
CREATE INDEX idx_template_exercises_exercise ON user_workout_template_exercises(exercise_id) WHERE exercise_id IS NOT NULL;
CREATE INDEX idx_template_exercises_custom ON user_workout_template_exercises(custom_exercise_id) WHERE custom_exercise_id IS NOT NULL;

-- =======================
-- ROW LEVEL SECURITY (RLS)
-- =======================

-- Enable RLS on all tables
ALTER TABLE custom_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_workout_template_exercises ENABLE ROW LEVEL SECURITY;

-- RLS Policies for custom_exercises
CREATE POLICY "Users can manage their own custom exercises" 
ON custom_exercises FOR ALL 
USING (auth.uid() = user_id);

-- RLS Policies for user_workout_templates
CREATE POLICY "Users can manage their own workout templates" 
ON user_workout_templates FOR ALL 
USING (auth.uid() = user_id);

-- RLS Policies for user_workout_template_exercises
CREATE POLICY "Users can manage their own template exercises" 
ON user_workout_template_exercises FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM user_workout_templates 
    WHERE id = template_id AND user_id = auth.uid()
  )
);

-- =======================
-- UPDATED_AT TRIGGERS
-- =======================

-- Trigger for custom_exercises
CREATE TRIGGER handle_custom_exercises_updated_at
  BEFORE UPDATE ON custom_exercises
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- =======================
-- COMMENTS FOR DOCUMENTATION
-- =======================

COMMENT ON TABLE custom_exercises IS 'Custom exercises created by users';
COMMENT ON COLUMN custom_exercises.visible_list IS 'Whether the exercise appears in the user''s exercise list';

COMMENT ON TABLE user_workout_templates IS 'User-created workout templates';
COMMENT ON COLUMN user_workout_templates.is_custom IS 'Flag to distinguish user templates from system templates';
COMMENT ON COLUMN user_workout_templates.estimated_duration_minutes IS 'Estimated workout duration in minutes';

COMMENT ON TABLE user_workout_template_exercises IS 'Exercises within user workout templates';
COMMENT ON COLUMN user_workout_template_exercises.order_index IS 'Exercise order within the template';
COMMENT ON COLUMN user_workout_template_exercises.exercise_id IS 'Reference to system exercise (mutually exclusive with custom_exercise_id)';
COMMENT ON COLUMN user_workout_template_exercises.custom_exercise_id IS 'Reference to custom exercise (mutually exclusive with exercise_id)';
COMMENT ON COLUMN user_workout_template_exercises.suggested_sets IS 'Suggested number of sets for this exercise';
COMMENT ON COLUMN user_workout_template_exercises.suggested_reps_min IS 'Minimum suggested reps per set';
COMMENT ON COLUMN user_workout_template_exercises.suggested_reps_max IS 'Maximum suggested reps per set';

-- Migration completed successfully