"""
Tests pour l'API Real-time Synchronization
Tests de synchronisation en temps réel multi-device
"""

import pytest
import asyncio
import json
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from fastapi.websockets import WebSocket
from unittest.mock import Mock, patch, AsyncMock

from main import app
from realtime_api import connection_manager, ConnectionManager, DeviceInfo

# Configuration des tests
client = TestClient(app)

# Mock user pour les tests
MOCK_USER = {
    "sub": "test-user-123",
    "email": "test@example.com"
}

# ==================== FIXTURES ====================

@pytest.fixture
def mock_auth():
    """Mock de l'authentification"""
    with patch("realtime_api.get_current_user") as mock:
        mock.return_value = MOCK_USER
        yield mock

@pytest.fixture
def mock_supabase():
    """Mock du client Supabase"""
    with patch("realtime_api.get_supabase_client") as mock:
        mock_client = Mock()
        mock.return_value = mock_client
        yield mock_client

@pytest.fixture
def clean_connection_manager():
    """Nettoyer le gestionnaire de connexions avant chaque test"""
    connection_manager.active_connections.clear()
    connection_manager.device_info.clear()
    connection_manager.user_subscriptions.clear()
    yield connection_manager

# ==================== TESTS ENDPOINTS REST ====================

class TestSyncStatus:
    """Tests pour l'endpoint de statut de synchronisation"""
    
    def test_get_sync_status_success(self, mock_auth, mock_supabase):
        """Test récupération du statut de sync avec succès"""
        # Mock des données Supabase
        mock_result = Mock()
        mock_result.data = [{"id": 1}, {"id": 2}]  # 2 entrées récentes
        mock_supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_result
        
        response = client.get("/api/realtime/sync-status?device_id=test-device-1")
        
        assert response.status_code == 200
        data = response.json()
        assert data["device_id"] == "test-device-1"
        assert data["pending_uploads"] == 2
        assert data["server_version"] == "1.0.0"
        assert "last_sync" in data
        assert isinstance(data["is_online"], bool)

    def test_get_sync_status_no_pending(self, mock_auth, mock_supabase):
        """Test statut de sync sans données en attente"""
        # Mock sans données
        mock_result = Mock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_result
        
        response = client.get("/api/realtime/sync-status?device_id=test-device-2")
        
        assert response.status_code == 200
        data = response.json()
        assert data["pending_uploads"] == 0

    def test_get_sync_status_unauthorized(self):
        """Test statut de sync sans authentification"""
        response = client.get("/api/realtime/sync-status?device_id=test-device-1")
        assert response.status_code == 401

class TestSyncData:
    """Tests pour l'endpoint de synchronisation des données"""
    
    def test_sync_data_full_sync(self, mock_auth, mock_supabase):
        """Test synchronisation complète"""
        # Mock des données de différentes tables
        mock_food_entries = Mock()
        mock_food_entries.data = [
            {"id": 1, "user_id": "test-user-123", "food_id": 1, "quantity": 100},
            {"id": 2, "user_id": "test-user-123", "food_id": 2, "quantity": 150}
        ]
        
        mock_workout_sessions = Mock()
        mock_workout_sessions.data = [
            {"id": 1, "user_id": "test-user-123", "name": "Push Day", "duration": 3600}
        ]
        
        # Configuration du mock Supabase
        def mock_table_query(table_name):
            mock_table = Mock()
            mock_query = Mock()
            mock_query.eq.return_value = mock_query
            mock_query.limit.return_value = mock_query
            mock_query.order.return_value = mock_query
            
            if table_name == "food_entries":
                mock_query.execute.return_value = mock_food_entries
            elif table_name == "workout_sessions":
                mock_query.execute.return_value = mock_workout_sessions
            else:
                mock_empty = Mock()
                mock_empty.data = []
                mock_query.execute.return_value = mock_empty
            
            mock_table.select.return_value = mock_query
            return mock_table
        
        mock_supabase.table.side_effect = mock_table_query
        
        # Données de requête
        sync_request = {
            "device_id": "test-device-1",
            "force_full_sync": True,
            "tables": ["food_entries", "workout_sessions"]
        }
        
        response = client.post("/api/realtime/sync", json=sync_request)
        
        assert response.status_code == 200
        data = response.json()
        assert "sync_timestamp" in data
        assert "changes" in data
        assert "conflicts" in data
        assert data["total_changes"] == 3  # 2 food_entries + 1 workout_session
        assert "food_entries" in data["changes"]
        assert "workout_sessions" in data["changes"]
        assert len(data["changes"]["food_entries"]) == 2
        assert len(data["changes"]["workout_sessions"]) == 1

    def test_sync_data_incremental(self, mock_auth, mock_supabase):
        """Test synchronisation incrémentale"""
        # Mock avec timestamp
        mock_result = Mock()
        mock_result.data = [{"id": 3, "user_id": "test-user-123", "updated_at": "2024-01-15T10:00:00Z"}]
        
        mock_table = Mock()
        mock_query = Mock()
        mock_query.eq.return_value = mock_query
        mock_query.gte.return_value = mock_query  # Filtre par timestamp
        mock_query.limit.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_table.select.return_value = mock_query
        mock_supabase.table.return_value = mock_table
        
        sync_request = {
            "device_id": "test-device-1",
            "last_sync_timestamp": "2024-01-15T09:00:00Z",
            "tables": ["food_entries"]
        }
        
        response = client.post("/api/realtime/sync", json=sync_request)
        
        assert response.status_code == 200
        data = response.json()
        assert data["total_changes"] == 1

    def test_sync_data_empty_tables(self, mock_auth, mock_supabase):
        """Test synchronisation avec tables vides"""
        mock_result = Mock()
        mock_result.data = []
        
        mock_table = Mock()
        mock_query = Mock()
        mock_query.eq.return_value = mock_query
        mock_query.limit.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.execute.return_value = mock_result
        mock_table.select.return_value = mock_query
        mock_supabase.table.return_value = mock_table
        
        sync_request = {
            "device_id": "test-device-1",
            "tables": ["food_entries"]
        }
        
        response = client.post("/api/realtime/sync", json=sync_request)
        
        assert response.status_code == 200
        data = response.json()
        assert data["total_changes"] == 0
        assert data["changes"] == {}

