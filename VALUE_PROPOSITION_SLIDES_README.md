# 📱 Value Proposition Slides - Documentation

## 🎯 Vue d'ensemble

Les **Value Proposition Slides** sont 3 slides affichées **AVANT** l'onboarding pour présenter les bénéfices clés de Ryze à l'utilisateur.

**Objectif** : Réduire le taux d'abandon de l'onboarding de 40-50% à 20-25% en créant de l'engagement avant la collecte de données.

---

## 📂 Fichiers créés

```
lib/components/
├── onboarding_with_value_prop.dart       # Wrapper qui combine slides + onboarding
└── ui/
    ├── value_proposition_slides.dart     # Widget des 3 slides
    └── value_proposition_models.dart     # Modèles de données (copy FR/EN)
```

---

## 🎨 Les 3 Slides

### **Slide 1 : Simplicité d'input**
- **Avatar** : `coach_ryze_welcome.png` (panda qui salue)
- **Message** : "Choisis ta méthode, je m'occupe du reste"
- **Contenu** : 3 cartes (Photo, Voix, Texte)
- **Bénéfice** : "Plus besoin de chercher dans des listes infinies"

### **Slide 2 : Coach sur demande**
- **Avatar** : `coach_ryze_ai_chat_nutrition.png` (panda avec blouse, main sur menton)
- **Message** : "Un vrai coach, quand tu en as besoin"
- **Contenu** : Mockup interface nutrition + bouton "Analyser" + réponse coach
- **Animation** : Réponse coach apparaît après 1.5s automatiquement
- **Bénéfices** : Appuie pour analyser • Conseils adaptés • Bilan personnalisé

