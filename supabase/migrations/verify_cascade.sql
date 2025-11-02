-- =======================
-- VERIFICATION SCRIPT FOR CASCADE CONSTRAINTS
-- Execute this after applying CASCADE migrations
-- =======================

-- Display script header
SELECT '===================================================' as title;
SELECT 'CASCADE CONSTRAINTS VERIFICATION REPORT' as title;
SELECT '===================================================' as title;
SELECT '' as spacer;

-- =======================
-- 1. COUNT ALL FOREIGN KEYS REFERENCING auth.users
-- =======================

SELECT '1. FOREIGN KEYS POINTING TO auth.users' as section;
SELECT '---------------------------------------------------' as separator;

SELECT
  conname AS constraint_name,
  conrelid::regclass AS table_name,
  CASE confdeltype
    WHEN 'c' THEN '✅ CASCADE'
    WHEN 'n' THEN '⚠️  SET NULL'
    WHEN 'r' THEN '❌ RESTRICT'
    WHEN 'a' THEN '❌ NO ACTION'
    ELSE '❓ UNKNOWN'
  END AS on_delete_action,
  confdeltype as action_code
FROM pg_constraint
WHERE confrelid = 'auth.users'::regclass
  AND contype = 'f'
ORDER BY
  CASE confdeltype
    WHEN 'c' THEN 1
    WHEN 'n' THEN 2
    ELSE 3
  END,
  table_name;

SELECT '' as spacer;

-- =======================
-- 2. COUNT BY ACTION TYPE
-- =======================

SELECT '2. SUMMARY BY ACTION TYPE' as section;
SELECT '---------------------------------------------------' as separator;

SELECT
  CASE confdeltype
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET NULL'
    WHEN 'r' THEN 'RESTRICT'
    WHEN 'a' THEN 'NO ACTION'
    ELSE 'UNKNOWN'
  END AS action_type,
  COUNT(*) as count
FROM pg_constraint
WHERE confrelid = 'auth.users'::regclass
  AND contype = 'f'
GROUP BY confdeltype
ORDER BY count DESC;

SELECT '' as spacer;

-- =======================
-- 3. TABLES WITHOUT CASCADE (SHOULD BE EMPTY OR INTENTIONAL)
-- =======================

SELECT '3. TABLES WITH user_id BUT NO CASCADE' as section;
SELECT '---------------------------------------------------' as separator;
SELECT '(This should be empty or only show intentional SET NULL)' as note;

WITH user_id_tables AS (
  SELECT DISTINCT
    table_name,
    column_name
  FROM information_schema.columns
  WHERE column_name IN ('user_id', 'reported_by', 'reviewed_by')
    AND table_schema = 'public'
),
cascade_tables AS (
  SELECT DISTINCT
    conrelid::regclass::text AS table_name
  FROM pg_constraint
  WHERE confrelid = 'auth.users'::regclass
    AND contype = 'f'
    AND confdeltype = 'c'
)
SELECT
  u.table_name,
  u.column_name,
  CASE
    WHEN c.table_name IS NOT NULL THEN '✅ Has CASCADE'
    ELSE '⚠️  Missing CASCADE'
  END as status
FROM user_id_tables u
LEFT JOIN cascade_tables c ON u.table_name = c.table_name
WHERE u.table_name NOT IN ('auth.users', 'users')
ORDER BY
  CASE WHEN c.table_name IS NOT NULL THEN 1 ELSE 0 END,
  u.table_name;

SELECT '' as spacer;

-- =======================
-- 4. ALL TABLE RELATIONSHIPS (CASCADE AND SET NULL)
-- =======================

SELECT '4. ALL CASCADE RELATIONSHIPS (INCLUDING TABLE-TO-TABLE)' as section;
SELECT '---------------------------------------------------' as separator;

SELECT
  tc.table_name as from_table,
  kcu.column_name as from_column,
  ccu.table_name AS to_table,
  ccu.column_name AS to_column,
  CASE rc.delete_rule
    WHEN 'CASCADE' THEN '✅ CASCADE'
    WHEN 'SET NULL' THEN '⚠️  SET NULL'
    WHEN 'RESTRICT' THEN '❌ RESTRICT'
    WHEN 'NO ACTION' THEN '❌ NO ACTION'
    ELSE rc.delete_rule
  END AS delete_action
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND rc.delete_rule IN ('CASCADE', 'SET NULL')
ORDER BY
  CASE rc.delete_rule
    WHEN 'CASCADE' THEN 1
    WHEN 'SET NULL' THEN 2
    ELSE 3
  END,
  tc.table_name,
  kcu.column_name;

