# 🔧 Fix: Extraction du Nom depuis Social Login (Google & Apple)

## 📋 Problème Identifié

Avant ce fix, lorsqu'un utilisateur se connectait via Google ou Apple Sign-In :
- ❌ Le nom n'était **jamais extrait** depuis le provider
- ❌ L'utilisateur se retrouvait avec `firstName: "User"` et `lastName: ""`
- ❌ Aucune personnalisation possible dans l'app

## ✅ Solution Implémentée

### 1. **Extraction du nom depuis Google** ([auth_service.dart:236-265](lib/services/auth_service.dart#L236-L265))

```dart
// Extraire le nom depuis Google (si disponible)
String? firstName;
String? lastName;

if (googleUser.displayName != null && googleUser.displayName!.isNotEmpty) {
  final nameParts = googleUser.displayName!.split(' ');
  firstName = nameParts.first;
  if (nameParts.length > 1) {
    lastName = nameParts.sublist(1).join(' ');
  }
  debugPrint('📝 Google name extracted: $firstName $lastName');
}
```

**Comment ça marche:**
- Récupère `googleUser.displayName` (ex: "John Doe")
- Split par espace → `["John", "Doe"]`
- Premier élément = prénom, reste = nom de famille

### 2. **Extraction du nom depuis Apple** ([auth_service.dart:308-337](lib/services/auth_service.dart#L308-L337))

```dart
// Extraire le nom depuis Apple (si disponible)
// IMPORTANT: Apple ne donne le nom QU'À LA PREMIÈRE connexion !
String? firstName;
String? lastName;

if (credential.givenName != null && credential.givenName!.isNotEmpty) {
  firstName = credential.givenName;
}
if (credential.familyName != null && credential.familyName!.isNotEmpty) {
  lastName = credential.familyName;
}
```

**⚠️ IMPORTANT - Spécificité Apple:**
- Apple ne donne le nom **QU'À LA PREMIÈRE** connexion
- Aux connexions suivantes: `givenName` et `familyName` = `null`
- C'est pourquoi on vérifie toujours si le nom existe déjà en base

### 3. **Mise à jour intelligente du profil** ([auth_service.dart:548-574](lib/services/auth_service.dart#L548-L574))

```dart
// Mettre à jour le profil avec le nom si disponible et si pas déjà renseigné
if (firstName != null && _currentUser != null) {
  final needsUpdate = _currentUser!.firstName.isEmpty ||
                     _currentUser!.firstName == 'User' ||
                     _currentUser!.lastName.isEmpty;

  if (needsUpdate) {
    await _updateUserNameFromSocial(userId, firstName, lastName ?? '');
  }
}
```

**Logique:**
- ✅ Met à jour **SEULEMENT** si le nom est manquant ou générique ("User")
- ✅ Ne touche **PAS** à un nom déjà personnalisé par l'utilisateur
- ✅ Sauvegarde en base de données Supabase

### 4. **Écran de complétion du profil** ([complete_profile_screen.dart](lib/screens/auth/complete_profile_screen.dart))

Si malgré tout le nom n'a pas pu être récupéré (cas Apple après la 1ère connexion, ou provider sans nom):

```dart
/// Vérifie si l'utilisateur a un nom complet
bool get hasCompleteName {
  if (_currentUser == null) return false;
  return _currentUser!.firstName.isNotEmpty &&
         _currentUser!.firstName != 'User' &&
         _currentUser!.lastName.isNotEmpty;
}
```

**Flow:**
1. Login social réussit
2. `RyzeApp` vérifie `authService.hasCompleteName`
3. Si `false` → Affiche `CompleteProfileScreen`
4. L'utilisateur entre manuellement son nom
5. Continue vers l'onboarding ou l'app

### 5. **Intégration dans le flow** ([ryze_app.dart:59-72](lib/pages/ryze_app.dart#L59-L72))

```dart
// Vérifier si l'utilisateur a un nom complet
final authService = Provider.of<AuthService>(context, listen: false);
final hasCompleteName = authService.hasCompleteName;

// Si pas de nom complet → écran de complétion de profil
if (!hasCompleteName) {
  debugPrint('⚠️ Nom manquant → CompleteProfileScreen');
  targetScreen = CompleteProfileScreen(
    onComplete: () {
      // Après avoir complété le nom, redéterminer le routing
      _determineInitialRoute();
    },
  );
}
```

## 📊 Nouveau Flow Complet

