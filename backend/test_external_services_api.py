"""
Tests pour External Services API - Task 9
Tests optimisés pour barcode scanning et GPS tracking mobile
"""

import pytest
import json
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timedelta
import aiohttp
from uuid import uuid4
from fastapi import FastAPI
from fastapi.testclient import TestClient

# Import des classes à tester
from external_services_api import (
    BarcodeService, GPSTrackingService, router,
    BarcodeProductInfo, GPSPoint, GPSBatchPoints, GPSTrackingSessionCreate,
    calculate_realtime_session_metrics, process_gps_points_batch
)

# ==================== FIXTURES ====================

@pytest.fixture
def mock_supabase_client():
    """Mock client Supabase pour les tests"""
    mock_client = MagicMock()
    
    # Mock des responses typiques
    mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []
    mock_client.table.return_value.insert.return_value.execute.return_value.data = [{"id": "test-id"}]
    mock_client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{"id": "test-id"}]
    
    return mock_client

@pytest.fixture
def mock_current_user():
    """Mock utilisateur authentifié"""
    return {"id": "test-user-123", "email": "test@ryze.app"}

@pytest.fixture
def sample_barcode_product():
    """Exemple de produit avec code-barres"""
    return BarcodeProductInfo(
        barcode="1234567890123",
        product_name="Protein Bar",
        brand="TestBrand",
        category="Sports Nutrition",
        calories=280,
        proteins=20,
        carbs=30,
        fats=8,
        data_source="openfoodfacts",
        quality_score=85
    )

@pytest.fixture
def sample_gps_points():
    """Exemple de points GPS pour test"""
    base_time = datetime.now()
    return [
        GPSPoint(
            latitude=48.8566,
            longitude=2.3522,
            altitude_meters=35.0,
            accuracy_meters=5.0,
            speed_mps=2.5,
            recorded_at=base_time + timedelta(seconds=i*5),
            battery_level=90 - i,
            signal_strength=85
        ) for i in range(10)
    ]

# ==================== TESTS BARCODE SERVICE ====================

class TestBarcodeService:
    """Tests pour le service de scan de codes-barres"""
    
    @pytest.mark.asyncio
    async def test_search_openfoodfacts_success(self):
        """Test recherche réussie dans OpenFoodFacts"""
        service = BarcodeService()
        
        mock_response_data = {
            "status": 1,
            "product": {
                "product_name": "Test Product",
                "brands": "Test Brand",
                "categories": "Food",
                "nutriments": {
                    "energy-kcal_100g": 250,
                    "proteins_100g": 15,
                    "carbohydrates_100g": 30,
                    "fat_100g": 5
                },
                "ingredients_text": "Water, protein, vitamins",
                "image_url": "https://example.com/image.jpg"
            }
        }
        
        with patch('aiohttp.ClientSession.get') as mock_get:
            mock_response = AsyncMock()
            mock_response.status = 200
            mock_response.json.return_value = mock_response_data
            mock_get.return_value.__aenter__.return_value = mock_response
            
            result = await service._search_openfoodfacts("1234567890123")
            
            assert result is not None
            assert result.product_name == "Test Product"
            assert result.brand == "Test Brand"
            assert result.calories == 250
            assert result.data_source == "openfoodfacts"
    
    @pytest.mark.asyncio
    async def test_search_openfoodfacts_not_found(self):
        """Test produit non trouvé dans OpenFoodFacts"""
        service = BarcodeService()
        
        with patch('aiohttp.ClientSession.get') as mock_get:
            mock_response = AsyncMock()
            mock_response.status = 404
            mock_get.return_value.__aenter__.return_value = mock_response
            
            result = await service._search_openfoodfacts("0000000000000")
            
            assert result is None
    
    @pytest.mark.asyncio
    async def test_cache_product(self, mock_supabase_client, sample_barcode_product):
        """Test mise en cache d'un produit"""
        service = BarcodeService()
        
        with patch('external_services_api.get_supabase_client', return_value=mock_supabase_client):
            # Simuler produit non existant
            mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []
            
            await service._cache_product(sample_barcode_product)
            
            # Vérifier insertion
            mock_supabase_client.table.assert_called_with("barcode_foods")
    
    @pytest.mark.asyncio
    async def test_get_cached_product(self, mock_supabase_client, sample_barcode_product):
        """Test récupération produit du cache"""
        service = BarcodeService()
        
        with patch('external_services_api.get_supabase_client', return_value=mock_supabase_client):
            # Simuler produit en cache
            mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
                sample_barcode_product.dict()
            ]
            
            result = await service._get_cached_product("1234567890123")
            
            assert result is not None
            assert result.barcode == sample_barcode_product.barcode

# ==================== TESTS GPS SERVICE ====================

