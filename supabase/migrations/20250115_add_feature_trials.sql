-- Migration: Système d'essais gratuits par feature Premium
-- Permet de tracker si l'utilisateur a utilisé son essai gratuit (1 fois par feature)

-- Table pour tracker les essais gratuits
CREATE TABLE IF NOT EXISTS user_feature_trials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  used_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Contrainte unique : 1 seul enregistrement par user + feature
  CONSTRAINT unique_user_feature UNIQUE(user_id, feature_key)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_user_feature_trials_user_id
  ON user_feature_trials(user_id);

CREATE INDEX IF NOT EXISTS idx_user_feature_trials_feature_key
  ON user_feature_trials(feature_key);

CREATE INDEX IF NOT EXISTS idx_user_feature_trials_user_feature
  ON user_feature_trials(user_id, feature_key);

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_user_feature_trials_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour updated_at
DROP TRIGGER IF EXISTS trigger_update_user_feature_trials_updated_at ON user_feature_trials;
CREATE TRIGGER trigger_update_user_feature_trials_updated_at
  BEFORE UPDATE ON user_feature_trials
  FOR EACH ROW
  EXECUTE FUNCTION update_user_feature_trials_updated_at();

-- RLS (Row Level Security)
ALTER TABLE user_feature_trials ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres trials
DROP POLICY IF EXISTS "Users can view their own trials" ON user_feature_trials;
CREATE POLICY "Users can view their own trials"
  ON user_feature_trials FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent insérer leurs propres trials
DROP POLICY IF EXISTS "Users can insert their own trials" ON user_feature_trials;
CREATE POLICY "Users can insert their own trials"
  ON user_feature_trials FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent mettre à jour leurs propres trials
DROP POLICY IF EXISTS "Users can update their own trials" ON user_feature_trials;
CREATE POLICY "Users can update their own trials"
  ON user_feature_trials FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent supprimer leurs propres trials (pour testing/support)
DROP POLICY IF EXISTS "Users can delete their own trials" ON user_feature_trials;
CREATE POLICY "Users can delete their own trials"
  ON user_feature_trials FOR DELETE
  USING (auth.uid() = user_id);

-- Commentaires pour documentation
COMMENT ON TABLE user_feature_trials IS
  'Stocke les essais gratuits des features Premium (1 essai par feature par utilisateur)';

COMMENT ON COLUMN user_feature_trials.feature_key IS
  'Clé de la feature (ex: feature_scanner_used, feature_barcode_used, etc.)';

COMMENT ON COLUMN user_feature_trials.used IS
  'Indique si l''utilisateur a utilisé son essai gratuit pour cette feature';

COMMENT ON COLUMN user_feature_trials.used_at IS
  'Date/heure à laquelle l''essai gratuit a été utilisé';
