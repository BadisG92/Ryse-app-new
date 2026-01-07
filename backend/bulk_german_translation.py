#!/usr/bin/env python3
"""
Bulk German Translation for food_database
Translates all food names and reference units from English to German
"""

import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# German translations dictionary
FOOD_TRANSLATIONS = {
    # Alcoholic beverages
    "Pastis (anise-flavoured spirit)": "Pastis (Anisschnaps)",
    "Clear fruit brandy or eau-de-vie": "Klarer Obstbrand oder Eau-de-vie",
    "Gin": "Gin",
    "Liqueur": "Likör",
    "Rum": "Rum",
    "Whisky": "Whisky",
    "Wine, white, sweet": "Wein, weiß, süß",
    "Wine-based aperitif": "Weinbasierter Aperitif",
    "Vodka": "Wodka",
    "Sangria": "Sangria",
    "Sake or rice wine": "Sake oder Reiswein",
    "Calvados brandy": "Calvados",
    "Marsala wine": "Marsalawein",

    # Fruits
    "Apple": "Apfel", "Banana": "Banane", "Orange": "Orange", "Strawberry": "Erdbeere",
    "Strawberries": "Erdbeeren", "Grape": "Traube", "Grapes": "Trauben",
    "Pineapple": "Ananas", "Mango": "Mango", "Peach": "Pfirsich",
    "Cherry": "Kirsche", "Cherries": "Kirschen", "Watermelon": "Wassermelone",
    "Blueberry": "Heidelbeere", "Blueberries": "Heidelbeeren",
    "Raspberry": "Himbeere", "Raspberries": "Himbeeren",
    "Blackberry": "Brombeere", "Blackberries": "Brombeeren",
    "Kiwi": "Kiwi", "Pear": "Birne", "Plum": "Pflaume", "Apricot": "Aprikose",
    "Lemon": "Zitrone", "Lime": "Limette", "Melon": "Melone",
    "Cantaloupe": "Cantaloupe-Melone", "Honeydew": "Honigmelone",
    "Grapefruit": "Grapefruit", "Pomegranate": "Granatapfel",
    "Fig": "Feige", "Figs": "Feigen", "Date": "Dattel", "Dates": "Datteln",
    "Cranberry": "Cranberry", "Cranberries": "Cranberries",
    "Passion fruit": "Passionsfrucht", "Papaya": "Papaya", "Coconut": "Kokosnuss",

    # Vegetables
    "Broccoli": "Brokkoli", "Spinach": "Spinat", "Carrot": "Karotte", "Carrots": "Karotten",
    "Tomato": "Tomate", "Tomatoes": "Tomaten", "Potato": "Kartoffel", "Potatoes": "Kartoffeln",
    "Sweet Potato": "Süßkartoffel", "Onion": "Zwiebel", "Garlic": "Knoblauch",
    "Pepper": "Paprika", "Bell Pepper": "Paprika", "Cucumber": "Gurke",
    "Lettuce": "Salat", "Cabbage": "Kohl", "Cauliflower": "Blumenkohl",
    "Brussels Sprouts": "Rosenkohl", "Asparagus": "Spargel",
    "Green Beans": "Grüne Bohnen", "Peas": "Erbsen", "Mushroom": "Pilz",
    "Mushrooms": "Pilze", "Avocado": "Avocado", "Zucchini": "Zucchini",
    "Eggplant": "Aubergine", "Celery": "Sellerie", "Corn": "Mais",
    "Beet": "Rote Bete", "Radish": "Radieschen", "Turnip": "Rübe",
    "Leek": "Lauch", "Artichoke": "Artischocke", "Kale": "Grünkohl",
    "Arugula": "Rucola", "Chard": "Mangold", "Fennel": "Fenchel",
    "Pumpkin": "Kürbis", "Squash": "Kürbis", "Parsnip": "Pastinake",

    # Proteins / Meat
    "Chicken": "Hähnchen", "Chicken Breast": "Hähnchenbrust",
    "Chicken Thigh": "Hähnchenschenkel", "Turkey": "Pute", "Turkey Breast": "Putenbrust",
    "Beef": "Rindfleisch", "Lean Beef": "Mageres Rindfleisch",
    "Ground Beef": "Rinderhackfleisch", "Pork": "Schweinefleisch",
    "Pork Tenderloin": "Schweinefilet", "Lamb": "Lammfleisch",
    "Duck": "Ente", "Veal": "Kalbfleisch", "Bacon": "Speck",
    "Ham": "Schinken", "Sausage": "Wurst", "Steak": "Steak",

    # Fish & Seafood
    "Fish": "Fisch", "Salmon": "Lachs", "Tuna": "Thunfisch",
    "Cod": "Kabeljau", "Shrimp": "Garnelen", "Crab": "Krabbe",
    "Lobster": "Hummer", "Scallops": "Jakobsmuscheln", "Mussels": "Muscheln",
    "Oyster": "Auster", "Oysters": "Austern", "Sardine": "Sardine",
    "Sardines": "Sardinen", "Mackerel": "Makrele", "Trout": "Forelle",
    "Herring": "Hering", "Anchovy": "Sardelle", "Anchovies": "Sardellen",
    "Squid": "Tintenfisch", "Octopus": "Oktopus", "Clam": "Venusmuschel",

    # Dairy
    "Milk": "Milch", "Cheese": "Käse", "Yogurt": "Joghurt",
    "Greek Yogurt": "Griechischer Joghurt", "Butter": "Butter",
    "Cream": "Sahne", "Cottage Cheese": "Hüttenkäse",
    "Cream Cheese": "Frischkäse", "Mozzarella": "Mozzarella",
    "Cheddar": "Cheddar", "Parmesan": "Parmesan", "Feta": "Feta",
    "Goat Cheese": "Ziegenkäse", "Brie": "Brie", "Camembert": "Camembert",
    "Swiss Cheese": "Schweizer Käse", "Ricotta": "Ricotta",
    "Sour Cream": "Saure Sahne", "Whipped Cream": "Schlagsahne",
    "Ice Cream": "Eiscreme", "Eggs": "Eier", "Egg": "Ei",
    "Egg White": "Eiweiß", "Egg Yolk": "Eigelb",

    # Grains
    "Rice": "Reis", "Brown Rice": "Vollkornreis", "White Rice": "Weißer Reis",
    "Bread": "Brot", "Pasta": "Nudeln", "Noodles": "Nudeln",
    "Quinoa": "Quinoa", "Oats": "Haferflocken", "Oatmeal": "Haferbrei",
    "Barley": "Gerste", "Wheat": "Weizen", "Whole Wheat Bread": "Vollkornbrot",
    "Bagel": "Bagel", "Cereal": "Müsli", "Granola": "Müsli",
    "Couscous": "Couscous", "Bulgur": "Bulgur", "Millet": "Hirse",
    "Buckwheat": "Buchweizen", "Flour": "Mehl", "Cornmeal": "Maismehl",
    "Tortilla": "Tortilla", "Cracker": "Cracker", "Crackers": "Cracker",

    # Nuts & Seeds
    "Almond": "Mandel", "Almonds": "Mandeln", "Walnut": "Walnuss",
    "Walnuts": "Walnüsse", "Peanut": "Erdnuss", "Peanuts": "Erdnüsse",
    "Cashew": "Cashewnuss", "Cashews": "Cashewnüsse",
    "Pistachio": "Pistazie", "Pistachios": "Pistazien",
    "Hazelnut": "Haselnuss", "Hazelnuts": "Haselnüsse",
    "Macadamia": "Macadamia", "Pecan": "Pekannuss", "Pecans": "Pekannüsse",
    "Brazil Nuts": "Paranüsse", "Pine Nuts": "Pinienkerne",
    "Sunflower Seeds": "Sonnenblumenkerne", "Pumpkin Seeds": "Kürbiskerne",
    "Chia Seeds": "Chiasamen", "Flax Seeds": "Leinsamen",
    "Sesame Seeds": "Sesamsamen", "Hemp Seeds": "Hanfsamen",

    # Legumes
    "Bean": "Bohne", "Beans": "Bohnen", "Lentil": "Linse", "Lentils": "Linsen",
    "Chickpea": "Kichererbse", "Chickpeas": "Kichererbsen",
    "Black Beans": "Schwarze Bohnen", "Kidney Beans": "Kidneybohnen",
    "Navy Beans": "Weiße Bohnen", "Pinto Beans": "Pintobohnen",
    "Lima Beans": "Limabohnen", "Split Peas": "Schälerbsen",
    "Hummus": "Hummus", "Tofu": "Tofu", "Tempeh": "Tempeh", "Seitan": "Seitan",
    "Edamame": "Edamame", "Soy": "Soja", "Soybean": "Sojabohne",

    # Oils & Fats
    "Oil": "Öl", "Olive Oil": "Olivenöl", "Coconut Oil": "Kokosöl",
    "Vegetable Oil": "Pflanzenöl", "Canola Oil": "Rapsöl",
    "Sesame Oil": "Sesamöl", "Avocado Oil": "Avocadoöl",
    "Sunflower Oil": "Sonnenblumenöl", "Peanut Oil": "Erdnussöl",
    "Margarine": "Margarine", "Lard": "Schmalz",

    # Beverages
    "Water": "Wasser", "Coffee": "Kaffee", "Tea": "Tee",
    "Green Tea": "Grüner Tee", "Black Tea": "Schwarzer Tee",
    "Herbal Tea": "Kräutertee", "Juice": "Saft",
    "Orange Juice": "Orangensaft", "Apple Juice": "Apfelsaft",
    "Almond Milk": "Mandelmilch", "Soy Milk": "Sojamilch",
    "Oat Milk": "Hafermilch", "Coconut Milk": "Kokosmilch",
    "Beer": "Bier", "Wine": "Wein", "Red Wine": "Rotwein", "White Wine": "Weißwein",

    # Spices & Herbs
    "Salt": "Salz", "Black Pepper": "Schwarzer Pfeffer", "Basil": "Basilikum",
    "Oregano": "Oregano", "Thyme": "Thymian", "Rosemary": "Rosmarin",
    "Parsley": "Petersilie", "Cilantro": "Koriander", "Mint": "Minze",
    "Ginger": "Ingwer", "Turmeric": "Kurkuma", "Cinnamon": "Zimt",
    "Paprika": "Paprika", "Cumin": "Kreuzkümmel", "Curry": "Curry",
    "Nutmeg": "Muskatnuss", "Clove": "Nelke", "Bay Leaf": "Lorbeerblatt",
    "Dill": "Dill", "Sage": "Salbei", "Chive": "Schnittlauch",
    "Chives": "Schnittlauch", "Tarragon": "Estragon", "Cardamom": "Kardamom",

    # Sweeteners & Condiments
    "Sugar": "Zucker", "Honey": "Honig", "Maple Syrup": "Ahornsirup",
    "Molasses": "Melasse", "Brown Sugar": "Brauner Zucker",
    "Powdered Sugar": "Puderzucker", "Stevia": "Stevia",
    "Ketchup": "Ketchup", "Mustard": "Senf", "Mayonnaise": "Mayonnaise",
    "Vinegar": "Essig", "Soy Sauce": "Sojasauce",
    "Hot Sauce": "Scharfe Sauce", "Salsa": "Salsa",
    "Worcestershire Sauce": "Worcestersauce", "BBQ Sauce": "BBQ-Sauce",

    # Baked goods
    "Cake": "Kuchen", "Cookie": "Keks", "Cookies": "Kekse",
    "Pie": "Kuchen", "Pastry": "Gebäck", "Croissant": "Croissant",
    "Muffin": "Muffin", "Donut": "Donut", "Brownie": "Brownie",
    "Pancake": "Pfannkuchen", "Pancakes": "Pfannkuchen",
    "Waffle": "Waffel", "Waffles": "Waffeln", "Toast": "Toast",

    # Prepared foods
    "Soup": "Suppe", "Salad": "Salat", "Sandwich": "Sandwich",
    "Pizza": "Pizza", "Burger": "Burger", "Hot Dog": "Hot Dog",
    "Fries": "Pommes", "French Fries": "Pommes Frites",
    "Chips": "Chips", "Popcorn": "Popcorn",

    # Common modifiers
    "Fresh": "Frisch", "Frozen": "Tiefgekühlt", "Dried": "Getrocknet",
    "Raw": "Roh", "Cooked": "Gekocht", "Grilled": "Gegrillt",
    "Baked": "Gebacken", "Steamed": "Gedünstet", "Organic": "Bio",
    "Canned": "Dose", "Roasted": "Geröstet", "Boiled": "Gekocht",
    "Fried": "Gebraten", "Smoked": "Geräuchert", "Pickled": "Eingelegt",
    "Salted": "Gesalzen", "Unsalted": "Ungesalzen",
    "Low-fat": "Fettarm", "Fat-free": "Fettfrei",
    "Whole": "Ganz", "Sliced": "Geschnitten", "Diced": "Gewürfelt",
    "Minced": "Gehackt", "Chopped": "Gehackt", "Mashed": "Püriert",
    "Stuffed": "Gefüllt", "Marinated": "Mariniert",

    # Plant-based
    "Plant-based": "Pflanzlich", "Vegan": "Vegan", "Vegetarian": "Vegetarisch",
    "Plant-based spread-cheese type, with soybean, prepacked": "Pflanzlicher Streichkäse mit Soja, verpackt",
    "Plant-based cheese, with cashew, prepacked": "Pflanzlicher Käse mit Cashew, verpackt",
    "Plant-based cheese, without soybean, prepacked": "Pflanzlicher Käse ohne Soja, verpackt",
    "Plant-based ham, prepacked": "Pflanzlicher Schinken, verpackt",
    "Plant-based pâté, prepacked": "Pflanzliche Pastete, verpackt",
}

