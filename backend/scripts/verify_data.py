#!/usr/bin/env python3
"""
Data Verification Script for Ryze App
Verifies the quality and completeness of imported data
"""

import os
import sys
import asyncio
from datetime import datetime
from typing import Dict, List, Any

# Add the parent directory to the path to import our modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = "YOUR_SUPABASE_URL"  # Replace with your actual URL
SUPABASE_KEY = "YOUR_SUPABASE_ANON_KEY"  # Replace with your actual key

class DataVerifier:
    def __init__(self, supabase_url: str, supabase_key: str):
        self.supabase: Client = create_client(supabase_url, supabase_key)
        self.verification_results = {
            'foods': {'passed': 0, 'failed': 0, 'issues': []},
            'exercises': {'passed': 0, 'failed': 0, 'issues': []},
            'recipes': {'passed': 0, 'failed': 0, 'issues': []},
            'recipe_ingredients': {'passed': 0, 'failed': 0, 'issues': []}
        }
    
    async def verify_foods_data(self) -> bool:
        """Verify foods data quality"""
        print("🍎 Verifying foods data...")
        
        try:
            # Get all foods
            result = self.supabase.table('foods').select('*').execute()
            foods = result.data if result.data else []
            
            print(f"  Found {len(foods)} food items")
            
            for food in foods:
                issues = []
                
                # Check required fields
                if not food.get('name') or len(food['name'].strip()) == 0:
                    issues.append("Missing or empty name")
                
                # Check nutritional values are non-negative
                nutritional_fields = ['calories_per_100g', 'protein_per_100g', 'carbs_per_100g', 'fat_per_100g']
                for field in nutritional_fields:
                    if food.get(field) is None or food[field] < 0:
                        issues.append(f"Invalid {field}: {food.get(field)}")
                
                # Check calories calculation (rough estimate)
                calculated_calories = (food.get('protein_per_100g', 0) * 4 + 
                                     food.get('carbs_per_100g', 0) * 4 + 
                                     food.get('fat_per_100g', 0) * 9)
                actual_calories = food.get('calories_per_100g', 0)
                
                # Allow 20% variance in calorie calculation
                if abs(calculated_calories - actual_calories) > (actual_calories * 0.2):
                    issues.append(f"Calorie mismatch: calculated {calculated_calories:.1f}, actual {actual_calories}")
                
                # Check category is valid
                valid_categories = ['fruits', 'vegetables', 'meat', 'fish', 'seafood', 'dairy', 'grains', 'nuts', 'seeds', 'legumes', 'oils', 'beverages', 'plant_protein']
                if food.get('category') not in valid_categories:
                    issues.append(f"Invalid category: {food.get('category')}")
                
                # Check serving size is reasonable
                serving_size = food.get('serving_size', 0)
                if serving_size <= 0 or serving_size > 1000:
                    issues.append(f"Unreasonable serving size: {serving_size}")
                
                if issues:
                    self.verification_results['foods']['failed'] += 1
                    self.verification_results['foods']['issues'].extend([f"{food['name']}: {issue}" for issue in issues])
                else:
                    self.verification_results['foods']['passed'] += 1
            
            success_rate = self.verification_results['foods']['passed'] / len(foods) * 100 if foods else 0
            print(f"  ✅ Foods verification: {success_rate:.1f}% passed ({self.verification_results['foods']['passed']}/{len(foods)})")
            
            if self.verification_results['foods']['issues']:
                print(f"  ⚠️ Found {len(self.verification_results['foods']['issues'])} issues")
                for issue in self.verification_results['foods']['issues'][:5]:  # Show first 5 issues
                    print(f"    - {issue}")
                if len(self.verification_results['foods']['issues']) > 5:
                    print(f"    ... and {len(self.verification_results['foods']['issues']) - 5} more")
            
            return success_rate >= 95  # 95% success rate required
            
        except Exception as e:
            print(f"❌ Error verifying foods: {str(e)}")
            return False
    
    async def verify_exercises_data(self) -> bool:
        """Verify exercises data quality"""
        print("💪 Verifying exercises data...")
        
        try:
            # Get all exercises
            result = self.supabase.table('exercises').select('*').execute()
            exercises = result.data if result.data else []
            
            print(f"  Found {len(exercises)} exercises")
            
            for exercise in exercises:
                issues = []
                
                # Check required fields
                required_fields = ['name', 'category', 'muscle_group', 'equipment', 'difficulty', 'instructions']
                for field in required_fields:
                    if not exercise.get(field):
                        issues.append(f"Missing {field}")
                
                # Check category is valid
                valid_categories = ['strength', 'cardio', 'flexibility', 'balance', 'sports']
                if exercise.get('category') not in valid_categories:
                    issues.append(f"Invalid category: {exercise.get('category')}")
                
                # Check muscle group is valid
                valid_muscle_groups = ['chest', 'back', 'shoulders', 'arms', 'legs', 'glutes', 'core', 'full_body']
                if exercise.get('muscle_group') not in valid_muscle_groups:
                    issues.append(f"Invalid muscle group: {exercise.get('muscle_group')}")
                
                # Check difficulty is valid
                valid_difficulties = ['beginner', 'intermediate', 'advanced']
                if exercise.get('difficulty') not in valid_difficulties:
                    issues.append(f"Invalid difficulty: {exercise.get('difficulty')}")
                
                # Check instructions are provided
                instructions = exercise.get('instructions', [])
                if not instructions or len(instructions) < 3:
                    issues.append("Insufficient instructions (need at least 3 steps)")
                
                # Check numeric values are reasonable
                calories_per_minute = exercise.get('calories_per_minute', 0)
                if calories_per_minute <= 0 or calories_per_minute > 20:
                    issues.append(f"Unreasonable calories per minute: {calories_per_minute}")
                
                sets = exercise.get('sets', 0)
                if sets <= 0 or sets > 10:
                    issues.append(f"Unreasonable sets: {sets}")
                
                reps = exercise.get('reps', 0)
                if reps <= 0 or reps > 100:
                    issues.append(f"Unreasonable reps: {reps}")
                
                if issues:
                    self.verification_results['exercises']['failed'] += 1
                    self.verification_results['exercises']['issues'].extend([f"{exercise['name']}: {issue}" for issue in issues])
                else:
                    self.verification_results['exercises']['passed'] += 1
            
            success_rate = self.verification_results['exercises']['passed'] / len(exercises) * 100 if exercises else 0
            print(f"  ✅ Exercises verification: {success_rate:.1f}% passed ({self.verification_results['exercises']['passed']}/{len(exercises)})")
            
            if self.verification_results['exercises']['issues']:
                print(f"  ⚠️ Found {len(self.verification_results['exercises']['issues'])} issues")
                for issue in self.verification_results['exercises']['issues'][:3]:
                    print(f"    - {issue}")
                if len(self.verification_results['exercises']['issues']) > 3:
                    print(f"    ... and {len(self.verification_results['exercises']['issues']) - 3} more")
            
            return success_rate >= 95
            
        except Exception as e:
            print(f"❌ Error verifying exercises: {str(e)}")
            return False
    
    async def verify_recipes_data(self) -> bool:
        """Verify recipes data quality"""
        print("🍽️ Verifying recipes data...")
        
        try:
            # Get all recipes with ingredients
            recipes_result = self.supabase.table('recipes').select('*').execute()
            recipes = recipes_result.data if recipes_result.data else []
            
            print(f"  Found {len(recipes)} recipes")
            
            for recipe in recipes:
                issues = []
                
                # Check required fields
                required_fields = ['name', 'description', 'category', 'prep_time_minutes', 'cook_time_minutes', 'servings', 'instructions']
                for field in required_fields:
                    if not recipe.get(field):
                        issues.append(f"Missing {field}")
                
                # Check numeric values are reasonable
                prep_time = recipe.get('prep_time_minutes', 0)
                if prep_time < 0 or prep_time > 300:  # 5 hours max
                    issues.append(f"Unreasonable prep time: {prep_time} minutes")
                
                cook_time = recipe.get('cook_time_minutes', 0)
                if cook_time < 0 or cook_time > 480:  # 8 hours max
                    issues.append(f"Unreasonable cook time: {cook_time} minutes")
                
                servings = recipe.get('servings', 0)
                if servings <= 0 or servings > 20:
                    issues.append(f"Unreasonable servings: {servings}")
                
                # Check nutritional values
                calories = recipe.get('calories_per_serving', 0)
                if calories <= 0 or calories > 2000:
                    issues.append(f"Unreasonable calories per serving: {calories}")
                
                # Check instructions
                instructions = recipe.get('instructions', [])
                if not instructions or len(instructions) < 3:
                    issues.append("Insufficient instructions (need at least 3 steps)")
                
                # Check ingredients exist
                ingredients_result = self.supabase.table('recipe_ingredients').select('*').eq('recipe_id', recipe['id']).execute()
                ingredients = ingredients_result.data if ingredients_result.data else []
                
                if len(ingredients) < 2:
                    issues.append(f"Too few ingredients: {len(ingredients)}")
                
                if issues:
                    self.verification_results['recipes']['failed'] += 1
                    self.verification_results['recipes']['issues'].extend([f"{recipe['name']}: {issue}" for issue in issues])
                else:
                    self.verification_results['recipes']['passed'] += 1
                
                # Count recipe ingredients
                self.verification_results['recipe_ingredients']['passed'] += len(ingredients)
            
            success_rate = self.verification_results['recipes']['passed'] / len(recipes) * 100 if recipes else 0
            print(f"  ✅ Recipes verification: {success_rate:.1f}% passed ({self.verification_results['recipes']['passed']}/{len(recipes)})")
            
            if self.verification_results['recipes']['issues']:
                print(f"  ⚠️ Found {len(self.verification_results['recipes']['issues'])} issues")
                for issue in self.verification_results['recipes']['issues'][:3]:
                    print(f"    - {issue}")
                if len(self.verification_results['recipes']['issues']) > 3:
                    print(f"    ... and {len(self.verification_results['recipes']['issues']) - 3} more")
            
            return success_rate >= 90  # Slightly lower threshold for recipes
            
        except Exception as e:
            print(f"❌ Error verifying recipes: {str(e)}")
            return False
    
    async def verify_data_relationships(self) -> bool:
        """Verify data relationships and integrity"""
        print("🔗 Verifying data relationships...")
        
        try:
            # Check recipe ingredients reference valid foods
            ingredients_result = self.supabase.table('recipe_ingredients').select('*, foods(name)').execute()
            ingredients = ingredients_result.data if ingredients_result.data else []
            
            orphaned_ingredients = 0
            for ingredient in ingredients:
                if not ingredient.get('foods'):
                    orphaned_ingredients += 1
            
            if orphaned_ingredients > 0:
                print(f"  ⚠️ Found {orphaned_ingredients} recipe ingredients with invalid food references")
                return False
            
            print(f"  ✅ All {len(ingredients)} recipe ingredients have valid food references")
            return True
            
        except Exception as e:
            print(f"❌ Error verifying relationships: {str(e)}")
            return False
    
    async def generate_summary_report(self) -> Dict[str, Any]:
        """Generate a summary report of the verification"""
        print("📊 Generating summary report...")
        
        try:
            # Get counts from database
            foods_result = self.supabase.table('foods').select('id', count='exact').execute()
            exercises_result = self.supabase.table('exercises').select('id', count='exact').execute()
            recipes_result = self.supabase.table('recipes').select('id', count='exact').execute()
            ingredients_result = self.supabase.table('recipe_ingredients').select('id', count='exact').execute()
            
            report = {
                'timestamp': datetime.now().isoformat(),
                'database_counts': {
                    'foods': foods_result.count or 0,
                    'exercises': exercises_result.count or 0,
                    'recipes': recipes_result.count or 0,
                    'recipe_ingredients': ingredients_result.count or 0
                },
                'verification_results': self.verification_results,
                'overall_status': 'PASSED'
            }
            
            # Determine overall status
            total_passed = sum(result['passed'] for result in self.verification_results.values())
            total_failed = sum(result['failed'] for result in self.verification_results.values())
            total_items = total_passed + total_failed
            
            if total_items == 0:
                report['overall_status'] = 'NO_DATA'
            elif total_failed > (total_items * 0.05):  # More than 5% failed
                report['overall_status'] = 'FAILED'
            elif total_failed > 0:
                report['overall_status'] = 'PASSED_WITH_WARNINGS'
            
            return report
            
        except Exception as e:
            print(f"❌ Error generating report: {str(e)}")
            return {'error': str(e)}
    
    async def run_full_verification(self) -> bool:
        """Run the complete data verification process"""
        print("🔍 Starting Ryze App data verification...")
        print("=" * 50)
        
        start_time = datetime.now()
        
        # Run all verifications
        foods_ok = await self.verify_foods_data()
        exercises_ok = await self.verify_exercises_data()
        recipes_ok = await self.verify_recipes_data()
        relationships_ok = await self.verify_data_relationships()
        
        # Generate summary report
        report = await self.generate_summary_report()
        
        end_time = datetime.now()
        duration = end_time - start_time
        
        print("=" * 50)
        print("📋 Verification Summary:")
        print(f"  Database Counts:")
        print(f"    Foods: {report['database_counts']['foods']}")
        print(f"    Exercises: {report['database_counts']['exercises']}")
        print(f"    Recipes: {report['database_counts']['recipes']}")
        print(f"    Recipe Ingredients: {report['database_counts']['recipe_ingredients']}")
        
        print(f"  Verification Results:")
        for table, results in self.verification_results.items():
            total = results['passed'] + results['failed']
            if total > 0:
                success_rate = results['passed'] / total * 100
                print(f"    {table.title()}: {success_rate:.1f}% passed ({results['passed']}/{total})")
        
        overall_success = foods_ok and exercises_ok and recipes_ok and relationships_ok
        
        print(f"  Overall Status: {report['overall_status']}")
        print(f"  Verification Time: {duration}")
        
        if overall_success:
            print("✅ Data verification completed successfully!")
            print("🚀 Your Ryze App database is ready for production use!")
        else:
            print("❌ Data verification found issues that need attention")
        
        return overall_success

async def main():
    """Main function to run the data verification"""
    
    # Check if Supabase credentials are configured
    if SUPABASE_URL == "YOUR_SUPABASE_URL" or SUPABASE_KEY == "YOUR_SUPABASE_ANON_KEY":
        print("❌ Please configure your Supabase credentials in this script")
        print("   Update SUPABASE_URL and SUPABASE_KEY variables")
        return False
    
    # Create verifier and run
    verifier = DataVerifier(SUPABASE_URL, SUPABASE_KEY)
    success = await verifier.run_full_verification()
    
    return success

if __name__ == "__main__":
    # Run the verification
    success = asyncio.run(main())
    
    if success:
        print("\n✅ Verification passed! Your data is high quality and ready to use.")
    else:
        print("\n❌ Verification failed. Please review the issues above.")
        print("   You may need to re-run the import or fix data quality issues.")
    
    sys.exit(0 if success else 1) 