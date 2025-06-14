INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, created_at, updated_at)
VALUES ('Nutella', 'Nutella', 'Pâtes À Tartiner', 539, 6.3, 57.5, 30.9, 0, NOW(), NOW())
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
VALUES ('Le Beurre Tendre Doux', 'Le Beurre Tendre Doux Barquette', 'Beurres Tendres', 744, 0.7, 0.8, 82, 0, NOW(), NOW())
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
VALUES ('Cornstarch', 'Maizena Fleur de Maïs Sans Gluten 400g', 'Other', 355, 0.5, 86, 0.5, 1, NOW(), NOW())
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
VALUES ('Véritable Petit Écolier Chocolat au Lait', 'Véritable Petit Écolier Chocolat au Lait', 'Other', 498, 6.2, 65, 23, 2.8, NOW(), NOW())
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
VALUES ('Grand Arôme 32% de Cacao', 'Grand Arôme 32% de Cacao', 'Other', 0, 0, 0, 0, 0, NOW(), NOW())
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
VALUES ('Petit écolier chocolat noir pur beurre de cacao', 'Petit écolier chocolat noir pur beurre de cacao', 'Other', 502, 5.6, 62, 25, 4.5, NOW(), NOW())
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
VALUES ('Lasagne all''uovo', 'BARILLA LASAGNE ALL''UOVO 500g', 'Lasagnes A Garnir Aux Oeufs', 368, 14, 68, 4, 3, NOW(), NOW())
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
VALUES ('Excellence Noir Orange Intense Aux amandes effilées', 'Excellence Noir Orange Intense', 'Other', 535, 7, 51, 32, 0, NOW(), NOW())
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
VALUES ('Coconut Water', 'Eau de coco original', 'Other', 18.8, 0, 4.58, 0, 0, NOW(), NOW())
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
VALUES ('Curly cacahuète l''original', 'Curly cacahuète l''original', 'Biscuits Aperitif Souffles A La Cacahuete', 486, 13, 52, 24, 5.5, NOW(), NOW())
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
VALUES ('Bonbons à la sève de pin', 'Bonbon à la Sève de Pin', 'Other', 390, 0.1, 97.5, 0, 0, NOW(), NOW())
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
VALUES ('Prince -  Goût Lait -  Choco Au Blé Compet', 'Prince -  Goût Lait -  Choco Au Blé Compet', 'Other', 477, 6, 70, 19, 3.2, NOW(), NOW())
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
VALUES ('Sucre de glace', 'Sucre glace', 'Other', 400, 0, 100, 0, 0, NOW(), NOW())
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
VALUES ('Lulu La Barquette Fraise', 'Lulu La Barquette Fraise', 'Barquettes', 353, 3.8, 78, 2.4, 1.7, NOW(), NOW())
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
VALUES ('Chipster', 'Chipster', 'Other', 472, 4.3, 66, 20, 4, NOW(), NOW())
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
VALUES ('NESTLE DESSERT Lait', 'NESTLE DESSERT Lait 170g', 'Other', 554, 6.9, 52.9, 34.1, 3.7, NOW(), NOW())
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
VALUES ('Original Oreo', 'Original Oreo', 'Other', 472, 5.6, 67, 19, 2.9, NOW(), NOW())
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
VALUES ('Creamy Peanut Butter', 'Beurre d''arachide crémeux', 'Other', 600, 20, 20, 53.3, 6.67, NOW(), NOW())
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
VALUES ('李錦記熊貓牌鮮味蠔油', 'Panda Brand sauce saveur huître', 'Other', 113, 1.2, 27, 0.5, 0, NOW(), NOW())
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
VALUES ('Trancetto cacao', 'Trancetto cacao', 'Other', 369, 5.3, 56, 13, 0, NOW(), NOW())
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
VALUES ('Le Ster - Madeleines Long Original Recipe, 250g (8.8oz)', '20 madeleines longues aux œufs frais', 'Other', 445, 6.1, 55, 22, 0, NOW(), NOW())
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
VALUES ('Smooth Peanut Butter', 'Beurre de Cacahuètes Crémeux', 'Other', 600, 20, 26.7, 53.3, 6.67, NOW(), NOW())
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
VALUES ('Chapelure de pain', 'Fine chapelure de pain', 'Other', 364, 13, 72, 1.8, 3.9, NOW(), NOW())
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
VALUES ('Organic Honey - No 1 Amber', 'Naturoney', 'Other', 300, 0, 85, 0, 0, NOW(), NOW())
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
VALUES ('chocolat NESTLE DESSERT Noir 2X205g', 'chocolat NESTLE DESSERT Noir 2X205g', 'Other', 551, 5.9, 50.6, 34.6, 7.2, NOW(), NOW())
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
VALUES ('Sriracha', 'Sriracha Chili Sauce 730ML', 'Other', 133, 3.33, 26.7, 1.33, 3.33, NOW(), NOW())
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
VALUES ('Kiwifruit', 'Fruits Kiwi Sungold', 'Other', 77, 0.9, 11.1, 0.3, 1.1, NOW(), NOW())
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
VALUES ('Peanut butter Pretzels', 'Valencia Peanut Butter Filled Pretzel Nuggets', 'Other', 480, 16, 54, 22, 4, NOW(), NOW())
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
VALUES ('Coconut Milk', '', 'Other', 181, 1.2, 2.41, 18.1, 0, NOW(), NOW())
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
VALUES ('Choco sticks', 'Milka 112G Choco Lila Stix Cookies', 'Other', 500, 7.2, 64, 23, 2, NOW(), NOW())
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
VALUES ('Extra virgin olive oil', 'Huile d''olive vierge extra (Biologique)', 'Other', 800, 0, 0, 86.7, 0, NOW(), NOW())
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
VALUES ('Mix Max', 'Mix Max', 'Other', 427, 5.6, 55, 20, 0, NOW(), NOW())
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
VALUES ('Starmix', 'Haribo Starmix', 'Other', 325, 7.5, 75, 0, 0, NOW(), NOW())
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
VALUES ('MixMax', 'Mixmax snacks', 'Other', 433, 5.9, 51.1, 22.2, 0, NOW(), NOW())
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
VALUES ('10 pains au lait', '10 pains au lait', 'Pains Au Lait Aux Oeufs Frais', 351, 8.5, 53, 11, 2.8, NOW(), NOW())
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
VALUES ('Quick 1-minute Oats imp', 'Quaker Oats', 'Other', 0, 0, 0, 0, 0, NOW(), NOW())
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
VALUES ('Macine con Panna Fresca', '', 'Other', 482, 6, 68.2, 20, 2.8, NOW(), NOW())
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
VALUES ('Harissa de la Tunisie', 'Harissa de la Tunisie', 'Harissa Du Cap Bon', 72, 2.9, 11, 1, 2.5, NOW(), NOW())
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
VALUES ('Coconut Water', 'Eau de noix de coco', 'Other', 24, 0, 5.6, 0, 0, NOW(), NOW())
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
VALUES ('Chi lately Chunks Cookie Dough Protein Bar', 'Barre protéinée', 'Other', 367, 35, 40, 10, 10, NOW(), NOW())
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
VALUES ('Organic Virgin Coconut Oil', 'Huile de coco vierge biologique', 'Other', 867, 0, 0, 100, 0, NOW(), NOW())
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
VALUES ('pl milka', 'Chocolat noisette raisin', 'Other', 508, 6.2, 57, 28, 3, NOW(), NOW())
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
VALUES ('Chung Jung One Gochujang Hot Red Pepper Paste 500 g', 'Monggo Taeyangcho Red Pepper Paste', 'Gochujang', 216, 3.9, 44, 2.9, 0, NOW(), NOW())
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
VALUES ('Kinder Chocolate', 'Tablette Kinder Chocolat Chocolat au Lait x12 -150g', 'Other', 566, 8.7, 53.5, 35, 0, NOW(), NOW())
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
VALUES ('Maple Syrup', '', 'Other', 367, 0, 90, 0, 0, NOW(), NOW())
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
VALUES ('Hazelnut spread with cocoa', 'Tartinade de noisette', 'Pâtes À Tartiner', 542, 5.9, 55, 32.3, 5, NOW(), NOW())
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
VALUES ('Almonds', '', 'Other', 571, 21.4, 21.4, 50, 14.3, NOW(), NOW())
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
VALUES ('Original Crackers', '', 'Other', 0, 0, 20.01, 0, 0, NOW(), NOW())
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
VALUES ('Crème de pistache', 'Pistì - spreadtable pistachio cream', 'Pâtes À Tartiner', 571, 11.2, 45.9, 38.2, 0, NOW(), NOW())
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
VALUES ('Peanut Butter Crunchy', 'Beurre D’arachide Croquant', 'Other', 600, 20, 20, 53.3, 6.67, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    updated_at = NOW();