class TestGPSTrackingService:
    """Tests pour le service de tracking GPS"""
    
    def test_calculate_distance(self):
        """Test calcul de distance GPS (formule haversine)"""
        # Paris -> Londres (distance réelle ~344 km)
        paris_lat, paris_lon = 48.8566, 2.3522
        london_lat, london_lon = 51.5074, -0.1278
        
        distance = GPSTrackingService.calculate_distance(
            paris_lat, paris_lon, london_lat, london_lon
        )
        
        # Vérifier que la distance est proche de 344km (tolérance 10km)
        assert 334000 <= distance <= 354000
    
    def test_calculate_distance_same_point(self):
        """Test distance entre points identiques"""
        distance = GPSTrackingService.calculate_distance(
            48.8566, 2.3522, 48.8566, 2.3522
        )
        assert distance == 0.0
    
    def test_calculate_speed(self):
        """Test calcul de vitesse"""
        # 1000m en 100s = 36 km/h
        speed = GPSTrackingService.calculate_speed(1000, 100)
        assert speed == 36.0
        
        # Test division par zéro
        speed = GPSTrackingService.calculate_speed(1000, 0)
        assert speed == 0.0
    
    def test_is_point_valid(self, sample_gps_points):
        """Test validation de points GPS"""
        # Point valide
        assert GPSTrackingService.is_point_valid(sample_gps_points[0])
        
        # Coordonnées invalides
        invalid_point = GPSPoint(
            latitude=91.0,  # > 90°
            longitude=2.3522,
            recorded_at=datetime.now()
        )
        assert not GPSTrackingService.is_point_valid(invalid_point)
        
        # Vitesse irréaliste
        point1 = sample_gps_points[0]
        point2 = GPSPoint(
            latitude=48.8566 + 1.0,  # ~100km de différence
            longitude=2.3522,
            recorded_at=point1.recorded_at + timedelta(seconds=1)  # 1 seconde plus tard
        )
        assert not GPSTrackingService.is_point_valid(point2, point1)

# ==================== TESTS ENDPOINTS BARCODE ====================

class TestBarcodeEndpoints:
    """Tests pour les endpoints de scan de codes-barres"""
    
    @pytest.mark.asyncio
    async def test_search_barcode_success(self, mock_current_user):
        """Test recherche de code-barres réussie"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user), \
             patch('external_services_api.BarcodeService') as mock_service:
            
            # Mock du service
            mock_instance = mock_service.return_value
            mock_instance.search_barcode.return_value = BarcodeProductInfo(
                barcode="1234567890123",
                product_name="Test Product",
                calories=250
            )
            
            response = client.post("/barcode/search", json={
                "barcode": "1234567890123",
                "force_refresh": False,
                "preferred_sources": ["openfoodfacts"]
            })
            
            assert response.status_code == 200
            data = response.json()
            assert data["found"] is True
            assert data["product"]["product_name"] == "Test Product"
    
    @pytest.mark.asyncio
    async def test_get_popular_products(self, mock_current_user, mock_supabase_client):
        """Test récupération des produits populaires"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user), \
             patch('external_services_api.get_supabase_client', return_value=mock_supabase_client):
            
            # Mock des produits populaires
            mock_supabase_client.table.return_value.select.return_value.order.return_value.limit.return_value.execute.return_value.data = [
                {
                    "barcode": "1234567890123",
                    "product_name": "Popular Product",
                    "scan_count": 100,
                    "calories": 250
                }
            ]
            
            response = client.get("/barcode/popular?limit=10")
            
            assert response.status_code == 200
            data = response.json()
            assert len(data) == 1
            assert data[0]["product_name"] == "Popular Product"

# ==================== TESTS ENDPOINTS GPS ====================