```
SOCIAL LOGIN (Google/Apple)
├─ Extraction du nom depuis le provider
│  ├─ Google: displayName → split en firstName/lastName
│  └─ Apple: givenName + familyName (seulement 1ère fois)
│
├─ Mise à jour automatique en base SI nom manquant
│
├─ Vérification: hasCompleteName ?
│  ├─ OUI → Continue vers onboarding ou app
│  └─ NON → CompleteProfileScreen
│     └─ L'utilisateur entre son nom
│        └─ Continue vers onboarding ou app
```

## 🧪 Comment Tester

### Test 1: Google Sign-In (première fois)
1. Supprimer l'app de l'émulateur
2. Lancer l'app
3. Créer un nouveau compte via Google
4. ✅ **Attendu**: Le nom depuis Google doit être automatiquement extrait et sauvegardé
5. Vérifier dans Settings → Le nom doit s'afficher

### Test 2: Apple Sign-In (première fois)
1. Supprimer l'app de l'émulateur
2. Révoquer l'accès Ryze depuis les Settings iOS → Apple ID → Sign in with Apple
3. Lancer l'app
4. Créer un nouveau compte via Apple
5. Apple va demander: "Share My Email" et "Edit Name"
6. ✅ **Attendu**: Le nom entré doit être extrait et sauvegardé
7. Vérifier dans Settings → Le nom doit s'afficher

### Test 3: Apple Sign-In (reconnexion)
1. Se déconnecter de l'app
2. Se reconnecter avec Apple
3. ⚠️ Apple ne redonne **PAS** le nom
4. ✅ **Attendu**: Le nom reste celui sauvegardé en base

### Test 4: Nom manquant (fallback)
1. Pour simuler un nom manquant:
   - Supprimer manuellement le nom en base Supabase
   - Ou utiliser un provider sans nom
2. Se connecter
3. ✅ **Attendu**: `CompleteProfileScreen` s'affiche
4. Entrer prénom + nom
5. ✅ **Attendu**: Redirection vers onboarding/app

### Test 5: Vérifier la base de données
```sql
-- Vérifier que les noms sont bien sauvegardés
SELECT id, email, first_name, last_name, created_at
FROM users
WHERE email = 'votre-email@gmail.com';
```

## 📝 Fichiers Modifiés

1. **[lib/services/auth_service.dart](lib/services/auth_service.dart)**
   - Ligne 236-265: Extraction nom Google
   - Ligne 308-337: Extraction nom Apple
   - Ligne 548-574: Méthode `_updateUserNameFromSocial`
   - Ligne 576-582: Getter `hasCompleteName`

2. **[lib/screens/auth/complete_profile_screen.dart](lib/screens/auth/complete_profile_screen.dart)** (NOUVEAU)
   - Écran de complétion du profil si nom manquant

3. **[lib/pages/ryze_app.dart](lib/pages/ryze_app.dart)**
   - Ligne 59-72: Vérification `hasCompleteName` dans le flow

4. **[lib/services/translations.dart](lib/services/translations.dart)**
   - Ligne 1891-1902: Traductions pour `CompleteProfileScreen`

## 🚨 Points d'Attention

### Apple Sign-In
- ⚠️ **Apple ne donne le nom QU'À LA PREMIÈRE connexion**
- Après, `givenName` et `familyName` sont `null`
- C'est NORMAL et par design d'Apple
- On sauvegarde donc le nom dès la 1ère connexion

### Google Sign-In
- ✅ Google donne toujours le `displayName` à chaque connexion
- Mais on ne met à jour QUE si le nom est manquant (pour respecter les modifications manuelles)

### Privacy
- ❌ Ne JAMAIS écraser un nom déjà personnalisé
- ✅ Seulement mettre à jour si vide ou "User"

## 🎯 Résultat Final

✅ **Utilisateur Google** → Nom automatiquement extrait et sauvegardé
✅ **Utilisateur Apple (1ère fois)** → Nom extrait et sauvegardé
✅ **Utilisateur Apple (reconnexion)** → Nom déjà en base, pas touché
✅ **Nom manquant** → Écran de complétion affiché
✅ **Personnalisation** → Nom utilisé dans toute l'app (salutations, coach, etc.)

## 📱 Experience Utilisateur

### Avant le fix:
```
Login Google → "Bonjour User !" 😞
```

### Après le fix:
```
Login Google → "Bonjour John Doe !" 😊
```

---

**Date du fix**: 2025-01-29
**Testé sur**: iOS Simulator
**Status**: ✅ Ready to test
