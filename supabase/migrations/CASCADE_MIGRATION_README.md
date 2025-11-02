# Migration CASCADE - Guide d'Application

## Vue d'ensemble

Ces migrations ajoutent des contraintes `ON DELETE CASCADE` pour assurer que toutes les données d'un utilisateur sont supprimées automatiquement lorsque son compte est supprimé.

## Fichiers de migration créés

1. **20250130_add_user_cascade_delete.sql**
   - Ajoute ON DELETE CASCADE pour toutes les relations utilisateur → tables
   - Concerne 17+ tables liées aux utilisateurs
   - Ajoute des index pour optimiser les performances

2. **20250130_add_table_relation_cascades.sql**
   - Ajoute ON DELETE CASCADE pour les relations entre tables
   - Exemples : workout_sessions → workout_exercises → exercise_sets
   - Utilise SET NULL pour préserver l'historique quand approprié

## Ordre d'application

**IMPORTANT** : Appliquer les migrations dans cet ordre :

```bash
1. 20250130_add_table_relation_cascades.sql  (relations entre tables d'abord)
2. 20250130_add_user_cascade_delete.sql      (relations utilisateur ensuite)
```

## Méthodes d'application

### Option 1 : Via l'interface Supabase (Recommandé)

1. Aller sur https://supabase.com/dashboard
2. Sélectionner votre projet : `mfskwlzgxjhhknlwpblq`
3. Aller dans **SQL Editor**
4. Copier le contenu de `20250130_add_table_relation_cascades.sql`
5. Exécuter la requête
6. Répéter avec `20250130_add_user_cascade_delete.sql`

### Option 2 : Via Supabase CLI

```bash
# Installer Supabase CLI si pas déjà fait
npm install -g supabase

# Se connecter
supabase login

# Lier le projet
supabase link --project-ref mfskwlzgxjhhknlwpblq

# Appliquer les migrations
supabase db push

# OU appliquer manuellement
psql "postgresql://postgres:[YOUR_PASSWORD]@db.mfskwlzgxjhhknlwpblq.supabase.co:5432/postgres" \
  -f supabase/migrations/20250130_add_table_relation_cascades.sql

psql "postgresql://postgres:[YOUR_PASSWORD]@db.mfskwlzgxjhhknlwpblq.supabase.co:5432/postgres" \
  -f supabase/migrations/20250130_add_user_cascade_delete.sql
```

### Option 3 : Via code Dart/Flutter (Non recommandé pour cette migration)

Cette option n'est pas recommandée car elle nécessite des privilèges élevés.

## Vérification post-migration

### 1. Vérifier les contraintes CASCADE sur auth.users

Exécuter dans SQL Editor :

```sql
SELECT
  conname AS constraint_name,
  conrelid::regclass AS table_name,
  CASE confdeltype
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET NULL'
    WHEN 'r' THEN 'RESTRICT'
    WHEN 'a' THEN 'NO ACTION'
  END AS on_delete_action
FROM pg_constraint
WHERE confrelid = 'auth.users'::regclass
  AND contype = 'f'
ORDER BY table_name;
```

**Résultat attendu** : Toutes les tables doivent avoir `CASCADE`

### 2. Vérifier toutes les relations CASCADE

```sql
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND rc.delete_rule IN ('CASCADE', 'SET NULL')
ORDER BY tc.table_name;
```

### 3. Test de suppression (PRUDENCE!)

**NE PAS FAIRE EN PRODUCTION SANS BACKUP**

```sql
-- Créer un utilisateur de test
INSERT INTO auth.users (id, email)
VALUES ('00000000-0000-0000-0000-000000000001', 'test@delete.com');

-- Ajouter des données de test
INSERT INTO food_entries (id, user_id, meal_type, quantity, unit, calories, proteins, carbs, fats, consumed_at)
VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000001', 'breakfast', 100, 'g', 200, 10, 20, 5, NOW());

-- Vérifier que les données existent
SELECT COUNT(*) FROM food_entries WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- Supprimer l'utilisateur
DELETE FROM auth.users WHERE id = '00000000-0000-0000-0000-000000000001';

-- Vérifier que les données ont été supprimées
SELECT COUNT(*) FROM food_entries WHERE user_id = '00000000-0000-0000-0000-000000000001';
-- Devrait retourner 0
```

## Impact et considérations

### ✅ Avantages

- **Intégrité des données** : Pas de données orphelines
- **Conformité RGPD** : Suppression complète des données utilisateur
- **Automatique** : Pas besoin de code applicatif pour nettoyer
- **Performance** : Index ajoutés pour optimiser les suppressions

### ⚠️ Points d'attention

1. **Performance de suppression**
   - La suppression d'un utilisateur avec beaucoup de données peut prendre du temps
   - Les cascades sont exécutées de manière synchrone
   - Considérer une suppression asynchrone pour les gros comptes

2. **Logs et historique**
   - Certaines tables utilisent `SET NULL` au lieu de `CASCADE` pour préserver l'historique
   - Exemple : `content_reports.reviewed_by` garde le rapport même si le reviewer est supprimé

3. **Backup recommandé**
   - Faire un backup de la base de données avant d'appliquer
   - Tester d'abord sur un environnement de staging

## Rollback (Annulation)

Si vous devez annuler ces migrations :

```sql
-- Supprimer toutes les contraintes ajoutées
-- ATTENTION : Ceci rétablit l'état SANS CASCADE

-- Liste des contraintes à supprimer (exemple)
ALTER TABLE food_entries DROP CONSTRAINT IF EXISTS fk_food_entries_user;
ALTER TABLE custom_foods DROP CONSTRAINT IF EXISTS fk_custom_foods_user;
-- ... etc pour toutes les tables

-- OU créer une migration de rollback complète
```

## Support et questions

- Documentation Supabase : https://supabase.com/docs
- Foreign Keys PostgreSQL : https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-FK
- Issues GitHub : https://github.com/anthropics/claude-code/issues

## Checklist finale

- [ ] Backup de la base de données effectué
- [ ] Migrations testées en environnement de staging
- [ ] Migrations appliquées dans l'ordre correct
- [ ] Requêtes de vérification exécutées avec succès
- [ ] Test de suppression d'un utilisateur de test réalisé
- [ ] Documentation mise à jour dans CLAUDE.md
- [ ] Équipe informée des changements

## Prochaines étapes recommandées

1. **Créer une fonction de suppression douce (soft delete)**
   ```sql
   ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
   ```

2. **Ajouter des triggers de logging**
   ```sql
   -- Logger les suppressions d'utilisateurs pour audit
   CREATE TABLE user_deletion_log (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID NOT NULL,
     deleted_at TIMESTAMPTZ DEFAULT NOW(),
     reason TEXT
   );
   ```

3. **Implémenter une purge automatique**
   - Utiliser pg_cron pour nettoyer les anciennes données
   - Anonymiser au lieu de supprimer pour certaines données
