-- ═══════════════════════════════════════════════════════════════════════════
-- Gestion des Tutoriels - Ryse App
-- ═══════════════════════════════════════════════════════════════════════════
-- Description : Commandes SQL pour gérer les tutoriels des utilisateurs
-- Usage : Copier/coller dans le SQL Editor de Supabase Dashboard
-- ═══════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════
-- 📊 REQUÊTES DE CONSULTATION (LECTURE SEULE)
-- ══════════════════════════════════════════════════════════════

-- 1️⃣ Afficher le statut des tutoriels pour UN utilisateur spécifique
-- Remplacer 'email@example.com' par l'email de l'utilisateur
SELECT
  id,
  email,
  tutorial_dashboard_completed AS "Dashboard ✅",
  tutorial_nutrition_completed AS "Nutrition ✅",
  tutorial_sport_completed AS "Sport ✅",
  tutorial_cardio_completed AS "Cardio ✅",
  tutorial_musculation_completed AS "Musculation ✅",
  tutorial_progression_completed AS "Progression ✅",
  created_at AS "Créé le"
FROM public.users
WHERE email = 'email@example.com';

-- 2️⃣ Trouver les utilisateurs qui n'ont PAS complété un tutoriel spécifique
SELECT
  email,
  tutorial_dashboard_completed,
  created_at
FROM public.users
WHERE tutorial_dashboard_completed = FALSE
ORDER BY created_at DESC
LIMIT 10;

-- 3️⃣ Statistiques globales des tutoriels
SELECT
  COUNT(*) AS "Total utilisateurs",
  ROUND(100.0 * COUNT(CASE WHEN tutorial_dashboard_completed THEN 1 END) / COUNT(*), 1) AS "% Dashboard",
  ROUND(100.0 * COUNT(CASE WHEN tutorial_nutrition_completed THEN 1 END) / COUNT(*), 1) AS "% Nutrition",
  ROUND(100.0 * COUNT(CASE WHEN tutorial_sport_completed THEN 1 END) / COUNT(*), 1) AS "% Sport",
  ROUND(100.0 * COUNT(CASE WHEN tutorial_cardio_completed THEN 1 END) / COUNT(*), 1) AS "% Cardio",
  ROUND(100.0 * COUNT(CASE WHEN tutorial_musculation_completed THEN 1 END) / COUNT(*), 1) AS "% Musculation",
  ROUND(100.0 * COUNT(CASE WHEN tutorial_progression_completed THEN 1 END) / COUNT(*), 1) AS "% Progression"
FROM public.users;

-- 4️⃣ Utilisateurs avec TOUS les tutoriels complétés (champions 🏆)
SELECT
  email,
  created_at
FROM public.users
WHERE tutorial_dashboard_completed = TRUE
  AND tutorial_nutrition_completed = TRUE
  AND tutorial_sport_completed = TRUE
  AND tutorial_cardio_completed = TRUE
  AND tutorial_musculation_completed = TRUE
  AND tutorial_progression_completed = TRUE
ORDER BY created_at DESC;

-- 5️⃣ Utilisateurs avec AUCUN tutoriel complété (nouveaux utilisateurs potentiels)
SELECT
  email,
  created_at
FROM public.users
WHERE tutorial_dashboard_completed = FALSE
  AND tutorial_nutrition_completed = FALSE
  AND tutorial_sport_completed = FALSE
  AND tutorial_cardio_completed = FALSE
  AND tutorial_musculation_completed = FALSE
  AND tutorial_progression_completed = FALSE
ORDER BY created_at DESC
LIMIT 10;

-- ══════════════════════════════════════════════════════════════
-- 🔧 REQUÊTES DE MODIFICATION (À UTILISER AVEC PRÉCAUTION)
-- ══════════════════════════════════════════════════════════════

-- ⚠️ ATTENTION : Ces requêtes modifient la base de données.
--    Décommenter uniquement si vous savez ce que vous faites.

-- 6️⃣ Réinitialiser TOUS les tutoriels pour UN utilisateur spécifique
-- Utile pour tester ou pour un utilisateur qui veut revoir les tutoriels
/*
UPDATE public.users
SET
  tutorial_dashboard_completed = FALSE,
  tutorial_nutrition_completed = FALSE,
  tutorial_sport_completed = FALSE,
  tutorial_cardio_completed = FALSE,
  tutorial_musculation_completed = FALSE,
  tutorial_progression_completed = FALSE
WHERE email = 'email@example.com';

SELECT 'Tutoriels réinitialisés pour ' || email AS "Résultat"
FROM public.users
WHERE email = 'email@example.com';
*/

-- 7️⃣ Réinitialiser UN SEUL tutoriel pour un utilisateur
-- Exemple : Réinitialiser le tutoriel du dashboard
/*
UPDATE public.users
SET tutorial_dashboard_completed = FALSE
WHERE email = 'email@example.com';

SELECT 'Tutorial Dashboard réinitialisé pour ' || email AS "Résultat"
FROM public.users
WHERE email = 'email@example.com';
*/

