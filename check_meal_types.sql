-- Vérifier les types de repas dans la base
SELECT DISTINCT meal_type, COUNT(*) as count
FROM food_entries  
WHERE consumed_at >= CURRENT_DATE
GROUP BY meal_type
ORDER BY meal_type;
