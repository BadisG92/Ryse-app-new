#!/usr/bin/env python3
"""
French Translation via MCP Supabase API
Adds French translations for foods and exercises using direct SQL
"""

# Translation dictionaries
FOOD_TRANSLATIONS = {
    "Apple": "Pomme",
    "Banana": "Banane", 
    "Orange": "Orange",
    "Strawberries": "Fraises",
    "Grapes": "Raisins",
    "Broccoli": "Brocoli",
    "Spinach": "Épinards",
    "Carrots": "Carottes",
    "Bell Pepper": "Poivron",
    "Tomato": "Tomate",
    "Chicken Breast": "Blanc de Poulet",
    "Salmon": "Saumon",
    "Brown Rice": "Riz Complet",
    "Greek Yogurt": "Yaourt Grec",
    "Eggs": "Œufs",
    "Milk": "Lait",
    "Cheese": "Fromage",
    "Bread": "Pain",
    "Pasta": "Pâtes",
    "Water": "Eau",
    "Coffee": "Café",
    "Green Tea": "Thé Vert",
    "Olive Oil": "Huile d'Olive",
    "Almonds": "Amandes",
    "Quinoa": "Quinoa",
    "Avocado": "Avocat",
    "Sweet Potato": "Patate Douce",
    "Chicken": "Poulet",
    "Beef": "Bœuf",
    "Fish": "Poisson",
    "Rice": "Riz",
    "Potato": "Pomme de Terre",
    "Onion": "Oignon",
    "Garlic": "Ail",
    "Cucumber": "Concombre",
    "Lettuce": "Laitue",
    "Mushroom": "Champignon",
    "Pineapple": "Ananas",
    "Mango": "Mangue",
    "Strawberry": "Fraise",
    "Cherry": "Cerise",
    "Peach": "Pêche",
    "Grape": "Raisin",
    "Lemon": "Citron",
    "Lime": "Citron Vert",
    "Kiwi": "Kiwi",
    "Watermelon": "Pastèque",
    "Melon": "Melon",
    "Pear": "Poire",
    "Plum": "Prune",
    "Apricot": "Abricot",
    "Blueberry": "Myrtille",
    "Blueberries": "Myrtilles",
    "Raspberry": "Framboise",
    "Raspberries": "Framboises",
    "Blackberry": "Mûre",
    "Blackberries": "Mûres"
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
    "Mountain Climbers": "Grimpeurs",
    "Crunches": "Abdominaux",
    "Sit-ups": "Redressements Assis"
}

CATEGORIES_FR = {
    "fruits": "Fruits",
    "vegetables": "Légumes",
    "meat": "Viande", 
    "fish": "Poisson",
    "dairy": "Produits Laitiers",
    "grains": "Céréales",
    "nuts": "Noix",
    "legumes": "Légumineuses",
    "oils": "Huiles",
    "beverages": "Boissons",
    "other": "Autre"
}

def translate_food_name(english_name):
    """Translate food name to French"""
    if english_name in FOOD_TRANSLATIONS:
        return FOOD_TRANSLATIONS[english_name]
    
    # Try word-by-word translation
    french_name = english_name
    for en_word, fr_word in FOOD_TRANSLATIONS.items():
        if en_word in english_name:
            french_name = french_name.replace(en_word, fr_word)
    
    return french_name

def translate_exercise_name(english_name):
    """Translate exercise name to French"""
    if english_name in EXERCISE_TRANSLATIONS:
        return EXERCISE_TRANSLATIONS[english_name]
    return english_name

print("🌍 French Translation Script")
print("This script will help you add French translations to your Supabase database")
print("\n📋 Available translations:")
print(f"   - Foods: {len(FOOD_TRANSLATIONS)} translations")
print(f"   - Exercises: {len(EXERCISE_TRANSLATIONS)} translations")
print(f"   - Categories: {len(CATEGORIES_FR)} translations")

print("\n🔧 To use this script:")
print("1. Use the MCP Supabase tools to get foods/exercises without French translations")
print("2. Use the translation functions above to get French names")
print("3. Insert the translations using MCP Supabase insert operations")

print("\n💡 Example usage:")
print("   English: 'Apple' -> French: 'Pomme'")
print("   English: 'Push-ups' -> French: 'Pompes'")

# Test some translations
test_foods = ["Apple", "Chicken Breast", "Brown Rice", "Fresh Strawberries"]
print(f"\n🧪 Test translations:")
for food in test_foods:
    french = translate_food_name(food)
    print(f"   {food} -> {french}")

print(f"\n✅ Ready to translate! Use MCP Supabase tools to apply these translations.") 