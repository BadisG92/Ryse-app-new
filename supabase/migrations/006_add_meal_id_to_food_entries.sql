-- Add meal_id to track unique meal blocks
-- This allows multiple meals of the same type (e.g., "Collation 1", "Collation 2")

-- Add meal_id column with UUID generation
ALTER TABLE food_entries 
ADD COLUMN meal_id UUID DEFAULT gen_random_uuid();

-- Create index for better performance when querying by meal_id
CREATE INDEX idx_food_entries_meal_id ON food_entries(meal_id);

-- Create index for better performance when querying by user_id, date, and meal_id
CREATE INDEX idx_food_entries_user_date_meal ON food_entries(user_id, DATE(consumed_at), meal_id);

-- Note: Existing entries will get random meal_ids, which is fine for our use case
-- as we want to support multiple meal blocks of the same type 