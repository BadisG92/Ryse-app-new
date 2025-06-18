-- Migration 005: Add origin column to custom_foods
-- This migration adds an origin column to track whether the food was added manually or via barcode

-- Add the origin column
ALTER TABLE custom_foods 
ADD COLUMN origin TEXT NOT NULL DEFAULT 'manual';

-- Add a check constraint to ensure only valid values
ALTER TABLE custom_foods 
ADD CONSTRAINT custom_foods_origin_check 
CHECK (origin IN ('manual', 'barcode'));

-- Add an index for performance
CREATE INDEX idx_custom_foods_origin ON custom_foods(origin);

-- Add comment for documentation
COMMENT ON COLUMN custom_foods.origin IS 'Source of the custom food: manual (user created) or barcode (scanned from API)'; 