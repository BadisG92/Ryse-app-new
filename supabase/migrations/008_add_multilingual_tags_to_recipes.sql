-- Migration pour ajouter des tags multilingues à la table recipes
-- Ajoute les colonnes tags_en et tags_fr pour séparer les tags anglais et français

-- Ajouter les nouvelles colonnes
ALTER TABLE recipes ADD COLUMN tags_en TEXT[];
ALTER TABLE recipes ADD COLUMN tags_fr TEXT[];

-- Migrer les tags existants vers tags_en
UPDATE recipes SET tags_en = tags WHERE tags IS NOT NULL;

-- Créer une fonction de traduction des tags
CREATE OR REPLACE FUNCTION translate_recipe_tags(english_tags TEXT[])
RETURNS TEXT[] AS $$
DECLARE
    tag TEXT;
    french_tags TEXT[] := ARRAY[]::TEXT[];
    translation_map JSONB := '{
        "high_protein": "Riche en protéines",
        "low_carb": "Faible en glucides", 
        "gluten_free": "Sans gluten",
        "vegan": "Végan",
        "vegetarian": "Végétarien",
        "healthy": "Sain",
        "quick": "Rapide",
        "make_ahead": "À préparer à l''avance",
        "high_fiber": "Riche en fibres",
        "plant_based": "À base de plantes",
        "mediterranean": "Méditerranéen",
        "omega_3": "Riche en oméga-3",
        "keto": "Keto",
        "paleo": "Paléo",
        "antioxidants": "Antioxydants",
        "comfort_food": "Plat réconfortant",
        "breakfast": "Petit-déjeuner",
        "lunch": "Déjeuner", 
        "dinner": "Dîner",
        "snack": "Collation",
        "beverage": "Boisson",
        "dessert": "Dessert",
        "soup": "Soupe",
        "salad": "Salade",
        "main_course": "Plat principal",
        "italian": "Italien",
        "asian": "Asiatique",
        "american": "Américain",
        "french": "Français",
        "mexican": "Mexicain",
        "thai": "Thaï",
        "indian": "Indien",
        "hearty": "Copieux",
        "creamy": "Crémeux",
        "spicy": "Épicé",
        "low_fat": "Faible en gras",
        "dairy_free": "Sans lactose",
        "nut_free": "Sans noix",
        "soy_free": "Sans soja",
        "raw": "Cru",
        "fermented": "Fermenté",
        "probiotic": "Probiotique",
        "seasonal": "Saisonnier",
        "budget_friendly": "Économique",
        "family_friendly": "Familial",
        "kid_friendly": "Pour enfants",
        "party": "Fête",
        "romantic": "Romantique",
        "cold": "Froid",
        "warm": "Chaud",
        "refreshing": "Rafraîchissant",
        "energizing": "Énergisant",
        "recovery": "Récupération",
        "pre_workout": "Pré-entraînement",
        "post_workout": "Post-entraînement"
    }';
BEGIN
    IF english_tags IS NULL THEN
        RETURN ARRAY[]::TEXT[];
    END IF;
    
    FOREACH tag IN ARRAY english_tags
    LOOP
        -- Rechercher la traduction dans le mapping
        IF translation_map ? tag THEN
            french_tags := array_append(french_tags, translation_map->>tag);
        ELSE
            -- Si pas de traduction trouvée, garder le tag original
            french_tags := array_append(french_tags, tag);
        END IF;
    END LOOP;
    
    RETURN french_tags;
END;
$$ LANGUAGE plpgsql;

-- Appliquer la traduction à toutes les recettes existantes
UPDATE recipes 
SET tags_fr = translate_recipe_tags(tags_en)
WHERE tags_en IS NOT NULL;

-- Supprimer l'ancienne colonne tags après la migration
-- (optionnel - à décommenter si vous voulez supprimer complètement l'ancienne colonne)
-- ALTER TABLE recipes DROP COLUMN tags;

-- Ajouter des contraintes et index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_recipes_tags_en ON recipes USING GIN(tags_en);
CREATE INDEX IF NOT EXISTS idx_recipes_tags_fr ON recipes USING GIN(tags_fr);

-- Ajouter des commentaires pour documentation
COMMENT ON COLUMN recipes.tags_en IS 'Tags de la recette en anglais (pour compatibilité avec les données existantes)';
COMMENT ON COLUMN recipes.tags_fr IS 'Tags de la recette en français (pour l''interface utilisateur)';

-- Supprimer la fonction temporaire après utilisation
DROP FUNCTION translate_recipe_tags(TEXT[]); 