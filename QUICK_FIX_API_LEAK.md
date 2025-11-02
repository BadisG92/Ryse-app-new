# 🚨 FIX RAPIDE - Clé API Gemini Leakée

## ⚡ Actions IMMÉDIATES (5 minutes)

### 1. Révoquer la clé compromise

1. Allez sur [Google AI Studio](https://aistudio.google.com/app/apikey)
2. **Supprimez** l'ancienne clé (celle qui a fuité)
3. Cliquez sur **"Create API Key"**
4. Copiez la nouvelle clé (commence par `AIza...`)

### 2. Mettre à jour `.env.local`

```bash
# Ouvrir le fichier
nano .env.local

# Remplacer la ligne (utilisez votre NOUVELLE clé) :
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Sauvegarder : Ctrl+O puis Entrée, puis Ctrl+X
```

### 3. Tester

```bash
# Vérifier la sécurité
./check_api_keys.sh

# Lancer l'app
flutter run --dart-define-from-file=.env.local

# Tester le scanner AI
# Allez dans l'app > Scanner AI > Prenez une photo
```

---

## ✅ C'est fait !

Votre nouvelle clé fonctionne maintenant.

---

## 🛡️ Prévention Automatique

Le projet a maintenant :

✅ **Git Hook** : Vérifie automatiquement avant chaque commit
✅ **Script de vérification** : `./check_api_keys.sh`
✅ **`.gitignore`** renforcé : Bloque tous les fichiers `.env`
✅ **Documentation** : `SECURITY_API_KEYS.md`

**Le hook Git bloquera automatiquement tout commit contenant des clés !**

---

## 📋 Commandes Utiles

```bash
# Vérifier la sécurité
./check_api_keys.sh

# Développement
flutter run --dart-define-from-file=.env.local

# Production
flutter build ios --dart-define-from-file=.env.production

# Vérifier que .env.local est gitignored
git check-ignore .env.local
# Doit afficher : .env.local
```

---

## 🆘 En cas de problème

### L'erreur persiste ?

1. Vérifiez que vous avez bien mis la **NOUVELLE** clé dans `.env.local`
2. Redémarrez complètement Flutter : `flutter clean && flutter pub get`
3. Tuez toutes les instances : `killall -9 dart`
4. Relancez : `flutter run --dart-define-from-file=.env.local`

### La clé ne fonctionne toujours pas ?

- Vérifiez que la clé commence bien par `AIza`
- Vérifiez qu'il n'y a pas d'espaces avant/après la clé dans `.env.local`
- Vérifiez que l'API Gemini est activée sur [Google Cloud Console](https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com)

### Besoin d'aide ?

Voir la documentation complète : [SECURITY_API_KEYS.md](SECURITY_API_KEYS.md)

---

**Date de création** : 2025-02-02
**Dernière mise à jour** : 2025-02-02
