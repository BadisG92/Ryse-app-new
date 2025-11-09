# Messages d'erreur d'authentification - Documentation

## Vue d'ensemble

Les messages d'erreur d'authentification ont été refactorisés pour être plus **ludiques**, **clairs** et **conviviaux** ! 🎉

## Changements apportés

### 1. Fonction de traduction intelligente (`_getFriendlyErrorMessage`)

Une nouvelle fonction dans `auth_service.dart` qui convertit automatiquement les erreurs techniques Supabase en messages conviviaux.

**Exemple :**
- ❌ Avant : `Invalid login credentials`
- ✅ Après : `Oups ! Email ou mot de passe incorrect 🤔\nVérifie bien tes identifiants !`

### 2. Nouveaux messages d'erreur

Tous les messages incluent maintenant :
- **Emojis** pour une touche ludique 😊
- **Explications claires** de ce qui s'est passé
- **Actions suggérées** pour résoudre le problème

## Liste complète des messages

### Erreurs de connexion
| Clé | Français | English |
|-----|----------|---------|
| `auth_error_invalid_credentials` | Oups ! Email ou mot de passe incorrect 🤔 | Oops! Wrong email or password 🤔 |
| `auth_error_user_not_found` | On dirait que ce compte n'existe pas encore 🧐 | Looks like this account doesn't exist yet 🧐 |

### Erreurs d'inscription
| Clé | Français | English |
|-----|----------|---------|
| `auth_error_email_already_exists` | Cet email est déjà utilisé 👀 | This email is already in use 👀 |
| `auth_error_weak_password` | Ce mot de passe est trop simple 💪 | This password is too weak 💪 |
| `auth_error_invalid_email` | Cet email ne semble pas valide 📧 | This email doesn't look valid 📧 |

### Erreurs de sécurité
| Clé | Français | English |
|-----|----------|---------|
| `auth_error_too_many_requests` | Wow, doucement ! 🛑 | Whoa, slow down! 🛑 |
| `auth_error_account_disabled` | Ton compte a été désactivé 🔒 | Your account has been disabled 🔒 |
| `auth_error_session_expired` | Ta session a expiré ⏰ | Your session expired ⏰ |

### Erreurs de connexion sociale
| Clé | Français | English |
|-----|----------|---------|
| `auth_error_google_cancelled` | Connexion Google annulée 🚫 | Google sign-in cancelled 🚫 |
| `auth_error_google_failed` | Connexion Google impossible 😅 | Google sign-in failed 😅 |
| `auth_error_apple_cancelled` | Connexion Apple annulée 🍎 | Apple sign-in cancelled 🍎 |
| `auth_error_apple_failed` | Connexion Apple impossible 😅 | Apple sign-in failed 😅 |

### Erreurs réseau
| Clé | Français | English |
|-----|----------|---------|
| `auth_error_network` | Pas de connexion internet 📡 | No internet connection 📡 |
| `auth_error_password_reset_failed` | Impossible d'envoyer l'email de réinitialisation 📨 | Couldn't send reset email 📨 |

### Erreur générique
| Clé | Français | English |
|-----|----------|---------|
| `auth_error_unknown` | Quelque chose s'est mal passé 🤷 | Something went wrong 🤷 |

## Détection automatique des erreurs

La fonction `_getFriendlyErrorMessage` détecte automatiquement le type d'erreur en analysant le message technique :

```dart
// Exemple : mauvais identifiants
if (errorLower.contains('invalid login') ||
    errorLower.contains('invalid credentials') ||
    errorLower.contains('email not confirmed') ||
    errorLower.contains('invalid grant')) {
  return 'auth_error_invalid_credentials';
}
```

## Fichiers modifiés

### Services
- ✅ `lib/services/auth_service.dart` - Ajout de `_getFriendlyErrorMessage()`
- ✅ `lib/services/translations.dart` - Nouveaux messages EN/FR

### Écrans
- ✅ `lib/screens/auth/login_screen.dart` - Affichage des messages traduits
- ✅ `lib/screens/auth/register_screen.dart` - Affichage des messages traduits
- ✅ `lib/screens/auth/forgot_password_screen.dart` - Affichage des messages traduits

## Exemple d'utilisation

Lorsqu'un utilisateur essaie de se connecter avec un mauvais mot de passe :

1. **Supabase** retourne : `AuthException: Invalid login credentials`
2. **`_getFriendlyErrorMessage`** détecte "invalid credentials"
3. **Traduit en** : `auth_error_invalid_credentials`
4. **L'écran affiche** :
   - 🇫🇷 "Oups ! Email ou mot de passe incorrect 🤔\nVérifie bien tes identifiants !"
   - 🇬🇧 "Oops! Wrong email or password 🤔\nDouble-check your credentials!"

## Amélioration de l'UX

### Durée d'affichage
Les snackbars affichent maintenant les erreurs pendant **4 secondes** au lieu de 2, permettant aux utilisateurs de lire le message complet.

### Multi-ligne
Les messages peuvent utiliser `\n` pour afficher des conseils sur plusieurs lignes.

### Ton ludique
Les emojis et le tutoiement créent une ambiance positive et amicale, même en cas d'erreur !

## Tests recommandés

Pour tester tous les cas d'erreur :

1. ❌ **Mauvais identifiants** → `auth_error_invalid_credentials`
2. 📧 **Email invalide** → `auth_error_invalid_email`
3. 🔐 **Mot de passe trop faible** → `auth_error_weak_password`
4. 👤 **Email déjà utilisé** → `auth_error_email_already_exists`
5. 🚫 **Annulation Google/Apple** → `auth_error_google_cancelled` / `auth_error_apple_cancelled`
6. 📡 **Mode avion** → `auth_error_network`
7. 🛑 **Trop de tentatives** → `auth_error_too_many_requests`

---

**Note** : Tous les messages sont disponibles en français et en anglais, avec détection automatique selon la langue de l'app.
