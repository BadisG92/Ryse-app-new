# Guide de Test - Compteur de Pas Corrigé

## 🎯 Objectif du Test
Valider que le nouveau compteur de pas fonctionne correctement avec les 3 modes hiérarchiques.

## 📱 Prérequis

### Matériel Nécessaire
- **iPhone ou Android physique** (le compteur ne fonctionne pas sur simulateur/émulateur)
- Application Ryze installée (mode Debug ou Release)
- Accès à un espace pour marcher (intérieur ou extérieur)

### Préparation
1. Installer l'application sur le téléphone
2. S'assurer que l'application a les permissions nécessaires :
   - iOS : Motion & Fitness (dans Réglages > Confidentialité)
   - Android : Activité physique (dans Paramètres > Applications > Ryze > Autorisations)

## ✅ Scénarios de Test

### Test #1 : Mode STEPS (Pedometer Natif) 🔵

**Objectif** : Valider le compteur de pas natif

#### Étapes
1. Ouvrir l'application Ryze
2. Aller dans la section Cardio
3. Sélectionner "Marche" → "Marche libre"
4. **Vérifier** : Badge bleu **STEPS** avec icône 👣 en haut de l'écran
5. Appuyer sur le bouton ▶️ (Play) pour démarrer
6. **Marcher exactement 100 pas** (compter manuellement)
7. Appuyer sur ⏹️ (Stop)

