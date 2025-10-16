-- Migration: Créer la table nutrition_analyses pour Coach Ryze Nutrition
-- Date: 2025-10-15

BEGIN;

-- Créer la table nutrition_analyses
CREATE TABLE IF NOT EXISTS nutrition_analyses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  context VARCHAR(50) NOT NULL CHECK (context IN ('empty_day', 'in_progress', 'post_workout', 'end_of_day')),
  analysis_text TEXT NOT NULL,
  score NUMERIC(5,2) CHECK (score >= 0 AND score <= 100),
  insights TEXT[] DEFAULT '{}',
  recommendations TEXT[] DEFAULT '{}',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_nutrition_analyses_user_id ON nutrition_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_analyses_date ON nutrition_analyses(date);
CREATE INDEX IF NOT EXISTS idx_nutrition_analyses_user_date ON nutrition_analyses(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_nutrition_analyses_context ON nutrition_analyses(context);

-- Index pour le JSONB metadata
CREATE INDEX IF NOT EXISTS idx_nutrition_analyses_metadata ON nutrition_analyses USING GIN (metadata);

-- Fonction de mise à jour automatique du timestamp
CREATE OR REPLACE FUNCTION update_nutrition_analyses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour updated_at
DROP TRIGGER IF EXISTS trigger_update_nutrition_analyses_updated_at ON nutrition_analyses;
CREATE TRIGGER trigger_update_nutrition_analyses_updated_at
  BEFORE UPDATE ON nutrition_analyses
  FOR EACH ROW
  EXECUTE FUNCTION update_nutrition_analyses_updated_at();

-- Politique RLS (Row Level Security)
ALTER TABLE nutrition_analyses ENABLE ROW LEVEL SECURITY;

-- Politique : Les utilisateurs peuvent lire leurs propres analyses
DROP POLICY IF EXISTS "Users can read their own analyses" ON nutrition_analyses;
CREATE POLICY "Users can read their own analyses"
  ON nutrition_analyses
  FOR SELECT
  USING (auth.uid() = user_id);

-- Politique : Les utilisateurs peuvent insérer leurs propres analyses
DROP POLICY IF EXISTS "Users can insert their own analyses" ON nutrition_analyses;
CREATE POLICY "Users can insert their own analyses"
  ON nutrition_analyses
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Politique : Les utilisateurs peuvent mettre à jour leurs propres analyses
DROP POLICY IF EXISTS "Users can update their own analyses" ON nutrition_analyses;
CREATE POLICY "Users can update their own analyses"
  ON nutrition_analyses
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Politique : Les utilisateurs peuvent supprimer leurs propres analyses
DROP POLICY IF EXISTS "Users can delete their own analyses" ON nutrition_analyses;
CREATE POLICY "Users can delete their own analyses"
  ON nutrition_analyses
  FOR DELETE
  USING (auth.uid() = user_id);

COMMIT;

-- Vérification
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'nutrition_analyses'
ORDER BY ordinal_position;

-- Afficher les index
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'nutrition_analyses';

-- Afficher les politiques RLS
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'nutrition_analyses';
