"""
External Services API - Task 9: Integrate External Services
API pour barcode scanning et GPS tracking optimisée pour mobile iOS/Android
"""

from fastapi import APIRouter, HTTPException, Depends, Query, BackgroundTasks
from typing import List, Optional, Dict, Any, Union
from pydantic import BaseModel, Field, validator
from uuid import UUID, uuid4
from datetime import datetime, timedelta
import json
import asyncio
import aiohttp
import math
from decimal import Decimal

# Import des dépendances (simulation pour le développement)
try:
    from database import get_supabase_client
    from auth import get_current_user
except ImportError:
    # Fallback pour le développement
    def get_supabase_client():
        return None
    def get_current_user():
        return {"id": "test-user-123", "email": "test@example.com"}

router = APIRouter(prefix="/api/external-services")

# ==================== MODÈLES PYDANTIC ====================

# Modèles Barcode Scanning
class BarcodeProductInfo(BaseModel):
    barcode: str = Field(..., min_length=8, max_length=20)
    product_name: str
    brand: Optional[str] = None
    category: Optional[str] = None
    
    # Nutrition pour 100g
    calories: Optional[float] = None
    proteins: Optional[float] = None
    carbs: Optional[float] = None
    fats: Optional[float] = None
    fiber: Optional[float] = None
    sugar: Optional[float] = None
    sodium: Optional[float] = None
    
    # Métadonnées
    serving_size: Optional[str] = None
    serving_unit: str = "g"
    ingredients: Optional[str] = None
    allergens: List[str] = Field(default_factory=list)
    
    # Sources
    data_source: str = "openfoodfacts"
    quality_score: int = Field(default=0, ge=0, le=100)
    image_url: Optional[str] = None
    product_url: Optional[str] = None

class BarcodeScanRequest(BaseModel):
    barcode: str = Field(..., min_length=8, max_length=20)
    force_refresh: bool = Field(default=False)
    preferred_sources: List[str] = Field(default=["openfoodfacts", "usda"])