class TestGPSEndpoints:
    """Tests pour les endpoints de tracking GPS"""
    
    @pytest.mark.asyncio
    async def test_create_gps_session(self, mock_current_user, mock_supabase_client):
        """Test création d'une session GPS"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user), \
             patch('external_services_api.get_supabase_client', return_value=mock_supabase_client):
            
            # Mock de la création de session
            mock_supabase_client.table.return_value.insert.return_value.execute.return_value.data = [{
                "id": "session-123",
                "user_id": "test-user-123",
                "activity_type": "running",
                "status": "active"
            }]
            
            response = client.post("/gps/sessions", json={
                "activity_type": "running",
                "tracking_accuracy": "high",
                "device_info": {"platform": "ios", "version": "14.0"}
            })
            
            assert response.status_code == 200
            data = response.json()
            assert data["message"] == "Session GPS créée"
            assert "session" in data
            assert "config" in data
    
    @pytest.mark.asyncio
    async def test_upload_gps_points_batch(self, mock_current_user, mock_supabase_client, sample_gps_points):
        """Test upload de points GPS en batch"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        session_id = str(uuid4())
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user), \
             patch('external_services_api.get_supabase_client', return_value=mock_supabase_client):
            
            # Mock vérification session
            mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
                "user_id": "test-user-123"
            }]
            
            # Préparer les données de points
            points_data = []
            for point in sample_gps_points[:5]:  # 5 points seulement
                points_data.append({
                    "latitude": point.latitude,
                    "longitude": point.longitude,
                    "altitude_meters": point.altitude_meters,
                    "accuracy_meters": point.accuracy_meters,
                    "speed_mps": point.speed_mps,
                    "recorded_at": point.recorded_at.isoformat(),
                    "battery_level": point.battery_level,
                    "signal_strength": point.signal_strength
                })
            
            response = client.post("/gps/points/batch", json={
                "session_id": session_id,
                "points": points_data
            })
            
            assert response.status_code == 200
            data = response.json()
            assert "points_count" in data
            assert data["points_count"] == 5
    
    @pytest.mark.asyncio
    async def test_get_session_stats_active(self, mock_current_user, mock_supabase_client):
        """Test récupération des stats d'une session active"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        session_id = str(uuid4())
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user), \
             patch('external_services_api.get_supabase_client', return_value=mock_supabase_client), \
             patch('external_services_api.calculate_realtime_session_metrics') as mock_calc:
            
            # Mock session active
            mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
                "id": session_id,
                "status": "active",
                "user_id": "test-user-123"
            }]
            
            # Mock calcul métriques temps réel
            mock_calc.return_value = {
                "total_distance_meters": 1000.0,
                "duration_seconds": 300,
                "average_speed_kmh": 12.0,
                "max_speed_kmh": 15.0,
                "elevation_gain_meters": 50.0,
                "pace_per_km_seconds": 300,
                "point_count": 60
            }
            
            response = client.get(f"/gps/sessions/{session_id}/stats")
            
            assert response.status_code == 200
            data = response.json()
            assert data["total_distance_meters"] == 1000.0
            assert data["average_speed_kmh"] == 12.0

# ==================== TESTS CONFIGURATION MOBILE ====================

class TestMobileConfig:
    """Tests pour la configuration mobile"""
    
    @pytest.mark.asyncio
    async def test_get_mobile_config_ios(self, mock_current_user):
        """Test configuration optimisée iOS"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user):
            response = client.get("/mobile/config?platform=ios")
            
            assert response.status_code == 200
            data = response.json()
            
            # Configuration iOS spécifique
            assert data["gps_update_interval_seconds"] == 3
            assert data["gps_accuracy_threshold_meters"] == 5.0
            assert data["batch_upload_size"] == 25
    
    @pytest.mark.asyncio
    async def test_get_mobile_config_android(self, mock_current_user):
        """Test configuration optimisée Android"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user):
            response = client.get("/mobile/config?platform=android")
            
            assert response.status_code == 200
            data = response.json()
            
            # Configuration Android spécifique
            assert data["gps_update_interval_seconds"] == 5
            assert data["gps_accuracy_threshold_meters"] == 10.0
            assert data["batch_upload_size"] == 50
    
    @pytest.mark.asyncio
    async def test_mobile_health_check(self):
        """Test health check mobile"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        with patch('external_services_api.get_supabase_client', return_value=MagicMock()):
            response = client.get("/mobile/health")
            
            assert response.status_code == 200
            data = response.json()
            
            assert "status" in data
            assert "services" in data
            assert "response_time_ms" in data
            assert "timestamp" in data

# ==================== TESTS FONCTIONS UTILITAIRES ====================

class TestUtilityFunctions:
    """Tests pour les fonctions utilitaires"""
    
    @pytest.mark.asyncio
    async def test_process_gps_points_batch(self, mock_supabase_client, sample_gps_points):
        """Test traitement d'un batch de points GPS"""
        session_id = str(uuid4())
        
        # Créer un batch
        batch = GPSBatchPoints(
            session_id=uuid4(),
            points=sample_gps_points[:5]
        )
        
        with patch('external_services_api.get_supabase_client', return_value=mock_supabase_client):
            # Mock pas de points précédents
            mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []
            
            await process_gps_points_batch(batch, session_id)
            
            # Vérifier insertion des points
            mock_supabase_client.table.assert_called()
    
    @pytest.mark.asyncio
    async def test_calculate_realtime_session_metrics(self, mock_supabase_client):
        """Test calcul de métriques en temps réel"""
        session_id = str(uuid4())
        
        # Mock points GPS
        mock_points = [
            {
                "distance_from_previous_meters": 100,
                "speed_mps": 3.0,
                "recorded_at": "2024-01-01T10:00:00+00:00"
            },
            {
                "distance_from_previous_meters": 150,
                "speed_mps": 4.0,
                "recorded_at": "2024-01-01T10:01:00+00:00"
            }
        ]
        
        with patch('external_services_api.get_supabase_client', return_value=mock_supabase_client):
            mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = mock_points
            
            metrics = await calculate_realtime_session_metrics(session_id)
            
            assert "total_distance_meters" in metrics
            assert "average_speed_kmh" in metrics
            assert "max_speed_kmh" in metrics
            assert metrics["point_count"] == 2

