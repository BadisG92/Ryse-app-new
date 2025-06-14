#!/usr/bin/env python3
"""
Test script for multilingual datasets
Verifies data integrity and translation completeness
"""

import sys
import os

# Add parent directory to path to import datasets
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from data.multilingual_foods_dataset import (
    get_multilingual_foods_dataset,
    get_food_categories_translations
)
from data.multilingual_exercises_dataset import (
    get_multilingual_exercises_dataset,
    get_exercise_categories_translations
)
from data.multilingual_recipes_dataset import (
    get_multilingual_recipes_dataset,
    get_recipe_categories_translations
)

def test_foods_dataset():
    """Test multilingual foods dataset"""
    print("🍎 Testing Foods Dataset...")
    
    foods = get_multilingual_foods_dataset()
    categories = get_food_categories_translations()
    
    print(f"  📊 Total foods: {len(foods)}")
    print(f"  📊 Categories: {len(categories)}")
    
    # Test data integrity
    errors = []
    
    for food in foods:
        # Check required fields
        if not food.get('id'):
            errors.append(f"Food missing ID: {food}")
        
        if not food.get('translations'):
            errors.append(f"Food {food.get('id')} missing translations")
            continue
            
        # Check both languages
        for lang in ['en', 'fr']:
            if lang not in food['translations']:
                errors.append(f"Food {food['id']} missing {lang} translation")
                continue
                
            translation = food['translations'][lang]
            required_fields = ['name', 'category', 'serving_unit']
            
            for field in required_fields:
                if not translation.get(field):
                    errors.append(f"Food {food['id']} {lang} missing {field}")
    
    if errors:
        print("  ❌ Errors found:")
        for error in errors[:3]:
            print(f"    - {error}")
        return False
    else:
        print("  ✅ Foods dataset validation passed!")
        return True

def test_exercises_dataset():
    """Test multilingual exercises dataset"""
    print("💪 Testing Exercises Dataset...")
    
    exercises = get_multilingual_exercises_dataset()
    categories = get_exercise_categories_translations()
    
    print(f"  📊 Total exercises: {len(exercises)}")
    print(f"  📊 Categories: {len(categories)}")
    
    # Test data integrity
    errors = []
    
    for exercise in exercises:
        # Check required fields
        if not exercise.get('id'):
            errors.append(f"Exercise missing ID: {exercise}")
        
        if not exercise.get('translations'):
            errors.append(f"Exercise {exercise.get('id')} missing translations")
            continue
            
        # Check both languages
        for lang in ['en', 'fr']:
            if lang not in exercise['translations']:
                errors.append(f"Exercise {exercise['id']} missing {lang} translation")
                continue
                
            translation = exercise['translations'][lang]
            required_fields = [
                'name', 'category', 'muscle_group', 'equipment', 
                'difficulty', 'instructions'
            ]
            
            for field in required_fields:
                if not translation.get(field):
                    errors.append(f"Exercise {exercise['id']} {lang} missing {field}")
                elif field == 'instructions' and not isinstance(translation[field], list):
                    errors.append(f"Exercise {exercise['id']} {lang} instructions must be a list")
        
        # Check metrics
        metric_fields = ['calories_per_minute', 'duration_minutes', 'sets', 'reps']
        
        for field in metric_fields:
            if exercise.get(field) is None:
                errors.append(f"Exercise {exercise['id']} missing {field}")
    
    if errors:
        print("  ❌ Errors found:")
        for error in errors[:3]:
            print(f"    - {error}")
        return False
    else:
        print("  ✅ Exercises dataset validation passed!")
        return True

def test_recipes_dataset():
    """Test multilingual recipes dataset"""
    print("🍽️ Testing Recipes Dataset...")
    
    recipes = get_multilingual_recipes_dataset()
    categories = get_recipe_categories_translations()
    
    print(f"  📊 Total recipes: {len(recipes)}")
    print(f"  📊 Categories: {len(categories)}")
    
    # Test data integrity
    errors = []
    
    for recipe in recipes:
        # Check required fields
        if not recipe.get('id'):
            errors.append(f"Recipe missing ID: {recipe}")
        
        if not recipe.get('translations'):
            errors.append(f"Recipe {recipe.get('id')} missing translations")
            continue
            
        # Check both languages
        for lang in ['en', 'fr']:
            if lang not in recipe['translations']:
                errors.append(f"Recipe {recipe['id']} missing {lang} translation")
                continue
                
            translation = recipe['translations'][lang]
            required_fields = [
                'name', 'description', 'category', 'difficulty', 'instructions'
            ]
            
            for field in required_fields:
                if not translation.get(field):
                    errors.append(f"Recipe {recipe['id']} {lang} missing {field}")
                elif field == 'instructions' and not isinstance(translation[field], list):
                    errors.append(f"Recipe {recipe['id']} {lang} instructions must be a list")
        
        # Check nutritional data
        nutritional_fields = [
            'prep_time_minutes', 'cook_time_minutes', 'servings',
            'calories_per_serving', 'protein_per_serving'
        ]
        
        for field in nutritional_fields:
            if recipe.get(field) is None:
                errors.append(f"Recipe {recipe['id']} missing {field}")
        
        # Check ingredients
        if not recipe.get('ingredients'):
            errors.append(f"Recipe {recipe['id']} missing ingredients")
        elif not isinstance(recipe['ingredients'], list):
            errors.append(f"Recipe {recipe['id']} ingredients must be a list")
        else:
            for i, ingredient in enumerate(recipe['ingredients']):
                required_ingredient_fields = ['food_name', 'quantity', 'unit']
                for field in required_ingredient_fields:
                    if not ingredient.get(field):
                        errors.append(f"Recipe {recipe['id']} ingredient {i} missing {field}")
    
    if errors:
        print("  ❌ Errors found:")
        for error in errors[:3]:
            print(f"    - {error}")
        return False
    else:
        print("  ✅ Recipes dataset validation passed!")
        return True

