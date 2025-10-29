# 💻 SETUP SUR 2ÈME PC

## Après `git pull` sur votre 2ème PC

Les fichiers `.env.local` et `.env.production` ne seront **pas** dans le repo (pour sécurité).

Voici comment les recréer :

---

## 🔧 Étape 1 : Créer .env.local

```bash
# Copier le template
cp .env.example .env.local
```

Puis **éditer** `.env.local` et **remplacer** ces lignes :

```bash
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo

GEMINI_API_KEY=AIzaSyAQDTnQpN7h7p7pFKti-JFhKgJ5kOo-7Gw

GOOGLE_VISION_API_KEY=AIzaSyAQDTnQpN7h7p7pFKti-JFhKgJ5kOo-7Gw
```

**Le reste** peut rester tel quel (OAuth, etc.)

---

## 🔧 Étape 2 : Créer .env.production

```bash
# Copier .env.local
cp .env.local .env.production
```

Puis **éditer** `.env.production` et **changer** ces lignes :

```bash
ENVIRONMENT=production
TEST_MODE=false
ENABLE_DEBUG_LOGS=false
```

---

## ✅ Étape 3 : Tester

```bash
flutter clean
flutter pub get
flutter run --dart-define-from-file=.env.local
```

Vous devriez voir dans les logs :
```
🔧 Environment Configuration:
  Supabase Key: ✅ eyJhbGci...
  Gemini Key: ✅ AIzaSy...
```

---

## 📋 Fichier Complet .env.local

Si vous préférez copier/coller le fichier entier :

```bash
# ===================================
# RYZE APP - DEVELOPMENT ENVIRONMENT
# ===================================
# ⚠️ CE FICHIER EST IGNORÉ PAR GIT
# Utilisez vos clés de DÉVELOPPEMENT ici
# ===================================

# Supabase Configuration
SUPABASE_URL=https://mfskwlzgxjhhknlwpblq.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo

# Google Gemini AI
GEMINI_API_KEY=AIzaSyAQDTnQpN7h7p7pFKti-JFhKgJ5kOo-7Gw

# Google Cloud Vision API
GOOGLE_VISION_API_KEY=AIzaSyAQDTnQpN7h7p7pFKti-JFhKgJ5kOo-7Gw

# Google OAuth
GOOGLE_CLIENT_ID=992101491811-meask250jrb56gkpmkqkqs4gu3i9isn6.apps.googleusercontent.com
GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.992101491811-meask250jrb56gkpmkqkqs4gu3i9isn6

# Apple OAuth
APPLE_CLIENT_ID=com.BadisG.ryzeApp

# Environment
ENVIRONMENT=development
TEST_MODE=true
ENABLE_DEBUG_LOGS=true
```

---

## 📋 Fichier Complet .env.production

```bash
# ===================================
# RYZE APP - PRODUCTION ENVIRONMENT
# ===================================
# ⚠️ CE FICHIER EST IGNORÉ PAR GIT
# Utilisez vos clés de PRODUCTION ici
# ===================================

# Supabase Configuration (PRODUCTION)
SUPABASE_URL=https://mfskwlzgxjhhknlwpblq.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo

# Google Gemini AI (PRODUCTION)
GEMINI_API_KEY=AIzaSyAQDTnQpN7h7p7pFKti-JFhKgJ5kOo-7Gw

# Google Cloud Vision API (PRODUCTION)
GOOGLE_VISION_API_KEY=AIzaSyAQDTnQpN7h7p7pFKti-JFhKgJ5kOo-7Gw

# Google OAuth (PRODUCTION)
GOOGLE_CLIENT_ID=992101491811-meask250jrb56gkpmkqkqs4gu3i9isn6.apps.googleusercontent.com
GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.992101491811-meask250jrb56gkpmkqkqs4gu3i9isn6

# Apple OAuth
APPLE_CLIENT_ID=com.BadisG.ryzeApp

# Environment (PRODUCTION)
ENVIRONMENT=production
TEST_MODE=false
ENABLE_DEBUG_LOGS=false
```

---

## 💡 Astuce

**Sauvegardez ce fichier quelque part de sûr** (1Password, USB, email personnel) pour pouvoir recréer les `.env` facilement sur n'importe quel PC.

---

**Date** : 29 octobre 2025
**Note** : Ces clés sont les ANCIENNES clés (exposées). Elles fonctionnent mais devront être révoquées avant l'App Store.
