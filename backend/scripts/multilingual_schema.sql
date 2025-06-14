-- Multilingual Database Schema for Ryze App
-- Supports French (fr) and English (en) languages
-- Run this in your Supabase SQL editor before importing data

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Translation Keys Table (for categories, tags, etc.)
CREATE TABLE translation_keys (
    id BIGSERIAL PRIMARY KEY,
    key TEXT NOT NULL,
    language TEXT NOT NULL CHECK (language IN ('en', 'fr')),
    value TEXT NOT NULL,
    category TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(key, language)
);

-- Foods Base Table (nutritional data - language independent)
CREATE TABLE foods (
    id BIGSERIAL PRIMARY KEY,
    brand TEXT,
    barcode TEXT,
    calories_per_100g REAL NOT NULL,
    protein_per_100g REAL NOT NULL,
    carbs_per_100g REAL NOT NULL,
    fat_per_100g REAL NOT NULL,
    fiber_per_100g REAL DEFAULT 0,
    sugar_per_100g REAL DEFAULT 0,
    sodium_per_100g REAL DEFAULT 0,
    serving_size REAL DEFAULT 100,
    verified BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Food Translations Table
CREATE TABLE food_translations (
    id BIGSERIAL PRIMARY KEY,
    food_id BIGINT NOT NULL REFERENCES foods(id) ON DELETE CASCADE,
    language TEXT NOT NULL CHECK (language IN ('en', 'fr')),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    serving_unit TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(food_id, language)
);

-- Exercises Base Table (metrics - language independent)
CREATE TABLE exercises (
    id BIGSERIAL PRIMARY KEY,
    calories_per_minute REAL DEFAULT 5,
    duration_minutes INTEGER DEFAULT 1,
    sets INTEGER DEFAULT 3,
    reps INTEGER DEFAULT 10,
    rest_seconds INTEGER DEFAULT 60,
    image_url TEXT,
    video_url TEXT,
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Exercise Translations Table
CREATE TABLE exercise_translations (
    id BIGSERIAL PRIMARY KEY,
    exercise_id BIGINT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    language TEXT NOT NULL CHECK (language IN ('en', 'fr')),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    muscle_group TEXT NOT NULL,
    secondary_muscles TEXT[],
    equipment TEXT NOT NULL,
    difficulty TEXT NOT NULL,
    instructions TEXT[] NOT NULL,
    tips TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(exercise_id, language)
);

-- Recipes Base Table (nutritional data - language independent)
CREATE TABLE recipes (
    id BIGSERIAL PRIMARY KEY,
    prep_time_minutes INTEGER NOT NULL,
    cook_time_minutes INTEGER NOT NULL,
    servings INTEGER NOT NULL,
    calories_per_serving REAL NOT NULL,
    protein_per_serving REAL NOT NULL,
    carbs_per_serving REAL NOT NULL,
    fat_per_serving REAL NOT NULL,
    fiber_per_serving REAL DEFAULT 0,
    image_url TEXT,
    created_by TEXT DEFAULT 'admin',
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recipe Translations Table
CREATE TABLE recipe_translations (
    id BIGSERIAL PRIMARY KEY,
    recipe_id BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    language TEXT NOT NULL CHECK (language IN ('en', 'fr')),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    cuisine TEXT,
    difficulty TEXT NOT NULL,
    instructions TEXT[] NOT NULL,
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(recipe_id, language)
);

-- Recipe Ingredients Table (links recipes to foods)
CREATE TABLE recipe_ingredients (
    id BIGSERIAL PRIMARY KEY,
    recipe_id BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    food_name TEXT NOT NULL,
    quantity REAL NOT NULL,
    unit TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Preferences Table (for language settings)
CREATE TABLE user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    language TEXT NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'fr')),
    timezone TEXT DEFAULT 'UTC',
    units_system TEXT DEFAULT 'metric' CHECK (units_system IN ('metric', 'imperial')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Indexes for better performance
CREATE INDEX idx_food_translations_food_id ON food_translations(food_id);
CREATE INDEX idx_food_translations_language ON food_translations(language);
CREATE INDEX idx_food_translations_name ON food_translations(name);
CREATE INDEX idx_food_translations_category ON food_translations(category);

CREATE INDEX idx_exercise_translations_exercise_id ON exercise_translations(exercise_id);
CREATE INDEX idx_exercise_translations_language ON exercise_translations(language);
CREATE INDEX idx_exercise_translations_name ON exercise_translations(name);
CREATE INDEX idx_exercise_translations_category ON exercise_translations(category);
CREATE INDEX idx_exercise_translations_muscle_group ON exercise_translations(muscle_group);

CREATE INDEX idx_recipe_translations_recipe_id ON recipe_translations(recipe_id);
CREATE INDEX idx_recipe_translations_language ON recipe_translations(language);
CREATE INDEX idx_recipe_translations_name ON recipe_translations(name);
CREATE INDEX idx_recipe_translations_category ON recipe_translations(category);

CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_food_name ON recipe_ingredients(food_name);

CREATE INDEX idx_translation_keys_key ON translation_keys(key);
CREATE INDEX idx_translation_keys_language ON translation_keys(language);
CREATE INDEX idx_translation_keys_category ON translation_keys(category);

-- RLS (Row Level Security) Policies
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_translations ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_translations ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_translations ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE translation_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Public read access for foods and translations
CREATE POLICY "Public foods read access" ON foods FOR SELECT USING (true);
CREATE POLICY "Public food translations read access" ON food_translations FOR SELECT USING (true);

-- Public read access for exercises and translations
CREATE POLICY "Public exercises read access" ON exercises FOR SELECT USING (is_public = true);
CREATE POLICY "Public exercise translations read access" ON exercise_translations FOR SELECT USING (
    exercise_id IN (SELECT id FROM exercises WHERE is_public = true)
);

-- Public read access for recipes and translations
CREATE POLICY "Public recipes read access" ON recipes FOR SELECT USING (is_public = true);
CREATE POLICY "Public recipe translations read access" ON recipe_translations FOR SELECT USING (
    recipe_id IN (SELECT id FROM recipes WHERE is_public = true)
);
CREATE POLICY "Public recipe ingredients read access" ON recipe_ingredients FOR SELECT USING (
    recipe_id IN (SELECT id FROM recipes WHERE is_public = true)
);

-- Public read access for translation keys
CREATE POLICY "Public translation keys read access" ON translation_keys FOR SELECT USING (true);

-- User preferences policies
CREATE POLICY "Users can view own preferences" ON user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own preferences" ON user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own preferences" ON user_preferences FOR UPDATE USING (auth.uid() = user_id);

-- Functions for getting localized content
CREATE OR REPLACE FUNCTION get_localized_food(food_id_param BIGINT, lang_param TEXT DEFAULT 'en')
RETURNS TABLE (
    id BIGINT,
    name TEXT,
    category TEXT,
    serving_unit TEXT,
    calories_per_100g REAL,
    protein_per_100g REAL,
    carbs_per_100g REAL,
    fat_per_100g REAL,
    fiber_per_100g REAL,
    sugar_per_100g REAL,
    sodium_per_100g REAL,
    serving_size REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        ft.name,
        ft.category,
        ft.serving_unit,
        f.calories_per_100g,
        f.protein_per_100g,
        f.carbs_per_100g,
        f.fat_per_100g,
        f.fiber_per_100g,
        f.sugar_per_100g,
        f.sodium_per_100g,
        f.serving_size
    FROM foods f
    JOIN food_translations ft ON f.id = ft.food_id
    WHERE f.id = food_id_param AND ft.language = lang_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_localized_exercise(exercise_id_param BIGINT, lang_param TEXT DEFAULT 'en')
RETURNS TABLE (
    id BIGINT,
    name TEXT,
    category TEXT,
    muscle_group TEXT,
    secondary_muscles TEXT[],
    equipment TEXT,
    difficulty TEXT,
    instructions TEXT[],
    tips TEXT[],
    calories_per_minute REAL,
    duration_minutes INTEGER,
    sets INTEGER,
    reps INTEGER,
    rest_seconds INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        et.name,
        et.category,
        et.muscle_group,
        et.secondary_muscles,
        et.equipment,
        et.difficulty,
        et.instructions,
        et.tips,
        e.calories_per_minute,
        e.duration_minutes,
        e.sets,
        e.reps,
        e.rest_seconds
    FROM exercises e
    JOIN exercise_translations et ON e.id = et.exercise_id
    WHERE e.id = exercise_id_param AND et.language = lang_param;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_localized_recipe(recipe_id_param BIGINT, lang_param TEXT DEFAULT 'en')
RETURNS TABLE (
    id BIGINT,
    name TEXT,
    description TEXT,
    category TEXT,
    cuisine TEXT,
    difficulty TEXT,
    instructions TEXT[],
    tags TEXT[],
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    servings INTEGER,
    calories_per_serving REAL,
    protein_per_serving REAL,
    carbs_per_serving REAL,
    fat_per_serving REAL,
    fiber_per_serving REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        rt.name,
        rt.description,
        rt.category,
        rt.cuisine,
        rt.difficulty,
        rt.instructions,
        rt.tags,
        r.prep_time_minutes,
        r.cook_time_minutes,
        r.servings,
        r.calories_per_serving,
        r.protein_per_serving,
        r.carbs_per_serving,
        r.fat_per_serving,
        r.fiber_per_serving
    FROM recipes r
    JOIN recipe_translations rt ON r.id = rt.recipe_id
    WHERE r.id = recipe_id_param AND rt.language = lang_param;
END;
$$ LANGUAGE plpgsql;

-- Trigger functions for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER update_foods_updated_at BEFORE UPDATE ON foods FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_food_translations_updated_at BEFORE UPDATE ON food_translations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_exercises_updated_at BEFORE UPDATE ON exercises FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_exercise_translations_updated_at BEFORE UPDATE ON exercise_translations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_recipes_updated_at BEFORE UPDATE ON recipes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_recipe_translations_updated_at BEFORE UPDATE ON recipe_translations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_recipe_ingredients_updated_at BEFORE UPDATE ON recipe_ingredients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_translation_keys_updated_at BEFORE UPDATE ON translation_keys FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE foods IS 'Base foods table with nutritional data (language independent)';
COMMENT ON TABLE food_translations IS 'Translations for food names, categories, and serving units';
COMMENT ON TABLE exercises IS 'Base exercises table with metrics (language independent)';
COMMENT ON TABLE exercise_translations IS 'Translations for exercise names, instructions, and metadata';
COMMENT ON TABLE recipes IS 'Base recipes table with nutritional data (language independent)';
COMMENT ON TABLE recipe_translations IS 'Translations for recipe names, descriptions, and instructions';
COMMENT ON TABLE recipe_ingredients IS 'Links recipes to foods with quantities';
COMMENT ON TABLE translation_keys IS 'Translation keys for categories, tags, and other UI elements';
COMMENT ON TABLE user_preferences IS 'User language and preference settings';

COMMENT ON FUNCTION get_localized_food IS 'Returns food data with translations for specified language';
COMMENT ON FUNCTION get_localized_exercise IS 'Returns exercise data with translations for specified language';
COMMENT ON FUNCTION get_localized_recipe IS 'Returns recipe data with translations for specified language'; 