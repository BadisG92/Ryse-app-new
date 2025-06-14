"""
Tests pour l'API de contenu personnalisé - Task 8
Tests des fonctionnalités de création, partage et modération communautaire
"""

import pytest
from fastapi.testclient import TestClient
from uuid import uuid4
import json

# Mock dependencies pour les tests
def mock_get_supabase_client():
    """Mock du client Supabase pour les tests"""
    class MockSupabaseClient:
        def __init__(self):
            self.data = []
            self.count = 0
        
        def table(self, table_name):
            return MockSupabaseTable(table_name)
        
        def rpc(self, function_name, params=None):
            return MockRPCResult()
    
    return MockSupabaseClient()

def mock_get_current_user():
    """Mock de l'utilisateur actuel pour les tests"""
    return {
        "id": "test-user-123",
        "email": "test@example.com"
    }

class MockSupabaseTable:
    def __init__(self, table_name):
        self.table_name = table_name
        self._filters = {}
        self._data = self._get_mock_data()
    
    def _get_mock_data(self):
        """Données de test simulées"""
        if self.table_name == "foods":
            return [
                {
                    "id": "food-1",
                    "name_en": "Custom Protein Bar",
                    "name_fr": "Barre Protéinée Personnalisée",
                    "calories": 250,
                    "proteins": 20.0,
                    "carbs": 15.0,
                    "fats": 8.0,
                    "category": "snacks",
                    "tags": ["protein", "healthy"],
                    "is_custom": True,
                    "is_public": True,
                    "is_verified": False,
                    "community_rating": 4.2,
                    "rating_count": 15,
                    "user_id": "test-user-123"
                }
            ]
        elif self.table_name == "exercises":
            return [
                {
                    "id": "exercise-1",
                    "name_en": "Custom Push-up Variant",
                    "name_fr": "Variante Pompes Personnalisée",
                    "muscle_group": "chest",
                    "equipment": "bodyweight",
                    "description": "A custom push-up variation",
                    "difficulty_level": "intermediate",
                    "tags": ["strength", "upper-body"],
                    "is_custom": True,
                    "is_public": True,
                    "is_verified": True,
                    "community_rating": 4.5,
                    "rating_count": 8,
                    "user_id": "test-user-123"
                }
            ]
        elif self.table_name == "content_tags":
            return [
                {"id": "tag-1", "name": "Protein", "color": "#FF6B6B", "category": "food", "usage_count": 100},
                {"id": "tag-2", "name": "Strength", "color": "#4ECDC4", "category": "exercise", "usage_count": 75}
            ]
        elif self.table_name == "community_ratings":
            return [
                {
                    "id": "rating-1",
                    "user_id": "test-user-123",
                    "content_type": "food",
                    "content_id": "food-1",
                    "rating": 5,
                    "comment": "Excellent custom food!",
                    "created_at": "2024-01-15T10:00:00Z"
                }
            ]
        return []
    
    def select(self, columns="*"):
        return self
    
    def eq(self, column, value):
        return self
    
    def or_(self, condition):
        return self
    
    def gte(self, column, value):
        return self
    
    def contains(self, column, value):
        return self
    
    def ilike(self, column, pattern):
        return self
    
    def range(self, start, end):
        return self
    
    def order(self, column, desc=False):
        return self
    
    def insert(self, data):
        if isinstance(data, list):
            result_data = []
            for item in data:
                new_item = {**item, "id": str(uuid4())}
                result_data.append(new_item)
            return MockResult(result_data)
        else:
            new_item = {**data, "id": str(uuid4())}
            return MockResult([new_item])
    
    def update(self, data):
        updated_item = {**self._data[0], **data} if self._data else data
        return MockResult([updated_item])
    
    def delete(self):
        return MockResult([])
    
    def execute(self):
        return MockResult(self._data)

class MockResult:
    def __init__(self, data, count=None):
        self.data = data
        self.count = count or len(data)

class MockRPCResult:
    def execute(self):
        return MockResult([{
            "total_custom_foods": 5,
            "total_custom_exercises": 3,
            "total_custom_recipes": 2,
            "total_public_content": 10,
            "total_ratings": 25,
            "average_rating": 4.2,
            "top_contributors": []
        }])

