"""
Script to fix muscle_group_fr translations in exercises table
Based on muscle_group_en values
"""

# Standard muscle group translations EN -> FR
MUSCLE_GROUP_TRANSLATIONS = {
    # Common muscle groups
    'Chest': 'Pectoraux',
    'Back': 'Dos',
    'Shoulders': 'Épaules',
    'Biceps': 'Biceps',
    'Triceps': 'Triceps',
    'Forearms': 'Avant-bras',
    'Abs': 'Abdominaux',
    'Legs': 'Jambes',
    'Quads': 'Quadriceps',
    'Hamstrings': 'Ischio-jambiers',
    'Glutes': 'Fessiers',
    'Calves': 'Mollets',
    'Core': 'Tronc',
    'Full Body': 'Corps entier',
    'Cardio': 'Cardio',

    # Additional variations
    'Upper Back': 'Haut du dos',
    'Lower Back': 'Bas du dos',
    'Upper Chest': 'Haut des pectoraux',
    'Lower Chest': 'Bas des pectoraux',
    'Front Shoulders': 'Avant des épaules',
    'Side Shoulders': 'Épaules latérales',
    'Rear Shoulders': 'Arrière des épaules',
    'Inner Thighs': 'Intérieur des cuisses',
    'Outer Thighs': 'Extérieur des cuisses',
    'Hip Flexors': 'Fléchisseurs de la hanche',
    'Obliques': 'Obliques',
    'Lower Abs': 'Abdominaux inférieurs',
    'Upper Abs': 'Abdominaux supérieurs',
    'Neck': 'Cou',
    'Traps': 'Trapèzes',
    'Lats': 'Dorsaux',

    # Special cases
    'Custom': 'Personnalisé',
    'Other': 'Autre',
    '': '',
}

def generate_update_sql():
    """Generate SQL UPDATE statement to fix muscle_group_fr"""

    print("Generating SQL to fix muscle_group_fr translations...")
    print(f"Translation mappings: {len(MUSCLE_GROUP_TRANSLATIONS)}")

    # Create SQL file
    with open('fix_muscle_groups.sql', 'w', encoding='utf-8') as f:
        f.write("-- Fix muscle_group_fr translations based on muscle_group_en\n")
        f.write(f"-- Total translations: {len(MUSCLE_GROUP_TRANSLATIONS)}\n")
        f.write("-- Generated automatically\n\n")

        # Use CASE statement for efficiency
        f.write("UPDATE exercises\n")
        f.write("SET muscle_group_fr = CASE muscle_group_en\n")

        for en, fr in sorted(MUSCLE_GROUP_TRANSLATIONS.items()):
            if en:  # Skip empty string
                # Escape single quotes
                en_escaped = en.replace("'", "''")
                fr_escaped = fr.replace("'", "''")
                f.write(f"  WHEN '{en_escaped}' THEN '{fr_escaped}'\n")

        f.write("  ELSE muscle_group_fr\n")
        f.write("END\n")
        f.write("WHERE muscle_group_en IS NOT NULL;\n\n")

        # Add verification query
        f.write("-- Verification: Check distinct muscle groups\n")
        f.write("SELECT DISTINCT\n")
        f.write("  muscle_group_en,\n")
        f.write("  muscle_group_fr,\n")
        f.write("  COUNT(*) as exercise_count\n")
        f.write("FROM exercises\n")
        f.write("GROUP BY muscle_group_en, muscle_group_fr\n")
        f.write("ORDER BY muscle_group_en, muscle_group_fr;\n")

    print(f"✓ SQL file created: fix_muscle_groups.sql")

    # Also create individual UPDATE statements for manual execution if needed
    with open('fix_muscle_groups_individual.sql', 'w', encoding='utf-8') as f:
        f.write("-- Individual UPDATE statements for each muscle group\n")
        f.write("-- Use this if the CASE statement doesn't work\n\n")

        for en, fr in sorted(MUSCLE_GROUP_TRANSLATIONS.items()):
            if en:
                en_escaped = en.replace("'", "''")
                fr_escaped = fr.replace("'", "''")
                f.write(f"-- {en} -> {fr}\n")
                f.write(f"UPDATE exercises SET muscle_group_fr = '{fr_escaped}' ")
                f.write(f"WHERE muscle_group_en = '{en_escaped}';\n\n")

    print(f"✓ Individual SQL file created: fix_muscle_groups_individual.sql")

    # Print summary
    print("\n" + "="*70)
    print("Summary:")
    print("="*70)
    print(f"Translations defined: {len([k for k in MUSCLE_GROUP_TRANSLATIONS.keys() if k])}")
    print("\nSample translations:")
    for i, (en, fr) in enumerate(sorted(MUSCLE_GROUP_TRANSLATIONS.items())[:10]):
        if en:
            print(f"  {en:20} -> {fr}")
    print("\n✓ Ready to execute!")
    print("\nNext steps:")
    print("1. Review fix_muscle_groups.sql")
    print("2. Execute in Supabase SQL Editor")
    print("3. Check verification query at the end")

if __name__ == "__main__":
    generate_update_sql()
