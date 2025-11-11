# 🔧 Configuration Xcode pour les variables d'environnement

## Problème
Xcode ne charge pas automatiquement les variables depuis `.env.local`, donc l'app ne peut pas se connecter à Supabase.

## Solution : Configurer le Build Scheme

### 1. Ouvrir le projet dans Xcode
```bash
open ios/Runner.xcworkspace
```

### 2. Éditer le Scheme
1. **Menu** : Product → Scheme → Edit Scheme...
2. **Ou** : Cliquez sur "Runner" en haut à gauche, puis "Edit Scheme..."

### 3. Ajouter les variables dans Build → Pre-actions

1. Dans la fenêtre Edit Scheme, sélectionnez **"Build"** dans la liste de gauche
2. Cliquez sur **"Pre-actions"** en bas
3. Cliquez sur **"+"** → **"New Run Script Action"**
4. **Provide build settings from** : Runner
5. Dans le script, ajoutez :

```bash
# Exporter les variables depuis .env.local vers Info.plist temporaire
echo "Loading environment variables..."

# Lire .env.local et créer un fichier de configuration temporaire
if [ -f "${PROJECT_DIR}/../.env.local" ]; then
    echo "Found .env.local"
    # Créer un fichier temporaire avec les variables
    cp "${PROJECT_DIR}/../.env.local" "${TEMP_DIR}/env.tmp"
fi
```

### 4. Alternative plus simple : Créer un script de lancement

Créez un fichier `run_ios_xcode.sh` :

```bash
#!/bin/bash
# Script pour lancer depuis Xcode avec les bonnes variables

# Lire les variables depuis .env.local
source .env.local

# Lancer Xcode avec les variables exportées
open ios/Runner.xcworkspace

echo "✅ Xcode ouvert avec les variables d'environnement"
echo "   Maintenant vous pouvez Run (⌘+R) normalement"
```

### 5. Solution immédiate (temporaire)

Modifiez temporairement `lib/config/env_config.dart` pour mettre des valeurs par défaut NON VIDES :

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://mfskwlzgxjhhknlwpblq.supabase.co', // Temporaire pour Xcode
);
```

⚠️ **NE PAS COMMITER cette modification !**

## Pourquoi ça marchait avant ?

Avant, vous aviez probablement :
- Soit des clés hardcodées directement dans le code
- Soit des defaultValue non vides
- Soit un scheme Xcode configuré qui a été perdu

## Recommandation

Pour le développement avec Xcode, utilisez plutôt :
```bash
flutter run --dart-define-from-file=.env.local
```

C'est plus sûr et ça garantit que les variables sont chargées.