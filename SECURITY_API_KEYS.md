# 🔒 Guide de Sécurité - Clés API

## ⚠️ PROBLÈME : Clé API Gemini Leakée

**Erreur reçue** :
```
Your API key was reported as leaked. Please use another API key.
```

Cette erreur signifie que votre clé API Gemini a été détectée comme compromise (probablement parce qu'elle a été commitée dans Git).

---

## 🚨 SOLUTION IMMÉDIATE

### 1️⃣ Générer une Nouvelle Clé API Gemini

**Action à faire MAINTENANT** :

1. Allez sur [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Connectez-vous avec votre compte Google
3. **Supprimez l'ancienne clé compromise** (celle qui a fuité)
4. Cliquez sur "Create API Key"
5. Sélectionnez votre projet Google Cloud
6. Copiez la nouvelle clé (elle commence par `AIza...`)

### 2️⃣ Configurer la Nouvelle Clé de Manière Sécurisée

**IMPORTANT** : Ne collez JAMAIS la clé directement dans le code !

#### Option A : Utiliser `.env.local` (Recommandé pour le développement)

1. Ouvrez le fichier `.env.local` à la racine du projet
2. Remplacez la ligne `GEMINI_API_KEY=...` avec votre nouvelle clé :

```bash
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

3. Sauvegardez le fichier
4. **VÉRIFIEZ** que `.env.local` est bien dans `.gitignore`

#### Option B : Ligne de Commande (Pour des tests ponctuels)

```bash
flutter run --dart-define-from-file=.env.local
```

### 3️⃣ Tester la Configuration

```bash
# Lancer l'app en mode développement
flutter run --dart-define-from-file=.env.local

# L'app devrait afficher dans les logs :
# 🔧 Environment Configuration:
#   Gemini Key: ✅ AIzaSyXX...XXXX
```

---

## 🛡️ PRÉVENTION - Ne Plus Jamais Leak de Clés

### ✅ CE QUI EST DÉJÀ SÉCURISÉ

Votre projet a déjà un bon système en place :

1. **EnvConfig** ([lib/config/env_config.dart](lib/config/env_config.dart))
   - Charge les clés depuis les variables d'environnement
   - Masque les secrets dans les logs
   - Valide la configuration au démarrage

2. **GeminiConfig** ([lib/config/gemini_config.dart](lib/config/gemini_config.dart))
   - Utilise `EnvConfig.geminiApiKey` (pas de clé hardcodée)

3. **`.gitignore`**
   - `.env.local` et `.env.production` sont ignorés

### ⚠️ RÈGLES À SUIVRE ABSOLUMENT

#### 🚫 NE JAMAIS FAIRE

```dart
// ❌ JAMAIS ça !
static const String geminiApiKey = 'AIzaSyXXXXXXXXXXXX';

// ❌ JAMAIS ça non plus !
final apiKey = 'AIzaSyXXXXXXXXXXXX';
```

#### ✅ TOUJOURS FAIRE

```dart
// ✅ Toujours via EnvConfig
static String get geminiApiKey => EnvConfig.geminiApiKey;

// ✅ Ou via String.fromEnvironment
static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
```

### 📋 Checklist de Sécurité

Avant chaque commit, vérifiez :

- [ ] Aucune clé API dans le code source
- [ ] `.env.local` et `.env.production` dans `.gitignore`
- [ ] Pas de fichier `API_KEYS_BACKUP.txt` ou similaire committé
- [ ] Utilisez `git diff` pour vérifier les changements avant le commit

### 🔍 Vérification Automatique

Ajoutez cette commande avant chaque commit :

```bash
# Rechercher des clés API dans le code
grep -r "AIza" lib/ --exclude-dir=node_modules
grep -r "GEMINI_API_KEY.*=.*AIza" . --exclude-dir=node_modules
```

Si cette commande trouve quelque chose, **NE COMMITEZ PAS** !

---

## 🔄 Workflow de Développement

### Développement Local

```bash
# 1. Créer .env.local (si pas déjà fait)
cp .env.example .env.local

# 2. Ajouter vos vraies clés dans .env.local
nano .env.local

# 3. Lancer l'app
flutter run --dart-define-from-file=.env.local
```

### Build de Production

```bash
# 1. Créer .env.production avec les clés de production
nano .env.production

# 2. Build avec les variables de production
flutter build apk --dart-define-from-file=.env.production
flutter build ios --dart-define-from-file=.env.production
```

### CI/CD (GitHub Actions, etc.)

Les clés doivent être stockées dans les **Secrets** de votre plateforme CI/CD :

```yaml
# .github/workflows/build.yml
- name: Create .env.production
  run: |
    echo "GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}" >> .env.production
    echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> .env.production
    # ... autres variables
```

---

## 📝 Fichiers de Configuration

### Fichiers à Commiter (Safe)

✅ Ces fichiers **peuvent** être commitéss dans Git :

- `.env.example` - Template avec des valeurs fictives
- `lib/config/env_config.dart` - Code de configuration
- `lib/config/gemini_config.dart` - Configuration Gemini
- `.gitignore` - Règles d'exclusion

### Fichiers à NE JAMAIS Commiter

🚫 Ces fichiers **NE DOIVENT JAMAIS** être dans Git :

- `.env` - Variables d'environnement
- `.env.local` - Variables de développement local
- `.env.production` - Variables de production
- `.env.staging` - Variables de staging
- `API_KEYS_BACKUP.txt` - Backup de clés (à supprimer)

---

## 🆘 En Cas de Leak Détecté

Si Google détecte une clé leakée :

1. **Révoquer immédiatement** la clé compromise sur [Google AI Studio](https://aistudio.google.com/app/apikey)
2. **Générer une nouvelle clé** (voir section 1️⃣)
3. **Chercher où la clé a fuité** :
   ```bash
   git log -S "AIzaSy" --all --source --full-history
   ```
4. **Nettoyer l'historique Git** (si nécessaire) :
   ```bash
   # ⚠️ DANGEREUX - Réécrit l'historique Git
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch .env.local .env.production' \
     --prune-empty --tag-name-filter cat -- --all
   ```
5. **Force push** (si le repo est public) :
   ```bash
   git push origin --force --all
   ```

---

## 📚 Ressources

- [Google AI Studio](https://aistudio.google.com/app/apikey) - Gestion des clés Gemini
- [Supabase Dashboard](https://supabase.com/dashboard) - Clés Supabase
- [Google Cloud Console](https://console.cloud.google.com/) - API Google Vision
- [Flutter Environment Variables](https://docs.flutter.dev/deployment/flavors#using-environment-variables) - Documentation officielle

---

## ✅ Validation Finale

Après avoir suivi ce guide, testez :

```bash
# 1. Vérifier que les clés ne sont pas dans le code
grep -r "AIza" lib/

# 2. Vérifier que .env.local est gitignored
git check-ignore .env.local
# Doit afficher : .env.local

# 3. Lancer l'app
flutter run --dart-define-from-file=.env.local

# 4. Vérifier que Gemini fonctionne
# Allez dans l'app > Scanner AI > Prenez une photo de nourriture
```

---

## 🎯 Résumé

**Pour éviter que ça arrive à nouveau** :

1. ✅ Utilisez **toujours** `.env.local` pour les clés
2. ✅ **Vérifiez** que `.env.local` est dans `.gitignore`
3. ✅ **Ne commitez JAMAIS** de fichiers contenant des clés réelles
4. ✅ **Utilisez** `EnvConfig` pour accéder aux clés
5. ✅ **Révoquez immédiatement** toute clé compromise

**Commandes essentielles** :

```bash
# Développement
flutter run --dart-define-from-file=.env.local

# Production
flutter build ios --dart-define-from-file=.env.production

# Vérification
grep -r "AIza" lib/
git check-ignore .env.local
```

---

**Dernière mise à jour** : 2025-02-02
