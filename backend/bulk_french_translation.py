#!/usr/bin/env python3
"""
Bulk French Translation Generator
Generates SQL statements to translate all remaining foods to French
"""

# Comprehensive food translations
FOOD_TRANSLATIONS = {
    # Fruits
    "Apple": "Pomme", "Banana": "Banane", "Orange": "Orange", "Strawberry": "Fraise", "Strawberries": "Fraises",
    "Grape": "Raisin", "Grapes": "Raisins", "Pineapple": "Ananas", "Mango": "Mangue", "Peach": "Pêche",
    "Cherry": "Cerise", "Watermelon": "Pastèque", "Blueberry": "Myrtille", "Blueberries": "Myrtilles",
    "Raspberry": "Framboise", "Raspberries": "Framboises", "Blackberry": "Mûre", "Blackberries": "Mûres",
    "Kiwi": "Kiwi", "Pear": "Poire", "Plum": "Prune", "Apricot": "Abricot", "Lemon": "Citron",
    "Lime": "Citron Vert", "Melon": "Melon", "Cantaloupe": "Cantaloup", "Honeydew": "Melon Miel",
    
    # Vegetables
    "Broccoli": "Brocoli", "Spinach": "Épinards", "Carrot": "Carotte", "Carrots": "Carottes",
    "Tomato": "Tomate", "Potato": "Pomme de Terre", "Sweet Potato": "Patate Douce",
    "Onion": "Oignon", "Garlic": "Ail", "Pepper": "Poivron", "Bell Pepper": "Poivron",
    "Cucumber": "Concombre", "Lettuce": "Laitue", "Cabbage": "Chou", "Cauliflower": "Chou-fleur",
    "Brussels Sprouts": "Choux de Bruxelles", "Asparagus": "Asperges", "Green Beans": "Haricots Verts",
    "Peas": "Petits Pois", "Mushroom": "Champignon", "Avocado": "Avocat", "Zucchini": "Courgette",
    "Eggplant": "Aubergine", "Celery": "Céleri", "Corn": "Maïs", "Beet": "Betterave",
    "Radish": "Radis", "Turnip": "Navet", "Leek": "Poireau", "Artichoke": "Artichaut",
    
    # Proteins
    "Chicken": "Poulet", "Chicken Breast": "Blanc de Poulet", "Turkey": "Dinde", "Turkey Breast": "Blanc de Dinde",
    "Beef": "Bœuf", "Lean Beef": "Bœuf Maigre", "Ground Beef": "Bœuf Haché", "Pork": "Porc",
    "Pork Tenderloin": "Filet de Porc", "Fish": "Poisson", "Salmon": "Saumon", "Tuna": "Thon",
    "Cod": "Cabillaud", "Shrimp": "Crevettes", "Crab": "Crabe", "Lobster": "Homard",
    "Scallops": "Coquilles Saint-Jacques", "Mussels": "Moules", "Eggs": "Œufs", "Tofu": "Tofu",
    "Tempeh": "Tempeh", "Seitan": "Seitan", "Lamb": "Agneau", "Duck": "Canard",
    
    # Dairy
    "Milk": "Lait", "Cheese": "Fromage", "Yogurt": "Yaourt", "Greek Yogurt": "Yaourt Grec",
    "Butter": "Beurre", "Cream": "Crème", "Cottage Cheese": "Fromage Blanc", "Mozzarella": "Mozzarella",
    "Cheddar": "Cheddar", "Parmesan": "Parmesan", "Feta": "Feta", "Goat Cheese": "Fromage de Chèvre",
    
    # Grains
    "Rice": "Riz", "Brown Rice": "Riz Complet", "White Rice": "Riz Blanc", "Bread": "Pain",
    "Pasta": "Pâtes", "Quinoa": "Quinoa", "Oats": "Avoine", "Barley": "Orge", "Wheat": "Blé",
    "Whole Wheat Bread": "Pain Complet", "Bagel": "Bagel", "Cereal": "Céréales", "Granola": "Granola",
    "Couscous": "Couscous", "Bulgur": "Boulgour", "Millet": "Millet", "Buckwheat": "Sarrasin",
    
    # Nuts & Seeds
    "Almond": "Amande", "Almonds": "Amandes", "Walnut": "Noix", "Walnuts": "Noix",
    "Peanut": "Cacahuète", "Peanuts": "Cacahuètes", "Cashew": "Noix de Cajou", "Pistachio": "Pistache",
    "Sunflower Seeds": "Graines de Tournesol", "Pumpkin Seeds": "Graines de Courge",
    "Chia Seeds": "Graines de Chia", "Flax Seeds": "Graines de Lin", "Sesame Seeds": "Graines de Sésame",
    "Pine Nuts": "Pignons", "Pecans": "Noix de Pécan", "Brazil Nuts": "Noix du Brésil",
    
    # Legumes
    "Bean": "Haricot", "Beans": "Haricots", "Lentil": "Lentille", "Lentils": "Lentilles",
    "Chickpea": "Pois Chiche", "Chickpeas": "Pois Chiches", "Black Beans": "Haricots Noirs",
    "Kidney Beans": "Haricots Rouges", "Navy Beans": "Haricots Blancs", "Pinto Beans": "Haricots Pinto",
    "Lima Beans": "Haricots de Lima", "Split Peas": "Pois Cassés",
    
    # Oils & Fats
    "Oil": "Huile", "Olive Oil": "Huile d'Olive", "Coconut Oil": "Huile de Coco",
    "Vegetable Oil": "Huile Végétale", "Canola Oil": "Huile de Colza", "Sesame Oil": "Huile de Sésame",
    "Olive": "Olive", "Olives": "Olives", "Coconut": "Coco", "Avocado Oil": "Huile d'Avocat",
    
    # Beverages
    "Water": "Eau", "Coffee": "Café", "Tea": "Thé", "Green Tea": "Thé Vert", "Black Tea": "Thé Noir",
    "Coffee (Black)": "Café Noir", "Herbal Tea": "Tisane", "Juice": "Jus", "Orange Juice": "Jus d'Orange",
    "Apple Juice": "Jus de Pomme", "Milk": "Lait", "Almond Milk": "Lait d'Amande", "Soy Milk": "Lait de Soja",
    
    # Spices & Herbs
    "Salt": "Sel", "Pepper": "Poivre", "Basil": "Basilic", "Oregano": "Origan", "Thyme": "Thym",
    "Rosemary": "Romarin", "Parsley": "Persil", "Cilantro": "Coriandre", "Mint": "Menthe",
    "Ginger": "Gingembre", "Turmeric": "Curcuma", "Cinnamon": "Cannelle", "Paprika": "Paprika",
    
    # Common modifiers
    "Fresh": "Frais", "Frozen": "Surgelé", "Dried": "Séché", "Raw": "Cru", "Cooked": "Cuit",
    "Grilled": "Grillé", "Baked": "Cuit au Four", "Steamed": "Cuit à la Vapeur", "Organic": "Bio",
    "Canned": "En Conserve", "Roasted": "Grillé", "Boiled": "Bouilli", "Fried": "Frit"
}

