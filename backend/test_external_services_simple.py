"""
Tests simplifiés pour External Services API - Task 9
Tests core pour barcode scanning et GPS tracking mobile
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime, timedelta
from uuid import uuid4

# Import des classes à tester
from external_services_api import (
    BarcodeService, GPSTrackingService, BarcodeProductInfo, GPSPoint
)

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
    async def test_get_cached_product(self):
        """Test récupération produit du cache"""
        service = BarcodeService()
        
        mock_supabase = MagicMock()
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "barcode": "1234567890123",
            "product_name": "Cached Product",
            "calories": 280,
            "proteins": 20,
            "carbs": 30,
            "fats": 8,
            "data_source": "openfoodfacts",
            "quality_score": 85
        }]
        
        with patch('external_services_api.get_supabase_client', return_value=mock_supabase):
            result = await service._get_cached_product("1234567890123")
            
            assert result is not None
            assert result.barcode == "1234567890123"
            assert result.product_name == "Cached Product"

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
    
    def test_is_point_valid(self):
        """Test validation de points GPS"""
        # Point valide
        valid_point = GPSPoint(
            latitude=48.8566,
            longitude=2.3522,
            recorded_at=datetime.now()
        )
        assert GPSTrackingService.is_point_valid(valid_point)
        
        # Coordonnées invalides
        invalid_point = GPSPoint(
            latitude=91.0,  # > 90°
            longitude=2.3522,
            recorded_at=datetime.now()
        )
        assert not GPSTrackingService.is_point_valid(invalid_point)
        
        # Vitesse irréaliste
        point1 = GPSPoint(
            latitude=48.8566,
            longitude=2.3522,
            recorded_at=datetime.now()
        )
        point2 = GPSPoint(
            latitude=48.8566 + 1.0,  # ~100km de différence
            longitude=2.3522,
            recorded_at=point1.recorded_at + timedelta(seconds=1)  # 1 seconde plus tard
        )
        assert not GPSTrackingService.is_point_valid(point2, point1)

# ==================== TESTS MODÈLES PYDANTIC ====================

class TestPydanticModels:
    """Tests pour les modèles Pydantic"""
    
    def test_barcode_product_info_validation(self):
        """Test validation BarcodeProductInfo"""
        # Produit valide
        product = BarcodeProductInfo(
            barcode="1234567890123",
            product_name="Test Product",
            calories=250,
            proteins=15
        )
        
        assert product.barcode == "1234567890123"
        assert product.product_name == "Test Product"
        assert product.data_source == "openfoodfacts"  # Valeur par défaut
        assert product.quality_score == 0  # Valeur par défaut
    
    def test_gps_point_validation(self):
        """Test validation GPSPoint"""
        # Point valide
        point = GPSPoint(
            latitude=48.8566,
            longitude=2.3522,
            recorded_at=datetime.now()
        )
        
        assert point.latitude == 48.8566
        assert point.longitude == 2.3522
        
        # Test validation coordonnées
        with pytest.raises(ValueError):
            GPSPoint(
                latitude=91.0,  # Invalide
                longitude=2.3522,
                recorded_at=datetime.now()
            )

# ==================== TESTS UTILITAIRES ====================

class TestUtilityFunctions:
    """Tests pour les fonctions utilitaires"""
    
    @pytest.mark.asyncio
    async def test_calculate_realtime_session_metrics(self):
        """Test calcul de métriques en temps réel"""
        from external_services_api import calculate_realtime_session_metrics
        
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
        
        mock_supabase = MagicMock()
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = mock_points
        
        with patch('external_services_api.get_supabase_client', return_value=mock_supabase):
            metrics = await calculate_realtime_session_metrics(session_id)
            
            assert "total_distance_meters" in metrics
            assert "average_speed_kmh" in metrics
            assert "max_speed_kmh" in metrics
            assert metrics["point_count"] == 2
            assert metrics["total_distance_meters"] == 250  # 100 + 150

# ==================== TESTS PERFORMANCE ====================

class TestPerformance:
    """Tests de performance pour mobile"""
    
    def test_gps_batch_size_limit(self):
        """Test limite de taille des batches GPS"""
        from external_services_api import GPSBatchPoints
        
        # Créer des points GPS de test
        base_time = datetime.now()
        test_points = []
        
        for i in range(500):  # 500 points
            test_points.append(GPSPoint(
                latitude=48.8566 + i * 0.0001,
                longitude=2.3522 + i * 0.0001,
                recorded_at=base_time + timedelta(seconds=i)
            ))
        
        # Créer batch avec limite respectée
        batch = GPSBatchPoints(
            session_id=uuid4(),
            points=test_points
        )
        
        # Vérifier que le batch respecte la limite
        assert len(batch.points) <= 1000
    
    def test_distance_calculation_performance(self):
        """Test performance calcul de distance"""
        import time
        
        # Test calcul de 1000 distances
        start_time = time.time()
        
        for i in range(1000):
            distance = GPSTrackingService.calculate_distance(
                48.8566, 2.3522,
                48.8566 + i * 0.0001, 2.3522 + i * 0.0001
            )
        
        end_time = time.time()
        calculation_time = end_time - start_time
        
        # Le calcul de 1000 distances devrait prendre moins de 1 seconde
        assert calculation_time < 1.0

if __name__ == "__main__":
    pytest.main([__file__, "-v"])