# ==================== TESTS D'INTÉGRATION ====================

class TestIntegration:
    """Tests d'intégration end-to-end"""
    
    @pytest.mark.asyncio
    async def test_complete_gps_tracking_workflow(self, mock_current_user, mock_supabase_client, sample_gps_points):
        """Test complet d'un workflow de tracking GPS"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user), \
             patch('external_services_api.get_supabase_client', return_value=mock_supabase_client):
            
            # 1. Créer session
            mock_supabase_client.table.return_value.insert.return_value.execute.return_value.data = [{
                "id": "session-123",
                "user_id": "test-user-123",
                "status": "active"
            }]
            
            session_response = client.post("/gps/sessions", json={
                "activity_type": "running",
                "tracking_accuracy": "high"
            })
            
            assert session_response.status_code == 200
            session_id = session_response.json()["session"]["id"]
            
            # 2. Upload points
            mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
                "user_id": "test-user-123"
            }]
            
            points_data = []
            for point in sample_gps_points[:3]:
                points_data.append({
                    "latitude": point.latitude,
                    "longitude": point.longitude,
                    "recorded_at": point.recorded_at.isoformat()
                })
            
            upload_response = client.post("/gps/points/batch", json={
                "session_id": session_id,
                "points": points_data
            })
            
            assert upload_response.status_code == 200
            
            # 3. Terminer session
            update_response = client.put(f"/gps/sessions/{session_id}", json={
                "status": "completed"
            })
            
            assert update_response.status_code == 200
    
    @pytest.mark.asyncio
    async def test_barcode_to_nutrition_integration(self, mock_current_user):
        """Test intégration scan barcode vers nutrition"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user), \
             patch('external_services_api.BarcodeService') as mock_service:
            
            # Mock produit trouvé
            product = BarcodeProductInfo(
                barcode="1234567890123",
                product_name="Protein Bar",
                calories=280,
                proteins=20,
                carbs=30,
                fats=8
            )
            
            mock_instance = mock_service.return_value
            mock_instance.search_barcode.return_value = product
            
            response = client.post("/barcode/search", json={
                "barcode": "1234567890123"
            })
            
            assert response.status_code == 200
            data = response.json()
            
            # Vérifier que les données sont compatibles pour le module nutrition
            product_data = data["product"]
            assert product_data["calories"] == 280
            assert product_data["proteins"] == 20
            assert product_data["carbs"] == 30
            assert product_data["fats"] == 8

# ==================== TESTS DE PERFORMANCE ====================

class TestPerformance:
    """Tests de performance pour mobile"""
    
    @pytest.mark.asyncio
    async def test_barcode_search_response_time(self, mock_current_user):
        """Test temps de réponse recherche barcode < 200ms"""
        app = FastAPI()
        app.include_router(router)
        client = TestClient(app)
        
        with patch('external_services_api.get_current_user', return_value=mock_current_user), \
             patch('external_services_api.BarcodeService') as mock_service:
            
            # Mock réponse rapide
            mock_instance = mock_service.return_value
            mock_instance.search_barcode.return_value = BarcodeProductInfo(
                barcode="1234567890123",
                product_name="Test Product",
                calories=250
            )
            
            start_time = time.time()
            response = client.post("/barcode/search", json={
                "barcode": "1234567890123"
            })
            end_time = time.time()
            
            assert response.status_code == 200
            response_time_ms = (end_time - start_time) * 1000
            
            # Vérifier temps de réponse < 200ms (en conditions idéales)
            assert response_time_ms < 200
    
    @pytest.mark.asyncio
    async def test_gps_batch_processing_efficiency(self, sample_gps_points):
        """Test efficacité traitement batch GPS"""
        # Test qu'un batch de 100 points peut être traité
        large_batch = sample_gps_points * 10  # 100 points
        
        batch = GPSBatchPoints(
            session_id=uuid4(),
            points=large_batch
        )
        
        # Vérifier que le batch ne dépasse pas la limite
        assert len(batch.points) <= 1000
        
        # Test validation rapide
        service = GPSTrackingService()
        valid_points = 0
        
        for point in batch.points:
            if service.is_point_valid(point):
                valid_points += 1
                
        # La plupart des points devraient être valides
        assert valid_points >= len(batch.points) * 0.8

if __name__ == "__main__":
    pytest.main([__file__, "-v"])