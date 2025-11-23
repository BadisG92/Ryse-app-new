# Edge Function: delete-user

## Description
Cette Edge Function supprime complètement un compte utilisateur de Supabase, incluant :
- Les données dans `public.users` (avec CASCADE sur toutes les tables liées)
- Le compte d'authentification dans `auth.users`

## Pourquoi une Edge Function ?
Le client Flutter ne peut pas supprimer directement de `auth.users` car cela nécessite la clé `service_role` (admin).
Seule une Edge Function côté serveur peut utiliser l'API admin de Supabase Auth.

## Déploiement

### Prérequis
```bash
# Installer Supabase CLI
npm install -g supabase

# Se connecter
supabase login
```

### Déployer la fonction
```bash
# Depuis la racine du projet
cd /Users/badis/Documents/Ryse-app-new

# Lier au projet (si pas déjà fait)
supabase link --project-ref mfskwlzgxjhhknlwpblq

# Déployer la fonction
supabase functions deploy delete-user
```

### Vérifier le déploiement
```bash
supabase functions list
```

## Configuration requise

La fonction utilise automatiquement les variables d'environnement Supabase :
- `SUPABASE_URL` - URL du projet
- `SUPABASE_SERVICE_ROLE_KEY` - Clé admin (ne jamais exposer côté client !)

Ces variables sont automatiquement disponibles dans les Edge Functions.

## Sécurité

1. **Authentification requise** : L'utilisateur doit être connecté et envoyer son JWT token
2. **Auto-suppression uniquement** : Un utilisateur ne peut supprimer que son propre compte
3. **Pas d'accès à la clé service_role** : La clé admin reste côté serveur

## Utilisation depuis Flutter

```dart
final response = await supabase.functions.invoke(
  'delete-user',
  headers: {
    'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
  },
);

if (response.status == 200) {
  // Compte supprimé avec succès
} else {
  // Erreur
  final error = response.data?['error'];
}
```

## Réponses

### Succès (200)
```json
{
  "success": true,
  "message": "User account completely deleted",
  "userId": "uuid-xxx"
}
```

### Erreur (401 - Non authentifié)
```json
{
  "error": "No authorization header"
}
```

### Erreur (500 - Échec suppression)
```json
{
  "error": "Failed to delete auth user",
  "details": "..."
}
```

## Test manuel

```bash
# Tester avec curl (remplacer les valeurs)
curl -X POST 'https://mfskwlzgxjhhknlwpblq.supabase.co/functions/v1/delete-user' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json'
```

## Logs

Les logs sont disponibles dans le dashboard Supabase :
1. Aller sur https://supabase.com/dashboard
2. Projet > Edge Functions > delete-user > Logs
