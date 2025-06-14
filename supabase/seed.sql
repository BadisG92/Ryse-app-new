-- =======================
-- RYZE APP - SEED DATA
-- Populating initial data for exercises, HIIT workouts, and foods
-- =======================

-- =======================
-- PREDEFINED EXERCISES
-- =======================

INSERT INTO exercises (name, muscle_group, equipment, description, is_custom) VALUES
-- Pectoraux
('Développé couché', 'Pectoraux', 'Barre', 'Exercice de base pour développer les pectoraux', false),
('Développé incliné', 'Pectoraux', 'Haltères', 'Développé sur banc incliné avec haltères', false),
('Pompes', 'Pectoraux', 'Poids du corps', 'Pompes classiques au sol', false),
('Écarté couché', 'Pectoraux', 'Haltères', 'Écartés avec haltères sur banc plat', false),

-- Dos
('Tractions', 'Dos', 'Barre de traction', 'Tractions en pronation', false),
('Rowing barre', 'Dos', 'Barre', 'Rowing penché avec barre', false),
('Tirage horizontal', 'Dos', 'Poulie', 'Tirage horizontal à la poulie', false),
('Soulevé de terre', 'Dos', 'Barre', 'Soulevé de terre classique', false),

-- Épaules
('Développé militaire', 'Épaules', 'Barre', 'Développé militaire debout', false),
('Élévations latérales', 'Épaules', 'Haltères', 'Élévations latérales avec haltères', false),
('Développé Arnold', 'Épaules', 'Haltères', 'Développé Arnold avec rotation', false),
('Oiseau', 'Épaules', 'Haltères', 'Oiseau pour deltoïdes postérieurs', false),

-- Biceps
('Curl biceps barre', 'Biceps', 'Barre', 'Curl biceps avec barre droite', false),
('Curl haltères', 'Biceps', 'Haltères', 'Curl alterné avec haltères', false),
('Curl marteau', 'Biceps', 'Haltères', 'Curl marteau avec haltères', false),
('Curl pupitre', 'Biceps', 'Haltères', 'Curl sur banc pupitre', false),

-- Triceps
('Dips', 'Triceps', 'Barres parallèles', 'Dips aux barres parallèles', false),
('Extension triceps', 'Triceps', 'Haltères', 'Extension triceps couché', false),
('Pompes diamant', 'Triceps', 'Poids du corps', 'Pompes avec mains en diamant', false),
('Extension poulie haute', 'Triceps', 'Poulie', 'Extension triceps à la poulie haute', false),

-- Jambes
('Squat', 'Jambes', 'Barre', 'Squat avec barre', false),
('Presse à cuisses', 'Jambes', 'Machine', 'Presse à cuisses à 45°', false),
('Fentes', 'Jambes', 'Haltères', 'Fentes avant avec haltères', false),
('Leg curl', 'Jambes', 'Machine', 'Leg curl pour ischio-jambiers', false),

-- Fessiers
('Hip thrust', 'Fessiers', 'Barre', 'Hip thrust avec barre', false),
('Squats sumo', 'Fessiers', 'Haltères', 'Squats sumo avec haltère', false),
('Fentes latérales', 'Fessiers', 'Haltères', 'Fentes latérales avec haltères', false),
('Pont fessier', 'Fessiers', 'Poids du corps', 'Pont fessier au sol', false),

-- Abdominaux
('Crunch', 'Abdominaux', 'Poids du corps', 'Crunch classique au sol', false),
('Planche', 'Abdominaux', 'Poids du corps', 'Planche statique', false),
('Mountain climbers', 'Abdominaux', 'Poids du corps', 'Mountain climbers dynamiques', false),
('Russian twist', 'Abdominaux', 'Poids du corps', 'Rotation du buste assis', false),

-- Mollets
('Élévation mollets debout', 'Mollets', 'Haltères', 'Élévation sur pointes de pieds', false),
('Élévation mollets assis', 'Mollets', 'Machine', 'Élévation mollets en position assise', false);

