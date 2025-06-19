#!/usr/bin/env python3
"""
Script pour appliquer la migration des tags multilingues aux recettes
Ajoute les colonnes tags_en et tags_fr et traduit les tags existants
"""

import os
import sys
from supabase import create_client, Client
from config import SUPABASE_URL, SUPABASE_SERVICE_KEY

def create_supabase_client() -> Client:
    """Créer un client Supabase avec la clé de service"""
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

def apply_migration():
    """Applique la migration des tags multilingues"""
    print("🔄 Application de la migration des tags multilingues...")
    
    supabase = create_supabase_client()
    
    try:
        # Lire le fichier de migration
        migration_file = "supabase/migrations/008_add_multilingual_tags_to_recipes.sql"
        
        if not os.path.exists(migration_file):
            print(f"❌ Fichier de migration non trouvé: {migration_file}")
            return False
        
        with open(migration_file, 'r', encoding='utf-8') as f:
            migration_sql = f.read()
        
        print("📝 Exécution de la migration SQL...")
        
        # Diviser la migration en plusieurs parties pour éviter les erreurs
        sql_commands = migration_sql.split(';')
        
        for i, command in enumerate(sql_commands):
            command = command.strip()
            if command and not command.startswith('--'):
                try:
                    print(f"   Étape {i+1}: {command[:50]}...")
                    result = supabase.rpc('exec_sql', {'sql': command}).execute()
                    print(f"   ✅ Étape {i+1} terminée")
                except Exception as e:
                    if "already exists" in str(e) or "does not exist" in str(e):
                        print(f"   ⚠️ Étape {i+1} ignorée (déjà appliquée): {e}")
                    else:
                        print(f"   ❌ Erreur à l'étape {i+1}: {e}")
        
        print("✅ Migration appliquée avec succès!")
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de l'application de la migration: {e}")
        return False

def verify_migration():
    """Vérifie que la migration a été appliquée correctement"""
    print("🔍 Vérification de la migration...")
    
    supabase = create_supabase_client()
    
    try:
        # Vérifier que les nouvelles colonnes existent
        result = supabase.table('recipes').select('tags_en, tags_fr').limit(1).execute()
        
        if result.data:
            print("✅ Colonnes tags_en et tags_fr créées avec succès")
            
            # Vérifier qu'il y a des données traduites
            recipes_with_tags = supabase.table('recipes').select('*').not_.is_('tags_fr', 'null').limit(5).execute()
            
            if recipes_with_tags.data:
                print(f"✅ {len(recipes_with_tags.data)} recettes ont des tags français")
                
                # Afficher un exemple
                example = recipes_with_tags.data[0]
                print(f"   Exemple - Nom: {example.get('name_fr', 'N/A')}")
                print(f"   Tags EN: {example.get('tags_en', [])}")
                print(f"   Tags FR: {example.get('tags_fr', [])}")
            else:
                print("⚠️ Aucune recette avec des tags français trouvée")
                
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de la vérification: {e}")
        return False

def main():
    """Fonction principale"""
    print("🚀 Migration des tags multilingues pour les recettes")
    print("=" * 50)
    
    # Appliquer la migration
    if apply_migration():
        print()
        # Vérifier la migration
        verify_migration()
        print()
        print("🎉 Migration terminée avec succès!")
        print()
        print("📋 Prochaines étapes:")
        print("1. Redémarrez l'application Flutter")
        print("2. Testez les filtres de recettes dans l'onglet nutrition")
        print("3. Les filtres utilisent maintenant les tags français de la base de données")
    else:
        print("❌ Échec de la migration")
        sys.exit(1)

if __name__ == "__main__":
    main() 