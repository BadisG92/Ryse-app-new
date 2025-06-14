"""
Performance and Load Testing Suite - Task 10
Framework complet pour tester la performance et la charge de l'application Ryze
"""

import asyncio
import aiohttp
import time
import json
import statistics
import random
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass, field
from datetime import datetime, timedelta
import concurrent.futures
from urllib.parse import urljoin
import logging
import csv
import sys
from contextlib import asynccontextmanager

# Configuration logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# ==================== CONFIGURATIONS ====================

@dataclass
class LoadTestConfig:
    """Configuration pour les tests de charge"""
    
    # URLs et authentification
    base_url: str = "http://localhost:8000"
    auth_token: Optional[str] = None
    
    # Paramètres de charge
    concurrent_users: int = 100
    total_requests: int = 1000
    ramp_up_time: int = 60  # secondes
    test_duration: int = 300  # secondes
    
    # Limites de performance
    max_response_time_ms: int = 2000
    max_error_rate_percent: float = 1.0
    min_throughput_rps: float = 50.0  # Requests per second
    
    # Configuration connexions
    connection_timeout: int = 30
    read_timeout: int = 60
    max_connections: int = 500
    
    # Données de test
    test_users_count: int = 1000
    test_foods_count: int = 500
    test_workouts_count: int = 200

@dataclass
class PerformanceMetrics:
    """Métriques de performance collectées"""
    
    # Temps de réponse
    response_times: List[float] = field(default_factory=list)
    min_response_time: float = 0
    max_response_time: float = 0
    avg_response_time: float = 0
    p95_response_time: float = 0
    p99_response_time: float = 0
    
    # Throughput
    total_requests: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    requests_per_second: float = 0
    
    # Erreurs
    error_rate: float = 0
    error_details: Dict[str, int] = field(default_factory=dict)
    
    # Ressources
    peak_memory_mb: float = 0
    avg_cpu_percent: float = 0
    
    # Timestamp
    test_start_time: datetime = field(default_factory=datetime.now)
    test_end_time: Optional[datetime] = None
    test_duration: float = 0

# ==================== GÉNÉRATEURS DE DONNÉES ====================

class TestDataGenerator:
    """Générateur de données de test réalistes"""
    
    @staticmethod
    def generate_user_data(count: int) -> List[Dict[str, Any]]:
        """Génère des données utilisateur pour les tests"""
        users = []
        for i in range(count):
            users.append({
                "email": f"testuser{i}@ryze.app",
                "password": "TestPassword123!",
                "first_name": f"User{i}",
                "last_name": f"Test{i}",
                "age": random.randint(18, 65),
                "weight": random.uniform(50, 120),
                "height": random.uniform(150, 200),
                "activity_level": random.choice(["sedentary", "light", "moderate", "active", "very_active"]),
                "goal": random.choice(["lose_weight", "maintain_weight", "gain_weight", "build_muscle"])
            })
        return users
    
    @staticmethod
    def generate_food_data(count: int) -> List[Dict[str, Any]]:
        """Génère des données alimentaires pour les tests"""
        foods = []
        food_names = ["Chicken Breast", "Rice", "Broccoli", "Salmon", "Oats", "Banana", "Apple", "Egg"]
        
        for i in range(count):
            foods.append({
                "name": f"{random.choice(food_names)} {i}",
                "calories_per_100g": random.randint(50, 500),
                "proteins_per_100g": random.uniform(0, 30),
                "carbs_per_100g": random.uniform(0, 80),
                "fats_per_100g": random.uniform(0, 30),
                "serving_size": random.randint(50, 300)
            })
        return foods
    
    @staticmethod
    def generate_workout_data(count: int) -> List[Dict[str, Any]]:
        """Génère des données d'entraînement pour les tests"""
        workouts = []
        workout_types = ["strength", "cardio", "hiit", "flexibility"]
        exercises = ["Push-ups", "Squats", "Deadlifts", "Bench Press", "Running", "Cycling"]
        
        for i in range(count):
            workouts.append({
                "name": f"Workout {i}",
                "type": random.choice(workout_types),
                "duration_minutes": random.randint(15, 120),
                "exercises": [
                    {
                        "name": random.choice(exercises),
                        "sets": random.randint(1, 5),
                        "reps": random.randint(5, 20),
                        "weight": random.uniform(5, 100)
                    } for _ in range(random.randint(3, 8))
                ]
            })
        return workouts
    
    @staticmethod
    def generate_gps_points(count: int) -> List[Dict[str, Any]]:
        """Génère des points GPS pour tests de tracking"""
        base_lat, base_lon = 48.8566, 2.3522  # Paris
        points = []
        
        for i in range(count):
            # Simulation d'un parcours en spirale
            angle = i * 0.01
            radius = i * 0.0001
            
            points.append({
                "latitude": base_lat + radius * math.cos(angle),
                "longitude": base_lon + radius * math.sin(angle),
                "altitude_meters": 35.0 + random.uniform(-5, 10),
                "accuracy_meters": random.uniform(3, 15),
                "speed_mps": random.uniform(1, 5),
                "recorded_at": (datetime.now() + timedelta(seconds=i*5)).isoformat()
            })
        return points

