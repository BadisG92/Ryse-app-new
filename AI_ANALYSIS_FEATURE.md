# 🤖 Analyse IA des Performances d'Exercice

## 📋 Vue d'ensemble

Cette fonctionnalité permet aux utilisateurs d'obtenir une analyse personnalisée de leurs performances sur un exercice spécifique en utilisant l'IA Gemini 2.0 Flash.

## ✨ Fonctionnalités

### 1. **Analyse à la demande**
- Bouton "Analyser avec l'IA" affiché sous le graphique de progression
- Génération d'analyse uniquement sur demande (pas automatique)
- Nécessite minimum 3 séances pour activer l'analyse

### 2. **Cache intelligent (24h)**
- Les analyses sont mises en cache pendant 24 heures
- Évite les appels répétés coûteux à l'API Gemini
- Badge "Nouvelle dispo" si de nouvelles séances sont ajoutées

### 3. **Support multilingue**
- Analyse générée en français ou anglais selon les préférences utilisateur
- Traductions complètes de l'interface

### 4. **Design compact et élégant**
- Card expandable/collapsible pour économiser l'espace
- Bouton refresh pour régénérer l'analyse
- Timestamp "Il y a X heures/jours"
- Design cohérent avec la DA de l'application

## 🏗️ Architecture

### Fichiers créés

1. **`lib/services/exercise_ai_analysis_service.dart`**
   - Service de communication avec Gemini 2.0 Flash
   - Gestion du cache avec SharedPreferences
   - Détection de nouvelles séances
   - Prompts optimisés FR/EN

2. **`lib/components/exercise_ai_analysis_widget.dart`**
   - Widget UI avec 4 états :
     - État initial (bouton)
     - Loading
     - Analyse affichée
     - Badge "Nouvelle analyse disponible"

### Fichiers modifiés

1. **`pubspec.yaml`**
   - Ajout de `google_generative_ai: ^0.4.6`
   - `shared_preferences` déjà présente

2. **`lib/main.dart`**
   - Initialisation du service au démarrage

3. **`lib/widgets/exercise/exercise_detail_page.dart`**
   - Intégration du widget entre graphique et historique
   - Vérification du minimum de 3 séances

4. **`lib/services/translations.dart`**
   - Ajout des clés de traduction :
     - `analyze_with_ai`
     - `ai_analysis`
     - `analysis_in_progress`
     - `refresh_analysis`
     - `new_analysis_available`
     - `minimum_sessions_required`
     - `analysis_error`

## 🎨 Design Specs

### États du widget

#### État 1 : Bouton initial
```
┌─────────────────────────────────────┐
│ [🤖 Analyser avec l'IA]            │
└─────────────────────────────────────┘
```
- OutlinedButton avec border Color(0xFF6366F1)
- Icon: Icons.psychology

#### État 2 : Loading
```
┌─────────────────────────────────────┐
│ [Spinner] Analyse en cours...       │
└─────────────────────────────────────┘
```

#### État 3 : Analyse affichée
```
┌─────────────────────────────────────┐
│ 🤖 Analyse IA          [↻]  [▼]    │
├─────────────────────────────────────┤
│ 📊 Vos performances sont stables... │
│                                     │
│ 💡 Pour progresser :                │
│ • Augmentez à 12kg                  │
│ • Visez 22-25 reps                  │
│                                     │
│ Il y a 2h                           │
└─────────────────────────────────────┘
```

#### État 4 : Badge notification
```
┌─────────────────────────────────────┐
│ 🤖 Analyse IA [🔔 Nouvelle dispo]  │
└─────────────────────────────────────┘
```

## 📊 Format de l'analyse

Le prompt Gemini génère une analyse structurée :

```
📊 [Observation sur la progression - 1-2 phrases]

💡 Recommandations :
• [Action concrète 1]
• [Action concrète 2]
• [Action concrète 3 optionnelle]
```

### Données analysées
- Historique des 10 dernières séances maximum
- Poids, répétitions, volume total par séance
- Dates des séances pour analyser la régularité
- Toutes les séries (pas seulement la meilleure)

## 🔧 Configuration

### Clé API Gemini
Configurée dans `lib/config/gemini_config.dart` :
```dart
static const String geminiApiKey = 'AIzaSy...';
static const String modelName = 'gemini-2.0-flash';
```

### Paramètres du service
```dart
static const Duration _cacheDuration = Duration(hours: 24);
static const int _minimumSessions = 3;
static const int _maxSessionsForAnalysis = 10;
```

## 🚀 Utilisation

### Pour l'utilisateur

1. Aller sur la page de détail d'un exercice
2. Effectuer au moins 3 séances de l'exercice
3. Cliquer sur "Analyser avec l'IA"
4. L'analyse s'affiche en quelques secondes
5. Possibilité de refresh pour régénérer
6. Badge orange si de nouvelles séances sont ajoutées

### Pour le développeur

```dart
// Initialisation (dans main.dart)
ExerciseAiAnalysisService.initialize();

// Utilisation du widget
ExerciseAiAnalysisWidget(
  exerciseName: 'Squat',
  userId: 'user_id',
  sessionHistory: sessionHistory,
)

// Invalidation manuelle du cache
ExerciseAiAnalysisService.invalidateUserCache(userId);
```

## 🔒 Sécurité & Performance

### Cache
- Stockage local avec SharedPreferences
- Durée de vie : 24h
- Clé de cache : `ai_analysis_{userId}_{exerciseName}`

### Optimisations
- Génération à la demande uniquement
- Limitation à 10 dernières séances
- Minimum 3 séances pour activer
- Réutilisation du cache existant

### Gestion d'erreurs
- Vérification `mounted` pour éviter les fuites mémoire
- Fallback silencieux en cas d'erreur API
- Messages d'erreur localisés

## 📱 Compatibilité

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Multilingue (FR/EN)

## 🎯 Améliorations futures possibles

1. **Graphiques dans l'analyse**
   - Visualisations générées par l'IA
   - Courbes de progression

2. **Notifications**
   - Alerte quand une nouvelle analyse est disponible
   - Rappel si l'utilisateur stagne

3. **Historique des analyses**
   - Voir l'évolution des recommandations
   - Comparer les analyses précédentes

4. **Export**
   - Partager l'analyse
   - Export PDF/image

5. **Analyse multi-exercices**
   - Analyse globale du programme
   - Détection de déséquilibres musculaires

## 🐛 Debug

Pour activer les logs :
```dart
debugPrint('🤖 AI Analysis: ...');
```

Les logs incluent :
- Génération d'analyse
- Erreurs API
- État du cache

## 📝 Tests

### Manuel
1. Créer un utilisateur test
2. Ajouter 3+ séances pour un exercice
3. Vérifier l'affichage du bouton
4. Tester la génération d'analyse
5. Vérifier le cache (fermer/rouvrir l'app)
6. Ajouter une nouvelle séance
7. Vérifier le badge orange

### Automatisé (à implémenter)
```dart
testWidgets('Shows AI analysis button after 3 sessions', (tester) async {
  // Test implementation
});
```

## 👥 Crédits

- **IA** : Gemini 2.0 Flash (Google)
- **Framework** : Flutter
- **Design** : Cohérent avec Ryze App DA
- **Développement** : [Votre nom]

---

*Dernière mise à jour : Octobre 2025*
