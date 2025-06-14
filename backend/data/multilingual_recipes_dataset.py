#!/usr/bin/env python3
"""
Multilingual Recipes Dataset for Ryze App
Supports French (fr) and English (en) languages
"""

def get_multilingual_recipes_dataset():
    """
    Returns recipes dataset with multilingual support
    """
    return [
        {
            "id": 1,
            "translations": {
                "en": {
                    "name": "Grilled Chicken Salad",
                    "description": "Fresh mixed greens with grilled chicken breast, cherry tomatoes, and balsamic vinaigrette",
                    "category": "main_course",
                    "cuisine": "mediterranean",
                    "difficulty": "easy",
                    "instructions": [
                        "Season chicken breast with salt, pepper, and herbs",
                        "Grill chicken for 6-7 minutes per side until cooked through",
                        "Let chicken rest for 5 minutes, then slice",
                        "Wash and dry mixed greens thoroughly",
                        "Halve cherry tomatoes",
                        "Whisk olive oil, balsamic vinegar, and seasonings for dressing",
                        "Arrange greens on plates",
                        "Top with sliced chicken and tomatoes",
                        "Drizzle with balsamic vinaigrette"
                    ],
                    "tags": ["high_protein", "low_carb", "gluten_free", "healthy"]
                },
                "fr": {
                    "name": "Salade de Poulet Grillé",
                    "description": "Mélange de verdures fraîches avec blanc de poulet grillé, tomates cerises et vinaigrette balsamique",
                    "category": "plat_principal",
                    "cuisine": "méditerranéenne",
                    "difficulty": "facile",
                    "instructions": [
                        "Assaisonnez le blanc de poulet avec sel, poivre et herbes",
                        "Grillez le poulet 6-7 minutes de chaque côté jusqu'à cuisson complète",
                        "Laissez reposer le poulet 5 minutes, puis tranchez",
                        "Lavez et séchez soigneusement le mélange de verdures",
                        "Coupez les tomates cerises en deux",
                        "Fouettez l'huile d'olive, le vinaigre balsamique et les assaisonnements pour la vinaigrette",
                        "Disposez les verdures dans les assiettes",
                        "Garnissez avec le poulet tranché et les tomates",
                        "Arrosez de vinaigrette balsamique"
                    ],
                    "tags": ["riche_en_protéines", "faible_en_glucides", "sans_gluten", "sain"]
                }
            },
            "prep_time_minutes": 15,
            "cook_time_minutes": 15,
            "servings": 2,
            "calories_per_serving": 320,
            "protein_per_serving": 35.0,
            "carbs_per_serving": 8.0,
            "fat_per_serving": 16.0,
            "fiber_per_serving": 4.0,
            "ingredients": [
                {"food_name": "Chicken Breast", "quantity": 200, "unit": "g"},
                {"food_name": "Mixed Greens", "quantity": 100, "unit": "g"},
                {"food_name": "Cherry Tomatoes", "quantity": 150, "unit": "g"},
                {"food_name": "Olive Oil", "quantity": 15, "unit": "ml"},
                {"food_name": "Balsamic Vinegar", "quantity": 10, "unit": "ml"},
                {"food_name": "Cucumber", "quantity": 100, "unit": "g"},
                {"food_name": "Red Onion", "quantity": 30, "unit": "g"}
            ],
            "image_url": None,
            "created_by": "admin",
            "is_public": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 2,
            "translations": {
                "en": {
                    "name": "Protein Pancakes",
                    "description": "High-protein pancakes made with oats and eggs for a nutritious breakfast",
                    "category": "breakfast",
                    "cuisine": "american",
                    "difficulty": "easy",
                    "instructions": [
                        "Blend oats into flour consistency",
                        "Mash banana in a bowl",
                        "Whisk eggs and add to banana",
                        "Mix in oat flour and yogurt",
                        "Heat non-stick pan over medium heat",
                        "Pour batter to form pancakes",
                        "Cook 2-3 minutes until bubbles form",
                        "Flip and cook 2 minutes more",
                        "Serve with blueberries and honey"
                    ],
                    "tags": ["high_protein", "breakfast", "healthy", "gluten_free"]
                },
                "fr": {
                    "name": "Pancakes Protéinés",
                    "description": "Pancakes riches en protéines à base d'avoine et d'œufs pour un petit-déjeuner nutritif",
                    "category": "petit_déjeuner",
                    "cuisine": "américaine",
                    "difficulty": "facile",
                    "instructions": [
                        "Mixez l'avoine jusqu'à obtenir une consistance de farine",
                        "Écrasez la banane dans un bol",
                        "Battez les œufs et ajoutez à la banane",
                        "Incorporez la farine d'avoine et le yaourt",
                        "Chauffez une poêle antiadhésive à feu moyen",
                        "Versez la pâte pour former des pancakes",
                        "Cuisez 2-3 minutes jusqu'à formation de bulles",
                        "Retournez et cuisez 2 minutes de plus",
                        "Servez avec des myrtilles et du miel"
                    ],
                    "tags": ["riche_en_protéines", "petit_déjeuner", "sain", "sans_gluten"]
                }
            },
            "prep_time_minutes": 10,
            "cook_time_minutes": 10,
            "servings": 2,
            "calories_per_serving": 320,
            "protein_per_serving": 22.0,
            "carbs_per_serving": 35.0,
            "fat_per_serving": 8.0,
            "fiber_per_serving": 6.0,
            "ingredients": [
                {"food_name": "Oats", "quantity": 80, "unit": "g"},
                {"food_name": "Eggs", "quantity": 100, "unit": "g"},
                {"food_name": "Greek Yogurt", "quantity": 100, "unit": "g"},
                {"food_name": "Banana", "quantity": 100, "unit": "g"},
                {"food_name": "Blueberries", "quantity": 80, "unit": "g"},
                {"food_name": "Honey", "quantity": 20, "unit": "g"}
            ],
            "image_url": None,
            "created_by": "admin",
            "is_public": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 3,
            "translations": {
                "en": {
                    "name": "Buddha Bowl with Tahini Dressing",
                    "description": "Colorful bowl with roasted vegetables, quinoa, and creamy tahini dressing",
                    "category": "lunch",
                    "cuisine": "mediterranean",
                    "difficulty": "medium",
                    "instructions": [
                        "Cook quinoa according to package instructions",
                        "Roast cubed sweet potato at 200°C for 20 minutes",
                        "Massage kale with olive oil and lemon",
                        "Mix tahini with lemon juice and water for dressing",
                        "Arrange quinoa in bowls",
                        "Top with roasted sweet potato and chickpeas",
                        "Add massaged kale and sliced avocado",
                        "Drizzle with tahini dressing"
                    ],
                    "tags": ["vegan", "high_fiber", "plant_based", "healthy"]
                },
                "fr": {
                    "name": "Buddha Bowl à la Sauce Tahini",
                    "description": "Bol coloré avec légumes rôtis, quinoa et sauce crémeuse au tahini",
                    "category": "déjeuner",
                    "cuisine": "méditerranéenne",
                    "difficulty": "moyen",
                    "instructions": [
                        "Cuisez le quinoa selon les instructions de l'emballage",
                        "Rôtissez la patate douce en cubes à 200°C pendant 20 minutes",
                        "Massez le chou kale avec huile d'olive et citron",
                        "Mélangez le tahini avec jus de citron et eau pour la sauce",
                        "Disposez le quinoa dans les bols",
                        "Garnissez avec patate douce rôtie et pois chiches",
                        "Ajoutez le chou kale massé et l'avocat tranché",
                        "Arrosez de sauce tahini"
                    ],
                    "tags": ["végétalien", "riche_en_fibres", "à_base_de_plantes", "sain"]
                }
            },
            "prep_time_minutes": 20,
            "cook_time_minutes": 25,
            "servings": 2,
            "calories_per_serving": 480,
            "protein_per_serving": 18.0,
            "carbs_per_serving": 62.0,
            "fat_per_serving": 20.0,
            "fiber_per_serving": 14.0,
            "ingredients": [
                {"food_name": "Quinoa", "quantity": 150, "unit": "g"},
                {"food_name": "Sweet Potato", "quantity": 200, "unit": "g"},
                {"food_name": "Chickpeas", "quantity": 150, "unit": "g"},
                {"food_name": "Kale", "quantity": 80, "unit": "g"},
                {"food_name": "Avocado", "quantity": 100, "unit": "g"},
                {"food_name": "Tahini", "quantity": 30, "unit": "g"},
                {"food_name": "Lemon", "quantity": 20, "unit": "ml"},
                {"food_name": "Olive Oil", "quantity": 15, "unit": "ml"}
            ],
            "image_url": None,
            "created_by": "admin",
            "is_public": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
    ]

def get_recipe_categories_translations():
    """
    Returns translations for recipe categories
    """
    return {
        "breakfast": {
            "en": "Breakfast",
            "fr": "Petit-déjeuner"
        },
        "lunch": {
            "en": "Lunch",
            "fr": "Déjeuner"
        },
        "dinner": {
            "en": "Dinner",
            "fr": "Dîner"
        },
        "snack": {
            "en": "Snack",
            "fr": "Collation"
        },
        "main_course": {
            "en": "Main Course",
            "fr": "Plat Principal"
        },
        "soup": {
            "en": "Soup",
            "fr": "Soupe"
        },
        "salad": {
            "en": "Salad",
            "fr": "Salade"
        },
        "dessert": {
            "en": "Dessert",
            "fr": "Dessert"
        }
    }

def get_cuisine_translations():
    """
    Returns translations for cuisine types
    """
    return {
        "mediterranean": {
            "en": "Mediterranean",
            "fr": "Méditerranéenne"
        },
        "american": {
            "en": "American",
            "fr": "Américaine"
        },
        "asian": {
            "en": "Asian",
            "fr": "Asiatique"
        },
        "thai": {
            "en": "Thai",
            "fr": "Thaï"
        },
        "italian": {
            "en": "Italian",
            "fr": "Italienne"
        },
        "french": {
            "en": "French",
            "fr": "Française"
        },
        "mexican": {
            "en": "Mexican",
            "fr": "Mexicaine"
        },
        "indian": {
            "en": "Indian",
            "fr": "Indienne"
        },
        "modern": {
            "en": "Modern",
            "fr": "Moderne"
        }
    }

def get_difficulty_translations():
    """
    Returns translations for difficulty levels
    """
    return {
        "easy": {
            "en": "Easy",
            "fr": "Facile"
        },
        "medium": {
            "en": "Medium",
            "fr": "Moyen"
        },
        "hard": {
            "en": "Hard",
            "fr": "Difficile"
        }
    }

def get_recipe_tags_translations():
    """
    Returns translations for recipe tags
    """
    return {
        "high_protein": {
            "en": "High Protein",
            "fr": "Riche en Protéines"
        },
        "low_carb": {
            "en": "Low Carb",
            "fr": "Faible en Glucides"
        },
        "gluten_free": {
            "en": "Gluten Free",
            "fr": "Sans Gluten"
        },
        "vegan": {
            "en": "Vegan",
            "fr": "Végétalien"
        },
        "vegetarian": {
            "en": "Vegetarian",
            "fr": "Végétarien"
        },
        "healthy": {
            "en": "Healthy",
            "fr": "Sain"
        },
        "quick": {
            "en": "Quick",
            "fr": "Rapide"
        },
        "make_ahead": {
            "en": "Make Ahead",
            "fr": "À Préparer à l'Avance"
        },
        "high_fiber": {
            "en": "High Fiber",
            "fr": "Riche en Fibres"
        },
        "plant_based": {
            "en": "Plant Based",
            "fr": "À Base de Plantes"
        }
    } 