-- =======================
-- PREDEFINED HIIT WORKOUTS
-- =======================

INSERT INTO hiit_workouts (id, title, description, work_duration, rest_duration, total_duration, total_rounds, is_custom) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'HIIT débutant', '15 min - 30s effort / 30s repos', 30, 30, 15, 15, false),
('550e8400-e29b-41d4-a716-446655440002', 'HIIT intense', '20 min - 45s effort / 15s repos', 45, 15, 20, 20, false),
('550e8400-e29b-41d4-a716-446655440003', 'Tabata', '4 min - 20s effort / 10s repos', 20, 10, 4, 8, false),
('550e8400-e29b-41d4-a716-446655440004', 'HIIT endurance', '25 min - 40s effort / 20s repos', 40, 20, 25, 25, false),
('550e8400-e29b-41d4-a716-446655440005', 'HIIT sprint', '12 min - 20s effort / 40s repos', 20, 40, 12, 12, false);

-- =======================
-- BASIC FOODS DATABASE
-- =======================

INSERT INTO foods (name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, is_custom) VALUES
-- Protéines
('Blanc de poulet', 165, 31.0, 0.0, 3.6, false),
('Saumon', 208, 25.4, 0.0, 12.4, false),
('Œuf entier', 155, 13.0, 1.1, 11.0, false),
('Thon en conserve', 116, 25.5, 0.0, 0.8, false),
('Bœuf haché 5%', 137, 22.0, 0.0, 5.0, false),

-- Glucides
('Riz basmati', 350, 8.0, 78.0, 0.6, false),
('Avoine', 389, 16.9, 66.3, 6.9, false),
('Pomme de terre', 77, 2.0, 17.0, 0.1, false),
('Pâtes complètes', 349, 13.0, 67.0, 2.5, false),
('Pain complet', 247, 13.0, 41.0, 4.2, false),

-- Légumes
('Brocoli', 34, 2.8, 7.0, 0.4, false),
('Épinards', 23, 2.9, 3.6, 0.4, false),
('Carotte', 41, 0.9, 10.0, 0.2, false),
('Tomate', 18, 0.9, 3.9, 0.2, false),
('Courgette', 17, 1.2, 3.1, 0.3, false),

-- Fruits
('Banane', 89, 1.1, 23.0, 0.3, false),
('Pomme', 52, 0.3, 14.0, 0.2, false),
('Orange', 47, 0.9, 12.0, 0.1, false),
('Fraise', 32, 0.7, 8.0, 0.3, false),
('Avocat', 160, 2.0, 9.0, 15.0, false),

-- Lipides sains
('Amandes', 579, 21.0, 22.0, 50.0, false),
('Huile d''olive', 884, 0.0, 0.0, 100.0, false),
('Noix', 654, 15.0, 14.0, 65.0, false),

-- Légumineuses
('Lentilles', 353, 25.0, 60.0, 1.1, false),
('Haricots rouges', 333, 24.0, 60.0, 1.2, false),
('Pois chiches', 364, 19.0, 61.0, 6.0, false);

-- =======================
-- CREATE FUNCTION FOR CALCULATING NUTRITIONAL VALUES
-- =======================

CREATE OR REPLACE FUNCTION calculate_meal_nutrition(meal_id_param UUID)
RETURNS TABLE (
  total_calories INTEGER,
  total_protein DECIMAL,
  total_carbs DECIMAL,
  total_fat DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    SUM(mfi.calories)::INTEGER as total_calories,
    SUM((f.protein_per_100g * mfi.calories / f.calories_per_100g))::DECIMAL as total_protein,
    SUM((f.carbs_per_100g * mfi.calories / f.calories_per_100g))::DECIMAL as total_carbs,
    SUM((f.fat_per_100g * mfi.calories / f.calories_per_100g))::DECIMAL as total_fat
  FROM meal_food_items mfi
  JOIN foods f ON f.id = mfi.food_id
  WHERE mfi.meal_id = meal_id_param;
END;
$$ LANGUAGE plpgsql; 