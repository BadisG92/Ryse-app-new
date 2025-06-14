"""
Tests de Performance Simplifiés - Task 10
Validation préliminaire des endpoints avant les tests de charge complets
"""

import asyncio
import aiohttp
import time
import sys
import logging
from typing import Dict, Any, List

# Configuration logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SimplePerformanceTester:
    """Testeur simple pour valider les endpoints"""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.session = None
        
    async def __aenter__(self):
        """Initialisation du client HTTP"""
        self.session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=30),
            headers={
                "Content-Type": "application/json",
                "User-Agent": "Ryze-SimpleTest/1.0"
            }
        )
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Nettoyage des ressources"""
        if self.session:
            await self.session.close()
    
    async def test_endpoint(self, method: str, endpoint: str, data: Any = None, 
                          headers: Dict[str, str] = None) -> Dict[str, Any]:
        """Test un endpoint spécifique"""
        url = f"{self.base_url}{endpoint}"
        start_time = time.time()
        
        try:
            if method.upper() == "GET":
                async with self.session.get(url, headers=headers) as response:
                    response_data = await response.text()
                    status = response.status
            elif method.upper() == "POST":
                async with self.session.post(url, json=data, headers=headers) as response:
                    response_data = await response.text()
                    status = response.status
            else:
                async with self.session.request(method, url, json=data, headers=headers) as response:
                    response_data = await response.text()
                    status = response.status
                    
            response_time = (time.time() - start_time) * 1000  # ms
            
            return {
                "endpoint": endpoint,
                "method": method,
                "status": status,
                "response_time_ms": response_time,
                "success": 200 <= status < 300,
                "response_length": len(response_data) if response_data else 0
            }
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            logger.error(f"Erreur {method} {endpoint}: {e}")
            
            return {
                "endpoint": endpoint,
                "method": method,
                "status": 0,
                "response_time_ms": response_time,
                "success": False,
                "error": str(e)
            }
    
    async def test_basic_endpoints(self) -> List[Dict[str, Any]]:
        """Test les endpoints de base de l'application"""
        
        endpoints_to_test = [
            # Health checks
            ("GET", "/health", None),
            ("GET", "/", None),
            
            # API Documentation
            ("GET", "/docs", None),
            ("GET", "/openapi.json", None),
            
            # Authentication endpoints (should return error without data but endpoint should exist)
            ("POST", "/api/v1/auth/register", {"email": "test@test.com", "password": "test123"}),
            ("POST", "/api/v1/auth/login", {"email": "test@test.com", "password": "test123"}),
            
            # External services endpoints
            ("GET", "/api/external-services/mobile/health", None),
            ("GET", "/api/external-services/mobile/config?platform=ios", None),
            
            # Nutrition endpoints (may return 401 without auth but should exist)
            ("GET", "/api/nutrition/foods", None),
            ("GET", "/api/nutrition/daily-summary", None),
            
            # Workout endpoints
            ("GET", "/api/v1/workouts", None),
            ("GET", "/api/v1/exercises", None),
            
            # Realtime endpoints
            ("GET", "/api/realtime/sync-status", None),
        ]
        
        logger.info(f"🧪 Test de {len(endpoints_to_test)} endpoints de base...")
        
        results = []
        for method, endpoint, data in endpoints_to_test:
            result = await self.test_endpoint(method, endpoint, data)
            results.append(result)
            
            status_icon = "✅" if result["success"] or result["status"] in [401, 422] else "❌"
            logger.info(f"{status_icon} {method} {endpoint}: {result['status']} ({result['response_time_ms']:.0f}ms)")
            
        return results
    
    async def test_concurrent_requests(self, endpoint: str = "/health", count: int = 10) -> Dict[str, Any]:
        """Test de charge simple avec requêtes concurrentes"""
        logger.info(f"🚀 Test concurrent: {count} requêtes sur {endpoint}")
        
        start_time = time.time()
        
        # Exécution parallèle
        tasks = [self.test_endpoint("GET", endpoint) for _ in range(count)]
        results = await asyncio.gather(*tasks)
        
        total_time = time.time() - start_time
        successful_requests = sum(1 for r in results if r["success"])
        avg_response_time = sum(r["response_time_ms"] for r in results) / len(results)
        
        return {
            "endpoint": endpoint,
            "total_requests": count,
            "successful_requests": successful_requests,
            "failed_requests": count - successful_requests,
            "success_rate": (successful_requests / count) * 100,
            "total_time_seconds": total_time,
            "requests_per_second": count / total_time,
            "avg_response_time_ms": avg_response_time
        }

async def run_simple_performance_tests():
    """Exécute tous les tests de performance simples"""
    
    print("🚀 Ryze Simple Performance Tests")
    print("="*50)
    
    async with SimplePerformanceTester() as tester:
        
        # 1. Test des endpoints de base
        print("\n📋 Test des endpoints de base...")
        basic_results = await tester.test_basic_endpoints()
        
        successful_endpoints = sum(1 for r in basic_results if r["success"] or r["status"] in [401, 422])
        total_endpoints = len(basic_results)
        
        print(f"\n📊 Résultats endpoints: {successful_endpoints}/{total_endpoints} accessibles")
        
        # 2. Test de charge simple
        print("\n🚀 Test de charge simple...")
        load_result = await tester.test_concurrent_requests("/health", 20)
        
        print(f"✅ {load_result['successful_requests']}/{load_result['total_requests']} requêtes réussies")
        print(f"✅ Taux de succès: {load_result['success_rate']:.1f}%")
        print(f"✅ Throughput: {load_result['requests_per_second']:.1f} req/s")
        print(f"✅ Temps de réponse moyen: {load_result['avg_response_time_ms']:.0f}ms")
        
        # 3. Analyse des résultats
        print("\n💡 Analyse:")
        
        failed_endpoints = [r for r in basic_results if not r["success"] and r["status"] not in [401, 422]]
        if failed_endpoints:
            print("⚠️ Endpoints en erreur:")
            for endpoint in failed_endpoints:
                print(f"   • {endpoint['method']} {endpoint['endpoint']}: {endpoint.get('error', endpoint['status'])}")
        else:
            print("✅ Tous les endpoints sont accessibles")
            
        if load_result['success_rate'] >= 95:
            print("✅ Performance de base acceptable")
        else:
            print("⚠️ Performance de base insuffisante")
            
        slow_endpoints = [r for r in basic_results if r.get("response_time_ms", 0) > 1000]
        if slow_endpoints:
            print("⚠️ Endpoints lents (>1s):")
            for endpoint in slow_endpoints:
                print(f"   • {endpoint['method']} {endpoint['endpoint']}: {endpoint['response_time_ms']:.0f}ms")
        
        # 4. Recommandations
        print("\n🎯 Recommandations:")
        if not failed_endpoints and load_result['success_rate'] >= 95:
            print("✅ Prêt pour les tests de charge complets")
            print("▶️ Exécuter: python performance_testing.py")
        else:
            print("⚠️ Corriger les problèmes avant les tests de charge")
            print("▶️ Vérifier que le serveur FastAPI est démarré")
            print("▶️ Vérifier la base de données et les migrations")

if __name__ == "__main__":
    try:
        asyncio.run(run_simple_performance_tests())
    except KeyboardInterrupt:
        print("\n🛑 Tests interrompus par l'utilisateur")
    except Exception as e:
        logger.error(f"Erreur lors des tests: {e}")
        sys.exit(1)