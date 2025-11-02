-- =======================
-- CASCADE DELETE TEST SCRIPT
-- SAFE TEST - Uses a dedicated test user
-- =======================

-- WARNING: This script creates and deletes a test user
-- Only run in development/staging environment
-- DO NOT RUN IN PRODUCTION without review

\echo '=================================================='
\echo 'CASCADE DELETE TEST - Starting...'
\echo '=================================================='
\echo ''

-- =======================
-- STEP 1: Create test user
-- =======================

\echo 'STEP 1: Creating test user...'

DO $$
DECLARE
  test_user_id UUID := '00000000-0000-0000-0000-cascade-test'::UUID;
  test_email TEXT := 'cascade-test@ryse-app-test.com';
BEGIN
  -- Delete if exists (cleanup from previous test)
  DELETE FROM auth.users WHERE id = test_user_id;

  -- Create test user
  INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
  ) VALUES (
    test_user_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    test_email,
    crypt('test-password-123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    false,
    false
  );

  RAISE NOTICE 'Test user created: %', test_user_id;
END $$;

\echo '✅ Test user created'
\echo ''

-- =======================
-- STEP 2: Add test data
-- =======================

\echo 'STEP 2: Adding test data...'

DO $$
DECLARE
  test_user_id UUID := '00000000-0000-0000-0000-cascade-test'::UUID;
  test_workout_id UUID;
  test_workout_exercise_id UUID;
  test_recipe_id UUID;
  test_cardio_id UUID;
  test_gps_id UUID;
  test_food_id UUID;
BEGIN
  -- Food entries
  INSERT INTO food_entries (
    id, user_id, meal_type, quantity, unit,
    calories, proteins, carbs, fats, consumed_at, created_at, updated_at
  )
  SELECT
    gen_random_uuid(),
    test_user_id,
    'breakfast',
    100,
    'g',
    200,
    10,
    20,
    5,
    NOW() - (i || ' days')::INTERVAL,
    NOW(),
    NOW()
  FROM generate_series(1, 10) i;

  RAISE NOTICE 'Created 10 food entries';

  -- Custom foods
  INSERT INTO custom_foods (
    id, name, calories, proteins, carbs, fats,
    reference_quantity, reference_unit_en, origin,
    user_id, created_at, updated_at
  )
  SELECT
    i,
    'Test Food ' || i,
    100 * i,
    10,
    20,
    5,
    100,
    'g',
    'manual',
    test_user_id,
    NOW(),
    NOW()
  FROM generate_series(1, 5) i;

  RAISE NOTICE 'Created 5 custom foods';

  -- Workout session
  INSERT INTO workout_sessions (
    id, user_id, name, start_time, is_completed, created_at
  ) VALUES (
    gen_random_uuid(),
    test_user_id,
    'Test Workout Session',
    NOW(),
    false,
    NOW()
  ) RETURNING id INTO test_workout_id;

  -- Workout exercises (if exercises table has data)
  IF EXISTS (SELECT 1 FROM exercises LIMIT 1) THEN
    INSERT INTO workout_exercises (
      id, session_id, exercise_id, order_index, created_at
    )
    SELECT
      gen_random_uuid(),
      test_workout_id,
      (SELECT id FROM exercises LIMIT 1),
      i,
      NOW()
    FROM generate_series(1, 3) i
    RETURNING id INTO test_workout_exercise_id;

    -- Exercise sets
    INSERT INTO exercise_sets (
      id, workout_exercise_id, reps, weight, set_order, is_completed, created_at
    )
    SELECT
      gen_random_uuid(),
      test_workout_exercise_id,
      10,
      50,
      i,
      true,
      NOW()
    FROM generate_series(1, 3) i;

    RAISE NOTICE 'Created workout with exercises and sets';
  ELSE
    RAISE NOTICE 'Skipped workout exercises (no exercises in DB)';
  END IF;

  -- Recipe
  INSERT INTO recipes (
    id, name_en, name_fr, steps_en, steps_fr,
    servings, "calories per portion",
    is_custom, user_id, created_at, updated_at
  ) VALUES (
    gen_random_uuid(),
    'Test Recipe',
    'Recette Test',
    ARRAY['Step 1', 'Step 2'],
    ARRAY['Étape 1', 'Étape 2'],
    4,
    300,
    true,
    test_user_id,
    NOW(),
    NOW()
  ) RETURNING id INTO test_recipe_id;

  -- Recipe ingredients (if foods table has data)
  IF EXISTS (SELECT 1 FROM foods LIMIT 1) THEN
    INSERT INTO recipe_ingredients (
      id, recipe_id, food_id, quantity, unit, display_order, created_at
    )
    SELECT
      gen_random_uuid(),
      test_recipe_id,
      (SELECT id FROM foods LIMIT 1),
      100,
      'g',
      i,
      NOW()
    FROM generate_series(1, 3) i;

    RAISE NOTICE 'Created recipe with ingredients';
  ELSE
    RAISE NOTICE 'Created recipe without ingredients (no foods in DB)';
  END IF;

  -- Cardio session
  INSERT INTO cardio_sessions (
    id, user_id, activity_type, activity_title, format_title,
    start_time, duration_seconds, is_running, is_paused, created_at
  ) VALUES (
    gen_random_uuid(),
    test_user_id,
    'running',
    'Test Run',
    'Distance',
    NOW(),
    1800,
    false,
    false,
    NOW()
  ) RETURNING id INTO test_cardio_id;

  -- Location points
  INSERT INTO location_points (
    id, cardio_session_id, latitude, longitude,
    recorded_at, created_at
  )
  SELECT
    gen_random_uuid(),
    test_cardio_id,
    48.8566 + (random() * 0.01),
    2.3522 + (random() * 0.01),
    NOW() - (i || ' seconds')::INTERVAL,
    NOW()
  FROM generate_series(1, 50) i;

  RAISE NOTICE 'Created cardio session with 50 location points';

  -- GPS tracking
  INSERT INTO gps_tracking_sessions (
    id, user_id, activity_type, start_time,
    status, created_at, updated_at
  ) VALUES (
    gen_random_uuid(),
    test_user_id,
    'running',
    NOW(),
    'completed',
    NOW(),
    NOW()
  ) RETURNING id INTO test_gps_id;

  -- GPS points
  INSERT INTO gps_tracking_points (
    id, session_id, latitude, longitude,
    recorded_at, sequence_number, created_at
  )
  SELECT
    gen_random_uuid(),
    test_gps_id,
    48.8566 + (random() * 0.01),
    2.3522 + (random() * 0.01),
    NOW() - (i || ' seconds')::INTERVAL,
    i,
    NOW()
  FROM generate_series(1, 100) i;

  RAISE NOTICE 'Created GPS session with 100 points';

  -- HIIT session
  IF EXISTS (SELECT 1 FROM hiit_workouts LIMIT 1) THEN
    INSERT INTO hiit_sessions (
      id, user_id, workout_id, start_time,
      current_phase, current_round, is_completed, created_at
    ) VALUES (
      gen_random_uuid(),
      test_user_id,
      (SELECT id FROM hiit_workouts LIMIT 1),
      NOW(),
      'work',
      1,
      false,
      NOW()
    );
    RAISE NOTICE 'Created HIIT session';
  END IF;

  -- Community rating
  IF EXISTS (SELECT 1 FROM recipes WHERE is_public = true LIMIT 1) THEN
    INSERT INTO community_ratings (
      id, user_id, content_type, content_id,
      rating, created_at, updated_at
    ) VALUES (
      gen_random_uuid(),
      test_user_id,
      'recipe',
      (SELECT id FROM recipes WHERE is_public = true LIMIT 1),
      5,
      NOW(),
      NOW()
    );
    RAISE NOTICE 'Created community rating';
  END IF;

END $$;

\echo '✅ Test data created'
\echo ''

-- =======================
-- STEP 3: Count data before delete
-- =======================

\echo 'STEP 3: Counting data before delete...'

DO $$
DECLARE
  test_user_id UUID := '00000000-0000-0000-0000-cascade-test'::UUID;
  food_count INT;
  custom_food_count INT;
  workout_count INT;
  workout_ex_count INT;
  set_count INT;
  recipe_count INT;
  recipe_ing_count INT;
  cardio_count INT;
  location_count INT;
  gps_session_count INT;
  gps_point_count INT;
  total_count INT := 0;
BEGIN
  SELECT COUNT(*) INTO food_count FROM food_entries WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO custom_food_count FROM custom_foods WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO workout_count FROM workout_sessions WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO cardio_count FROM cardio_sessions WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO gps_session_count FROM gps_tracking_sessions WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO recipe_count FROM recipes WHERE user_id = test_user_id;

  SELECT COUNT(*) INTO workout_ex_count
  FROM workout_exercises we
  JOIN workout_sessions ws ON we.session_id = ws.id
  WHERE ws.user_id = test_user_id;

  SELECT COUNT(*) INTO set_count
  FROM exercise_sets es
  JOIN workout_exercises we ON es.workout_exercise_id = we.id
  JOIN workout_sessions ws ON we.session_id = ws.id
  WHERE ws.user_id = test_user_id;

  SELECT COUNT(*) INTO recipe_ing_count
  FROM recipe_ingredients ri
  JOIN recipes r ON ri.recipe_id = r.id
  WHERE r.user_id = test_user_id;

  SELECT COUNT(*) INTO location_count
  FROM location_points lp
  JOIN cardio_sessions cs ON lp.cardio_session_id = cs.id
  WHERE cs.user_id = test_user_id;

  SELECT COUNT(*) INTO gps_point_count
  FROM gps_tracking_points gp
  JOIN gps_tracking_sessions gs ON gp.session_id = gs.id
  WHERE gs.user_id = test_user_id;

  total_count := food_count + custom_food_count + workout_count + workout_ex_count +
                 set_count + recipe_count + recipe_ing_count + cardio_count +
                 location_count + gps_session_count + gps_point_count;

  RAISE NOTICE '---------------------------------------------------';
  RAISE NOTICE 'DATA BEFORE DELETE:';
  RAISE NOTICE 'Food entries: %', food_count;
  RAISE NOTICE 'Custom foods: %', custom_food_count;
  RAISE NOTICE 'Workout sessions: %', workout_count;
  RAISE NOTICE '  └─ Workout exercises: %', workout_ex_count;
  RAISE NOTICE '     └─ Exercise sets: %', set_count;
  RAISE NOTICE 'Recipes: %', recipe_count;
  RAISE NOTICE '  └─ Recipe ingredients: %', recipe_ing_count;
  RAISE NOTICE 'Cardio sessions: %', cardio_count;
  RAISE NOTICE '  └─ Location points: %', location_count;
  RAISE NOTICE 'GPS sessions: %', gps_session_count;
  RAISE NOTICE '  └─ GPS points: %', gps_point_count;
  RAISE NOTICE '---------------------------------------------------';
  RAISE NOTICE 'TOTAL ROWS: %', total_count;
  RAISE NOTICE '---------------------------------------------------';
END $$;

\echo ''

-- =======================
-- STEP 4: Delete user (CASCADE TEST)
-- =======================

\echo 'STEP 4: Deleting test user (CASCADE will trigger)...'
\echo 'This is the CRITICAL TEST...'
\echo ''

DO $$
DECLARE
  test_user_id UUID := '00000000-0000-0000-0000-cascade-test'::UUID;
  start_time TIMESTAMP;
  end_time TIMESTAMP;
  duration INTERVAL;
BEGIN
  start_time := clock_timestamp();

  DELETE FROM auth.users WHERE id = test_user_id;

  end_time := clock_timestamp();
  duration := end_time - start_time;

  RAISE NOTICE 'User deleted in: %', duration;
END $$;

\echo '✅ User deleted'
\echo ''

-- =======================
-- STEP 5: Verify CASCADE worked
-- =======================

\echo 'STEP 5: Verifying CASCADE delete...'

DO $$
DECLARE
  test_user_id UUID := '00000000-0000-0000-0000-cascade-test'::UUID;
  food_count INT;
  custom_food_count INT;
  workout_count INT;
  workout_ex_count INT;
  set_count INT;
  recipe_count INT;
  recipe_ing_count INT;
  cardio_count INT;
  location_count INT;
  gps_session_count INT;
  gps_point_count INT;
  total_count INT := 0;
  test_passed BOOLEAN := true;
BEGIN
  SELECT COUNT(*) INTO food_count FROM food_entries WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO custom_food_count FROM custom_foods WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO workout_count FROM workout_sessions WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO cardio_count FROM cardio_sessions WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO gps_session_count FROM gps_tracking_sessions WHERE user_id = test_user_id;
  SELECT COUNT(*) INTO recipe_count FROM recipes WHERE user_id = test_user_id;

  SELECT COUNT(*) INTO workout_ex_count
  FROM workout_exercises we
  JOIN workout_sessions ws ON we.session_id = ws.id
  WHERE ws.user_id = test_user_id;

  SELECT COUNT(*) INTO set_count
  FROM exercise_sets es
  JOIN workout_exercises we ON es.workout_exercise_id = we.id
  JOIN workout_sessions ws ON we.session_id = ws.id
  WHERE ws.user_id = test_user_id;

  SELECT COUNT(*) INTO recipe_ing_count
  FROM recipe_ingredients ri
  JOIN recipes r ON ri.recipe_id = r.id
  WHERE r.user_id = test_user_id;

  SELECT COUNT(*) INTO location_count
  FROM location_points lp
  JOIN cardio_sessions cs ON lp.cardio_session_id = cs.id
  WHERE cs.user_id = test_user_id;

  SELECT COUNT(*) INTO gps_point_count
  FROM gps_tracking_points gp
  JOIN gps_tracking_sessions gs ON gp.session_id = gs.id
  WHERE gs.user_id = test_user_id;

  total_count := food_count + custom_food_count + workout_count + workout_ex_count +
                 set_count + recipe_count + recipe_ing_count + cardio_count +
                 location_count + gps_session_count + gps_point_count;

  RAISE NOTICE '---------------------------------------------------';
  RAISE NOTICE 'DATA AFTER DELETE:';
  RAISE NOTICE 'Food entries: % (expected: 0)', food_count;
  RAISE NOTICE 'Custom foods: % (expected: 0)', custom_food_count;
  RAISE NOTICE 'Workout sessions: % (expected: 0)', workout_count;
  RAISE NOTICE '  └─ Workout exercises: % (expected: 0)', workout_ex_count;
  RAISE NOTICE '     └─ Exercise sets: % (expected: 0)', set_count;
  RAISE NOTICE 'Recipes: % (expected: 0)', recipe_count;
  RAISE NOTICE '  └─ Recipe ingredients: % (expected: 0)', recipe_ing_count;
  RAISE NOTICE 'Cardio sessions: % (expected: 0)', cardio_count;
  RAISE NOTICE '  └─ Location points: % (expected: 0)', location_count;
  RAISE NOTICE 'GPS sessions: % (expected: 0)', gps_session_count;
  RAISE NOTICE '  └─ GPS points: % (expected: 0)', gps_point_count;
  RAISE NOTICE '---------------------------------------------------';
  RAISE NOTICE 'TOTAL REMAINING ROWS: % (expected: 0)', total_count;
  RAISE NOTICE '---------------------------------------------------';

  -- Validate
  IF total_count > 0 THEN
    test_passed := false;
    RAISE WARNING '❌ CASCADE TEST FAILED - Data still exists!';
  ELSE
    RAISE NOTICE '✅ CASCADE TEST PASSED - All data deleted!';
  END IF;

  IF NOT test_passed THEN
    RAISE EXCEPTION 'CASCADE test failed - check constraints';
  END IF;
END $$;

\echo ''
\echo '=================================================='
\echo '✅ CASCADE DELETE TEST COMPLETED SUCCESSFULLY'
\echo '=================================================='
\echo ''
\echo 'All user data was properly deleted via CASCADE.'
\echo 'Your database constraints are working correctly!'
\echo ''