# ==================== TESTS DE CHARGE SPÉCIFIQUES ====================

class RyzeLoadTester:
    """Testeur de charge spécialisé pour l'application Ryze"""
    
    def __init__(self, config: LoadTestConfig):
        self.config = config
        self.metrics = PerformanceMetrics()
        self.session: Optional[aiohttp.ClientSession] = None
        self.auth_tokens: List[str] = []
        
    async def __aenter__(self):
        """Initialisation du client HTTP"""
        connector = aiohttp.TCPConnector(
            limit=self.config.max_connections,
            limit_per_host=100
        )
        
        timeout = aiohttp.ClientTimeout(
            total=self.config.connection_timeout,
            sock_read=self.config.read_timeout
        )
        
        self.session = aiohttp.ClientSession(
            connector=connector,
            timeout=timeout,
            headers={
                "Content-Type": "application/json",
                "User-Agent": "Ryze-LoadTest/1.0"
            }
        )
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Nettoyage des ressources"""
        if self.session:
            await self.session.close()
    
    async def authenticate_users(self, user_count: int) -> List[str]:
        """Authentifie plusieurs utilisateurs et retourne les tokens"""
        logger.info(f"Authentification de {user_count} utilisateurs...")
        
        users = TestDataGenerator.generate_user_data(user_count)
        tokens = []
        
        # Créer et authentifier les utilisateurs
        for i, user in enumerate(users[:user_count]):
            try:
                # Inscription
                await self._make_request("POST", "/api/v1/auth/register", user)
                
                # Connexion
                login_data = {
                    "email": user["email"],
                    "password": user["password"]
                }
                
                response = await self._make_request("POST", "/api/v1/auth/login", login_data)
                if response and "access_token" in response:
                    tokens.append(response["access_token"])
                    
                if i % 50 == 0:
                    logger.info(f"Authentifiés: {i+1}/{user_count}")
                    
            except Exception as e:
                logger.warning(f"Erreur authentification utilisateur {i}: {e}")
                
        logger.info(f"Authentification terminée: {len(tokens)} tokens obtenus")
        return tokens
    
    async def _make_request(self, method: str, endpoint: str, data: Any = None, 
                          token: str = None, track_metrics: bool = True) -> Optional[Dict[str, Any]]:
        """Effectue une requête HTTP avec métriques"""
        url = urljoin(self.config.base_url, endpoint)
        headers = {}
        
        if token:
            headers["Authorization"] = f"Bearer {token}"
            
        start_time = time.time()
        
        try:
            if method.upper() == "GET":
                async with self.session.get(url, headers=headers) as response:
                    response_data = await response.json() if response.content_type == "application/json" else await response.text()
                    status = response.status
            else:
                async with self.session.request(method, url, json=data, headers=headers) as response:
                    response_data = await response.json() if response.content_type == "application/json" else await response.text()
                    status = response.status
                    
            response_time = (time.time() - start_time) * 1000  # en ms
            
            if track_metrics:
                self.metrics.total_requests += 1
                self.metrics.response_times.append(response_time)
                
                if 200 <= status < 300:
                    self.metrics.successful_requests += 1
                else:
                    self.metrics.failed_requests += 1
                    error_key = f"HTTP_{status}"
                    self.metrics.error_details[error_key] = self.metrics.error_details.get(error_key, 0) + 1
                    
            return response_data if 200 <= status < 300 else None
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            
            if track_metrics:
                self.metrics.total_requests += 1
                self.metrics.failed_requests += 1
                error_key = f"EXCEPTION_{type(e).__name__}"
                self.metrics.error_details[error_key] = self.metrics.error_details.get(error_key, 0) + 1
                self.metrics.response_times.append(response_time)
                
            logger.error(f"Erreur requête {method} {endpoint}: {e}")
            return None
    
    async def test_authentication_load(self, concurrent_users: int = 50) -> Dict[str, Any]:
        """Test de charge sur l'authentification"""
        logger.info(f"🔐 Test de charge authentification - {concurrent_users} utilisateurs")
        
        start_time = time.time()
        users = TestDataGenerator.generate_user_data(concurrent_users)
        
        async def authenticate_user(user_data):
            # Inscription
            register_result = await self._make_request("POST", "/api/v1/auth/register", user_data)
            
            # Connexion
            login_data = {"email": user_data["email"], "password": user_data["password"]}
            login_result = await self._make_request("POST", "/api/v1/auth/login", login_data)
            
            return register_result is not None and login_result is not None
        
        # Exécution parallèle
        tasks = [authenticate_user(user) for user in users]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        successful_auths = sum(1 for r in results if r is True)
        total_time = time.time() - start_time
        
        return {
            "test_type": "authentication_load",
            "concurrent_users": concurrent_users,
            "successful_authentications": successful_auths,
            "total_time_seconds": total_time,
            "auth_rate_per_second": successful_auths / total_time,
            "success_rate": successful_auths / concurrent_users * 100
        }
    
    async def test_nutrition_api_load(self, concurrent_requests: int = 100) -> Dict[str, Any]:
        """Test de charge sur l'API nutrition"""
        logger.info(f"🥗 Test de charge API nutrition - {concurrent_requests} requêtes")
        
        if not self.auth_tokens:
            self.auth_tokens = await self.authenticate_users(10)
            
        foods = TestDataGenerator.generate_food_data(50)
        start_time = time.time()
        
        async def nutrition_operations():
            token = random.choice(self.auth_tokens) if self.auth_tokens else None
            
            # Opérations variées
            operations = [
                ("GET", "/api/nutrition/foods", None),
                ("POST", "/api/nutrition/foods", random.choice(foods)),
                ("GET", "/api/nutrition/daily-summary", None),
                ("POST", "/api/nutrition/food-entries", {
                    "food_id": random.randint(1, 100),
                    "quantity": random.uniform(50, 300),
                    "meal_type": random.choice(["breakfast", "lunch", "dinner", "snack"])
                })
            ]
            
            method, endpoint, data = random.choice(operations)
            result = await self._make_request(method, endpoint, data, token)
            return result is not None
        
        # Exécution parallèle
        tasks = [nutrition_operations() for _ in range(concurrent_requests)]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        successful_ops = sum(1 for r in results if r is True)
        total_time = time.time() - start_time
        
        return {
            "test_type": "nutrition_api_load",
            "concurrent_requests": concurrent_requests,
            "successful_operations": successful_ops,
            "total_time_seconds": total_time,
            "operations_per_second": successful_ops / total_time,
            "success_rate": successful_ops / concurrent_requests * 100
        }
    
    async def test_workout_api_load(self, concurrent_requests: int = 100) -> Dict[str, Any]:
        """Test de charge sur l'API workouts"""
        logger.info(f"💪 Test de charge API workouts - {concurrent_requests} requêtes")
        
        if not self.auth_tokens:
            self.auth_tokens = await self.authenticate_users(10)
            
        workouts = TestDataGenerator.generate_workout_data(20)
        start_time = time.time()
        
        async def workout_operations():
            token = random.choice(self.auth_tokens) if self.auth_tokens else None
            
            operations = [
                ("GET", "/api/v1/workouts", None),
                ("POST", "/api/v1/workouts", random.choice(workouts)),
                ("GET", "/api/v1/exercises", None),
                ("GET", "/api/workout-templates", None)
            ]
            
            method, endpoint, data = random.choice(operations)
            result = await self._make_request(method, endpoint, data, token)
            return result is not None
        
        tasks = [workout_operations() for _ in range(concurrent_requests)]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        successful_ops = sum(1 for r in results if r is True)
        total_time = time.time() - start_time
        
        return {
            "test_type": "workout_api_load",
            "concurrent_requests": concurrent_requests,
            "successful_operations": successful_ops,
            "total_time_seconds": total_time,
            "operations_per_second": successful_ops / total_time,
            "success_rate": successful_ops / concurrent_requests * 100
        }
    
    async def test_external_services_load(self, concurrent_requests: int = 50) -> Dict[str, Any]:
        """Test de charge sur les services externes (barcode, GPS)"""
        logger.info(f"📱 Test de charge services externes - {concurrent_requests} requêtes")
        
        if not self.auth_tokens:
            self.auth_tokens = await self.authenticate_users(5)
            
        start_time = time.time()
        
        async def external_operations():
            token = random.choice(self.auth_tokens) if self.auth_tokens else None
            
            # Opérations services externes
            operations = [
                # Barcode scanning
                ("POST", "/api/external-services/barcode/search", {
                    "barcode": f"123456789012{random.randint(0,9)}",
                    "force_refresh": False
                }),
                ("GET", "/api/external-services/barcode/popular", None),
                
                # GPS tracking
                ("POST", "/api/external-services/gps/sessions", {
                    "activity_type": random.choice(["running", "walking", "cycling"]),
                    "tracking_accuracy": "high"
                }),
                ("GET", "/api/external-services/mobile/health", None),
                ("GET", "/api/external-services/mobile/config?platform=ios", None)
            ]
            
            method, endpoint, data = random.choice(operations)
            result = await self._make_request(method, endpoint, data, token)
            return result is not None
        
        tasks = [external_operations() for _ in range(concurrent_requests)]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        successful_ops = sum(1 for r in results if r is True)
        total_time = time.time() - start_time
        
        return {
            "test_type": "external_services_load",
            "concurrent_requests": concurrent_requests,
            "successful_operations": successful_ops,
            "total_time_seconds": total_time,
            "operations_per_second": successful_ops / total_time,
            "success_rate": successful_ops / concurrent_requests * 100
        }
    
    async def test_real_time_sync_load(self, concurrent_connections: int = 20) -> Dict[str, Any]:
        """Test de charge sur la synchronisation temps réel"""
        logger.info(f"⚡ Test de charge sync temps réel - {concurrent_connections} connexions")
        
        start_time = time.time()
        
        async def realtime_operations():
            # Simulation d'opérations temps réel
            operations = [
                ("GET", "/api/realtime/sync-status", None),
                ("POST", "/api/realtime/client-state", {
                    "last_sync": datetime.now().isoformat(),
                    "pending_changes": random.randint(0, 10)
                }),
                ("GET", "/api/realtime/changes", None)
            ]
            
            method, endpoint, data = random.choice(operations)
            result = await self._make_request(method, endpoint, data)
            return result is not None
        
        tasks = [realtime_operations() for _ in range(concurrent_connections)]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        successful_ops = sum(1 for r in results if r is True)
        total_time = time.time() - start_time
        
        return {
            "test_type": "realtime_sync_load",
            "concurrent_connections": concurrent_connections,
            "successful_operations": successful_ops,
            "total_time_seconds": total_time,
            "operations_per_second": successful_ops / total_time,
            "success_rate": successful_ops / concurrent_connections * 100
        }
    
    def calculate_metrics(self) -> None:
        """Calcule les métriques finales de performance"""
        if not self.metrics.response_times:
            return
            
        self.metrics.min_response_time = min(self.metrics.response_times)
        self.metrics.max_response_time = max(self.metrics.response_times)
        self.metrics.avg_response_time = statistics.mean(self.metrics.response_times)
        
        sorted_times = sorted(self.metrics.response_times)
        self.metrics.p95_response_time = sorted_times[int(len(sorted_times) * 0.95)]
        self.metrics.p99_response_time = sorted_times[int(len(sorted_times) * 0.99)]
        
        self.metrics.error_rate = (self.metrics.failed_requests / self.metrics.total_requests * 100) if self.metrics.total_requests > 0 else 0
        
        self.metrics.test_end_time = datetime.now()
        self.metrics.test_duration = (self.metrics.test_end_time - self.metrics.test_start_time).total_seconds()
        self.metrics.requests_per_second = self.metrics.total_requests / self.metrics.test_duration if self.metrics.test_duration > 0 else 0