def test_translation_consistency():
    """Test translation consistency across datasets"""
    print("🌍 Testing Translation Consistency...")
    
    # Collect all categories from different datasets
    food_categories = set()
    exercise_categories = set()
    recipe_categories = set()
    
    # Foods
    foods = get_multilingual_foods_dataset()
    for food in foods:
        for lang, translation in food.get('translations', {}).items():
            if translation.get('category'):
                food_categories.add((lang, translation['category']))
    
    # Exercises
    exercises = get_multilingual_exercises_dataset()
    for exercise in exercises:
        for lang, translation in exercise.get('translations', {}).items():
            if translation.get('category'):
                exercise_categories.add((lang, translation['category']))
    
    # Recipes
    recipes = get_multilingual_recipes_dataset()
    for recipe in recipes:
        for lang, translation in recipe.get('translations', {}).items():
            if translation.get('category'):
                recipe_categories.add((lang, translation['category']))
    
    print(f"  📊 Food categories found: {len(food_categories)}")
    print(f"  📊 Exercise categories found: {len(exercise_categories)}")
    print(f"  📊 Recipe categories found: {len(recipe_categories)}")
    
    # Check for consistent translations
    errors = []
    
    # Example: Check if all items have both EN and FR translations
    for dataset_name, dataset in [
        ('foods', foods),
        ('exercises', exercises),
        ('recipes', recipes)
    ]:
        for item in dataset:
            translations = item.get('translations', {})
            if 'en' not in translations:
                errors.append(f"{dataset_name} item {item.get('id')} missing English translation")
            if 'fr' not in translations:
                errors.append(f"{dataset_name} item {item.get('id')} missing French translation")
    
    if errors:
        print("  ❌ Translation consistency errors:")
        for error in errors[:3]:
            print(f"    - {error}")
        return False
    else:
        print("  ✅ Translation consistency validation passed!")
        return True

def display_sample_data():
    """Display sample data from each dataset"""
    print("📋 Sample Data Preview...")
    
    # Sample food
    foods = get_multilingual_foods_dataset()
    if foods:
        sample_food = foods[0]
        print(f"\n🍎 Sample Food (ID: {sample_food['id']}):")
        print(f"  EN: {sample_food['translations']['en']['name']} ({sample_food['translations']['en']['category']})")
        print(f"  FR: {sample_food['translations']['fr']['name']} ({sample_food['translations']['fr']['category']})")
        print(f"  Calories: {sample_food['calories_per_100g']}/100g")
    
    # Sample exercise
    exercises = get_multilingual_exercises_dataset()
    if exercises:
        sample_exercise = exercises[0]
        print(f"\n💪 Sample Exercise (ID: {sample_exercise['id']}):")
        print(f"  EN: {sample_exercise['translations']['en']['name']} ({sample_exercise['translations']['en']['category']})")
        print(f"  FR: {sample_exercise['translations']['fr']['name']} ({sample_exercise['translations']['fr']['category']})")
        print(f"  Calories: {sample_exercise['calories_per_minute']}/min")
    
    # Sample recipe
    recipes = get_multilingual_recipes_dataset()
    if recipes:
        sample_recipe = recipes[0]
        print(f"\n🍽️ Sample Recipe (ID: {sample_recipe['id']}):")
        print(f"  EN: {sample_recipe['translations']['en']['name']} ({sample_recipe['translations']['en']['category']})")
        print(f"  FR: {sample_recipe['translations']['fr']['name']} ({sample_recipe['translations']['fr']['category']})")
        print(f"  Servings: {sample_recipe['servings']}, Calories: {sample_recipe['calories_per_serving']}/serving")

def main():
    """Main test function"""
    print("🧪 MULTILINGUAL DATASETS VALIDATION")
    print("=" * 50)
    
    # Test foods
    foods_ok = test_foods_dataset()
    
    print("\n" + "=" * 50)
    if foods_ok:
        print("🎉 Multilingual datasets are ready!")
        
        # Show sample
        foods = get_multilingual_foods_dataset()
        if foods:
            sample = foods[0]
            print(f"\n📋 Sample Food:")
            print(f"  EN: {sample['translations']['en']['name']}")
            print(f"  FR: {sample['translations']['fr']['name']}")
    else:
        print("❌ Please fix the errors above.")

if __name__ == "__main__":
    main() 