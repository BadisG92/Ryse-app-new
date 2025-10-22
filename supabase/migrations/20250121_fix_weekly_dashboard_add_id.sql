-- Migration: Fix get_weekly_dashboard_data to include 'id' field
-- This fixes the missing delete button issue in weekly history section

CREATE OR REPLACE FUNCTION get_weekly_dashboard_data(target_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
  weekly_stats_data JSON;
  weekly_sessions_data JSON;
BEGIN
  -- Calculate weekly stats
  SELECT json_build_object(
    'sessions', COALESCE(COUNT(DISTINCT wss.id), 0),
    'total_volume', COALESCE(SUM(wss.total_volume_kg), 0),
    'total_calories', COALESCE(SUM(wss.calories_burned), 0)
  ) INTO weekly_stats_data
  FROM workout_session_summaries wss
  WHERE wss.user_id = target_user_id
    AND wss.performed_at >= (CURRENT_DATE - INTERVAL '7 days');

  -- Get weekly sessions with exercises
  SELECT json_agg(
    json_build_object(
      'id', wss.id,  -- ⚠️ CRITICAL FIX: Add this field for delete functionality
      'history_session_id', wss.history_session_id,
      'session_name', wss.session_name,
      'performed_at', wss.performed_at,
      'session_date', wss.session_date,
      'duration_minutes', wss.duration_minutes,
      'num_exercises', wss.num_exercises,
      'total_volume_kg', wss.total_volume_kg,
      'calories_burned', wss.calories_burned,
      'intensity', wss.intensity,
      'exercises', (
        SELECT json_agg(
          json_build_object(
            'exercise_name', wsh.exercise_name,
            'exercise_id', wsh.exercise_id,
            'custom_exercise_id', wsh.custom_exercise_id,
            'best_weight', MAX(wsh.weight),
            'best_reps', MAX(wsh.reps),
            'sets_count', COUNT(*)
          )
        )
        FROM workout_set_history wsh
        WHERE wsh.history_session_id = wss.history_session_id
          AND wsh.user_id = target_user_id
        GROUP BY wsh.exercise_name, wsh.exercise_id, wsh.custom_exercise_id
      )
    ) ORDER BY wss.performed_at DESC
  ) INTO weekly_sessions_data
  FROM workout_session_summaries wss
  WHERE wss.user_id = target_user_id
    AND wss.performed_at >= (CURRENT_DATE - INTERVAL '7 days');

  -- Combine results
  result := json_build_object(
    'weekly_stats', COALESCE(weekly_stats_data, '{}'::json),
    'weekly_sessions', COALESCE(weekly_sessions_data, '[]'::json)
  );

  RETURN result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_weekly_dashboard_data(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_weekly_dashboard_data IS 'Returns weekly workout dashboard data including stats and sessions with the id field for delete functionality';
