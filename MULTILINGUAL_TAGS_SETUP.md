# Configuration des Tags Multilingues pour les Recettes

## 🎯 Solution Implémentée

Au lieu d'utiliser un mapping complexe entre l'interface française et les tags anglais de la base de données, cette solution ajoute deux colonnes distinctes dans la table `recipes` :

- **`tags_en`** : Tags en anglais (pour compatibilité avec les données existantes)
- **`tags_fr`** : Tags en français (pour l'interface utilisateur)

## 📋 Étapes d'Application

### 1. Migration de la Base de Données

Appliquez la migration pour ajouter les nouvelles colonnes :

```bash
cd ryze_app/backend
python apply_multilingual_tags_migration.py
```

Cette migration va :
- ✅ Ajouter les colonnes `tags_en` et `tags_fr` à la table `recipes`
- ✅ Migrer les tags existants vers `tags_en`
- ✅ Traduire automatiquement tous les tags vers le français dans `tags_fr`
- ✅ Créer des index pour optimiser les performances
- ✅ Nettoyer les fonctions temporaires

### 2. Structure de Base de Données Résultante

```sql
-- Table recipes mise à jour
CREATE TABLE recipes (
  id UUID NOT NULL,
  name_en TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  tags_en TEXT[], -- ["high_protein", "quick", "healthy"]
  tags_fr TEXT[], -- ["Riche en protéines", "Rapide", "Sain"]
  -- ... autres colonnes
);
```

### 3. Traductions Automatiques Appliquées

| Tags Anglais (tags_en) | Tags Français (tags_fr) |
|------------------------|-------------------------|
| `high_protein` | `Riche en protéines` |
| `low_carb` | `Faible en glucides` |
| `gluten_free` | `Sans gluten` |
| `vegan` | `Végan` |
| `vegetarian` | `Végétarien` |
| `healthy` | `Sain` |
| `quick` | `Rapide` |
| `mediterranean` | `Méditerranéen` |
| `plant_based` | `À base de plantes` |
| `high_fiber` | `Riche en fibres` |
| `omega_3` | `Riche en oméga-3` |

## 🔧 Modifications de l'Application

### 1. Service de Recettes (`RecipeService`)

La méthode `_convertTags` utilise maintenant la bonne colonne selon la langue :

```dart
static List<String> _convertTags(Map<String, dynamic> recipeData, String language) {
  // Utiliser les tags français ou anglais selon la langue
  dynamic tags;
  if (language == 'fr') {
    tags = recipeData['tags_fr'] ?? recipeData['tags_en'] ?? recipeData['tags'];
  } else {
    tags = recipeData['tags_en'] ?? recipeData['tags_fr'] ?? recipeData['tags'];
  }
  
  if (tags == null) return [];
  if (tags is List) return tags.cast<String>();
  return [];
}
```

### 2. Filtres de Recettes (`RecipeFilters`)

Les filtres utilisent maintenant directement les tags français :

```dart
static const Map<String, List<String>> regimeFilterMapping = {
  'Végétarien': ['Végétarien', 'À base de plantes'],
  'Végan': ['Végan', 'À base de plantes'],
  'Sans gluten': ['Sans gluten'],
  'Keto': ['Keto', 'Faible en glucides'],
  'Paléo': ['Paléo', 'Faible en glucides'],
  'Méditerranéen': ['Méditerranéen', 'Sain', 'Riche en oméga-3'],
};
```

## ✅ Avantages de cette Solution

1. **🎯 Précision** : Correspondance exacte entre filtres et tags
2. **🚀 Performance** : Pas de mapping complexe à chaque filtrage
3. **🔧 Maintenance** : Facilité d'ajout de nouveaux tags traduits
4. **🌍 Multilingue** : Support natif de l'anglais et du français
5. **📊 Base de données propre** : Structure claire avec colonnes dédiées

## 🔍 Vérification du Fonctionnement

Après application de la migration, vérifiez :

1. **Interface** : Les filtres dans l'onglet recettes utilisent les termes français
2. **Base de données** : Les recettes ont des `tags_fr` traduits
3. **Filtrage** : La sélection "Végétarien" affiche les recettes avec le tag "Végétarien"

## 📈 Exemple de Données

```json
{
  "id": "recipe-123",
  "name_fr": "Salade de Quinoa aux Légumes",
  "name_en": "Quinoa Vegetable Salad",
  "tags_en": ["vegetarian", "healthy", "high_fiber", "plant_based"],
  "tags_fr": ["Végétarien", "Sain", "Riche en fibres", "À base de plantes"]
}
```

## 🚀 Ajout de Nouvelles Recettes

Lors de l'ajout de nouvelles recettes, spécifiez les deux colonnes :

```sql
INSERT INTO recipes (name_en, name_fr, tags_en, tags_fr, ...) VALUES (
  'New Recipe',
  'Nouvelle Recette', 
  '{"healthy", "quick"}',
  '{"Sain", "Rapide"}',
  ...
);
```

## 🎉 Résultat Final

✅ **Filtres parfaitement fonctionnels** : Les régimes alimentaires filtrent correctement  
✅ **Interface française native** : Tous les tags affichés en français  
✅ **Base de données optimisée** : Structure multilingue propre  
✅ **Performance améliorée** : Pas de traduction à la volée  
✅ **Extensibilité** : Facilité d'ajout de nouvelles langues 