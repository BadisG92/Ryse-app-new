# 🎤 Guide de Debug - Voice Input Musculation

## ✅ Corrections Appliquées

### 1. **Permissions iOS** ([Info.plist:51-54](ios/Runner/Info.plist))
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Cette application utilise le microphone pour l'assistance vocale lors du scan nutritionnel et l'enregistrement mains-libres de vos performances pendant les entraînements.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Cette application utilise la reconnaissance vocale pour enregistrer vos répétitions et poids pendant l'entraînement musculation, vous permettant de rester concentré sur votre séance.</string>
```

### 2. **Permissions Android** ([AndroidManifest.xml:8-13](android/app/src/main/AndroidManifest.xml))
```xml
<!-- Permissions pour la reconnaissance vocale -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Feature pour reconnaissance vocale (optionnel mais recommandé) -->
<uses-feature android:name="android.hardware.microphone" android:required="false" />
```

---

## 🔍 Checklist de Debug

### **Étape 1 : Rebuild l'application**
Les permissions nécessitent un **rebuild complet** :

```bash
# Nettoyer le build
flutter clean

# Récupérer les dépendances
flutter pub get

# iOS : Réinstaller les pods
cd ios && pod install && cd ..

# Rebuild
flutter run --release  # OU en mode debug
```

### **Étape 2 : Vérifier les permissions sur le device**

#### **iOS** :
1. Ouvrez **Réglages** > **Ryze App**
2. Vérifiez que les permissions suivantes sont activées :
   - ✅ **Microphone**
   - ✅ **Reconnaissance vocale** (Speech Recognition)

Si elles n'apparaissent pas :
- Désinstallez complètement l'app
- Réinstallez avec `flutter run`
- L'app demandera les permissions au premier lancement

#### **Android** :
1. Ouvrez **Paramètres** > **Applications** > **Ryze App** > **Autorisations**
2. Vérifiez que **Microphone** est activé

Si la permission n'est pas demandée :
- Désinstallez l'app
- Réinstallez avec `flutter run`

---

## 🧪 Test du Bouton Micro

### **Scénario de test**

1. **Ouvrir une séance de musculation** :
   - Aller sur l'onglet "Sport"
   - Taper sur "Séance manuelle"
   - Ajouter au moins 1 exercice (ex: "Développé couché")

2. **Vérifier l'apparition du bouton** :
   - Le bouton micro doit apparaître en **bas à droite**
   - Texte affiché : "Tenir" (FR) / "Hold" (EN)
   - Couleur de fond : Bleu foncé `#0B132B`

3. **Tester le hold** :
   - **Maintenir appuyé** (long press) sur le bouton
   - ✅ **Attendu** :
     - Le bouton devient **rouge**
     - Un overlay noir avec animation micro apparaît
     - Message : "Dictez vos reps et poids..."

4. **Parler dans le micro** :
   - Dire par exemple : **"10 reps 80 kilos"**
   - OU : **"80 kilos 10 reps"** (ordre inversé)
   - OU : **"10 reps"** (sans poids)

5. **Relâcher le bouton** :
   - ✅ **Attendu** :
     - L'overlay se ferme
     - Un feedback vocal confirme : "10 répétitions, 80 kilos enregistrés"
     - Les champs de la série sont automatiquement remplis
     - Vibration de succès

---

## 🐛 Problèmes Courants

### **❌ Le bouton n'apparaît pas**

**Causes possibles** :
1. Aucun exercice dans la séance
   - **Solution** : Ajouter au moins 1 exercice

2. Le widget Stack n'est pas rendu
   - **Debug** : Ajouter un `debugPrint` dans `_buildVoiceButton()` ligne 3020

3. Z-index problem (caché derrière autre widget)
   - **Debug** : Vérifier que `Positioned(bottom: 100)` n'est pas masqué

### **❌ Le bouton apparaît mais ne réagit pas au hold**

**Causes possibles** :
1. Permissions refusées
   - **Solution** : Vérifier Réglages > Ryze App > Microphone

