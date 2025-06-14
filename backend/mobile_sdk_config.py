"""
Mobile SDK Configuration - Task 9: External Services
Configuration et helpers pour intégration mobile iOS/Android
"""

from typing import Dict, Any, List, Optional
from pydantic import BaseModel
from enum import Enum
import json

class MobilePlatform(str, Enum):
    """Plateformes mobiles supportées"""
    IOS = "ios"
    ANDROID = "android"

class GPSAccuracyMode(str, Enum):
    """Modes de précision GPS"""
    HIGH = "high"          # Haute précision, consommation élevée
    MEDIUM = "medium"      # Précision moyenne, équilibré
    LOW = "low"           # Basse précision, économie batterie
    PASSIVE = "passive"   # Utilise la géolocalisation d'autres apps

class BarcodeFormat(str, Enum):
    """Formats de codes-barres supportés"""
    EAN13 = "ean13"
    EAN8 = "ean8"
    UPC_A = "upc_a"
    UPC_E = "upc_e"
    CODE128 = "code128"
    QR_CODE = "qr_code"
    DATAMATRIX = "datamatrix"

# ==================== CONFIGURATION MOBILE ====================

class MobileGPSConfig(BaseModel):
    """Configuration GPS optimisée par plateforme"""
    
    # Paramètres de base
    update_interval_seconds: int = 5
    accuracy_threshold_meters: float = 10.0
    min_distance_filter_meters: float = 5.0
    
    # Gestion de la batterie
    background_mode_enabled: bool = True
    pause_on_low_battery: bool = True
    low_battery_threshold: int = 20  # %
    
    # Upload et sync
    batch_upload_size: int = 50
    upload_interval_seconds: int = 30
    offline_storage_limit_points: int = 10000
    
    # Validation et filtrage
    max_speed_threshold_kmh: float = 200.0
    min_accuracy_meters: float = 100.0
    outlier_detection_enabled: bool = True

class MobileBarcodeConfig(BaseModel):
    """Configuration scan de codes-barres"""
    
    # Formats supportés
    supported_formats: List[BarcodeFormat] = [
        BarcodeFormat.EAN13,
        BarcodeFormat.EAN8,
        BarcodeFormat.UPC_A,
        BarcodeFormat.UPC_E,
        BarcodeFormat.CODE128
    ]
    
    # Performance caméra
    auto_focus_enabled: bool = True
    torch_mode_available: bool = True
    continuous_scan_enabled: bool = False
    
    # Cache et recherche
    cache_expiry_hours: int = 24
    search_timeout_seconds: int = 10
    retry_attempts: int = 3
    fallback_sources_enabled: bool = True
    
    # UI/UX
    vibration_on_scan: bool = True
    sound_on_scan: bool = True
    show_scan_overlay: bool = True

class MobileNetworkConfig(BaseModel):
    """Configuration réseau et synchronisation"""
    
    # Timeouts
    api_timeout_seconds: int = 30
    upload_timeout_seconds: int = 60
    download_timeout_seconds: int = 45
    
    # Retry et resilience
    max_retry_attempts: int = 3
    retry_backoff_factor: float = 2.0
    circuit_breaker_enabled: bool = True
    
    # Compression et optimisation
    compression_enabled: bool = True
    compression_level: int = 6  # 1-9
    response_caching_enabled: bool = True
    cache_duration_seconds: int = 300
    
    # Mode offline
    offline_mode_enabled: bool = True
    sync_on_wifi_only: bool = False
    background_sync_enabled: bool = True

# ==================== CONFIGURATIONS PAR PLATEFORME ====================

