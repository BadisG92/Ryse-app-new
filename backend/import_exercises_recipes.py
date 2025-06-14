from data.exercises_dataset import EXERCISES_DATASET
from data.recipes_dataset import RECIPES_DATASET
from supabase import create_client
import time

# Create Supabase client
supabase = create_client('https://mfskwlzgxjhhknlwpblq.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo')

print(f'📊 Available data:')
print(f'   - Exercises: {len(EXERCISES_DATASET)}')
print(f'   - Recipes: {len(RECIPES_DATASET)}')

# Clear existing exercises and recipes
print('🧹 Clearing existing exercises and recipes...')
try:
    supabase.table('recipe_ingredients').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
    supabase.table('recipe_translations').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
    supabase.table('exercise_translations').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
    supabase.table('recipes').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
    supabase.table('exercises').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
    print('✅ Cleared existing data')
except Exception as e:
    print(f'⚠️ Warning: {e}')

# Import exercises
print(f'💪 Starting import of {len(EXERCISES_DATASET)} exercises...')
batch_size = 50
total_exercises = 0

for i in range(0, len(EXERCISES_DATASET), batch_size):
    batch = EXERCISES_DATASET[i:i + batch_size]
    
    exercises_data = []
    for exercise in batch:
        exercises_data.append({
            'name': exercise['name'],
            'muscle_group': exercise['muscle_group'],
            'equipment': exercise.get('equipment', ''),
            'description': f"{exercise['category']} exercise targeting {exercise['muscle_group']}",
            'is_custom': False
        })
    
    try:
        result = supabase.table('exercises').insert(exercises_data).execute()
        batch_count = len(result.data)
        total_exercises += batch_count
        print(f'✅ Exercise Batch {i//batch_size + 1}: {batch_count} exercises imported (Total: {total_exercises})')
        
        # Add translations
        exercise_translations = []
        for j, exercise_record in enumerate(result.data):
            if j < len(batch):
                original_exercise = batch[j]
                exercise_translations.append({
                    'exercise_id': exercise_record['id'],
                    'language': 'en',
                    'name': original_exercise['name'],
                    'category': original_exercise['category'].title(),
                    'muscle_group': original_exercise['muscle_group'].title(),
                    'secondary_muscles': original_exercise.get('secondary_muscles', []),
                    'equipment': original_exercise.get('equipment', 'None'),
                    'difficulty': original_exercise.get('difficulty', 'Medium'),
                    'instructions': original_exercise.get('instructions', []),
                    'tips': original_exercise.get('tips', [])
                })
        
        if exercise_translations:
            supabase.table('exercise_translations').insert(exercise_translations).execute()
            print(f'✅ Added {len(exercise_translations)} exercise translations')
            
    except Exception as e:
        print(f'❌ Error exercise batch {i//batch_size + 1}: {e}')
    
    time.sleep(0.2)

# Import recipes
print(f'🍳 Starting import of {len(RECIPES_DATASET)} recipes...')
batch_size = 25
total_recipes = 0

for i in range(0, len(RECIPES_DATASET), batch_size):
    batch = RECIPES_DATASET[i:i + batch_size]
    
    recipes_data = []
    for recipe in batch:
        recipes_data.append({
            'prep_time_minutes': recipe.get('prep_time_minutes', 15),
            'cook_time_minutes': recipe.get('cook_time_minutes', 20),
            'servings': recipe.get('servings', 4),
            'calories_per_serving': recipe.get('calories_per_serving', 300),
            'protein_per_serving': recipe.get('protein_per_serving', 15),
            'carbs_per_serving': recipe.get('carbs_per_serving', 30),
            'fat_per_serving': recipe.get('fat_per_serving', 10),
            'fiber_per_serving': recipe.get('fiber_per_serving', 5),
            'is_public': True
        })
    
    try:
        result = supabase.table('recipes').insert(recipes_data).execute()
        batch_count = len(result.data)
        total_recipes += batch_count
        print(f'✅ Recipe Batch {i//batch_size + 1}: {batch_count} recipes imported (Total: {total_recipes})')
        
        # Add translations and ingredients
        recipe_translations = []
        recipe_ingredients = []
        
        for j, recipe_record in enumerate(result.data):
            if j < len(batch):
                original_recipe = batch[j]
                
                # Add translation
                recipe_translations.append({
                    'recipe_id': recipe_record['id'],
                    'language': 'en',
                    'name': original_recipe['name'],
                    'description': original_recipe.get('description', ''),
                    'category': original_recipe.get('category', 'Main Course'),
                    'cuisine': original_recipe.get('cuisine', 'International'),
                    'difficulty': original_recipe.get('difficulty', 'Medium'),
                    'instructions': original_recipe.get('instructions', []),
                    'tags': original_recipe.get('tags', [])
                })
                
                # Add ingredients
                for ingredient in original_recipe.get('ingredients', []):
                    recipe_ingredients.append({
                        'recipe_id': recipe_record['id'],
                        'food_name': ingredient.get('name', 'Unknown'),
                        'quantity': ingredient.get('quantity', 100),
                        'unit': ingredient.get('unit', 'g')
                    })
        
        # Insert translations and ingredients
        if recipe_translations:
            supabase.table('recipe_translations').insert(recipe_translations).execute()
            print(f'✅ Added {len(recipe_translations)} recipe translations')
        
        if recipe_ingredients:
            supabase.table('recipe_ingredients').insert(recipe_ingredients).execute()
            print(f'✅ Added {len(recipe_ingredients)} recipe ingredients')
            
    except Exception as e:
        print(f'❌ Error recipe batch {i//batch_size + 1}: {e}')
    
    time.sleep(0.2)

print(f'🎉 COMPLETED!')
print(f'   - Exercises imported: {total_exercises}')
print(f'   - Recipes imported: {total_recipes}')

# Verify final counts
exercises_count = supabase.table('exercises').select('id', count='exact').execute()
recipes_count = supabase.table('recipes').select('id', count='exact').execute()
exercise_translations_count = supabase.table('exercise_translations').select('id', count='exact').execute()
recipe_translations_count = supabase.table('recipe_translations').select('id', count='exact').execute()

print(f'📊 Final verification:')
print(f'   - Exercises in database: {exercises_count.count}')
print(f'   - Recipes in database: {recipes_count.count}')
print(f'   - Exercise translations: {exercise_translations_count.count}')
print(f'   - Recipe translations: {recipe_translations_count.count}') 