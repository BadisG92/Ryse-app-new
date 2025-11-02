-- Migration pour ajouter les colonnes de tutoriels dans Supabase
-- UNE COLONNE PAR PAGE avec tutoriel interactif
-- Permet de persister l'état des tutoriels entre les sessions

ALTER TABLE public.users
  -- Page d'accueil (dashboard principal)
  ADD COLUMN IF NOT EXISTS tutorial_dashboard_completed BOOLEAN DEFAULT FALSE,

  -- Page nutrition
  ADD COLUMN IF NOT EXISTS tutorial_nutrition_completed BOOLEAN DEFAULT FALSE,

  -- Page sport (section principale)
  ADD COLUMN IF NOT EXISTS tutorial_sport_completed BOOLEAN DEFAULT FALSE,

  -- Onglet cardio de la page sport
  ADD COLUMN IF NOT EXISTS tutorial_cardio_completed BOOLEAN DEFAULT FALSE,

  -- Onglet musculation de la page sport
  ADD COLUMN IF NOT EXISTS tutorial_musculation_completed BOOLEAN DEFAULT FALSE,

  -- Page progression
  ADD COLUMN IF NOT EXISTS tutorial_progression_completed BOOLEAN DEFAULT FALSE;

-- Commentaires pour documentation
COMMENT ON COLUMN public.users.tutorial_dashboard_completed IS 'Tutoriel de la page d''accueil';
COMMENT ON COLUMN public.users.tutorial_nutrition_completed IS 'Tutoriel de la page nutrition';
COMMENT ON COLUMN public.users.tutorial_sport_completed IS 'Tutoriel de la page sport';
COMMENT ON COLUMN public.users.tutorial_cardio_completed IS 'Tutoriel de l''onglet cardio (page sport)';
COMMENT ON COLUMN public.users.tutorial_musculation_completed IS 'Tutoriel de l''onglet musculation (page sport)';
COMMENT ON COLUMN public.users.tutorial_progression_completed IS 'Tutoriel de la page progression';

-- Optionnel : Marquer tous les tutoriels comme vus pour les utilisateurs existants
-- (décommenter si vous ne voulez pas que vos utilisateurs existants voient les tutoriels)
/*
UPDATE public.users
SET
  tutorial_dashboard_completed = TRUE,
  tutorial_nutrition_completed = TRUE,
  tutorial_sport_completed = TRUE,
  tutorial_cardio_completed = TRUE,
  tutorial_musculation_completed = TRUE,
  tutorial_progression_completed = TRUE
WHERE created_at < NOW();
*/
