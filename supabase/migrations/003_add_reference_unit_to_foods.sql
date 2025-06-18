-- Migration: Add reference_unit column to foods table
-- This allows all foods to specify their reference unit (g, ml, portion, cuillère, unité)

-- Add reference_unit column to foods table
ALTER TABLE foods 
ADD COLUMN reference_unit VARCHAR(20) DEFAULT 'g';

-- Add comment to explain the column
COMMENT ON COLUMN foods.reference_unit IS 'Unit of reference for nutritional values (g, ml, portion, cuillère, unité)';

-- Update existing foods to have appropriate reference units based on their category
-- Most foods will use grams (g) by default, but we can set specific ones for liquids
UPDATE foods 
SET reference_unit = 'ml' 
WHERE LOWER(category) LIKE '%boisson%' 
   OR LOWER(category) LIKE '%drink%'
   OR LOWER(name_fr) LIKE '%jus%'
   OR LOWER(name_fr) LIKE '%eau%'
   OR LOWER(name_fr) LIKE '%lait%'
   OR LOWER(name_fr) LIKE '%café%'
   OR LOWER(name_fr) LIKE '%thé%'
   OR LOWER(name_en) LIKE '%juice%'
   OR LOWER(name_en) LIKE '%water%'
   OR LOWER(name_en) LIKE '%milk%'
   OR LOWER(name_en) LIKE '%coffee%'
   OR LOWER(name_en) LIKE '%tea%';

-- Create index for performance on reference_unit column
CREATE INDEX idx_foods_reference_unit ON foods(reference_unit); 