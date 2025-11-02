# Guide Visuel - Suppressions en CASCADE

## Vue d'ensemble

Ce document montre visuellement ce qui se passe quand un utilisateur est supprimé.

## Scénario : Suppression d'un utilisateur

```
DELETE FROM auth.users WHERE id = 'user-123';
```

### Effet CASCADE (suppression automatique)

```
auth.users (user-123)
│
├── ✅ food_entries (toutes ses entrées alimentaires)
│   └── → Supprimé automatiquement
│
├── ✅ custom_foods (ses aliments personnalisés)
│   └── → Supprimé automatiquement
│
├── ✅ workout_sessions (toutes ses séances)
│   ├── → Supprimé automatiquement
│   └── → CASCADE vers workout_exercises
│       └── → CASCADE vers exercise_sets
│
├── ✅ cardio_sessions (toutes ses séances cardio)
│   ├── → Supprimé automatiquement
│   └── → CASCADE vers location_points
│
├── ✅ hiit_sessions (ses séances HIIT)
│   └── → Supprimé automatiquement
│
├── ✅ recipes (ses recettes)
│   ├── → Supprimé automatiquement
│   └── → CASCADE vers recipe_ingredients
│
├── ✅ exercises (ses exercices personnalisés)
│   └── → Supprimé automatiquement
│
├── ✅ barcode_foods (ses produits scannés)
│   └── → Supprimé automatiquement
│
├── ✅ gps_tracking_sessions (ses données GPS)
│   ├── → Supprimé automatiquement
│   └── → CASCADE vers gps_tracking_points
│
├── ✅ community_ratings (ses évaluations)
│   └── → Supprimé automatiquement
│
├── ✅ user_collections (ses collections)
│   └── → Supprimé automatiquement
│
├── ✅ workout_templates (ses modèles d'entraînement)
│   ├── → Supprimé automatiquement
│   └── → CASCADE vers workout_template_exercises
│
├── ✅ workout_programs (ses programmes)
│   └── → Supprimé automatiquement
│
├── ✅ hiit_workouts (ses entraînements HIIT)
│   └── → Supprimé automatiquement
│
├── ✅ cardio_activities (ses activités cardio)
│   └── → Supprimé automatiquement
│
└── ✅ external_api_logs (ses logs API)
    └── → Supprimé automatiquement
```

## Effet SET NULL (données préservées)

Certaines données sont **préservées** mais la référence utilisateur est mise à NULL :

```
content_reports (rapports de la communauté)
│
├── ⚠️  reported_by = 'user-123'
│   └── → SET NULL (rapport conservé, reporteur anonymisé)
│
└── ⚠️  reviewed_by = 'user-123'
    └── → SET NULL (rapport conservé, reviewer anonymisé)
```

```
food_entries (entrées alimentaires)
│
├── ⚠️  food_id (référence vers foods)
│   └── → SET NULL si l'aliment est supprimé
│   └── → L'entrée nutrition est conservée avec les valeurs
│
├── ⚠️  custom_food_id (référence vers custom_foods)
│   └── → SET NULL si l'aliment custom est supprimé
│
└── ⚠️  recipe_id (référence vers recipes)
    └── → SET NULL si la recette est supprimée
```

## Exemple Concret

### Utilisateur "Marie" (ID: abc-123)

**Données avant suppression:**
- 450 entrées alimentaires
- 25 aliments personnalisés
- 15 séances d'entraînement
  - Contenant 120 exercices
  - Contenant 450 séries
- 30 séances de cardio
  - Contenant 5,000 points GPS
- 5 recettes personnalisées
  - Contenant 40 ingrédients
- 10 évaluations communautaires

**Après `DELETE FROM auth.users WHERE id = 'abc-123'`:**

```
Suppressions CASCADE automatiques:
✅ 450 food_entries supprimées
✅ 25 custom_foods supprimés
✅ 15 workout_sessions supprimées
  ✅ → 120 workout_exercises supprimés
    ✅ → 450 exercise_sets supprimés
✅ 30 cardio_sessions supprimées
  ✅ → 5,000 location_points supprimés
✅ 5 recipes supprimées
  ✅ → 40 recipe_ingredients supprimés
✅ 10 community_ratings supprimées

Total: ~6,150 lignes supprimées automatiquement
Temps estimé: < 1 seconde
```

## Impact Performance

### Petit utilisateur (< 100 entrées)
```
Temps de suppression: < 100ms
Impact: ✅ Négligeable
```

### Utilisateur moyen (100-1000 entrées)
```
Temps de suppression: 100-500ms
Impact: ✅ Acceptable
```

### Utilisateur intensif (> 1000 entrées)
```
Temps de suppression: 500ms-2s
Impact: ⚠️  Acceptable, mais considérer suppression async
```

