-- ============================================
-- CRON Job pour la génération des notifications IA
-- Exécute l'Edge Function chaque dimanche à 22h UTC
-- ============================================

-- Note: Ce CRON doit être configuré manuellement dans le dashboard Supabase
-- car pg_cron nécessite une configuration spécifique par projet.

-- Instructions de configuration manuelle :
-- 1. Aller dans le Dashboard Supabase > Database > Extensions
-- 2. Activer l'extension pg_cron si pas déjà fait
-- 3. Aller dans SQL Editor et exécuter :

/*
-- Planifier la génération chaque dimanche 22h UTC
SELECT cron.schedule(
  'generate-ai-notifications',
  '0 22 * * 0', -- Dimanche 22h UTC
  $$
  SELECT net.http_post(
    url := 'https://[YOUR_PROJECT_REF].supabase.co/functions/v1/generate-ai-notifications',
    headers := jsonb_build_object(
      'Authorization', 'Bearer [YOUR_SERVICE_ROLE_KEY]',
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- Pour vérifier les jobs planifiés :
SELECT * FROM cron.job;

-- Pour voir l'historique d'exécution :
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;

-- Pour supprimer le job si nécessaire :
SELECT cron.unschedule('generate-ai-notifications');
*/

-- ============================================
-- Alternative : Utiliser un service externe (Vercel Cron, GitHub Actions, etc.)
-- ============================================

-- Si pg_cron n'est pas disponible, vous pouvez utiliser :
--
-- 1. Vercel Cron Jobs (vercel.json) :
-- {
--   "crons": [{
--     "path": "/api/generate-ai-notifications",
--     "schedule": "0 22 * * 0"
--   }]
-- }
--
-- 2. GitHub Actions (.github/workflows/ai-notifications.yml) :
-- name: Generate AI Notifications
-- on:
--   schedule:
--     - cron: '0 22 * * 0'
-- jobs:
--   generate:
--     runs-on: ubuntu-latest
--     steps:
--       - name: Call Edge Function
--         run: |
--           curl -X POST \
--             -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}" \
--             https://[PROJECT_REF].supabase.co/functions/v1/generate-ai-notifications

-- ============================================
-- Fonction de nettoyage des notifications expirées
-- ============================================

-- Fonction pour nettoyer les notifications expirées et utilisées
CREATE OR REPLACE FUNCTION cleanup_ai_notifications()
RETURNS void AS $$
BEGIN
  -- Supprimer les notifications expirées (non utilisées mais périmées)
  DELETE FROM ai_notifications_pool
  WHERE expires_at < NOW() AND used = false;

  -- Supprimer les notifications utilisées il y a plus de 30 jours
  DELETE FROM ai_notifications_pool
  WHERE used = true AND used_at < NOW() - INTERVAL '30 days';

  RAISE NOTICE 'AI notifications cleanup completed';
END;
$$ LANGUAGE plpgsql;

-- Commentaire sur la fonction
COMMENT ON FUNCTION cleanup_ai_notifications() IS 'Nettoie les notifications IA expirées et les anciennes notifications utilisées';

-- Note: Pour planifier le nettoyage automatique avec pg_cron :
/*
SELECT cron.schedule(
  'cleanup-ai-notifications',
  '0 3 * * *', -- Chaque jour à 3h UTC
  'SELECT cleanup_ai_notifications()'
);
*/
