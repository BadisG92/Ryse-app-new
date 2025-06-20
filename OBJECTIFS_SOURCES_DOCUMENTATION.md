# 🎯 Documentation des Sources d'Objectifs - Dashboard

## 📊 Vue d'ensemble

Les objectifs du bloc "Objectifs du jour" de la page d'accueil sont maintenant **connectés en temps réel** aux données de la base Supabase.

---

## 🍽️ **Objectif 1 : "Suivre mes repas aujourd'hui"**

### 📍 **Source des données** :
- **Table** : `food_entries`
- **Champ clé** : `meal_id` (UUID unique par bloc repas)
- **Filtre** : `user_id` = utilisateur connecté + `consumed_at` = aujourd'hui

### 🧮 **Calcul** :
```sql
SELECT COUNT(DISTINCT meal_id) as meals_count
FROM food_entries 
WHERE user_id = ? 
AND consumed_at >= start_of_day 
AND consumed_at < end_of_day
```

### 🎯 **Logique d'objectif** :
- **Progression** : `(meals_count / 3) * 100`
- **Complété** : `meals_count >= 3`
- **Valeur cible** : 3 repas (fixe)
- **Unité** : Aucune

### 📝 **Notes** :
- Chaque `meal_id` représente un bloc repas unique dans le journal
- Un même type de repas peut avoir plusieurs blocs (ex: "Collation 1", "Collation 2")
- Système plus précis que l'ancien comptage par nombre d'entrées

---

## 💧 **Objectif 2 : "Boire XL d'eau"**

### 📍 **Sources des données** :

#### **Quantité consommée** :
- **Table** : `water_entries`
- **Champ** : `amount` (en millilitres)
- **Filtre** : `user_id` = utilisateur connecté + `consumed_at` = aujourd'hui

#### **Objectif personnalisé** :
- **Table** : `users`
- **Champ** : `daily_water_goal` (en millilitres)
- **Conversion** : `daily_water_goal / 1000` pour affichage en litres

### 🧮 **Calcul** :
```sql
-- Consommé
SELECT SUM(amount) as water_consumed_ml
FROM water_entries 
WHERE user_id = ? 
AND consumed_at >= start_of_day 
AND consumed_at < end_of_day

-- Objectif
SELECT daily_water_goal 
FROM users 
WHERE id = ?
```

### 🎯 **Logique d'objectif** :
- **Progression** : `(water_consumed_ml / daily_water_goal) * 100`
- **Complété** : `water_consumed_ml >= daily_water_goal`
- **Valeur cible** : `daily_water_goal / 1000` (en litres)
- **Unité** : "L"

### 📝 **Notes** :
- Objectif dynamique selon les préférences utilisateur
- Support des différents types de contenants (verre, bouteille, etc.)
- Valeur par défaut : 2000ml (2L) si non configuré

---

## 🔥 **Objectif 3 : "Atteindre mes calories"**

### 📍 **Sources des données** :

#### **Calories consommées** :
- **Table** : `food_entries`
- **Champ** : `calories` (nombre total de kcal)
- **Filtre** : `user_id` = utilisateur connecté + `consumed_at` = aujourd'hui

#### **Objectif personnalisé** :
- **Table** : `users`
- **Champ** : `daily_calories` (objectif quotidien en kcal)

### 🧮 **Calcul** :
```sql
-- Consommé
SELECT SUM(calories) as calories_consumed
FROM food_entries 
WHERE user_id = ? 
AND consumed_at >= start_of_day 
AND consumed_at < end_of_day

-- Objectif
SELECT daily_calories 
FROM users 
WHERE id = ?
```

### 🎯 **Logique d'objectif** :
- **Progression** : `(calories_consumed / daily_calories) * 100`
- **Complété** : `calories_consumed >= daily_calories * 0.9` (90% de l'objectif)
- **Valeur cible** : `daily_calories`
- **Unité** : "cal"

### 📝 **Notes** :
- Objectif dynamique selon le profil nutritionnel de l'utilisateur
- Seuil de complétion à 90% pour éviter le suralimentation
- Valeur par défaut : 2000 kcal si non configuré

---

## 🏃 **Objectif 4 : "Faire une séance aujourd'hui"**

### 📍 **État actuel** :
- **Statique** : Toujours à 0% (non implémenté)
- **TODO** : Connexion aux tables de sport (`workout_sessions`, `hiit_sessions`, `cardio_sessions`)

### 🎯 **Implémentation future** :
```sql
-- Sera implémenté avec
SELECT COUNT(*) as sessions_count
FROM (
  SELECT id FROM workout_sessions WHERE user_id = ? AND DATE(start_time) = today
  UNION ALL
  SELECT id FROM hiit_sessions WHERE user_id = ? AND DATE(start_time) = today  
  UNION ALL
  SELECT id FROM cardio_sessions WHERE user_id = ? AND DATE(start_time) = today
) as all_sessions
```

---

## ⚡ **Mise à jour en temps réel**

### 🔄 **Mécanisme de synchronisation** :

#### **Déclencheurs automatiques** :
1. **Ajout/suppression d'eau** → `WaterService.addWaterEntry()` / `deleteWaterEntry()`
2. **Ajout/suppression de nourriture** → `FoodEntriesService.addFoodEntry()` / `removeFoodEntry()`

#### **Pipeline de mise à jour** :
```dart
// 1. Action utilisateur (ajout eau/nourriture)
await WaterService.addWaterEntry(amount: 250);

// 2. Invalidation du cache automatique
await DashboardService.invalidateAndRefreshGoals();

// 3. Récupération des nouvelles données
final goals = await getDailyGoals(); // Nouvelle requête SQL

// 4. Mise à jour du notifier
GoalsNotifier.instance.update(goals);

// 5. Refresh automatique de l'UI
// ValueListenableBuilder se met à jour automatiquement
```

### 📊 **Cache intelligent** :
- **Durée** : Cache valide pour la journée en cours uniquement
- **Invalidation** : Automatique à minuit + lors des modifications
- **Performance** : Évite les requêtes répétées inutiles

---

## 🎨 **Interface utilisateur**

### 📱 **Affichage dynamique** :
- **Compteur** : "X/4 objectifs atteints" (mis à jour automatiquement)
- **Progression** : Barres de progression en temps réel
- **Labels** : Titres dynamiques (ex: "Boire 2.5L d'eau" selon l'objectif utilisateur)

### 🔧 **Technologie** :
- **State Management** : `ValueListenableBuilder` + `GoalsNotifier`
- **Pattern** : Singleton pour la cohérence entre pages
- **Reactivity** : Mise à jour automatique sans `setState()` manuel

---

## 📈 **Performance & Fiabilité**

### ⚡ **Optimisations** :
- Requêtes SQL optimisées avec index appropriés
- Cache intelligent par jour
- Requêtes groupées (moins d'appels réseau)

### 🛡️ **Robustesse** :
- Valeurs par défaut en cas d'erreur
- Gestion des utilisateurs non connectés
- Fallback sur données statiques si nécessaire

### 📊 **Monitoring** :
- Logs détaillés pour debug
- Affichage des valeurs calculées en temps réel
- Suivi des performances des requêtes 