-- 8️⃣ Marquer TOUS les tutoriels comme complétés pour UN utilisateur
-- Utile pour un utilisateur avancé qui ne veut plus voir les tutoriels
/*
UPDATE public.users
SET
  tutorial_dashboard_completed = TRUE,
  tutorial_nutrition_completed = TRUE,
  tutorial_sport_completed = TRUE,
  tutorial_cardio_completed = TRUE,
  tutorial_musculation_completed = TRUE,
  tutorial_progression_completed = TRUE
WHERE email = 'email@example.com';

SELECT 'Tous les tutoriels marqués comme complétés pour ' || email AS "Résultat"
FROM public.users
WHERE email = 'email@example.com';
*/

-- 9️⃣ Marquer les tutoriels comme complétés pour TOUS les utilisateurs créés AVANT une date
-- Utile lors du déploiement initial pour ne pas ennuyer les utilisateurs existants
-- ⚠️ ACTION IRRÉVERSIBLE SUR PLUSIEURS UTILISATEURS
/*
UPDATE public.users
SET
  tutorial_dashboard_completed = TRUE,
  tutorial_nutrition_completed = TRUE,
  tutorial_sport_completed = TRUE,
  tutorial_cardio_completed = TRUE,
  tutorial_musculation_completed = TRUE,
  tutorial_progression_completed = TRUE
WHERE created_at < '2025-01-30 00:00:00'::timestamp;

SELECT COUNT(*) || ' utilisateurs mis à jour' AS "Résultat"
FROM public.users
WHERE created_at < '2025-01-30 00:00:00'::timestamp;
*/

-- 🔟 Réinitialiser TOUS les tutoriels pour TOUS les utilisateurs
-- ⚠️ DANGER : ACTION IRRÉVERSIBLE SUR TOUTE LA BASE
-- Ne décommenter que pour un environnement de TEST
/*
UPDATE public.users
SET
  tutorial_dashboard_completed = FALSE,
  tutorial_nutrition_completed = FALSE,
  tutorial_sport_completed = FALSE,
  tutorial_cardio_completed = FALSE,
  tutorial_musculation_completed = FALSE,
  tutorial_progression_completed = FALSE;

SELECT COUNT(*) || ' utilisateurs réinitialisés' AS "Résultat" FROM public.users;
*/

-- ══════════════════════════════════════════════════════════════
-- 🏗️ REQUÊTES DE MAINTENANCE
-- ══════════════════════════════════════════════════════════════

-- 1️⃣1️⃣ Vérifier que toutes les colonnes tutorial_* existent
SELECT
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND column_name LIKE 'tutorial_%'
ORDER BY column_name;

-- Si cette requête retourne 0 lignes, la migration n'est pas appliquée
-- Exécuter : supabase db push

-- 1️⃣2️⃣ Vérifier les index (performance)
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'users'
  AND indexname LIKE '%tutorial%';

-- 1️⃣3️⃣ Taille de la table users
SELECT
  pg_size_pretty(pg_total_relation_size('public.users')) AS "Taille totale"
FROM pg_class
WHERE relname = 'users';

-- ══════════════════════════════════════════════════════════════
-- 📈 REQUÊTES D'ANALYSE AVANCÉE
-- ══════════════════════════════════════════════════════════════

-- 1️⃣4️⃣ Taux de complétion par tutoriel (pour analytics)
SELECT
  'Dashboard' AS "Tutoriel",
  COUNT(CASE WHEN tutorial_dashboard_completed THEN 1 END) AS "Complétés",
  COUNT(*) AS "Total",
  ROUND(100.0 * COUNT(CASE WHEN tutorial_dashboard_completed THEN 1 END) / COUNT(*), 1) AS "Taux %"
FROM public.users
UNION ALL
SELECT
  'Nutrition',
  COUNT(CASE WHEN tutorial_nutrition_completed THEN 1 END),
  COUNT(*),
  ROUND(100.0 * COUNT(CASE WHEN tutorial_nutrition_completed THEN 1 END) / COUNT(*), 1)
FROM public.users
UNION ALL
SELECT
  'Sport',
  COUNT(CASE WHEN tutorial_sport_completed THEN 1 END),
  COUNT(*),
  ROUND(100.0 * COUNT(CASE WHEN tutorial_sport_completed THEN 1 END) / COUNT(*), 1)
FROM public.users
UNION ALL
SELECT
  'Cardio',
  COUNT(CASE WHEN tutorial_cardio_completed THEN 1 END),
  COUNT(*),
  ROUND(100.0 * COUNT(CASE WHEN tutorial_cardio_completed THEN 1 END) / COUNT(*), 1)
FROM public.users
UNION ALL
SELECT
  'Musculation',
  COUNT(CASE WHEN tutorial_musculation_completed THEN 1 END),
  COUNT(*),
  ROUND(100.0 * COUNT(CASE WHEN tutorial_musculation_completed THEN 1 END) / COUNT(*), 1)
