-- Migration: Create user_subscriptions table
-- Description: Table pour gérer les abonnements utilisateurs (Free/Premium)
-- Date: 2025-01-25

CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
  period TEXT CHECK (period IN ('weekly', 'monthly', 'annual', 'lifetime')),
  start_date TIMESTAMPTZ,
  expiry_date TIMESTAMPTZ,
  is_test_mode BOOLEAN DEFAULT false,
  is_trial BOOLEAN DEFAULT false,
  trial_end_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Un seul abonnement actif par utilisateur
  UNIQUE(user_id)
);

-- Index pour recherches rapides
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_tier ON user_subscriptions(tier);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_expiry ON user_subscriptions(expiry_date)
  WHERE expiry_date IS NOT NULL;

-- RLS Policies
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- L'utilisateur peut voir son propre abonnement
CREATE POLICY user_subscriptions_select_own ON user_subscriptions
  FOR SELECT
  USING (auth.uid() = user_id);

-- L'utilisateur peut modifier son propre abonnement
CREATE POLICY user_subscriptions_update_own ON user_subscriptions
  FOR UPDATE
  USING (auth.uid() = user_id);

-- L'utilisateur peut insérer son propre abonnement
CREATE POLICY user_subscriptions_insert_own ON user_subscriptions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION update_user_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_subscriptions_updated_at
  BEFORE UPDATE ON user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_subscriptions_updated_at();

-- Fonction pour vérifier si un abonnement est actif
CREATE OR REPLACE FUNCTION is_subscription_active(subscription_row user_subscriptions)
RETURNS BOOLEAN AS $$
BEGIN
  -- Test mode: toujours actif
  IF subscription_row.is_test_mode THEN
    RETURN TRUE;
  END IF;

  -- Free tier
  IF subscription_row.tier = 'free' THEN
    RETURN FALSE;
  END IF;

  -- Lifetime: toujours actif
  IF subscription_row.period = 'lifetime' THEN
    RETURN TRUE;
  END IF;

  -- Vérifier expiration
  IF subscription_row.expiry_date IS NULL THEN
    RETURN TRUE;
  END IF;

  RETURN subscription_row.expiry_date > now();
END;
$$ LANGUAGE plpgsql;

-- Vue pour faciliter les queries
CREATE OR REPLACE VIEW active_premium_users AS
SELECT
  u.id as user_id,
  u.email,
  s.tier,
  s.period,
  s.start_date,
  s.expiry_date,
  s.is_test_mode,
  s.is_trial,
  is_subscription_active(s.*) as is_active
FROM auth.users u
INNER JOIN user_subscriptions s ON u.id = s.user_id
WHERE s.tier = 'premium'
  AND is_subscription_active(s.*) = TRUE;

COMMENT ON TABLE user_subscriptions IS 'Gestion des abonnements utilisateurs (Free/Premium)';
COMMENT ON COLUMN user_subscriptions.tier IS 'Tier d''abonnement: free ou premium';
COMMENT ON COLUMN user_subscriptions.period IS 'Période de facturation: weekly, monthly, annual, lifetime';
COMMENT ON COLUMN user_subscriptions.is_test_mode IS 'Mode TEST activé (bypass paiement pour dev/test)';
COMMENT ON COLUMN user_subscriptions.is_trial IS 'Utilisateur en période d''essai gratuite';
