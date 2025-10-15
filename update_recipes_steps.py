"""
Script to update steps_en column in recipes_database from Excel file
"""
import json
import os
from supabase import create_client, Client

# Configuration Supabase
SUPABASE_URL = os.getenv('SUPABASE_URL', 'YOUR_SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_KEY', 'YOUR_SUPABASE_SERVICE_KEY')

def load_updates():
    """Load recipe updates from JSON file"""
    with open('recipe_updates.json', 'r', encoding='utf-8') as f:
        return json.load(f)

def update_recipes_batch(supabase: Client, updates, batch_size=10):
    """Update recipes in batches"""
    total = len(updates)
    success_count = 0
    error_count = 0

    print(f"Starting update of {total} recipes...")

    for i in range(0, total, batch_size):
        batch = updates[i:i + batch_size]
        batch_num = (i // batch_size) + 1

        print(f"\nProcessing batch {batch_num} (recipes {i+1} to {min(i+batch_size, total)})...")

        for update in batch:
            recipe_id = update['id']
            steps_en = update['steps_en']

            try:
                # Update the recipe
                result = supabase.table('recipes_database') \
                    .update({'steps_en': steps_en}) \
                    .eq('id', recipe_id) \
                    .execute()

                success_count += 1
                print(f"  ✓ Recipe {recipe_id} updated")

            except Exception as e:
                error_count += 1
                print(f"  ✗ Recipe {recipe_id} failed: {str(e)}")

    print(f"\n{'='*60}")
    print(f"Update complete!")
    print(f"  Success: {success_count}/{total}")
    print(f"  Errors: {error_count}/{total}")
    print(f"{'='*60}")

    return success_count, error_count

def verify_updates(supabase: Client, sample_ids=[1, 50, 100]):
    """Verify a sample of updates"""
    print("\nVerifying sample updates...")

    for recipe_id in sample_ids:
        try:
            result = supabase.table('recipes_database') \
                .select('id, name_en, steps_en') \
                .eq('id', recipe_id) \
                .single() \
                .execute()

            if result.data:
                print(f"\nRecipe {recipe_id}: {result.data['name_en']}")
                print(f"  Steps: {result.data['steps_en'][:100]}...")
        except Exception as e:
            print(f"\nRecipe {recipe_id}: Error - {str(e)}")

def main():
    """Main function"""
    # Load updates
    updates = load_updates()
    print(f"Loaded {len(updates)} recipe updates from JSON file")

    # Initialize Supabase client
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("Connected to Supabase")
    except Exception as e:
        print(f"Error connecting to Supabase: {e}")
        print("\nPlease set environment variables:")
        print("  SUPABASE_URL - Your Supabase project URL")
        print("  SUPABASE_SERVICE_KEY - Your Supabase service role key")
        return

    # Confirm before proceeding
    print(f"\nAbout to update {len(updates)} recipes in the database.")
    response = input("Continue? (yes/no): ")

    if response.lower() not in ['yes', 'y']:
        print("Update cancelled")
        return

    # Update recipes
    success_count, error_count = update_recipes_batch(supabase, updates)

    # Verify updates
    if success_count > 0:
        verify_updates(supabase)

if __name__ == "__main__":
    main()