FROM public.users
UNION ALL
SELECT
  'Progression',
  COUNT(CASE WHEN tutorial_progression_completed THEN 1 END),
  COUNT(*),
  ROUND(100.0 * COUNT(CASE WHEN tutorial_progression_completed THEN 1 END) / COUNT(*), 1)
FROM public.users
ORDER BY "Taux %" DESC;

-- 1️⃣5️⃣ Funnel d'adoption des tutoriels (quel tutoriel est le plus abandonné ?)
SELECT
  SUM(CASE WHEN tutorial_dashboard_completed THEN 1 ELSE 0 END) AS "1️⃣ Dashboard",
  SUM(CASE WHEN tutorial_nutrition_completed THEN 1 ELSE 0 END) AS "2️⃣ Nutrition",
  SUM(CASE WHEN tutorial_sport_completed THEN 1 ELSE 0 END) AS "3️⃣ Sport",
  SUM(CASE WHEN tutorial_cardio_completed THEN 1 ELSE 0 END) AS "4️⃣ Cardio",
  SUM(CASE WHEN tutorial_musculation_completed THEN 1 ELSE 0 END) AS "5️⃣ Musculation",
  SUM(CASE WHEN tutorial_progression_completed THEN 1 ELSE 0 END) AS "6️⃣ Progression"
FROM public.users;

-- 1️⃣6️⃣ Complétion moyenne par cohorte (par mois de création du compte)
SELECT
  TO_CHAR(created_at, 'YYYY-MM') AS "Mois",
  COUNT(*) AS "Utilisateurs",
  ROUND(AVG(CASE WHEN tutorial_dashboard_completed THEN 100 ELSE 0 END), 1) AS "% Dashboard",
  ROUND(AVG(CASE WHEN tutorial_nutrition_completed THEN 100 ELSE 0 END), 1) AS "% Nutrition",
  ROUND(AVG(CASE WHEN tutorial_sport_completed THEN 100 ELSE 0 END), 1) AS "% Sport"
FROM public.users
GROUP BY TO_CHAR(created_at, 'YYYY-MM')
ORDER BY "Mois" DESC
LIMIT 6;

-- ══════════════════════════════════════════════════════════════
-- 🔍 REQUÊTES DE DEBUG
-- ══════════════════════════════════════════════════════════════

-- 1️⃣7️⃣ Trouver un utilisateur qui a un comportement bizarre
-- (ex: Cardio complété mais pas Dashboard)
SELECT
  email,
  tutorial_dashboard_completed AS "Dashboard",
  tutorial_nutrition_completed AS "Nutrition",
  tutorial_sport_completed AS "Sport",
  tutorial_cardio_completed AS "Cardio",
  tutorial_musculation_completed AS "Musculation",
  tutorial_progression_completed AS "Progression"
FROM public.users
WHERE (
  -- Cardio complété mais pas Dashboard (anormal)
  tutorial_cardio_completed = TRUE AND tutorial_dashboard_completed = FALSE
) OR (
  -- Musculation complétée mais pas Sport (anormal)
  tutorial_musculation_completed = TRUE AND tutorial_sport_completed = FALSE
)
LIMIT 10;

-- 1️⃣8️⃣ Compter les utilisateurs avec des patterns spécifiques
SELECT
  CASE
    WHEN tutorial_dashboard_completed AND NOT tutorial_nutrition_completed THEN 'Dashboard uniquement'
    WHEN tutorial_dashboard_completed AND tutorial_nutrition_completed AND NOT tutorial_sport_completed THEN 'Dashboard + Nutrition'
    WHEN NOT tutorial_dashboard_completed AND NOT tutorial_nutrition_completed THEN 'Aucun tutoriel'
    ELSE 'Autre pattern'
  END AS "Pattern",
  COUNT(*) AS "Nombre d'utilisateurs"
FROM public.users
GROUP BY "Pattern"
ORDER BY "Nombre d'utilisateurs" DESC;

-- ══════════════════════════════════════════════════════════════
-- 💡 NOTES D'UTILISATION
-- ══════════════════════════════════════════════════════════════

/*
📌 GUIDE RAPIDE :

1. Pour CONSULTER l'état d'un utilisateur :
   → Requête #1 (remplacer l'email)

2. Pour RÉINITIALISER un utilisateur (test) :
   → Requête #6 (décommenter et remplacer l'email)

3. Pour les STATISTIQUES globales :
   → Requête #3 ou #14

4. Pour le DÉPLOIEMENT INITIAL (utilisateurs existants) :
   → Requête #9 (décommenter et ajuster la date)

5. Pour VÉRIFIER que la migration est appliquée :
   → Requête #11 (doit retourner 6 colonnes)

⚠️ SÉCURITÉ :
- Toutes les requêtes de MODIFICATION sont commentées par défaut
- Ne décommenter que si vous êtes sûr de l'action à effectuer
- Tester sur un environnement de staging avant la production

📚 DOCUMENTATION :
- TUTORIAL_STATUS_VERIFICATION.md : Analyse technique
- TUTORIAL_TEST_GUIDE.md : Guide de test complet
- tutorial_service.dart : Code source
*/
