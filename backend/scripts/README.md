# 📊 Ryze App Data Import Scripts

This directory contains scripts to populate your Supabase database with initial datasets for the Ryze App.

## 📋 What's Included

### 🍎 Foods Dataset (1000+ items)
- Complete nutritional information for 1000+ food items
- Categories: fruits, vegetables, meat, fish, dairy, grains, nuts, legumes, etc.
- Verified nutritional data from USDA FoodData Central
- Serving sizes and units included

### 🍽️ Recipes Dataset (24+ recipes)
- Healthy, balanced recipes with complete instructions
- Categories: Breakfast, Lunch, Dinner, Snacks, Soups, Main Courses, Salads
- Nutritional information calculated per serving
- Ingredient lists with quantities
- Various cuisines and meal types (American, Mediterranean, Asian, Thai, Italian)

### 💪 Exercises Dataset (45+ exercises)
- **Strength (27 exercises)**: Push-ups variations, Squats, Planks, Dumbbell exercises
- **Cardio (9 exercises)**: HIIT, Jumping jacks, Burpees, Running variations
- **Flexibility (9 exercises)**: Yoga poses, Stretches, Mobility work
- Detailed instructions and tips
- Equipment requirements: Bodyweight, dumbbells, resistance bands, yoga mats
- Muscle groups and calorie burn estimates

## 🚀 Quick Start

### 1. Configure Supabase Credentials

Edit the following files and update your Supabase credentials:
- `import_data.py` - Lines 15-16
- `verify_data.py` - Lines 15-16

```python
SUPABASE_URL = "https://your-project.supabase.co"
SUPABASE_KEY = "your-anon-key-here"
```

### 2. Install Dependencies

```bash
pip install supabase
```

### 3. Run the Import

```bash
# Import all data
python import_data.py

# Verify data quality (optional)
python verify_data.py
```

## 📁 File Structure

```
scripts/
├── README.md                 # This file
├── import_data.py            # Main import script
├── verify_data.py            # Data verification script
└── ../data/
    ├── foods_dataset.py      # Foods data (1000+ items)
    ├── recipes_dataset.py    # Recipes data (24+ recipes)
    └── exercises_dataset.py  # Exercises data (45+ exercises)
```

## 🔧 Detailed Usage

### Import Script (`import_data.py`)

The main import script will:
1. **Import Foods** - 1000+ food items with nutritional data
2. **Import Exercises** - 45+ exercises with instructions
3. **Import Recipes** - 24+ recipes with ingredients
4. **Verify Import** - Check that all data was imported correctly

**Features:**
- Batch processing to handle large datasets
- Error handling and rollback
- Progress reporting
- Automatic verification

**Usage:**
```bash
python import_data.py
```

**Expected Output:**
```
🚀 Starting Ryze App data import...
==================================================
🍎 Starting foods import...
  ✅ Imported batch 1: 100 foods
  ✅ Imported batch 2: 100 foods
  ...
🎉 Successfully imported 1000 foods!

💪 Starting exercises import...
🎉 Successfully imported 45 exercises!

🍽️ Starting recipes import...
  ✅ Imported recipe: Grilled Chicken Salad with 7 ingredients
  ✅ Imported recipe: Protein Pancakes with 6 ingredients
  ✅ Imported recipe: Buddha Bowl with Tahini Dressing with 8 ingredients
  ...
🎉 Successfully imported 24 recipes!

🔍 Verifying import...
📊 Database verification:
  Foods: 1000 records
  Exercises: 45 records
  Recipes: 24 records
  Recipe Ingredients: 168 records
✅ Import verification successful!
==================================================
🎉 Data import completed successfully!
```

### Verification Script (`verify_data.py`)

The verification script will:
1. **Check Data Quality** - Validate nutritional values, required fields
2. **Verify Relationships** - Ensure recipe ingredients reference valid foods
3. **Generate Report** - Provide detailed quality metrics

**Usage:**
```bash
python verify_data.py
```

**What it checks:**
- **Foods**: Nutritional values, calorie calculations, valid categories
- **Exercises**: Required fields, valid categories/muscle groups, instruction quality
- **Recipes**: Cooking times, serving sizes, ingredient relationships
- **Relationships**: Foreign key integrity, orphaned records

## 📊 Database Schema Requirements

Your Supabase database should have these tables:

