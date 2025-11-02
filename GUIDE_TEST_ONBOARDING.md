# 🧪 Guide de Test - Nouvelles Fonctionnalités Onboarding

## 🚀 Lancement Rapide

### Méthode 1 : Script automatique
```bash
./test_onboarding.sh
```

### Méthode 2 : Commande Flutter
```bash
flutter run -t lib/test_onboarding_display.dart
```

### Méthode 3 : Depuis VS Code
1. Ouvrir `lib/test_onboarding_display.dart`
2. Cliquer sur "Run" ou F5

---

## 🎯 Scénarios de Test

### ✅ **Test 1 : Perte de Poids (Femme)**

**Données à saisir** :
- Genre : Femme
- Âge : 30 ans
- Poids actuel : 65 kg
- Taille : 162 cm
- Activité : Peu active (low)
- Objectif : Perte de poids (lose)
- **Poids cible : 58 kg** ⭐

**Résultats attendus** :
- ✅ Calories : ~1298 kcal/jour (PAS 1122 !)
- ✅ Affiche : "🕐 Environ 3 mois pour perdre 7.0 kg"
- ✅ SANS le détail "(0.5 kg/semaine)"

---

### ✅ **Test 2 : Gain de Poids (Homme)**

**Données à saisir** :
- Genre : Homme
- Âge : 25 ans
- Poids actuel : 65 kg
- Taille : 180 cm
- Activité : Très active (high)
- Objectif : Prise de masse (gain)
- **Poids cible : 75 kg** ⭐

**Résultats attendus** :
- ✅ Calories : ~3400 kcal/jour
- ✅ Affiche : "🕐 Environ 9 mois pour prendre 10.0 kg"
- ✅ SANS le détail "(0.25 kg/semaine)"

---

### ✅ **Test 3 : Maintien (Ne doit PAS afficher l'estimation)**

**Données à saisir** :
- Genre : Femme
- Âge : 28 ans
- Poids actuel : 60 kg
- Taille : 168 cm
- Activité : Modérée (moderate)
- Objectif : Maintien (maintain)
- Poids cible : 60 kg (ou laisser vide)

**Résultats attendus** :
- ✅ Calories : ~2000 kcal/jour (TDEE)
- ❌ **N'affiche RIEN** pour l'estimation de temps
- ✅ Seulement l'objectif calorique visible

---

### ✅ **Test 4 : Perte SANS Poids Cible**

**Données à saisir** :
- Genre : Femme
- Âge : 35 ans
- Poids actuel : 70 kg
- Taille : 165 cm
- Activité : Peu active
- Objectif : Perte de poids (lose)
- **Poids cible : laisser vide ou ne pas remplir** ⭐

**Résultats attendus** :
- ✅ Calories : calculées avec déficit adaptatif
- ❌ **N'affiche RIEN** pour l'estimation de temps
- ✅ Utilise le nouveau calcul standard (20% déficit)

---

## 🔍 Points Critiques à Vérifier

### 1. **Calculs Caloriques Sécurisés**
- [ ] Femmes : JAMAIS sous 1200 kcal
- [ ] Hommes : JAMAIS sous 1500 kcal
- [ ] Déficit adaptatif (20% du TDEE, max 500 kcal)
- [ ] Surplus adaptatif (15% du TDEE, max 500 kcal)

### 2. **Affichage de l'Estimation**
- [ ] S'affiche UNIQUEMENT pour perte/gain avec poids cible
- [ ] Ne s'affiche PAS pour maintien
- [ ] Ne s'affiche PAS si poids cible vide
- [ ] Texte concis sans "(kg/semaine)"

### 3. **Design Visuel**
- [ ] Icône horloge 🕐 présente
- [ ] Fond gradient subtil
- [ ] Bordure fine
- [ ] Texte centré
- [ ] Intégration harmonieuse avec le reste

### 4. **Formules Mathématiques**
- [ ] BMR : Mifflin-St Jeor correct
- [ ] TDEE : Facteurs d'activité corrects (1.2 / 1.55 / 1.8)
- [ ] Macros : Répartition selon objectif
- [ ] Temps : 0.5 kg/semaine (femmes), 0.75 (hommes), 0.25 (gain)

---

## 📸 Screenshots à Capturer

Pour valider les modifications :

1. **Écran de résultats - Perte avec poids cible**
   - Capture l'affichage complet avec l'estimation de temps

2. **Écran de résultats - Maintien**
   - Capture pour prouver que l'estimation ne s'affiche PAS

3. **Écran de résultats - Perte sans poids cible**
   - Capture pour prouver que l'estimation ne s'affiche PAS

---

## 🐛 Problèmes Connus et Solutions

### Problème : L'app ne démarre pas
**Solution** :
```bash
flutter clean
flutter pub get
flutter run -t lib/test_onboarding_display.dart
```

### Problème : L'onboarding ne s'affiche pas
**Solution** :
```bash
# Effacer manuellement les données
flutter run -d <device_id>
# Puis dans l'app : Settings → Clear Data
# Ou désinstaller/réinstaller l'app
```

### Problème : Erreur de compilation
**Solution** :
```bash
flutter analyze lib/components/ui/onboarding_models.dart
flutter analyze lib/components/onboarding_gamified_hybrid.dart
```

---

## ✅ Checklist de Validation Finale

Avant de merger les modifications :

- [ ] Test 1 (Perte femme) : OK
- [ ] Test 2 (Gain homme) : OK
- [ ] Test 3 (Maintien) : N'affiche rien - OK
- [ ] Test 4 (Sans poids cible) : N'affiche rien - OK
- [ ] Calculs caloriques sécurisés : OK
- [ ] Texte sans kg/semaine : OK
- [ ] Design visuel harmonieux : OK
- [ ] Pas d'erreurs de compilation : OK
- [ ] Pas de crash pendant l'onboarding : OK

---

## 📊 Comparaison Avant/Après

### AVANT
```
Femme 65kg, 162cm, peu active, perte
→ Objectif : 1122 kcal ❌ (SOUS BMR)
→ Pas d'estimation de temps
```

### APRÈS
```
Femme 65kg, 162cm, peu active, perte → 58kg
→ Objectif : 1298 kcal ✅ (Sécurisé)
→ "🕐 Environ 3 mois pour perdre 7.0 kg" ✅
```

---

## 🎉 Félicitations !

Si tous les tests passent, les nouvelles fonctionnalités sont prêtes pour la production :

1. ✅ Calculs caloriques améliorés et sécurisés
2. ✅ Intégration du poids cible
3. ✅ Estimation du temps intelligente
4. ✅ Affichage conditionnel (perte/gain uniquement)
5. ✅ Texte épuré et concis

**Prochaine étape** : Merger dans la branche principale et déployer ! 🚀
