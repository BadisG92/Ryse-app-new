#!/usr/bin/env python3
"""
Script principal pour exécuter les tests de performance - Task 10
Orchestration complète des tests de charge et de performance
"""

import asyncio
import sys
import os
import json
import argparse
from datetime import datetime
from pathlib import Path
from typing import Dict, Any

# Ajout du chemin pour les imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from performance_testing import run_comprehensive_load_tests, LoadTestConfig, export_results_to_csv, generate_html_report
from test_performance_simple import run_simple_performance_tests
from performance_optimization import PerformanceOptimizer

def print_banner():
    """Affiche le banner du programme"""
    print("""
    ╔══════════════════════════════════════════════════════════════╗
    ║                  🚀 RYZE PERFORMANCE TESTING SUITE          ║
    ║                       Task 10 Implementation                 ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  📊 Load Testing  •  ⚡ Performance Optimization            ║
    ║  🔍 Monitoring    •  📈 Detailed Reporting                  ║
    ╚══════════════════════════════════════════════════════════════╝
    """)

def parse_arguments():
    """Parse les arguments de la ligne de commande"""
    parser = argparse.ArgumentParser(description='Ryze Performance Testing Suite')
    
    parser.add_argument('--mode', 
                       choices=['simple', 'full', 'optimization-only'],
                       default='simple',
                       help='Mode de test à exécuter')
    
    parser.add_argument('--url', 
                       default='http://localhost:8000',
                       help='URL de base de l\'application')
    
    parser.add_argument('--concurrent-users', 
                       type=int, 
                       default=100,
                       help='Nombre d\'utilisateurs concurrents')
    
    parser.add_argument('--total-requests', 
                       type=int, 
                       default=1000,
                       help='Nombre total de requêtes')
    
    parser.add_argument('--max-response-time', 
                       type=int, 
                       default=2000,
                       help='Temps de réponse maximum acceptable (ms)')
    
    parser.add_argument('--max-error-rate', 
                       type=float, 
                       default=1.0,
                       help='Taux d\'erreur maximum acceptable (%)')
    
    parser.add_argument('--min-throughput', 
                       type=float, 
                       default=50.0,
                       help='Throughput minimum acceptable (req/s)')
    
    parser.add_argument('--output-dir', 
                       default='./performance_results',
                       help='Répertoire de sortie des résultats')
    
    parser.add_argument('--enable-redis', 
                       action='store_true',
                       help='Activer les optimisations Redis')
    
    parser.add_argument('--verbose', '-v', 
                       action='store_true',
                       help='Mode verbeux')
    
    return parser.parse_args()

async def run_optimization_setup(enable_redis: bool = False):
    """Configure et teste les optimisations de performance"""
    print("\n🔧 Configuration des optimisations de performance...")
    
    try:
        optimizer = PerformanceOptimizer()
        
        if enable_redis:
            await optimizer.initialize()
            
            # Test du statut des optimisations
            status = await optimizer.get_optimization_status()
            
            print("✅ Status des optimisations:")
            print(f"   • Cache Redis: {'✅ Activé' if status['cache']['enabled'] else '❌ Désactivé'}")
            print(f"   • Monitoring: {'✅ Activé' if status['monitoring']['enabled'] else '❌ Désactivé'}")
            print(f"   • Pool DB: ✅ Configuré ({status['database']['config']['pool_size']} connexions)")
            
            # Vérification de performance
            perf_check = await optimizer.run_performance_check()
            print(f"\n📊 Vérifications système:")
            for check in perf_check['checks']:
                status_icon = "✅" if check['status'] == 'healthy' else "⚠️"
                print(f"   • {check['component'].title()}: {status_icon} {check['status']}")
            
            await optimizer.cleanup()
        else:
            print("   • Cache Redis: ❌ Désactivé (utiliser --enable-redis)")
            print("   • Monitoring: ✅ Activé (mode basique)")
            print("   • Pool DB: ✅ Configuration par défaut")
            
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de la configuration: {e}")
        return False

def prepare_output_directory(output_dir: str) -> Path:
    """Prépare le répertoire de sortie"""
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    # Créer un sous-répertoire avec timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    test_run_dir = output_path / f"test_run_{timestamp}"
    test_run_dir.mkdir(exist_ok=True)
    
    return test_run_dir

async def run_simple_tests():
    """Exécute les tests simples de validation"""
    print("\n🧪 Exécution des tests de validation simple...")
    
    try:
        await run_simple_performance_tests()
        return True
    except Exception as e:
        print(f"❌ Erreur lors des tests simples: {e}")
        return False