# Modèles GPS Tracking
class GPSPoint(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    altitude_meters: Optional[float] = None
    accuracy_meters: Optional[float] = None
    speed_mps: Optional[float] = None
    bearing_degrees: Optional[float] = Field(None, ge=0, le=360)
    recorded_at: datetime
    
    # Données mobiles
    battery_level: Optional[int] = Field(None, ge=0, le=100)
    signal_strength: Optional[int] = Field(None, ge=0, le=100)

class GPSTrackingSessionCreate(BaseModel):
    activity_type: str = Field(default="running", regex="^(running|walking|cycling|hiking|other)$")
    cardio_session_id: Optional[UUID] = None
    tracking_accuracy: str = Field(default="high", regex="^(high|medium|low)$")
    device_info: Dict[str, Any] = Field(default_factory=dict)

class GPSTrackingSessionUpdate(BaseModel):
    status: str = Field(..., regex="^(active|paused|completed|cancelled)$")
    end_time: Optional[datetime] = None

class GPSBatchPoints(BaseModel):
    session_id: UUID
    points: List[GPSPoint] = Field(..., max_items=1000)  # Limite pour performance mobile

# Modèles Device/Mobile
class DeviceInfo(BaseModel):
    platform: str = Field(..., regex="^(ios|android)$")
    platform_version: str
    app_version: str
    device_model: str
    gps_capabilities: Dict[str, Any] = Field(default_factory=dict)

class MobileAppConfig(BaseModel):
    gps_update_interval_seconds: int = Field(default=5, ge=1, le=60)
    gps_accuracy_threshold_meters: float = Field(default=10.0, ge=1.0, le=100.0)
    batch_upload_size: int = Field(default=50, ge=1, le=1000)
    offline_storage_limit_mb: int = Field(default=100, ge=10, le=1000)

# Modèles réponse
class BarcodeSearchResponse(BaseModel):
    found: bool
    product: Optional[BarcodeProductInfo] = None
    alternatives: List[BarcodeProductInfo] = Field(default_factory=list)
    cache_hit: bool = False
    response_time_ms: int = 0

class GPSSessionStats(BaseModel):
    total_distance_meters: float
    duration_seconds: int
    average_speed_kmh: float
    max_speed_kmh: float
    elevation_gain_meters: float = 0
    pace_per_km_seconds: Optional[int] = None
    point_count: int

# ==================== SERVICES BARCODE ====================

class BarcodeService:
    """Service pour la recherche et validation de codes-barres"""
    
    def __init__(self):
        self.openfoodfacts_url = "https://world.openfoodfacts.org/api/v0"
        self.usda_url = "https://api.nal.usda.gov/fdc/v1"
        
    async def search_barcode(self, barcode: str, sources: List[str] = None) -> Optional[BarcodeProductInfo]:
        """Recherche un produit par code-barres dans les sources spécifiées"""
        sources = sources or ["openfoodfacts", "usda"]
        
        # Vérifier d'abord le cache local
        cached_product = await self._get_cached_product(barcode)
        if cached_product:
            return cached_product
            
        # Rechercher dans les sources externes
        for source in sources:
            try:
                if source == "openfoodfacts":
                    product = await self._search_openfoodfacts(barcode)
                elif source == "usda":
                    product = await self._search_usda(barcode)
                else:
                    continue
                    
                if product:
                    # Sauvegarder en cache
                    await self._cache_product(product)
                    return product
                    
            except Exception as e:
                print(f"Erreur recherche {source}: {e}")
                continue
                
        return None
    
    async def _search_openfoodfacts(self, barcode: str) -> Optional[BarcodeProductInfo]:
        """Recherche dans Open Food Facts"""
        url = f"{self.openfoodfacts_url}/product/{barcode}.json"
        
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=10)) as response:
                if response.status != 200:
                    return None
                    
                data = await response.json()
                
                if not data.get("status") or not data.get("product"):
                    return None
                
                product = data["product"]
                nutriments = product.get("nutriments", {})
                
                return BarcodeProductInfo(
                    barcode=barcode,
                    product_name=product.get("product_name", "Unknown Product"),
                    brand=product.get("brands", "").split(",")[0].strip() if product.get("brands") else None,
                    category=product.get("categories", "").split(",")[0].strip() if product.get("categories") else None,
                    
                    # Nutrition (pour 100g)
                    calories=nutriments.get("energy-kcal_100g"),
                    proteins=nutriments.get("proteins_100g"),
                    carbs=nutriments.get("carbohydrates_100g"),
                    fats=nutriments.get("fat_100g"),
                    fiber=nutriments.get("fiber_100g"),
                    sugar=nutriments.get("sugars_100g"),
                    sodium=nutriments.get("sodium_100g"),
                    
                    # Métadonnées
                    ingredients=product.get("ingredients_text"),
                    allergens=product.get("allergens", "").split(",") if product.get("allergens") else [],
                    
                    # Sources
                    data_source="openfoodfacts",
                    quality_score=min(100, len([v for v in nutriments.values() if v is not None]) * 10),
                    image_url=product.get("image_url"),
                    product_url=f"https://world.openfoodfacts.org/product/{barcode}"
                )
    
    async def _search_usda(self, barcode: str) -> Optional[BarcodeProductInfo]:
        """Recherche dans USDA (nécessite API key)"""
        # Implémentation simplifiée - nécessiterait une vraie clé API
        return None
    
    async def _get_cached_product(self, barcode: str) -> Optional[BarcodeProductInfo]:
        """Récupère un produit du cache local"""
        try:
            supabase = get_supabase_client()
            if not supabase:
                return None
                
            result = supabase.table("barcode_foods").select("*").eq("barcode", barcode).execute()
            
            if result.data:
                product_data = result.data[0]
                return BarcodeProductInfo(**product_data)
                
        except Exception as e:
            print(f"Erreur cache: {e}")
            
        return None
    
    async def _cache_product(self, product: BarcodeProductInfo):
        """Sauvegarde un produit en cache"""
        try:
            supabase = get_supabase_client()
            if not supabase:
                return
                
            # Incrémenter le compteur de scan
            existing = supabase.table("barcode_foods").select("scan_count").eq("barcode", product.barcode).execute()
            
            product_data = product.dict()
            product_data["last_scanned_at"] = datetime.now().isoformat()
            
            if existing.data:
                # Mise à jour
                product_data["scan_count"] = existing.data[0]["scan_count"] + 1
                supabase.table("barcode_foods").update(product_data).eq("barcode", product.barcode).execute()
            else:
                # Création
                product_data["scan_count"] = 1
                supabase.table("barcode_foods").insert(product_data).execute()
                
        except Exception as e:
            print(f"Erreur sauvegarde cache: {e}")

