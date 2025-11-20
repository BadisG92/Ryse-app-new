#!/bin/bash
# Script de débogage pour vérifier les colonnes tutorial dans Supabase

echo "🔍 Vérification des colonnes tutorial dans la table users..."
echo ""

# Charger les variables d'environnement
if [ -f ~/.claude-code-supabase.env ]; then
  source ~/.claude-code-supabase.env
  echo "✅ Variables d'environnement chargées"
else
  echo "❌ Fichier ~/.claude-code-supabase.env introuvable"
  exit 1
fi

# Vérifier si SUPABASE_DB_URL est défini
if [ -z "$SUPABASE_DB_URL" ]; then
  echo "❌ SUPABASE_DB_URL non défini"
  exit 1
fi

echo "📡 Connexion à Supabase..."
echo ""

# 1. Vérifier l'existence des colonnes tutorial
echo "📋 1. Liste des colonnes tutorial_ dans la table users:"
/opt/homebrew/bin/psql "$SUPABASE_DB_URL" -c "
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
"

echo ""
echo "📊 2. Valeurs des colonnes tutorial pour les 3 derniers utilisateurs:"
/opt/homebrew/bin/psql "$SUPABASE_DB_URL" -c "
SELECT
  id,
  email,
  tutorial_dashboard_completed,
  tutorial_nutrition_completed,
  tutorial_sport_completed,
  tutorial_cardio_completed,
  tutorial_musculation_completed,
  tutorial_progression_completed,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 3;
"

echo ""
echo "📈 3. Statistiques des tutoriels complétés:"
/opt/homebrew/bin/psql "$SUPABASE_DB_URL" -c "
SELECT
  COUNT(*) as total_users,
  COUNT(CASE WHEN tutorial_dashboard_completed = true THEN 1 END) as dashboard_completed,
  COUNT(CASE WHEN tutorial_nutrition_completed = true THEN 1 END) as nutrition_completed,
  COUNT(CASE WHEN tutorial_sport_completed = true THEN 1 END) as sport_completed,
  COUNT(CASE WHEN tutorial_cardio_completed = true THEN 1 END) as cardio_completed,
  COUNT(CASE WHEN tutorial_musculation_completed = true THEN 1 END) as musculation_completed,
  COUNT(CASE WHEN tutorial_progression_completed = true THEN 1 END) as progression_completed
FROM users;
"

echo ""
echo "✅ Vérification terminée"
