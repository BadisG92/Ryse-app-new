# 🔧 Configuration Xcode pour les variables d'environnement

## Pourquoi cette configuration ?
Xcode ne charge pas automatiquement le fichier `.env.local`. Il faut configurer le scheme pour passer les variables.

## Configuration du Scheme Runner

### 1. Ouvrir le projet dans Xcode
```bash
open ios/Runner.xcworkspace
```

### 2. Éditer le Scheme
1. **Menu** : Product → Scheme → Edit Scheme...
2. Ou **Raccourci** : ⌘ + Shift + <

### 3. Ajouter les Arguments
Dans la fenêtre Edit Scheme :

1. **Sélectionnez "Run"** dans la barre latérale gauche
2. **Onglet "Arguments"**
3. **Section "Arguments Passed On Launch"**, ajoutez :
   ```
   --dart-define-from-file=.env.local
   ```

### 4. Alternative : Variables d'environnement directes
Si l'option ci-dessus ne fonctionne pas :

1. **Onglet "Arguments"**
2. **Section "Environment Variables"**, ajoutez manuellement :
   - `SUPABASE_URL` : (votre URL Supabase)
   - `SUPABASE_ANON_KEY` : (votre clé)
   - `GEMINI_API_KEY` : (votre clé)
   - `GOOGLE_VISION_API_KEY` : (votre clé)

⚠️ **ATTENTION** : Cette méthode expose vos clés dans Xcode

## Option Alternative : Script de lancement

Créez un script qui lance l'app avec les bonnes variables :

```bash
#!/bin/bash
# run_ios.sh
flutter run --dart-define-from-file=.env.local
```

## Vérification

Après configuration, l'app devrait afficher :
- ✅ Supabase initialized successfully
- Pas d'erreur "Missing required environment variables"

## Note importante

Les modifications du scheme Xcode sont locales et ne sont pas committées dans Git. Chaque développeur doit configurer son Xcode.