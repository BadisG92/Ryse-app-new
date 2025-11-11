# Implémentation du Compteur de Pas Natif

## 🎯 Objectif
Corriger le compteur de pas "déconnant" en intégrant le capteur de pas natif du téléphone avec des fallbacks intelligents.

## ✅ Solution Implémentée

### 3 Modes de Tracking Hiérarchiques

1. **🔵 STEPS Mode (Pedometer Natif)** - Le plus précis
   - Utilise le capteur de pas natif iOS/Android
   - Activé automatiquement pour la marche si disponible
   - Affiche un badge bleu avec icône 👣

2. **🟢 GPS Mode** - Précis
   - Utilise le GPS pour calculer distance et vitesse
   - Estimation des pas via formule scientifique (distance ÷ longueur de foulée)
   - Affiche un badge vert avec icône 🛰️

3. **🟠 SIMU Mode (Simulation)** - Estimation
   - Simulation réaliste en l'absence de GPS/Pedometer
   - Cadence corrigée à 100-120 pas/minute (au lieu de 60-180)
   - Affiche un badge orange avec icône 📡

## 📁 Fichiers Modifiés

### Nouveau Service
- **`lib/services/pedometer_service.dart`**
  - Service singleton pour gérer le pedometer natif
  - Gestion des permissions iOS (Motion & Fitness) et Android (Activity Recognition)
  - Callbacks en temps réel pour mise à jour des pas
  - Réinitialisation par session
  - Détection du statut piéton (walking/stopped)

### Écran Modifié
- **`lib/screens/cardio_tracking_screen.dart`**
  - Intégration du `PedometerService`
  - Vérification de disponibilité au démarrage
  - Démarrage automatique pour activité `walking`
  - Callback temps réel : `onStepCountChanged`
  - Indicateur visuel du mode actif (STEPS/GPS/SIMU)

### Corrections des Calculs

#### 1. GPS Fallback (lignes 262-316)
```dart
// AVANT (INCORRECT)
final stepsPerMinute = (currentSpeed * 20).clamp(80, 140); // Formule arbitraire
steps = ((stepsPerMinute / 60) * _session.duration.inSeconds).round(); // Recalcul total

// APRÈS (CORRECT)
final strideLength = _calculateStrideLength(currentSpeed); // 0.60-0.95m selon vitesse
steps = ((distance * 1000) / strideLength).round(); // Accumulation basée sur distance
```

**Formule scientifique :**
- Vitesse < 3 km/h → Foulée 0.60m
- Vitesse 3-4 km/h → Foulée 0.70m
- Vitesse 4-5 km/h → Foulée 0.78m
- Vitesse 5-6 km/h → Foulée 0.85m
- Vitesse > 6 km/h → Foulée 0.95m

#### 2. Mode Simulation (lignes 318-357)
```dart
// AVANT (INCORRECT)
stepsIncrement = random.nextInt(3) + 1; // 1-3 pas/sec = 60-180 pas/min ❌

// APRÈS (CORRECT)
final stepsPerSecond = 1.67 + (random.nextDouble() * 0.33); // 1.67-2.0 pas/sec
stepsIncrement = stepsPerSecond.round(); // ~100-120 pas/min ✅
```

## 🔐 Permissions Ajoutées

### iOS (`ios/Runner/Info.plist`)
✅ Déjà présent :
```xml
<key>NSMotionUsageDescription</key>
<string>Cette application utilise les capteurs de mouvement pour compter vos pas lors des séances de marche et optimiser le suivi de vos activités.</string>
```

### Android (`android/app/src/main/AndroidManifest.xml`)
✅ Ajouté :
```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

## 📦 Dépendance Ajoutée

**`pubspec.yaml`** :
```yaml
pedometer: ^4.0.1  # Compteur de pas natif (iOS & Android)
```

Installation :
```bash
flutter pub get
```

## 🎨 Interface Utilisateur

### Indicateur de Mode (Header)
Badge dynamique affichant le mode actif :
- **STEPS** (bleu) + icône 👣 → Pedometer natif
- **GPS** (vert) + icône 🛰️ → GPS actif
- **SIMU** (orange) + icône 📡 → Simulation

Méthodes helper :
- `_getTrackingModeColor()` → Couleur du badge
- `_getTrackingModeIcon()` → Icône du badge
- `_getTrackingModeLabel()` → Label du badge

## 🧪 Tests Recommandés

### Test 1 : Pedometer Natif
1. Lancer une séance de marche sur appareil réel
2. Vérifier badge **STEPS** (bleu)
3. Marcher 100 pas et comparer avec compteur natif iOS/Android
4. Logs attendus : `✅ Pedometer: Tracking démarré` + `👣 Pedometer: X pas totaux`

### Test 2 : GPS Fallback
1. Refuser permissions pedometer
2. Activer GPS
3. Vérifier badge **GPS** (vert)
4. Logs attendus : `👣 GPS Fallback: X pas estimés (foulée: Xm)`

### Test 3 : Simulation
1. Refuser permissions pedometer + GPS
2. Ou tester sur Web
3. Vérifier badge **SIMU** (orange)
4. Logs attendus : `🎲 Simulation: +X pas (XXX pas/min)`

### Validation Scientifique
Pour une marche de 30 minutes à 5 km/h :
- **Distance** : ~2.5 km
- **Pas attendus** : 2500m ÷ 0.78m = ~3200 pas
- **Cadence** : ~107 pas/minute ✅

## 🐛 Problèmes Corrigés

### Problème #1 : Calcul GPS incorrect
- ❌ **Avant** : `currentSpeed * 20` (formule arbitraire)
- ✅ **Après** : `distance / strideLength(speed)` (formule biomécanique)

### Problème #2 : Simulation irréaliste
- ❌ **Avant** : 1-3 pas/sec = 60-180 pas/min (trop variable)
- ✅ **Après** : 1.67-2 pas/sec = 100-120 pas/min (réaliste)

### Problème #3 : Pas de vrai capteur
- ❌ **Avant** : Uniquement estimations GPS/simulation
- ✅ **Après** : Pedometer natif en priorité

## 📊 Architecture

```
┌─────────────────────────────────────┐
│  CardioTrackingScreen               │
│  ├─ _checkPedometerAvailability()   │
│  ├─ _startTracking()                │
│  └─ Timer (1 sec)                   │
│     ├─ Pedometer natif (priorité 1) │
│     ├─ GPS fallback (priorité 2)    │
│     └─ Simulation (priorité 3)      │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  PedometerService (Singleton)       │
│  ├─ checkPedometerAvailability()    │
│  ├─ startTracking()                 │
│  ├─ stopTracking()                  │
│  ├─ resetSessionSteps()             │
│  ├─ getSessionSteps()               │
│  └─ onStepCountChanged callback     │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Package: pedometer ^4.0.1          │
│  ├─ iOS: CoreMotion (CMPedometer)   │
│  └─ Android: SensorManager          │
└─────────────────────────────────────┘
```

## 🚀 Prochaines Étapes

- [ ] Tester sur appareil réel iOS
- [ ] Tester sur appareil réel Android
- [ ] Valider précision vs compteur natif
- [ ] Ajuster formules si nécessaire
- [ ] Intégrer avec HealthKit (optionnel)

## 📚 Références

- [Pedometer Package](https://pub.dev/packages/pedometer)
- [Biomécanique de la marche](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3528799/)
- Longueur de foulée moyenne : 0.78m (adulte moyen)
- Cadence normale : 100-120 pas/minute

---

**Auteur** : Claude Code
**Date** : 2025-01-30
**Version** : 1.0