SELECT '' as spacer;

-- =======================
-- 5. EXPECTED TABLES CHECK
-- =======================

SELECT '5. EXPECTED TABLES WITH CASCADE' as section;
SELECT '---------------------------------------------------' as separator;

WITH expected_tables AS (
  SELECT unnest(ARRAY[
    'foods',
    'custom_foods',
    'food_entries',
    'barcode_foods',
    'recipes',
    'exercises',
    'workout_sessions',
    'workout_templates',
    'workout_programs',
    'hiit_workouts',
    'hiit_sessions',
    'cardio_activities',
    'cardio_sessions',
    'gps_tracking_sessions',
    'community_ratings',
    'user_collections',
    'external_api_logs'
  ]) as table_name
),
actual_cascades AS (
  SELECT DISTINCT
    conrelid::regclass::text AS table_name
  FROM pg_constraint
  WHERE confrelid = 'auth.users'::regclass
    AND contype = 'f'
    AND confdeltype = 'c'
)
SELECT
  e.table_name,
  CASE
    WHEN a.table_name IS NOT NULL THEN '✅ CASCADE configured'
    ELSE '❌ CASCADE missing'
  END as status
FROM expected_tables e
LEFT JOIN actual_cascades a ON e.table_name = a.table_name
ORDER BY
  CASE WHEN a.table_name IS NOT NULL THEN 1 ELSE 0 END,
  e.table_name;

SELECT '' as spacer;

-- =======================
-- 6. INDEX VERIFICATION
-- =======================

SELECT '6. INDEXES ON FOREIGN KEY COLUMNS' as section;
SELECT '---------------------------------------------------' as separator;

SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND (
    indexdef LIKE '%user_id%'
    OR indexdef LIKE '%session_id%'
    OR indexdef LIKE '%recipe_id%'
    OR indexdef LIKE '%exercise_id%'
  )
ORDER BY tablename, indexname;

SELECT '' as spacer;

-- =======================
-- 7. PERFORMANCE ESTIMATE
-- =======================

SELECT '7. ESTIMATED DELETION IMPACT (Row Counts)' as section;
SELECT '---------------------------------------------------' as separator;
SELECT 'When a user is deleted, these rows will be affected:' as note;

SELECT
  'food_entries' as table_name,
  COUNT(*) as avg_rows_per_user,
  'CASCADE DELETE' as action
FROM food_entries
GROUP BY user_id
ORDER BY COUNT(*) DESC
LIMIT 1

UNION ALL

SELECT
  'custom_foods' as table_name,
  COUNT(*) as avg_rows_per_user,
  'CASCADE DELETE' as action
FROM custom_foods
GROUP BY user_id
ORDER BY COUNT(*) DESC
LIMIT 1

UNION ALL

SELECT
  'workout_sessions' as table_name,
  COUNT(*) as avg_rows_per_user,
  'CASCADE DELETE' as action
FROM workout_sessions
GROUP BY user_id
ORDER BY COUNT(*) DESC
LIMIT 1

UNION ALL

SELECT
  'cardio_sessions' as table_name,
  COUNT(*) as avg_rows_per_user,
  'CASCADE DELETE' as action
FROM cardio_sessions
GROUP BY user_id
ORDER BY COUNT(*) DESC
LIMIT 1;

SELECT '' as spacer;

-- =======================
-- FINAL SUMMARY
-- =======================

SELECT '===================================================' as title;
SELECT 'VERIFICATION COMPLETE' as title;
SELECT '===================================================' as title;

SELECT
  'Total FK constraints to auth.users: ' ||
  (SELECT COUNT(*) FROM pg_constraint WHERE confrelid = 'auth.users'::regclass AND contype = 'f') as summary;

SELECT
  'Constraints with CASCADE: ' ||
  (SELECT COUNT(*) FROM pg_constraint WHERE confrelid = 'auth.users'::regclass AND contype = 'f' AND confdeltype = 'c') as summary;

SELECT
  'Constraints with SET NULL: ' ||
  (SELECT COUNT(*) FROM pg_constraint WHERE confrelid = 'auth.users'::regclass AND contype = 'f' AND confdeltype = 'n') as summary;

SELECT
  'Constraints with RESTRICT/NO ACTION: ' ||
  (SELECT COUNT(*) FROM pg_constraint WHERE confrelid = 'auth.users'::regclass AND contype = 'f' AND confdeltype NOT IN ('c', 'n')) as summary;
