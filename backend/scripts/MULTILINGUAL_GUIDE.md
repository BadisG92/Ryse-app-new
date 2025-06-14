# 🌍 Guide Multilingue pour Ryze App

Ce guide explique comment implémenter le support multilingue (français/anglais) dans votre application Ryze.

## 📋 Vue d'ensemble

### 🎯 Objectifs
- Support complet français/anglais
- Structure de base de données optimisée
- Performance maintenue
- Facilité d'ajout de nouvelles langues

### 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────────┐
│   Base Tables   │    │  Translation Tables  │
│                 │    │                      │
│ • foods         │◄──►│ • food_translations  │
│ • exercises     │◄──►│ • exercise_trans...  │
│ • recipes       │◄──►│ • recipe_trans...    │
└─────────────────┘    └──────────────────────┘
```

## 🚀 Étapes d'implémentation

### 1. Configuration de la base de données

```bash
# 1. Exécutez le schéma SQL dans Supabase
# Copiez le contenu de multilingual_schema.sql dans l'éditeur SQL Supabase
```

### 2. Structure des données

#### 📊 Tables principales
- **foods** : Données nutritionnelles (indépendantes de la langue)
- **food_translations** : Noms et catégories traduits
- **exercises** : Métriques d'exercices (indépendantes de la langue)
- **exercise_translations** : Instructions et descriptions traduites
- **recipes** : Données nutritionnelles des recettes
- **recipe_translations** : Instructions et descriptions traduites

#### 🔑 Tables de support
- **translation_keys** : Clés de traduction pour l'UI
- **user_preferences** : Préférences linguistiques des utilisateurs

### 3. Import des données

```bash
# Configurez vos credentials Supabase
nano multilingual_import.py
# Modifiez SUPABASE_URL et SUPABASE_KEY

# Installez les dépendances
pip install supabase

# Lancez l'import
python multilingual_import.py
```

## 📱 Implémentation côté Flutter

### 1. Configuration de l'internationalisation

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

### 2. Service de localisation

```dart
// lib/services/localization_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalizationService {
  static Future<String> getUserLanguage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('user_preferences')
          .select('language')
          .eq('user_id', user.id)
          .maybeSingle();
      
      return response?['language'] ?? 'en';
    }
    return 'en';
  }
  
  static Future<void> setUserLanguage(String language) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('user_preferences')
          .upsert({
            'user_id': user.id,
            'language': language,
          });
    }
  }
}
```

## 🎉 Résultat final

Votre application Ryze supportera maintenant :
- ✅ Interface utilisateur en français/anglais
- ✅ Données d'aliments traduites
- ✅ Instructions d'exercices dans les deux langues
- ✅ Recettes avec instructions localisées
- ✅ Préférences utilisateur sauvegardées
- ✅ Performance optimisée
- ✅ Facilité d'ajout de nouvelles langues

🌍 **Votre app est maintenant prête pour un public international !** 