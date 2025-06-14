"""
Performance Optimization Module - Task 10
Configuration d'optimisations de performance pour l'application Ryze
"""

import asyncio
import redis.asyncio as redis
from sqlalchemy.pool import QueuePool
from sqlalchemy import create_engine
import psutil
import time
import logging
from typing import Dict, Any, Optional, List
from dataclasses import dataclass, field
from datetime import datetime, timedelta
import json
import os
from contextlib import asynccontextmanager

# Configuration logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ==================== CONFIGURATION CACHE REDIS ====================

@dataclass
class CacheConfig:
    """Configuration du cache Redis"""
    
    redis_url: str = "redis://localhost:6379"
    default_ttl: int = 3600  # 1 heure
    max_connections: int = 20
    
    # TTL spécifiques par type de données
    ttl_user_profile: int = 1800  # 30 minutes
    ttl_nutrition_data: int = 7200  # 2 heures
    ttl_workout_templates: int = 14400  # 4 heures
    ttl_barcode_cache: int = 86400  # 24 heures
    ttl_gps_sessions: int = 3600  # 1 heure

class RyzeCache:
    """Cache Redis optimisé pour Ryze"""
    
    def __init__(self, config: CacheConfig):
        self.config = config
        self.redis_client: Optional[redis.Redis] = None
        
    async def initialize(self):
        """Initialise la connexion Redis"""
        try:
            self.redis_client = redis.from_url(
                self.config.redis_url,
                max_connections=self.config.max_connections,
                retry_on_timeout=True,
                decode_responses=True
            )
            
            # Test de connexion
            await self.redis_client.ping()
            logger.info("✅ Cache Redis initialisé")
            
        except Exception as e:
            logger.error(f"❌ Erreur initialisation Redis: {e}")
            self.redis_client = None
    
    async def get(self, key: str) -> Optional[Any]:
        """Récupère une valeur du cache"""
        if not self.redis_client:
            return None
            
        try:
            value = await self.redis_client.get(key)
            if value:
                return json.loads(value)
        except Exception as e:
            logger.warning(f"Erreur cache GET {key}: {e}")
        
        return None
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Stocke une valeur dans le cache"""
        if not self.redis_client:
            return False
            
        try:
            ttl = ttl or self.config.default_ttl
            serialized_value = json.dumps(value, default=str)
            await self.redis_client.setex(key, ttl, serialized_value)
            return True
        except Exception as e:
            logger.warning(f"Erreur cache SET {key}: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """Supprime une clé du cache"""
        if not self.redis_client:
            return False
            
        try:
            await self.redis_client.delete(key)
            return True
        except Exception as e:
            logger.warning(f"Erreur cache DELETE {key}: {e}")
            return False
    
    async def clear_pattern(self, pattern: str) -> int:
        """Supprime toutes les clés correspondant au pattern"""
        if not self.redis_client:
            return 0
            
        try:
            keys = await self.redis_client.keys(pattern)
            if keys:
                deleted = await self.redis_client.delete(*keys)
                return deleted
        except Exception as e:
            logger.warning(f"Erreur cache CLEAR_PATTERN {pattern}: {e}")
        
        return 0
    
    async def get_stats(self) -> Dict[str, Any]:
        """Récupère les statistiques du cache"""
        if not self.redis_client:
            return {}
            
        try:
            info = await self.redis_client.info()
            return {
                "used_memory_human": info.get("used_memory_human", "N/A"),
                "connected_clients": info.get("connected_clients", 0),
                "total_commands_processed": info.get("total_commands_processed", 0),
                "keyspace_hits": info.get("keyspace_hits", 0),
                "keyspace_misses": info.get("keyspace_misses", 0),
                "hit_rate": info.get("keyspace_hits", 0) / max(info.get("keyspace_hits", 0) + info.get("keyspace_misses", 1), 1) * 100
            }
        except Exception as e:
            logger.warning(f"Erreur stats Redis: {e}")
            return {}
    
    async def close(self):
        """Ferme la connexion Redis"""
        if self.redis_client:
            await self.redis_client.close()

# ==================== OPTIMISATION BASE DE DONNÉES ====================

@dataclass
class DatabaseConfig:
    """Configuration optimisée de la base de données"""
    
    # Pool de connexions
    pool_size: int = 20
    max_overflow: int = 30
    pool_timeout: int = 30
    pool_recycle: int = 3600  # 1 heure
    
    # Performances
    echo: bool = False
    connect_args: Dict[str, Any] = field(default_factory=lambda: {
        "connect_timeout": 10,
        "command_timeout": 60,
        "server_settings": {
            "application_name": "ryze_app",
            "jit": "off"  # Désactive JIT pour les petites requêtes
        }
    })

def create_optimized_database_engine(database_url: str, config: DatabaseConfig):
    """Crée un moteur de base de données optimisé"""
    
    return create_engine(
        database_url,
        poolclass=QueuePool,
        pool_size=config.pool_size,
        max_overflow=config.max_overflow,
        pool_timeout=config.pool_timeout,
        pool_recycle=config.pool_recycle,
        pool_pre_ping=True,  # Vérifie les connexions avant utilisation
        echo=config.echo,
        connect_args=config.connect_args
    )

# ==================== MONITORING DE PERFORMANCE ====================

@dataclass
class PerformanceStats:
    """Statistiques de performance en temps réel"""
    
    # Système
    cpu_percent: float = 0
    memory_percent: float = 0
    memory_used_mb: float = 0
    disk_usage_percent: float = 0
    
    # Application
    active_connections: int = 0
    request_count: int = 0
    avg_response_time_ms: float = 0
    error_count: int = 0
    
    # Cache
    cache_hit_rate: float = 0
    cache_memory_mb: float = 0
    
    # Timestamp
    timestamp: datetime = field(default_factory=datetime.now)

class PerformanceMonitor:
    """Moniteur de performance en temps réel"""
    
    def __init__(self, cache: RyzeCache):
        self.cache = cache
        self.stats_history: List[PerformanceStats] = []
        self.max_history = 100  # Garde les 100 dernières mesures
        
    async def collect_stats(self) -> PerformanceStats:
        """Collecte les statistiques actuelles"""
        stats = PerformanceStats()
        
        try:
            # Statistiques système
            stats.cpu_percent = psutil.cpu_percent(interval=0.1)
            memory = psutil.virtual_memory()
            stats.memory_percent = memory.percent
            stats.memory_used_mb = memory.used / 1024 / 1024
            
            disk = psutil.disk_usage('/')
            stats.disk_usage_percent = (disk.used / disk.total) * 100
            
            # Statistiques cache
            cache_stats = await self.cache.get_stats()
            stats.cache_hit_rate = cache_stats.get("hit_rate", 0)
            
            # Ajouter à l'historique
            self.stats_history.append(stats)
            if len(self.stats_history) > self.max_history:
                self.stats_history.pop(0)
                
        except Exception as e:
            logger.warning(f"Erreur collecte stats: {e}")
            
        return stats
    
    def get_performance_summary(self) -> Dict[str, Any]:
        """Retourne un résumé des performances"""
        if not self.stats_history:
            return {}
            
        recent_stats = self.stats_history[-10:]  # 10 dernières mesures
        
        return {
            "current": {
                "cpu_percent": recent_stats[-1].cpu_percent,
                "memory_percent": recent_stats[-1].memory_percent,
                "memory_used_mb": recent_stats[-1].memory_used_mb,
                "cache_hit_rate": recent_stats[-1].cache_hit_rate
            },
            "averages": {
                "avg_cpu_percent": sum(s.cpu_percent for s in recent_stats) / len(recent_stats),
                "avg_memory_percent": sum(s.memory_percent for s in recent_stats) / len(recent_stats),
                "avg_cache_hit_rate": sum(s.cache_hit_rate for s in recent_stats) / len(recent_stats)
            },
            "alerts": self._generate_alerts(recent_stats)
        }
    
    def _generate_alerts(self, stats: List[PerformanceStats]) -> List[str]:
        """Génère des alertes basées sur les statistiques"""
        alerts = []
        
        if not stats:
            return alerts
            
        latest = stats[-1]
        
        # Alertes CPU
        if latest.cpu_percent > 80:
            alerts.append(f"⚠️ CPU élevé: {latest.cpu_percent:.1f}%")
            
        # Alertes mémoire
        if latest.memory_percent > 85:
            alerts.append(f"⚠️ Mémoire élevée: {latest.memory_percent:.1f}%")
            
        # Alertes cache
        if latest.cache_hit_rate < 50:
            alerts.append(f"⚠️ Taux de cache faible: {latest.cache_hit_rate:.1f}%")
            
        # Alertes disque
        if latest.disk_usage_percent > 90:
            alerts.append(f"⚠️ Disque plein: {latest.disk_usage_percent:.1f}%")
            
        return alerts

# ==================== DECORATEURS DE CACHE ====================

def cache_result(cache: RyzeCache, ttl: int = 3600, key_prefix: str = ""):
    """Décorateur pour mettre en cache les résultats de fonction"""
    
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # Génération de la clé de cache
            cache_key = f"{key_prefix}:{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # Tentative de récupération du cache
            cached_result = await cache.get(cache_key)
            if cached_result is not None:
                return cached_result
                
            # Exécution de la fonction et mise en cache
            result = await func(*args, **kwargs)
            await cache.set(cache_key, result, ttl)
            
            return result
        return wrapper
    return decorator

# ==================== CONFIGURATION COMPLÈTE ====================

class PerformanceOptimizer:
    """Gestionnaire principal des optimisations de performance"""
    
    def __init__(self):
        self.cache_config = CacheConfig()
        self.db_config = DatabaseConfig()
        self.cache: Optional[RyzeCache] = None
        self.monitor: Optional[PerformanceMonitor] = None
        
    async def initialize(self):
        """Initialise toutes les optimisations"""
        logger.info("🚀 Initialisation des optimisations de performance...")
        
        # Initialisation du cache
        self.cache = RyzeCache(self.cache_config)
        await self.cache.initialize()
        
        # Initialisation du monitoring
        self.monitor = PerformanceMonitor(self.cache)
        
        logger.info("✅ Optimisations de performance initialisées")
    
    async def get_optimization_status(self) -> Dict[str, Any]:
        """Retourne le statut des optimisations"""
        status = {
            "cache": {
                "enabled": self.cache and self.cache.redis_client is not None,
                "stats": await self.cache.get_stats() if self.cache else {}
            },
            "monitoring": {
                "enabled": self.monitor is not None,
                "performance": self.monitor.get_performance_summary() if self.monitor else {}
            },
            "database": {
                "pool_configured": True,
                "config": {
                    "pool_size": self.db_config.pool_size,
                    "max_overflow": self.db_config.max_overflow
                }
            }
        }
        
        return status
    
    async def run_performance_check(self) -> Dict[str, Any]:
        """Exécute une vérification complète de performance"""
        check_results = {
            "timestamp": datetime.now().isoformat(),
            "checks": []
        }
        
        # Vérification cache
        if self.cache:
            cache_stats = await self.cache.get_stats()
            check_results["checks"].append({
                "component": "cache",
                "status": "healthy" if cache_stats else "warning",
                "details": cache_stats
            })
        
        # Vérification monitoring
        if self.monitor:
            perf_stats = await self.monitor.collect_stats()
            status = "healthy"
            if perf_stats.cpu_percent > 80 or perf_stats.memory_percent > 85:
                status = "warning"
                
            check_results["checks"].append({
                "component": "system",
                "status": status,
                "details": {
                    "cpu_percent": perf_stats.cpu_percent,
                    "memory_percent": perf_stats.memory_percent,
                    "memory_used_mb": perf_stats.memory_used_mb
                }
            })
        
        return check_results
    
    async def cleanup(self):
        """Nettoyage des ressources"""
        if self.cache:
            await self.cache.close()

# ==================== HELPERS POUR ENDPOINTS OPTIMISÉS ====================

async def get_cached_user_profile(user_id: int, cache: RyzeCache) -> Optional[Dict[str, Any]]:
    """Récupère le profil utilisateur avec cache"""
    cache_key = f"user_profile:{user_id}"
    return await cache.get(cache_key)

async def set_cached_user_profile(user_id: int, profile_data: Dict[str, Any], 
                                cache: RyzeCache) -> bool:
    """Met en cache le profil utilisateur"""
    cache_key = f"user_profile:{user_id}"
    return await cache.set(cache_key, profile_data, cache.config.ttl_user_profile)

async def get_cached_nutrition_data(user_id: int, date: str, cache: RyzeCache) -> Optional[Dict[str, Any]]:
    """Récupère les données nutritionnelles avec cache"""
    cache_key = f"nutrition_data:{user_id}:{date}"
    return await cache.get(cache_key)

async def get_cached_barcode_data(barcode: str, cache: RyzeCache) -> Optional[Dict[str, Any]]:
    """Récupère les données de code-barres avec cache"""
    cache_key = f"barcode_data:{barcode}"
    return await cache.get(cache_key)

async def set_cached_barcode_data(barcode: str, product_data: Dict[str, Any], 
                                cache: RyzeCache) -> bool:
    """Met en cache les données de code-barres"""
    cache_key = f"barcode_data:{barcode}"
    return await cache.set(cache_key, product_data, cache.config.ttl_barcode_cache)

# ==================== CONFIGURATION PRODUCTION ====================

def get_production_config() -> Dict[str, Any]:
    """Configuration optimisée pour la production"""
    return {
        "cache": {
            "redis_url": os.getenv("REDIS_URL", "redis://localhost:6379"),
            "max_connections": 50,
            "default_ttl": 3600
        },
        "database": {
            "pool_size": 30,
            "max_overflow": 50,
            "pool_timeout": 30,
            "pool_recycle": 3600
        },
        "monitoring": {
            "collect_interval": 30,  # secondes
            "alert_thresholds": {
                "cpu_percent": 80,
                "memory_percent": 85,
                "cache_hit_rate": 70
            }
        }
    }

# ==================== EXEMPLE D'UTILISATION ====================

async def example_usage():
    """Exemple d'utilisation des optimisations"""
    
    # Initialisation
    optimizer = PerformanceOptimizer()
    await optimizer.initialize()
    
    # Vérification du statut
    status = await optimizer.get_optimization_status()
    print("Status des optimisations:", json.dumps(status, indent=2, default=str))
    
    # Test du cache
    if optimizer.cache:
        await optimizer.cache.set("test_key", {"data": "test"}, 60)
        cached_data = await optimizer.cache.get("test_key")
        print("Test cache:", cached_data)
    
    # Collecte de statistiques
    if optimizer.monitor:
        stats = await optimizer.monitor.collect_stats()
        print(f"CPU: {stats.cpu_percent}%, Mémoire: {stats.memory_percent}%")
    
    # Nettoyage
    await optimizer.cleanup()

if __name__ == "__main__":
    asyncio.run(example_usage())