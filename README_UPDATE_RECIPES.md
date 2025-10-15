# Recipe Steps_EN Update - Instructions

## Summary
This package contains files to update the `steps_en` column in the `recipes_database` table from the Excel file `recipe_steps_translation.xlsx`.

## Files Generated

### 1. **single_update.sql** (RECOMMENDED)
- Single UPDATE statement using CASE for all 100 recipes
- Most efficient method - updates all recipes in one transaction
- **THIS IS THE FILE TO USE**

### 2. batch_update_recipes.sql
- Traditional approach with 100 individual UPDATE statements
- Wrapped in BEGIN/COMMIT transaction
- Alternative if single_update.sql doesn't work

### 3. Supporting Files
- `recipe_updates.json`: Extracted data from Excel
- `execute_update.sql`: Clean version of single_update.sql
- Various Python scripts for generation

## How to Execute the Update

### Method 1: Via Supabase SQL Editor (RECOMMENDED)
1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Open the file `single_update.sql`
4. Copy and paste the entire content into the SQL Editor
5. Click **Run** or press Ctrl+Enter
6. Verify the update: You should see "100 rows affected"

### Method 2: Via Supabase CLI
```bash
# Navigate to project directory
cd "C:\rise app v2\ryze_app"

# Execute the SQL file
npx supabase db execute --file single_update.sql
```

### Method 3: Via psql (if you have direct database access)
```bash
psql -h your-supabase-host -U postgres -d postgres -f single_update.sql
```

## Verification Queries

After executing the update, run these queries to verify:

### Check Sample Recipes
```sql
SELECT id, name_en, LEFT(steps_en, 100) as steps_preview
FROM recipes_database
WHERE id IN (1, 25, 50, 75, 100)
ORDER BY id;
```

### Count Updated Records
```sql
SELECT COUNT(*) as updated_count
FROM recipes_database
WHERE id BETWEEN 1 AND 100
  AND steps_en IS NOT NULL
  AND steps_en != '';
```

### Check All 100 Recipes
```sql
SELECT id, name_en,
       CASE
         WHEN steps_en IS NULL THEN 'NULL'
         WHEN steps_en = '' THEN 'EMPTY'
         ELSE 'OK'
       END as status
FROM recipes_database
WHERE id BETWEEN 1 AND 100
ORDER BY id;
```

## What Gets Updated

- **Table**: `recipes_database`
- **Column**: `steps_en`
- **Records**: IDs 1 to 100 (100 recipes total)
- **Source**: Excel file `recipe_steps_translation.xlsx`

## Data Sample

### Before
```
id | steps_en
1  | (old French or empty text)
2  | (old French or empty text)
```

### After
```
id | steps_en
1  | 1. Cut tofu into cubes and marinate 20 minutes | 2. Cut vegetables...
2  | 1. Put all ingredients in blender | 2. Blend 45 seconds until smooth...
```

## Rollback (if needed)

If you need to rollback the changes, you would need a backup. To create a backup before updating:

```sql
-- Create backup table
CREATE TABLE recipes_database_backup AS
SELECT * FROM recipes_database WHERE id BETWEEN 1 AND 100;

-- To restore (if needed)
UPDATE recipes_database r
SET steps_en = b.steps_en
FROM recipes_database_backup b
WHERE r.id = b.id;
```

## Notes

- The UPDATE uses a CASE statement for efficiency
- All 100 recipes are updated in a single transaction
- SQL is properly escaped (single quotes doubled)
- Safe to run multiple times (idempotent)
- Only affects recipes with IDs 1-100

## Troubleshooting

### If you get "relation does not exist" error
- Verify you're connected to the correct database
- Check table name is exactly `recipes_database`

### If you get "column does not exist" error
- Verify column name is exactly `steps_en`
- Check with: `\d recipes_database` (in psql) or view table structure

### If some updates fail
- Check the logs for specific error messages
- Individual recipes can be updated manually if needed
- Use the batch_update_recipes.sql file as alternative

## Success Criteria

After successful execution, you should see:
- Message: "UPDATE 100" or "100 rows affected"
- All 100 recipes (IDs 1-100) have English steps in `steps_en` column
- No errors in the SQL execution log

## Contact

If you encounter issues, check:
1. The log output from Supabase SQL Editor
2. Network connection to Supabase
3. Database permissions (need UPDATE permission)