### `foods` table
```sql
CREATE TABLE foods (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT,
    barcode TEXT,
    calories_per_100g REAL NOT NULL,
    protein_per_100g REAL NOT NULL,
    carbs_per_100g REAL NOT NULL,
    fat_per_100g REAL NOT NULL,
    fiber_per_100g REAL DEFAULT 0,
    sugar_per_100g REAL DEFAULT 0,
    sodium_per_100g REAL DEFAULT 0,
    category TEXT NOT NULL,
    serving_size REAL DEFAULT 100,
    serving_unit TEXT DEFAULT 'g',
    verified BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `exercises` table
```sql
CREATE TABLE exercises (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    muscle_group TEXT NOT NULL,
    secondary_muscles TEXT[],
    equipment TEXT NOT NULL,
    difficulty TEXT NOT NULL,
    instructions TEXT[] NOT NULL,
    tips TEXT[],
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
```

### `recipes` table
```sql
CREATE TABLE recipes (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    cuisine TEXT,
    prep_time_minutes INTEGER NOT NULL,
    cook_time_minutes INTEGER NOT NULL,
    servings INTEGER NOT NULL,
    difficulty TEXT NOT NULL,
    calories_per_serving REAL NOT NULL,
    protein_per_serving REAL NOT NULL,
    carbs_per_serving REAL NOT NULL,
    fat_per_serving REAL NOT NULL,
    fiber_per_serving REAL DEFAULT 0,
    instructions TEXT[] NOT NULL,
    tags TEXT[],
    image_url TEXT,
    created_by TEXT DEFAULT 'admin',
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `recipe_ingredients` table
```sql
CREATE TABLE recipe_ingredients (
    id BIGSERIAL PRIMARY KEY,
    recipe_id BIGINT REFERENCES recipes(id) ON DELETE CASCADE,
    food_id BIGINT REFERENCES foods(id) ON DELETE CASCADE,
    quantity REAL NOT NULL,
    unit TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 🛠️ Customization

### Adding More Foods
Edit `../data/foods_dataset.py` and add items to the `EXTENDED_FOODS` list:

```python
{"name": "Your Food", "calories_per_100g": 100, "protein_per_100g": 5.0, ...}
```

### Adding More Recipes
Edit `../data/recipes_dataset.py` and add items to the `RECIPES_DATASET` list:

```python
{
    "name": "Your Recipe",
    "description": "Description here",
    "ingredients": [
        {"food_name": "Chicken Breast", "quantity": 200, "unit": "g"}
    ],
    ...
}
```

### Adding More Exercises
Edit `../data/exercises_dataset.py` and add items to the `EXERCISES_DATASET` list:

```python
{
    "name": "Your Exercise",
    "category": "strength",
    "muscle_group": "chest",
    "instructions": ["Step 1", "Step 2", ...],
    ...
}
```

## 🚨 Troubleshooting

### Common Issues

1. **Supabase Connection Error**
   - Check your URL and API key
   - Ensure your Supabase project is active
   - Verify network connectivity

2. **Import Fails Partway Through**
   - Check Supabase logs for detailed errors
   - Verify your database schema matches requirements
   - Check for API rate limits

3. **Verification Fails**
   - Review the specific issues reported
   - Check for data quality problems
   - Verify foreign key relationships

### Getting Help

If you encounter issues:
1. Check the console output for specific error messages
2. Review your Supabase project logs
3. Verify your database schema matches the requirements
4. Ensure your API keys have the necessary permissions

## 📈 Performance Notes

- **Import Time**: Expect 2-5 minutes for full import
- **Batch Size**: Foods are imported in batches of 100 to avoid API limits
- **Memory Usage**: Scripts use minimal memory (~50MB)
- **API Calls**: Approximately 50-100 API calls total

## ✅ Success Criteria

After successful import, you should have:
- ✅ 1000+ foods with complete nutritional data
- ✅ 20+ exercises with detailed instructions
- ✅ 10+ recipes with ingredient relationships
- ✅ All data verified for quality and consistency
- ✅ Ready-to-use database for your Ryze App

## 🎯 Next Steps

After importing data:
1. Test your app's food search functionality
2. Verify recipe display and ingredient calculations
3. Test exercise filtering and display
4. Consider adding more data specific to your users' needs

---

**Happy coding! 🚀** 