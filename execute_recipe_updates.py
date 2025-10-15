"""
Script to execute recipe updates using generated SQL
This script reads the JSON updates and executes them one by one
"""
import json
import sys

def escape_sql_string(text):
    """Escape single quotes for SQL"""
    return text.replace("'", "''")

def generate_update_sql(recipe_id, steps_en):
    """Generate SQL UPDATE statement"""
    escaped_steps = escape_sql_string(steps_en)
    return f"UPDATE recipes_database SET steps_en = '{escaped_steps}' WHERE id = {recipe_id};"

def main():
    # Load updates
    with open('recipe_updates.json', 'r', encoding='utf-8') as f:
        updates = json.load(f)

    print(f"Loaded {len(updates)} recipe updates")

    # Generate all SQL statements
    print("\nGenerating SQL statements...")
    sql_statements = []

    for update in updates:
        sql = generate_update_sql(update['id'], update['steps_en'])
        sql_statements.append(sql)

    # Save to file for manual execution if needed
    with open('all_updates.sql', 'w', encoding='utf-8') as f:
        f.write("-- Recipe steps_en updates\n")
        f.write("-- Total updates: {}\n\n".format(len(sql_statements)))
        for sql in sql_statements:
            f.write(sql + "\n")

    print(f"Generated {len(sql_statements)} SQL statements")
    print(f"Saved to: all_updates.sql")

    # Print first 3 as samples
    print("\nSample SQL statements:")
    for i, sql in enumerate(sql_statements[:3], 1):
        print(f"\n{i}. {sql[:100]}...")

if __name__ == "__main__":
    main()
