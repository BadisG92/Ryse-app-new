# Guide de Débogage des Tutoriels

## 🐛 Problème

Les utilisateurs voient les tutoriels même si les colonnes `tutorial_*_completed` sont à `true` dans la base de données Supabase.

## 🔍 Causes Possibles

### 1. **Cache SharedPreferences corrompu**
Le système utilise un cache local (SharedPreferences) qui peut être désynchronisé avec Supabase.

**Vérification** :
```dart
// Les valeurs locales et Supabase peuvent être différentes
Supabase: tutorial_dashboard_completed = true
Local:    tutorial_dashboard_completed = false  ← Problème !
```

### 2. **Erreur de lecture depuis Supabase**
La requête Supabase peut échouer silencieusement (timeout, permissions, etc.) et le code utilise alors le fallback SharedPreferences.

**Vérification des logs** :
```
⚠️ Erreur lecture tutorial depuis Supabase: [error message]
🔄 Fallback vers SharedPreferences: tutorial_dashboard_completed = false
```

### 3. **Migration non appliquée en production**
Les colonnes `tutorial_*_completed` n'existent peut-être pas dans la base de données de production.

**Vérification** :
```bash
./debug_tutorial_columns.sh
```

### 4. **Race Condition**
L'utilisateur termine le tutorial, mais entre le moment où `markTutorialAsCompleted()` sauvegarde les données et le moment où `_isTutorialCompleted()` les lit, il y a un délai.

## 🛠️ Solutions

### Solution 1 : Vérifier les logs détaillés

J'ai ajouté des logs détaillés dans `tutorial_service.dart` pour identifier le problème :

```dart
// Les logs vont maintenant afficher :
🔍 === VÉRIFICATION TUTORIAL: tutorial_dashboard_completed ===
✅ Utilisateur connecté: abc-123-def
📡 Requête Supabase: SELECT tutorial_dashboard_completed FROM users WHERE id = abc-123-def
📦 Réponse Supabase brute: {tutorial_dashboard_completed: true}
✅ Valeur extraite de Supabase: tutorial_dashboard_completed = true
💾 SharedPreferences synchronisé: tutorial_dashboard_completed = true
🔍 === RÉSULTAT: Tutorial tutorial_dashboard_completed COMPLÉTÉ ✅ ===
```

**Comment tester** :
1. Lancez l'app avec `flutter run --dart-define-from-file=.env.local`
2. Regardez les logs Xcode/Android Studio
3. Naviguez vers une page qui déclenche un tutorial
4. Vérifiez les logs pour identifier le problème

### Solution 2 : Utiliser l'écran de débogage

J'ai créé un écran de débogage pour tester les tutoriels : `lib/screens/tutorial_debug_screen.dart`

**Comment l'ajouter à votre app** :
```dart
// Dans lib/pages/ryze_app.dart ou un autre écran
import '../screens/tutorial_debug_screen.dart';

// Ajouter un bouton dans les settings ou ailleurs
IconButton(
  icon: const Icon(Icons.bug_report),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TutorialDebugScreen()),
    );
  },
  tooltip: 'Déboguer les tutoriels',
)
```

**Fonctionnalités** :
- ✅ Voir les valeurs Supabase vs Local
- 🔄 Recharger les données en temps réel
- 🔁 Réinitialiser tous les tutoriels
- 🔄 Synchroniser Supabase → Local
- 📋 Logs détaillés

### Solution 3 : Vérifier la base de données

Utilisez le script shell pour vérifier les colonnes :

```bash
./debug_tutorial_columns.sh
```

**Ce qu'il vérifie** :
1. ✅ Existence des colonnes `tutorial_*_completed`
2. 📊 Valeurs actuelles pour les derniers utilisateurs
3. 📈 Statistiques globales

### Solution 4 : Forcer la synchronisation

Si vous identifiez un problème de synchronisation, vous pouvez forcer la mise à jour :

```dart
// Dans tutorial_service.dart
Future<void> forceSync() async {
  final prefs = await SharedPreferences.getInstance();
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return;

  final response = await supabase
      .from('users')
      .select('tutorial_dashboard_completed, tutorial_nutrition_completed, ...')
      .eq('id', user.id)
      .single();

  // Synchroniser toutes les valeurs
  for (final key in response.keys) {
    if (key.startsWith('tutorial_')) {
      await prefs.setBool(key, response[key] as bool? ?? false);
    }
  }
}
```

## 📋 Checklist de Débogage

Suivez ces étapes dans l'ordre :

- [ ] 1. Vérifier que la migration `20250130_add_tutorial_columns.sql` est appliquée en production
- [ ] 2. Exécuter `./debug_tutorial_columns.sh` pour voir les valeurs en base
- [ ] 3. Lancer l'app et regarder les logs détaillés
- [ ] 4. Ouvrir l'écran de débogage et comparer Supabase vs Local
- [ ] 5. Si désynchronisé : utiliser "Synchroniser Supabase → Local"
- [ ] 6. Si erreur Supabase : vérifier les permissions RLS sur la table `users`
- [ ] 7. Si tout est OK mais le tutorial apparaît quand même : vérifier `_debugMode = false` dans `tutorial_service.dart`

## 🔧 Commandes Utiles

### Vérifier les colonnes en production
```bash
./debug_tutorial_columns.sh
```

### Réinitialiser les tutoriels pour UN utilisateur (SQL)
```sql
UPDATE users
SET
  tutorial_dashboard_completed = false,
  tutorial_nutrition_completed = false,
  tutorial_sport_completed = false,
  tutorial_cardio_completed = false,
  tutorial_musculation_completed = false,
  tutorial_progression_completed = false
WHERE id = 'USER_ID_HERE';
```

### Réinitialiser les tutoriels pour TOUS les utilisateurs (SQL)
```sql
UPDATE users
SET
  tutorial_dashboard_completed = false,
  tutorial_nutrition_completed = false,
  tutorial_sport_completed = false,
  tutorial_cardio_completed = false,
  tutorial_musculation_completed = false,
  tutorial_progression_completed = false;
```

### Effacer le cache local (Dart)
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.clear(); // ATTENTION : efface TOUTES les SharedPreferences
```

## 🎯 Solution Finale

Une fois le problème identifié, voici les corrections possibles :

### Si le problème est le cache local :
→ Ajouter une synchronisation automatique au démarrage de l'app

### Si le problème est une erreur Supabase :
→ Augmenter le timeout, ajouter des retry, vérifier les permissions RLS

### Si le problème est la migration :
→ Appliquer la migration en production via `supabase db push`

### Si le problème est une race condition :
→ Ajouter un délai avant de vérifier si le tutorial est complété

## 📝 Notes

- Le mode debug (`_debugMode = true`) force TOUJOURS l'affichage des tutoriels
- Les logs sont visibles uniquement en mode debug (pas en release)
- SharedPreferences est le fallback si Supabase échoue
- La source de vérité est TOUJOURS Supabase

## 🆘 Support

Si le problème persiste :
1. Partagez les logs complets de l'écran de débogage
2. Partagez la sortie de `./debug_tutorial_columns.sh`
3. Indiquez si c'est un nouveau compte ou un compte existant
4. Précisez sur quel environnement (dev/staging/production)