2. Service vocal non initialisé
   - **Debug** : Ajouter des logs dans `_startVoiceInput()` ligne 3254
   ```dart
   debugPrint('🎤 Starting voice input...');
   ```

3. `onLongPressStart` ne se déclenche pas
   - **Test** : Remplacer temporairement par `onTap` pour vérifier
   ```dart
   // TEST TEMPORAIRE
   onTap: () => _startVoiceInput(),
   // Remplacer onLongPressStart
   ```

### **❌ Le micro s'active mais ne reconnaît rien**

**Causes possibles** :
1. Package `speech_to_text` pas initialisé correctement
   - **Debug** : Vérifier les logs console pour :
     ```
     ✅ WorkoutVoiceService initialized
     🎤 Speech status: listening
     ```

2. Locale non supporté
   - **Solution** : Le code supporte `fr_FR` et `en_US`
   - Vérifier que `LocalizationService.instance.currentLanguageCode` retourne `'fr'` ou `'en'`

3. Timeout trop court
   - **Solution** : Actuellement 5s (`listenFor: Duration(seconds: 5)`)
   - Augmenter si nécessaire dans [workout_voice_service.dart:80](lib/services/workout_voice_service.dart#L80)

### **❌ Reconnaissance incorrecte**

**Patterns supportés** (voir [workout_voice_service.dart:134-196](lib/services/workout_voice_service.dart#L134-L196)) :

| Format | Exemple | Pattern |
|--------|---------|---------|
| Reps + Poids | "10 reps 80 kilos" | `(\d+) reps (\d+) kg` |
| Poids + Reps | "80 kilos 10 reps" | `(\d+) kg (\d+) reps` |
| Reps only | "10 reps" | `(\d+) reps` |

**Mots-clés acceptés** :
- Reps : `rep`, `reps`, `répétition`, `répétitions`
- Poids : `kg`, `kilo`, `kilos`

**Amélioration possible** :
- Ajouter support pour nombres en lettres ("dix répétitions")
- Ajouter support pour décimales ("82.5 kilos")

---

## 📊 Logs Utiles

### **Activer les logs détaillés**

Dans [workout_voice_service.dart](lib/services/workout_voice_service.dart), tous les logs sont déjà activés :
```dart
onStatus: (status) => debugPrint('🎤 Speech status: $status'),
onError: (error) => debugPrint('❌ Speech error: $error'),
```

### **Logs attendus (succès)** :
```
✅ WorkoutVoiceService initialized
🎤 Starting voice input...
🎤 Speech status: listening
🔍 Parsing: "10 reps 80 kilos"
✅ Parsed (pattern 1): 10 reps, 80.0 kg
10 répétitions, 80 kilos enregistrés
```

### **Logs d'erreur** :
```
❌ Speech error: error_speech_timeout
❌ No pattern matched
🔄 Auto-retry 1/3
```

---

## 🚀 Prochaines Améliorations

1. **Feedback visuel plus clair** pendant l'écoute (onde sonore animée)
2. **Support nombres en lettres** : "dix répétitions" → 10 reps
3. **Historique des dernières commandes vocales** pour auto-complétion
4. **Mode "écoute continue"** : Enchaîner plusieurs séries sans re-hold
5. **Calibration du seuil de bruit** pour salles de sport bruyantes

---

## 📞 Contact / Support

Si le problème persiste après ces vérifications :

1. **Vérifier les logs console** avec `flutter logs`
2. **Tester sur device réel** (pas émulateur - le micro peut ne pas fonctionner)
3. **Tester la langue** : Switcher entre FR/EN dans les paramètres
4. **Vérifier la version du package** : `speech_to_text: ^7.0.0`

---

## 🔐 Notes de Sécurité

- ✅ Reconnaissance vocale **on-device** activée (`onDevice: true`) pour iOS récents
- ✅ Fallback vers API cloud si device ne supporte pas
- ✅ Aucune donnée vocale stockée ou envoyée à des serveurs tiers
- ✅ Les permissions sont demandées seulement lors du premier usage
