-- ═══════════════════════════════════════════════════════════════════════════
-- Script de Vérification du Système de Tutoriel
-- ═══════════════════════════════════════════════════════════════════════════
-- Description : Vérifie que les colonnes tutorial_* existent et affiche
--               le statut des tutoriels pour les utilisateurs
-- Usage : Exécuter dans le SQL Editor de Supabase Dashboard
-- ═══════════════════════════════════════════════════════════════════════════

\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '📋 VÉRIFICATION 1 : Colonnes tutorial_* dans la table users'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- Vérifier que les colonnes existent
SELECT
  column_name AS "Colonne",
  data_type AS "Type",
  column_default AS "Valeur par défaut",
  is_nullable AS "Nullable"
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND column_name LIKE 'tutorial_%'
ORDER BY column_name;

\echo ''
\echo '✅ Si 6 colonnes sont affichées, la migration est appliquée correctement'
\echo '❌ Si 0 colonnes, vous devez appliquer la migration : supabase db push'
\echo ''

\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '📊 VÉRIFICATION 2 : Statistiques des tutoriels'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- Statistiques globales
SELECT
  COUNT(*) AS "Total utilisateurs",
  COUNT(CASE WHEN tutorial_dashboard_completed = TRUE THEN 1 END) AS "Dashboard complété",
  COUNT(CASE WHEN tutorial_nutrition_completed = TRUE THEN 1 END) AS "Nutrition complété",
  COUNT(CASE WHEN tutorial_sport_completed = TRUE THEN 1 END) AS "Sport complété",
  COUNT(CASE WHEN tutorial_cardio_completed = TRUE THEN 1 END) AS "Cardio complété",
  COUNT(CASE WHEN tutorial_musculation_completed = TRUE THEN 1 END) AS "Musculation complété",
  COUNT(CASE WHEN tutorial_progression_completed = TRUE THEN 1 END) AS "Progression complété"
FROM public.users;

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '👤 VÉRIFICATION 3 : Détails des 10 derniers utilisateurs'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- Détail des derniers utilisateurs
SELECT
  LEFT(id::text, 8) || '...' AS "ID",
  email,
  CASE WHEN tutorial_dashboard_completed THEN '✅' ELSE '❌' END AS "Dashboard",
  CASE WHEN tutorial_nutrition_completed THEN '✅' ELSE '❌' END AS "Nutrition",
  CASE WHEN tutorial_sport_completed THEN '✅' ELSE '❌' END AS "Sport",
  CASE WHEN tutorial_cardio_completed THEN '✅' ELSE '❌' END AS "Cardio",
  CASE WHEN tutorial_musculation_completed THEN '✅' ELSE '❌' END AS "Musculation",
  CASE WHEN tutorial_progression_completed THEN '✅' ELSE '❌' END AS "Progression",
  TO_CHAR(created_at, 'YYYY-MM-DD') AS "Créé le"
FROM public.users
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '🔍 VÉRIFICATION 4 : Utilisateurs avec tutoriels incomplets'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- Utilisateurs avec au moins un tutoriel non complété
SELECT
  LEFT(id::text, 8) || '...' AS "ID",
  email,
  CASE WHEN NOT tutorial_dashboard_completed THEN '⏳ Dashboard' ELSE NULL END AS "Manquant 1",
  CASE WHEN NOT tutorial_nutrition_completed THEN '⏳ Nutrition' ELSE NULL END AS "Manquant 2",
  CASE WHEN NOT tutorial_sport_completed THEN '⏳ Sport' ELSE NULL END AS "Manquant 3",
  CASE WHEN NOT tutorial_cardio_completed THEN '⏳ Cardio' ELSE NULL END AS "Manquant 4",
  CASE WHEN NOT tutorial_musculation_completed THEN '⏳ Musculation' ELSE NULL END AS "Manquant 5",
  CASE WHEN NOT tutorial_progression_completed THEN '⏳ Progression' ELSE NULL END AS "Manquant 6"
FROM public.users
WHERE NOT (
  tutorial_dashboard_completed AND
  tutorial_nutrition_completed AND
  tutorial_sport_completed AND
  tutorial_cardio_completed AND
  tutorial_musculation_completed AND
  tutorial_progression_completed
)
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '⚙️  VÉRIFICATION 5 : Utilisateurs créés AVANT la migration'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- Utilisateurs existants AVANT l'ajout des tutoriels
-- (utile pour décider s'il faut les marquer comme complétés)
SELECT
  COUNT(*) AS "Utilisateurs créés avant 2025-01-30",
  COUNT(CASE WHEN tutorial_dashboard_completed = TRUE THEN 1 END) AS "Avec tutoriels marqués complétés"
FROM public.users
WHERE created_at < '2025-01-30'::timestamp;

\echo ''
\echo '💡 Si le nombre "Utilisateurs créés avant 2025-01-30" est > 0'
\echo '   et "Avec tutoriels marqués complétés" est < ce nombre,'
\echo '   vous devriez décider si les marquer comme complétés'
\echo ''

\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '✅ Vérification terminée'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- ═══════════════════════════════════════════════════════════════════════════
-- ACTIONS OPTIONNELLES (décommenter si nécessaire)
-- ═══════════════════════════════════════════════════════════════════════════

-- ❌ OPTION A : Marquer TOUS les tutoriels comme vus pour les ANCIENS utilisateurs
--              (pour qu'ils ne voient pas le tutoriel)
/*
UPDATE public.users
SET
  tutorial_dashboard_completed = TRUE,
  tutorial_nutrition_completed = TRUE,
  tutorial_sport_completed = TRUE,
  tutorial_cardio_completed = TRUE,
  tutorial_musculation_completed = TRUE,
  tutorial_progression_completed = TRUE
WHERE created_at < '2025-01-30'::timestamp;

SELECT 'ℹ️  Tutoriels marqués comme complétés pour les utilisateurs existants' AS "Résultat";
*/

-- ❌ OPTION B : Réinitialiser TOUS les tutoriels pour UN utilisateur spécifique
--              (pour tester)
/*
UPDATE public.users
SET
  tutorial_dashboard_completed = FALSE,
  tutorial_nutrition_completed = FALSE,
  tutorial_sport_completed = FALSE,
  tutorial_cardio_completed = FALSE,
  tutorial_musculation_completed = FALSE,
  tutorial_progression_completed = FALSE
WHERE email = 'votre.email@example.com';

SELECT 'ℹ️  Tutoriels réinitialisés pour cet utilisateur' AS "Résultat";
*/

-- ❌ OPTION C : Réinitialiser TOUS les tutoriels pour TOUS les utilisateurs
--              (ATTENTION : Action irréversible !)
/*
UPDATE public.users
SET
  tutorial_dashboard_completed = FALSE,
  tutorial_nutrition_completed = FALSE,
  tutorial_sport_completed = FALSE,
  tutorial_cardio_completed = FALSE,
  tutorial_musculation_completed = FALSE,
  tutorial_progression_completed = FALSE;

SELECT 'ℹ️  TOUS les tutoriels ont été réinitialisés' AS "Résultat";
*/