# Tests avec mocking
@pytest.fixture
def client():
    """Client de test avec mocking des dépendances"""
    from custom_content_api import router, get_supabase_client, get_current_user
    from fastapi import FastAPI
    
    # Override dependencies
    router.dependency_overrides[get_supabase_client] = mock_get_supabase_client
    router.dependency_overrides[get_current_user] = mock_get_current_user
    
    app = FastAPI()
    app.include_router(router)
    
    yield TestClient(app)
    
    # Clean up
    router.dependency_overrides.clear()

# ==================== TESTS CUSTOM FOODS ====================

def test_get_custom_foods(client):
    """Test de récupération des aliments personnalisés"""
    response = client.get("/api/custom-content/foods")
    assert response.status_code == 200
    
    data = response.json()
    assert "data" in data
    assert "pagination" in data
    assert len(data["data"]) > 0

def test_get_custom_foods_with_filters(client):
    """Test de récupération avec filtres"""
    response = client.get("/api/custom-content/foods?search=protein&only_verified=true&min_rating=4.0")
    assert response.status_code == 200
    
    data = response.json()
    assert "data" in data

def test_create_custom_food(client):
    """Test de création d'aliment personnalisé"""
    food_data = {
        "name_en": "My Custom Smoothie",
        "name_fr": "Mon Smoothie Personnalisé",
        "calories": 180,
        "proteins": 15.0,
        "carbs": 25.0,
        "fats": 5.0,
        "category": "beverages",
        "tags": ["healthy", "protein"],
        "is_public": True
    }
    
    response = client.post("/api/custom-content/foods", json=food_data)
    assert response.status_code == 200
    
    result = response.json()
    assert "message" in result
    assert "food" in result
    assert result["food"]["name_en"] == food_data["name_en"]

def test_update_custom_food(client):
    """Test de mise à jour d'aliment personnalisé"""
    food_id = "food-1"
    update_data = {
        "name_en": "Updated Protein Bar",
        "name_fr": "Barre Protéinée Mise à Jour",
        "calories": 260,
        "proteins": 22.0,
        "carbs": 15.0,
        "fats": 8.0,
        "category": "snacks",
        "tags": ["protein", "healthy", "updated"],
        "is_public": True
    }
    
    response = client.put(f"/api/custom-content/foods/{food_id}", json=update_data)
    assert response.status_code == 200
    
    result = response.json()
    assert "message" in result
    assert result["food"]["calories"] == 260

def test_delete_custom_food(client):
    """Test de suppression d'aliment personnalisé"""
    food_id = "food-1"
    
    response = client.delete(f"/api/custom-content/foods/{food_id}")
    assert response.status_code == 200
    
    result = response.json()
    assert "message" in result

# ==================== TESTS CUSTOM EXERCISES ====================

def test_get_custom_exercises(client):
    """Test de récupération des exercices personnalisés"""
    response = client.get("/api/custom-content/exercises")
    assert response.status_code == 200
    
    data = response.json()
    assert "data" in data
    assert "pagination" in data

def test_create_custom_exercise(client):
    """Test de création d'exercice personnalisé"""
    exercise_data = {
        "name_en": "Custom Squat Variation",
        "name_fr": "Variante Squat Personnalisée",
        "muscle_group": "legs",
        "equipment": "bodyweight",
        "description": "A unique squat variation",
        "instructions_en": "Step-by-step instructions",
        "instructions_fr": "Instructions étape par étape",
        "difficulty_level": "beginner",
        "tags": ["strength", "legs"],
        "is_public": True
    }
    
    response = client.post("/api/custom-content/exercises", json=exercise_data)
    assert response.status_code == 200
    
    result = response.json()
    assert "message" in result
    assert "exercise" in result

# ==================== TESTS COLLECTIONS ====================

def test_get_user_collections(client):
    """Test de récupération des collections utilisateur"""
    response = client.get("/api/custom-content/collections")
    assert response.status_code == 200