def get_ios_config() -> Dict[str, Any]:
    """Configuration optimisée pour iOS"""
    return {
        "gps": MobileGPSConfig(
            update_interval_seconds=3,          # iOS gère mieux les updates fréquents
            accuracy_threshold_meters=5.0,      # Précision supérieure sur iOS
            batch_upload_size=25,               # Batches plus petits
            background_mode_enabled=True,       # Excellent support background
            min_distance_filter_meters=3.0      # Filtrage plus fin
        ).dict(),
        
        "barcode": MobileBarcodeConfig(
            auto_focus_enabled=True,
            torch_mode_available=True,
            continuous_scan_enabled=True,       # iOS supporte bien le scan continu
            cache_expiry_hours=48,              # Cache plus long sur iOS
            vibration_on_scan=True,
            sound_on_scan=True
        ).dict(),
        
        "network": MobileNetworkConfig(
            api_timeout_seconds=25,
            compression_enabled=True,
            compression_level=7,                # Compression plus élevée
            offline_mode_enabled=True,
            sync_on_wifi_only=False            # 5G/4G performant sur iOS
        ).dict(),
        
        "platform_specific": {
            "location_permission": "whenInUse",  # ou "always" pour background
            "motion_permission": True,
            "camera_permission": True,
            "background_app_refresh": True,
            "core_location_accuracy": "best",
            "significant_location_change": True
        }
    }

def get_android_config() -> Dict[str, Any]:
    """Configuration optimisée pour Android"""
    return {
        "gps": MobileGPSConfig(
            update_interval_seconds=5,          # Plus conservateur sur Android
            accuracy_threshold_meters=10.0,
            batch_upload_size=50,               # Batches plus gros
            background_mode_enabled=True,
            pause_on_low_battery=True,          # Important sur Android
            min_distance_filter_meters=5.0
        ).dict(),
        
        "barcode": MobileBarcodeConfig(
            auto_focus_enabled=True,
            torch_mode_available=True,
            continuous_scan_enabled=False,      # Économie batterie
            cache_expiry_hours=24,
            vibration_on_scan=True,
            sound_on_scan=False                 # Moins intrusif sur Android
        ).dict(),
        
        "network": MobileNetworkConfig(
            api_timeout_seconds=35,             # Plus généreux
            compression_enabled=True,
            compression_level=5,                # Équilibré performance/CPU
            offline_mode_enabled=True,
            sync_on_wifi_only=True,            # Économie données
            background_sync_enabled=False      # Permission plus complexe
        ).dict(),
        
        "platform_specific": {
            "location_permission": "fine",      # ACCESS_FINE_LOCATION
            "background_location": False,       # Par défaut off
            "camera_permission": True,
            "wake_lock": True,                  # Pour GPS en background
            "doze_mode_whitelist": False,       # À demander explicitement
            "battery_optimization_ignore": False
        }
    }

# ==================== SDK HELPERS ====================