# ==================== SERVICES GPS ====================

class GPSTrackingService:
    """Service pour le tracking GPS optimisé mobile"""
    
    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calcule la distance entre deux points GPS (formule haversine)"""
        if lat1 == lat2 and lon1 == lon2:
            return 0.0
            
        # Conversion en radians
        lat1_rad = math.radians(lat1)
        lon1_rad = math.radians(lon1)
        lat2_rad = math.radians(lat2)
        lon2_rad = math.radians(lon2)
        
        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad
        
        # Formule haversine
        a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        
        # Rayon de la Terre en mètres
        r = 6371000
        
        return r * c
    
    @staticmethod
    def calculate_speed(distance_meters: float, time_seconds: float) -> float:
        """Calcule la vitesse en km/h"""
        if time_seconds <= 0:
            return 0.0
        return (distance_meters / time_seconds) * 3.6  # m/s vers km/h
    
    @staticmethod
    def is_point_valid(point: GPSPoint, previous_point: Optional[GPSPoint] = None) -> bool:
        """Valide un point GPS (filtre les erreurs de géolocalisation)"""
        # Vérifications de base
        if not (-90 <= point.latitude <= 90) or not (-180 <= point.longitude <= 180):
            return False
            
        # Si on a un point précédent, vérifier la cohérence
        if previous_point:
            distance = GPSTrackingService.calculate_distance(
                previous_point.latitude, previous_point.longitude,
                point.latitude, point.longitude
            )
            time_diff = (point.recorded_at - previous_point.recorded_at).total_seconds()
            
            # Rejeter les points avec vitesse irréaliste (>200 km/h)
            if time_diff > 0:
                speed_kmh = GPSTrackingService.calculate_speed(distance, time_diff)
                if speed_kmh > 200:
                    return False
                    
            # Rejeter les points trop proches temporellement (<1 seconde)
            if time_diff < 1:
                return False
                
        return True

# ==================== ENDPOINTS BARCODE ====================

@router.post("/barcode/search", response_model=BarcodeSearchResponse)
async def search_barcode_product(
    request: BarcodeScanRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Recherche un produit par code-barres
    Optimisé pour scan mobile avec cache intelligent
    """
    start_time = datetime.now()
    
    try:
        barcode_service = BarcodeService()
        
        # Si force_refresh, ignorer le cache
        if request.force_refresh:
            sources = request.preferred_sources
        else:
            sources = ["cache"] + request.preferred_sources
            
        product = await barcode_service.search_barcode(
            request.barcode, 
            sources=request.preferred_sources
        )
        
        response_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return BarcodeSearchResponse(
            found=product is not None,
            product=product,
            alternatives=[],  # TODO: Implémenter recherche alternative
            cache_hit=not request.force_refresh and product is not None,
            response_time_ms=int(response_time)
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur recherche: {str(e)}")

@router.get("/barcode/popular", response_model=List[BarcodeProductInfo])
async def get_popular_products(
    limit: int = Query(default=20, le=100),
    category: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """Récupère les produits les plus scannés (pour suggestions)"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            return []
            
        query = supabase.table("barcode_foods").select("*").order("scan_count", desc=True).limit(limit)
        
        if category:
            query = query.eq("category", category)
            
        result = query.execute()
        
        return [BarcodeProductInfo(**item) for item in result.data]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur récupération: {str(e)}")

@router.post("/barcode/manual")
async def add_manual_product(
    product: BarcodeProductInfo,
    current_user: dict = Depends(get_current_user)
):
    """Permet d'ajouter manuellement un produit (crowdsourcing)"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            raise HTTPException(status_code=500, detail="Service indisponible")
            
        product_data = product.dict()
        product_data["user_id"] = current_user["id"]
        product_data["data_source"] = "manual"
        product_data["scan_count"] = 1
        product_data["last_scanned_at"] = datetime.now().isoformat()
        
        result = supabase.table("barcode_foods").insert(product_data).execute()
        
        return {"message": "Produit ajouté avec succès", "product": result.data[0]}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur ajout: {str(e)}")

# ==================== ENDPOINTS GPS TRACKING ====================

@router.post("/gps/sessions", response_model=dict)
async def create_gps_session(
    session_data: GPSTrackingSessionCreate,
    current_user: dict = Depends(get_current_user)
):
    """Démarre une nouvelle session de tracking GPS"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            raise HTTPException(status_code=500, detail="Service indisponible")
            
        session = {
            "user_id": current_user["id"],
            "activity_type": session_data.activity_type,
            "cardio_session_id": str(session_data.cardio_session_id) if session_data.cardio_session_id else None,
            "start_time": datetime.now().isoformat(),
            "status": "active",
            "device_info": session_data.device_info,
            "tracking_accuracy": session_data.tracking_accuracy,
            "total_distance_meters": 0,
            "average_speed_kmh": 0,
            "max_speed_kmh": 0
        }
        
        result = supabase.table("gps_tracking_sessions").insert(session).execute()
        
        return {
            "message": "Session GPS créée",
            "session": result.data[0],
            "config": {
                "update_interval_seconds": 5,
                "batch_size": 50,
                "accuracy_threshold_meters": 10.0
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur création session: {str(e)}")

@router.post("/gps/points/batch")
async def upload_gps_points_batch(
    batch: GPSBatchPoints,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user)
):
    """
    Upload en lot des points GPS (optimisé mobile)
    Traitement en arrière-plan pour performance
    """
    try:
        supabase = get_supabase_client()
        if not supabase:
            raise HTTPException(status_code=500, detail="Service indisponible")
            
        # Vérifier que la session appartient à l'utilisateur
        session_check = supabase.table("gps_tracking_sessions").select("user_id").eq("id", str(batch.session_id)).execute()
        
        if not session_check.data or session_check.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Session non autorisée")
            
        # Traitement en arrière-plan
        background_tasks.add_task(process_gps_points_batch, batch, str(batch.session_id))
        
        return {
            "message": f"Batch de {len(batch.points)} points en cours de traitement",
            "points_count": len(batch.points),
            "session_id": str(batch.session_id)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur upload: {str(e)}")

@router.put("/gps/sessions/{session_id}")
async def update_gps_session(
    session_id: UUID,
    update_data: GPSTrackingSessionUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Met à jour une session GPS (pause, resume, stop)"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            raise HTTPException(status_code=500, detail="Service indisponible")
            
        # Vérifier propriété
        session_check = supabase.table("gps_tracking_sessions").select("user_id").eq("id", str(session_id)).execute()
        
        if not session_check.data or session_check.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Session non autorisée")
            
        update_dict = {"status": update_data.status}
        
        if update_data.end_time:
            update_dict["end_time"] = update_data.end_time.isoformat()
            
        # Si completion, calculer les métriques finales
        if update_data.status == "completed":
            metrics = await calculate_final_session_metrics(str(session_id))
            update_dict.update(metrics)
            
        result = supabase.table("gps_tracking_sessions").update(update_dict).eq("id", str(session_id)).execute()
        
        return {"message": "Session mise à jour", "session": result.data[0]}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur mise à jour: {str(e)}")

@router.get("/gps/sessions/{session_id}/stats", response_model=GPSSessionStats)
async def get_session_stats(
    session_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Récupère les statistiques d'une session GPS"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            raise HTTPException(status_code=500, detail="Service indisponible")
            
        # Vérifier propriété et récupérer session
        session_result = supabase.table("gps_tracking_sessions").select("*").eq("id", str(session_id)).eq("user_id", current_user["id"]).execute()
        
        if not session_result.data:
            raise HTTPException(status_code=404, detail="Session non trouvée")
            
        session = session_result.data[0]
        
        # Calculer stats en temps réel si nécessaire
        if session["status"] == "active":
            metrics = await calculate_realtime_session_metrics(str(session_id))
        else:
            metrics = {
                "total_distance_meters": session.get("total_distance_meters", 0),
                "duration_seconds": session.get("duration_seconds", 0),
                "average_speed_kmh": session.get("average_speed_kmh", 0),
                "max_speed_kmh": session.get("max_speed_kmh", 0),
                "elevation_gain_meters": session.get("elevation_gain_meters", 0),
                "pace_per_km_seconds": session.get("pace_per_km_seconds"),
                "point_count": 0  # TODO: compter points
            }
            
        return GPSSessionStats(**metrics)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur stats: {str(e)}")

@router.get("/gps/sessions")
async def get_user_gps_sessions(
    limit: int = Query(default=20, le=100),
    activity_type: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """Récupère les sessions GPS de l'utilisateur"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            raise HTTPException(status_code=500, detail="Service indisponible")
            
        query = supabase.table("gps_tracking_sessions").select("*").eq("user_id", current_user["id"]).order("start_time", desc=True).limit(limit)
        
        if activity_type:
            query = query.eq("activity_type", activity_type)
            
        result = query.execute()
        
        return {"sessions": result.data}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur récupération: {str(e)}")

# ==================== ENDPOINTS CONFIGURATION MOBILE ====================

@router.get("/mobile/config", response_model=MobileAppConfig)
async def get_mobile_config(
    platform: str = Query(..., regex="^(ios|android)$"),
    current_user: dict = Depends(get_current_user)
):
    """Configuration optimisée par plateforme mobile"""
    
    # Configuration différenciée iOS/Android
    base_config = MobileAppConfig()
    
    if platform == "ios":
        # iOS: Optimisations spécifiques
        base_config.gps_update_interval_seconds = 3  # Plus fréquent sur iOS
        base_config.gps_accuracy_threshold_meters = 5.0  # Plus précis
        base_config.batch_upload_size = 25  # Batches plus petits
        
    elif platform == "android":
        # Android: Gestion batterie
        base_config.gps_update_interval_seconds = 5
        base_config.gps_accuracy_threshold_meters = 10.0
        base_config.batch_upload_size = 50
        
    return base_config

@router.get("/mobile/health")
async def mobile_health_check():
    """Health check optimisé mobile avec latence"""
    start_time = datetime.now()
    
    # Tests rapides de connectivité
    db_healthy = True
    external_apis_healthy = True
    
    try:
        supabase = get_supabase_client()
        if supabase:
            # Test rapide DB
            supabase.table("external_api_configs").select("service_name").limit(1).execute()
    except:
        db_healthy = False
        
    response_time = (datetime.now() - start_time).total_seconds() * 1000
    
    return {
        "status": "healthy" if db_healthy else "degraded",
        "services": {
            "database": "healthy" if db_healthy else "down",
            "external_apis": "healthy" if external_apis_healthy else "degraded",
            "gps_tracking": "healthy",
            "barcode_scanning": "healthy"
        },
        "response_time_ms": int(response_time),
        "timestamp": datetime.now().isoformat()
    }

# ==================== FONCTIONS UTILITAIRES ====================

async def process_gps_points_batch(batch: GPSBatchPoints, session_id: str):
    """Traite un batch de points GPS en arrière-plan"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            return
            
        gps_service = GPSTrackingService()
        processed_points = []
        previous_point = None
        
        # Récupérer le dernier point de la session pour calculs
        last_point_result = supabase.table("gps_tracking_points").select("*").eq("session_id", session_id).order("sequence_number", desc=True).limit(1).execute()
        
        if last_point_result.data:
            last_data = last_point_result.data[0]
            previous_point = GPSPoint(
                latitude=last_data["latitude"],
                longitude=last_data["longitude"],
                recorded_at=datetime.fromisoformat(last_data["recorded_at"].replace('Z', '+00:00'))
            )
            sequence_start = last_data["sequence_number"] + 1
        else:
            sequence_start = 1
            
        # Traiter chaque point
        for i, point in enumerate(batch.points):
            if not gps_service.is_point_valid(point, previous_point):
                continue
                
            # Calculer distance depuis point précédent
            distance_from_previous = 0
            time_from_previous = 0
            
            if previous_point:
                distance_from_previous = gps_service.calculate_distance(
                    previous_point.latitude, previous_point.longitude,
                    point.latitude, point.longitude
                )
                time_from_previous = (point.recorded_at - previous_point.recorded_at).total_seconds()
                
            point_data = {
                "session_id": session_id,
                "latitude": point.latitude,
                "longitude": point.longitude,
                "altitude_meters": point.altitude_meters,
                "accuracy_meters": point.accuracy_meters,
                "speed_mps": point.speed_mps,
                "bearing_degrees": point.bearing_degrees,
                "recorded_at": point.recorded_at.isoformat(),
                "sequence_number": sequence_start + i,
                "distance_from_previous_meters": distance_from_previous,
                "time_from_previous_seconds": time_from_previous,
                "battery_level": point.battery_level,
                "signal_strength": point.signal_strength
            }
            
            processed_points.append(point_data)
            previous_point = point
            
        # Insertion en lot
        if processed_points:
            supabase.table("gps_tracking_points").insert(processed_points).execute()
            
        # Mettre à jour les métriques de session
        await update_session_metrics(session_id)
        
    except Exception as e:
        print(f"Erreur traitement batch GPS: {e}")

async def update_session_metrics(session_id: str):
    """Met à jour les métriques d'une session en cours"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            return
            
        # Utiliser la fonction SQL pour calculer les métriques
        result = supabase.rpc("calculate_session_metrics", {"session_uuid": session_id}).execute()
        
        if result.data:
            metrics = result.data[0]
            supabase.table("gps_tracking_sessions").update(metrics).eq("id", session_id).execute()
            
    except Exception as e:
        print(f"Erreur mise à jour métriques: {e}")

async def calculate_final_session_metrics(session_id: str) -> dict:
    """Calcule les métriques finales d'une session terminée"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            return {}
            
        result = supabase.rpc("calculate_session_metrics", {"session_uuid": session_id}).execute()
        
        if result.data:
            return result.data[0]
            
    except Exception as e:
        print(f"Erreur calcul métriques finales: {e}")
        
    return {}

async def calculate_realtime_session_metrics(session_id: str) -> dict:
    """Calcule les métriques en temps réel d'une session active"""
    try:
        supabase = get_supabase_client()
        if not supabase:
            return {
                "total_distance_meters": 0,
                "duration_seconds": 0,
                "average_speed_kmh": 0,
                "max_speed_kmh": 0,
                "elevation_gain_meters": 0,
                "pace_per_km_seconds": None,
                "point_count": 0
            }
            
        # Calculer métriques depuis les points GPS
        points_result = supabase.table("gps_tracking_points").select("*").eq("session_id", session_id).order("sequence_number").execute()
        
        if not points_result.data:
            return {
                "total_distance_meters": 0,
                "duration_seconds": 0,
                "average_speed_kmh": 0,
                "max_speed_kmh": 0,
                "elevation_gain_meters": 0,
                "pace_per_km_seconds": None,
                "point_count": 0
            }
            
        points = points_result.data
        total_distance = sum(p.get("distance_from_previous_meters", 0) for p in points)
        
        start_time = datetime.fromisoformat(points[0]["recorded_at"].replace('Z', '+00:00'))
        end_time = datetime.fromisoformat(points[-1]["recorded_at"].replace('Z', '+00:00'))
        duration_seconds = (end_time - start_time).total_seconds()
        
        # Vitesse moyenne
        avg_speed = (total_distance / duration_seconds * 3.6) if duration_seconds > 0 else 0
        
        # Vitesse max
        max_speed = max((p.get("speed_mps", 0) * 3.6 for p in points), default=0)
        
        # Pace (secondes par km)
        pace = int(3600 / avg_speed) if avg_speed > 0 else None
        
        return {
            "total_distance_meters": total_distance,
            "duration_seconds": int(duration_seconds),
            "average_speed_kmh": round(avg_speed, 2),
            "max_speed_kmh": round(max_speed, 2),
            "elevation_gain_meters": 0,  # TODO: calculer dénivelé
            "pace_per_km_seconds": pace,
            "point_count": len(points)
        }
        
    except Exception as e:
        print(f"Erreur calcul temps réel: {e}")
        return {
            "total_distance_meters": 0,
            "duration_seconds": 0,
            "average_speed_kmh": 0,
            "max_speed_kmh": 0,
            "elevation_gain_meters": 0,
            "pace_per_km_seconds": None,
            "point_count": 0
        }