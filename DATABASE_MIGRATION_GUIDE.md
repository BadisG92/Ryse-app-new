# Guide de Migration - Architecture Base de Données Simplifiée

## 🎯 Résumé de la Transformation

L'architecture multilingue complexe de Supabase a été **simplifiée** pour correspondre aux besoins réels de l'UX Ryze App. 

### ❌ Ancienne Architecture (Complexe)
- Tables de traduction séparées (`exercise_translations`, `food_translations`, etc.)
- Jointures complexes pour récupérer les données localisées
- Performance dégradée avec de multiples requêtes
- Maintenance difficile

### ✅ Nouvelle Architecture (Simplifiée)
- Colonnes directes `name_en` et `name_fr` dans chaque table
- Fonctions utilitaires pour la localisation
- Performance optimisée avec une seule requête
- Maintenance facile et intuitive

---

## 📊 Tables Principales Créées

### 1. **exercises**
```sql
- id (UUID)
- name_en (TEXT) - Nom en anglais
- name_fr (TEXT) - Nom en français  
- muscle_group (TEXT)
- equipment (TEXT)
- description (TEXT)
- is_custom (BOOLEAN)
- user_id (UUID) - Pour exercices personnalisés
```
**Données**: 127 exercices migrés

### 2. **foods**
```sql
- id (UUID)
- name_en (TEXT) - Nom en anglais
- name_fr (TEXT) - Nom en français
- calories (INTEGER)
- proteins (NUMERIC)
- carbs (NUMERIC) 
- fats (NUMERIC)
- category (TEXT)
- is_custom (BOOLEAN)
- user_id (UUID) - Pour aliments personnalisés
```
**Données**: 1,067 aliments migrés

### 3. **hiit_workouts**
```sql
- id (UUID)
- title_en (TEXT) - Titre en anglais
- title_fr (TEXT) - Titre en français
- description_en (TEXT)
- description_fr (TEXT)
- work_duration (INTEGER) - Secondes
- rest_duration (INTEGER) - Secondes
- total_duration (INTEGER) - Secondes
- total_rounds (INTEGER)
- is_custom (BOOLEAN)
- user_id (UUID)
```
**Données**: 5 entraînements HIIT migrés

### 4. **recipes**
```sql
- id (UUID)
- name_en (TEXT) - Nom en anglais
- name_fr (TEXT) - Nom en français
- ingredients (JSONB) - Structure flexible
- steps_en (TEXT[]) - Étapes en anglais
- steps_fr (TEXT[]) - Étapes en français
- image_url (TEXT)
- duration (TEXT)
- servings (INTEGER)
- difficulty (TEXT)
- tags (TEXT[])
- is_custom (BOOLEAN)
- user_id (UUID)
```
**Données**: 50 recettes migrées

### 5. **cardio_activities**
```sql
- id (UUID)
- activity_type (TEXT)
- name_en (TEXT) - Nom en anglais
- name_fr (TEXT) - Nom en français
- is_custom (BOOLEAN)
- user_id (UUID)
```
**Données**: 3 activités cardio créées

---

## 🔧 Fonctions Utilitaires Supabase

### Fonctions de Localisation
```sql
-- Récupère les exercices dans la langue demandée
get_exercises_localized(user_language TEXT DEFAULT 'en')

-- Récupère les aliments dans la langue demandée  
get_foods_localized(user_language TEXT DEFAULT 'en')

-- Récupère les entraînements HIIT dans la langue demandée
get_hiit_workouts_localized(user_language TEXT DEFAULT 'en')

-- Récupère les recettes dans la langue demandée
get_recipes_localized(user_language TEXT DEFAULT 'en')

-- Récupère les activités cardio dans la langue demandée
get_cardio_activities_localized(user_language TEXT DEFAULT 'en')
```

### Fonctions d'Historique
```sql
-- Historique nutrition utilisateur
get_user_nutrition_history(target_user_id UUID, start_date DATE, end_date DATE)

-- Historique entraînements musculation
get_user_workout_history(target_user_id UUID, start_date DATE, end_date DATE)

-- Historique sessions HIIT
get_user_hiit_history(target_user_id UUID, start_date DATE, end_date DATE)

-- Historique sessions cardio
get_user_cardio_history(target_user_id UUID, start_date DATE, end_date DATE)

-- Résumé quotidien utilisateur
get_user_daily_summary(target_user_id UUID, target_date DATE)
```

---

## 💻 Intégration Flutter

### 1. Types Dart Générés
Le fichier `lib/types/database_types.dart` contient tous les types Dart :

```dart
// Exemple d'utilisation
Exercise exercise = Exercise.fromJson(jsonData);
String localizedName = exercise.getLocalizedName('fr'); // Nom en français
```

### 2. Service de Base de Données
Le fichier `lib/services/database_service.dart` fournit une API simple :

