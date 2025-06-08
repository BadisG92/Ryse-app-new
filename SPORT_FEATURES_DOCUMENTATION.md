# Documentation des fonctionnalités Sport - Module Musculation

## Vue d'ensemble

Ce document détaille les nouvelles fonctionnalités implémentées dans le module sport de l'application, spécifiquement pour la partie musculation.

## Fonctionnalités implémentées

### 1. Gestion des séances manuelles

#### Démarrage d'une séance
- **Bouton "Commencer une séance"** : Lance le processus de création de séance
- **Modal de choix** : Permet de choisir entre :
  - Créer une séance manuellement
  - Choisir un programme préenregistré (à venir)

#### Configuration de la séance
- **Nom de la séance** : Saisie personnalisée avec valeur par défaut (Séance du jour)
- **Suivi en temps réel** : Chronomètre automatique dès le démarrage

### 2. Ajout d'exercices

#### Bottom Sheet de sélection d'exercice
- **Barre de recherche** : Recherche textuelle dans la base d'exercices
- **Filtres par muscle** : 
  - Tous
  - Pectoraux, Dos, Épaules, Biceps, Triceps
  - Jambes, Fessiers, Abdominaux, Mollets, Avant-bras
- **Base d'exercices prédéfinis** : 8 exercices populaires inclus
- **Création d'exercices personnalisés** : Option pour ajouter des exercices non listés

#### Exercices prédéfinis inclus
1. Développé couché (Pectoraux)
2. Squat (Jambes)  
3. Tractions (Dos)
4. Développé militaire (Épaules)
5. Curl biceps (Biceps)
6. Dips (Triceps)
7. Soulevé de terre (Dos)
8. Crunchs (Abdominaux)

### 3. Gestion des séries

#### Interface des séries
- **Header de l'exercice** : Nom, muscle ciblé, progression (X/Y séries)
- **Tableau des séries** avec colonnes :
  - Numéro de série
  - Poids (kg)
  - Nombre de répétitions
  - Bouton de validation
- **Bouton "Ajouter une série"** : Ajout dynamique de nouvelles séries

#### Fonctionnalités des séries
- **Saisie en temps réel** : Mise à jour immédiate des valeurs
- **Validation visuelle** : Changement de couleur quand la série est complétée
- **Suppression** : Possibilité de supprimer une série (minimum 1 série par exercice)

### 4. Suivi de progression

#### Indicateurs visuels
- **Compteur de séries** : Affichage "séries complétées/total" par exercice
- **État des séries** : Code couleur vert pour les séries validées
- **Chronomètre de séance** : Durée écoulée depuis le début

## Structure technique

### Modèles de données

#### `Exercise`
```dart
class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String description;
  final bool isCustom;
}
```

#### `ExerciseSet`
```dart
class ExerciseSet {
  final int reps;
  final double weight;
  final bool isCompleted;
}
```

#### `WorkoutExercise`
```dart
class WorkoutExercise {
  final Exercise exercise;
  final List<ExerciseSet> sets;
}
```

#### `WorkoutSession`
```dart
class WorkoutSession {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutExercise> exercises;
  final bool isCompleted;
}
```

### Composants UI

#### `ExerciseSelectionBottomSheet`
- Gestion de la sélection et création d'exercices
- Recherche et filtrage
- Interface de saisie du nombre de séries

#### `ExerciseSetsWidget`
- Affichage et gestion des séries d'un exercice
- Interface de saisie poids/répétitions
- Boutons d'action (valider, supprimer, ajouter)

### Fichiers modifiés

1. **Nouveaux fichiers** :
   - `lib/models/sport_models.dart`
   - `lib/bottom_sheets/exercise_selection_bottom_sheet.dart`
   - `lib/components/ui/exercise_sets_widget.dart`

2. **Fichiers modifiés** :
   - `lib/components/sport_musculation_hybrid.dart`

## Flux utilisateur

1. **Démarrage** : Clic sur "Commencer une séance"
2. **Configuration** : Choix du type et nom de séance
3. **Ajout d'exercices** : Sélection via bottom sheet avec recherche/filtres
4. **Configuration des séries** : Saisie du nombre de séries souhaité
5. **Exécution** : Saisie des poids et répétitions en temps réel
6. **Validation** : Marquage des séries comme complétées
7. **Extension** : Ajout de nouvelles séries si nécessaire

## Améliorations futures possibles

1. **Programmes préenregistrés** : Templates de séances prédéfinies
2. **Historique détaillé** : Sauvegarde et consultation des séances passées
3. **Graphiques de progression** : Évolution des performances par exercice
4. **Temps de repos** : Timer entre les séries
5. **Exercices superset** : Groupement d'exercices
6. **Base d'exercices étendue** : Plus d'exercices avec images/vidéos
7. **Synchronisation cloud** : Sauvegarde des données utilisateur 