def test_create_collection(client):
    """Test de création de collection"""
    collection_data = {
        "name": "Ma Collection de Favoris",
        "description": "Mes aliments et exercices préférés",
        "collection_type": "foods",
        "is_public": False,
        "item_ids": []
    }
    
    response = client.post("/api/custom-content/collections", json=collection_data)
    assert response.status_code == 200
    
    result = response.json()
    assert "message" in result
    assert "collection" in result

def test_add_item_to_collection(client):
    """Test d'ajout d'élément à une collection"""
    collection_id = "collection-1"
    item_id = "food-1"
    
    response = client.put(f"/api/custom-content/collections/{collection_id}/items/{item_id}")
    assert response.status_code == 200

def test_remove_item_from_collection(client):
    """Test de retrait d'élément d'une collection"""
    collection_id = "collection-1"
    item_id = "food-1"
    
    response = client.delete(f"/api/custom-content/collections/{collection_id}/items/{item_id}")
    assert response.status_code == 200

# ==================== TESTS COMMUNITY RATINGS ====================

def test_create_rating(client):
    """Test de création/mise à jour de note communautaire"""
    rating_data = {
        "content_type": "food",
        "content_id": "food-1",
        "rating": 5,
        "comment": "Excellent aliment personnalisé !",
        "is_helpful": True
    }
    
    response = client.post("/api/custom-content/ratings", json=rating_data)
    assert response.status_code == 200
    
    result = response.json()
    assert "message" in result
    assert "rating" in result

def test_get_content_ratings(client):
    """Test de récupération des notes d'un contenu"""
    content_type = "food"
    content_id = "food-1"
    
    response = client.get(f"/api/custom-content/ratings/{content_type}/{content_id}")
    assert response.status_code == 200
    
    result = response.json()
    assert "ratings" in result
    assert "statistics" in result
    assert "average" in result["statistics"]
    assert "count" in result["statistics"]

# ==================== TESTS CONTENT REPORTS ====================

def test_create_report(client):
    """Test de signalement de contenu"""
    report_data = {
        "content_type": "food",
        "content_id": "food-1",
        "reason": "incorrect_info",
        "description": "Les informations nutritionnelles semblent incorrectes"
    }
    
    response = client.post("/api/custom-content/reports", json=report_data)
    assert response.status_code == 200
    
    result = response.json()
    assert "message" in result
    assert "report" in result

# ==================== TESTS TAGS ====================

def test_get_content_tags(client):
    """Test de récupération des tags"""
    response = client.get("/api/custom-content/tags")
    assert response.status_code == 200
    
    tags = response.json()
    assert isinstance(tags, list)
    assert len(tags) > 0

def test_get_content_tags_by_category(client):
    """Test de récupération des tags par catégorie"""
    response = client.get("/api/custom-content/tags?category=food")
    assert response.status_code == 200
    
    tags = response.json()
    assert isinstance(tags, list)

def test_create_tag(client):
    """Test de création de tag"""
    tag_data = {
        "name": "Custom Tag",
        "color": "#FF5733",
        "category": "food"
    }
    
    response = client.post("/api/custom-content/tags", json=tag_data)
    assert response.status_code == 200
    
    result = response.json()
    assert "message" in result
    assert "tag" in result

# ==================== TESTS CONTENU SIMILAIRE ====================

def test_get_similar_content(client):
    """Test de récupération de contenu similaire"""
    content_type = "food"
    content_id = "food-1"
    
    response = client.get(f"/api/custom-content/similar/{content_type}/{content_id}?limit=5")
    assert response.status_code == 200
    
    result = response.json()
    assert "similar_content" in result

# ==================== TESTS STATISTIQUES COMMUNAUTÉ ====================

def test_get_community_stats(client):
    """Test de récupération des statistiques communautaires"""
    response = client.get("/api/custom-content/community/stats")
    assert response.status_code == 200
    
    result = response.json()
    assert "community_statistics" in result
    stats = result["community_statistics"]
    assert "total_custom_foods" in stats
    assert "total_custom_exercises" in stats
    assert "average_rating" in stats

# ==================== TESTS IMPORT EN MASSE ====================

