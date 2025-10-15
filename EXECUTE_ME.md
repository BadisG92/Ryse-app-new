# 🚀 EXÉCUTION RAPIDE - Muscle Groups Translation

## ⚡ En 3 Étapes (2 minutes)

### Étape 1: Ouvrir Supabase
👉 https://app.supabase.com
- Connectez-vous
- Sélectionnez votre projet Ryze App
- Cliquez sur **SQL Editor** (dans le menu gauche)

### Étape 2: Copier le SQL
👉 Ouvrez le fichier: **`fix_muscle_groups.sql`**
- Sélectionnez TOUT (Ctrl+A)
- Copiez (Ctrl+C)

### Étape 3: Exécuter
👉 Dans Supabase SQL Editor:
- Collez le SQL (Ctrl+V)
- Cliquez **Run** ▶️ (ou Ctrl+Enter)

## ✅ C'est Fait!

Vous devriez voir:
```
UPDATE X
```
où X = nombre d'exercices mis à jour

Puis un tableau avec les traductions:
```
muscle_group_en | muscle_group_fr | exercise_count
----------------|-----------------|---------------
Chest           | Pectoraux       | 42
Back            | Dos             | 38
...
```

## 🔍 Vérification Rapide (Optionnel)

Exécutez cette requête pour confirmer:

```sql
SELECT COUNT(*) FROM exercises
WHERE muscle_group_fr = 'Personnalisé'
  AND muscle_group_en != 'Custom';
```

**Résultat attendu: 0** (aucun problème restant)

---

## 📁 Fichier à Utiliser

**`fix_muscle_groups.sql`** ⭐

---

**C'est tout!** Les traductions seront corrigées automatiquement. 🎉