# ==================== EXÉCUTION COMPLÈTE DES TESTS ====================

async def run_comprehensive_load_tests(config: LoadTestConfig) -> Dict[str, Any]:
    """Exécute tous les tests de charge de manière complète"""
    
    logger.info("🚀 DÉMARRAGE DES TESTS DE CHARGE RYZE")
    logger.info("="*60)
    
    results = {
        "test_config": config.__dict__,
        "test_results": [],
        "overall_metrics": {},
        "recommendations": []
    }
    
    async with RyzeLoadTester(config) as tester:
        
        # 1. Test authentification
        auth_result = await tester.test_authentication_load(50)
        results["test_results"].append(auth_result)
        logger.info(f"✅ Auth: {auth_result['success_rate']:.1f}% success, {auth_result['auth_rate_per_second']:.1f} auth/s")
        
        # 2. Test API nutrition
        nutrition_result = await tester.test_nutrition_api_load(100)
        results["test_results"].append(nutrition_result)
        logger.info(f"✅ Nutrition: {nutrition_result['success_rate']:.1f}% success, {nutrition_result['operations_per_second']:.1f} ops/s")
        
        # 3. Test API workouts
        workout_result = await tester.test_workout_api_load(100)
        results["test_results"].append(workout_result)
        logger.info(f"✅ Workouts: {workout_result['success_rate']:.1f}% success, {workout_result['operations_per_second']:.1f} ops/s")
        
        # 4. Test services externes
        external_result = await tester.test_external_services_load(50)
        results["test_results"].append(external_result)
        logger.info(f"✅ External: {external_result['success_rate']:.1f}% success, {external_result['operations_per_second']:.1f} ops/s")
        
        # 5. Test temps réel
        realtime_result = await tester.test_real_time_sync_load(20)
        results["test_results"].append(realtime_result)
        logger.info(f"✅ Realtime: {realtime_result['success_rate']:.1f}% success, {realtime_result['operations_per_second']:.1f} ops/s")
        
        # Calcul des métriques globales
        tester.calculate_metrics()
        
        results["overall_metrics"] = {
            "total_requests": tester.metrics.total_requests,
            "successful_requests": tester.metrics.successful_requests,
            "failed_requests": tester.metrics.failed_requests,
            "avg_response_time_ms": tester.metrics.avg_response_time,
            "p95_response_time_ms": tester.metrics.p95_response_time,
            "p99_response_time_ms": tester.metrics.p99_response_time,
            "error_rate_percent": tester.metrics.error_rate,
            "requests_per_second": tester.metrics.requests_per_second,
            "test_duration_seconds": tester.metrics.test_duration
        }
        
        # Générer recommandations
        recommendations = generate_performance_recommendations(results, config)
        results["recommendations"] = recommendations
        
    return results

