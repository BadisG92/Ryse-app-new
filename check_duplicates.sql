-- Vérifier les doublons de name_en dans la table exercises
SELECT
  name_en,
  COUNT(*) as count,
  STRING_AGG(id::text, ', ') as exercise_ids
FROM exercises
GROUP BY name_en
HAVING COUNT(*) > 1
ORDER BY count DESC, name_en;

-- Vérifier aussi les doublons de name_fr
SELECT
  name_fr,
  COUNT(*) as count,
  STRING_AGG(id::text, ', ') as exercise_ids
FROM exercises
GROUP BY name_fr
HAVING COUNT(*) > 1
ORDER BY count DESC, name_fr;

-- Voir le total d'exercices
SELECT COUNT(*) as total_exercises FROM exercises;
