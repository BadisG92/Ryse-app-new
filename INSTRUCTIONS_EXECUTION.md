# 🚀 Instructions pour Exécuter la Mise à Jour

## ⚠️ Problème Technique
L'outil MCP Supabase a une erreur technique ("crypto is not defined") qui empêche l'exécution directe depuis le code. Vous devez donc exécuter le SQL manuellement.

## ✅ Solution Simple (5 minutes)

### Étape 1: Ouvrir Supabase Dashboard
1. Allez sur: **https://app.supabase.com**
2. Connectez-vous à votre compte
3. Sélectionnez votre projet Ryze App

### Étape 2: Ouvrir l'Éditeur SQL
1. Dans le menu latéral gauche, cliquez sur **SQL Editor**
2. Cliquez sur **New Query** (nouvelle requête)

### Étape 3: Copier le SQL
1. Ouvrez le fichier: **`single_update.sql`** (dans ce dossier)
2. **Sélectionnez TOUT le contenu** (Ctrl+A)
3. **Copiez** (Ctrl+C)

### Étape 4: Coller et Exécuter
1. Retournez dans Supabase SQL Editor
2. **Collez** le SQL (Ctrl+V)
3. Cliquez sur **Run** (ou appuyez sur Ctrl+Enter)

### Étape 5: Vérifier le Résultat
Vous devriez voir:
```
Success. 100 rows affected.
```
ou
```
UPDATE 100
```

## 🔍 Vérification Après Exécution

Exécutez cette requête pour vérifier:

```sql
-- Vérifier quelques recettes mises à jour
SELECT
  id,
  name_en,
  LEFT(steps_en, 80) as steps_preview,
  LENGTH(steps_en) as steps_length
FROM recipes_database
WHERE id IN (1, 10, 50, 100)
ORDER BY id;
```

Vous devriez voir les étapes en anglais pour chaque recette.

## 📊 Statistiques Attendues

Après l'exécution:
- ✅ 100 recettes mises à jour
- ✅ Toutes avec des étapes en anglais
- ✅ IDs de 1 à 100

## ❓ En Cas de Problème

### "Permission denied"
→ Vérifiez que vous êtes connecté avec un compte admin

### "Table does not exist"
→ Vérifiez que vous êtes sur le bon projet Supabase

### Erreur de syntaxe
→ Assurez-vous d'avoir copié TOUT le contenu du fichier SQL

## 📁 Fichiers Disponibles

- **`single_update.sql`** ← Utilisez celui-ci (le meilleur)
- `batch_update_recipes.sql` (alternative)
- `execute_update.sql` (version propre sans commentaires)

## ⏱️ Temps Estimé
- Copier-coller: 30 secondes
- Exécution: 1-2 secondes
- Vérification: 1 minute

**Total: ~2 minutes maximum**

## ✨ C'est Tout!

Une fois exécuté, vos 100 recettes auront leurs instructions en anglais dans la colonne `steps_en`.