# Unit translations
UNIT_TRANSLATIONS = {
    "g": "g",
    "ml": "ml",
    "oz": "oz",
    "cup": "Tasse",
    "cups": "Tassen",
    "1 cup": "1 Tasse",
    "1/2 cup": "1/2 Tasse",
    "slice": "Scheibe",
    "slices": "Scheiben",
    "1 slice": "1 Scheibe",
    "piece": "Stück",
    "pieces": "Stücke",
    "1 piece": "1 Stück",
    "tablespoon": "Esslöffel",
    "tbsp": "EL",
    "1 tablespoon": "1 Esslöffel",
    "teaspoon": "Teelöffel",
    "tsp": "TL",
    "1 teaspoon": "1 Teelöffel",
    "serving": "Portion",
    "1 serving": "1 Portion",
    "unit": "Einheit",
    "1 unit": "1 Einheit",
    "100g": "100g",
    "100ml": "100ml",
    "medium": "mittel",
    "large": "groß",
    "small": "klein",
    "1 medium": "1 mittel",
    "1 large": "1 groß",
    "1 small": "1 klein",
    "can": "Dose",
    "bottle": "Flasche",
    "package": "Packung",
    "bag": "Beutel",
    "bunch": "Bund",
    "head": "Kopf",
    "clove": "Zehe",
    "leaf": "Blatt",
    "leaves": "Blätter",
    "sprig": "Zweig",
    "stick": "Stange",
    "fillet": "Filet",
    "breast": "Brust",
    "thigh": "Schenkel",
    "wing": "Flügel",
    "leg": "Keule",
}


