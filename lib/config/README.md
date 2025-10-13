# Configuration des API Keys

⚠️ **IMPORTANT** : Ne jamais commit les fichiers de configuration contenant des clés API réelles !

## Setup Initial

1. **Copier les fichiers templates :**
   ```bash
   cp lib/config/gemini_config.dart.example lib/config/gemini_config.dart
   cp lib/config/google_vision_config.dart.example lib/config/google_vision_config.dart
   ```

2. **Obtenir les clés API :**

   ### Gemini API Key
   - Va sur : https://aistudio.google.com/app/apikey
   - Crée une nouvelle clé API
   - Copie la clé

   ### Google Cloud Vision API Key
   - Va sur : https://console.cloud.google.com/apis/credentials
   - Crée une nouvelle clé API
   - Active l'API Cloud Vision
   - Copie la clé

3. **Configurer les fichiers :**
   - Ouvre `lib/config/gemini_config.dart`
   - Remplace `YOUR_GEMINI_API_KEY_HERE` par ta vraie clé Gemini
   - Ouvre `lib/config/google_vision_config.dart`
   - Remplace `YOUR_GOOGLE_CLOUD_API_KEY_HERE` par ta vraie clé Google Cloud

## Sécurité

Les fichiers suivants sont automatiquement ignorés par git (`.gitignore`) :
- `lib/config/gemini_config.dart`
- `lib/config/google_vision_config.dart`
- `lib/config/supabase_config.dart`

✅ Les fichiers `.example` sont versionnés et servent de templates
❌ Les fichiers réels avec les vraies clés ne sont JAMAIS versionnés

## Si une clé a été exposée

1. **Révoquer immédiatement** la clé sur la console Google
2. **Générer une nouvelle clé**
3. **Nettoyer l'historique git** :
   ```bash
   # Option 1 : Utiliser BFG Repo-Cleaner (recommandé)
   brew install bfg
   bfg --replace-text passwords.txt
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive

   # Option 2 : Utiliser git-filter-repo
   pip install git-filter-repo
   git filter-repo --replace-text passwords.txt

   # Option 3 : Force push sur une nouvelle branche
   git checkout --orphan new-clean-branch
   git add -A
   git commit -m "Initial commit with cleaned history"
   git branch -D main
   git branch -m main
   git push -f origin main
   ```

## Vérification

Avant de commit, vérifie toujours :
```bash
# Vérifier qu'aucune clé n'est présente
git diff | grep -i "AIzaSy"

# Vérifier les fichiers stagés
git status
```
