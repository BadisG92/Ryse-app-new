-- Migration pour ajouter les colonnes de streak dans la table users
-- Date: 2024-12-18
-- Description: Ajouter streak_count et streak_last_date pour optimiser le calcul de streak

-- Ajouter les colonnes de streak
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS streak_last_date DATE DEFAULT NULL;

-- Index pour optimiser les requêtes sur streak_last_date
CREATE INDEX IF NOT EXISTS idx_users_streak_last_date ON users(streak_last_date);

-- Commentaires pour documenter les colonnes
COMMENT ON COLUMN users.streak_count IS 'Nombre de jours consécutifs d''activité (avec tolérance)';
COMMENT ON COLUMN users.streak_last_date IS 'Date du dernier jour d''activité comptabilisé dans la streak';