def generate_performance_recommendations(results: Dict[str, Any], config: LoadTestConfig) -> List[str]:
    """Génère des recommandations basées sur les résultats de tests"""
    recommendations = []
    metrics = results["overall_metrics"]
    
    # Analyse temps de réponse
    if metrics["avg_response_time_ms"] > config.max_response_time_ms:
        recommendations.append(f"⚠️ Temps de réponse moyen ({metrics['avg_response_time_ms']:.0f}ms) dépasse la limite ({config.max_response_time_ms}ms)")
        recommendations.append("💡 Optimiser les requêtes DB et ajouter du cache Redis")
    
    # Analyse taux d'erreur
    if metrics["error_rate_percent"] > config.max_error_rate_percent:
        recommendations.append(f"⚠️ Taux d'erreur ({metrics['error_rate_percent']:.1f}%) dépasse la limite ({config.max_error_rate_percent}%)")
        recommendations.append("💡 Améliorer la gestion d'erreurs et ajouter circuit breakers")
    
    # Analyse throughput
    if metrics["requests_per_second"] < config.min_throughput_rps:
        recommendations.append(f"⚠️ Throughput ({metrics['requests_per_second']:.1f} rps) sous la limite ({config.min_throughput_rps} rps)")
        recommendations.append("💡 Optimiser l'architecture et considérer le scaling horizontal")
    
    # Recommandations spécifiques par module
    for test_result in results["test_results"]:
        if test_result["success_rate"] < 95:
            module = test_result["test_type"]
            recommendations.append(f"⚠️ Module {module}: succès {test_result['success_rate']:.1f}% < 95%")
    
    # Recommandations positives
    if not recommendations:
        recommendations.append("✅ Toutes les métriques sont dans les limites acceptables")
        recommendations.append("🚀 L'application est prête pour la production")
    
    return recommendations