def translate_food_name(english_name: str) -> str:
    """Translate food name from English to German"""
    if not english_name:
        return english_name

    # Direct match
    if english_name in FOOD_TRANSLATIONS:
        return FOOD_TRANSLATIONS[english_name]

    # Try word-by-word translation for compound names
    german_name = english_name
    for en_word, de_word in sorted(FOOD_TRANSLATIONS.items(), key=lambda x: -len(x[0])):
        if en_word in german_name and len(en_word) > 2:
            german_name = german_name.replace(en_word, de_word)

    return german_name


def translate_unit(english_unit: str) -> str:
    """Translate unit from English to German"""
    if not english_unit:
        return english_unit

    # Direct match
    if english_unit in UNIT_TRANSLATIONS:
        return UNIT_TRANSLATIONS[english_unit]

    # Try partial match
    german_unit = english_unit
    for en_unit, de_unit in sorted(UNIT_TRANSLATIONS.items(), key=lambda x: -len(x[0])):
        if en_unit in german_unit:
            german_unit = german_unit.replace(en_unit, de_unit)

    return german_unit


def main():
    """Main function to translate all foods to German"""
    # Initialize Supabase client
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")

    if not supabase_url or not supabase_key:
        print("Error: SUPABASE_URL and SUPABASE_KEY environment variables are required")
        print("Please set them in .env file or as environment variables")
        sys.exit(1)

    print("🇩🇪 Starting German translation for food_database...")
    print(f"📚 Available translations: {len(FOOD_TRANSLATIONS)} foods, {len(UNIT_TRANSLATIONS)} units")

    supabase: Client = create_client(supabase_url, supabase_key)

    # Get all foods without German translation
    batch_size = 100
    offset = 0
    total_translated = 0

    while True:
        print(f"\n📦 Fetching batch at offset {offset}...")

        # Fetch foods where name_de is NULL
        response = supabase.table("food_database") \
            .select("id, name_en, reference_unit_en") \
            .is_("name_de", "null") \
            .order("id") \
            .range(offset, offset + batch_size - 1) \
            .execute()

        foods = response.data

        if not foods:
            print("✅ No more foods to translate!")
            break

        print(f"   Found {len(foods)} foods to translate")

        # Translate and update each food
        for food in foods:
            food_id = food["id"]
            name_en = food.get("name_en", "")
            unit_en = food.get("reference_unit_en", "")

            name_de = translate_food_name(name_en)
            unit_de = translate_unit(unit_en)

            # Update the food
            try:
                supabase.table("food_database") \
                    .update({
                        "name_de": name_de,
                        "reference_unit_de": unit_de
                    }) \
                    .eq("id", food_id) \
                    .execute()

                total_translated += 1

                if total_translated % 50 == 0:
                    print(f"   ✓ Translated {total_translated} foods...")

            except Exception as e:
                print(f"   ❌ Error updating food {food_id}: {e}")

        offset += batch_size

    print(f"\n🎉 Translation complete! Total foods translated: {total_translated}")


if __name__ == "__main__":
    main()
