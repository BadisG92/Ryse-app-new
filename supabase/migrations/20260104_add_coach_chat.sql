-- Migration: Add Coach Chat feature
-- Date: 2026-01-04
-- Description: Creates tables for AI coach chat functionality with multi-conversation support

-- =============================================
-- TABLE: coach_conversations
-- =============================================
-- Stores conversation sessions (max 5 per user)
CREATE TABLE IF NOT EXISTS coach_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT, -- Auto-generated from first message or AI summary
  started_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  message_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for coach_conversations
CREATE INDEX IF NOT EXISTS idx_coach_conversations_user_id
  ON coach_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_coach_conversations_last_message
  ON coach_conversations(user_id, last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_coach_conversations_active
  ON coach_conversations(user_id, is_active) WHERE is_active = TRUE;

-- =============================================
-- TABLE: coach_messages
-- =============================================
-- Stores individual chat messages
CREATE TABLE IF NOT EXISTS coach_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES coach_conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  tokens_used INTEGER DEFAULT 0, -- For cost tracking
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for coach_messages
CREATE INDEX IF NOT EXISTS idx_coach_messages_conversation
  ON coach_messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_coach_messages_user
  ON coach_messages(user_id);

-- =============================================
-- TABLE: user_coach_preferences
-- =============================================
-- Stores preferences extracted from conversations (allergies, restrictions, etc.)
CREATE TABLE IF NOT EXISTS user_coach_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  preferences JSONB DEFAULT '{
    "allergies": [],
    "dietary_restrictions": [],
    "food_preferences": [],
    "fitness_constraints": [],
    "preferred_workout_times": [],
    "custom_notes": []
  }'::jsonb,
  last_extraction_at TIMESTAMPTZ,
  extraction_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for user_coach_preferences
CREATE INDEX IF NOT EXISTS idx_user_coach_preferences_user
  ON user_coach_preferences(user_id);

-- =============================================
-- TABLE: coach_daily_usage
-- =============================================
-- Tracks daily message usage for rate limiting (5 msg/day free users)
CREATE TABLE IF NOT EXISTS coach_daily_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  message_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, usage_date)
);

-- Index for coach_daily_usage
CREATE INDEX IF NOT EXISTS idx_coach_daily_usage_user_date
  ON coach_daily_usage(user_id, usage_date);

-- =============================================
-- FUNCTION: Update conversation timestamp
-- =============================================
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE coach_conversations
  SET
    last_message_at = NEW.created_at,
    message_count = message_count + 1,
    updated_at = NOW()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update conversation on new message
DROP TRIGGER IF EXISTS trigger_update_conversation_on_message ON coach_messages;
CREATE TRIGGER trigger_update_conversation_on_message
  AFTER INSERT ON coach_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_last_message();

-- =============================================
-- FUNCTION: Auto-generate conversation title
-- =============================================
CREATE OR REPLACE FUNCTION generate_conversation_title()
RETURNS TRIGGER AS $$
DECLARE
  first_user_message TEXT;
BEGIN
  -- Only generate title if it's NULL and this is the first user message
  IF NEW.role = 'user' THEN
    SELECT title INTO first_user_message FROM coach_conversations WHERE id = NEW.conversation_id;
    IF first_user_message IS NULL THEN
      UPDATE coach_conversations
      SET title = LEFT(NEW.content, 50) || CASE WHEN LENGTH(NEW.content) > 50 THEN '...' ELSE '' END
      WHERE id = NEW.conversation_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate title from first message
DROP TRIGGER IF EXISTS trigger_generate_conversation_title ON coach_messages;
CREATE TRIGGER trigger_generate_conversation_title
  AFTER INSERT ON coach_messages
  FOR EACH ROW
  EXECUTE FUNCTION generate_conversation_title();

-- =============================================
-- RLS Policies
-- =============================================

-- Enable RLS
ALTER TABLE coach_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_coach_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_daily_usage ENABLE ROW LEVEL SECURITY;

-- Policies for coach_conversations
CREATE POLICY "Users can view their own conversations"
  ON coach_conversations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own conversations"
  ON coach_conversations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations"
  ON coach_conversations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations"
  ON coach_conversations FOR DELETE
  USING (auth.uid() = user_id);

-- Policies for coach_messages
CREATE POLICY "Users can view their own messages"
  ON coach_messages FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own messages"
  ON coach_messages FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policies for user_coach_preferences
CREATE POLICY "Users can view their own preferences"
  ON user_coach_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences"
  ON user_coach_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences"
  ON user_coach_preferences FOR UPDATE
  USING (auth.uid() = user_id);

-- Policies for coach_daily_usage
CREATE POLICY "Users can view their own usage"
  ON coach_daily_usage FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own usage"
  ON coach_daily_usage FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own usage"
  ON coach_daily_usage FOR UPDATE
  USING (auth.uid() = user_id);

-- =============================================
-- COMMENTS
-- =============================================
COMMENT ON TABLE coach_conversations IS 'Stores AI coach chat conversations (max 5 per user)';
COMMENT ON TABLE coach_messages IS 'Stores individual chat messages in conversations';
COMMENT ON TABLE user_coach_preferences IS 'Stores user preferences extracted from coach conversations';
COMMENT ON TABLE coach_daily_usage IS 'Tracks daily message usage for rate limiting';