class MobileSDKHelper:
    """Helper pour faciliter l'intégration mobile"""
    
    @staticmethod
    def get_platform_config(platform: MobilePlatform) -> Dict[str, Any]:
        """Récupère la configuration par plateforme"""
        if platform == MobilePlatform.IOS:
            return get_ios_config()
        elif platform == MobilePlatform.ANDROID:
            return get_android_config()
        else:
            raise ValueError(f"Plateforme non supportée: {platform}")
    
    @staticmethod
    def get_api_endpoints() -> Dict[str, str]:
        """Retourne tous les endpoints de l'API externe"""
        base_url = "/api/external-services"
        
        return {
            # Barcode endpoints
            "barcode_search": f"{base_url}/barcode/search",
            "barcode_popular": f"{base_url}/barcode/popular",
            "barcode_manual": f"{base_url}/barcode/manual",
            
            # GPS endpoints
            "gps_session_create": f"{base_url}/gps/sessions",
            "gps_session_update": f"{base_url}/gps/sessions/{{session_id}}",
            "gps_session_stats": f"{base_url}/gps/sessions/{{session_id}}/stats",
            "gps_points_batch": f"{base_url}/gps/points/batch",
            "gps_sessions_list": f"{base_url}/gps/sessions",
            
            # Mobile endpoints
            "mobile_config": f"{base_url}/mobile/config",
            "mobile_health": f"{base_url}/mobile/health"
        }
    
    @staticmethod
    def get_request_examples() -> Dict[str, Any]:
        """Exemples de requêtes pour les développeurs mobile"""
        return {
            "barcode_search": {
                "method": "POST",
                "url": "/api/external-services/barcode/search",
                "headers": {
                    "Authorization": "Bearer {jwt_token}",
                    "Content-Type": "application/json"
                },
                "body": {
                    "barcode": "1234567890123",
                    "force_refresh": False,
                    "preferred_sources": ["openfoodfacts", "usda"]
                }
            },
            
            "gps_session_create": {
                "method": "POST",
                "url": "/api/external-services/gps/sessions",
                "headers": {
                    "Authorization": "Bearer {jwt_token}",
                    "Content-Type": "application/json"
                },
                "body": {
                    "activity_type": "running",
                    "tracking_accuracy": "high",
                    "device_info": {
                        "platform": "ios",
                        "platform_version": "15.0",
                        "app_version": "1.0.0",
                        "device_model": "iPhone 13"
                    }
                }
            },
            
            "gps_points_batch": {
                "method": "POST",
                "url": "/api/external-services/gps/points/batch",
                "headers": {
                    "Authorization": "Bearer {jwt_token}",
                    "Content-Type": "application/json"
                },
                "body": {
                    "session_id": "session-uuid",
                    "points": [
                        {
                            "latitude": 48.8566,
                            "longitude": 2.3522,
                            "altitude_meters": 35.0,
                            "accuracy_meters": 5.0,
                            "speed_mps": 2.5,
                            "bearing_degrees": 45.0,
                            "recorded_at": "2024-01-01T10:00:00Z",
                            "battery_level": 90,
                            "signal_strength": 85
                        }
                    ]
                }
            }
        }
    
    @staticmethod
    def get_error_codes() -> Dict[str, str]:
        """Codes d'erreur spécifiques aux services externes"""
        return {
            "BARCODE_INVALID": "Code-barres invalide (format incorrect)",
            "BARCODE_NOT_FOUND": "Produit non trouvé dans les bases de données",
            "BARCODE_SERVICE_UNAVAILABLE": "Service de recherche temporairement indisponible",
            
            "GPS_INVALID_COORDINATES": "Coordonnées GPS invalides",
            "GPS_SESSION_NOT_FOUND": "Session GPS introuvable",
            "GPS_SESSION_UNAUTHORIZED": "Accès non autorisé à la session GPS",
            "GPS_BATCH_TOO_LARGE": "Batch de points GPS trop volumineux (max 1000)",
            "GPS_POINT_INVALID": "Point GPS invalide (vitesse irréaliste ou coordonnées aberrantes)",
            
            "MOBILE_CONFIG_INVALID": "Configuration mobile invalide",
            "PLATFORM_NOT_SUPPORTED": "Plateforme mobile non supportée",
            
            "RATE_LIMIT_EXCEEDED": "Limite de taux dépassée",
            "INSUFFICIENT_PERMISSIONS": "Permissions insuffisantes",
            "SERVICE_TEMPORARILY_UNAVAILABLE": "Service temporairement indisponible"
        }

# ==================== SCHÉMAS POUR DÉVELOPPEURS ====================

