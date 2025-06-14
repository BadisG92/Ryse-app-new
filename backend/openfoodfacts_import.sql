-- OpenFoodFacts Import for Ryze App
-- Generated on: 2025-06-14 14:02:35
-- Total products: 120
-- Categories: Sucrants, Œufs, Céréales, Substituts protéinés, Fruits, Viandes, Noix, Huiles, Poissons, Produits laitiers, Légumineuses, Légumes


-- Viandes (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Pork Sausages', 'Pork sausages', 'Viandes', 266.0, 20.0, 1.58, 20.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Blanc de poulet', 'Blanc de Poulet', 'Viandes', 100.0, 21.0, 0.5, 1.6, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('No Artificial Additives 6 Pork Sausages', 'No Artificial Additives 6 Pork Sausages', 'Viandes', 227.0, 15.6, 0.2, 18.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Le Supérieur - à l''Etouffée - Conservation sans Nitrite', 'Le Supérieur - à l''Etouffée - Conservation sans Nitrite', 'Viandes', 115.0, 22.0, 0.5, 2.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Le Supérieur -25% de Sel - Conservation sans Nitrite', 'Le Supérieur -25% de Sel - Conservation sans Nitrite', 'Viandes', 115.0, 22.0, 0.5, 2.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Pechuga De Pavo Cocida 92%', 'Pechuga de Pavo Cocida 92%', 'Viandes', 89.0, 19.5, 0.0, 1.3, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('unsmoked back bacon rashers', 'unsmoked back bacon rashers', 'Viandes', 257.0, 29.4, 1.0, 15.1, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Blanc de poulet', 'HERTA Blanc Poulet Nature conservation sans nitrite x4 -140g', 'Viandes', 105.6, 21.0, 0.9, 2.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Fleury-Michon rôti de poulet 100 % filet', 'Rôti de Poulet - 100% filet', 'Viandes', 110.0, 22.0, 0.5, 2.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('jamón cocido natural', 'Jambon', 'Viandes', 102.0, 19.0, 0.9, 2.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Poissons (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Filets de maquereau', 'Filets de maquereau', 'Poissons', 180.0, 30.1, 0.6, 8.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Filets De Maquereaux', 'Filets De Maquereaux', 'Poissons', 180.0, 30.1, 0.6, 6.4, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('sardines huile d olive', 'Sardines Huile d''Olive Vierge Extra', 'Poissons', 227.0, 23.0, 0.0, 15.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Atun', 'Isabel Thon', 'Poissons', 198.0, 27.0, 0.0, 10.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Joly Thon Entier', 'Joly Thon Entier', 'Poissons', 175.0, 33.0, 0.97, 1.1, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Atun C / Tomate Isabel', 'Atun C / Tomate Isabel', 'Poissons', 155.0, 17.0, 2.7, 8.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Miettes de Maquereaux', 'Miettes de Maquereaux', 'Poissons', 180.1, 30.1, 0.6, 6.4, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Thon Joly', 'Thon Joly', 'Poissons', 175.0, 33.0, 0.96, 4.4, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Plain Sardines', 'Sardine Nature', 'Poissons', 158.0, 22.0, 0.0, 7.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('TAM thon entier a l''huile', 'TAM thon entier a l''huile', 'Poissons', 231.0, 25.8, 0.0, 14.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Œufs (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('6 Free Range Eggs', 'Tesco Free Range Eggs Medium Box Of 6', 'Œufs', 131.0, 12.6, 0.1, 9.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Œufs frais plein air', 'Œufs frais plein air', 'Œufs', 140.0, 13.0, 0.5, 9.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('10 Œuf frais', '10 Œuf frais', 'Œufs', 140.0, 12.0, 0.7, 9.9, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Oeufs frais plein air Oméga3 x 12', 'Oeufs frais plein air Oméga3 x 12', 'Œufs', 140.0, 13.0, 0.5, 9.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Œufs', 'Œufs', 'Œufs', 140.0, 12.7, 0.27, 9.83, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('12 British Free Range Eggs', '12 British Free Range Eggs', 'Œufs', 131.0, 13.0, 0.5, 9.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Stéphanie eleveur', 'Stéphanie eleveur', 'Œufs', 140.0, 13.0, 0.5, 9.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Œufs de poules élevées en plein air* *conformément au mode de production biologique', 'Œufs de poules élevées en plein air* *conformément au mode de production biologique', 'Œufs', 140.0, 13.0, 0.5, 9.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Œufs bio x6', 'Œufs bio x6', 'Œufs', 75.0, 0.0, 0.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Large free range eggs', 'Free Range Eggs Large Box', 'Œufs', 131.0, 12.6, 0.1, 9.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Légumineuses (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Baked Beans', 'Beanz In a rich tomato sauce', 'Légumineuses', 81.0, 4.82, 15.5, 0.337, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Chickpeas In Water', 'Chickpeas In Water', 'Légumineuses', 115.0, 6.7, 13.6, 2.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Puy Lentils & French green lentils', 'Puy Lentils & French green lentils', 'Légumineuses', 138.0, 8.9, 18.0, 1.7, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Baked Beans', 'Baked Beans', 'Légumineuses', 91.0, 4.7, 14.5, 0.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Protein packed lentil cakes', 'Protein packed lentil cakes', 'Légumineuses', 366.0, 25.0, 58.4, 1.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Tomatoey French Puy & Green lentils', 'Tomatoey French Puy & Green lentils', 'Légumineuses', 142.0, 8.3, 16.0, 4.1, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Heinz Baked Beans', 'Heinz Baked Beans', 'Légumineuses', 81.0, 4.8, 15.5, 0.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Baked Beans', 'Baked Beans in a rich and tasty tomato sauce', 'Légumineuses', 85.0, 4.6, 12.5, 0.6, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Lentilles préparées', 'Lentilles préparées', 'Légumineuses', 91.0, 7.0, 12.5, 0.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Chickpeas in water', 'Greencane Paper Tissues', 'Légumineuses', 122.0, 7.67, 22.8, 1.42, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Céréales (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('tonik', 'Tonik', 'Céréales', 504.0, 4.35, 71.7, 22.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Oat Drink Barista Edition', 'Oat Drink Barista Edition', 'Céréales', 61.0, 1.1, 7.1, 3.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Weetabix', 'Weetabix', 'Céréales', 358.0, 11.8, 68.4, 2.11, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Organic - Lightly Salted - Wholegrain Low Fat - Rice Cakes imp', 'Kallo Organic lightly Salted wholegrain low fat Rice Cakes', 'Céréales', 386.0, 8.57, 80.0, 2.86, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Pain de mie grandes tranches Seigle & Graines 500g', 'Pain de mie grandes tranches Seigle & Graines 500g', 'Céréales', 297.0, 12.0, 37.0, 9.6, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Cruesli - Mixed Nuts', 'cruesly mélange de noix', 'Céréales', 462.0, 8.5, 57.0, 19.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Ohne zucker hafer', 'Avoine Sans Sucres', 'Céréales', 44.0, 0.7, 5.5, 1.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Family Pack', 'Family Pack', 'Céréales', 362.0, 12.0, 69.0, 2.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Haferflocken', 'Zarte Haferflocken', 'Céréales', 372.0, 13.5, 58.8, 7.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Flocons d''avoine', 'Flocons d''avoine', 'Céréales', 362.0, 11.0, 58.0, 7.1, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Légumes (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Concentré de tomates Aicha', 'Concentré de tomates Aicha', 'Légumes', 31.6, 1.24, 6.41, 0.108, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Tomates cerises allongées', 'Tomates cerises allongées', 'Légumes', 0.0, 0.0, 0.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Aicha Tomato Paste', 'Aicha Tomato Paste', 'Légumes', 117.0, 4.6, 23.7, 0.4, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Chopped Tomatoes', 'Tomates pelées', 'Légumes', 26.0, 1.3, 4.0, 0.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Smooth Peanut Butter', 'Crema de cacahuete', 'Légumes', 656.0, 29.6, 15.9, 51.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Italian Tomato Purée Double Concentrate', 'Italian Tomato Purée Double Concentrate', 'Légumes', 89.0, 4.3, 15.3, 0.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Italian Chopped Tomatoes', 'Italian Chopped Tomatoes', 'Légumes', 25.0, 1.4, 4.0, 0.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Chopped Tomatoes', 'Chopped Tomatoes', 'Légumes', 22.0, 1.1, 3.8, 0.1, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Aubergines cuisinées à la provençale', 'Aubergines cuisinées à la provençale', 'Légumes', 83.0, 1.8, 6.7, 5.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Courgettes cuisinees a la provencale', 'Courgettes cuisinées à la provençale', 'Légumes', 62.0, 1.8, 5.5, 3.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Fruits (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Aïn Soltane', 'Aïn Soltane', 'Fruits', 0.0, 0.0, 0.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Cranberries', 'Cranberriess (séchées/sucrées)', 'Fruits', 338.0, 0.7, 78.0, 1.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Cocoa Orange', 'Nakd bar Cacao Orange', 'Fruits', 394.0, 8.7, 51.0, 16.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Crownfield Premium Fruit and Nut Muesli', 'Fruit and nut muesli', 'Fruits', 393.0, 8.89, 60.4, 11.6, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Crème Yaourt Brassé 🍋', 'Crème Yaourt Brassé 🍋', 'Fruits', 113.0, 4.2, 14.9, 4.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Assaisonnement aromatise au citron', 'Assaisonnement aromatise au citron', 'Fruits', 1.12, 0.0, 0.14, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Organic Mixed Berry Granola', 'Organic Mixed Berry Granola', 'Fruits', 441.0, 9.7, 63.5, 14.6, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Perly façon tarte aux fraises', 'Perly façon tarte aux fraises', 'Fruits', 118.0, 7.3, 13.5, 3.9, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Soft Pitted Dates', 'Soft Pitted Dates', 'Fruits', 288.0, 2.5, 65.2, 0.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Compote Pomme Nature', 'Compote Pomme Nature', 'Fruits', 55.0, 0.3, 12.0, 0.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Noix (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Almonds', 'Amandes', 'Noix', 621.0, 24.5, 4.8, 53.3, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Cashew Nuts', 'Noix de cajou non salées', 'Noix', 600.0, 20.5, 19.8, 47.6, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Mix de frutos secos al natural', 'Mélange de fruits secs', 'Noix', 646.0, 20.4, 6.4, 58.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Walnüsse', 'Cerneaux de Noix', 'Noix', 712.0, 15.5, 3.7, 69.1, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Menguy''s Peanut 100%', 'Menguy''s Peanut 100%', 'Noix', 610.0, 28.0, 13.0, 48.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Paranusskerne', 'Noix du Bresil', 'Noix', 697.0, 16.9, 2.7, 66.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Peanut butter creamy', 'Menguy''s Beurre de cacahuètes creamy', 'Noix', 629.0, 25.0, 12.0, 52.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Dorset cereals simply nutty', 'Dorset cereals simply nutty', 'Noix', 376.0, 9.9, 64.4, 6.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Californian Pistachios', 'Pistaches de Californie', 'Noix', 605.0, 26.0, 10.0, 49.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Pistachos', 'Pistacchi', 'Noix', 605.0, 26.5, 10.3, 49.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Huiles (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Huile de table lio', 'Huile de table lio', 'Huiles', 900.0, 0.0, 0.0, 100.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Huile de table équilibrée riche en vitamines A,E,D3', 'Huile de table équilibrée riche en vitamines A,E,D3', 'Huiles', 900.0, 0.0, 0.0, 100.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Hule D''olive', 'Hule D''olive', 'Huiles', 822.0, 0.0, 0.0, 90.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Huile d''olive vierge extra', 'Huile d''olive vierge extra', 'Huiles', 828.0, 0.0, 0.0, 92.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Houilor', 'Houilor', 'Huiles', 900.0, 0.0, 0.0, 100.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Lio huile de table', 'Lio huile de table', 'Huiles', 900.0, 0.0, 0.0, 100.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Huile d''olive vierge de Maroc', 'Huile d''olive vierge de Maroc', 'Huiles', 900.0, 0.0, 0.0, 100.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Huile Lesieur 3 Graines', 'Huile Lesieur 3 Graines', 'Huiles', 900.0, 0.0, 0.0, 100.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('MA HFO .25.16.14', 'Huile d''olive', 'Huiles', 900.0, 0.0, 0.0, 92.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Huile d''olive vierge extra Bio Classico', 'Huile d''olive vierge extra Bio Classico', 'Huiles', 821.0, 0.0, 0.0, 91.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Produits laitiers (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Perly', 'Perly', 'Produits laitiers', 97.0, 8.0, 9.4, 3.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Lait', 'Lait', 'Produits laitiers', 45.0, 3.1, 4.9, 1.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Fromage blanc nature', 'Fromage blanc nature', 'Produits laitiers', 80.6, 7.3, 6.1, 12.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Lait entier UHT', 'Lait entier UHT', 'Produits laitiers', 58.0, 3.0, 4.8, 3.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Jben', 'Jben', 'Produits laitiers', 235.0, 8.0, 3.5, 21.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Marmite Yeast Extract', 'Yeast Extract', 'Produits laitiers', 260.0, 34.0, 30.0, 0.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Lait Frais', 'Lait Frais', 'Produits laitiers', 45.0, 3.0, 4.8, 1.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Margarine de table', 'Margarine de table', 'Produits laitiers', 675.0, 0.1, 0.2, 75.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Yaourt nature', 'Yaourt nature', 'Produits laitiers', 78.5, 4.2, 15.7, 3.3, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('La hollandaise cheddar p64', 'la Hollandaise cheddar', 'Produits laitiers', 270.0, 9.0, 6.0, 21.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Substituts protéinés (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Confiture de fraise', 'Confiture de fraise', 'Substituts protéinés', 250.0, 0.5, 61.33, 0.3, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Sourdough White Ciabattin Bread', 'Sourdough White Ciabattin Bread', 'Substituts protéinés', 230.0, 10.1, 44.1, 0.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('White Sourdough Bread', 'White Sourdough Bread', 'Substituts protéinés', 237.0, 9.73, 46.0, 0.698, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Sourdough Grains & Seeds', 'Sourdough Grains & Seeds', 'Substituts protéinés', 237.0, 10.7, 40.2, 2.7, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Nescafé Classic', 'Nescafé Classic', 'Substituts protéinés', 0.0, 0.0, 0.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Tofoo Naked', 'Tofoo Naked', 'Substituts protéinés', 144.359464627151, 16.5, 1.1, 7.8, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Les Tranches Végé Lentilles Corail', 'Les Tranches Végé Lentilles Corail', 'Substituts protéinés', 143.0, 8.1, 11.0, 6.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Les Tranches Végé Pois chiches', 'Les Tranches Végé Pois chiches', 'Substituts protéinés', 138.0, 8.1, 11.0, 6.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Middle Eastern Plant-Based Falafels', 'Falafels Du Moyen-Orient À Base De Plantes', 'Substituts protéinés', 222.0, 7.6, 20.0, 9.9, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('La Panée Soja et Blé', 'La Panée Soja et Blé', 'Substituts protéinés', 235.0, 12.3, 17.6, 11.7, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();

-- Sucrants (10 items)
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Cosumar Sucre En Lingot Pour Le Thé 1 kg', 'Cosumar Sucre En Lingot Pour Le Thé 1 kg', 'Sucrants', 400.0, 0.0, 100.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Sucre Vanilliné', 'Sucre Vanilliné', 'Sucrants', 392.0, 0.0, 97.6, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Poudre stevia', 'Poudre stevia', 'Sucrants', 2.0, 0.0, 99.0, 0.2, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Miel crémeux français & responsable', 'Miel crémeux français & responsable', 'Sucrants', 0.0, 0.0, 0.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('enmer', 'Sucre  enmer', 'Sucrants', 400.0, 0.0, 100.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('sucre arôme vanille', 'sucre arôme vanille', 'Sucrants', 286.0, 1.43, 100.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Cassonade pure canne', 'Ppk cassonade pure canne kraft daddy 750g', 'Sucrants', 400.0, 0.0, 100.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Pure Cane Sugar', 'Cassonade', 'Sucrants', 400.0, 0.0, 100.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Cosumar Sucre Granule - Granulated Sugar', 'Cosumar Sucre Granule - Granulated Sugar', 'Sucrants', 400.0, 0.0, 100.0, 0.0, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
INSERT INTO foods (name, name_fr, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, created_at, updated_at)
VALUES ('Runny Honey imp', 'Runny Honey imp', 'Sucrants', 329.0, 0.5, 81.5, 0.5, NOW(), NOW())
ON CONFLICT (name) DO UPDATE SET
    name_fr = EXCLUDED.name_fr,
    category = EXCLUDED.category,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    updated_at = NOW();
