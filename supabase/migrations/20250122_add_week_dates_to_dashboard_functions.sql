-- Migration: Add week_start_date and week_end_date parameters to dashboard functions
-- This fixes timezone issues by allowing Flutter to calculate the current week in user's local time
-- and pass explicit dates to PostgreSQL

-- Recreate function with date parameters
CREATE OR REPLACE FUNCTION get_weekly_dashboard_data(
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
  weekly_sessions_data JSON;
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

  -- Calculate weekly stats (semaine courante lundi-dimanche)
  SELECT json_build_object(
    'sessions', COALESCE(COUNT(DISTINCT wss.id), 0),
    'total_volume', COALESCE(SUM(wss.total_volume_kg), 0),
    'total_calories', COALESCE(SUM(wss.calories_burned), 0)
  ) INTO weekly_stats_data
  FROM workout_session_summaries wss
  WHERE wss.user_id = target_user_id
    AND wss.session_date >= actual_week_start
    AND wss.session_date < actual_week_end;

  -- Get weekly sessions WITHOUT nested exercises (to avoid nested aggregates)
  SELECT json_agg(
    json_build_object(
      'id', wss.id,
      'history_session_id', wss.history_session_id,
      'session_name', wss.session_name,
      'performed_at', wss.performed_at,
      'session_date', wss.session_date,
      'duration_minutes', wss.duration_minutes,
      'num_exercises', wss.num_exercises,
      'total_volume_kg', wss.total_volume_kg,
      'calories_burned', wss.calories_burned,
      'intensity', wss.intensity
    ) ORDER BY wss.performed_at DESC
  ) INTO weekly_sessions_data
  FROM workout_session_summaries wss
  WHERE wss.user_id = target_user_id
    AND wss.session_date >= actual_week_start
    AND wss.session_date < actual_week_end;

  -- Combine results
  result := json_build_object(
    'weekly_stats', COALESCE(weekly_stats_data, '{}'::json),
    'weekly_sessions', COALESCE(weekly_sessions_data, '[]'::json)
  );

  RETURN result;
END;
$$;

-- Recreate cardio function with date parameters
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

  -- Calculate weekly stats (semaine courante lundi-dimanche)
  SELECT json_build_object(
    'total_distance', COALESCE(SUM(distance_km), 0),
    'total_duration_minutes', COALESCE(SUM(duration_seconds / 60), 0),
    'total_calories', COALESCE(SUM(calories), 0),
    'sessions_count', COALESCE(COUNT(*), 0)
  ) INTO weekly_stats_data
  FROM cardio_sessions
  WHERE user_id = target_user_id
    AND is_completed = true
    AND session_date >= actual_week_start
    AND session_date < actual_week_end;

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
    'notes', notes
  ) INTO last_session_data
  FROM cardio_sessions
  WHERE user_id = target_user_id
    AND is_completed = true
  ORDER BY created_at DESC
  LIMIT 1;

  -- Get sessions from current week
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
      'notes', notes
    ) ORDER BY created_at DESC
  ) INTO week_sessions_data
  FROM cardio_sessions
  WHERE user_id = target_user_id
    AND is_completed = true
    AND session_date >= actual_week_start
    AND session_date < actual_week_end;

  -- Combine results
  result := json_build_object(
    'weekly_stats', COALESCE(weekly_stats_data, '{}'::json),
    'last_session', last_session_data,
    'week_sessions', COALESCE(week_sessions_data, '[]'::json)
  );

  RETURN result;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_weekly_dashboard_data(UUID, DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cardio_dashboard_data(UUID, DATE, DATE) TO authenticated;

-- Add comments
COMMENT ON FUNCTION get_weekly_dashboard_data IS 'Returns weekly workout dashboard data with optional week date parameters (fixes timezone issues)';
COMMENT ON FUNCTION get_cardio_dashboard_data IS 'Returns cardio dashboard data with optional week date parameters (fixes timezone issues)';
