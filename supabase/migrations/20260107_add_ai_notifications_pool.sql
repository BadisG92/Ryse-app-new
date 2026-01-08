-- ============================================
-- AI Notifications Pool Table
-- Stores pre-generated AI notifications for personalized push messages
-- Generated weekly by Edge Function, 30% of notifications use AI
-- ============================================

-- Create the ai_notifications_pool table
CREATE TABLE IF NOT EXISTS ai_notifications_pool (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL, -- meal, water, streak, workout, progress, etc.
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  locale TEXT NOT NULL DEFAULT 'fr', -- fr, en, de
  coach_personality TEXT, -- friendly, strict, supportive, sassy, direct, custom
  context_used TEXT, -- event, progress, blocker, motivation, goal
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  used BOOLEAN DEFAULT FALSE,
  used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ, -- expire after 7 days
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient lookup of unused notifications by user and type
CREATE INDEX IF NOT EXISTS idx_ai_notifs_user_unused
ON ai_notifications_pool(user_id, used, notification_type);

-- Index for cleanup of expired notifications
CREATE INDEX IF NOT EXISTS idx_ai_notifs_expires
ON ai_notifications_pool(expires_at) WHERE used = false;

-- Index for locale filtering
CREATE INDEX IF NOT EXISTS idx_ai_notifs_locale
ON ai_notifications_pool(user_id, locale);

-- Enable RLS
ALTER TABLE ai_notifications_pool ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only read their own notifications
CREATE POLICY "Users can read own ai notifications"
ON ai_notifications_pool FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can update (mark as used) their own notifications
CREATE POLICY "Users can update own ai notifications"
ON ai_notifications_pool FOR UPDATE
USING (auth.uid() = user_id);

-- Policy: Only service role can insert (Edge Function)
CREATE POLICY "Service role can insert ai notifications"
ON ai_notifications_pool FOR INSERT
WITH CHECK (true);

-- Policy: Service role can delete (cleanup)
CREATE POLICY "Service role can delete ai notifications"
ON ai_notifications_pool FOR DELETE
USING (true);

-- Comment on table
COMMENT ON TABLE ai_notifications_pool IS 'Pre-generated AI notifications for personalized push messages. Generated weekly, 30% of notifications use AI content.';
COMMENT ON COLUMN ai_notifications_pool.notification_type IS 'Type of notification: meal, water, streak, workout, progress';
COMMENT ON COLUMN ai_notifications_pool.locale IS 'Language of the notification: fr, en, de';
COMMENT ON COLUMN ai_notifications_pool.coach_personality IS 'Coach personality used: friendly, strict, supportive, sassy, direct, custom';
COMMENT ON COLUMN ai_notifications_pool.context_used IS 'User context that influenced the message: event, progress, blocker, motivation, goal';
