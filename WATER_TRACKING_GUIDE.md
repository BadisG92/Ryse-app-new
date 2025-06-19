# Guide du Système de Suivi d'Hydratation

## 🎯 **Architecture Recommandée : Table Dédiée**

Après analyse, **une table dédiée `water_entries`** est la meilleure solution pour gérer l'hydratation.

### **✅ Pourquoi une table dédiée ?**

1. **🎯 Spécialisée** : Conçue spécifiquement pour l'hydratation
2. **⚡ Performance** : Requêtes optimisées pour l'eau uniquement  
3. **🔧 Flexibilité** : Métadonnées spécifiques (type de contenant, notes)
4. **📊 Clarté** : Séparation logique entre nourriture et hydratation
5. **🚀 Évolutivité** : Facilité d'ajout de fonctionnalités futures

### **❌ Pourquoi pas `food_entries` ?**

- **Pollution** : Mélange nourriture et hydratation
- **Performance** : Requêtes plus lourdes 
- **Logique** : `meal_type` inapproprié pour l'eau
- **Complexité** : Conditions partout dans le code

## 📊 **Structure de la Base de Données**

### **Table `water_entries`**

```sql
CREATE TABLE water_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,                    -- en millilitres
    consumed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    source_type TEXT DEFAULT 'manual',         -- type de contenant
    notes TEXT,                                 -- optionnel
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

### **Colonne ajoutée à `users`**

```sql
ALTER TABLE users ADD COLUMN daily_water_goal INTEGER DEFAULT 2000; -- en ml
```

### **Types de contenants (`source_type`)**

- `manual` : Saisie manuelle
- `glass` : Verre (≈250ml)
- `bottle` : Bouteille (≈500ml) 
- `sports_bottle` : Gourde de sport (≈750ml)
- `cup` : Tasse (≈200ml)

## 🔍 **Vues et Fonctions Créées**

### **Vue `daily_water_stats`**
Statistiques quotidiennes par utilisateur :
```sql
SELECT * FROM daily_water_stats 
WHERE user_id = 'your-user-id' 
AND date = CURRENT_DATE;
```

### **Fonction `get_daily_water_progress()`**
Progrès d'hydratation détaillé :
```sql
SELECT * FROM get_daily_water_progress('your-user-id', CURRENT_DATE);
```

Retourne :
- `consumed_ml` : Eau consommée (ml)
- `goal_ml` : Objectif quotidien (ml)
- `progress_percentage` : Pourcentage de progression
- `remaining_ml` : Eau restante à boire
- `entries_count` : Nombre d'entrées

## 💡 **Exemples d'Utilisation**

### **1. Ajouter de l'eau**
```sql
INSERT INTO water_entries (user_id, amount, source_type, notes)
VALUES (
    'user-uuid',
    250,
    'glass',
    'Verre d''eau après sport'
);
```

### **2. Voir le progrès du jour**
```sql
SELECT * FROM get_daily_water_progress('user-uuid');
-- Résultat : 750ml/2000ml (37.5% - reste 1250ml)
```

### **3. Historique de la semaine**
```sql
SELECT 
    consumed_at::date as date,
    SUM(amount) as total_ml,
    COUNT(*) as entries
FROM water_entries 
WHERE user_id = 'user-uuid'
AND consumed_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY consumed_at::date
ORDER BY date;
```

## 🎮 **Interface Utilisateur Suggérée**

### **Boutons Rapides**
- 🥤 **+250ml** (Verre)
- 🍼 **+500ml** (Bouteille) 
- 🏃 **+750ml** (Gourde sport)
- ➕ **Personnalisé** (Saisie manuelle)

### **Indicateur de Progrès**
```
💧 Hydratation aujourd'hui
████████░░ 750ml / 2000ml (38%)
Il vous reste 1250ml à boire
```

### **Historique**
```
📅 Cette semaine
Lun: 1800ml ✅    Mar: 2100ml ✅
Mer: 1600ml ❌    Jeu: 2000ml ✅
Ven: 1900ml ✅    Sam: 2200ml ✅
```

## 🔒 **Sécurité (RLS)**

- ✅ Row Level Security activé
- ✅ Politiques : users voient uniquement leurs données
- ✅ Cascade delete si user supprimé

## 📱 **Intégration Flutter**

Un service `WaterService` sera créé pour :
- ✅ Ajouter des entrées d'eau
- ✅ Récupérer le progrès quotidien
- ✅ Afficher l'historique
- ✅ Gérer les objectifs d'hydratation

## 🚀 **Fonctionnalités Futures**

- **🔔 Rappels** : Notifications pour boire
- **📊 Analytics** : Tendances d'hydratation
- **🏆 Badges** : Objectifs atteints
- **🌡️ Ajustements** : Objectifs selon météo/activité
- **💧 Types de liquides** : Thé, café, jus (avec coefficients)

## 📈 **Avantages de cette Architecture**

1. **Performance** : Requêtes spécialisées et rapides
2. **Maintenabilité** : Code organisé et logique
3. **Flexibilité** : Ajout facile de nouvelles fonctionnalités
4. **Historique complet** : Suivi détaillé dans le temps
5. **Expérience utilisateur** : Interface dédiée et intuitive

Cette architecture offre une base solide pour un système d'hydratation complet et évolutif ! 🎯 