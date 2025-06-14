#!/usr/bin/env python3
"""
Smart French Translation Script for Ryze App
Translates only missing French content, avoiding duplicates
"""

from supabase import create_client
import time

# Supabase configuration
SUPABASE_URL = "https://mfskwlzgxjhhknlwpblq.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo"

# Comprehensive French translations
FOOD_TRANSLATIONS = {
    "Apple": "Pomme",
    "Banana": "Banane",
    "Orange": "Orange",
    "Strawberry": "Fraise",
    "Strawberries": "Fraises",
    "Grapes": "Raisins",
    "Pineapple": "Ananas",
    "Mango": "Mangue",
    "Peach": "Pêche",
    "Cherry": "Cerise",
    "Watermelon": "Pastèque",
    "Blueberry": "Myrtille",
    "Blueberries": "Myrtilles",
    "Raspberry": "Framboise",
    "Raspberries": "Framboises",
    "Blackberry": "Mûre",
    "Blackberries": "Mûres",
    "Kiwi": "Kiwi",
    "Pear": "Poire",
    
    # Vegetables
    "Broccoli": "Brocoli",
    "Spinach": "Épinards",
    "Carrot": "Carotte",
    "Carrots": "Carottes",
    "Tomato": "Tomate",
    "Potato": "Pomme de Terre",
    "Sweet Potato": "Patate Douce",
    "Onion": "Oignon",
    "Garlic": "Ail",
    "Pepper": "Poivron",
    "Bell Pepper": "Poivron",
    "Cucumber": "Concombre",
    "Lettuce": "Laitue",
    "Cabbage": "Chou",
    "Cauliflower": "Chou-fleur",
    "Brussels Sprouts": "Choux de Bruxelles",
    "Asparagus": "Asperges",
    "Green Beans": "Haricots Verts",
    "Peas": "Petits Pois",
    "Mushroom": "Champignon",
    "Avocado": "Avocat",
    "Zucchini": "Courgette",
    "Eggplant": "Aubergine",
    "Celery": "Céleri",
    
    # Proteins
    "Chicken": "Poulet",
    "Chicken Breast": "Blanc de Poulet",
    "Turkey": "Dinde",
    "Turkey Breast": "Blanc de Dinde",
    "Beef": "Bœuf",
    "Lean Beef": "Bœuf Maigre",
    "Pork": "Porc",
    "Pork Tenderloin": "Filet de Porc",
    "Fish": "Poisson",
    "Salmon": "Saumon",
    "Tuna": "Thon",
    "Cod": "Cabillaud",
    "Shrimp": "Crevettes",
    "Crab": "Crabe",
    "Lobster": "Homard",
    "Scallops": "Coquilles Saint-Jacques",
    "Mussels": "Moules",
    "Eggs": "Œufs",
    
    # Dairy
    "Milk": "Lait",
    "Cheese": "Fromage",
    "Yogurt": "Yaourt",
    "Greek Yogurt": "Yaourt Grec",
    "Butter": "Beurre",
    "Cream": "Crème",
    
    # Grains
    "Rice": "Riz",
    "Brown Rice": "Riz Complet",
    "White Rice": "Riz Blanc",
    "Bread": "Pain",
    "Pasta": "Pâtes",
    "Quinoa": "Quinoa",
    "Oats": "Avoine",
    "Barley": "Orge",
    "Wheat": "Blé",
    
    # Nuts & Seeds
    "Almond": "Amande",
    "Almonds": "Amandes",
    "Walnut": "Noix",
    "Walnuts": "Noix",
    "Peanut": "Cacahuète",
    "Peanuts": "Cacahuètes",
    "Cashew": "Noix de Cajou",
    "Pistachio": "Pistache",
    "Sunflower Seeds": "Graines de Tournesol",
    
    # Legumes
    "Bean": "Haricot",
    "Beans": "Haricots",
    "Lentil": "Lentille",
    "Lentils": "Lentilles",
    "Chickpea": "Pois Chiche",
    "Chickpeas": "Pois Chiches",
    
    # Oils & Fats
    "Oil": "Huile",
    "Olive Oil": "Huile d'Olive",
    "Coconut Oil": "Huile de Coco",
    "Olive": "Olive",
    "Olives": "Olives",
    
    # Beverages
    "Water": "Eau",
    "Coffee": "Café",
    "Tea": "Thé",
    "Green Tea": "Thé Vert",
    "Black Tea": "Thé Noir",
    
    # Common modifiers
    "Fresh": "Frais",
    "Frozen": "Surgelé",
    "Dried": "Séché",
    "Raw": "Cru",
    "Cooked": "Cuit",
    "Grilled": "Grillé",
    "Baked": "Cuit au Four",
    "Steamed": "Cuit à la Vapeur",
    "Organic": "Bio",
    "Canned": "En Conserve"
}

EXERCISE_TRANSLATIONS = {
    "Push-ups": "Pompes",
    "Squats": "Squats",
    "Pull-ups": "Tractions",
    "Jumping Jacks": "Jumping Jacks",
    "Burpees": "Burpees",
    "Plank": "Planche",
    "Lunges": "Fentes",
    "Deadlifts": "Soulevés de Terre",
    "Bench Press": "Développé Couché",
    "Running": "Course à Pied",
    "Walking": "Marche",
    "Cycling": "Vélo",
    "Swimming": "Natation",
    "Jump Squats": "Squats Sautés",
    "Mountain Climbers": "Grimpeurs",
    "Crunches": "Abdominaux",
    "Sit-ups": "Redressements Assis",
    "Leg Raises": "Élévations de Jambes",
    "Bicep Curls": "Flexions des Biceps",
    "Tricep Dips": "Dips pour Triceps",
    "Shoulder Press": "Développé Épaules",
    "Lat Pulldown": "Tirage Vertical",
    "Rowing": "Rameur",
    "Calf Raises": "Élévations Mollets"
}

