-- Test: Vérifier les dates calculées par la fonction
SELECT 
  CURRENT_DATE as today,
  CURRENT_DATE - (EXTRACT(isodow FROM CURRENT_DATE)::int - 1) as week_start,
  (CURRENT_DATE - (EXTRACT(isodow FROM CURRENT_DATE)::int - 1)) + INTERVAL '7 days' as week_end;

-- Test: Compter les séances dans la semaine courante
SELECT 
  COUNT(*) as sessions_count,
  MIN(session_date) as first_date,
  MAX(session_date) as last_date
FROM cardio_sessions
WHERE user_id = 'eb9e464b-a49c-4908-ac46-09de3ec65ebd'
  AND is_completed = true
  AND session_date >= CURRENT_DATE - (EXTRACT(isodow FROM CURRENT_DATE)::int - 1)
  AND session_date < (CURRENT_DATE - (EXTRACT(isodow FROM CURRENT_DATE)::int - 1)) + INTERVAL '7 days';