### Utilisateur extrême (> 10,000 entrées)
```
Temps de suppression: 2s-10s
Impact: ⚠️  Considérer une suppression asynchrone
Recommandation: Implémenter soft delete + purge planifiée
```

## Schéma de Dépendances

```
Niveau 1: auth.users
    │
    ├─ Niveau 2: Tables utilisateur direct
    │   ├─ food_entries
    │   ├─ custom_foods
    │   ├─ workout_sessions ────┐
    │   ├─ cardio_sessions ─────┤
    │   ├─ recipes ─────────────┤
    │   ├─ gps_tracking_sessions┤
    │   └─ ...                  │
    │                            │
    └─ Niveau 3: Tables enfants │
        ├─ workout_exercises ◄──┘
        ├─ location_points
        ├─ recipe_ingredients
        └─ ...
            │
            └─ Niveau 4: Tables petits-enfants
                └─ exercise_sets
```

## Checklist de Vérification

Après application de la migration, vérifier :

- [ ] Toutes les tables avec `user_id` ont CASCADE
- [ ] Les tables enfants ont CASCADE vers leurs parents
- [ ] Les relations historiques utilisent SET NULL
- [ ] Tous les index sont créés
- [ ] Le script de vérification passe avec succès
- [ ] Test de suppression sur utilisateur de test OK

## Commandes de Test

### 1. Créer un utilisateur de test
```sql
INSERT INTO auth.users (id, email, email_confirmed_at)
VALUES (
  '00000000-0000-0000-0000-999999999999',
  'test-cascade@example.com',
  NOW()
);
```

### 2. Ajouter des données de test
```sql
-- Entrée alimentaire
INSERT INTO food_entries (
  id, user_id, meal_type, quantity, unit,
  calories, proteins, carbs, fats, consumed_at
) VALUES (
  gen_random_uuid(),
  '00000000-0000-0000-0000-999999999999',
  'breakfast', 100, 'g',
  200, 10, 20, 5, NOW()
);

-- Séance d'entraînement
INSERT INTO workout_sessions (
  id, user_id, name, start_time, is_completed
) VALUES (
  '11111111-1111-1111-1111-111111111111',
  '00000000-0000-0000-0000-999999999999',
  'Test Workout', NOW(), false
);
```

### 3. Vérifier les données
```sql
SELECT
  (SELECT COUNT(*) FROM food_entries WHERE user_id = '00000000-0000-0000-0000-999999999999') as food_entries,
  (SELECT COUNT(*) FROM workout_sessions WHERE user_id = '00000000-0000-0000-0000-999999999999') as workouts;
```

### 4. Supprimer l'utilisateur
```sql
DELETE FROM auth.users WHERE id = '00000000-0000-0000-0000-999999999999';
```

### 5. Vérifier la CASCADE
```sql
SELECT
  (SELECT COUNT(*) FROM food_entries WHERE user_id = '00000000-0000-0000-0000-999999999999') as food_entries,
  (SELECT COUNT(*) FROM workout_sessions WHERE user_id = '00000000-0000-0000-0000-999999999999') as workouts;

-- Devrait retourner 0 pour les deux
```

## Rollback d'Urgence

Si quelque chose se passe mal :

```sql
-- 1. Arrêter immédiatement toute suppression
BEGIN; -- Commencer une transaction

-- 2. Vérifier les données
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM food_entries;

-- 3. Si tout va bien
COMMIT;

-- 4. Si problème
ROLLBACK; -- Annule tout
```

## Support RGPD

Ces CASCADE assurent la conformité RGPD :

✅ **Article 17 - Droit à l'effacement**
- Toutes les données personnelles sont supprimées
- Suppression complète en une seule opération
- Aucune donnée orpheline

✅ **Article 5 - Limitation de la conservation**
- Les données ne persistent pas après suppression du compte
- Nettoyage automatique garanti

⚠️ **Logs conservés (si applicable)**
- `content_reports.reviewed_by` → SET NULL (anonymisé)
- Considérer l'ajout d'une purge planifiée pour les anciens logs

## Prochaines Étapes Recommandées

1. **Implémenter Soft Delete**
   ```sql
   ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
   -- Permet de récupérer un compte supprimé par erreur
   ```

2. **Logging des Suppressions**
   ```sql
   CREATE TABLE user_deletion_audit (
     id UUID PRIMARY KEY,
     user_id UUID,
     deleted_at TIMESTAMPTZ,
     deletion_reason TEXT,
     row_counts JSONB
   );
   ```

3. **Anonymisation Alternative**
   - Au lieu de supprimer, anonymiser les données
   - Garder les statistiques agrégées
   - Supprimer uniquement les données identifiables

4. **Export des Données (RGPD Article 20)**
   ```dart
   // Fonction pour exporter toutes les données utilisateur
   Future<Map<String, dynamic>> exportUserData(String userId);
   ```