class TestDeviceManagement:
    """Tests pour la gestion des devices"""
    
    def test_get_user_devices(self, mock_auth, clean_connection_manager):
        """Test récupération des devices utilisateur"""
        # Ajouter des devices de test
        device1 = DeviceInfo(
            device_id="device-1",
            device_type="mobile",
            app_version="1.0.0",
            last_seen=datetime.utcnow(),
            is_active=True
        )
        device2 = DeviceInfo(
            device_id="device-2",
            device_type="web",
            app_version="1.0.0",
            last_seen=datetime.utcnow() - timedelta(minutes=5),
            is_active=False
        )
        
        clean_connection_manager.device_info["device-1"] = device1
        clean_connection_manager.device_info["device-2"] = device2
        
        response = client.get("/api/realtime/devices")
        
        assert response.status_code == 200
        devices = response.json()
        # Seuls les devices actifs sont retournés
        assert len(devices) == 1
        assert devices[0]["device_id"] == "device-1"
        assert devices[0]["is_active"] is True

    def test_get_active_users(self, mock_auth, clean_connection_manager):
        """Test récupération des utilisateurs actifs"""
        # Simuler des utilisateurs connectés
        clean_connection_manager.active_connections["user-1"] = set()
        clean_connection_manager.active_connections["user-2"] = set()
        
        response = client.get("/api/realtime/active-users")
        
        assert response.status_code == 200
        data = response.json()
        assert data["active_users_count"] == 2
        assert "user-1" in data["active_users"]
        assert "user-2" in data["active_users"]

