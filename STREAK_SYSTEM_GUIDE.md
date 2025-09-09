# 🔥 Nouveau Système de Streak Optimisé

## 📋 **Résumé**

Le système de streak a été complètement refondu pour être ultra-performant avec un cache en base de données au lieu de recalculs coûteux.

## 🗃️ **Migration Base de Données REQUISE**

**⚠️ IMPORTANT :** Tu dois exécuter cette migration dans ton tableau de bord Supabase avant de tester :

```sql
-- Dans Supabase Dashboard > SQL Editor
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS streak_last_date DATE DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_users_streak_last_date ON users(streak_last_date);

COMMENT ON COLUMN users.streak_count IS 'Nombre de jours consécutifs d''activité (avec tolérance)';
COMMENT ON COLUMN users.streak_last_date IS 'Date du dernier jour d''activité comptabilisé dans la streak';
```

## 🚀 **Comment ça fonctionne**

### **📊 Logique de la Streak :**

1. **🆕 Première utilisation** : `streak_count = 1`, `streak_last_date = aujourd'hui`

2. **📅 Utilisation quotidienne** :
   - Si la dernière date = aujourd'hui → Pas de changement
   - Si dans la tolérance (≤ 7 jours) → `streak_count + 1`, mise à jour de la date  
   - Si hors tolérance (> 7 jours) → Reset à `streak_count = 1`

3. **⚡ Performance** : 
   - 1 seule requête SQL au lieu de 60+ requêtes
   - Cache automatique en base de données
   - Pas de recalcul à chaque ouverture d'app

### **🔄 Intégration :**

- **Dashboard principal** : Utilise `StreakService.getCurrentStreak()`
- **Page progression** : Utilise le même service via `ProgressServiceV2`
- **Page sport** : Utilise `StreakService.getCurrentStreak()` dans `SportDashboardService`
- **Page nutrition** : Charge dynamiquement via `StreakService.getCurrentStreak()`
- **Activités** : `ActivityTracker` notifie automatiquement les changements

## 🧪 **Test du Système**

### **Test 1 : Première utilisation**
```dart
// Dans la console
await StreakService.getCurrentStreak(); // Devrait retourner 1
await StreakService.debugStreakState(); // Voir l'état en DB
```

### **Test 2 : Utilisation quotidienne**
```dart
// Jour suivant
await StreakService.getCurrentStreak(); // Devrait retourner 2
```

### **Test 3 : Tolérance**
```dart
// Simuler 3 jours plus tard
// Modifier manuellement streak_last_date dans Supabase à J-3
await StreakService.getCurrentStreak(); // Devrait retourner ancien+1
```

### **Test 4 : Reset après 7 jours**
```dart
// Simuler 8 jours plus tard
// Modifier manuellement streak_last_date dans Supabase à J-8
await StreakService.getCurrentStreak(); // Devrait retourner 1
```

## 📱 **Utilisation dans l'App**

### **Récupération rapide (sans recalcul) :**
```dart
final streak = await StreakService.getStreakValue(); // Juste la valeur DB
```

### **Recalcul intelligent :**
```dart
final streak = await StreakService.getCurrentStreak(); // Avec logique de mise à jour
```

### **Notification d'activité :**
```dart
// Déjà intégré dans ActivityTracker
ActivityTracker.notifyWorkoutCompleted(); // Met à jour automatiquement
```

## 🎯 **Avantages**

✅ **Performance** : 1 requête au lieu de 60+  
✅ **Cohérence** : Même valeur partout dans l'app  
✅ **Tolérance** : 7 jours avant reset (comme demandé)  
✅ **Cache intelligent** : Pas de recalcul inutile  
✅ **Automatique** : Se met à jour lors des activités  

## 🔍 **Debug**

Si tu vois toujours "7 jours", vérifie :

1. **Migration appliquée ?** → Vérifie que les colonnes existent dans Supabase
2. **Service utilisé ?** → Vérifie les logs console pour voir les appels StreakService
3. **Cache vidé ?** → Redémarre l'app complètement

**Commande debug :**
```dart
await StreakService.debugStreakState(); // Voir l'état actuel en DB
```
