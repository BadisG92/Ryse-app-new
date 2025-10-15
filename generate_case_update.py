"""
Generate a single UPDATE statement using CASE for all recipes
This is more efficient than 100 individual UPDATE statements
"""
import json

def escape_sql(text):
    """Escape single quotes for SQL"""
    return text.replace("'", "''")

def generate_case_update():
    """Generate single UPDATE with CASE statement"""

    # Load updates
    with open('recipe_updates.json', 'r', encoding='utf-8') as f:
        updates = json.load(f)

    print(f"Generating CASE UPDATE for {len(updates)} recipes...")

    # Start SQL
    sql = "UPDATE recipes_database\nSET steps_en = CASE id\n"

    # Add WHEN clauses
    for update in updates:
        recipe_id = update['id']
        steps_en = escape_sql(update['steps_en'])
        sql += f"  WHEN {recipe_id} THEN '{steps_en}'\n"

    # Add ELSE and WHERE
    sql += "  ELSE steps_en\n"
    sql += "END\n"

    # Only update the specific IDs
    ids = [str(u['id']) for u in updates]
    sql += f"WHERE id IN ({', '.join(ids)});"

    # Save to file
    with open('single_update.sql', 'w', encoding='utf-8') as f:
        f.write("-- Single UPDATE statement for all recipes\n")
        f.write("-- Using CASE to update 100 recipes in one query\n\n")
        f.write(sql)

    print(f"Generated single UPDATE statement")
    print(f"Saved to: single_update.sql")
    print(f"\nSQL length: {len(sql)} characters")

    # Also print first few lines
    lines = sql.split('\n')
    print(f"\nFirst 10 lines:")
    for i, line in enumerate(lines[:10], 1):
        print(f"{i:2}. {line[:100]}")

if __name__ == "__main__":
    generate_case_update()