class TestUtilityEndpoints:
    """Tests pour les endpoints utilitaires"""
    
    def test_health_check(self, clean_connection_manager):
        """Test du health check"""
        response = client.get("/api/realtime/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "realtime-sync"
        assert "active_connections" in data
        assert "total_devices" in data
        assert "features" in data
        assert data["features"]["websocket"] is True

    def test_test_broadcast(self, mock_auth, clean_connection_manager):
        """Test du broadcast de test"""
        response = client.post("/api/realtime/test-broadcast?message=Hello World")
        
        assert response.status_code == 200
        data = response.json()
        assert "Broadcast envoyé" in data["message"]

# ==================== TESTS CONNECTION MANAGER ====================

class TestConnectionManager:
    """Tests pour le gestionnaire de connexions"""
    
    @pytest.mark.asyncio
    async def test_connect_disconnect(self, clean_connection_manager):
        """Test connexion et déconnexion WebSocket"""
        mock_websocket = Mock(spec=WebSocket)
        mock_websocket.accept = AsyncMock()
        
        user_id = "test-user"
        device_id = "test-device"
        
        # Test connexion
        await clean_connection_manager.connect(mock_websocket, user_id, device_id)
        
        assert user_id in clean_connection_manager.active_connections
        assert mock_websocket in clean_connection_manager.active_connections[user_id]
        assert device_id in clean_connection_manager.device_info
        assert clean_connection_manager.device_info[device_id].is_active is True
        
        # Test déconnexion
        clean_connection_manager.disconnect(mock_websocket, user_id, device_id)
        
        assert user_id not in clean_connection_manager.active_connections
        assert clean_connection_manager.device_info[device_id].is_active is False

    @pytest.mark.asyncio
    async def test_send_to_user(self, clean_connection_manager):
        """Test envoi de message à un utilisateur"""
        mock_websocket = Mock(spec=WebSocket)
        mock_websocket.accept = AsyncMock()
        mock_websocket.send_text = AsyncMock()
        
        user_id = "test-user"
        device_id = "test-device"
        
        # Connecter l'utilisateur
        await clean_connection_manager.connect(mock_websocket, user_id, device_id)
        
        # Envoyer un message
        test_message = {"type": "test", "data": "hello"}
        await clean_connection_manager.send_to_user(user_id, test_message)
        
        # Vérifier que le message a été envoyé
        mock_websocket.send_text.assert_called_once_with(json.dumps(test_message))

    @pytest.mark.asyncio
    async def test_broadcast_to_all(self, clean_connection_manager):
        """Test broadcast à tous les utilisateurs"""
        # Créer plusieurs connexions
        users_websockets = []
        for i in range(3):
            mock_websocket = Mock(spec=WebSocket)
            mock_websocket.accept = AsyncMock()
            mock_websocket.send_text = AsyncMock()
            user_id = f"user-{i}"
            device_id = f"device-{i}"
            
            await clean_connection_manager.connect(mock_websocket, user_id, device_id)
            users_websockets.append((user_id, mock_websocket))
        
        # Broadcaster un message
        test_message = {"type": "broadcast", "data": "hello all"}
        await clean_connection_manager.broadcast_to_all(test_message)
        
        # Vérifier que tous ont reçu le message
        for user_id, websocket in users_websockets:
            websocket.send_text.assert_called_with(json.dumps(test_message))

    def test_get_active_users(self, clean_connection_manager):
        """Test récupération des utilisateurs actifs"""
        # Ajouter des utilisateurs
        clean_connection_manager.active_connections["user-1"] = set()
        clean_connection_manager.active_connections["user-2"] = set()
        
        active_users = clean_connection_manager.get_active_users()
        
        assert len(active_users) == 2
        assert "user-1" in active_users
        assert "user-2" in active_users

# ==================== TESTS FONCTIONS UTILITAIRES ====================

class TestUtilityFunctions:
    """Tests pour les fonctions utilitaires"""
    
    def test_detect_sync_conflicts(self):
        """Test détection des conflits de synchronisation"""
        from realtime_api import detect_sync_conflicts
        
        local_data = {
            "id": 1,
            "name": "Local Name",
            "value": 100,
            "updated_at": "2024-01-15T10:00:00Z"
        }
        
        server_data = {
            "id": 1,
            "name": "Server Name",  # Conflit
            "value": 100,  # Pas de conflit
            "updated_at": "2024-01-15T11:00:00Z"  # Ignoré
        }
        
        conflicts = detect_sync_conflicts(local_data, server_data)
        
        assert len(conflicts) == 1
        assert "name" in conflicts
        assert "value" not in conflicts
        assert "updated_at" not in conflicts

    def test_resolve_conflict_server_wins(self):
        """Test résolution de conflit - serveur gagne"""
        from realtime_api import resolve_conflict
        
        local_data = {"name": "Local", "value": 100}
        server_data = {"name": "Server", "value": 200}
        
        result = resolve_conflict(local_data, server_data, "server_wins")
        
        assert result == server_data

    def test_resolve_conflict_client_wins(self):
        """Test résolution de conflit - client gagne"""
        from realtime_api import resolve_conflict
        
        local_data = {"name": "Local", "value": 100}
        server_data = {"name": "Server", "value": 200}
        
        result = resolve_conflict(local_data, server_data, "client_wins")
        
        assert result == local_data

    def test_resolve_conflict_merge(self):
        """Test résolution de conflit - merge"""
        from realtime_api import resolve_conflict
        
        local_data = {"id": 1, "name": "Local", "value": 100, "created_at": "2024-01-01"}
        server_data = {"id": 1, "name": "Server", "description": "Server desc", "created_at": "2024-01-01"}
        
        result = resolve_conflict(local_data, server_data, "merge")
        
        # Le merge devrait garder les données serveur et ajouter les données locales (sauf id et created_at)
        assert result["id"] == 1  # Du serveur
        assert result["name"] == "Local"  # Du local (écrase le serveur)
        assert result["description"] == "Server desc"  # Du serveur
        assert result["value"] == 100  # Du local
        assert result["created_at"] == "2024-01-01"  # Du serveur

# ==================== TESTS D'INTÉGRATION ====================

class TestIntegration:
    """Tests d'intégration pour l'API Real-time"""
    
    @pytest.mark.asyncio
    async def test_full_sync_workflow(self, mock_auth, mock_supabase, clean_connection_manager):
        """Test du workflow complet de synchronisation"""
        # 1. Vérifier le statut initial
        mock_result = Mock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_result
        
        status_response = client.get("/api/realtime/sync-status?device_id=integration-test")
        assert status_response.status_code == 200
        
        # 2. Effectuer une synchronisation
        mock_sync_result = Mock()
        mock_sync_result.data = [{"id": 1, "data": "test"}]
        
        mock_table = Mock()
        mock_query = Mock()
        mock_query.eq.return_value = mock_query
        mock_query.limit.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.execute.return_value = mock_sync_result
        mock_table.select.return_value = mock_query
        mock_supabase.table.return_value = mock_table
        
        sync_request = {
            "device_id": "integration-test",
            "force_full_sync": True
        }
        
        sync_response = client.post("/api/realtime/sync", json=sync_request)
        assert sync_response.status_code == 200
        
        sync_data = sync_response.json()
        assert sync_data["total_changes"] > 0
        
        # 3. Vérifier le health check
        health_response = client.get("/api/realtime/health")
        assert health_response.status_code == 200

if __name__ == "__main__":
    pytest.main([__file__, "-v"]) 