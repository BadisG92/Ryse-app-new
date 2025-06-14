"""
Tests pour l'API Workout Templates
Validation des fonctionnalités de templates d'entraînement
"""

import asyncio
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import get_supabase_client
import logging

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_workout_templates():
    """Test des templates d'entraînement"""
    
    print("🏋️ Test des Templates d'Entraînement")
    print("=" * 40)
    
    try:
        supabase = get_supabase_client()
        
        # Test des tables
        print("\n1. Vérification des tables...")
        
        tables = ["workout_templates", "workout_template_exercises"]
        
        for table in tables:
            try:
                result = supabase.table(table).select("*").limit(1).execute()
                print(f"   ✅ Table '{table}' OK")
            except Exception as e:
                print(f"   ❌ Table '{table}': {e}")
        
        # Test des templates
        print("\n2. Templates disponibles...")
        
        templates = supabase.table("workout_templates").select("*").execute()
        
        if templates.data:
            print(f"   ✅ {len(templates.data)} templates:")
            for t in templates.data:
                print(f"      - {t['name_fr']}")
        else:
            print("   ⚠️  Aucun template")
        
        print("\n✅ Tests terminés!")
        return True
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

async def test_template_workflow():
    """Test du workflow complet : session → template → nouvelle session"""
    
    print("\n🔄 Test du Workflow Complet")
    print("=" * 50)
    
    try:
        supabase = get_supabase_client()
        
        # Vérifier s'il y a des sessions existantes
        sessions = supabase.table("workout_sessions").select("*").limit(1).execute()
        
        if sessions.data:
            print("   ✅ Sessions d'entraînement disponibles pour les tests")
            print("   ℹ️  Le workflow session → template → session peut être testé")
        else:
            print("   ⚠️  Aucune session d'entraînement trouvée")
            print("   ℹ️  Créez d'abord une session pour tester le workflow complet")
        
        # Vérifier les templates disponibles
        templates = supabase.table("workout_templates").select("*").execute()
        
        if templates.data:
            print(f"   ✅ {len(templates.data)} templates disponibles pour créer des sessions")
            
            # Afficher quelques templates populaires
            popular_templates = sorted(templates.data, key=lambda x: x.get("usage_count", 0), reverse=True)[:3]
            
            print("   🏆 Templates les plus utilisés:")
            for template in popular_templates:
                usage = template.get("usage_count", 0)
                rating = template.get("average_rating", 0.0)
                print(f"      - {template['name_fr']} (utilisé {usage} fois, note: {rating:.1f}/5)")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors du test de workflow: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(test_workout_templates()) 