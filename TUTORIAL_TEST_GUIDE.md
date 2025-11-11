# 🧪 Guide de Test du Système de Tutoriel

## 📋 Objectif

Vérifier que le système de tutoriel fonctionne correctement et qu'un utilisateur **ne voit pas 2 fois** le même tutoriel.

---

## ⚙️ Prérequis

1. ✅ Migration appliquée dans Supabase
   ```bash
   supabase db push
   ```

2. ✅ Mode debug désactivé dans [`lib/services/tutorial_service.dart:17`](lib/services/tutorial_service.dart#L17)
   ```dart
   static const bool _debugMode = false; // ✅ Mode production
   ```

3. ✅ App compilée en mode debug sur un appareil réel ou simulateur
   ```bash
   flutter run --dart-define-from-file=.env.local
   ```

---

## 🧪 Test 1 : Premier Lancement (Nouvel Utilisateur)

### Étapes

1. **Créer un nouveau compte** ou **se connecter** avec un compte qui n'a jamais vu le tutoriel

2. **Observer l'écran de bienvenue**
   - ✅ L'écran "Coach Ryze" avec le panda doit s'afficher
   - ✅ Message de bienvenue personnalisé avec le prénom de l'utilisateur
   - ✅ Deux boutons : "Commencer le tour" et "Passer"

3. **Appuyer sur "Commencer le tour"**
   - ✅ Le tutoriel interactif doit commencer
   - ✅ 7 étapes doivent s'afficher séquentiellement :
     1. Bouton "Ajouter aliment"
     2. Bouton "Ajouter exercice"
     3. Bouton "Ajouter eau"
     4. Carte des calories
     5. Onglet Nutrition
     6. Onglet Sport
     7. Onglet Progression

4. **Compléter toutes les étapes** en cliquant sur "Compris" à chaque fois

5. **Vérifier les logs dans la console**
   ```
   ✅ Tutorial marqué comme complété localement: tutorial_dashboard_completed
   ✅ Tutorial marqué comme complété dans Supabase: tutorial_dashboard_completed
   ```

### Résultat Attendu

✅ Le tutoriel s'affiche correctement
✅ Les logs confirment la sauvegarde

---

## 🧪 Test 2 : Deuxième Lancement (Vérification de Non-Duplication)

### Étapes

1. **Fermer complètement l'app** (kill process)
   ```bash
   # iOS Simulator
   Cmd + Shift + H + H → Swipe up

   # Android
   Recent apps → Swipe up

   # OU
   flutter run --dart-define-from-file=.env.local
   ```

2. **Relancer l'app** avec le même compte

3. **Observer le dashboard principal**
   - ✅ Le tutoriel **NE doit PAS** s'afficher
   - ✅ Vous devez arriver directement sur le dashboard
   - ✅ Pas d'écran de bienvenue

4. **Vérifier les logs dans la console**
   ```
   ℹ️ Tutorial Dashboard déjà complété
   ```

### Résultat Attendu

✅ Le tutoriel ne s'affiche PAS (pas de double affichage)
✅ Les logs confirment qu'il est déjà complété

---

## 🧪 Test 3 : Synchronisation Cross-Device (Optionnel)

### Étapes

1. **Compléter le tutoriel sur l'iPhone** (ou simulateur iOS)
   - ✅ Tutoriel s'affiche et se complète

2. **Se connecter avec le MÊME compte sur iPad** (ou autre appareil)

3. **Observer le dashboard**
   - ✅ Le tutoriel **NE doit PAS** s'afficher
   - ✅ Synchronisation automatique via Supabase

### Résultat Attendu

✅ Le tutoriel ne s'affiche pas sur le 2ème appareil
✅ Supabase fonctionne comme source de vérité

---

## 🧪 Test 4 : Mode Offline (Fallback SharedPreferences)

### Étapes

1. **Compléter le tutoriel** avec une connexion internet active

2. **Activer le mode avion** (désactiver WiFi + données mobiles)

3. **Fermer et relancer l'app**

4. **Observer le dashboard**
   - ✅ Le tutoriel **NE doit PAS** s'afficher
   - ✅ Fallback vers SharedPreferences

5. **Vérifier les logs**
   ```
   ⚠️ Erreur lecture tutorial depuis Supabase: [timeout/network error]
   ℹ️ Tutorial Dashboard déjà complété (via SharedPreferences)
   ```

### Résultat Attendu

✅ Le tutoriel ne s'affiche pas même sans internet
✅ Fallback fonctionne correctement

---

## 🧪 Test 5 : Bouton "Passer" (Skip)

### Étapes

1. **Créer un nouveau compte** ou utiliser un compte test

2. **Observer l'écran de bienvenue**

3. **Appuyer sur "Passer"**
   - ✅ Le tutoriel doit se fermer immédiatement
   - ✅ Pas d'affichage des étapes interactives

4. **Vérifier que l'état est sauvegardé**
   ```
   ⏭️ Tutorial Dashboard skippé depuis le Welcome Screen
   ✅ Tutorial marqué comme complété dans Supabase: tutorial_dashboard_completed
   ```

5. **Relancer l'app**
   - ✅ Le tutoriel **NE doit PAS** s'afficher

### Résultat Attendu

✅ Skip sauvegarde l'état comme "complété"
✅ Pas de réaffichage au prochain lancement

---

## 🧪 Test 6 : Vérification Base de Données

### Étapes

1. **Se connecter au Dashboard Supabase**
   - URL : https://supabase.com/dashboard
   - Projet : Ryse App

2. **Ouvrir le SQL Editor**

3. **Exécuter le script de vérification**
   ```sql
   -- Copier/coller le contenu de supabase/verify_tutorial_status.sql
   ```

4. **Observer les résultats**
   - ✅ 6 colonnes `tutorial_*` doivent exister
   - ✅ Les statistiques doivent afficher les utilisateurs avec tutoriels complétés

### Résultat Attendu

✅ Les colonnes existent dans la table `users`
✅ Les valeurs `TRUE` correspondent aux utilisateurs testés

---

## 🐛 Debugging : Problèmes Courants

### Problème 1 : Le tutoriel s'affiche à chaque lancement

**Symptôme** : Le tutoriel se relance même après avoir été complété

**Causes possibles** :
1. ❌ Mode debug activé (`_debugMode = true`)
2. ❌ Migration non appliquée (colonnes manquantes)
3. ❌ SharedPreferences effacées (désinstall/reinstall app)

**Solution** :
```dart
// Vérifier tutorial_service.dart:17
static const bool _debugMode = false; // ✅ Doit être false
```

```bash
# Appliquer la migration
supabase db push
```

```sql
-- Vérifier dans SQL Editor
SELECT tutorial_dashboard_completed
FROM users
WHERE email = 'votre.email@test.com';
```

---

### Problème 2 : Erreur "Column does not exist"

**Symptôme** : Log d'erreur dans la console
```
❌ Erreur sauvegarde tutorial dans Supabase: Column "tutorial_dashboard_completed" does not exist
```

**Cause** : Migration non appliquée

**Solution** :
```bash
# Appliquer la migration
supabase db push

# OU si lié à un projet distant
supabase db remote commit
```

---

### Problème 3 : Le tutoriel ne s'affiche jamais (même pour un nouvel utilisateur)

**Symptôme** : Aucun tutoriel ne s'affiche, même pour un compte fraîchement créé

**Causes possibles** :
1. ❌ `showDashboardTutorial()` n'est pas appelé
2. ❌ Les GlobalKeys ne sont pas montées
3. ❌ Context démonté trop tôt

**Solution** :
```dart
// Vérifier main_dashboard_hybrid.dart:75-78
WidgetsBinding.instance.addPostFrameCallback((_) {
  _showDashboardTutorial(); // ✅ Doit être appelé
});
```

**Debug** :
```dart
// Ajouter des logs dans tutorial_service.dart:265
Future<void> showDashboardTutorial({...}) async {
  debugPrint('🚀 showDashboardTutorial appelé');

  if (await _isTutorialCompleted(_dashboardTutorialKey)) {
    debugPrint('ℹ️ Tutorial Dashboard déjà complété');
    return;
  }

  debugPrint('✅ Tutorial va s\'afficher');
  // ...
}
```

---

## 📊 Checklist Finale

Avant de déployer en production, vérifier :

- [ ] ✅ Migration appliquée (`supabase db push`)
- [ ] ✅ Mode debug désactivé (`_debugMode = false`)
- [ ] ✅ Test 1 : Tutoriel s'affiche au premier lancement
- [ ] ✅ Test 2 : Tutoriel ne s'affiche PAS au deuxième lancement
- [ ] ✅ Test 3 : Synchronisation cross-device fonctionne
- [ ] ✅ Test 4 : Mode offline fonctionne (fallback)
- [ ] ✅ Test 5 : Bouton "Passer" sauvegarde l'état
- [ ] ✅ Test 6 : Base de données Supabase correctement mise à jour
- [ ] ✅ Logs confirment le comportement attendu
- [ ] ✅ Décision prise pour les utilisateurs existants (voir migration SQL ligne 32-44)

---

## 📝 Rapport de Test

**Testeur** : _____________
**Date** : _____________
**Version de l'app** : _____________
**Plateforme** : iOS / Android / Les deux

| Test | Statut | Commentaires |
|------|--------|-------------|
| Test 1 : Premier lancement | ✅ / ❌ | |
| Test 2 : Deuxième lancement | ✅ / ❌ | |
| Test 3 : Cross-device | ✅ / ❌ / N/A | |
| Test 4 : Mode offline | ✅ / ❌ | |
| Test 5 : Skip | ✅ / ❌ | |
| Test 6 : Base de données | ✅ / ❌ | |

---

**Résultat global** : ✅ VALIDÉ / ❌ À CORRIGER

**Notes supplémentaires** :

_________________________________________________________________

_________________________________________________________________

_________________________________________________________________

---

**Fichiers de référence** :
- [`TUTORIAL_STATUS_VERIFICATION.md`](TUTORIAL_STATUS_VERIFICATION.md) - Analyse technique
- [`TUTORIAL_README.md`](TUTORIAL_README.md) - Documentation du système
- [`lib/services/tutorial_service.dart`](lib/services/tutorial_service.dart) - Code source
