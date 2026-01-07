-- Migration: Add German translations to food_database
-- Target: IDs 39228 to 76066
-- Date: 2026-01-05

-- Step 1: Add German columns if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'food_database' AND column_name = 'name_de') THEN
        ALTER TABLE food_database ADD COLUMN name_de TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'food_database' AND column_name = 'reference_unit_de') THEN
        ALTER TABLE food_database ADD COLUMN reference_unit_de TEXT;
    END IF;
END $$;

-- Step 2: Create a function to translate reference units from English to German
CREATE OR REPLACE FUNCTION translate_reference_unit_to_german(unit_en TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN CASE
        -- Basic units (unchanged)
        WHEN unit_en = '100g' THEN '100g'
        WHEN unit_en = '100 g' THEN '100 g'
        WHEN unit_en = 'g' THEN 'g'
        WHEN unit_en = 'ml' THEN 'ml'
        WHEN unit_en = '100ml' THEN '100ml'
        WHEN unit_en = '100 ml' THEN '100 ml'
        WHEN unit_en = 'kg' THEN 'kg'
        WHEN unit_en = 'l' THEN 'l'
        WHEN unit_en = 'L' THEN 'L'

        -- Cup variations
        WHEN unit_en ILIKE '1 cup' THEN '1 Tasse'
        WHEN unit_en ILIKE '% cup' THEN REPLACE(REPLACE(unit_en, ' cup', ' Tasse'), ' Cup', ' Tasse')
        WHEN unit_en ILIKE '% cups' THEN REPLACE(REPLACE(unit_en, ' cups', ' Tassen'), ' Cups', ' Tassen')

        -- Slice variations
        WHEN unit_en ILIKE '1 slice' THEN '1 Scheibe'
        WHEN unit_en ILIKE '% slice' THEN REPLACE(unit_en, ' slice', ' Scheibe')
        WHEN unit_en ILIKE '% slices' THEN REPLACE(unit_en, ' slices', ' Scheiben')

        -- Piece variations
        WHEN unit_en ILIKE '1 piece' THEN '1 Stück'
        WHEN unit_en ILIKE '% piece' THEN REPLACE(unit_en, ' piece', ' Stück')
        WHEN unit_en ILIKE '% pieces' THEN REPLACE(unit_en, ' pieces', ' Stück')

        -- Tablespoon variations
        WHEN unit_en ILIKE '1 tablespoon' THEN '1 Esslöffel'
        WHEN unit_en ILIKE '% tablespoon' THEN REPLACE(unit_en, ' tablespoon', ' Esslöffel')
        WHEN unit_en ILIKE '% tablespoons' THEN REPLACE(unit_en, ' tablespoons', ' Esslöffel')
        WHEN unit_en ILIKE '1 tbsp' THEN '1 EL'
        WHEN unit_en ILIKE '% tbsp' THEN REPLACE(unit_en, ' tbsp', ' EL')

        -- Teaspoon variations
        WHEN unit_en ILIKE '1 teaspoon' THEN '1 Teelöffel'
        WHEN unit_en ILIKE '% teaspoon' THEN REPLACE(unit_en, ' teaspoon', ' Teelöffel')
        WHEN unit_en ILIKE '% teaspoons' THEN REPLACE(unit_en, ' teaspoons', ' Teelöffel')
        WHEN unit_en ILIKE '1 tsp' THEN '1 TL'
        WHEN unit_en ILIKE '% tsp' THEN REPLACE(unit_en, ' tsp', ' TL')

        -- Serving variations
        WHEN unit_en ILIKE '1 serving' THEN '1 Portion'
        WHEN unit_en ILIKE '% serving' THEN REPLACE(unit_en, ' serving', ' Portion')
        WHEN unit_en ILIKE '% servings' THEN REPLACE(unit_en, ' servings', ' Portionen')

        -- Unit variations
        WHEN unit_en ILIKE '1 unit' THEN '1 Einheit'
        WHEN unit_en ILIKE '% unit' THEN REPLACE(unit_en, ' unit', ' Einheit')
        WHEN unit_en ILIKE '% units' THEN REPLACE(unit_en, ' units', ' Einheiten')

        -- Ounce variations
        WHEN unit_en ILIKE '1 oz' THEN '1 Unze'
        WHEN unit_en ILIKE '% oz' THEN REPLACE(unit_en, ' oz', ' Unzen')
        WHEN unit_en ILIKE '1 ounce' THEN '1 Unze'
        WHEN unit_en ILIKE '% ounce' THEN REPLACE(unit_en, ' ounce', ' Unze')
        WHEN unit_en ILIKE '% ounces' THEN REPLACE(unit_en, ' ounces', ' Unzen')

        -- Pound variations
        WHEN unit_en ILIKE '1 lb' THEN '1 Pfund'
        WHEN unit_en ILIKE '% lb' THEN REPLACE(unit_en, ' lb', ' Pfund')
        WHEN unit_en ILIKE '1 pound' THEN '1 Pfund'
        WHEN unit_en ILIKE '% pound' THEN REPLACE(unit_en, ' pound', ' Pfund')
        WHEN unit_en ILIKE '% pounds' THEN REPLACE(unit_en, ' pounds', ' Pfund')

        -- Bowl/Glass variations
        WHEN unit_en ILIKE '1 bowl' THEN '1 Schüssel'
        WHEN unit_en ILIKE '% bowl' THEN REPLACE(unit_en, ' bowl', ' Schüssel')
        WHEN unit_en ILIKE '% bowls' THEN REPLACE(unit_en, ' bowls', ' Schüsseln')
        WHEN unit_en ILIKE '1 glass' THEN '1 Glas'
        WHEN unit_en ILIKE '% glass' THEN REPLACE(unit_en, ' glass', ' Glas')
        WHEN unit_en ILIKE '% glasses' THEN REPLACE(unit_en, ' glasses', ' Gläser')

        -- Portion / small / medium / large
        WHEN unit_en ILIKE '1 small' THEN '1 klein'
        WHEN unit_en ILIKE '1 medium' THEN '1 mittel'
        WHEN unit_en ILIKE '1 large' THEN '1 groß'
        WHEN unit_en ILIKE '% small' THEN REPLACE(unit_en, ' small', ' klein')
        WHEN unit_en ILIKE '% medium' THEN REPLACE(unit_en, ' medium', ' mittel')
        WHEN unit_en ILIKE '% large' THEN REPLACE(unit_en, ' large', ' groß')

        -- Handful
        WHEN unit_en ILIKE '1 handful' THEN '1 Handvoll'
        WHEN unit_en ILIKE '% handful' THEN REPLACE(unit_en, ' handful', ' Handvoll')

        -- Container / Package / Can
        WHEN unit_en ILIKE '1 can' THEN '1 Dose'
        WHEN unit_en ILIKE '% can' THEN REPLACE(unit_en, ' can', ' Dose')
        WHEN unit_en ILIKE '% cans' THEN REPLACE(unit_en, ' cans', ' Dosen')
        WHEN unit_en ILIKE '1 package' THEN '1 Packung'
        WHEN unit_en ILIKE '% package' THEN REPLACE(unit_en, ' package', ' Packung')
        WHEN unit_en ILIKE '% packages' THEN REPLACE(unit_en, ' packages', ' Packungen')
        WHEN unit_en ILIKE '1 bottle' THEN '1 Flasche'
        WHEN unit_en ILIKE '% bottle' THEN REPLACE(unit_en, ' bottle', ' Flasche')
        WHEN unit_en ILIKE '% bottles' THEN REPLACE(unit_en, ' bottles', ' Flaschen')

        -- Default: keep original
        ELSE unit_en
    END;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Create a function to translate common food terms from English to German
CREATE OR REPLACE FUNCTION translate_food_name_to_german(name_en TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    result := name_en;

    -- Proteins / Meat
    result := REGEXP_REPLACE(result, '\mChicken\M', 'Hähnchen', 'gi');
    result := REGEXP_REPLACE(result, '\mchicken\M', 'Hähnchen', 'gi');
    result := REGEXP_REPLACE(result, '\mBeef\M', 'Rindfleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mbeef\M', 'Rindfleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mPork\M', 'Schweinefleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mpork\M', 'Schweinefleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mLamb\M', 'Lammfleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mlamb\M', 'Lammfleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mTurkey\M', 'Truthahn', 'gi');
    result := REGEXP_REPLACE(result, '\mturkey\M', 'Truthahn', 'gi');
    result := REGEXP_REPLACE(result, '\mDuck\M', 'Ente', 'gi');
    result := REGEXP_REPLACE(result, '\mduck\M', 'Ente', 'gi');
    result := REGEXP_REPLACE(result, '\mHam\M', 'Schinken', 'gi');
    result := REGEXP_REPLACE(result, '\mham\M', 'Schinken', 'gi');
    result := REGEXP_REPLACE(result, '\mBacon\M', 'Speck', 'gi');
    result := REGEXP_REPLACE(result, '\mbacon\M', 'Speck', 'gi');
    result := REGEXP_REPLACE(result, '\mSausage\M', 'Wurst', 'gi');
    result := REGEXP_REPLACE(result, '\msausage\M', 'Wurst', 'gi');
    result := REGEXP_REPLACE(result, '\mMeat\M', 'Fleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mmeat\M', 'Fleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mSteak\M', 'Steak', 'gi');

    -- Fish / Seafood
    result := REGEXP_REPLACE(result, '\mFish\M', 'Fisch', 'gi');
    result := REGEXP_REPLACE(result, '\mfish\M', 'Fisch', 'gi');
    result := REGEXP_REPLACE(result, '\mSalmon\M', 'Lachs', 'gi');
    result := REGEXP_REPLACE(result, '\msalmon\M', 'Lachs', 'gi');
    result := REGEXP_REPLACE(result, '\mTuna\M', 'Thunfisch', 'gi');
    result := REGEXP_REPLACE(result, '\mtuna\M', 'Thunfisch', 'gi');
    result := REGEXP_REPLACE(result, '\mShrimp\M', 'Garnelen', 'gi');
    result := REGEXP_REPLACE(result, '\mshrimp\M', 'Garnelen', 'gi');
    result := REGEXP_REPLACE(result, '\mPrawns\M', 'Garnelen', 'gi');
    result := REGEXP_REPLACE(result, '\mCrab\M', 'Krabbe', 'gi');
    result := REGEXP_REPLACE(result, '\mcrab\M', 'Krabbe', 'gi');
    result := REGEXP_REPLACE(result, '\mLobster\M', 'Hummer', 'gi');
    result := REGEXP_REPLACE(result, '\mlobster\M', 'Hummer', 'gi');
    result := REGEXP_REPLACE(result, '\mCod\M', 'Kabeljau', 'gi');
    result := REGEXP_REPLACE(result, '\mcod\M', 'Kabeljau', 'gi');
    result := REGEXP_REPLACE(result, '\mTrout\M', 'Forelle', 'gi');
    result := REGEXP_REPLACE(result, '\mtrout\M', 'Forelle', 'gi');
    result := REGEXP_REPLACE(result, '\mSeafood\M', 'Meeresfrüchte', 'gi');
    result := REGEXP_REPLACE(result, '\mseafood\M', 'Meeresfrüchte', 'gi');

    -- Dairy
    result := REGEXP_REPLACE(result, '\mMilk\M', 'Milch', 'gi');
    result := REGEXP_REPLACE(result, '\mmilk\M', 'Milch', 'gi');
    result := REGEXP_REPLACE(result, '\mCheese\M', 'Käse', 'gi');
    result := REGEXP_REPLACE(result, '\mcheese\M', 'Käse', 'gi');
    result := REGEXP_REPLACE(result, '\mButter\M', 'Butter', 'gi');
    result := REGEXP_REPLACE(result, '\mbutter\M', 'Butter', 'gi');
    result := REGEXP_REPLACE(result, '\mYogurt\M', 'Joghurt', 'gi');
    result := REGEXP_REPLACE(result, '\myogurt\M', 'Joghurt', 'gi');
    result := REGEXP_REPLACE(result, '\mYoghurt\M', 'Joghurt', 'gi');
    result := REGEXP_REPLACE(result, '\mCream\M', 'Sahne', 'gi');
    result := REGEXP_REPLACE(result, '\mcream\M', 'Sahne', 'gi');
    result := REGEXP_REPLACE(result, '\mEgg\M', 'Ei', 'gi');
    result := REGEXP_REPLACE(result, '\megg\M', 'Ei', 'gi');
    result := REGEXP_REPLACE(result, '\mEggs\M', 'Eier', 'gi');
    result := REGEXP_REPLACE(result, '\meggs\M', 'Eier', 'gi');

    -- Vegetables
    result := REGEXP_REPLACE(result, '\mVegetable\M', 'Gemüse', 'gi');
    result := REGEXP_REPLACE(result, '\mvegetable\M', 'Gemüse', 'gi');
    result := REGEXP_REPLACE(result, '\mVegetables\M', 'Gemüse', 'gi');
    result := REGEXP_REPLACE(result, '\mvegetables\M', 'Gemüse', 'gi');
    result := REGEXP_REPLACE(result, '\mCarrot\M', 'Karotte', 'gi');
    result := REGEXP_REPLACE(result, '\mcarrot\M', 'Karotte', 'gi');
    result := REGEXP_REPLACE(result, '\mCarrots\M', 'Karotten', 'gi');
    result := REGEXP_REPLACE(result, '\mcarrots\M', 'Karotten', 'gi');
    result := REGEXP_REPLACE(result, '\mPotato\M', 'Kartoffel', 'gi');
    result := REGEXP_REPLACE(result, '\mpotato\M', 'Kartoffel', 'gi');
    result := REGEXP_REPLACE(result, '\mPotatoes\M', 'Kartoffeln', 'gi');
    result := REGEXP_REPLACE(result, '\mpotatoes\M', 'Kartoffeln', 'gi');
    result := REGEXP_REPLACE(result, '\mTomato\M', 'Tomate', 'gi');
    result := REGEXP_REPLACE(result, '\mtomato\M', 'Tomate', 'gi');
    result := REGEXP_REPLACE(result, '\mTomatoes\M', 'Tomaten', 'gi');
    result := REGEXP_REPLACE(result, '\mtomatoes\M', 'Tomaten', 'gi');
    result := REGEXP_REPLACE(result, '\mOnion\M', 'Zwiebel', 'gi');
    result := REGEXP_REPLACE(result, '\monion\M', 'Zwiebel', 'gi');
    result := REGEXP_REPLACE(result, '\mOnions\M', 'Zwiebeln', 'gi');
    result := REGEXP_REPLACE(result, '\monions\M', 'Zwiebeln', 'gi');
    result := REGEXP_REPLACE(result, '\mGarlic\M', 'Knoblauch', 'gi');
    result := REGEXP_REPLACE(result, '\mgarlic\M', 'Knoblauch', 'gi');
    result := REGEXP_REPLACE(result, '\mPepper\M', 'Paprika', 'gi');
    result := REGEXP_REPLACE(result, '\mpepper\M', 'Paprika', 'gi');
    result := REGEXP_REPLACE(result, '\mBroccoli\M', 'Brokkoli', 'gi');
    result := REGEXP_REPLACE(result, '\mbroccoli\M', 'Brokkoli', 'gi');
    result := REGEXP_REPLACE(result, '\mCauliflower\M', 'Blumenkohl', 'gi');
    result := REGEXP_REPLACE(result, '\mcauliflower\M', 'Blumenkohl', 'gi');
    result := REGEXP_REPLACE(result, '\mSpinach\M', 'Spinat', 'gi');
    result := REGEXP_REPLACE(result, '\mspinach\M', 'Spinat', 'gi');
    result := REGEXP_REPLACE(result, '\mLettuce\M', 'Salat', 'gi');
    result := REGEXP_REPLACE(result, '\mlettuce\M', 'Salat', 'gi');
    result := REGEXP_REPLACE(result, '\mCabbage\M', 'Kohl', 'gi');
    result := REGEXP_REPLACE(result, '\mcabbage\M', 'Kohl', 'gi');
    result := REGEXP_REPLACE(result, '\mCucumber\M', 'Gurke', 'gi');
    result := REGEXP_REPLACE(result, '\mcucumber\M', 'Gurke', 'gi');
    result := REGEXP_REPLACE(result, '\mZucchini\M', 'Zucchini', 'gi');
    result := REGEXP_REPLACE(result, '\mzucchini\M', 'Zucchini', 'gi');
    result := REGEXP_REPLACE(result, '\mEggplant\M', 'Aubergine', 'gi');
    result := REGEXP_REPLACE(result, '\meggplant\M', 'Aubergine', 'gi');
    result := REGEXP_REPLACE(result, '\mMushroom\M', 'Pilz', 'gi');
    result := REGEXP_REPLACE(result, '\mmushroom\M', 'Pilz', 'gi');
    result := REGEXP_REPLACE(result, '\mMushrooms\M', 'Pilze', 'gi');
    result := REGEXP_REPLACE(result, '\mmushrooms\M', 'Pilze', 'gi');
    result := REGEXP_REPLACE(result, '\mPeas\M', 'Erbsen', 'gi');
    result := REGEXP_REPLACE(result, '\mpeas\M', 'Erbsen', 'gi');
    result := REGEXP_REPLACE(result, '\mBeans\M', 'Bohnen', 'gi');
    result := REGEXP_REPLACE(result, '\mbeans\M', 'Bohnen', 'gi');
    result := REGEXP_REPLACE(result, '\mCorn\M', 'Mais', 'gi');
    result := REGEXP_REPLACE(result, '\mcorn\M', 'Mais', 'gi');
    result := REGEXP_REPLACE(result, '\mAsparagus\M', 'Spargel', 'gi');
    result := REGEXP_REPLACE(result, '\masparagus\M', 'Spargel', 'gi');
    result := REGEXP_REPLACE(result, '\mCelery\M', 'Sellerie', 'gi');
    result := REGEXP_REPLACE(result, '\mcelery\M', 'Sellerie', 'gi');
    result := REGEXP_REPLACE(result, '\mLeek\M', 'Lauch', 'gi');
    result := REGEXP_REPLACE(result, '\mleek\M', 'Lauch', 'gi');
    result := REGEXP_REPLACE(result, '\mBeet\M', 'Rote Bete', 'gi');
    result := REGEXP_REPLACE(result, '\mbeet\M', 'Rote Bete', 'gi');
    result := REGEXP_REPLACE(result, '\mRadish\M', 'Radieschen', 'gi');
    result := REGEXP_REPLACE(result, '\mradish\M', 'Radieschen', 'gi');
    result := REGEXP_REPLACE(result, '\mSweet potato\M', 'Süßkartoffel', 'gi');
    result := REGEXP_REPLACE(result, '\msweet potato\M', 'Süßkartoffel', 'gi');

    -- Fruits
    result := REGEXP_REPLACE(result, '\mFruit\M', 'Obst', 'gi');
    result := REGEXP_REPLACE(result, '\mfruit\M', 'Obst', 'gi');
    result := REGEXP_REPLACE(result, '\mFruits\M', 'Obst', 'gi');
    result := REGEXP_REPLACE(result, '\mfruits\M', 'Obst', 'gi');
    result := REGEXP_REPLACE(result, '\mApple\M', 'Apfel', 'gi');
    result := REGEXP_REPLACE(result, '\mapple\M', 'Apfel', 'gi');
    result := REGEXP_REPLACE(result, '\mApples\M', 'Äpfel', 'gi');
    result := REGEXP_REPLACE(result, '\mapples\M', 'Äpfel', 'gi');
    result := REGEXP_REPLACE(result, '\mBanana\M', 'Banane', 'gi');
    result := REGEXP_REPLACE(result, '\mbanana\M', 'Banane', 'gi');
    result := REGEXP_REPLACE(result, '\mBananas\M', 'Bananen', 'gi');
    result := REGEXP_REPLACE(result, '\mbananas\M', 'Bananen', 'gi');
    result := REGEXP_REPLACE(result, '\mOrange\M', 'Orange', 'gi');
    result := REGEXP_REPLACE(result, '\morange\M', 'Orange', 'gi');
    result := REGEXP_REPLACE(result, '\mOranges\M', 'Orangen', 'gi');
    result := REGEXP_REPLACE(result, '\moranges\M', 'Orangen', 'gi');
    result := REGEXP_REPLACE(result, '\mLemon\M', 'Zitrone', 'gi');
    result := REGEXP_REPLACE(result, '\mlemon\M', 'Zitrone', 'gi');
    result := REGEXP_REPLACE(result, '\mLemons\M', 'Zitronen', 'gi');
    result := REGEXP_REPLACE(result, '\mlemons\M', 'Zitronen', 'gi');
    result := REGEXP_REPLACE(result, '\mLime\M', 'Limette', 'gi');
    result := REGEXP_REPLACE(result, '\mlime\M', 'Limette', 'gi');
    result := REGEXP_REPLACE(result, '\mGrape\M', 'Traube', 'gi');
    result := REGEXP_REPLACE(result, '\mgrape\M', 'Traube', 'gi');
    result := REGEXP_REPLACE(result, '\mGrapes\M', 'Trauben', 'gi');
    result := REGEXP_REPLACE(result, '\mgrapes\M', 'Trauben', 'gi');
    result := REGEXP_REPLACE(result, '\mStrawberry\M', 'Erdbeere', 'gi');
    result := REGEXP_REPLACE(result, '\mstrawberry\M', 'Erdbeere', 'gi');
    result := REGEXP_REPLACE(result, '\mStrawberries\M', 'Erdbeeren', 'gi');
    result := REGEXP_REPLACE(result, '\mstrawberries\M', 'Erdbeeren', 'gi');
    result := REGEXP_REPLACE(result, '\mBlueberry\M', 'Heidelbeere', 'gi');
    result := REGEXP_REPLACE(result, '\mblueberry\M', 'Heidelbeere', 'gi');
    result := REGEXP_REPLACE(result, '\mBlueberries\M', 'Heidelbeeren', 'gi');
    result := REGEXP_REPLACE(result, '\mblueberries\M', 'Heidelbeeren', 'gi');
    result := REGEXP_REPLACE(result, '\mRaspberry\M', 'Himbeere', 'gi');
    result := REGEXP_REPLACE(result, '\mraspberry\M', 'Himbeere', 'gi');
    result := REGEXP_REPLACE(result, '\mRaspberries\M', 'Himbeeren', 'gi');
    result := REGEXP_REPLACE(result, '\mraspberries\M', 'Himbeeren', 'gi');
    result := REGEXP_REPLACE(result, '\mCherry\M', 'Kirsche', 'gi');
    result := REGEXP_REPLACE(result, '\mcherry\M', 'Kirsche', 'gi');
    result := REGEXP_REPLACE(result, '\mCherries\M', 'Kirschen', 'gi');
    result := REGEXP_REPLACE(result, '\mcherries\M', 'Kirschen', 'gi');
    result := REGEXP_REPLACE(result, '\mPeach\M', 'Pfirsich', 'gi');
    result := REGEXP_REPLACE(result, '\mpeach\M', 'Pfirsich', 'gi');
    result := REGEXP_REPLACE(result, '\mPeaches\M', 'Pfirsiche', 'gi');
    result := REGEXP_REPLACE(result, '\mpeaches\M', 'Pfirsiche', 'gi');
    result := REGEXP_REPLACE(result, '\mPear\M', 'Birne', 'gi');
    result := REGEXP_REPLACE(result, '\mpear\M', 'Birne', 'gi');
    result := REGEXP_REPLACE(result, '\mPears\M', 'Birnen', 'gi');
    result := REGEXP_REPLACE(result, '\mpears\M', 'Birnen', 'gi');
    result := REGEXP_REPLACE(result, '\mPlum\M', 'Pflaume', 'gi');
    result := REGEXP_REPLACE(result, '\mplum\M', 'Pflaume', 'gi');
    result := REGEXP_REPLACE(result, '\mPlums\M', 'Pflaumen', 'gi');
    result := REGEXP_REPLACE(result, '\mplums\M', 'Pflaumen', 'gi');
    result := REGEXP_REPLACE(result, '\mMango\M', 'Mango', 'gi');
    result := REGEXP_REPLACE(result, '\mmango\M', 'Mango', 'gi');
    result := REGEXP_REPLACE(result, '\mPineapple\M', 'Ananas', 'gi');
    result := REGEXP_REPLACE(result, '\mpineapple\M', 'Ananas', 'gi');
    result := REGEXP_REPLACE(result, '\mWatermelon\M', 'Wassermelone', 'gi');
    result := REGEXP_REPLACE(result, '\mwatermelon\M', 'Wassermelone', 'gi');
    result := REGEXP_REPLACE(result, '\mMelon\M', 'Melone', 'gi');
    result := REGEXP_REPLACE(result, '\mmelon\M', 'Melone', 'gi');
    result := REGEXP_REPLACE(result, '\mKiwi\M', 'Kiwi', 'gi');
    result := REGEXP_REPLACE(result, '\mkiwi\M', 'Kiwi', 'gi');
    result := REGEXP_REPLACE(result, '\mPomegranate\M', 'Granatapfel', 'gi');
    result := REGEXP_REPLACE(result, '\mpomegranate\M', 'Granatapfel', 'gi');
    result := REGEXP_REPLACE(result, '\mCoconut\M', 'Kokosnuss', 'gi');
    result := REGEXP_REPLACE(result, '\mcoconut\M', 'Kokosnuss', 'gi');
    result := REGEXP_REPLACE(result, '\mAvocado\M', 'Avocado', 'gi');
    result := REGEXP_REPLACE(result, '\mavocado\M', 'Avocado', 'gi');

    -- Grains and Cereals
    result := REGEXP_REPLACE(result, '\mBread\M', 'Brot', 'gi');
    result := REGEXP_REPLACE(result, '\mbread\M', 'Brot', 'gi');
    result := REGEXP_REPLACE(result, '\mRice\M', 'Reis', 'gi');
    result := REGEXP_REPLACE(result, '\mrice\M', 'Reis', 'gi');
    result := REGEXP_REPLACE(result, '\mPasta\M', 'Nudeln', 'gi');
    result := REGEXP_REPLACE(result, '\mpasta\M', 'Nudeln', 'gi');
    result := REGEXP_REPLACE(result, '\mNoodles\M', 'Nudeln', 'gi');
    result := REGEXP_REPLACE(result, '\mnoodles\M', 'Nudeln', 'gi');
    result := REGEXP_REPLACE(result, '\mOats\M', 'Haferflocken', 'gi');
    result := REGEXP_REPLACE(result, '\moats\M', 'Haferflocken', 'gi');
    result := REGEXP_REPLACE(result, '\mOatmeal\M', 'Haferbrei', 'gi');
    result := REGEXP_REPLACE(result, '\moatmeal\M', 'Haferbrei', 'gi');
    result := REGEXP_REPLACE(result, '\mCereal\M', 'Müsli', 'gi');
    result := REGEXP_REPLACE(result, '\mcereal\M', 'Müsli', 'gi');
    result := REGEXP_REPLACE(result, '\mWheat\M', 'Weizen', 'gi');
    result := REGEXP_REPLACE(result, '\mwheat\M', 'Weizen', 'gi');
    result := REGEXP_REPLACE(result, '\mFlour\M', 'Mehl', 'gi');
    result := REGEXP_REPLACE(result, '\mflour\M', 'Mehl', 'gi');
    result := REGEXP_REPLACE(result, '\mBarley\M', 'Gerste', 'gi');
    result := REGEXP_REPLACE(result, '\mbarley\M', 'Gerste', 'gi');
    result := REGEXP_REPLACE(result, '\mQuinoa\M', 'Quinoa', 'gi');
    result := REGEXP_REPLACE(result, '\mquinoa\M', 'Quinoa', 'gi');
    result := REGEXP_REPLACE(result, '\mCracker\M', 'Cracker', 'gi');
    result := REGEXP_REPLACE(result, '\mcracker\M', 'Cracker', 'gi');
    result := REGEXP_REPLACE(result, '\mCrackers\M', 'Cracker', 'gi');
    result := REGEXP_REPLACE(result, '\mcrackers\M', 'Cracker', 'gi');

    -- Legumes and Nuts
    result := REGEXP_REPLACE(result, '\mLentils\M', 'Linsen', 'gi');
    result := REGEXP_REPLACE(result, '\mlentils\M', 'Linsen', 'gi');
    result := REGEXP_REPLACE(result, '\mChickpeas\M', 'Kichererbsen', 'gi');
    result := REGEXP_REPLACE(result, '\mchickpeas\M', 'Kichererbsen', 'gi');
    result := REGEXP_REPLACE(result, '\mTofu\M', 'Tofu', 'gi');
    result := REGEXP_REPLACE(result, '\mtofu\M', 'Tofu', 'gi');
    result := REGEXP_REPLACE(result, '\mAlmond\M', 'Mandel', 'gi');
    result := REGEXP_REPLACE(result, '\malmond\M', 'Mandel', 'gi');
    result := REGEXP_REPLACE(result, '\mAlmonds\M', 'Mandeln', 'gi');
    result := REGEXP_REPLACE(result, '\malmonds\M', 'Mandeln', 'gi');
    result := REGEXP_REPLACE(result, '\mWalnut\M', 'Walnuss', 'gi');
    result := REGEXP_REPLACE(result, '\mwalnut\M', 'Walnuss', 'gi');
    result := REGEXP_REPLACE(result, '\mWalnuts\M', 'Walnüsse', 'gi');
    result := REGEXP_REPLACE(result, '\mwalnuts\M', 'Walnüsse', 'gi');
    result := REGEXP_REPLACE(result, '\mPeanut\M', 'Erdnuss', 'gi');
    result := REGEXP_REPLACE(result, '\mpeanut\M', 'Erdnuss', 'gi');
    result := REGEXP_REPLACE(result, '\mPeanuts\M', 'Erdnüsse', 'gi');
    result := REGEXP_REPLACE(result, '\mpeanuts\M', 'Erdnüsse', 'gi');
    result := REGEXP_REPLACE(result, '\mCashew\M', 'Cashew', 'gi');
    result := REGEXP_REPLACE(result, '\mcashew\M', 'Cashew', 'gi');
    result := REGEXP_REPLACE(result, '\mHazelnut\M', 'Haselnuss', 'gi');
    result := REGEXP_REPLACE(result, '\mhazelnut\M', 'Haselnuss', 'gi');
    result := REGEXP_REPLACE(result, '\mHazelnuts\M', 'Haselnüsse', 'gi');
    result := REGEXP_REPLACE(result, '\mhazelnuts\M', 'Haselnüsse', 'gi');
    result := REGEXP_REPLACE(result, '\mPistachio\M', 'Pistazie', 'gi');
    result := REGEXP_REPLACE(result, '\mpistachio\M', 'Pistazie', 'gi');
    result := REGEXP_REPLACE(result, '\mPistachios\M', 'Pistazien', 'gi');
    result := REGEXP_REPLACE(result, '\mpistachios\M', 'Pistazien', 'gi');
    result := REGEXP_REPLACE(result, '\mSeeds\M', 'Samen', 'gi');
    result := REGEXP_REPLACE(result, '\mseeds\M', 'Samen', 'gi');
    result := REGEXP_REPLACE(result, '\mSunflower\M', 'Sonnenblumen', 'gi');
    result := REGEXP_REPLACE(result, '\msunflower\M', 'Sonnenblumen', 'gi');
    result := REGEXP_REPLACE(result, '\mPumpkin\M', 'Kürbis', 'gi');
    result := REGEXP_REPLACE(result, '\mpumpkin\M', 'Kürbis', 'gi');
    result := REGEXP_REPLACE(result, '\mChia\M', 'Chia', 'gi');
    result := REGEXP_REPLACE(result, '\mchia\M', 'Chia', 'gi');
    result := REGEXP_REPLACE(result, '\mFlax\M', 'Leinsamen', 'gi');
    result := REGEXP_REPLACE(result, '\mflax\M', 'Leinsamen', 'gi');

    -- Beverages
    result := REGEXP_REPLACE(result, '\mWater\M', 'Wasser', 'gi');
    result := REGEXP_REPLACE(result, '\mwater\M', 'Wasser', 'gi');
    result := REGEXP_REPLACE(result, '\mJuice\M', 'Saft', 'gi');
    result := REGEXP_REPLACE(result, '\mjuice\M', 'Saft', 'gi');
    result := REGEXP_REPLACE(result, '\mTea\M', 'Tee', 'gi');
    result := REGEXP_REPLACE(result, '\mtea\M', 'Tee', 'gi');
    result := REGEXP_REPLACE(result, '\mCoffee\M', 'Kaffee', 'gi');
    result := REGEXP_REPLACE(result, '\mcoffee\M', 'Kaffee', 'gi');
    result := REGEXP_REPLACE(result, '\mSoda\M', 'Limonade', 'gi');
    result := REGEXP_REPLACE(result, '\msoda\M', 'Limonade', 'gi');
    result := REGEXP_REPLACE(result, '\mBeer\M', 'Bier', 'gi');
    result := REGEXP_REPLACE(result, '\mbeer\M', 'Bier', 'gi');
    result := REGEXP_REPLACE(result, '\mWine\M', 'Wein', 'gi');
    result := REGEXP_REPLACE(result, '\mwine\M', 'Wein', 'gi');
    result := REGEXP_REPLACE(result, '\mSmoothie\M', 'Smoothie', 'gi');
    result := REGEXP_REPLACE(result, '\msmoothie\M', 'Smoothie', 'gi');
    result := REGEXP_REPLACE(result, '\mShake\M', 'Shake', 'gi');
    result := REGEXP_REPLACE(result, '\mshake\M', 'Shake', 'gi');

    -- Sweets and Snacks
    result := REGEXP_REPLACE(result, '\mChocolate\M', 'Schokolade', 'gi');
    result := REGEXP_REPLACE(result, '\mchocolate\M', 'Schokolade', 'gi');
    result := REGEXP_REPLACE(result, '\mCandy\M', 'Süßigkeiten', 'gi');
    result := REGEXP_REPLACE(result, '\mcandy\M', 'Süßigkeiten', 'gi');
    result := REGEXP_REPLACE(result, '\mCookie\M', 'Keks', 'gi');
    result := REGEXP_REPLACE(result, '\mcookie\M', 'Keks', 'gi');
    result := REGEXP_REPLACE(result, '\mCookies\M', 'Kekse', 'gi');
    result := REGEXP_REPLACE(result, '\mcookies\M', 'Kekse', 'gi');
    result := REGEXP_REPLACE(result, '\mCake\M', 'Kuchen', 'gi');
    result := REGEXP_REPLACE(result, '\mcake\M', 'Kuchen', 'gi');
    result := REGEXP_REPLACE(result, '\mPie\M', 'Torte', 'gi');
    result := REGEXP_REPLACE(result, '\mpie\M', 'Torte', 'gi');
    result := REGEXP_REPLACE(result, '\mIce cream\M', 'Eiscreme', 'gi');
    result := REGEXP_REPLACE(result, '\mice cream\M', 'Eiscreme', 'gi');
    result := REGEXP_REPLACE(result, '\mPudding\M', 'Pudding', 'gi');
    result := REGEXP_REPLACE(result, '\mpudding\M', 'Pudding', 'gi');
    result := REGEXP_REPLACE(result, '\mHoney\M', 'Honig', 'gi');
    result := REGEXP_REPLACE(result, '\mhoney\M', 'Honig', 'gi');
    result := REGEXP_REPLACE(result, '\mSugar\M', 'Zucker', 'gi');
    result := REGEXP_REPLACE(result, '\msugar\M', 'Zucker', 'gi');
    result := REGEXP_REPLACE(result, '\mSyrup\M', 'Sirup', 'gi');
    result := REGEXP_REPLACE(result, '\msyrup\M', 'Sirup', 'gi');
    result := REGEXP_REPLACE(result, '\mJam\M', 'Marmelade', 'gi');
    result := REGEXP_REPLACE(result, '\mjam\M', 'Marmelade', 'gi');
    result := REGEXP_REPLACE(result, '\mChips\M', 'Chips', 'gi');
    result := REGEXP_REPLACE(result, '\mchips\M', 'Chips', 'gi');
    result := REGEXP_REPLACE(result, '\mPopcorn\M', 'Popcorn', 'gi');
    result := REGEXP_REPLACE(result, '\mpopcorn\M', 'Popcorn', 'gi');
    result := REGEXP_REPLACE(result, '\mPretzel\M', 'Brezel', 'gi');
    result := REGEXP_REPLACE(result, '\mpretzel\M', 'Brezel', 'gi');
    result := REGEXP_REPLACE(result, '\mPretzels\M', 'Brezeln', 'gi');
    result := REGEXP_REPLACE(result, '\mpretzels\M', 'Brezeln', 'gi');
    result := REGEXP_REPLACE(result, '\mDonut\M', 'Donut', 'gi');
    result := REGEXP_REPLACE(result, '\mdonut\M', 'Donut', 'gi');
    result := REGEXP_REPLACE(result, '\mMuffin\M', 'Muffin', 'gi');
    result := REGEXP_REPLACE(result, '\mmuffin\M', 'Muffin', 'gi');
    result := REGEXP_REPLACE(result, '\mBrownie\M', 'Brownie', 'gi');
    result := REGEXP_REPLACE(result, '\mbrownie\M', 'Brownie', 'gi');
    result := REGEXP_REPLACE(result, '\mWaffle\M', 'Waffel', 'gi');
    result := REGEXP_REPLACE(result, '\mwaffle\M', 'Waffel', 'gi');
    result := REGEXP_REPLACE(result, '\mWaffles\M', 'Waffeln', 'gi');
    result := REGEXP_REPLACE(result, '\mwaffles\M', 'Waffeln', 'gi');
    result := REGEXP_REPLACE(result, '\mPancake\M', 'Pfannkuchen', 'gi');
    result := REGEXP_REPLACE(result, '\mpancake\M', 'Pfannkuchen', 'gi');
    result := REGEXP_REPLACE(result, '\mPancakes\M', 'Pfannkuchen', 'gi');
    result := REGEXP_REPLACE(result, '\mpancakes\M', 'Pfannkuchen', 'gi');

    -- Condiments and Sauces
    result := REGEXP_REPLACE(result, '\mSauce\M', 'Soße', 'gi');
    result := REGEXP_REPLACE(result, '\msauce\M', 'Soße', 'gi');
    result := REGEXP_REPLACE(result, '\mKetchup\M', 'Ketchup', 'gi');
    result := REGEXP_REPLACE(result, '\mketchup\M', 'Ketchup', 'gi');
    result := REGEXP_REPLACE(result, '\mMustard\M', 'Senf', 'gi');
    result := REGEXP_REPLACE(result, '\mmustard\M', 'Senf', 'gi');
    result := REGEXP_REPLACE(result, '\mMayonnaise\M', 'Mayonnaise', 'gi');
    result := REGEXP_REPLACE(result, '\mmayonnaise\M', 'Mayonnaise', 'gi');
    result := REGEXP_REPLACE(result, '\mMayo\M', 'Mayo', 'gi');
    result := REGEXP_REPLACE(result, '\mmayo\M', 'Mayo', 'gi');
    result := REGEXP_REPLACE(result, '\mVinegar\M', 'Essig', 'gi');
    result := REGEXP_REPLACE(result, '\mvinegar\M', 'Essig', 'gi');
    result := REGEXP_REPLACE(result, '\mOil\M', 'Öl', 'gi');
    result := REGEXP_REPLACE(result, '\moil\M', 'Öl', 'gi');
    result := REGEXP_REPLACE(result, '\mOlive\M', 'Oliven', 'gi');
    result := REGEXP_REPLACE(result, '\molive\M', 'Oliven', 'gi');
    result := REGEXP_REPLACE(result, '\mSoy\M', 'Soja', 'gi');
    result := REGEXP_REPLACE(result, '\msoy\M', 'Soja', 'gi');
    result := REGEXP_REPLACE(result, '\mDressing\M', 'Dressing', 'gi');
    result := REGEXP_REPLACE(result, '\mdressing\M', 'Dressing', 'gi');
    result := REGEXP_REPLACE(result, '\mSalt\M', 'Salz', 'gi');
    result := REGEXP_REPLACE(result, '\msalt\M', 'Salz', 'gi');

    -- Herbs and Spices
    result := REGEXP_REPLACE(result, '\mBasil\M', 'Basilikum', 'gi');
    result := REGEXP_REPLACE(result, '\mbasil\M', 'Basilikum', 'gi');
    result := REGEXP_REPLACE(result, '\mParsley\M', 'Petersilie', 'gi');
    result := REGEXP_REPLACE(result, '\mparsley\M', 'Petersilie', 'gi');
    result := REGEXP_REPLACE(result, '\mCilantro\M', 'Koriander', 'gi');
    result := REGEXP_REPLACE(result, '\mcilantro\M', 'Koriander', 'gi');
    result := REGEXP_REPLACE(result, '\mCoriander\M', 'Koriander', 'gi');
    result := REGEXP_REPLACE(result, '\mcoriander\M', 'Koriander', 'gi');
    result := REGEXP_REPLACE(result, '\mMint\M', 'Minze', 'gi');
    result := REGEXP_REPLACE(result, '\mmint\M', 'Minze', 'gi');
    result := REGEXP_REPLACE(result, '\mRosemary\M', 'Rosmarin', 'gi');
    result := REGEXP_REPLACE(result, '\mrosemary\M', 'Rosmarin', 'gi');
    result := REGEXP_REPLACE(result, '\mThyme\M', 'Thymian', 'gi');
    result := REGEXP_REPLACE(result, '\mthyme\M', 'Thymian', 'gi');
    result := REGEXP_REPLACE(result, '\mOregano\M', 'Oregano', 'gi');
    result := REGEXP_REPLACE(result, '\moregano\M', 'Oregano', 'gi');
    result := REGEXP_REPLACE(result, '\mCinnamon\M', 'Zimt', 'gi');
    result := REGEXP_REPLACE(result, '\mcinnamon\M', 'Zimt', 'gi');
    result := REGEXP_REPLACE(result, '\mGinger\M', 'Ingwer', 'gi');
    result := REGEXP_REPLACE(result, '\mginger\M', 'Ingwer', 'gi');
    result := REGEXP_REPLACE(result, '\mTurmeric\M', 'Kurkuma', 'gi');
    result := REGEXP_REPLACE(result, '\mturmeric\M', 'Kurkuma', 'gi');
    result := REGEXP_REPLACE(result, '\mCumin\M', 'Kreuzkümmel', 'gi');
    result := REGEXP_REPLACE(result, '\mcumin\M', 'Kreuzkümmel', 'gi');
    result := REGEXP_REPLACE(result, '\mPaprika\M', 'Paprika', 'gi');
    result := REGEXP_REPLACE(result, '\mpaprika\M', 'Paprika', 'gi');
    result := REGEXP_REPLACE(result, '\mChili\M', 'Chili', 'gi');
    result := REGEXP_REPLACE(result, '\mchili\M', 'Chili', 'gi');
    result := REGEXP_REPLACE(result, '\mVanilla\M', 'Vanille', 'gi');
    result := REGEXP_REPLACE(result, '\mvanilla\M', 'Vanille', 'gi');

    -- Common Dishes
    result := REGEXP_REPLACE(result, '\mSoup\M', 'Suppe', 'gi');
    result := REGEXP_REPLACE(result, '\msoup\M', 'Suppe', 'gi');
    result := REGEXP_REPLACE(result, '\mSalad\M', 'Salat', 'gi');
    result := REGEXP_REPLACE(result, '\msalad\M', 'Salat', 'gi');
    result := REGEXP_REPLACE(result, '\mSandwich\M', 'Sandwich', 'gi');
    result := REGEXP_REPLACE(result, '\msandwich\M', 'Sandwich', 'gi');
    result := REGEXP_REPLACE(result, '\mBurger\M', 'Burger', 'gi');
    result := REGEXP_REPLACE(result, '\mburger\M', 'Burger', 'gi');
    result := REGEXP_REPLACE(result, '\mPizza\M', 'Pizza', 'gi');
    result := REGEXP_REPLACE(result, '\mpizza\M', 'Pizza', 'gi');
    result := REGEXP_REPLACE(result, '\mTaco\M', 'Taco', 'gi');
    result := REGEXP_REPLACE(result, '\mtaco\M', 'Taco', 'gi');
    result := REGEXP_REPLACE(result, '\mWrap\M', 'Wrap', 'gi');
    result := REGEXP_REPLACE(result, '\mwrap\M', 'Wrap', 'gi');
    result := REGEXP_REPLACE(result, '\mStew\M', 'Eintopf', 'gi');
    result := REGEXP_REPLACE(result, '\mstew\M', 'Eintopf', 'gi');
    result := REGEXP_REPLACE(result, '\mCasserole\M', 'Auflauf', 'gi');
    result := REGEXP_REPLACE(result, '\mcasserole\M', 'Auflauf', 'gi');
    result := REGEXP_REPLACE(result, '\mOmelette\M', 'Omelett', 'gi');
    result := REGEXP_REPLACE(result, '\momelette\M', 'Omelett', 'gi');
    result := REGEXP_REPLACE(result, '\mOmelet\M', 'Omelett', 'gi');
    result := REGEXP_REPLACE(result, '\momelet\M', 'Omelett', 'gi');
    result := REGEXP_REPLACE(result, '\mSushi\M', 'Sushi', 'gi');
    result := REGEXP_REPLACE(result, '\msushi\M', 'Sushi', 'gi');
    result := REGEXP_REPLACE(result, '\mCurry\M', 'Curry', 'gi');
    result := REGEXP_REPLACE(result, '\mcurry\M', 'Curry', 'gi');
    result := REGEXP_REPLACE(result, '\mLasagna\M', 'Lasagne', 'gi');
    result := REGEXP_REPLACE(result, '\mlasagna\M', 'Lasagne', 'gi');
    result := REGEXP_REPLACE(result, '\mRavioli\M', 'Ravioli', 'gi');
    result := REGEXP_REPLACE(result, '\mravioli\M', 'Ravioli', 'gi');
    result := REGEXP_REPLACE(result, '\mRisotto\M', 'Risotto', 'gi');
    result := REGEXP_REPLACE(result, '\mrisotto\M', 'Risotto', 'gi');
    result := REGEXP_REPLACE(result, '\mPorridge\M', 'Haferbrei', 'gi');
    result := REGEXP_REPLACE(result, '\mporridge\M', 'Haferbrei', 'gi');

    -- Cooking Terms
    result := REGEXP_REPLACE(result, '\mRoasted\M', 'Geröstete', 'gi');
    result := REGEXP_REPLACE(result, '\mroasted\M', 'Geröstete', 'gi');
    result := REGEXP_REPLACE(result, '\mGrilled\M', 'Gegrillte', 'gi');
    result := REGEXP_REPLACE(result, '\mgrilled\M', 'Gegrillte', 'gi');
    result := REGEXP_REPLACE(result, '\mBaked\M', 'Gebackene', 'gi');
    result := REGEXP_REPLACE(result, '\mbaked\M', 'Gebackene', 'gi');
    result := REGEXP_REPLACE(result, '\mFried\M', 'Gebratene', 'gi');
    result := REGEXP_REPLACE(result, '\mfried\M', 'Gebratene', 'gi');
    result := REGEXP_REPLACE(result, '\mSteamed\M', 'Gedämpfte', 'gi');
    result := REGEXP_REPLACE(result, '\msteamed\M', 'Gedämpfte', 'gi');
    result := REGEXP_REPLACE(result, '\mBoiled\M', 'Gekochte', 'gi');
    result := REGEXP_REPLACE(result, '\mboiled\M', 'Gekochte', 'gi');
    result := REGEXP_REPLACE(result, '\mRaw\M', 'Rohe', 'gi');
    result := REGEXP_REPLACE(result, '\mraw\M', 'Rohe', 'gi');
    result := REGEXP_REPLACE(result, '\mFresh\M', 'Frische', 'gi');
    result := REGEXP_REPLACE(result, '\mfresh\M', 'Frische', 'gi');
    result := REGEXP_REPLACE(result, '\mFrozen\M', 'Gefrorene', 'gi');
    result := REGEXP_REPLACE(result, '\mfrozen\M', 'Gefrorene', 'gi');
    result := REGEXP_REPLACE(result, '\mDried\M', 'Getrocknete', 'gi');
    result := REGEXP_REPLACE(result, '\mdried\M', 'Getrocknete', 'gi');
    result := REGEXP_REPLACE(result, '\mSmoked\M', 'Geräucherte', 'gi');
    result := REGEXP_REPLACE(result, '\msmoked\M', 'Geräucherte', 'gi');
    result := REGEXP_REPLACE(result, '\mCanned\M', 'Konservierte', 'gi');
    result := REGEXP_REPLACE(result, '\mcanned\M', 'Konservierte', 'gi');
    result := REGEXP_REPLACE(result, '\mSliced\M', 'Geschnittene', 'gi');
    result := REGEXP_REPLACE(result, '\msliced\M', 'Geschnittene', 'gi');
    result := REGEXP_REPLACE(result, '\mChopped\M', 'Gehackte', 'gi');
    result := REGEXP_REPLACE(result, '\mchopped\M', 'Gehackte', 'gi');
    result := REGEXP_REPLACE(result, '\mMixed\M', 'Gemischte', 'gi');
    result := REGEXP_REPLACE(result, '\mmixed\M', 'Gemischte', 'gi');
    result := REGEXP_REPLACE(result, '\mStuffed\M', 'Gefüllte', 'gi');
    result := REGEXP_REPLACE(result, '\mstuffed\M', 'Gefüllte', 'gi');
    result := REGEXP_REPLACE(result, '\mBoneless\M', 'Ohne Knochen', 'gi');
    result := REGEXP_REPLACE(result, '\mboneless\M', 'Ohne Knochen', 'gi');
    result := REGEXP_REPLACE(result, '\mSkinless\M', 'Ohne Haut', 'gi');
    result := REGEXP_REPLACE(result, '\mskinless\M', 'Ohne Haut', 'gi');

    -- Modifiers
    result := REGEXP_REPLACE(result, '\mWhole\M', 'Ganze', 'gi');
    result := REGEXP_REPLACE(result, '\mwhole\M', 'Ganze', 'gi');
    result := REGEXP_REPLACE(result, '\mLow-fat\M', 'Fettarm', 'gi');
    result := REGEXP_REPLACE(result, '\mlow-fat\M', 'Fettarm', 'gi');
    result := REGEXP_REPLACE(result, '\mLow fat\M', 'Fettarm', 'gi');
    result := REGEXP_REPLACE(result, '\mlow fat\M', 'Fettarm', 'gi');
    result := REGEXP_REPLACE(result, '\mNon-fat\M', 'Fettfrei', 'gi');
    result := REGEXP_REPLACE(result, '\mnon-fat\M', 'Fettfrei', 'gi');
    result := REGEXP_REPLACE(result, '\mFat-free\M', 'Fettfrei', 'gi');
    result := REGEXP_REPLACE(result, '\mfat-free\M', 'Fettfrei', 'gi');
    result := REGEXP_REPLACE(result, '\mSugar-free\M', 'Zuckerfrei', 'gi');
    result := REGEXP_REPLACE(result, '\msugar-free\M', 'Zuckerfrei', 'gi');
    result := REGEXP_REPLACE(result, '\mOrganic\M', 'Bio', 'gi');
    result := REGEXP_REPLACE(result, '\morganic\M', 'Bio', 'gi');
    result := REGEXP_REPLACE(result, '\mLight\M', 'Leicht', 'gi');
    result := REGEXP_REPLACE(result, '\mlight\M', 'Leicht', 'gi');
    result := REGEXP_REPLACE(result, '\mSkimmed\M', 'Entrahmt', 'gi');
    result := REGEXP_REPLACE(result, '\mskimmed\M', 'Entrahmt', 'gi');
    result := REGEXP_REPLACE(result, '\mSkim\M', 'Entrahmt', 'gi');
    result := REGEXP_REPLACE(result, '\mskim\M', 'Entrahmt', 'gi');
    result := REGEXP_REPLACE(result, '\mWith\M', 'mit', 'gi');
    result := REGEXP_REPLACE(result, '\mwith\M', 'mit', 'gi');
    result := REGEXP_REPLACE(result, '\mWithout\M', 'ohne', 'gi');
    result := REGEXP_REPLACE(result, '\mwithout\M', 'ohne', 'gi');
    result := REGEXP_REPLACE(result, '\mAnd\M', 'und', 'gi');
    result := REGEXP_REPLACE(result, '\mand\M', 'und', 'gi');
    result := REGEXP_REPLACE(result, '\mIn\M', 'in', 'gi');
    result := REGEXP_REPLACE(result, '\mBreast\M', 'Brust', 'gi');
    result := REGEXP_REPLACE(result, '\mbreast\M', 'Brust', 'gi');
    result := REGEXP_REPLACE(result, '\mThigh\M', 'Schenkel', 'gi');
    result := REGEXP_REPLACE(result, '\mthigh\M', 'Schenkel', 'gi');
    result := REGEXP_REPLACE(result, '\mLeg\M', 'Keule', 'gi');
    result := REGEXP_REPLACE(result, '\mleg\M', 'Keule', 'gi');
    result := REGEXP_REPLACE(result, '\mWing\M', 'Flügel', 'gi');
    result := REGEXP_REPLACE(result, '\mwing\M', 'Flügel', 'gi');
    result := REGEXP_REPLACE(result, '\mFillet\M', 'Filet', 'gi');
    result := REGEXP_REPLACE(result, '\mfillet\M', 'Filet', 'gi');
    result := REGEXP_REPLACE(result, '\mGround\M', 'Hackfleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mground\M', 'Hackfleisch', 'gi');
    result := REGEXP_REPLACE(result, '\mMinced\M', 'Gehackt', 'gi');
    result := REGEXP_REPLACE(result, '\mminced\M', 'Gehackt', 'gi');

    -- Breakfast items
    result := REGEXP_REPLACE(result, '\mBreakfast\M', 'Frühstück', 'gi');
    result := REGEXP_REPLACE(result, '\mbreakfast\M', 'Frühstück', 'gi');
    result := REGEXP_REPLACE(result, '\mToast\M', 'Toast', 'gi');
    result := REGEXP_REPLACE(result, '\mtoast\M', 'Toast', 'gi');
    result := REGEXP_REPLACE(result, '\mCroissant\M', 'Croissant', 'gi');
    result := REGEXP_REPLACE(result, '\mcroissant\M', 'Croissant', 'gi');
    result := REGEXP_REPLACE(result, '\mBagel\M', 'Bagel', 'gi');
    result := REGEXP_REPLACE(result, '\mbagel\M', 'Bagel', 'gi');
    result := REGEXP_REPLACE(result, '\mGranola\M', 'Granola', 'gi');
    result := REGEXP_REPLACE(result, '\mgranola\M', 'Granola', 'gi');

    -- Other common foods
    result := REGEXP_REPLACE(result, '\mProtein\M', 'Protein', 'gi');
    result := REGEXP_REPLACE(result, '\mprotein\M', 'Protein', 'gi');
    result := REGEXP_REPLACE(result, '\mBar\M', 'Riegel', 'gi');
    result := REGEXP_REPLACE(result, '\mbar\M', 'Riegel', 'gi');
    result := REGEXP_REPLACE(result, '\mPowder\M', 'Pulver', 'gi');
    result := REGEXP_REPLACE(result, '\mpowder\M', 'Pulver', 'gi');
    result := REGEXP_REPLACE(result, '\mWhey\M', 'Molke', 'gi');
    result := REGEXP_REPLACE(result, '\mwhey\M', 'Molke', 'gi');
    result := REGEXP_REPLACE(result, '\mEnergy\M', 'Energie', 'gi');
    result := REGEXP_REPLACE(result, '\menergy\M', 'Energie', 'gi');
    result := REGEXP_REPLACE(result, '\mSnack\M', 'Snack', 'gi');
    result := REGEXP_REPLACE(result, '\msnack\M', 'Snack', 'gi');
    result := REGEXP_REPLACE(result, '\mMeal\M', 'Mahlzeit', 'gi');
    result := REGEXP_REPLACE(result, '\mmeal\M', 'Mahlzeit', 'gi');

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Apply translations to the specified ID range (39228 to 76066)
-- This updates both name_de and reference_unit_de columns

UPDATE food_database
SET
    name_de = translate_food_name_to_german(name_en),
    reference_unit_de = translate_reference_unit_to_german(reference_unit_en)
WHERE id >= 39228 AND id <= 76066;

-- Step 5: Create indexes for German columns (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_food_database_name_de') THEN
        CREATE INDEX idx_food_database_name_de ON food_database(name_de);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_food_database_reference_unit_de') THEN
        CREATE INDEX idx_food_database_reference_unit_de ON food_database(reference_unit_de);
    END IF;
END $$;

-- Step 6: Cleanup - Drop the translation functions after use (optional)
-- Uncomment the following lines if you want to remove the functions after the migration
-- DROP FUNCTION IF EXISTS translate_food_name_to_german(TEXT);
-- DROP FUNCTION IF EXISTS translate_reference_unit_to_german(TEXT);

-- Verification query (run after migration to check results)
-- SELECT id, name_en, name_de, reference_unit_en, reference_unit_de
-- FROM food_database
-- WHERE id >= 39228 AND id <= 76066
-- ORDER BY id
-- LIMIT 100;
