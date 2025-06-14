#!/usr/bin/env python3
"""
Auto-Translation Script for Ryze App
Automatically translates all English content to French using predefined dictionaries
"""

from supabase import create_client
import time

# Supabase configuration
SUPABASE_URL = "https://mfskwlzgxjhhknlwpblq.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo"

# Translation dictionaries
FOOD_CATEGORIES_FR = {
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
    "Other": "Autre"
}

# Common food name translations
FOOD_NAMES_FR = {
    "Apple": "Pomme",
    "Banana": "Banane", 
    "Orange": "Orange",
    "Chicken Breast": "Blanc de Poulet",
    "Salmon": "Saumon",
    "Brown Rice": "Riz Complet",
    "Greek Yogurt": "Yaourt Grec",
    "Broccoli": "Brocoli",
    "Spinach": "Épinards",
    "Carrots": "Carottes",
    "Tomato": "Tomate",
    "Eggs": "Œufs",
    "Milk": "Lait",
    "Cheese": "Fromage",
    "Bread": "Pain",
    "Pasta": "Pâtes",
    "Chicken": "Poulet",
    "Beef": "Bœuf", 
    "Pork": "Porc",
    "Turkey": "Dinde",
    "Fish": "Poisson",
    "Tuna": "Thon",
    "Rice": "Riz",
    "Yogurt": "Yaourt",
    "Butter": "Beurre",
    "Oil": "Huile",
    "Olive": "Olive",
    "Almond": "Amande",
    "Potato": "Pomme de Terre",
    "Onion": "Oignon",
    "Pepper": "Poivron",
    "Cucumber": "Concombre",
    "Lettuce": "Laitue",
    "Carrot": "Carotte",
    "Strawberry": "Fraise",
    "Grape": "Raisin",
    "Pineapple": "Ananas",
    "Mango": "Mangue",
    "Peach": "Pêche",
    "Cherry": "Cerise",
    "Water": "Eau"
}

EXERCISE_NAMES_FR = {
    "Push-ups": "Pompes",
    "Squats": "Squats",
    "Pull-ups": "Tractions",
    "Jumping Jacks": "Jumping Jacks",
    "Burpees": "Burpees",
    "Plank": "Planche",
    "Lunges": "Fentes",
    "Deadlifts": "Soulevés de Terre",
    "Bench Press": "Développé Couché",
    "Running": "Course à Pied"
}

def create_supabase_client():
    return create_client(SUPABASE_URL, SUPABASE_KEY)

def translate_food_name(english_name):
    # Check direct translation first
    if english_name in FOOD_NAMES_FR:
        return FOOD_NAMES_FR[english_name]
    
    # Try word-by-word translation
    french_name = english_name
    for en_word, fr_word in FOOD_NAMES_FR.items():
        french_name = french_name.replace(en_word, fr_word)
    
    return french_name

def main():
    print("🌍 Starting automatic French translation...")
    
    supabase = create_supabase_client()
    
    # Get foods without French translations
    foods_result = supabase.table('foods').select('id, name').limit(100).execute()
    foods = foods_result.data
    
    print(f"🍎 Translating {len(foods)} foods...")
    
    french_translations = []
    for food in foods:
        french_name = translate_food_name(food['name'])
        
        french_translations.append({
            'food_id': food['id'],
            'language': 'fr',
            'name': french_name,
            'category': 'Aliment',
            'serving_unit': 'g'
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
    
    print(f"🎉 Completed! Translated {total_inserted} foods to French")

if __name__ == "__main__":
    main() 