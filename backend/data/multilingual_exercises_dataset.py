#!/usr/bin/env python3
"""
Multilingual Exercises Dataset for Ryze App
Supports French (fr) and English (en) languages
"""

def get_multilingual_exercises_dataset():
    """
    Returns exercises dataset with multilingual support
    """
    return [
        {
            "id": 1,
            "translations": {
                "en": {
                    "name": "Push-ups",
                    "category": "strength",
                    "muscle_group": "chest",
                    "secondary_muscles": ["shoulders", "triceps"],
                    "equipment": "bodyweight",
                    "difficulty": "intermediate",
                    "instructions": [
                        "Start in plank position with hands shoulder-width apart",
                        "Keep body in straight line from head to heels",
                        "Lower chest toward ground by bending elbows",
                        "Push back up to starting position",
                        "Keep core engaged throughout movement"
                    ],
                    "tips": [
                        "Keep elbows at 45-degree angle to body",
                        "Don't let hips sag or pike up",
                        "Modify on knees if needed"
                    ]
                },
                "fr": {
                    "name": "Pompes",
                    "category": "force",
                    "muscle_group": "pectoraux",
                    "secondary_muscles": ["épaules", "triceps"],
                    "equipment": "poids du corps",
                    "difficulty": "intermédiaire",
                    "instructions": [
                        "Commencez en position de planche avec les mains écartées à la largeur des épaules",
                        "Gardez le corps en ligne droite de la tête aux talons",
                        "Abaissez la poitrine vers le sol en pliant les coudes",
                        "Repoussez vers la position de départ",
                        "Gardez le tronc engagé tout au long du mouvement"
                    ],
                    "tips": [
                        "Gardez les coudes à un angle de 45 degrés par rapport au corps",
                        "Ne laissez pas les hanches s'affaisser ou se relever",
                        "Modifiez sur les genoux si nécessaire"
                    ]
                }
            },
            "calories_per_minute": 8,
            "duration_minutes": 1,
            "sets": 3,
            "reps": 10,
            "rest_seconds": 60,
            "image_url": None,
            "video_url": None,
            "is_public": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 2,
            "translations": {
                "en": {
                    "name": "Squats",
                    "category": "strength",
                    "muscle_group": "legs",
                    "secondary_muscles": ["glutes", "core"],
                    "equipment": "bodyweight",
                    "difficulty": "beginner",
                    "instructions": [
                        "Stand with feet shoulder-width apart",
                        "Keep chest up and core engaged",
                        "Lower by pushing hips back and bending knees",
                        "Go down until thighs are parallel to floor",
                        "Drive through heels to return to standing"
                    ],
                    "tips": [
                        "Keep knees aligned with toes",
                        "Don't let knees cave inward",
                        "Keep weight on heels"
                    ]
                },
                "fr": {
                    "name": "Squats",
                    "category": "force",
                    "muscle_group": "jambes",
                    "secondary_muscles": ["fessiers", "tronc"],
                    "equipment": "poids du corps",
                    "difficulty": "débutant",
                    "instructions": [
                        "Tenez-vous debout, pieds écartés à la largeur des épaules",
                        "Gardez la poitrine haute et le tronc engagé",
                        "Descendez en poussant les hanches vers l'arrière et en pliant les genoux",
                        "Descendez jusqu'à ce que les cuisses soient parallèles au sol",
                        "Poussez sur les talons pour revenir debout"
                    ],
                    "tips": [
                        "Gardez les genoux alignés avec les orteils",
                        "Ne laissez pas les genoux s'effondrer vers l'intérieur",
                        "Gardez le poids sur les talons"
                    ]
                }
            },
            "calories_per_minute": 6,
            "duration_minutes": 1,
            "sets": 3,
            "reps": 15,
            "rest_seconds": 45,
            "image_url": None,
            "video_url": None,
            "is_public": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 3,
            "translations": {
                "en": {
                    "name": "Jumping Jacks",
                    "category": "cardio",
                    "muscle_group": "full_body",
                    "secondary_muscles": [],
                    "equipment": "bodyweight",
                    "difficulty": "beginner",
                    "instructions": [
                        "Start standing with feet together, arms at sides",
                        "Jump feet apart while raising arms overhead",
                        "Jump feet back together while lowering arms",
                        "Maintain steady rhythm",
                        "Land softly on balls of feet"
                    ],
                    "tips": [
                        "Keep core engaged",
                        "Land softly to protect joints",
                        "Modify by stepping instead of jumping"
                    ]
                },
                "fr": {
                    "name": "Jumping Jacks",
                    "category": "cardio",
                    "muscle_group": "corps entier",
                    "secondary_muscles": [],
                    "equipment": "poids du corps",
                    "difficulty": "débutant",
                    "instructions": [
                        "Commencez debout, pieds joints, bras le long du corps",
                        "Sautez en écartant les pieds tout en levant les bras au-dessus de la tête",
                        "Sautez pour remettre les pieds ensemble tout en abaissant les bras",
                        "Maintenez un rythme régulier",
                        "Atterrissez doucement sur la pointe des pieds"
                    ],
                    "tips": [
                        "Gardez le tronc engagé",
                        "Atterrissez doucement pour protéger les articulations",
                        "Modifiez en marchant au lieu de sauter"
                    ]
                }
            },
            "calories_per_minute": 10,
            "duration_minutes": 1,
            "sets": 3,
            "reps": 30,
            "rest_seconds": 30,
            "image_url": None,
            "video_url": None,
            "is_public": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "id": 4,
            "translations": {
                "en": {
                    "name": "Downward Dog",
                    "category": "flexibility",
                    "muscle_group": "back",
                    "secondary_muscles": ["shoulders", "hamstrings"],
                    "equipment": "bodyweight",
                    "difficulty": "beginner",
                    "instructions": [
                        "Start on hands and knees",
                        "Tuck toes under and lift hips up",
                        "Straighten legs and create inverted V shape",
                        "Press hands firmly into ground",
                        "Hold position and breathe deeply"
                    ],
                    "tips": [
                        "Keep hands shoulder-width apart",
                        "Pedal feet to warm up calves",
                        "Don't worry if heels don't touch ground"
                    ]
                },
                "fr": {
                    "name": "Chien Tête en Bas",
                    "category": "flexibilité",
                    "muscle_group": "dos",
                    "secondary_muscles": ["épaules", "ischio-jambiers"],
                    "equipment": "poids du corps",
                    "difficulty": "débutant",
                    "instructions": [
                        "Commencez à quatre pattes",
                        "Rentrez les orteils et soulevez les hanches",
                        "Tendez les jambes et créez une forme de V inversé",
                        "Appuyez fermement les mains au sol",
                        "Maintenez la position et respirez profondément"
                    ],
                    "tips": [
                        "Gardez les mains écartées à la largeur des épaules",
                        "Pédalez avec les pieds pour échauffer les mollets",
                        "Ne vous inquiétez pas si les talons ne touchent pas le sol"
                    ]
                }
            },
            "calories_per_minute": 3,
            "duration_minutes": 1,
            "sets": 1,
            "reps": 1,
            "rest_seconds": 0,
            "image_url": None,
            "video_url": None,
            "is_public": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
    ]

def get_exercise_categories_translations():
    """
    Returns translations for exercise categories
    """
    return {
        "strength": {
            "en": "Strength",
            "fr": "Force"
        },
        "cardio": {
            "en": "Cardio",
            "fr": "Cardio"
        },
        "flexibility": {
            "en": "Flexibility",
            "fr": "Flexibilité"
        }
    }

def get_muscle_groups_translations():
    """
    Returns translations for muscle groups
    """
    return {
        "chest": {
            "en": "Chest",
            "fr": "Pectoraux"
        },
        "legs": {
            "en": "Legs",
            "fr": "Jambes"
        },
        "back": {
            "en": "Back",
            "fr": "Dos"
        },
        "shoulders": {
            "en": "Shoulders",
            "fr": "Épaules"
        },
        "arms": {
            "en": "Arms",
            "fr": "Bras"
        },
        "core": {
            "en": "Core",
            "fr": "Tronc"
        },
        "glutes": {
            "en": "Glutes",
            "fr": "Fessiers"
        },
        "full_body": {
            "en": "Full Body",
            "fr": "Corps Entier"
        }
    }

def get_equipment_translations():
    """
    Returns translations for equipment types
    """
    return {
        "bodyweight": {
            "en": "Bodyweight",
            "fr": "Poids du Corps"
        },
        "dumbbells": {
            "en": "Dumbbells",
            "fr": "Haltères"
        },
        "resistance_bands": {
            "en": "Resistance Bands",
            "fr": "Bandes de Résistance"
        },
        "yoga_mat": {
            "en": "Yoga Mat",
            "fr": "Tapis de Yoga"
        },
        "bench": {
            "en": "Bench",
            "fr": "Banc"
        }
    }

def get_difficulty_translations():
    """
    Returns translations for difficulty levels
    """
    return {
        "beginner": {
            "en": "Beginner",
            "fr": "Débutant"
        },
        "intermediate": {
            "en": "Intermediate",
            "fr": "Intermédiaire"
        },
        "advanced": {
            "en": "Advanced",
            "fr": "Avancé"
        }
    } 