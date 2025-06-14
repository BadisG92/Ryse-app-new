#!/usr/bin/env python3
"""
Multilingual Foods Dataset for Ryze App
Supports French (fr) and English (en) languages
"""

def get_multilingual_foods_dataset():
    """
    Returns foods dataset with multilingual support
    Structure: Each food item has translations for name, category, and serving_unit
    """
    return [
        {
            "id": 1,
            "translations": {
                "en": {
                    "name": "Apple",
                    "category": "fruits",
                    "serving_unit": "piece"
                },
                "fr": {
                    "name": "Pomme",
                    "category": "fruits",
                    "serving_unit": "pièce"
                }
            },
            "brand": None,
            "barcode": None,
            "calories_per_100g": 52.0,
            "protein_per_100g": 0.3,
            "carbs_per_100g": 14.0,
            "fat_per_100g": 0.2,
            "fiber_per_100g": 2.4,
            "sugar_per_100g": 10.4,
            "sodium_per_100g": 1.0,
            "serving_size": 150.0,
            "verified": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 2,
            "translations": {
                "en": {
                    "name": "Banana",
                    "category": "fruits",
                    "serving_unit": "piece"
                },
                "fr": {
                    "name": "Banane",
                    "category": "fruits",
                    "serving_unit": "pièce"
                }
            },
            "brand": None,
            "barcode": None,
            "calories_per_100g": 89.0,
            "protein_per_100g": 1.1,
            "carbs_per_100g": 23.0,
            "fat_per_100g": 0.3,
            "fiber_per_100g": 2.6,
            "sugar_per_100g": 12.2,
            "sodium_per_100g": 1.0,
            "serving_size": 120.0,
            "verified": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 3,
            "translations": {
                "en": {
                    "name": "Chicken Breast",
                    "category": "meat",
                    "serving_unit": "g"
                },
                "fr": {
                    "name": "Blanc de Poulet",
                    "category": "viande",
                    "serving_unit": "g"
                }
            },
            "brand": None,
            "barcode": None,
            "calories_per_100g": 165.0,
            "protein_per_100g": 31.0,
            "carbs_per_100g": 0.0,
            "fat_per_100g": 3.6,
            "fiber_per_100g": 0.0,
            "sugar_per_100g": 0.0,
            "sodium_per_100g": 74.0,
            "serving_size": 100.0,
            "verified": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 4,
            "translations": {
                "en": {
                    "name": "Brown Rice",
                    "category": "grains",
                    "serving_unit": "g"
                },
                "fr": {
                    "name": "Riz Complet",
                    "category": "céréales",
                    "serving_unit": "g"
                }
            },
            "brand": None,
            "barcode": None,
            "calories_per_100g": 111.0,
            "protein_per_100g": 2.6,
            "carbs_per_100g": 23.0,
            "fat_per_100g": 0.9,
            "fiber_per_100g": 1.8,
            "sugar_per_100g": 0.4,
            "sodium_per_100g": 5.0,
            "serving_size": 100.0,
            "verified": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 5,
            "translations": {
                "en": {
                    "name": "Greek Yogurt",
                    "category": "dairy",
                    "serving_unit": "g"
                },
                "fr": {
                    "name": "Yaourt Grec",
                    "category": "produits laitiers",
                    "serving_unit": "g"
                }
            },
            "brand": None,
            "barcode": None,
            "calories_per_100g": 59.0,
            "protein_per_100g": 10.0,
            "carbs_per_100g": 3.6,
            "fat_per_100g": 0.4,
            "fiber_per_100g": 0.0,
            "sugar_per_100g": 3.6,
            "sodium_per_100g": 36.0,
            "serving_size": 150.0,
            "verified": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
    ]

def get_food_categories_translations():
    """
    Returns translations for food categories
    """
    return {
        "fruits": {
            "en": "Fruits",
            "fr": "Fruits"
        },
        "vegetables": {
            "en": "Vegetables", 
            "fr": "Légumes"
        },
        "meat": {
            "en": "Meat",
            "fr": "Viande"
        },
        "fish": {
            "en": "Fish",
            "fr": "Poisson"
        },
        "dairy": {
            "en": "Dairy",
            "fr": "Produits Laitiers"
        },
        "grains": {
            "en": "Grains",
            "fr": "Céréales"
        },
        "nuts": {
            "en": "Nuts",
            "fr": "Noix"
        },
        "legumes": {
            "en": "Legumes",
            "fr": "Légumineuses"
        },
        "oils": {
            "en": "Oils",
            "fr": "Huiles"
        },
        "beverages": {
            "en": "Beverages",
            "fr": "Boissons"
        }
    }

def get_serving_units_translations():
    """
    Returns translations for serving units
    """
    return {
        "g": {
            "en": "g",
            "fr": "g"
        },
        "ml": {
            "en": "ml",
            "fr": "ml"
        },
        "piece": {
            "en": "piece",
            "fr": "pièce"
        },
        "cup": {
            "en": "cup",
            "fr": "tasse"
        },
        "tbsp": {
            "en": "tbsp",
            "fr": "c. à soupe"
        },
        "tsp": {
            "en": "tsp",
            "fr": "c. à thé"
        },
        "slice": {
            "en": "slice",
            "fr": "tranche"
        }
    } 