### **Slide 3 : Analyse sport**
- **Avatar** : `coach_ryze_workout_avatar.png` (panda avec bandeau + clipboard)
- **Message** : "Coach Ryze analyse tes performances"
- **Contenu** : Graphique de progression + analyse + recommandations
- **CTA final** : "Commencer" (lance l'onboarding)

---

## 🔧 Intégration

### Avant (ancien flow)
```
Login → OnboardingGamifiedHybrid → MainApp
```

### Maintenant (nouveau flow)
```
Login → ValuePropositionSlides → OnboardingGamifiedHybrid → MainApp
```

### Fichier modifié
```dart
// lib/pages/ryze_app.dart

// AVANT
import '../components/onboarding_gamified_hybrid.dart';
if (!_isOnboarded) {
  return OnboardingGamifiedHybrid(onComplete: _completeOnboarding);
}

// APRÈS
import '../components/onboarding_with_value_prop.dart';
if (!_isOnboarded) {
  return OnboardingWithValueProp(onComplete: _completeOnboarding);
}
```

---

## 🐼 Avatars Coach Ryze utilisés

| Slide | Fichier | Description |
|-------|---------|-------------|
| Slide 1 | `coach_ryze_welcome.png` | Panda debout, patte levée en salut |
| Slide 2 | `coach_ryze_ai_chat_nutrition.png` | Panda avec blouse blanche, main sur menton |
| Slide 3 | `coach_ryze_workout_avatar.png` | Panda avec bandeau de sport + clipboard |

**Note** : Tous les avatars utilisent le même panda (bleu marine foncé #0B132B + blanc crème), style 3D render professionnel.

---

## 🌍 Traductions

Les slides sont **bilingues FR/EN** et s'adaptent automatiquement selon `LocalizationService.currentLanguageCode`.

Toutes les traductions sont dans `lib/components/ui/value_proposition_models.dart` :
- `Slide1Data` : Textes slide 1
- `Slide2Data` : Textes slide 2
- `Slide3Data` : Textes slide 3

---

## ✨ Features

### Navigation
- **Bouton Skip** : En haut à droite (permet de passer directement à l'onboarding)
- **Dots de pagination** : En bas (indique slide 1/3, 2/3, 3/3)
- **Bouton Retour** : Disponible à partir de la slide 2
- **Bouton Suivant** : Passe à la slide suivante
- **Bouton "Commencer"** : Sur slide 3, lance l'onboarding

### Animations
- **Fade in** : Chaque slide apparaît en fondu
- **Slide 2** : La réponse du coach slide depuis le bas après 1.5s
- **Transitions** : Smooth entre les slides (400ms)

### Graphique (Slide 3)
- **CustomPainter** : Graphique de progression dessiné en Flutter
- Points de données : `[60, 70, 80, 80]` kg
- Labels : "S1", "S2", "S3", "S4"
- Style : Ligne bleu marine avec points blancs au centre

---

## 🎨 Design System

### Couleurs
```dart
backgroundColor: Color(0xFFF8FAFC)      // Gris clair (fond)
primaryColor: Color(0xFF0B132B)         // Bleu marine foncé
secondaryColor: Color(0xFF1C2951)       // Bleu moyen
accentGreen: Color(0xFF22C55E)          // Vert succès
accentOrange: Color(0xFFA500)          // Orange énergie
textPrimary: Color(0xFF1A1A1A)          // Noir texte
textSecondary: Color(0xFF64748B)        // Gris texte
borderColor: Color(0xFFE2E8F0)          // Gris bordure
```

### Typographie
```dart
titleSize: 28px, bold                   // Titres slides
bodySize: 15-16px, regular              // Texte principal
smallSize: 13-14px, regular             // Texte secondaire
buttonSize: 16px, semibold              // Boutons
```

### Spacing
```dart
topPadding: 40px
coachImageSize: 140x140px
bubblePadding: 16px
methodCardHeight: 180px
sectionSpacing: 48px
```

---

## 📱 Assets nécessaires

### Existants (déjà présents) ✅
- `assets/images/coach_ryze_welcome.png`
- `assets/images/coach_ryze_ai_chat_nutrition.png`
- `assets/images/coach_ryze_workout_avatar.png`

### À créer (optionnel) ⚠️
Si tu veux des avatars spécifiques pour les value prop slides, crée :
- `assets/images/coach_ryze_value_prop_facilitator.png`
- `assets/images/coach_ryze_value_prop_analyst.png`
- `assets/images/coach_ryze_value_prop_motivator.png`

**Specs** : Voir le brief détaillé dans le fichier `COACH_RYZE_AVATARS_BRIEF.md` (si créé).

---

## 🧪 Testing

### Tester les slides
1. Déconnecte-toi de l'app
2. Supprime les données de l'app (ou utilise `resetOnboarding()`)
3. Reconnecte-toi
4. Les slides doivent s'afficher AVANT l'onboarding

### Forcer l'affichage
Dans `lib/pages/ryze_app.dart` :
```dart
static const bool _forceOnboarding = true; // Force l'onboarding
```

### Tester les traductions
Change la langue dans l'app settings, déconnecte/reconnecte pour voir les slides en FR/EN.

---

## 🐛 Troubleshooting

### Les slides ne s'affichent pas
**Problème** : Les slides sont skippées, l'onboarding apparaît directement.

**Solution** :
1. Vérifie que `OnboardingWithValueProp` est bien importé dans `ryze_app.dart`
2. Vérifie que `is_onboarded` est `false` en DB
3. Check les logs pour les erreurs d'import

### Les avatars ne s'affichent pas
**Problème** : Emoji 🐼 s'affiche au lieu de l'image.

**Solution** :
1. Vérifie que les fichiers existent dans `assets/images/`
2. Vérifie que `pubspec.yaml` inclut bien `assets/images/`
3. Relance `flutter pub get`
4. Rebuild l'app

### L'animation Slide 2 ne marche pas
**Problème** : La réponse du coach n'apparaît pas.

**Solution** :
1. Vérifie que `_showCoachResponse` est bien initialisé à `false`
2. Check que le Timer n'est pas cancelled prématurément
3. Vérifie que `_currentPage == 1` dans le callback

---

## 🔄 Customisation

### Modifier le copy
Édite `lib/components/ui/value_proposition_models.dart` :
```dart
static const String titleFr = "Ton nouveau titre";
static const String titleEn = "Your new title";
```

### Changer les avatars
Dans `value_proposition_slides.dart`, modifie les `imagePath` :
```dart
imagePath: 'assets/images/ton_nouveau_panda.png',
```

### Ajouter/retirer des slides
1. Ajoute un `_buildSlide4()` dans `value_proposition_slides.dart`
2. Ajoute-le dans le `PageView`
3. Mets à jour le `_currentPage < 3` en `< 4`
4. Ajoute un dot de pagination

### Désactiver le Skip
Dans `value_proposition_slides.dart` :
```dart
onSkip: null, // Au lieu de onSkip: _onSkipValueProp
```

---

## 📊 Métriques à suivre

Pour mesurer l'impact des slides :

1. **Taux de completion des slides** : Combien arrivent à slide 3 ?
2. **Taux de skip** : Combien cliquent sur "Passer" ?
3. **Taux de completion onboarding** : Avant/après les slides
4. **Temps moyen sur les slides** : Combien de temps passent-ils ?

---

## 🚀 Prochaines améliorations

### Court terme
- [ ] Créer des avatars dédiés pour les value prop (optionnel)
- [ ] Ajouter des animations plus poussées (parallax, etc.)
- [ ] Tester A/B testing (avec/sans slides)

### Moyen terme
- [ ] Ajouter des vidéos/GIFs dans les slides
- [ ] Personnaliser selon la source d'acquisition (App Store vs Google Play)
- [ ] Analytics Firebase pour tracker les interactions

### Long terme
- [ ] Slides dynamiques selon le profil (sport vs nutrition focus)
- [ ] Intégration avec le système de tutorial in-app
- [ ] Version web des slides

---

## 📚 Références

### Apps avec excellent onboarding
- **Duolingo** : 3 slides + mascotte Duo
- **Headspace** : 4 slides avec animations
- **Calm** : 5 slides avec vidéos
- **MyFitnessPal** : 2 slides minimalistes
- **Noom** : 3 slides + coach virtuel

### Best practices
- Baymard Institute : Onboarding UX research
- Appcues : Mobile onboarding guide
- UserOnboard : Teardowns d'onboardings

---

## ✅ Checklist d'intégration

- [x] Fichiers créés (`value_proposition_slides.dart`, `value_proposition_models.dart`, `onboarding_with_value_prop.dart`)
- [x] Imports ajoutés dans `ryze_app.dart`
- [x] Avatars Coach Ryze intégrés
- [x] Traductions FR/EN complètes
- [x] Navigation (skip, back, next) fonctionnelle
- [x] Animations implémentées
- [ ] Tests sur iOS
- [ ] Tests sur Android
- [ ] Tests traductions
- [ ] Analytics setup
- [ ] Documentation utilisateur

---

**Fait avec 💙 pour Ryze par Claude Code**
