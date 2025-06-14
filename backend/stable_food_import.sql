-- Open Food Facts Import for Ryze App (Stable Version)
-- Generated on: 2025-06-14 13:48:58
-- Total foods: 12
-- Categories: Other, Beverages, Plant Based Foods And Beverages


-- Other (3 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Nutella', 'Nutella', 'Other', 539.0, 6.3, 57.5, 30.9, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('American sandwich complet 600 g off', 'American sandwich complet 600 g off', 'Other', 253.0, 7.7, 41.7, 4.5, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Delise de fanie line', 'Delise de fanie line', 'Other', 0.0, 0.0, 0.0, 0.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();

-- Beverages (3 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('CRISTALINE Eau De Source 1.5L', 'CRISTALINE Eau De Source 1.5L', 'Beverages', 0.0, 0.0, 0.0, 0.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('NESQUIK Cacao', 'NESQUIK Cacao', 'Beverages', 386.0, 5.1, 78.9, 3.6, 7.7, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Nectar Pêche', 'Nectar Pêche', 'Beverages', 0.0, 0.0, 0.0, 0.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();

-- Plant Based Foods And Beverages (6 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Pain AMS complet', 'Pain AMS complet', 'Plant Based Foods And Beverages', 253.0, 7.7, 41.7, 4.5, 7.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Pain de mie nature', 'Pain de mie nature', 'Plant Based Foods And Beverages', 266.0, 7.0, 48.0, 4.3, 3.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Pain de mie céréales sans gluten', 'Pain de mie céréales sans gluten', 'Plant Based Foods And Beverages', 239.0, 3.3, 38.6, 6.2, 8.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Pain de mie nature BIO', 'Pain de mie nature BIO', 'Plant Based Foods And Beverages', 264.0, 8.0, 47.0, 3.8, 5.1, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Toastbrood', 'Pain Extra Moelleux nature sans sucres ajoutés', 'Plant Based Foods And Beverages', 276.0, 8.1, 46.1, 5.2, 6.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Pain 100% mie complet biologique', 'Pain 100% mie complet biologique', 'Plant Based Foods And Beverages', 248.0, 8.5, 39.2, 4.6, 7.7, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();
