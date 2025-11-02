-- =======================
-- CLEANUP ORPHANED DATA
-- Supprime toutes les données qui référencent des utilisateurs supprimés
-- À exécuter APRÈS avoir appliqué la migration cascade
-- =======================

-- ATTENTION : Cette opération est IRRÉVERSIBLE
-- Vérifiez d'abord quelles données seront supprimées avec les requêtes SELECT commentées

-- =======================
-- VÉRIFICATION : Compter les lignes orphelines
-- =======================

-- Décommentez ces requêtes pour voir combien de lignes seront supprimées :

/*
SELECT 'food_entries' as table_name, COUNT(*) as orphaned_rows
FROM food_entries
WHERE user_id NOT IN (SELECT id FROM auth.users)
UNION ALL
SELECT 'custom_foods', COUNT(*)
FROM custom_foods
WHERE user_id NOT IN (SELECT id FROM auth.users)
UNION ALL
SELECT 'recipes', COUNT(*)
FROM recipes
WHERE user_id NOT IN (SELECT id FROM auth.users)
UNION ALL
SELECT 'workout_sessions', COUNT(*)
FROM workout_sessions
WHERE user_id NOT IN (SELECT id FROM auth.users)
UNION ALL
SELECT 'cardio_sessions', COUNT(*)
FROM cardio_sessions
WHERE user_id NOT IN (SELECT id FROM auth.users)
UNION ALL
SELECT 'hiit_sessions', COUNT(*)
FROM hiit_sessions
WHERE user_id NOT IN (SELECT id FROM auth.users)
ORDER BY orphaned_rows DESC;
*/

-- =======================
-- NETTOYAGE : Supprimer les lignes orphelines
-- =======================

-- Food-related tables
DELETE FROM food_entries
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM custom_foods
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM barcode_foods
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM recipes
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM foods
WHERE user_id IS NOT NULL
  AND user_id NOT IN (SELECT id FROM auth.users);

-- Workout-related tables
DELETE FROM workout_sessions
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM workout_templates
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM workout_programs
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM exercises
WHERE user_id IS NOT NULL
  AND user_id NOT IN (SELECT id FROM auth.users);

-- HIIT tables
DELETE FROM hiit_sessions
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM hiit_workouts
WHERE user_id NOT IN (SELECT id FROM auth.users);

-- Cardio tables
DELETE FROM cardio_sessions
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM cardio_activities
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM gps_tracking_sessions
WHERE user_id NOT IN (SELECT id FROM auth.users);

-- Community tables
DELETE FROM community_ratings
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM user_collections
WHERE user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM content_reports
WHERE reported_by NOT IN (SELECT id FROM auth.users);

-- Set reviewed_by to NULL for orphaned reviewers
UPDATE content_reports
SET reviewed_by = NULL
WHERE reviewed_by IS NOT NULL
  AND reviewed_by NOT IN (SELECT id FROM auth.users);

-- System tables
DELETE FROM external_api_logs
WHERE user_id IS NOT NULL
  AND user_id NOT IN (SELECT id FROM auth.users);

-- =======================
-- VÉRIFICATION FINALE : Confirmer le nettoyage
-- =======================

-- Exécutez cette requête après le nettoyage pour vérifier qu'il n'y a plus de données orphelines
SELECT
  'Nettoyage terminé' as status,
  (SELECT COUNT(*) FROM food_entries WHERE user_id NOT IN (SELECT id FROM auth.users)) as food_entries_orphaned,
  (SELECT COUNT(*) FROM custom_foods WHERE user_id NOT IN (SELECT id FROM auth.users)) as custom_foods_orphaned,
  (SELECT COUNT(*) FROM recipes WHERE user_id NOT IN (SELECT id FROM auth.users)) as recipes_orphaned,
  (SELECT COUNT(*) FROM workout_sessions WHERE user_id NOT IN (SELECT id FROM auth.users)) as workout_sessions_orphaned,
  (SELECT COUNT(*) FROM cardio_sessions WHERE user_id NOT IN (SELECT id FROM auth.users)) as cardio_sessions_orphaned;
