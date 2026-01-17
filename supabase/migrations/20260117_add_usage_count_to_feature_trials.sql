-- Migration: Ajouter un compteur d'utilisation pour les features avec plusieurs essais gratuits
-- Utilisé notamment pour le planificateur hebdomadaire (5 essais gratuits)

-- Ajouter la colonne usage_count si elle n'existe pas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_feature_trials'
    AND column_name = 'usage_count'
  ) THEN
    ALTER TABLE user_feature_trials
    ADD COLUMN usage_count INTEGER DEFAULT 0;
  END IF;
END $$;

-- Commentaire pour documentation
COMMENT ON COLUMN user_feature_trials.usage_count IS
  'Compteur d''utilisations pour les features avec plusieurs essais (ex: planificateur = 5 essais)';