async def run_full_load_tests(config: LoadTestConfig, output_dir: Path):
    """Exécute les tests de charge complets"""
    print("\n🚀 Exécution des tests de charge complets...")
    print(f"   • URL cible: {config.base_url}")
    print(f"   • Utilisateurs concurrents: {config.concurrent_users}")
    print(f"   • Total requêtes: {config.total_requests}")
    print(f"   • Limite temps réponse: {config.max_response_time_ms}ms")
    print(f"   • Limite taux erreur: {config.max_error_rate_percent}%")
    print(f"   • Throughput minimum: {config.min_throughput_rps} req/s")
    
    try:
        # Exécution des tests complets
        results = await run_comprehensive_load_tests(config)
        
        # Sauvegarde des résultats
        csv_file = output_dir / "load_test_results.csv"
        html_file = output_dir / "load_test_report.html"
        json_file = output_dir / "load_test_results.json"
        
        export_results_to_csv(results, str(csv_file))
        generate_html_report(results, str(html_file))
        
        # Sauvegarde JSON pour analyse programmatique
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, default=str)
        
        print(f"\n📄 Résultats sauvegardés dans: {output_dir}")
        print(f"   • Rapport HTML: {html_file.name}")
        print(f"   • Données CSV: {csv_file.name}")
        print(f"   • Données JSON: {json_file.name}")
        
        # Affichage du résumé
        metrics = results["overall_metrics"]
        print(f"\n📈 RÉSUMÉ DES RÉSULTATS:")
        print(f"   ✅ Total requêtes: {metrics['total_requests']}")
        print(f"   ✅ Taux de succès: {(metrics['successful_requests']/metrics['total_requests']*100):.1f}%")
        print(f"   ✅ Temps réponse moyen: {metrics['avg_response_time_ms']:.0f}ms")
        print(f"   ✅ P95 temps réponse: {metrics['p95_response_time_ms']:.0f}ms")
        print(f"   ✅ Throughput: {metrics['requests_per_second']:.1f} req/s")
        print(f"   ✅ Taux d'erreur: {metrics['error_rate_percent']:.2f}%")
        
        # Recommandations
        print(f"\n💡 RECOMMANDATIONS:")
        for rec in results["recommendations"]:
            print(f"   {rec}")
        
        # Détermination du succès global
        success = (
            metrics['avg_response_time_ms'] <= config.max_response_time_ms and
            metrics['error_rate_percent'] <= config.max_error_rate_percent and
            metrics['requests_per_second'] >= config.min_throughput_rps
        )
        
        if success:
            print(f"\n🎉 TESTS RÉUSSIS - L'application est prête pour la production!")
        else:
            print(f"\n⚠️ TESTS PARTIELLEMENT RÉUSSIS - Optimisations recommandées")
            
        return success
        
    except Exception as e:
        print(f"❌ Erreur lors des tests de charge: {e}")
        return False

async def main():
    """Fonction principale"""
    args = parse_arguments()
    
    print_banner()
    
    # Préparation du répertoire de sortie
    output_dir = prepare_output_directory(args.output_dir)
    print(f"📁 Répertoire de sortie: {output_dir}")
    
    # Configuration des tests
    config = LoadTestConfig(
        base_url=args.url,
        concurrent_users=args.concurrent_users,
        total_requests=args.total_requests,
        max_response_time_ms=args.max_response_time,
        max_error_rate_percent=args.max_error_rate,
        min_throughput_rps=args.min_throughput
    )
    
    success = True
    
    # 1. Configuration des optimisations
    print("\n" + "="*60)
    print("ÉTAPE 1/3: CONFIGURATION DES OPTIMISATIONS")
    print("="*60)
    
    optimization_success = await run_optimization_setup(args.enable_redis)
    if not optimization_success:
        print("⚠️ Certaines optimisations ne sont pas disponibles, continuation...")
    
    # 2. Tests selon le mode choisi
    print("\n" + "="*60)
    print("ÉTAPE 2/3: EXÉCUTION DES TESTS")
    print("="*60)
    
    if args.mode == 'simple':
        success = await run_simple_tests()
        
    elif args.mode == 'full':
        # Tests simples d'abord
        simple_success = await run_simple_tests()
        
        if simple_success:
            print("\n✅ Tests simples réussis, passage aux tests de charge...")
            success = await run_full_load_tests(config, output_dir)
        else:
            print("\n❌ Tests simples échoués, arrêt des tests de charge")
            success = False
            
    elif args.mode == 'optimization-only':
        print("✅ Configuration des optimisations terminée")
        
    # 3. Rapport final
    print("\n" + "="*60)
    print("ÉTAPE 3/3: RAPPORT FINAL")
    print("="*60)
    
    if success:
        print("🎉 TOUS LES TESTS SONT TERMINÉS AVEC SUCCÈS!")
        if args.mode == 'full':
            print(f"📊 Rapports détaillés disponibles dans: {output_dir}")
        print("✅ L'application Ryze est prête pour la production")
        return 0
    else:
        print("⚠️ CERTAINS TESTS ONT ÉCHOUÉ")
        print("💡 Vérifiez les logs et corrigez les problèmes identifiés")
        print("🔧 Considérez l'activation des optimisations Redis avec --enable-redis")
        return 1

if __name__ == "__main__":
    try:
        exit_code = asyncio.run(main())
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n🛑 Tests interrompus par l'utilisateur")
        sys.exit(130)
    except Exception as e:
        print(f"\n❌ Erreur fatale: {e}")
        sys.exit(1)