#### Résultats Attendus
- Badge affiché : **STEPS** (bleu)
- Compteur de pas : **≈ 100 pas** (±5 pas d'erreur acceptable)
- Logs (dans Xcode/Android Studio) :
  ```
  ✅ Pedometer: Disponible et permissions accordées
  ✅ Pedometer: Tracking démarré
  👣 Pedometer: X pas totaux, Y pas cette session
  ```

#### Validation
- ✅ Précision : Écart < 5% (95-105 pas pour 100 pas réels)
- ✅ Badge : STEPS bleu affiché
- ✅ Pas en temps réel mis à jour chaque seconde

---

### Test #2 : Mode GPS (Fallback) 🟢

**Objectif** : Valider l'estimation GPS quand pedometer non disponible

#### Étapes
1. **Désactiver** les permissions pedometer :
   - iOS : Réglages > Confidentialité > Mouvement et forme > Ryze → OFF
   - Android : Paramètres > Applications > Ryze > Autorisations > Activité physique → Refuser
2. Redémarrer l'application
3. Autoriser la localisation GPS
4. Sélectionner "Marche" → "Marche libre"
5. **Vérifier** : Badge vert **GPS** avec icône 🛰️
6. Démarrer et marcher pendant 5 minutes à vitesse normale (~5 km/h)
7. Arrêter la session

#### Résultats Attendus
- Badge affiché : **GPS** (vert)
- Distance : **≈ 0.42 km** (5 km/h × 5 min)
- Pas estimés : **≈ 530 pas** (420m ÷ 0.78m foulée)
- Logs :
  ```
  ⚠️ Pedometer: Non disponible, utiliser fallback GPS
  🌍 Utilisation GPS réel
  👣 GPS Fallback: X pas estimés (foulée: 0.78m)
  ```

#### Validation
- ✅ Badge : GPS vert affiché
- ✅ Distance cohérente avec le parcours
- ✅ Pas estimés cohérents (distance × 1.25)

---

### Test #3 : Mode SIMU (Simulation) 🟠

**Objectif** : Valider la simulation en l'absence de GPS/Pedometer

#### Étapes
1. **Désactiver** :
   - Permissions pedometer (comme Test #2)
   - Localisation GPS (Mode Avion OU refuser permissions)
2. Redémarrer l'application
3. Sélectionner "Marche" → "Marche libre"
4. **Vérifier** : Badge orange **SIMU** avec icône 📡
5. Démarrer et laisser tourner pendant 1 minute
6. Arrêter

#### Résultats Attendus
- Badge affiché : **SIMU** (orange)
- Pas après 1 min : **≈ 100-120 pas** (cadence réaliste)
- Distance : Simulation cohérente (~0.08 km en 1 min à 5 km/h)
- Logs :
  ```
  ⚠️ Mode simulation - GPS: false, Permission: false
  🎲 Simulation: +2 pas (120 pas/min)
  ```

#### Validation
- ✅ Badge : SIMU orange affiché
- ✅ Cadence : 100-120 pas/minute (PAS 60-180 comme avant)
- ✅ Incréments réguliers : 2 pas/seconde en moyenne

---

### Test #4 : Comparaison avec Compteur Natif 📊

**Objectif** : Valider la précision vs compteur iOS/Android

#### Étapes
1. Ouvrir l'application **Santé** (iOS) ou **Google Fit** (Android)
2. Noter le nombre de pas actuel : **X pas**
3. Ouvrir Ryze et démarrer une séance de marche (mode STEPS)
4. Marcher pendant 10 minutes normalement
5. Arrêter la séance Ryze
6. Noter les pas Ryze : **Y pas**
7. Retourner dans Santé/Google Fit
8. Noter le nouveau total : **Z pas**

#### Résultats Attendus
- **Pas Ryze** (Y) ≈ **Pas natifs** (Z - X)
- Écart acceptable : ±10% (ex: 1000 pas Ryze vs 900-1100 pas natif)

#### Validation
- ✅ Précision : Écart < 10%
- ✅ Synchronisation possible (si intégration HealthKit/Google Fit activée)

---

## 🐛 Problèmes Connus & Solutions

### Problème : Badge reste en SIMU alors que GPS actif
**Cause** : Permissions GPS refusées
**Solution** : Autoriser "Toujours" ou "Pendant l'utilisation" dans les réglages

### Problème : Pas toujours à 0
**Cause** : Permissions pedometer refusées + GPS non actif
**Solution** :
1. Vérifier les permissions dans Réglages
2. Redémarrer l'application
3. Accepter les demandes de permission

### Problème : Compteur déconnant (ancien bug)
**Vérification** :
- Mode SIMU : Doit afficher ~100-120 pas/min (PAS 60-180)
- Logs : Chercher `🎲 Simulation: +X pas (XXX pas/min)`
- Si > 150 pas/min → Bug non corrigé

---

## 📊 Rapport de Test (Template)

```markdown
## Test du Compteur de Pas

**Date** : _____________________
**Appareil** : iPhone/Android _____________________
**OS Version** : _____________________
**App Version** : _____________________

### Test #1 : Mode STEPS
- [ ] Badge STEPS bleu affiché
- [ ] 100 pas manuels = _____ pas comptés (écart: _____%)
- [ ] Logs corrects

### Test #2 : Mode GPS
- [ ] Badge GPS vert affiché
- [ ] Distance cohérente
- [ ] Pas estimés corrects

### Test #3 : Mode SIMU
- [ ] Badge SIMU orange affiché
- [ ] Cadence 100-120 pas/min ✅
- [ ] Pas après 1 min : _____ (attendu: 100-120)

### Test #4 : Comparaison Natif
- Pas natifs (avant) : _____
- Pas Ryze : _____
- Pas natifs (après) : _____
- Écart : _____% (attendu: <10%)

### Bugs Détectés
_________________________________
_________________________________
_________________________________

### Commentaires
_________________________________
_________________________________
_________________________________
```

---

## 📱 Commandes pour Voir les Logs

### iOS (Xcode)
1. Ouvrir Xcode
2. Window > Devices and Simulators
3. Sélectionner l'iPhone connecté
4. Cliquer sur "Open Console"
5. Filtrer par "Pedometer" ou "👣"

### Android (Android Studio)
1. Ouvrir Android Studio
2. View > Tool Windows > Logcat
3. Filtrer par "flutter" ou chercher "Pedometer"
4. Filtrer par "👣" pour voir les logs de pas

---

## ✅ Critères de Succès

L'implémentation est considérée comme réussie si :

1. **Mode STEPS** : Précision ≥ 95% vs compteur manuel
2. **Mode GPS** : Distance cohérente, pas estimés raisonnables
3. **Mode SIMU** : Cadence 100-120 pas/min (NON 60-180)
4. **Badge** : Indicateur correct selon le mode actif
5. **Logs** : Pas d'erreurs critiques dans la console
6. **UX** : Transition fluide entre les modes

---

**Auteur** : Claude Code
**Date** : 2025-01-30
**Version** : 1.0
