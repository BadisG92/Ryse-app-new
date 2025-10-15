# 🏋️ Fix Muscle Group Translations - Instructions

## 📋 Problème Identifié

Dans la table `exercises`, certaines lignes ont `muscle_group_fr = 'Personnalisé'` alors que `muscle_group_en` contient le vrai nom du groupe musculaire en anglais (ex: "Chest", "Back", etc.).

## 🎯 Solution

Mettre à jour `muscle_group_fr` avec la traduction correcte basée sur `muscle_group_en`.

## 📁 Fichiers Générés

1. **`fix_muscle_groups.sql`** ⭐ - Fichier principal (à exécuter)
2. **`check_current_muscle_groups.sql`** - Requêtes de vérification avant/après
3. **`fix_muscle_groups_individual.sql`** - Alternative (si le CASE ne marche pas)

## 🚀 Étapes d'Exécution

### Étape 1: Vérifier l'État Actuel (Optionnel)

Avant de faire la mise à jour, vous pouvez vérifier l'état actuel:

1. Ouvrez **Supabase SQL Editor**
2. Copiez le contenu de `check_current_muscle_groups.sql`
3. Exécutez pour voir quels groupes musculaires ont besoin de traduction

### Étape 2: Exécuter la Correction

1. Ouvrez **Supabase SQL Editor** (https://app.supabase.com)
2. Ouvrez le fichier **`fix_muscle_groups.sql`**
3. **Copiez TOUT** le contenu (Ctrl+A, Ctrl+C)
4. **Collez** dans l'éditeur SQL (Ctrl+V)
5. Cliquez **Run** (ou Ctrl+Enter)

### Étape 3: Vérifier le Résultat

Le message devrait afficher:
```
UPDATE X
```
où X = nombre d'exercices mis à jour

Ensuite, la requête de vérification s'exécutera automatiquement et affichera:
```
muscle_group_en | muscle_group_fr | exercise_count
----------------|-----------------|---------------
Abs             | Abdominaux      | X
Back            | Dos             | X
Chest           | Pectoraux       | X
...
```

## 📊 Traductions Appliquées

Voici les 33 traductions qui seront appliquées:

| Anglais (EN)           | Français (FR)                    |
|------------------------|----------------------------------|
| Abs                    | Abdominaux                       |
| Back                   | Dos                              |
| Biceps                 | Biceps                           |
| Calves                 | Mollets                          |
| Cardio                 | Cardio                           |
| Chest                  | Pectoraux                        |
| Core                   | Tronc                            |
| Custom                 | Personnalisé                     |
| Forearms               | Avant-bras                       |
| Front Shoulders        | Avant des épaules                |
| Full Body              | Corps entier                     |
| Glutes                 | Fessiers                         |
| Hamstrings             | Ischio-jambiers                  |
| Hip Flexors            | Fléchisseurs de la hanche        |
| Inner Thighs           | Intérieur des cuisses            |
| Lats                   | Dorsaux                          |
| Legs                   | Jambes                           |
| Lower Abs              | Abdominaux inférieurs            |
| Lower Back             | Bas du dos                       |
| Lower Chest            | Bas des pectoraux                |
| Neck                   | Cou                              |
| Obliques               | Obliques                         |
| Other                  | Autre                            |
| Outer Thighs           | Extérieur des cuisses            |
| Quads                  | Quadriceps                       |
| Rear Shoulders         | Arrière des épaules              |
| Shoulders              | Épaules                          |
| Side Shoulders         | Épaules latérales                |
| Traps                  | Trapèzes                         |
| Triceps                | Triceps                          |
| Upper Abs              | Abdominaux supérieurs            |
| Upper Back             | Haut du dos                      |
| Upper Chest            | Haut des pectoraux               |

## 🔍 Requêtes de Vérification

### Après la mise à jour, vérifier les résultats:

```sql
-- 1. Vérifier qu'il n'y a plus de 'Personnalisé' inapproprié
SELECT COUNT(*) as still_wrong
FROM exercises
WHERE muscle_group_fr = 'Personnalisé'
  AND muscle_group_en != 'Custom'
  AND muscle_group_en IS NOT NULL;
```
**Résultat attendu: 0**

```sql
-- 2. Compter les exercices par groupe musculaire
SELECT
  muscle_group_en,
  muscle_group_fr,
  COUNT(*) as count
FROM exercises
WHERE muscle_group_en IS NOT NULL
GROUP BY muscle_group_en, muscle_group_fr
ORDER BY count DESC;
```

```sql
-- 3. Exemples d'exercices mis à jour
SELECT
  name_en,
  name_fr,
  muscle_group_en,
  muscle_group_fr
FROM exercises
WHERE muscle_group_en IN ('Chest', 'Back', 'Shoulders', 'Legs', 'Abs')
LIMIT 20;
```

## 🛡️ Sécurité

- ✅ La requête utilise `CASE` avec `ELSE muscle_group_fr`
  - Cela signifie: si `muscle_group_en` n'est pas dans la liste, on garde `muscle_group_fr` tel quel
- ✅ Seuls les exercices avec `muscle_group_en IS NOT NULL` sont affectés
- ✅ Aucun risque de perdre des données

## 📝 Exemple de Ce Qui Va Changer

### Avant:
```
id | name_en              | muscle_group_en | muscle_group_fr
---|---------------------|-----------------|----------------
1  | Bench Press         | Chest           | Personnalisé
2  | Pull-ups            | Back            | Personnalisé
3  | Squats              | Legs            | Personnalisé
```

### Après:
```
id | name_en              | muscle_group_en | muscle_group_fr
---|---------------------|-----------------|----------------
1  | Bench Press         | Chest           | Pectoraux
2  | Pull-ups            | Back            | Dos
3  | Squats              | Legs            | Jambes
```

## ❓ En Cas de Problème

### "Permission denied"
→ Vérifiez que vous avez les droits UPDATE sur la table exercises

### Certains groupes musculaires ne sont pas traduits
→ Vérifiez la requête de vérification pour voir quels groupes n'ont pas de mapping
→ Ajoutez les traductions manquantes dans le script Python et régénérez

### Rollback nécessaire
Si vous devez annuler les changements:

```sql
-- ATTENTION: Ceci remet 'Personnalisé' partout
-- À n'utiliser que si vraiment nécessaire
UPDATE exercises
SET muscle_group_fr = 'Personnalisé'
WHERE muscle_group_en IS NOT NULL;
```

## ⏱️ Temps Estimé

- Copier-coller: 30 secondes
- Exécution: 1-2 secondes
- Vérification: 1 minute

**Total: ~2 minutes**

## ✅ Checklist

- [ ] Ouvrir Supabase SQL Editor
- [ ] Copier le contenu de `fix_muscle_groups.sql`
- [ ] Coller dans l'éditeur
- [ ] Cliquer Run
- [ ] Vérifier le message de succès
- [ ] Exécuter les requêtes de vérification
- [ ] Confirmer que les traductions sont correctes

---

*Prêt à corriger les traductions des groupes musculaires !* 🏋️
