# Guide pour créer les screenshots des tutorials

## 📸 Screenshots nécessaires

Tu dois créer 3 screenshots de pages **vides** (sans données utilisateur) :

1. **nutrition_dashboard_empty.png** - Page Nutrition > Dashboard (vide)
2. **sport_dashboard_empty.png** - Page Sport > Dashboard (vide)
3. **cardio_dashboard_empty.png** - Page Sport > Cardio (vide)

---

## 🎯 Comment faire les screenshots

### Option 1 : Avec un compte test vide

1. **Créer un nouveau compte** sur l'app ou utiliser un compte de test
2. **Ne PAS ajouter de données** (pas de repas, pas de sport, etc.)
3. **Naviguer vers chaque page** et faire le screenshot

### Option 2 : Modifier temporairement le code

Si impossible d'avoir un compte vide, tu peux temporairement masquer les données :

```dart
// Dans le widget concerné, remplacer temporairement :
final hasData = true;

// Par :
final hasData = false;
```

---

## 📱 Spécifications techniques

### Format
- **Format d'image :** PNG
- **Résolution :** Résolution native de ton device de test
- **Orientation :** Portrait
- **Qualité :** Maximum (pas de compression)

### Cadrage
**TRÈS IMPORTANT** : Le screenshot doit inclure :
- ✅ La barre de navigation en bas (si présente)
- ✅ Les onglets en haut (Tableau de bord, Journal, Recettes, etc.)
- ✅ TOUT le contenu de la page
- ❌ PAS la barre système Android/iOS (heure, batterie, etc.)

### Zone de capture pour chaque page

#### 1. nutrition_dashboard_empty.png
📍 **Page : Nutrition > Tableau de bord**

Éléments visibles (vides) :
- Carte "Calories du jour" (0/2000 kcal)
- Carte "Macronutriments" (0g pour chaque macro)
- Section "Hydratation & Repas" (0 verres, 0 repas)
- Section "Actions rapides" (5 boutons d'ajout)

#### 2. sport_dashboard_empty.png
📍 **Page : Sport > Tableau de bord**

Éléments visibles (vides) :
- Carte "Calories brûlées cette semaine" (0 kcal)
- Carte "Progression de la semaine" (0 séances)
- Section "Activités du jour" (vide)
- Boutons "Cardio" et "Musculation"

#### 3. cardio_dashboard_empty.png
📍 **Page : Sport > Cardio**

Éléments visibles (vides) :
- Section "Cette semaine" (0 km, 0 kcal, etc.)
- Section "Choisir une activité" (icônes des activités)
- "Dernière séance enregistrée" (message "Aucune séance")
- "Vos séances de la semaine" (vide)
- Bouton "Voir l'historique complet"

---

## 🔧 Processus de création

### Étape 1 : Préparer l'environnement
```bash
# Lancer l'app sur un émulateur ou device
flutter run
```

### Étape 2 : Naviguer et capturer

1. **Aller sur la page** concernée
2. **Attendre que tout soit chargé** (pas de spinners)
3. **Faire le screenshot** :
   - **iOS Simulator** : `Cmd + S`
   - **Android Emulator** : Bouton caméra dans la toolbar
   - **Device physique** : Utiliser les boutons volume + power

### Étape 3 : Renommer et placer

1. Renommer le fichier exactement comme indiqué :
   - `nutrition_dashboard_empty.png`
   - `sport_dashboard_empty.png`
   - `cardio_dashboard_empty.png`

2. Placer dans le dossier :
   ```
   assets/images/tutorials/
   ```

### Étape 4 : Vérifier

- [ ] Les 3 fichiers sont présents
- [ ] Les noms sont EXACTEMENT corrects (sensible à la casse)
- [ ] Les images sont en PNG
- [ ] Les pages sont vides (pas de données utilisateur)
- [ ] Tout le contenu de la page est visible

---

## 🎨 Ajustement des positions (optionnel)

Une fois les screenshots en place, si les bulles ne sont pas bien positionnées :

1. Ouvrir `lib/services/tutorial_config.dart`
2. Ajuster les valeurs `bubblePosition`, `targetPosition` et `targetSize`
3. Les valeurs vont de 0.0 (haut/gauche) à 1.0 (bas/droite)

Exemple :
```dart
bubblePosition: const Offset(0.075, 0.35),  // x=7.5% de la largeur, y=35% de la hauteur
targetPosition: const Offset(0.05, 0.15),   // Position de la zone à highlighter
targetSize: const Size(0.9, 0.15),          // Largeur=90%, Hauteur=15%
```

---

## ✅ Checklist finale

Avant de tester :
- [ ] Les 3 screenshots sont créés et placés
- [ ] Les noms de fichiers sont corrects
- [ ] `flutter pub get` a été exécuté
- [ ] L'app compile sans erreur
- [ ] Les tutorials se lancent correctement

---

## 🐛 Troubleshooting

### L'image ne s'affiche pas
- Vérifier le nom du fichier (sensible à la casse)
- Vérifier le chemin : `assets/images/tutorials/`
- Relancer `flutter clean && flutter pub get`

### La position des bulles est décalée
- Ouvrir `tutorial_config.dart`
- Ajuster les valeurs Offset et Size
- Relancer l'app pour voir les changements

### Le screenshot montre du contenu
- Utiliser un compte de test vide
- Ou masquer temporairement les données dans le code

---

**Besoin d'aide ?** Regarde les exemples de position dans `tutorial_config.dart`