CATEGORIES_FR = {
    "Fruits": "Fruits",
    "Vegetables": "Légumes",
    "Meat": "Viande",
    "Fish": "Poisson",
    "Dairy": "Produits Laitiers",
    "Grains": "Céréales",
    "Nuts": "Noix",
    "Legumes": "Légumineuses",
    "Oils": "Huiles",
    "Beverages": "Boissons",
    "Other": "Autre",
    "Strength": "Force",
    "Cardio": "Cardio",
    "Flexibility": "Flexibilité",
    "Sports": "Sports"
}

def create_supabase_client():
    return create_client(SUPABASE_URL, SUPABASE_KEY)

def translate_text(english_text):
    """Translate English text to French using our dictionary"""
    if not english_text:
        return english_text
    
    # Check for direct translation
    if english_text in FOOD_TRANSLATIONS:
        return FOOD_TRANSLATIONS[english_text]
    
    if english_text in EXERCISE_TRANSLATIONS:
        return EXERCISE_TRANSLATIONS[english_text]
    
    # Try word-by-word translation
    french_text = english_text
    for en_word, fr_word in FOOD_TRANSLATIONS.items():
        french_text = french_text.replace(en_word, fr_word)
    
    return french_text

def translate_foods_to_french(supabase):
    """Translate foods that don't have French translations yet"""
    print("🍎 Finding foods without French translations...")
    
    # Get foods that don't have French translations
    result = supabase.execute("""
        SELECT f.id, f.name, ft_en.category, ft_en.serving_unit
        FROM foods f
        JOIN food_translations ft_en ON f.id = ft_en.food_id AND ft_en.language = 'en'
        LEFT JOIN food_translations ft_fr ON f.id = ft_fr.food_id AND ft_fr.language = 'fr'
        WHERE ft_fr.id IS NULL
        LIMIT 200
    """)
    
    foods_to_translate = result.data
    print(f"Found {len(foods_to_translate)} foods to translate")
    
    if not foods_to_translate:
        print("✅ All foods already have French translations!")
        return 0
    
    french_translations = []
    for food in foods_to_translate:
        french_name = translate_text(food['name'])
        french_category = CATEGORIES_FR.get(food['category'], food['category'])
        
        french_translations.append({
            'food_id': food['id'],
            'language': 'fr',
            'name': french_name,
            'category': french_category,
            'serving_unit': food['serving_unit']
        })
    
    # Insert in batches
    batch_size = 50
    total_inserted = 0
    
    for i in range(0, len(french_translations), batch_size):
        batch = french_translations[i:i + batch_size]
        try:
            supabase.table('food_translations').insert(batch).execute()
            total_inserted += len(batch)
            print(f"✅ Inserted {len(batch)} food translations (Total: {total_inserted})")
        except Exception as e:
            print(f"❌ Error: {e}")
        
        time.sleep(0.2)
    
    return total_inserted

def translate_exercises_to_french(supabase):
    """Translate exercises that don't have French translations yet"""
    print("💪 Finding exercises without French translations...")
    
    # Get exercises that don't have French translations
    result = supabase.execute("""
        SELECT e.id, e.name, et_en.category, et_en.muscle_group, et_en.equipment, et_en.difficulty
        FROM exercises e
        JOIN exercise_translations et_en ON e.id = et_en.exercise_id AND et_en.language = 'en'
        LEFT JOIN exercise_translations et_fr ON e.id = et_fr.exercise_id AND et_fr.language = 'fr'
        WHERE et_fr.id IS NULL
        LIMIT 100
    """)
    
    exercises_to_translate = result.data
    print(f"Found {len(exercises_to_translate)} exercises to translate")
    
    if not exercises_to_translate:
        print("✅ All exercises already have French translations!")
        return 0
    
    french_translations = []
    for exercise in exercises_to_translate:
        french_name = translate_text(exercise['name'])
        french_category = CATEGORIES_FR.get(exercise['category'], exercise['category'])
        
        french_translations.append({
            'exercise_id': exercise['id'],
            'language': 'fr',
            'name': french_name,
            'category': french_category,
            'muscle_group': exercise['muscle_group'],
            'equipment': exercise['equipment'],
            'difficulty': exercise['difficulty'],
            'instructions': [],
            'tips': []
        })
    
    try:
        supabase.table('exercise_translations').insert(french_translations).execute()
        print(f"✅ Inserted {len(french_translations)} exercise translations")
        return len(french_translations)
    except Exception as e:
        print(f"❌ Error: {e}")
        return 0

def main():
    print("🌍 Starting smart French translation...")
    
    supabase = create_supabase_client()
    
    try:
        # Translate foods
        foods_translated = translate_foods_to_french(supabase)
        
        # Translate exercises
        exercises_translated = translate_exercises_to_french(supabase)
        
        print(f"\n🎉 Translation completed!")
        print(f"📊 Summary:")
        print(f"   - Foods translated: {foods_translated}")
        print(f"   - Exercises translated: {exercises_translated}")
        
        # Verify final counts
        foods_fr = supabase.table('food_translations').select('id', count='exact').eq('language', 'fr').execute()
        exercises_fr = supabase.table('exercise_translations').select('id', count='exact').eq('language', 'fr').execute()
        
        print(f"\n📈 Total French translations in database:")
        print(f"   - Foods: {foods_fr.count}")
        print(f"   - Exercises: {exercises_fr.count}")
        
    except Exception as e:
        print(f"❌ Translation failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 