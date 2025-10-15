-- Check current muscle group values before update
-- This helps identify which groups need translation

-- 1. Show all unique combinations of muscle_group_en and muscle_group_fr
SELECT DISTINCT
  muscle_group_en,
  muscle_group_fr,
  COUNT(*) as exercise_count
FROM exercises
GROUP BY muscle_group_en, muscle_group_fr
ORDER BY muscle_group_en, muscle_group_fr;

-- 2. Find exercises where muscle_group_fr = 'Personnalisé' but muscle_group_en is not 'Custom'
SELECT
  id,
  name_en,
  name_fr,
  muscle_group_en,
  muscle_group_fr
FROM exercises
WHERE muscle_group_fr = 'Personnalisé'
  AND muscle_group_en != 'Custom'
  AND muscle_group_en IS NOT NULL
LIMIT 20;

-- 3. Count total exercises that need fixing
SELECT COUNT(*) as needs_translation
FROM exercises
WHERE muscle_group_fr = 'Personnalisé'
  AND muscle_group_en != 'Custom'
  AND muscle_group_en IS NOT NULL;

-- 4. Show all unique muscle_group_en values
SELECT DISTINCT muscle_group_en, COUNT(*) as count
FROM exercises
WHERE muscle_group_en IS NOT NULL
GROUP BY muscle_group_en
ORDER BY muscle_group_en;