CATEGORY_TRANSLATIONS = {
    "fruits": "Fruits", "Fruits": "Fruits",
    "vegetables": "Légumes", "Vegetables": "Légumes",
    "meat": "Viande", "Meat": "Viande",
    "fish": "Poisson", "Fish": "Poisson",
    "dairy": "Produits Laitiers", "Dairy": "Produits Laitiers",
    "grains": "Céréales", "Grains": "Céréales",
    "nuts": "Noix", "Nuts": "Noix",
    "legumes": "Légumineuses", "Legumes": "Légumineuses",
    "oils": "Huiles", "Oils": "Huiles",
    "beverages": "Boissons", "Beverages": "Boissons",
    "plant_protein": "Protéine Végétale",
    "other": "Autre", "Other": "Autre"
}

def translate_food_name(english_name):
    """Translate food name to French"""
    if english_name in FOOD_TRANSLATIONS:
        return FOOD_TRANSLATIONS[english_name]
    
    # Try word-by-word translation for compound names
    french_name = english_name
    for en_word, fr_word in FOOD_TRANSLATIONS.items():
        if en_word in english_name and len(en_word) > 3:  # Avoid short word conflicts
            french_name = french_name.replace(en_word, fr_word)
    
    return french_name

def translate_category(english_category):
    """Translate category to French"""
    return CATEGORY_TRANSLATIONS.get(english_category, english_category)

def generate_sql_for_foods(foods_data):
    """Generate SQL INSERT statements for food translations"""
    sql_values = []
    
    for food in foods_data:
        food_id = food['id']
        english_name = food['name']
        english_category = food['category']
        serving_unit = food['serving_unit']
        
        french_name = translate_food_name(english_name)
        french_category = translate_category(english_category)
        
        sql_values.append(f"  ('{food_id}', 'fr', '{french_name}', '{french_category}', '{serving_unit}')")
    
    if sql_values:
        sql = "INSERT INTO food_translations (food_id, language, name, category, serving_unit)\nVALUES\n"
        sql += ",\n".join(sql_values) + ";"
        return sql
    
    return ""

# Sample data for testing (you would get this from MCP Supabase query)
sample_foods = [
    {"id": "test-1", "name": "Chicken Thigh", "category": "meat", "serving_unit": "g"},
    {"id": "test-2", "name": "Sweet Potato", "category": "vegetables", "serving_unit": "g"},
    {"id": "test-3", "name": "Almond Milk", "category": "beverages", "serving_unit": "ml"},
    {"id": "test-4", "name": "Black Beans", "category": "legumes", "serving_unit": "g"},
    {"id": "test-5", "name": "Olive Oil", "category": "oils", "serving_unit": "ml"}
]

print("🌍 Bulk French Translation Generator")
print("=" * 50)

print("\n📋 Available translations:")
print(f"   - Foods: {len(FOOD_TRANSLATIONS)} translations")
print(f"   - Categories: {len(CATEGORY_TRANSLATIONS)} translations")

print("\n🧪 Testing with sample data:")
sample_sql = generate_sql_for_foods(sample_foods)
print(sample_sql)

print("\n💡 Usage Instructions:")
print("1. Get foods without French translations using MCP Supabase:")
print("   SELECT f.id, f.name, ft_en.category, ft_en.serving_unit")
print("   FROM foods f")
print("   JOIN food_translations ft_en ON f.id = ft_en.food_id AND ft_en.language = 'en'")
print("   LEFT JOIN food_translations ft_fr ON f.id = ft_fr.food_id AND ft_fr.language = 'fr'")
print("   WHERE ft_fr.id IS NULL;")
print("\n2. Use generate_sql_for_foods() function with the results")
print("3. Execute the generated SQL using MCP Supabase")

print("\n✅ Ready to generate bulk translations!")

# Test individual translations
test_names = ["Grilled Chicken Breast", "Fresh Strawberries", "Organic Quinoa", "Coconut Oil"]
print(f"\n🔍 Individual translation tests:")
for name in test_names:
    french = translate_food_name(name)
    print(f"   {name} -> {french}") 