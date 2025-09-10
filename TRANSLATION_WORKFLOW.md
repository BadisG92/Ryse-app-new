# WORKFLOW ANTI-DOUBLON TRADUCTIONS

## ⚠️ RÈGLE OBLIGATOIRE
**AVANT tout ajout de traduction → VÉRIFIER LES DOUBLONS**

## 🔍 PROCESS SYSTÉMATIQUE

### 1. VÉRIFICATION MANUELLE RAPIDE
Avant d'ajouter une nouvelle traduction, chercher dans `translations.dart` :

```bash
# Rechercher le texte français
grep -n "Votre texte français" lib/services/translations.dart

# Rechercher le texte anglais  
grep -n "Your english text" lib/services/translations.dart

# Rechercher par mot-clé
grep -n "cancel\|annul" lib/services/translations.dart
```

### 2. UTILISATION DU VÉRIFICATEUR AUTOMATIQUE

```dart
// Dans lib/utils/translation_checker.dart
var result = TranslationChecker.findExistingTranslation(
  frenchText: "Mon texte français",
  englishText: "My english text", 
  context: "workout" // optionnel
);

print(result); // Affiche si utiliser clé existante OU créer nouvelle
```

### 3. RÈGLES DE NOMMAGE

- **Format**: `snake_case` uniquement
- **Préfixe**: `workout_`, `nutrition_`, `cardio_`, `settings_`, etc.
- **Éviter**: `_btn`, `_text`, `_label` si inutile
- **Base**: Utiliser l'anglais pour créer la clé

### 4. EXEMPLES CONCRETS

✅ **BON:**
```dart
// Vérification: "Annuler" existe déjà avec clé "cancel"
// → Utiliser "cancel".tr() (pas créer de nouvelle clé)

// Nouveau texte: "Démarrer l'entraînement"  
// → Créer "workout_start_training"
```

❌ **ÉVITER:**
```dart
// Ne pas créer: "cancel_button", "workout_cancel", "annuler_btn"
// Si "cancel" existe déjà
```

## 🛠️ OUTILS DISPONIBLES

1. **TranslationChecker.findExistingTranslation()** - Vérification automatique
2. **TranslationChecker.findKeysByKeyword()** - Recherche par mot-clé  
3. **TranslationChecker.printAllKeys()** - Liste complète des clés

## 📝 CHECKLIST AVANT AJOUT

- [ ] J'ai vérifié que le texte n'existe pas déjà
- [ ] J'ai vérifié les textes similaires  
- [ ] La clé suit les conventions de nommage
- [ ] Le contexte est approprié (workout_, nutrition_, etc.)
- [ ] Pas de doublon avec les clés existantes

## 🎯 OBJECTIF
**Maintenir la qualité du fichier translations.dart avec ZÉRO doublon**