def generate_openapi_schema_mobile() -> Dict[str, Any]:
    """Génère un schéma OpenAPI spécifique pour mobile"""
    return {
        "openapi": "3.0.0",
        "info": {
            "title": "Ryze External Services API - Mobile SDK",
            "version": "1.0.0",
            "description": "API optimisée pour les applications mobiles iOS et Android"
        },
        "servers": [
            {
                "url": "https://api.ryze.app",
                "description": "Production server"
            },
            {
                "url": "https://staging-api.ryze.app",
                "description": "Staging server"
            }
        ],
        "paths": {
            "/api/external-services/mobile/config": {
                "get": {
                    "summary": "Get mobile platform configuration",
                    "parameters": [
                        {
                            "name": "platform",
                            "in": "query",
                            "required": True,
                            "schema": {
                                "type": "string",
                                "enum": ["ios", "android"]
                            }
                        }
                    ],
                    "responses": {
                        "200": {
                            "description": "Configuration mobile",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "gps": {"$ref": "#/components/schemas/MobileGPSConfig"},
                                            "barcode": {"$ref": "#/components/schemas/MobileBarcodeConfig"},
                                            "network": {"$ref": "#/components/schemas/MobileNetworkConfig"}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        "components": {
            "schemas": {
                "MobileGPSConfig": {
                    "type": "object",
                    "properties": {
                        "update_interval_seconds": {"type": "integer"},
                        "accuracy_threshold_meters": {"type": "number"},
                        "batch_upload_size": {"type": "integer"},
                        "offline_storage_limit_points": {"type": "integer"}
                    }
                }
            }
        }
    }

# ==================== EXPORT POUR MOBILE ====================

def export_mobile_config(platform: MobilePlatform, output_format: str = "json") -> str:
    """Exporte la configuration mobile dans le format demandé"""
    config = MobileSDKHelper.get_platform_config(platform)
    
    if output_format.lower() == "json":
        return json.dumps(config, indent=2)
    elif output_format.lower() == "swift":
        return generate_swift_config(config)
    elif output_format.lower() == "kotlin":
        return generate_kotlin_config(config)
    else:
        raise ValueError(f"Format non supporté: {output_format}")

def generate_swift_config(config: Dict[str, Any]) -> str:
    """Génère la configuration en Swift pour iOS"""
    return f"""
// Ryze Mobile SDK Configuration - iOS
// Auto-generated configuration file

import Foundation

struct RyzeMobileConfig {{
    
    // GPS Configuration
    static let gpsUpdateInterval: TimeInterval = {config['gps']['update_interval_seconds']}
    static let gpsAccuracyThreshold: Double = {config['gps']['accuracy_threshold_meters']}
    static let gpsBatchUploadSize: Int = {config['gps']['batch_upload_size']}
    static let gpsBackgroundModeEnabled: Bool = {str(config['gps']['background_mode_enabled']).lower()}
    
    // Barcode Configuration
    static let barcodeAutoFocusEnabled: Bool = {str(config['barcode']['auto_focus_enabled']).lower()}
    static let barcodeContinuousScanEnabled: Bool = {str(config['barcode']['continuous_scan_enabled']).lower()}
    static let barcodeCacheExpiryHours: Int = {config['barcode']['cache_expiry_hours']}
    
    // Network Configuration
    static let apiTimeoutSeconds: TimeInterval = {config['network']['api_timeout_seconds']}
    static let compressionEnabled: Bool = {str(config['network']['compression_enabled']).lower()}
    static let offlineModeEnabled: Bool = {str(config['network']['offline_mode_enabled']).lower()}
    
    // API Endpoints
    static let baseURL = "https://api.ryze.app"
    static let barcodeSearchEndpoint = "/api/external-services/barcode/search"
    static let gpsSessionsEndpoint = "/api/external-services/gps/sessions"
    static let gpsPointsBatchEndpoint = "/api/external-services/gps/points/batch"
}}
"""

def generate_kotlin_config(config: Dict[str, Any]) -> str:
    """Génère la configuration en Kotlin pour Android"""
    return f"""
// Ryze Mobile SDK Configuration - Android
// Auto-generated configuration file

package com.ryze.mobile.config

object RyzeMobileConfig {{
    
    // GPS Configuration
    const val GPS_UPDATE_INTERVAL_SECONDS = {config['gps']['update_interval_seconds']}
    const val GPS_ACCURACY_THRESHOLD_METERS = {config['gps']['accuracy_threshold_meters']}f
    const val GPS_BATCH_UPLOAD_SIZE = {config['gps']['batch_upload_size']}
    const val GPS_BACKGROUND_MODE_ENABLED = {str(config['gps']['background_mode_enabled']).lower()}
    
    // Barcode Configuration
    const val BARCODE_AUTO_FOCUS_ENABLED = {str(config['barcode']['auto_focus_enabled']).lower()}
    const val BARCODE_CONTINUOUS_SCAN_ENABLED = {str(config['barcode']['continuous_scan_enabled']).lower()}
    const val BARCODE_CACHE_EXPIRY_HOURS = {config['barcode']['cache_expiry_hours']}
    
    // Network Configuration
    const val API_TIMEOUT_SECONDS = {config['network']['api_timeout_seconds']}
    const val COMPRESSION_ENABLED = {str(config['network']['compression_enabled']).lower()}
    const val OFFLINE_MODE_ENABLED = {str(config['network']['offline_mode_enabled']).lower()}
    
    // API Endpoints
    const val BASE_URL = "https://api.ryze.app"
    const val BARCODE_SEARCH_ENDPOINT = "/api/external-services/barcode/search"
    const val GPS_SESSIONS_ENDPOINT = "/api/external-services/gps/sessions"
    const val GPS_POINTS_BATCH_ENDPOINT = "/api/external-services/gps/points/batch"
}}
"""