def test_bulk_import_foods(client):
    """Test d'import en masse d'aliments"""
    foods_data = [
        {
            "name_en": "Bulk Food 1",
            "name_fr": "Aliment Masse 1",
            "calories": 100,
            "proteins": 10.0,
            "carbs": 15.0,
            "fats": 5.0,
            "category": "test",
            "tags": ["bulk"],
            "is_public": False
        },
        {
            "name_en": "Bulk Food 2",
            "name_fr": "Aliment Masse 2",
            "calories": 120,
            "proteins": 12.0,
            "carbs": 18.0,
            "fats": 6.0,
            "category": "test",
            "tags": ["bulk"],
            "is_public": False
        }
    ]
    
    response = client.post("/api/custom-content/import/foods", json=foods_data)
    assert response.status_code == 200
    
    result = response.json()
    assert "imported_count" in result
    assert result["imported_count"] == 2

def test_bulk_import_exercises(client):
    """Test d'import en masse d'exercices"""
    exercises_data = [
        {
            "name_en": "Bulk Exercise 1",
            "name_fr": "Exercice Masse 1",
            "muscle_group": "test",
            "equipment": "none",
            "description": "Test exercise",
            "difficulty_level": "beginner",
            "tags": ["bulk"],
            "is_public": False
        }
    ]
    
    response = client.post("/api/custom-content/import/exercises", json=exercises_data)
    assert response.status_code == 200
    
    result = response.json()
    assert "imported_count" in result
    assert result["imported_count"] == 1

# ==================== TESTS VALIDATION ====================

def test_create_food_validation_error(client):
    """Test de validation des données lors de la création d'aliment"""
    invalid_food_data = {
        "name_en": "Test Food",
        "name_fr": "Aliment Test",
        "calories": -50,  # Invalid: negative calories
        "proteins": "invalid",  # Invalid: should be numeric
        "carbs": 15.0,
        "fats": 5.0
    }
    
    response = client.post("/api/custom-content/foods", json=invalid_food_data)
    # Should return validation error (422)
    assert response.status_code in [422, 500]

def test_create_exercise_validation_error(client):
    """Test de validation des données lors de la création d'exercice"""
    invalid_exercise_data = {
        "name_en": "Test Exercise",
        "name_fr": "Exercice Test",
        "muscle_group": "test",
        "difficulty_level": "expert"  # Invalid: should be beginner/intermediate/advanced
    }
    
    response = client.post("/api/custom-content/exercises", json=invalid_exercise_data)
    assert response.status_code in [422, 500]

# ==================== TESTS D'INTÉGRATION ====================

def test_complete_workflow(client):
    """Test du workflow complet: création -> notation -> collection"""
    # 1. Créer un aliment personnalisé
    food_data = {
        "name_en": "Workflow Test Food",
        "name_fr": "Aliment Test Workflow",
        "calories": 200,
        "proteins": 15.0,
        "carbs": 20.0,
        "fats": 8.0,
        "category": "test",
        "tags": ["workflow"],
        "is_public": True
    }
    
    food_response = client.post("/api/custom-content/foods", json=food_data)
    assert food_response.status_code == 200
    food_id = food_response.json()["food"]["id"]
    
    # 2. Noter l'aliment
    rating_data = {
        "content_type": "food",
        "content_id": food_id,
        "rating": 4,
        "comment": "Test rating",
        "is_helpful": True
    }
    
    rating_response = client.post("/api/custom-content/ratings", json=rating_data)
    assert rating_response.status_code == 200
    
    # 3. Créer une collection
    collection_data = {
        "name": "Test Workflow Collection",
        "description": "Collection pour test workflow",
        "collection_type": "foods",
        "is_public": False,
        "item_ids": []
    }
    
    collection_response = client.post("/api/custom-content/collections", json=collection_data)
    assert collection_response.status_code == 200
    collection_id = collection_response.json()["collection"]["id"]
    
    # 4. Ajouter l'aliment à la collection
    add_to_collection_response = client.put(f"/api/custom-content/collections/{collection_id}/items/{food_id}")
    assert add_to_collection_response.status_code == 200

if __name__ == "__main__":
    pytest.main([__file__, "-v"])