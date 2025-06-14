#!/usr/bin/env python3
"""
Data Import Script for Ryze App
Imports foods, recipes, and exercises into Supabase database
"""

import os
import sys
import asyncio
from datetime import datetime
from typing import List, Dict, Any

# Add the parent directory to the path to import our modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from supabase import create_client, Client
from data.foods_dataset import generate_complete_foods_dataset
from data.recipes_dataset import get_recipes_dataset
from data.exercises_dataset import get_exercises_dataset

# Supabase configuration
SUPABASE_URL = "YOUR_SUPABASE_URL"  # Replace with your actual URL
SUPABASE_KEY = "YOUR_SUPABASE_ANON_KEY"  # Replace with your actual key

class DataImporter:
    def __init__(self, supabase_url: str, supabase_key: str):
        self.supabase: Client = create_client(supabase_url, supabase_key)
        self.imported_counts = {
            'foods': 0,
            'recipes': 0,
            'exercises': 0,
            'recipe_ingredients': 0
        }
    
    async def import_foods(self) -> bool:
        """Import foods dataset into the database"""
        print("🍎 Starting foods import...")
        
        try:
            foods_data = generate_complete_foods_dataset()
            
            # Process foods in batches to avoid API limits
            batch_size = 100
            total_foods = len(foods_data)
            
            for i in range(0, total_foods, batch_size):
                batch = foods_data[i:i + batch_size]
                
                # Prepare data for Supabase
                foods_batch = []
                for food in batch:
                    food_record = {
                        'name': food['name'],
                        'brand': food.get('brand'),
                        'barcode': food.get('barcode'),
                        'calories_per_100g': food['calories_per_100g'],
                        'protein_per_100g': food['protein_per_100g'],
                        'carbs_per_100g': food['carbs_per_100g'],
                        'fat_per_100g': food['fat_per_100g'],
                        'fiber_per_100g': food.get('fiber_per_100g', 0),
                        'sugar_per_100g': food.get('sugar_per_100g', 0),
                        'sodium_per_100g': food.get('sodium_per_100g', 0),
                        'category': food['category'],
                        'serving_size': food.get('serving_size', 100),
                        'serving_unit': food.get('serving_unit', 'g'),
                        'verified': food.get('verified', True),
                        'created_at': datetime.now().isoformat(),
                        'updated_at': datetime.now().isoformat()
                    }
                    foods_batch.append(food_record)
                
                # Insert batch into Supabase
                result = self.supabase.table('foods').insert(foods_batch).execute()
                
                if result.data:
                    batch_count = len(result.data)
                    self.imported_counts['foods'] += batch_count
                    print(f"  ✅ Imported batch {i//batch_size + 1}: {batch_count} foods")
                else:
                    print(f"  ❌ Failed to import batch {i//batch_size + 1}")
                    return False
            
            print(f"🎉 Successfully imported {self.imported_counts['foods']} foods!")
            return True
            
        except Exception as e:
            print(f"❌ Error importing foods: {str(e)}")
            return False
    
    async def import_exercises(self) -> bool:
        """Import exercises dataset into the database"""
        print("💪 Starting exercises import...")
        
        try:
            exercises_data = get_exercises_dataset()
            
            # Prepare data for Supabase
            exercises_batch = []
            for exercise in exercises_data:
                exercise_record = {
                    'name': exercise['name'],
                    'category': exercise['category'],
                    'muscle_group': exercise['muscle_group'],
                    'secondary_muscles': exercise.get('secondary_muscles', []),
                    'equipment': exercise['equipment'],
                    'difficulty': exercise['difficulty'],
                    'instructions': exercise['instructions'],
                    'tips': exercise.get('tips', []),
                    'calories_per_minute': exercise.get('calories_per_minute', 5),
                    'duration_minutes': exercise.get('duration_minutes', 1),
                    'sets': exercise.get('sets', 3),
                    'reps': exercise.get('reps', 10),
                    'rest_seconds': exercise.get('rest_seconds', 60),
                    'image_url': exercise.get('image_url'),
                    'video_url': exercise.get('video_url'),
                    'is_public': exercise.get('is_public', True),
                    'created_at': datetime.now().isoformat(),
                    'updated_at': datetime.now().isoformat()
                }
                exercises_batch.append(exercise_record)
            
            # Insert all exercises
            result = self.supabase.table('exercises').insert(exercises_batch).execute()
            
            if result.data:
                self.imported_counts['exercises'] = len(result.data)
                print(f"🎉 Successfully imported {self.imported_counts['exercises']} exercises!")
                return True
            else:
                print("❌ Failed to import exercises")
                return False
                
        except Exception as e:
            print(f"❌ Error importing exercises: {str(e)}")
            return False
    
    async def import_recipes(self) -> bool:
        """Import recipes dataset into the database"""
        print("🍽️ Starting recipes import...")
        
        try:
            recipes_data = get_recipes_dataset()
            
            for recipe in recipes_data:
                # First, insert the recipe
                recipe_record = {
                    'name': recipe['name'],
                    'description': recipe['description'],
                    'category': recipe['category'],
                    'cuisine': recipe.get('cuisine'),
                    'prep_time_minutes': recipe['prep_time_minutes'],
                    'cook_time_minutes': recipe['cook_time_minutes'],
                    'servings': recipe['servings'],
                    'difficulty': recipe['difficulty'],
                    'calories_per_serving': recipe['calories_per_serving'],
                    'protein_per_serving': recipe['protein_per_serving'],
                    'carbs_per_serving': recipe['carbs_per_serving'],
                    'fat_per_serving': recipe['fat_per_serving'],
                    'fiber_per_serving': recipe.get('fiber_per_serving', 0),
                    'instructions': recipe['instructions'],
                    'tags': recipe.get('tags', []),
                    'image_url': recipe.get('image_url'),
                    'created_by': recipe.get('created_by', 'admin'),
                    'is_public': recipe.get('is_public', True),
                    'created_at': datetime.now().isoformat(),
                    'updated_at': datetime.now().isoformat()
                }
                
                # Insert recipe
                recipe_result = self.supabase.table('recipes').insert(recipe_record).execute()
                
                if recipe_result.data:
                    recipe_id = recipe_result.data[0]['id']
                    self.imported_counts['recipes'] += 1
                    
                    # Now insert recipe ingredients
                    ingredients_batch = []
                    for ingredient in recipe['ingredients']:
                        # Find the food ID by name
                        food_result = self.supabase.table('foods').select('id').eq('name', ingredient['food_name']).execute()
                        
                        if food_result.data:
                            food_id = food_result.data[0]['id']
                            ingredient_record = {
                                'recipe_id': recipe_id,
                                'food_id': food_id,
                                'quantity': ingredient['quantity'],
                                'unit': ingredient['unit'],
                                'created_at': datetime.now().isoformat()
                            }
                            ingredients_batch.append(ingredient_record)
                        else:
                            print(f"  ⚠️ Food '{ingredient['food_name']}' not found for recipe '{recipe['name']}'")
                    
                    # Insert ingredients
                    if ingredients_batch:
                        ingredients_result = self.supabase.table('recipe_ingredients').insert(ingredients_batch).execute()
                        if ingredients_result.data:
                            self.imported_counts['recipe_ingredients'] += len(ingredients_result.data)
                    
                    print(f"  ✅ Imported recipe: {recipe['name']} with {len(ingredients_batch)} ingredients")
                else:
                    print(f"  ❌ Failed to import recipe: {recipe['name']}")
            
            print(f"🎉 Successfully imported {self.imported_counts['recipes']} recipes!")
            print(f"🎉 Successfully imported {self.imported_counts['recipe_ingredients']} recipe ingredients!")
            return True
            
        except Exception as e:
            print(f"❌ Error importing recipes: {str(e)}")
            return False
    
    async def verify_import(self) -> bool:
        """Verify that data was imported correctly"""
        print("🔍 Verifying import...")
        
        try:
            # Check foods count
            foods_result = self.supabase.table('foods').select('id', count='exact').execute()
            foods_count = foods_result.count if foods_result.count else 0
            
            # Check exercises count
            exercises_result = self.supabase.table('exercises').select('id', count='exact').execute()
            exercises_count = exercises_result.count if exercises_result.count else 0
            
            # Check recipes count
            recipes_result = self.supabase.table('recipes').select('id', count='exact').execute()
            recipes_count = recipes_result.count if recipes_result.count else 0
            
            # Check recipe ingredients count
            ingredients_result = self.supabase.table('recipe_ingredients').select('id', count='exact').execute()
            ingredients_count = ingredients_result.count if ingredients_result.count else 0
            
            print(f"📊 Database verification:")
            print(f"  Foods: {foods_count} records")
            print(f"  Exercises: {exercises_count} records")
            print(f"  Recipes: {recipes_count} records")
            print(f"  Recipe Ingredients: {ingredients_count} records")
            
            # Verify minimum expected counts
            success = (
                foods_count >= 1000 and
                exercises_count >= 15 and
                recipes_count >= 10 and
                ingredients_count >= 50
            )
            
            if success:
                print("✅ Import verification successful!")
            else:
                print("❌ Import verification failed - some data may be missing")
            
            return success
            
        except Exception as e:
            print(f"❌ Error during verification: {str(e)}")
            return False
    
    async def run_full_import(self) -> bool:
        """Run the complete data import process"""
        print("🚀 Starting Ryze App data import...")
        print("=" * 50)
        
        start_time = datetime.now()
        
        # Import in order: foods first (needed for recipes), then exercises, then recipes
        success = True
        
        # 1. Import foods
        if not await self.import_foods():
            success = False
        
        # 2. Import exercises
        if success and not await self.import_exercises():
            success = False
        
        # 3. Import recipes (depends on foods)
        if success and not await self.import_recipes():
            success = False
        
        # 4. Verify import
        if success:
            success = await self.verify_import()
        
        end_time = datetime.now()
        duration = end_time - start_time
        
        print("=" * 50)
        if success:
            print("🎉 Data import completed successfully!")
            print(f"📊 Import summary:")
            print(f"  Foods: {self.imported_counts['foods']}")
            print(f"  Exercises: {self.imported_counts['exercises']}")
            print(f"  Recipes: {self.imported_counts['recipes']}")
            print(f"  Recipe Ingredients: {self.imported_counts['recipe_ingredients']}")
            print(f"⏱️ Total time: {duration}")
        else:
            print("❌ Data import failed!")
        
        return success

async def main():
    """Main function to run the data import"""
    
    # Check if Supabase credentials are configured
    if SUPABASE_URL == "YOUR_SUPABASE_URL" or SUPABASE_KEY == "YOUR_SUPABASE_ANON_KEY":
        print("❌ Please configure your Supabase credentials in this script")
        print("   Update SUPABASE_URL and SUPABASE_KEY variables")
        return False
    
    # Create importer and run
    importer = DataImporter(SUPABASE_URL, SUPABASE_KEY)
    success = await importer.run_full_import()
    
    return success

if __name__ == "__main__":
    # Run the import
    success = asyncio.run(main())
    
    if success:
        print("\n✅ Ready to use! Your Ryze App database is now populated with:")
        print("   • 1000+ food items with complete nutritional data")
        print("   • 20+ exercises for strength, cardio, and flexibility")
        print("   • 10+ healthy recipes with ingredients and instructions")
        print("\n🚀 You can now start using the Ryze App with real data!")
    else:
        print("\n❌ Import failed. Please check the errors above and try again.")
    
    sys.exit(0 if success else 1) 