"""
Execute SQL updates for recipes_database via MCP Supabase
Reads the batch_update_recipes.sql file and outputs individual statements
"""

def read_and_parse_sql():
    """Read SQL file and parse UPDATE statements"""
    with open('batch_update_recipes.sql', 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by lines and extract only UPDATE statements
    lines = content.split('\n')
    statements = []
    current_statement = []

    for line in lines:
        line = line.strip()

        # Skip comments and empty lines
        if not line or line.startswith('--') or line in ['BEGIN;', 'COMMIT;']:
            continue

        # Start of UPDATE statement
        if line.startswith('UPDATE'):
            if current_statement:
                statements.append(' '.join(current_statement))
            current_statement = [line]
        # Continuation of current statement
        elif current_statement:
            current_statement.append(line)
            # End of statement
            if line.endswith(';'):
                statements.append(' '.join(current_statement))
                current_statement = []

    return statements

def main():
    statements = read_and_parse_sql()

    print(f"Found {len(statements)} UPDATE statements")
    print("\nFirst 3 statements:")
    for i, stmt in enumerate(statements[:3], 1):
        # Truncate for display
        display_stmt = stmt if len(stmt) <= 150 else stmt[:150] + '...'
        print(f"\n{i}. {display_stmt}")

    print(f"\n\nTo execute these via MCP Supabase, run each statement with:")
    print("mcp__supabase__execute_sql")

    # Output all statements to a simpler format
    with open('statements_list.txt', 'w', encoding='utf-8') as f:
        for i, stmt in enumerate(statements, 1):
            f.write(f"-- Statement {i}\n")
            f.write(stmt + "\n\n")

    print(f"\nAll statements saved to: statements_list.txt")

if __name__ == "__main__":
    main()