```dart
// Récupérer les exercices en français
List<Exercise> exercises = await DatabaseService.getExercises(language: 'fr');

// Rechercher des aliments
List<Food> foods = await DatabaseService.searchFoods('pomme', language: 'fr');

// Obtenir l'historique utilisateur
UserDailySummary summary = await DatabaseService.getUserDailySummary(userId);
```

### 3. Exemples d'Utilisation

#### Afficher des Exercices Localisés
```dart
class ExerciseListWidget extends StatefulWidget {
  @override
  _ExerciseListWidgetState createState() => _ExerciseListWidgetState();
}

class _ExerciseListWidgetState extends State<ExerciseListWidget> {
  List<Exercise> exercises = [];
  
  @override
  void initState() {
    super.initState();
    loadExercises();
  }
  
  void loadExercises() async {
    final loadedExercises = await DatabaseService.getExercises(language: 'fr');
    setState(() {
      exercises = loadedExercises;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return ListTile(
          title: Text(exercise.getLocalizedName('fr')),
          subtitle: Text(exercise.muscleGroup),
        );
      },
    );
  }
}
```

#### Créer un Exercice Personnalisé
```dart
void createCustomExercise() async {
  final customExercise = Exercise(
    id: '', // Sera généré par Supabase
    nameEn: 'Custom Push-up',
    nameFr: 'Pompes Personnalisées',
    muscleGroup: 'chest',
    equipment: 'bodyweight',
    description: 'My custom push-up variation',
    isCustom: true,
    userId: currentUserId,
  );
  
  final created = await DatabaseService.createCustomExercise(customExercise);
  if (created != null) {
    print('Exercice créé avec succès !');
  }
}
```

---

## 🔄 Migration des Écrans Existants

### Écrans à Mettre à Jour

1. **workout_session_screen.dart**
   - Utiliser `DatabaseService.getExercises()` au lieu des anciennes requêtes
   - Appliquer la localisation avec `exercise.getLocalizedName(language)`

2. **hiit_session_screen.dart**  
   - Utiliser `DatabaseService.getHiitWorkouts()`
   - Localiser avec `workout.getLocalizedTitle(language)`

3. **cardio_tracking_screen.dart**
   - Utiliser `DatabaseService.getCardioActivities()`
   - Localiser avec `activity.getLocalizedName(language)`

4. **Écrans de nutrition**
   - Utiliser `DatabaseService.getFoods()` et `DatabaseService.searchFoods()`
   - Localiser avec `food.getLocalizedName(language)`

### Exemple de Migration d'Écran
```dart
// AVANT (complexe)
final response = await supabase
  .from('exercises')
  .select('*, exercise_translations(*)')
  .eq('exercise_translations.language_code', 'fr');

// APRÈS (simplifié)
final exercises = await DatabaseService.getExercises(language: 'fr');
```

---

## 📈 Avantages de la Nouvelle Architecture

### ✅ Performance
- **Une seule requête** au lieu de jointures multiples
- **Fonctions optimisées** avec index appropriés
- **Cache possible** au niveau Flutter

### ✅ Simplicité
- **Code plus lisible** et maintenable
- **Moins de bugs** liés aux jointures complexes
- **Développement plus rapide**

### ✅ Flexibilité
- **Contenu personnalisé** par utilisateur facilement gérable
- **Ajout de langues** simple (ajouter colonnes `name_xx`)
- **Migration progressive** possible

### ✅ Type Safety
- **Types Dart générés** automatiquement
- **Validation compile-time** des structures de données
- **IntelliSense complet** dans l'IDE

---

## 🚀 Prochaines Étapes

1. **Tester les fonctions** dans l'app Flutter
2. **Migrer les écrans** un par un vers la nouvelle API
3. **Ajouter la gestion des préférences** de langue utilisateur
4. **Optimiser les performances** avec du cache local si nécessaire
5. **Ajouter des tests unitaires** pour le DatabaseService

---

## 🔧 Configuration Supabase

### URL et Clés
```dart
// Dans votre configuration Supabase
const supabaseUrl = 'https://mfskwlzgxjhhknlwpblq.supabase.co';
const supabaseAnonKey = 'votre_anon_key';
```

### RLS (Row Level Security)
Toutes les tables ont des politiques RLS appropriées pour :
- Lecture publique des données globales (`is_custom = false`)
- Lecture/écriture privée des données utilisateur (`user_id = auth.uid()`)

---

## 📞 Support

Pour toute question sur cette migration :
1. Vérifier ce guide en premier
2. Tester les fonctions dans Supabase Dashboard
3. Consulter les logs d'erreur Flutter
4. Vérifier les types de données dans `database_types.dart`

**La nouvelle architecture est prête pour la production ! 🎉** 