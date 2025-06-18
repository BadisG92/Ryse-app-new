-- Migration 004: Add localized unit columns
-- This migration replaces the single reference_unit column with separate French and English columns

-- First, add the new columns
ALTER TABLE foods 
ADD COLUMN reference_unit_fr TEXT,
ADD COLUMN reference_unit_en TEXT;

ALTER TABLE custom_foods 
ADD COLUMN reference_unit_fr TEXT,
ADD COLUMN reference_unit_en TEXT;

-- Update existing data with proper translations
UPDATE foods SET 
  reference_unit_fr = CASE 
    WHEN reference_unit = 'g' THEN 'g'
    WHEN reference_unit = 'ml' THEN 'ml'
    WHEN reference_unit = 'portion' THEN 'portion'
    WHEN reference_unit = 'cuillère' THEN 'cuillère'
    WHEN reference_unit = 'tasse' THEN 'tasse'
    WHEN reference_unit = 'unité' THEN 'unité'
    ELSE reference_unit
  END,
  reference_unit_en = CASE 
    WHEN reference_unit = 'g' THEN 'g'
    WHEN reference_unit = 'ml' THEN 'ml'
    WHEN reference_unit = 'portion' THEN 'serving'
    WHEN reference_unit = 'cuillère' THEN 'spoon'
    WHEN reference_unit = 'tasse' THEN 'cup'
    WHEN reference_unit = 'unité' THEN 'unit'
    ELSE reference_unit
  END;

-- Update custom_foods (they should already have the old reference_unit from previous migration)
UPDATE custom_foods SET 
  reference_unit_fr = CASE 
    WHEN reference_unit = 'g' THEN 'g'
    WHEN reference_unit = 'ml' THEN 'ml'
    WHEN reference_unit = 'portion' THEN 'portion'
    WHEN reference_unit = 'cuillère' THEN 'cuillère'
    WHEN reference_unit = 'tasse' THEN 'tasse'
    WHEN reference_unit = 'unité' THEN 'unité'
    ELSE 'g'  -- default fallback
  END,
  reference_unit_en = CASE 
    WHEN reference_unit = 'g' THEN 'g'
    WHEN reference_unit = 'ml' THEN 'ml'
    WHEN reference_unit = 'portion' THEN 'serving'
    WHEN reference_unit = 'cuillère' THEN 'spoon'
    WHEN reference_unit = 'tasse' THEN 'cup'
    WHEN reference_unit = 'unité' THEN 'unit'
    ELSE 'g'  -- default fallback
  END;

-- Drop the old reference_unit column
ALTER TABLE foods DROP COLUMN reference_unit;
ALTER TABLE custom_foods DROP COLUMN reference_unit;

-- Add indexes for performance
CREATE INDEX idx_foods_reference_unit_fr ON foods(reference_unit_fr);
CREATE INDEX idx_foods_reference_unit_en ON foods(reference_unit_en);
CREATE INDEX idx_custom_foods_reference_unit_fr ON custom_foods(reference_unit_fr);
CREATE INDEX idx_custom_foods_reference_unit_en ON custom_foods(reference_unit_en); 