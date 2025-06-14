#!/usr/bin/env python3
"""
Complete Dataset Import Script for Ryze App
Imports 1000+ foods, all exercises, and all recipes to Supabase with multilingual support
"""

import os
import sys
from supabase import create_client, Client
from typing import List, Dict, Any
import time

# Add the data directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), 'data'))

# Import datasets
from foods_dataset import generate_complete_foods_dataset
from exercises_dataset import EXERCISES_DATASET
from recipes_dataset import RECIPES_DATASET

# Supabase configuration
SUPABASE_URL = "https://mfskwlzgxjhhknlwpblq.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo"

def create_supabase_client() -> Client:
    """Create Supabase client"""
    return create_client(SUPABASE_URL, SUPABASE_KEY)

def clear_existing_data(supabase: Client):
    """Clear existing data to avoid duplicates"""
    print("🧹 Clearing existing data...")
    
    try:
        # Clear in reverse order due to foreign key constraints
        supabase.table('recipe_ingredients').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
        supabase.table('recipe_translations').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
        supabase.table('exercise_translations').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
        supabase.table('food_translations').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
        
        supabase.table('recipes').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
        supabase.table('exercises').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
        supabase.table('foods').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
        
        print("✅ Existing data cleared")
    except Exception as e:
        print(f"⚠️ Warning clearing data: {e}")

def import_foods_complete(supabase: Client, foods_dataset: List[Dict], batch_size: int = 100):
    """Import complete foods dataset in batches"""
    print(f"🍎 Importing {len(foods_dataset)} foods...")
    
    total_imported = 0
    for i in range(0, len(foods_dataset), batch_size):
        batch = foods_dataset[i:i + batch_size]
        
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
            batch_count = len(result.data)
            total_imported += batch_count
            
            print(f"✅ Batch {i//batch_size + 1}: {batch_count} foods imported (Total: {total_imported})")
            
            # Add basic English translations
            food_translations = []
            for j, food_record in enumerate(result.data):
                if j < len(batch):  # Safety check
                    original_food = batch[j]
                    food_translations.append({
                        'food_id': food_record['id'],
                        'language': 'en',
                        'name': original_food['name'],
                        'category': original_food.get('category', 'Other').title(),
                        'serving_unit': original_food.get('serving_unit', 'g')
                    })
            
            # Insert translations
            if food_translations:
                supabase.table('food_translations').insert(food_translations).execute()
                print(f"✅ Added {len(food_translations)} translations for batch {i//batch_size + 1}")
            
        except Exception as e:
            print(f"❌ Error importing foods batch {i//batch_size + 1}: {e}")
        
        time.sleep(0.2)  # Rate limiting
    
    print(f"🎉 Completed importing {total_imported} foods!")
    return total_imported

def import_exercises_complete(supabase: Client, exercises_dataset: List[Dict], batch_size: int = 50):
    """Import complete exercises dataset in batches"""
    print(f"💪 Importing {len(exercises_dataset)} exercises...")
    
    total_imported = 0
    for i in range(0, len(exercises_dataset), batch_size):
        batch = exercises_dataset[i:i + batch_size]
        
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
            batch_count = len(result.data)
            total_imported += batch_count
            
            print(f"✅ Batch {i//batch_size + 1}: {batch_count} exercises imported (Total: {total_imported})")
            
            # Add English translations
            exercise_translations = []
            for j, exercise_record in enumerate(result.data):
                if j < len(batch):  # Safety check
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
            if exercise_translations:
                supabase.table('exercise_translations').insert(exercise_translations).execute()
                print(f"✅ Added {len(exercise_translations)} translations for batch {i//batch_size + 1}")
            
        except Exception as e:
            print(f"❌ Error importing exercises batch {i//batch_size + 1}: {e}")
        
        time.sleep(0.2)  # Rate limiting
    
    print(f"🎉 Completed importing {total_imported} exercises!")
    return total_imported

def import_recipes_complete(supabase: Client, recipes_dataset: List[Dict], batch_size: int = 25):
    """Import complete recipes dataset in batches"""
    print(f"🍳 Importing {len(recipes_dataset)} recipes...")
    
    total_imported = 0
    for i in range(0, len(recipes_dataset), batch_size):
        batch = recipes_dataset[i:i + batch_size]
        
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
            batch_count = len(result.data)
            total_imported += batch_count
            
            print(f"✅ Batch {i//batch_size + 1}: {batch_count} recipes imported (Total: {total_imported})")
            
            # Add English translations and ingredients
            recipe_translations = []
            recipe_ingredients = []
            
            for j, recipe_record in enumerate(result.data):
                if j < len(batch):  # Safety check
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
                print(f"✅ Added {len(recipe_translations)} translations for batch {i//batch_size + 1}")
            
            if recipe_ingredients:
                supabase.table('recipe_ingredients').insert(recipe_ingredients).execute()
                print(f"✅ Added {len(recipe_ingredients)} ingredients for batch {i//batch_size + 1}")
            
        except Exception as e:
            print(f"❌ Error importing recipes batch {i//batch_size + 1}: {e}")
        
        time.sleep(0.2)  # Rate limiting
    
    print(f"🎉 Completed importing {total_imported} recipes!")
    return total_imported

def main():
    """Main import function"""
    print("🚀 Starting COMPLETE dataset import to Supabase...")
    
    # Generate complete datasets
    print("📊 Generating complete datasets...")
    complete_foods = generate_complete_foods_dataset()
    
    print(f"📊 Data to import:")
    print(f"   - Foods: {len(complete_foods)}")
    print(f"   - Exercises: {len(EXERCISES_DATASET)}")
    print(f"   - Recipes: {len(RECIPES_DATASET)}")
    print()
    
    # Create Supabase client
    supabase = create_supabase_client()
    
    try:
        # Clear existing data
        clear_existing_data(supabase)
        
        # Import complete foods dataset
        foods_imported = import_foods_complete(supabase, complete_foods)
        
        # Import exercises
        exercises_imported = import_exercises_complete(supabase, EXERCISES_DATASET)
        
        # Import recipes
        recipes_imported = import_recipes_complete(supabase, RECIPES_DATASET)
        
        print("\n🎉 COMPLETE DATASET IMPORTED SUCCESSFULLY!")
        print("\n📈 Final Summary:")
        print(f"   - Foods imported: {foods_imported}")
        print(f"   - Exercises imported: {exercises_imported}")
        print(f"   - Recipes imported: {recipes_imported}")
        
        # Verify final counts
        foods_count = supabase.table('foods').select('id', count='exact').execute()
        exercises_count = supabase.table('exercises').select('id', count='exact').execute()
        recipes_count = supabase.table('recipes').select('id', count='exact').execute()
        
        print(f"\n📊 Database verification:")
        print(f"   - Total Foods in DB: {foods_count.count}")
        print(f"   - Total Exercises in DB: {exercises_count.count}")
        print(f"   - Total Recipes in DB: {recipes_count.count}")
        
        print(f"\n🌍 Multilingual support:")
        food_translations = supabase.table('food_translations').select('id', count='exact').execute()
        exercise_translations = supabase.table('exercise_translations').select('id', count='exact').execute()
        recipe_translations = supabase.table('recipe_translations').select('id', count='exact').execute()
        
        print(f"   - Food translations: {food_translations.count}")
        print(f"   - Exercise translations: {exercise_translations.count}")
        print(f"   - Recipe translations: {recipe_translations.count}")
        
    except Exception as e:
        print(f"❌ Import failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main() 