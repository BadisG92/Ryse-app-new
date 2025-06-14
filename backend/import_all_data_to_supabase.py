#!/usr/bin/env python3
"""
Complete Data Import Script for Ryze App
Imports all foods, exercises, and recipes to Supabase with multilingual support
"""

import os
import sys
from supabase import create_client, Client
from typing import List, Dict, Any
import time

# Add the data directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), 'data'))

# Import datasets
from foods_dataset import FOODS_DATASET
from exercises_dataset import EXERCISES_DATASET
from recipes_dataset import RECIPES_DATASET

# Supabase configuration
SUPABASE_URL = "https://mfskwlzgxjhhknlwpblq.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo"  # Anon key

def create_supabase_client() -> Client:
    """Create Supabase client"""
    return create_client(SUPABASE_URL, SUPABASE_KEY)

def import_foods_batch(supabase: Client, foods_batch: List[Dict], batch_size: int = 50):
    """Import foods in batches"""
    print(f"Importing {len(foods_batch)} foods...")
    
    for i in range(0, len(foods_batch), batch_size):
        batch = foods_batch[i:i + batch_size]
        
        # Prepare foods data for Supabase
        foods_data = []
        for food in batch:
            foods_data.append({
                'name': food['name'],
                'calories_per_100g': food['calories_per_100g'],
                'protein_per_100g': food['protein_per_100g'],
                'carbs_per_100g': food['carbs_per_100g'],
                'fat_per_100g': food['fat_per_100g'],
                'fiber_per_100g': food.get('fiber_per_100g', 0),
                'sugar_per_100g': food.get('sugar_per_100g', 0),
                'sodium_per_100g': food.get('sodium_per_100g', 0),
                'serving_size': food.get('serving_size', 100),
                'brand': food.get('brand'),
                'barcode': food.get('barcode'),
                'is_custom': False
            })
        
        try:
            # Insert foods
            result = supabase.table('foods').insert(foods_data).execute()
            print(f"✅ Imported batch {i//batch_size + 1}: {len(batch)} foods")
            
            # Add basic English translations
            food_translations = []
            for j, food_record in enumerate(result.data):
                original_food = batch[j]
                food_translations.append({
                    'food_id': food_record['id'],
                    'language': 'en',
                    'name': original_food['name'],
                    'category': original_food.get('category', 'Other'),
                    'serving_unit': original_food.get('serving_unit', 'g')
                })
            
            # Insert translations
            supabase.table('food_translations').insert(food_translations).execute()
            print(f"✅ Added translations for batch {i//batch_size + 1}")
            
        except Exception as e:
            print(f"❌ Error importing foods batch {i//batch_size + 1}: {e}")
        
        time.sleep(0.1)  # Rate limiting

def import_exercises_batch(supabase: Client, exercises_batch: List[Dict], batch_size: int = 30):
    """Import exercises in batches"""
    print(f"Importing {len(exercises_batch)} exercises...")
    
    for i in range(0, len(exercises_batch), batch_size):
        batch = exercises_batch[i:i + batch_size]
        
        # Prepare exercises data for Supabase
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
            # Insert exercises
            result = supabase.table('exercises').insert(exercises_data).execute()
            print(f"✅ Imported batch {i//batch_size + 1}: {len(batch)} exercises")
            
            # Add English translations
            exercise_translations = []
            for j, exercise_record in enumerate(result.data):
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
            
            # Insert translations
            supabase.table('exercise_translations').insert(exercise_translations).execute()
            print(f"✅ Added translations for batch {i//batch_size + 1}")
            
        except Exception as e:
            print(f"❌ Error importing exercises batch {i//batch_size + 1}: {e}")
        
        time.sleep(0.1)  # Rate limiting

def import_recipes_batch(supabase: Client, recipes_batch: List[Dict], batch_size: int = 20):
    """Import recipes in batches"""
    print(f"Importing {len(recipes_batch)} recipes...")
    
    for i in range(0, len(recipes_batch), batch_size):
        batch = recipes_batch[i:i + batch_size]
        
        # Prepare recipes data for Supabase
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
            # Insert recipes
            result = supabase.table('recipes').insert(recipes_data).execute()
            print(f"✅ Imported batch {i//batch_size + 1}: {len(batch)} recipes")
            
            # Add English translations and ingredients
            recipe_translations = []
            recipe_ingredients = []
            
            for j, recipe_record in enumerate(result.data):
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
            if recipe_ingredients:
                supabase.table('recipe_ingredients').insert(recipe_ingredients).execute()
            
            print(f"✅ Added translations and ingredients for batch {i//batch_size + 1}")
            
        except Exception as e:
            print(f"❌ Error importing recipes batch {i//batch_size + 1}: {e}")
        
        time.sleep(0.1)  # Rate limiting

def main():
    """Main import function"""
    print("🚀 Starting complete data import to Supabase...")
    print(f"📊 Data to import:")
    print(f"   - Foods: {len(FOODS_DATASET)}")
    print(f"   - Exercises: {len(EXERCISES_DATASET)}")
    print(f"   - Recipes: {len(RECIPES_DATASET)}")
    print()
    
    # Create Supabase client
    supabase = create_supabase_client()
    
    try:
        # Import foods
        print("🍎 IMPORTING FOODS...")
        import_foods_batch(supabase, FOODS_DATASET)
        print(f"✅ Completed importing {len(FOODS_DATASET)} foods\n")
        
        # Import exercises
        print("💪 IMPORTING EXERCISES...")
        import_exercises_batch(supabase, EXERCISES_DATASET)
        print(f"✅ Completed importing {len(EXERCISES_DATASET)} exercises\n")
        
        # Import recipes
        print("🍳 IMPORTING RECIPES...")
        import_recipes_batch(supabase, RECIPES_DATASET)
        print(f"✅ Completed importing {len(RECIPES_DATASET)} recipes\n")
        
        print("🎉 ALL DATA IMPORTED SUCCESSFULLY!")
        print("\n📈 Final Summary:")
        
        # Get final counts
        foods_count = supabase.table('foods').select('id', count='exact').execute()
        exercises_count = supabase.table('exercises').select('id', count='exact').execute()
        recipes_count = supabase.table('recipes').select('id', count='exact').execute()
        
        print(f"   - Total Foods in DB: {foods_count.count}")
        print(f"   - Total Exercises in DB: {exercises_count.count}")
        print(f"   - Total Recipes in DB: {recipes_count.count}")
        
    except Exception as e:
        print(f"❌ Import failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 