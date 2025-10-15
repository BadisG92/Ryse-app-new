"""
Batch update script for recipes_database.steps_en
Generates SQL file that can be executed via Supabase MCP
"""
import json

def escape_sql(text):
    """Escape single quotes for SQL and handle special characters"""
    # Replace single quotes with two single quotes for SQL escaping
    return text.replace("'", "''")

def create_batch_sql_file():
    """Create a single SQL file with all updates in a transaction"""

    # Load updates
    with open('recipe_updates.json', 'r', encoding='utf-8') as f:
        updates = json.load(f)

    total = len(updates)
    print(f"Processing {total} recipe updates...")

    # Create SQL file
    with open('batch_update_recipes.sql', 'w', encoding='utf-8') as f:
        f.write("-- Batch update for recipes_database.steps_en\n")
        f.write(f"-- Total recipes to update: {total}\n")
        f.write("-- Generated from recipe_steps_translation.xlsx\n\n")

        f.write("BEGIN;\n\n")

        # Generate UPDATE statements
        for i, update in enumerate(updates, 1):
            recipe_id = update['id']
            steps_en = escape_sql(update['steps_en'])

            f.write(f"-- Recipe {recipe_id}\n")
            f.write(f"UPDATE recipes_database\n")
            f.write(f"SET steps_en = '{steps_en}'\n")
            f.write(f"WHERE id = {recipe_id};\n\n")

            if i % 10 == 0:
                print(f"  Processed {i}/{total} recipes...")

        f.write("COMMIT;\n\n")

        # Add verification queries
        f.write("-- Verification: Check a sample of updated recipes\n")
        f.write("SELECT id, name_en, LEFT(steps_en, 100) as steps_preview\n")
        f.write("FROM recipes_database\n")
        f.write("WHERE id IN (1, 25, 50, 75, 100)\n")
        f.write("ORDER BY id;\n")

    print(f"\n✓ SQL file created: batch_update_recipes.sql")
    print(f"  Total statements: {total}")
    print(f"\nYou can now execute this file using:")
    print(f"  1. Supabase SQL Editor")
    print(f"  2. npx supabase db execute")
    print(f"  3. Or run the individual statements via MCP")

def create_individual_update_files():
    """Create individual SQL files for each batch of 10"""

    with open('recipe_updates.json', 'r', encoding='utf-8') as f:
        updates = json.load(f)

    batch_size = 10
    total_batches = (len(updates) + batch_size - 1) // batch_size

    print(f"\nCreating {total_batches} batch files ({batch_size} updates each)...")

    for batch_num in range(total_batches):
        start_idx = batch_num * batch_size
        end_idx = min(start_idx + batch_size, len(updates))
        batch = updates[start_idx:end_idx]

        filename = f"update_batch_{batch_num + 1:02d}.sql"

        with open(filename, 'w', encoding='utf-8') as f:
            f.write(f"-- Batch {batch_num + 1} of {total_batches}\n")
            f.write(f"-- Recipes {start_idx + 1} to {end_idx}\n\n")

            for update in batch:
                recipe_id = update['id']
                steps_en = escape_sql(update['steps_en'])

                f.write(f"UPDATE recipes_database SET steps_en = '{steps_en}' WHERE id = {recipe_id};\n")

        print(f"  Created: {filename}")

    print(f"\n✓ Created {total_batches} batch files")

if __name__ == "__main__":
    print("=" * 70)
    print("Recipe Steps Update - SQL Generator")
    print("=" * 70)

    # Create main SQL file
    create_batch_sql_file()

    # Also create individual batch files
    # create_individual_update_files()  # Uncomment if you want individual files

    print("\n" + "=" * 70)
    print("Done!")
    print("=" * 70)