# ==================== EXPORT ET REPORTING ====================

def export_results_to_csv(results: Dict[str, Any], filename: str = "load_test_results.csv"):
    """Exporte les résultats vers un fichier CSV"""
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        
        # Header général
        writer.writerow(["Ryze Load Test Results", datetime.now().isoformat()])
        writer.writerow([])
        
        # Métriques globales
        writer.writerow(["Overall Metrics"])
        writer.writerow(["Metric", "Value", "Unit"])
        
        metrics = results["overall_metrics"]
        for key, value in metrics.items():
            unit = ""
            if "time" in key and "ms" in key:
                unit = "ms"
            elif "percent" in key:
                unit = "%"
            elif "per_second" in key:
                unit = "per second"
            elif "seconds" in key:
                unit = "seconds"
                
            writer.writerow([key.replace("_", " ").title(), f"{value:.2f}", unit])
        
        writer.writerow([])
        
        # Résultats par test
        writer.writerow(["Test Results by Module"])
        writer.writerow(["Test Type", "Concurrent Users/Requests", "Success Rate %", "Operations/sec"])
        
        for test_result in results["test_results"]:
            concurrent = test_result.get("concurrent_users", test_result.get("concurrent_requests", test_result.get("concurrent_connections", 0)))
            ops_per_sec = test_result.get("operations_per_second", test_result.get("auth_rate_per_second", 0))
            
            writer.writerow([
                test_result["test_type"].replace("_", " ").title(),
                concurrent,
                f"{test_result['success_rate']:.1f}",
                f"{ops_per_sec:.1f}"
            ])
        
        writer.writerow([])
        
        # Recommandations
        writer.writerow(["Recommendations"])
        for rec in results["recommendations"]:
            writer.writerow([rec])

