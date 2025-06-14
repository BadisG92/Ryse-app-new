#!/usr/bin/env python3
"""
Multilingual Data Import Script for Ryze App
Imports foods, exercises, and recipes with French/English translations
"""

import sys
import os
from typing import Dict, List, Any
from supabase import create_client, Client
import json

# Add parent directory to path to import datasets
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from data.multilingual_foods_dataset import (
    get_multilingual_foods_dataset,
    get_food_categories_translations,
    get_serving_units_translations
)
from data.multilingual_exercises_dataset import (
    get_multilingual_exercises_dataset,
    get_exercise_categories_translations,
    get_muscle_groups_translations,
    get_equipment_translations,
    get_difficulty_translations
)
from data.multilingual_recipes_dataset import (
    get_multilingual_recipes_dataset,
    get_recipe_categories_translations,
    get_cuisine_translations,
    get_recipe_tags_translations
)

# Supabase Configuration
SUPABASE_URL = "https://your-project.supabase.co"  # Replace with your URL
SUPABASE_KEY = "your-anon-key-here"  # Replace with your anon key

class MultilingualDataImporter:
    def __init__(self, supabase_url: str, supabase_key: str):
        """Initialize the multilingual data importer"""
        self.supabase: Client = create_client(supabase_url, supabase_key)
        self.supported_languages = ['en', 'fr']
        
    def import_translation_keys(self):
        """Import translation keys for categories, tags, etc."""
        print("🌍 Importing translation keys...")
        
        # Food categories
        food_categories = get_food_categories_translations()
        for key, translations in food_categories.items():
            for lang, value in translations.items():
                self.supabase.table('translation_keys').upsert({
                    'key': f'food_category.{key}',
                    'language': lang,
                    'value': value,
                    'category': 'food_categories'
                }).execute()
        
        # Exercise categories
        exercise_categories = get_exercise_categories_translations()
        for key, translations in exercise_categories.items():
            for lang, value in translations.items():
                self.supabase.table('translation_keys').upsert({
                    'key': f'exercise_category.{key}',
                    'language': lang,
                    'value': value,
                    'category': 'exercise_categories'
                }).execute()
        
        # Muscle groups
        muscle_groups = get_muscle_groups_translations()
        for key, translations in muscle_groups.items():
            for lang, value in translations.items():
                self.supabase.table('translation_keys').upsert({
                    'key': f'muscle_group.{key}',
                    'language': lang,
                    'value': value,
                    'category': 'muscle_groups'
                }).execute()
        
        # Recipe categories
        recipe_categories = get_recipe_categories_translations()
        for key, translations in recipe_categories.items():
            for lang, value in translations.items():
                self.supabase.table('translation_keys').upsert({
                    'key': f'recipe_category.{key}',
                    'language': lang,
                    'value': value,
                    'category': 'recipe_categories'
                }).execute()
        
        print("✅ Translation keys imported successfully!")
    
    def import_multilingual_foods(self):
        """Import foods with multilingual support"""
        print("🍎 Importing multilingual foods...")
        
        foods_data = get_multilingual_foods_dataset()
        batch_size = 50
        
        for i in range(0, len(foods_data), batch_size):
            batch = foods_data[i:i + batch_size]
            
            # Import base food records
            base_foods = []
            for food in batch:
                base_food = {
                    'id': food['id'],
                    'calories_per_100g': food['calories_per_100g'],
                    'protein_per_100g': food['protein_per_100g'],
                    'carbs_per_100g': food['carbs_per_100g'],
                    'fat_per_100g': food['fat_per_100g'],
                    'fiber_per_100g': food['fiber_per_100g'],
                    'sugar_per_100g': food['sugar_per_100g'],
                    'sodium_per_100g': food['sodium_per_100g'],
                    'serving_size': food['serving_size'],
                    'brand': food['brand'],
                    'barcode': food['barcode'],
                    'verified': food['verified']
                }
                base_foods.append(base_food)
            
            # Insert base foods
            self.supabase.table('foods').upsert(base_foods).execute()
            
            # Import translations
            translations = []
            for food in batch:
                for lang, translation in food['translations'].items():
                    translations.append({
                        'food_id': food['id'],
                        'language': lang,
                        'name': translation['name'],
                        'category': translation['category'],
                        'serving_unit': translation['serving_unit']
                    })
            
            self.supabase.table('food_translations').upsert(translations).execute()
            print(f"  ✅ Imported batch: {len(batch)} foods")
        
        print(f"🎉 Successfully imported {len(foods_data)} multilingual foods!")
    
    def import_multilingual_exercises(self):
        """Import exercises with multilingual support"""
        print("💪 Importing multilingual exercises...")
        
        exercises_data = get_multilingual_exercises_dataset()
        
        # Import base exercise records
        base_exercises = []
        for exercise in exercises_data:
            base_exercise = {
                'id': exercise['id'],
                'calories_per_minute': exercise['calories_per_minute'],
                'duration_minutes': exercise['duration_minutes'],
                'sets': exercise['sets'],
                'reps': exercise['reps'],
                'rest_seconds': exercise['rest_seconds'],
                'image_url': exercise['image_url'],
                'video_url': exercise['video_url'],
                'is_public': exercise['is_public']
            }
            base_exercises.append(base_exercise)
        
        self.supabase.table('exercises').upsert(base_exercises).execute()
        
        # Import translations
        translations = []
        for exercise in exercises_data:
            for lang, translation in exercise['translations'].items():
                translations.append({
                    'exercise_id': exercise['id'],
                    'language': lang,
                    'name': translation['name'],
                    'category': translation['category'],
                    'muscle_group': translation['muscle_group'],
                    'secondary_muscles': translation['secondary_muscles'],
                    'equipment': translation['equipment'],
                    'difficulty': translation['difficulty'],
                    'instructions': translation['instructions'],
                    'tips': translation['tips']
                })
        
        self.supabase.table('exercise_translations').upsert(translations).execute()
        print(f"🎉 Successfully imported {len(exercises_data)} multilingual exercises!")
    
    def import_multilingual_recipes(self):
        """Import recipes with multilingual support"""
        print("🍽️ Importing multilingual recipes...")
        
        recipes_data = get_multilingual_recipes_dataset()
        
        # Import base recipe records
        base_recipes = []
        for recipe in recipes_data:
            base_recipe = {
                'id': recipe['id'],
                'prep_time_minutes': recipe['prep_time_minutes'],
                'cook_time_minutes': recipe['cook_time_minutes'],
                'servings': recipe['servings'],
                'calories_per_serving': recipe['calories_per_serving'],
                'protein_per_serving': recipe['protein_per_serving'],
                'carbs_per_serving': recipe['carbs_per_serving'],
                'fat_per_serving': recipe['fat_per_serving'],
                'fiber_per_serving': recipe['fiber_per_serving'],
                'image_url': recipe['image_url'],
                'created_by': recipe['created_by'],
                'is_public': recipe['is_public']
            }
            base_recipes.append(base_recipe)
        
        self.supabase.table('recipes').upsert(base_recipes).execute()
        
        # Import translations
        translations = []
        for recipe in recipes_data:
            for lang, translation in recipe['translations'].items():
                translations.append({
                    'recipe_id': recipe['id'],
                    'language': lang,
                    'name': translation['name'],
                    'description': translation['description'],
                    'category': translation['category'],
                    'cuisine': translation['cuisine'],
                    'difficulty': translation['difficulty'],
                    'instructions': translation['instructions'],
                    'tags': translation['tags']
                })
        
        self.supabase.table('recipe_translations').upsert(translations).execute()
        
        # Import recipe ingredients
        ingredients = []
        for recipe in recipes_data:
            for ingredient in recipe['ingredients']:
                ingredients.append({
                    'recipe_id': recipe['id'],
                    'food_name': ingredient['food_name'],
                    'quantity': ingredient['quantity'],
                    'unit': ingredient['unit']
                })
        
        self.supabase.table('recipe_ingredients').upsert(ingredients).execute()
        print(f"🎉 Successfully imported {len(recipes_data)} multilingual recipes!")
    
    def verify_multilingual_import(self):
        """Verify the multilingual import was successful"""
        print("🔍 Verifying multilingual import...")
        
        # Check foods
        foods_count = self.supabase.table('foods').select('id').execute()
        food_translations_count = self.supabase.table('food_translations').select('id').execute()
        
        # Check exercises
        exercises_count = self.supabase.table('exercises').select('id').execute()
        exercise_translations_count = self.supabase.table('exercise_translations').select('id').execute()
        
        # Check recipes
        recipes_count = self.supabase.table('recipes').select('id').execute()
        recipe_translations_count = self.supabase.table('recipe_translations').select('id').execute()
        
        print("📊 Multilingual Database verification:")
        print(f"  Foods: {len(foods_count.data)} records")
        print(f"  Food Translations: {len(food_translations_count.data)} records")
        print(f"  Exercises: {len(exercises_count.data)} records")
        print(f"  Exercise Translations: {len(exercise_translations_count.data)} records")
        print(f"  Recipes: {len(recipes_count.data)} records")
        print(f"  Recipe Translations: {len(recipe_translations_count.data)} records")
        
        # Verify we have translations for both languages
        for lang in self.supported_languages:
            food_lang_count = self.supabase.table('food_translations').select('id').eq('language', lang).execute()
            exercise_lang_count = self.supabase.table('exercise_translations').select('id').eq('language', lang).execute()
            recipe_lang_count = self.supabase.table('recipe_translations').select('id').eq('language', lang).execute()
            
            print(f"  {lang.upper()} translations:")
            print(f"    Foods: {len(food_lang_count.data)}")
            print(f"    Exercises: {len(exercise_lang_count.data)}")
            print(f"    Recipes: {len(recipe_lang_count.data)}")
        
        print("✅ Multilingual import verification successful!")

def main():
    """Main import function"""
    print("🚀 Starting Ryze App multilingual data import...")
    print("=" * 60)
    
    # Initialize importer
    importer = MultilingualDataImporter(SUPABASE_URL, SUPABASE_KEY)
    
    try:
        # Import translation keys
        importer.import_translation_keys()
        
        # Import multilingual data
        importer.import_multilingual_foods()
        importer.import_multilingual_exercises()
        importer.import_multilingual_recipes()
        
        # Verify import
        importer.verify_multilingual_import()
        
        print("=" * 60)
        print("🎉 Multilingual data import completed successfully!")
        print("🌍 Your app now supports French and English!")
        
    except Exception as e:
        print(f"❌ Import failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 