# 🏠 Guide d'Intégration Dashboard - Base de Données

## 📋 Résumé des Modifications

Le dashboard de la page d'accueil a été connecté à la base de données Supabase pour afficher des données dynamiques au lieu de données statiques.

## 🔗 Nouvelles Connexions

### 1. **Nom de l'Utilisateur**
- **Avant**: "Rihab" (en dur)
- **Maintenant**: Récupéré depuis `users.first_name` de la base de données
- **Fallback**: "Utilisateur" si pas de prénom

### 2. **Objectifs Journaliers Dynamiques**

#### **Objectif 1: Suivre mes repas (X/3)**
- **Source**: Compte les `meal_id` uniques dans `food_entries` pour aujourd'hui
- **Objectif**: 3 repas (reste en dur)
- **Calcul**: Progression basée sur le nombre de blocs repas distincts

#### **Objectif 2: Boire XL d'eau**
- **Objectif**: Récupéré depuis `users.daily_water_goal` (converti en litres)
- **Progression**: Somme de `water_entries.amount` pour aujourd'hui
- **Affichage**: "Boire 2L d'eau" → "Boire [X]L d'eau" (dynamique)

#### **Objectif 3: Atteindre mes calories**
- **Objectif**: Récupéré depuis `users.daily_calories`
- **Progression**: Somme de `food_entries.calories` pour aujourd'hui
- **Condition**: Objectif atteint à 90% de la cible

### 3. **Bloc Nutrition**
- **Calories**: Somme des calories consommées aujourd'hui (`food_entries`)
- **Eau**: Quantité d'eau consommée aujourd'hui (`water_entries`)

### 4. **Compteur d'Objectifs**
- **Format**: "X/4 objectifs atteints"
- **Calcul**: Compte automatiquement les objectifs marqués comme `completed`

## 🗃️ Nouvelle Table Créée

### `water_entries`
```sql
CREATE TABLE water_entries (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  amount INTEGER NOT NULL, -- en millilitres
  source_type TEXT DEFAULT 'manual',
  consumed_at TIMESTAMPTZ DEFAULT NOW(),
  -- autres champs...
);
```

### Nouveau Champ Utilisateur
```sql
ALTER TABLE users 
ADD COLUMN daily_water_goal INTEGER DEFAULT 2000; -- en ml
```

## 📁 Nouveaux Fichiers

### 1. `lib/services/dashboard_service.dart`
Service principal pour récupérer les données du dashboard depuis Supabase.

**Méthodes principales:**
- `getUserProfile()` - Profil utilisateur avec données réelles
- `getDailyGoals()` - Objectifs avec progression dynamique
- `getModulePreviews()` - Aperçus des modules avec données réelles
- `getCompletedGoalsCount()` - Compte des objectifs atteints

### 2. `supabase/migrations/009_add_water_tracking.sql`
Migration pour ajouter le suivi de l'eau avec:
- Table `water_entries`
- Fonction `get_daily_water_progress()`
- Vue `daily_water_stats`
- RLS et indexes

## 🔄 Modifications des Fichiers Existants

### `main_dashboard_hybrid.dart`
- ✅ Suppression des données statiques
- ✅ Ajout du service `DashboardService`
- ✅ États de chargement et d'erreur
- ✅ Pull-to-refresh pour actualiser les données
- ✅ Gestion des cas null

### `dashboard_models.dart`
- ✅ Ajout de la méthode `copyWith()` à `UserProfile`

## 🚀 Instructions d'Utilisation

### 1. **Appliquer la Migration**
Exécutez dans votre console Supabase :
```sql
-- Contenu de 009_add_water_tracking.sql
```

### 2. **Tester les Données**
```dart
// Les données apparaîtront automatiquement
// Ajoutez des entrées pour tester :

// 1. Ajout d'eau
await WaterService.addWaterEntry(amount: 250);

// 2. Ajout de nourriture (via les flux existants)
// Les données apparaîtront dans le dashboard

// 3. Refresh du dashboard
// Tirez vers le bas sur la page d'accueil
```

### 3. **Valeurs par Défaut**
- **Objectif eau**: 2L (2000ml)
- **Objectif calories**: Calculé selon le profil ou 2000 kcal
- **Objectif repas**: 3 blocs par jour

## 🔍 Points d'Attention

### **Gestion d'Erreurs**
- Si la base est inaccessible → données statiques de fallback
- Si l'utilisateur n'existe pas → valeurs par défaut
- États de chargement avec indicateurs visuels

### **Performance**
- Requêtes optimisées avec indexes
- Chargement en parallèle des données
- Cache automatique via Supabase

### **Sécurité**
- RLS activé sur toutes les tables
- Utilisateurs peuvent seulement voir leurs données
- Fonctions sécurisées avec SECURITY DEFINER

## 🎯 Prochaines Étapes

1. **Objectif Sport**: Connecter le 4ème objectif aux sessions d'entraînement
2. **Streak Calculation**: Calculer le vrai streak depuis l'historique
3. **XP System**: Système de points d'expérience basé sur les actions
4. **Premium Features**: Fonctionnalités premium dynamiques

## 🐛 Debugging

### Vérifier les Données
```sql
-- Vérifier l'eau aujourd'hui
SELECT * FROM water_entries 
WHERE user_id = auth.uid() 
AND DATE(consumed_at) = CURRENT_DATE;

-- Vérifier les repas aujourd'hui
SELECT meal_id, COUNT(*) 
FROM food_entries 
WHERE user_id = auth.uid() 
AND DATE(consumed_at) = CURRENT_DATE 
GROUP BY meal_id;

-- Vérifier le profil utilisateur
SELECT first_name, daily_calories, daily_water_goal 
FROM users 
WHERE id = auth.uid();
```

### Logs Flutter
```dart
// Activer les logs dans dashboard_service.dart
print('🔍 Debug: données récupérées = $response');
```

## ✅ État de Completion

- ✅ **Nom utilisateur dynamique**
- ✅ **Objectif repas dynamique**  
- ✅ **Objectif eau dynamique**
- ✅ **Objectif calories dynamique**
- ✅ **Bloc nutrition dynamique**
- ✅ **Compteur objectifs atteints**
- ✅ **Migration base de données**
- ✅ **Gestion d'erreurs**
- ✅ **Pull-to-refresh**
- 🔄 **Tests complets** (en cours)

Le dashboard est maintenant entièrement connecté à la base de données Supabase ! 🎉 