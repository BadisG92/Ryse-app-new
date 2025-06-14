from data.foods_dataset import generate_complete_foods_dataset
from data.exercises_dataset import EXERCISES_DATASET
from data.recipes_dataset import RECIPES_DATASET
from supabase import create_client
import time

# Generate complete dataset
complete_foods = generate_complete_foods_dataset()
print(f'Generated {len(complete_foods)} foods')

# Create Supabase client
supabase = create_client('https://mfskwlzgxjhhknlwpblq.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo')

# Clear existing foods
print('🧹 Clearing existing foods...')
try:
    supabase.table('food_translations').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
    supabase.table('foods').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
    print('✅ Cleared existing data')
except Exception as e:
    print(f'⚠️ Warning: {e}')

# Import foods in batches
batch_size = 100
total_imported = 0
print(f'🍎 Starting import of {len(complete_foods)} foods...')

for i in range(0, len(complete_foods), batch_size):
    batch = complete_foods[i:i + batch_size]
    
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
        result = supabase.table('foods').insert(foods_data).execute()
        batch_count = len(result.data)
        total_imported += batch_count
        print(f'✅ Batch {i//batch_size + 1}: {batch_count} foods imported (Total: {total_imported})')
        
        # Add translations
        food_translations = []
        for j, food_record in enumerate(result.data):
            if j < len(batch):
                original_food = batch[j]
                food_translations.append({
                    'food_id': food_record['id'],
                    'language': 'en',
                    'name': original_food['name'],
                    'category': original_food.get('category', 'Other').title(),
                    'serving_unit': original_food.get('serving_unit', 'g')
                })
        
        if food_translations:
            supabase.table('food_translations').insert(food_translations).execute()
            print(f'✅ Added {len(food_translations)} translations')
            
    except Exception as e:
        print(f'❌ Error batch {i//batch_size + 1}: {e}')
    
    time.sleep(0.3)

print(f'🎉 COMPLETED! Imported {total_imported} foods total')

# Verify final count
foods_count = supabase.table('foods').select('id', count='exact').execute()
translations_count = supabase.table('food_translations').select('id', count='exact').execute()
print(f'📊 Final verification:')
print(f'   - Foods in database: {foods_count.count}')
print(f'   - Translations in database: {translations_count.count}') 