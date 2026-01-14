-- Migration: Fix cardio dashboard to use start_time as fallback when session_date is NULL
-- This ensures consistency between last_session and week_sessions views

-- First, fix any existing sessions with NULL session_date
UPDATE cardio_sessions
SET session_date = DATE(start_time)
WHERE session_date IS NULL AND start_time IS NOT NULL;

-- Recreate cardio function with session_date fallback
CREATE OR REPLACE FUNCTION get_cardio_dashboard_data(
  target_user_id UUID,
  week_start_date DATE DEFAULT NULL,
  week_end_date DATE DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
  weekly_stats_data JSON;
  last_session_data JSON;
  week_sessions_data JSON;
  actual_week_start DATE;
  actual_week_end DATE;
BEGIN
  -- Si les dates ne sont pas fournies, calculer la semaine courante (lundi-dimanche)
  IF week_start_date IS NULL THEN
    actual_week_start := CURRENT_DATE - (EXTRACT(isodow FROM CURRENT_DATE)::int - 1);
  ELSE
    actual_week_start := week_start_date;
  END IF;

  IF week_end_date IS NULL THEN
    actual_week_end := actual_week_start + INTERVAL '7 days';
  ELSE
    actual_week_end := week_end_date;
  END IF;

  -- Calculate weekly stats using COALESCE for session_date fallback
  SELECT json_build_object(
    'total_distance', COALESCE(SUM(distance_km), 0),
    'total_duration_minutes', COALESCE(SUM(duration_seconds / 60), 0),
    'total_calories', COALESCE(SUM(calories), 0),
    'sessions_count', COALESCE(COUNT(*), 0)
  ) INTO weekly_stats_data
  FROM cardio_sessions
  WHERE user_id = target_user_id
    AND is_completed = true
    AND COALESCE(session_date, DATE(start_time)) >= actual_week_start
    AND COALESCE(session_date, DATE(start_time)) < actual_week_end;

  -- Get last session (most recent completed session, regardless of week)
  SELECT json_build_object(
    'id', id,
    'activity_type', activity_type,
    'activity_title', activity_title,
    'format_title', format_title,
    'start_time', start_time,
    'end_time', end_time,
    'distance_km', distance_km,
    'duration_seconds', duration_seconds,
    'calories', calories,
    'average_speed_kmh', average_speed_kmh,
    'steps', steps,
    'notes', notes,
    'session_date', COALESCE(session_date, DATE(start_time))
  ) INTO last_session_data
  FROM cardio_sessions
  WHERE user_id = target_user_id
    AND is_completed = true
  ORDER BY COALESCE(start_time, created_at) DESC
  LIMIT 1;

  -- Get sessions from current week using COALESCE for session_date fallback
  SELECT json_agg(
    json_build_object(
      'id', id,
      'activity_type', activity_type,
      'activity_title', activity_title,
      'format_title', format_title,
      'start_time', start_time,
      'end_time', end_time,
      'distance_km', distance_km,
      'duration_seconds', duration_seconds,
      'calories', calories,
      'average_speed_kmh', average_speed_kmh,
      'steps', steps,
      'notes', notes,
      'session_date', COALESCE(session_date, DATE(start_time))
    ) ORDER BY COALESCE(start_time, created_at) DESC
  ) INTO week_sessions_data
  FROM cardio_sessions
  WHERE user_id = target_user_id
    AND is_completed = true
    AND COALESCE(session_date, DATE(start_time)) >= actual_week_start
    AND COALESCE(session_date, DATE(start_time)) < actual_week_end;

  -- Combine results
  result := json_build_object(
    'weekly_stats', COALESCE(weekly_stats_data, '{}'::json),
    'last_session', last_session_data,
    'week_sessions', COALESCE(week_sessions_data, '[]'::json)
  );

  RETURN result;
END;
$$;

-- Add comment
COMMENT ON FUNCTION get_cardio_dashboard_data IS 'Returns cardio dashboard data with session_date fallback to start_time for consistency';