def generate_html_report(results: Dict[str, Any], filename: str = "load_test_report.html"):
    """Génère un rapport HTML détaillé"""
    
    html_content = f"""
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Ryze Load Test Report</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
            .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center; }}
            .section {{ background: white; margin: 20px 0; padding: 20px; border-radius: 10px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }}
            .metrics-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }}
            .metric-card {{ background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; }}
            .metric-value {{ font-size: 24px; font-weight: bold; color: #667eea; }}
            .recommendation {{ padding: 10px; margin: 5px 0; border-radius: 5px; }}
            .warning {{ background-color: #fff3cd; border-left: 4px solid #ffc107; }}
            .success {{ background-color: #d4edda; border-left: 4px solid #28a745; }}
            .info {{ background-color: #d1ecf1; border-left: 4px solid #17a2b8; }}
            table {{ width: 100%; border-collapse: collapse; }}
            th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
            th {{ background-color: #667eea; color: white; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🚀 Ryze Load Test Report</h1>
            <p>Performance and Load Testing Results - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        </div>
        
        <div class="section">
            <h2>📊 Overall Performance Metrics</h2>
            <div class="metrics-grid">
    """
    
    metrics = results["overall_metrics"]
    metric_cards = [
        ("Total Requests", metrics["total_requests"], ""),
        ("Success Rate", f"{(metrics['successful_requests']/metrics['total_requests']*100):.1f}", "%"),
        ("Avg Response Time", f"{metrics['avg_response_time_ms']:.0f}", "ms"),
        ("P95 Response Time", f"{metrics['p95_response_time_ms']:.0f}", "ms"),
        ("Throughput", f"{metrics['requests_per_second']:.1f}", "req/s"),
        ("Error Rate", f"{metrics['error_rate_percent']:.2f}", "%")
    ]
    
    for name, value, unit in metric_cards:
        html_content += f"""
                <div class="metric-card">
                    <div class="metric-value">{value}{unit}</div>
                    <div>{name}</div>
                </div>
        """
    
    html_content += """
            </div>
        </div>
        
        <div class="section">
            <h2>🧪 Test Results by Module</h2>
            <table>
                <tr>
                    <th>Module</th>
                    <th>Concurrent Load</th>
                    <th>Success Rate</th>
                    <th>Throughput</th>
                    <th>Duration</th>
                </tr>
    """
    
    for test_result in results["test_results"]:
        concurrent = test_result.get("concurrent_users", test_result.get("concurrent_requests", test_result.get("concurrent_connections", 0)))
        ops_per_sec = test_result.get("operations_per_second", test_result.get("auth_rate_per_second", 0))
        
        html_content += f"""
                <tr>
                    <td>{test_result["test_type"].replace("_", " ").title()}</td>
                    <td>{concurrent}</td>
                    <td>{test_result['success_rate']:.1f}%</td>
                    <td>{ops_per_sec:.1f} ops/s</td>
                    <td>{test_result['total_time_seconds']:.1f}s</td>
                </tr>
        """
    
    html_content += """
            </table>
        </div>
        
        <div class="section">
            <h2>💡 Recommendations</h2>
    """
    
    for rec in results["recommendations"]:
        css_class = "warning" if "⚠️" in rec else ("success" if "✅" in rec else "info")
        html_content += f'<div class="recommendation {css_class}">{rec}</div>'
    
    html_content += """
        </div>
    </body>
    </html>
    """
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(html_content)

# ==================== MAIN EXECUTION ====================

async def main():
    """Fonction principale pour exécuter les tests de charge"""
    
    # Configuration des tests
    config = LoadTestConfig(
        base_url="http://localhost:8000",
        concurrent_users=100,
        total_requests=1000,
        max_response_time_ms=2000,
        max_error_rate_percent=1.0,
        min_throughput_rps=50.0
    )
    
    print("🚀 Ryze Performance & Load Testing Suite")
    print("="*50)
    print(f"Target: {config.base_url}")
    print(f"Concurrent Users: {config.concurrent_users}")
    print(f"Total Requests: {config.total_requests}")
    print("="*50)
    
    try:
        # Exécution des tests
        results = await run_comprehensive_load_tests(config)
        
        # Export des résultats
        export_results_to_csv(results, "ryze_load_test_results.csv")
        generate_html_report(results, "ryze_load_test_report.html")
        
        print("\n" + "="*50)
        print("📈 RÉSULTATS FINAUX")
        print("="*50)
        
        metrics = results["overall_metrics"]
        print(f"✅ Total Requests: {metrics['total_requests']}")
        print(f"✅ Success Rate: {(metrics['successful_requests']/metrics['total_requests']*100):.1f}%")
        print(f"✅ Average Response Time: {metrics['avg_response_time_ms']:.0f}ms")
        print(f"✅ P95 Response Time: {metrics['p95_response_time_ms']:.0f}ms")
        print(f"✅ Throughput: {metrics['requests_per_second']:.1f} requests/second")
        print(f"✅ Error Rate: {metrics['error_rate_percent']:.2f}%")
        
        print("\n💡 RECOMMANDATIONS:")
        for rec in results["recommendations"]:
            print(f"   {rec}")
        
        print(f"\n📄 Rapports générés:")
        print(f"   • CSV: ryze_load_test_results.csv")
        print(f"   • HTML: ryze_load_test_report.html")
        
    except Exception as e:
        logger.error(f"Erreur lors de l'exécution des tests: {e}")
        sys.exit(1)

if __name__ == "__main__":
    import math
    asyncio.run(main())