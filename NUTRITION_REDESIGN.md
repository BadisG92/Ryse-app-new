# Refonte de l'onglet Nutrition

Plan d'implémentation. Il s'adresse à la session qui va porter la refonte en
Flutter. Tout ce qui est décidé est ici ; ce qui reste ouvert est marqué comme
tel. La référence visuelle et gestuelle est le prototype interactif :
https://claude.ai/code/artifact/fa7db40d-84ec-4517-b5ee-9d1e10a6fc30
Les règles générales sont dans
`DESIGN.md` et le code du système dans `lib/design/`. La page d'accueil déjà
portée (`lib/home/`) est le modèle de code à suivre : mêmes tokens, mêmes
composants, même façon de brancher les données.

Rien n'est livré tant que Nutrition, Sport et l'accueil ne sont pas tous faits.
Ne pas pousser de build TestFlight depuis cette refonte.

## 1. Vision

L'onglet Nutrition est la journée de l'utilisateur, lue comme une seule chose et
non comme une pile de cartes. En haut, un instrument : ce qu'il reste de
l'objectif calorique, avec trois rails pour les macros. Dessous, l'eau en
verres. Dessous, les repas en ligne de temps, chacun avec son heure réelle, son
état, ce qu'il contient, et son bouton pour ajouter. Tout ce qui est affiché se
touche. Rien n'est répété.

Ce qui fait la différence avec la page actuelle, en une phrase : aujourd'hui la
même donnée est écrite jusqu'à six fois et presque rien n'est cliquable ; demain
chaque donnée est écrite une fois et chaque ligne est une commande.

Ce que l'utilisateur a demandé, mot pour mot : ergonomique, les données utiles
et seulement elles, joli, des retours haptiques et de petits sons, engageant,
facile, beau. Plus de « blocs carrés compacts posés là ».

## 2. Ce qui existe et ce qu'il devient

| Aujourd'hui | Fichier | Devient |
|---|---|---|
| Bandeau permanent kcal · eau · sport · série au-dessus des trois pages | `lib/components/ui/global_state_header.dart`, monté dans `nutrition_section.dart` | **Supprimé.** Il répète ce qui est en dessous et n'est pas cliquable |
| Onglets soulignés « Tableau de bord / Journal / Recettes » | `nutrition_section.dart` `_buildHeader` | **Contrôle segmenté** « Aujourd'hui / Historique / Recettes », composant `RyzeSegmented` |
| `MainCaloriesCard` : cercle dégradé, compteur, trois KPI, barre, pourcentage | `lib/components/ui/nutrition_cards.dart` | **Remplacé** par `DayInstrument`, partagé avec l'accueil |
| `MacronutrientsCard` : trois lignes navy et gris | `nutrition_cards.dart` | **Fusionné** dans l'instrument : trois rails en encre sur gris, sans couleur par macro (§ 3.2) |
| `HydrationCard` : « 1,2 L / 2,0 L », barre, bouton + | `nutrition_cards.dart` | **Remplacé** par `GlassRow` : des verres qu'on remplit et qu'on vide au tap |
| `MealsCard` : compteur N/4 et quatre lignes non cliquables | `nutrition_cards.dart` | **Remplacé** par `MealTimeline` |
| `NutritionQuickActionsSection` : cinq icônes rondes « Ajouter rapidement » | `lib/components/ui/nutrition_widgets.dart` | **Seul le widget disparaît.** La classe porte aussi tous les helpers d'écriture de l'app et ne doit pas être supprimée : voir § 2 bis |
| Page Journal : cartes de repas repliées, résumé du jour, calendrier | `lib/components/nutrition_journal_hybrid.dart`, `lib/widgets/nutrition/meal_card.dart` | La partie « aujourd'hui » **fusionne** dans la page 1. La page 2 devient **Historique** : le calendrier, puis les jours passés |
| Calendrier mensuel avec intensité par jour | `lib/widgets/nutrition/calendar_view.dart` | **Gardé**, restylé : intensité ambre au lieu de bleu, cases 9 pt de rayon, aujourd'hui cerclé d'encre |
| Feuille des cinq façons d'ajouter, écrite trois fois | `nutrition_widgets.dart` `_showAddFoodOptionsForDashboard`, `…ForNewMeal`, `…ForExistingMeal` | **Une seule** `AddFoodSheet(meal)` sur `RyzeSheet` |
| `MealSelectionBottomSheet`, `NewMealTypeBottomSheet`, `AddMealBottomSheet` | `lib/bottom_sheets/` | **Retirés du parcours** : le repas est toujours connu quand on ajoute, puisqu'on part d'une ligne de repas. Ne les supprimer du dépôt qu'après avoir retiré leurs derniers appelants (§ 2 bis) |
| `WaterBottomSheet` : trois presets et quantité libre | `nutrition_widgets.dart` | **Remplacé** par une petite `RyzeSheet` de puces (25, 50, 75 cl, 1 L, autre), ouverte par le verre « + » en appui long. `NutritionBottomSheetHelper.showWaterSheet` reste tant que l'accueil et le widget iOS l'appellent (§ 2 bis) |
| Page Recettes | `lib/components/nutrition_recipes_hybrid.dart` | **Gardée avec ses images**, rendue par le même composant dans cette passe. Elle devient le lieu du « je remange la même chose » : la feuille d'ajout fait remonter les plats récents (§ 5), et le titre de la page peut devenir « Mes plats » (§ 11) |
| Snackbars vertes et rouges | `lib/components/ui/custom_snackbar.dart` | **Plus utilisées** sur cet onglet. Voir § 6, la barre d'annulation |

Code mort à supprimer dans la même passe, il n'est plus référencé :
`lib/components/main_dashboard_hybrid.dart`, `lib/components/ui/dashboard_widgets.dart`,
`lib/components/ui/dashboard_cards.dart`, `lib/components/bottom_navigation.dart`,
`lib/screens/manual_food_entry_screen.dart`, `lib/bottom_sheets/food_details_bottom_sheet.dart`,
et dans `nutrition_widgets.dart` les fonctions suffixées `_OLD`. Vérifier chaque
suppression avec `flutter analyze` : la référence est 2027 problèmes, tous
antérieurs.

## 2 bis. Ne rien débrancher : ce qui doit survivre

Vérifié dans le code le 7 septembre 2026. Deux choses portent le nom de « widget »
mais sont en réalité la plomberie d'écriture de toute l'app. **Les supprimer
casserait l'accueil, le journal et le widget iOS.**

**`NutritionQuickActionsSection`** n'est pas seulement la rangée de cinq icônes.
C'est la classe qui contient les helpers statiques appelés partout :

| Helper | Appelé depuis |
|---|---|
| `showMealSelectionForDashboard` | `lib/home/home_page.dart` (le nouvel accueil), `dashboard_widgets.dart` (mort) |
| `showAddFoodOptionsForNewMeal` | `lib/home/home_page.dart`, `nutrition_journal_hybrid.dart`, `widget_deep_link_handler.dart` (widget iOS) |
| `showAddFoodOptionsForExistingMeal` | `nutrition_journal_hybrid.dart` |
| `addFoodToSelectedMeal`, `addFoodToNewMealJournalStyle`, `addRecipeToNewMealJournalStyle` | `nutrition_dashboard_hybrid.dart`, et les rappels des cinq outils |
| `showMealSelectionForManualEntry` | `nutrition_dashboard_hybrid.dart` |

Marche à suivre : **extraire ces helpers dans `lib/services/food_add_flow.dart`**
avant de toucher à l'UI, faire pointer tous les appelants dessus, puis
supprimer le widget des cinq icônes. Le nouvel `AddFoodSheet` appelle le même
service. Ainsi l'accueil et le widget iOS continuent de marcher pendant toute la
refonte.

**`NutritionBottomSheetHelper.showWaterSheet`** est appelé par
`lib/home/home_page.dart` et par `lib/services/widget_deep_link_handler.dart`.
Le garder jusqu'à ce que la `RyzeSheet` des quantités le remplace des deux côtés.

**Ce qui est déjà sûr, et c'est l'essentiel.** `FoodEntriesService.addFoodEntry`
se suffit à lui-même : il écrit dans `food_entries`, met à jour
`GlobalStateManager` (calories et macros), rafraîchit le compte de repas,
notifie la nutrition, synchronise le planificateur et annule les rappels du
repas. **Toute UI qui appelle `addFoodEntry` reste connectée sans rien d'autre
à câbler.** Il attend `userId`, `mealName` (un nom reconnu par
`FoodEntriesService._mealTypeMapping`), `foodItem`, `consumedAt` et un `mealId`
optionnel obtenu par `generateMealId(userId, mealName, forDate)`.

**Le piège à corriger : deux plomberies parallèles.** Les cinq outils ne se
comportent pas pareil.

| Outil | Contrat actuel |
|---|---|
| `AIScannerScreen` | reçoit `mealName` + `mealId`, **écrit lui-même** |
| `AIChatInputScreen` | reçoit `mealName` + `mealId`, **écrit lui-même** |
| `BarcodeScannerScreen` | reçoit un rappel `onFoodScanned`, **rend un `FoodItem`**, l'appelant écrit. Reçoit aussi `mealId` mais **ne le lit jamais** |
| `ManualFoodSearchBottomSheet` | rappel `onFoodCreated`, rend un `FoodItem` ; `mealName`/`mealId` stockés mais jamais relus |
| `SelectRecipeScreen` | rappel `onRecipeSelected`, rend un `FoodItem` ; `mealName`/`mealId` jamais relus |

Décision : **unifier sur le contrat par paramètres.** Chaque outil reçoit
`mealName`, `mealId` et `consumedAt`, et écrit lui-même via `addFoodEntry`.
Les rappels disparaissent. C'est le contrat que deux outils sur cinq respectent
déjà, c'est celui qui survit à une ouverture depuis un lien profond, et c'est
lui qui règle le bug du code-barres qui dit « ajouté » sans écrire.

## 3. La page « Aujourd'hui », bloc par bloc

Fond : `OnbBackground(scene: false)`, le papier quadrillé de l'onboarding.
Gouttière : `context.vw(5.1)`. Police, tailles et couleurs : uniquement via
`RyzeText`, `context.vw` et `RyzeColors`. Aucun `Color(0x…)`, aucun `fontSize`
en dur, aucun texte littéral.

### 3.1 En-tête

La date en toutes lettres, semi-gras encre, 3,6 vw. Sous elle, le contrôle
segmenté à trois positions, pleine largeur, 34 pt de haut, fond `paper2`, la
position active en `surf` avec une ombre `soft`. Changer de page fait un retour
haptique de sélection et remet le défilement en haut.

### 3.2 L'instrument

`DayInstrument`, extrait de `lib/home/widgets/day_instrument.dart` vers
`lib/design/day_instrument.dart` pour être partagé, avec ces différences par
rapport à l'accueil :

- La jauge fait 10 pt, se remplit en **ambre** (`RyzeColors.acc`) sur `idle`, sans aiguille. C'est ce que `DESIGN.md` prescrit ; l'accueil sera aligné plus tard.
- Sous la ligne « mangé / objectif », trois rails de 6 pt, une par macro, dans l'ordre protéines, glucides, lipides. Nom à gauche en 3,3 vw semi-gras `mute`, rail au milieu rempli en `RyzeColors.ink` sur `idle`, valeur à droite « **70** / 150 g » en 3,1 vw. **Pas de couleur par macro** : les rails sont empilés et nommés, la couleur n'apporterait rien, et l'ambre reste réservé à la jauge des calories. Les tokens `RyzeColors.protein / carbs / fat` restent dans `tokens.dart` pour un éventuel écran de détail, pas sur cette surface ; aligner la phrase correspondante de `DESIGN.md` (« the three macro dots ») dans la même passe.
- Le nombre roule avec `RollingNumber` depuis une forme à zéros de même longueur, comme sur l'accueil. Corriger au passage le défaut connu : `_DigitColumn` dans `pickers.dart` n'expose pas de ligne de base, donc « kcal » saute au-dessus du chiffre sous 1 000. Ajouter dans son `Stack` un premier enfant non positionné `Opacity(opacity: 0, child: Text('0', style: style))`.
- Quand l'objectif est dépassé, l'amorce devient « Au-dessus de l'objectif » et le chiffre est signé. Quand il est atteint exactement, l'amorce devient « Objectif atteint » et le chiffre disparaît, on ne montre pas un zéro géant.

Données : `GlobalStateManager` pour `currentCalories`, `calorieGoal`,
`currentProteins / Carbs / Fats`, `proteinGoal / carbsGoal / fatGoal`. Tout
existe déjà.

### 3.3 L'eau

Titre « Eau » à gauche, « **0,5** / 2 L » à droite. Dessous, `GlassRow` : autant
de verres que l'objectif divisé par 25 cl, huit pour 2 L, répartis sur la
largeur, 44 pt de haut, coins 8 pt en haut et 11 pt en bas pour dessiner un
verre. Vide : `surf` et bord `line`. Plein : bord encre et remplissage encre qui
monte en 340 ms. Le prochain verre vide a un bord pointillé `mute2` et un « + ».

Gestes :
- Tap sur le prochain vide : `WaterService.addWaterEntry(amount: 250, sourceType: 'glass')`. Retour haptique léger, son « tic ». Au dernier verre : retour de succès et le petit accord.
- Tap sur un verre plein : le niveau redescend juste sous ce verre. Supprimer les dernières entrées d'eau du jour jusqu'à ce que le total soit inférieur ou égal à ce nombre de verres fois 250 ml, via `WaterService.deleteWaterEntry`, qui existe et n'a jamais été branché. Retour haptique de retrait, barre d'annulation « Verre retiré » qui réinsère les entrées supprimées. Pas d'appui long sur les verres : Badis ne l'a pas découvert dans le prototype, le tap est le geste attendu.
- Appui long sur le verre « + » pointillé : la feuille des quantités, puces 25 cl, 50 cl, 75 cl, 1 L, et un champ « autre ».

L'objectif d'eau : `updateDailyWaterGoal` existe dans `WaterService` et n'est
appelé nulle part. Le brancher dans les réglages, pas ici.

### 3.4 Les repas, en ligne de temps

Titre « Mes repas » à gauche, « 1 / 4 » à droite. Dessous, `MealTimeline` : un
rail vertical de 2 pt en `line` à gauche, et quatre rangées, toujours les
quatre : petit-déjeuner, déjeuner, collation, dîner. Dans Nutrition la collation
est toujours affichée, contrairement à l'accueil, parce que c'est ici qu'on en
ajoute une.

Chaque rangée porte un point de 16 pt sur le rail, dans les trois états du
système : libre = papier bordé `idle` ; prévu = `surf` bordé encre ; fait = encre
avec une coche blanche. Puis, sur la ligne principale : le nom du repas en
4 vw semi-gras, l'heure en 3,1 vw `mute2`, et à droite soit les calories
« 400 kcal » avec un chevron, soit un bouton rond « + » de 32 pt à bord
pointillé. Sur la seconde ligne, en 3,2 vw `mute` : les aliments joints par des
virgules si le repas est fait, « Prévu · Poulet, riz, brocolis » si le
planificateur l'a prévu, « Rien d'enregistré » sinon.

L'heure est **l'heure réelle** : celle du premier aliment enregistré
(`consumed_at`), sinon celle du repas prévu, sinon l'heure déclarée par
l'utilisateur dans ses préférences de notifications (`breakfastTime`,
`lunchTime`, `dinnerTime`, dans `NotificationPreferences`). Les constantes
factices de `FoodEntriesService` (8 h, 12 h 30, 16 h, 19 h 30) ne s'affichent
plus.

Gestes :
- Tap sur une rangée faite : elle **s'ouvre sur place**, `AnimatedSize` de 420 ms sur `RyzeCurves.out`, le chevron tourne. Dedans, une ligne par aliment : nom, portion en `mute`, calories, et une croix. En bas, un bouton fantôme « Ajouter un aliment ». Retour haptique de sélection.
- Tap sur une rangée prévue ou libre, ou sur son « + » : `AddFoodSheet(meal)`.
- Croix sur un aliment : la ligne glisse vers la gauche et disparaît, `FoodEntriesService.removeFoodEntry`. Pas de dialogue de confirmation : la barre d'annulation du § 6. Retour haptique de retrait.
- Après un ajout : la rangée passe à fait, son point grossit d'un tiers puis revient (spring 420 ms), le chiffre roule, les rails avancent. Retour de succès et l'accord.

### 3.5 L'état de départ

Un nouvel abonné à 10 h voit : l'objectif en amorce, le chiffre plein, la
jauge à zéro, les trois rails à zéro, huit verres vides, quatre rangées dont le
déjeuner et le dîner sont « Prévu · … » s'il a validé le plan de démo pendant
l'onboarding. Ce n'est pas un état vide : c'est un plan à suivre.

## 4. La page « Historique »

Le calendrier existant, restylé, en haut. Sous lui, la liste des jours passés
de la semaine en cours puis des précédents, une ligne par jour : date en
semi-gras, une petite barre ambre de 54 pt remplie à la fraction de l'objectif,
et les calories. Taper un jour du calendrier ou une ligne ouvre **la même
`MealTimeline` que la page 1, pour ce jour-là**, en lecture et en écriture.

Écriture sur un jour passé : c'est un bug aujourd'hui, l'entrée est écrite sur
aujourd'hui quel que soit le jour affiché. Tous les chemins vivants d'ajout
codent `DateTime.now()` en dur alors que `addFoodEntry` accepte `consumedAt` et
`generateMealId` accepte `forDate`. La `MealTimeline` porte sa date et la
transmet à `AddFoodSheet`, qui la transmet aux cinq outils. Liste des sites à
corriger : `nutrition_widgets.dart` lignes 2526, 2734, 2842, 2851, 2954 ;
`barcode_scanner_screen.dart` 2078 et 2136 ; `ai_scanner_screen.dart` 1741,
1859, 1924 ; `ai_analysis_screen.dart` 316 ; `recipe_details_screen.dart` 1047.
Les numéros de ligne datent du 7 septembre 2026, les retrouver par `grep
DateTime.now()` dans ces fichiers.

## 5. Les composants à construire

Tous dans `lib/design/`, exportés par `design.dart`, documentés d'une ligne
dans `DESIGN.md` sous « Components ».

| Composant | Rôle | Réutilisé par |
|---|---|---|
| `RyzeSheet` | La feuille du système : papier, coins 24, poignée 36 × 5 `idle`, fond assombri à 34 %, hauteur au contenu, glisser vers le bas pour fermer, actions collées en bas, la page recule de 4,5 % derrière. Entrée `spring` 460 ms | Nutrition, puis l'accueil et Sport |
| `RyzeSegmented` | Le contrôle à deux ou trois positions du § 3.1 | Nutrition, Historique |
| `RyzeHaptics` | Cinq retours : `light`, `selection`, `medium`, `success`, `removal`, sur `HapticFeedback` de Flutter. Le service actuel `HapticService` ne sait que vibrer | Partout |
| `RyzeSounds` | Quatre sons très courts, un tic, une sélection, un accord de deux notes pour un succès, un son grave pour un retrait. Fichiers dans `assets/sounds/`, moins de 100 ms chacun sauf l'accord, joués par `audioplayers` en catégorie ambiante pour respecter le bouton silencieux. Un réglage pour couper, activé par défaut | Partout |
| `UndoBar` | Voir § 6 | Nutrition, puis l'accueil |
| `DayInstrument` | Déplacé depuis `lib/home/widgets/`, avec le paramètre `macros: true` | Accueil, Nutrition |
| `MacroRail` | Un rail du § 3.2 | Instrument, plus tard le détail d'un repas |
| `GlassRow` | § 3.3 | Nutrition, plus tard l'accueil |
| `MealTimeline`, `MealRow`, `FoodItemRow` | § 3.4 | Nutrition, Historique |
| `AddFoodSheet` | Titre = le repas, sous-titre « Comment veux-tu l'ajouter ? ». **D'abord un bloc « Récents »** : jusqu'à six puces horizontales, nom du plat et calories, un tap l'ajoute au repas courant avec sa dernière portion, retour de succès, même chemin d'écriture que les cinq façons avec `consumedAt` transmis. Source : `DatabaseService.getFrequentlyUsedFoods(userId, limit: 6)`, qui existe déjà et calcule les aliments les plus utilisés sur 30 jours, fusionné avec les recettes de l'utilisateur récemment enregistrées (`RecipeService.getAllRecipes()`), triés par dernier usage. **Filtrés par type de repas** : on ne propose pas du poulet au petit-déjeuner. La table `food_entries` porte déjà `meal_type` ; la requête ne le sélectionne pas aujourd'hui, il faut ajouter un paramètre `mealType` et un `.eq('meal_type', mealType)` aux deux sous-requêtes. Si moins de trois récents sortent pour ce repas, compléter avec les récents tous repas confondus plutôt que d'afficher une rangée vide. Puis les cinq rangées de 58 pt : icône dans un rond papier de 38 pt, libellé semi-gras, aide en `mute` dessous, chevron. Ouvre l'outil avec le repas **et la date** déjà connus | Nutrition, l'accueil |

Sur les cinq outils que la feuille ouvre : `AIScannerScreen` et
`AIChatInputScreen` utilisent bien `mealName` et `mealId` reçus.
`BarcodeScannerScreen` les reçoit et **ne lit jamais `mealId`** : par le lien
profond du widget iOS, il affiche « ajouté » sans rien écrire. `SelectRecipeScreen`
et `ManualFoodSearchBottomSheet` les stockent sans les relire. Les trois sont à
corriger pour que le repas choisi soit celui écrit.

## 6. La barre d'annulation

Chaque écriture sur cet onglet est un seul tap, sans confirmation, et donc
réversible pendant quatre secondes. `UndoBar` : une barre encre de 44 pt,
coins 999, épinglée juste au-dessus de la barre d'onglets, texte blanc à gauche
« Verre ajouté » ou « Pain complet retiré », bouton « Annuler » en ambre à
droite. Elle glisse depuis le bas en 220 ms et repart seule. Annuler appelle
l'inverse de l'écriture : `deleteWaterEntry`, `removeFoodEntry`, ou la
réinsertion de l'aliment retiré avec ses valeurs.

Si l'écriture échoue hors ligne, la même barre passe en `RyzeColors.danger` et
dit « Pas de réseau, gardé pour plus tard » ; l'entrée va dans l'`offline_queue`
existant. Aujourd'hui `addWaterEntry` renvoie vrai avant la base et annule en
silence en cas d'échec : l'utilisateur voit le verre se remplir puis se vider
sans un mot.

Aucune snackbar verte sur cet onglet : le vert est réservé aux boutons de
validation par `DESIGN.md`.

## 7. Les données : une seule définition de « fait »

Aujourd'hui l'accueil et le tableau de bord Nutrition ne sont pas d'accord.
L'accueil croise le plan de la semaine et le journal, avec trois états
(`lib/home/home_slots.dart`). Le tableau de bord dit qu'un repas est fait si
ses calories dépassent zéro (`nutrition_dashboard_hybrid.dart`). Les deux
peuvent se contredire le même jour.

Décision : **la définition de `HomeSlots.ofDay` est la seule.** Un repas est
fait s'il a au moins un aliment dans le journal ce jour-là, ou si son repas
planifié est validé. Il est prévu si le planificateur l'a prévu et qu'il n'est
pas fait. Sinon il est libre. Extraire cette logique dans `lib/services/day_meals.dart`,
une classe `DayMeals` qui, pour une date, renvoie les quatre repas avec état,
heure réelle, aliments, calories et macros ; l'accueil et Nutrition la lisent
tous les deux. La collation compte toujours dans Nutrition ; l'accueil continue
de la cacher quand elle est libre.

Les macros par aliment sont stockées (`proteins`, `carbs`, `fats` dans
`food_entries`) et jamais affichées. Elles alimentent les rails, et le détail
d'un aliment ouvert peut les montrer sur une seconde ligne.

## 8. Les bugs à corriger dans la même passe

1. Écriture sur un jour passé (§ 4).
2. Impossible de corriger une quantité : il n'existe aucune mise à jour de `food_entries`. Ajouter `FoodEntriesService.updateFoodEntryQuantity(id, quantity)` qui recalcule calories et macros au prorata, et une petite feuille avec un pas de quantité, ouverte par un tap sur un aliment dans la rangée dépliée.
3. L'eau ne peut ni être retirée ni corrigée (§ 3.3).
4. L'objectif d'eau n'est modifiable nulle part (§ 3.3).
5. Le lien profond code-barres avec repas dit « ajouté » sans écrire (§ 5).
6. Depuis le tableau de bord, « Rechercher » demandait le repas puis redemandait « Rechercher ». Disparaît avec les cinq icônes.
7. Le bandeau affiche la série avec une flamme, alors que la série n'est jamais incrémentée par un enregistrement : `ActivityTracker` n'a aucun site d'appel. Brancher `ActivityTracker.notifyFoodAdded` et `notifyWaterAdded` dans les écritures de cet onglet, et passer `StreakService._toleranceDays` de 7 à 1.
8. Aucun chemin pour remanger un plat : ni récents, ni favoris, ni répéter un repas. Couvert par le bloc « Récents » de la feuille d'ajout (§ 5).

## 9. Les textes

Tous via `AppTranslations` dans `lib/services/translations.dart`, en français,
anglais et allemand, sous un commentaire `// Nutrition tab, the day as a line`.
Aucun littéral dans les widgets. Les repas s'appellent, dans le journal et dans
la base, par les noms que `FoodEntriesService._mealTypeMapping` reconnaît :
`meal_name_breakfast` = Petit-déjeuner / Breakfast / Frühstück, et ainsi de
suite ; ces quatre clés existent déjà. En allemand, `Mittagessen` et
`Abendessen`, jamais `Mittag` ni `Abend`, et les jours abrégés sur deux
lettres.

Voix : celle de l'onboarding. Des amorces courtes, jamais un reproche, jamais
une affirmation que l'app ne peut pas vérifier. « Rien d'enregistré », pas
« Tu n'as rien mangé ».

Nouvelles clés, avec leur usage : `nutri_page_today` Aujourd'hui,
`nutri_page_history` Historique, `nutri_page_recipes` Recettes, `nutri_water`
Eau, `nutri_meals` Mes repas, `nutri_nothing_logged` Rien d'enregistré,
`nutri_planned_prefix` Prévu, `nutri_add_food` Ajouter un aliment,
`nutri_how_add` Comment veux-tu l'ajouter ?, les cinq façons `way_photo`,
`way_barcode`, `way_search`, `way_recipe`, `way_coach` avec leur aide
`way_*_hint`, `undo` Annuler, `undo_glass_added` Verre ajouté,
`undo_item_removed` {name} retiré, `undo_offline` Pas de réseau, gardé pour
plus tard, `nutri_goal_over` Au-dessus de l'objectif, `nutri_goal_met` Objectif
atteint, `nutri_history_day` {d}, `water_other` Autre quantité, `way_recent`
Récents / Recent / Zuletzt, `undo_glass_removed` Verre retiré / Glass removed /
Glas entfernt.

## 10. Ordre de travail

1. Les fondations : `RyzeSheet`, `RyzeSegmented`, `RyzeHaptics`, `RyzeSounds`, `UndoBar`. Rien d'autre n'avance sans elles, et elles serviront à Sport et à l'accueil.
2. `DayMeals` (§ 7), avec l'accueil rebranché dessus pour ne garder qu'une définition.
3. `DayInstrument` déplacé dans `lib/design/` avec les rails ; `GlassRow` ; `MacroRail`.
4. La page « Aujourd'hui » : en-tête, instrument, eau, ligne de temps. Brancher les données, les gestes, les retours.
5. `AddFoodSheet` et les cinq outils avec repas et date transmis, en corrigeant les trois qui les ignorent.
6. La page « Historique » sur la même `MealTimeline`.
7. Les bugs du § 8 qui ne sont pas encore couverts.
8. La suppression du code mort du § 2, puis `flutter analyze` à la référence.

Chaque étape se termine par `flutter analyze --no-pub` à 2027 problèmes ou
moins, aucun texte littéral, aucune couleur hors tokens. Ne pas lancer
`flutter run`.

## 11. Ce qui reste ouvert

- Les sons : activés par défaut, ou désactivés ? Le prototype les propose activés et coupés d'un bouton.
- L'accueil doit-il adopter la jauge ambre de Nutrition ? `DESIGN.md` dit oui. À aligner quand on reviendra sur l'accueil.
- Le nom de la troisième page une fois les récents en place : « Recettes » ou « Mes plats ».

## Prototype

Référence interactive de tout ce qui précède, avec les gestes et les retours
rendus visibles : https://claude.ai/code/artifact/fa7db40d-84ec-4517-b5ee-9d1e10a6fc30
(aussi dans `/artifacts` de Claude Code). Le prototype de l'accueil, dont
Nutrition reprend le langage : https://claude.ai/code/artifact/b53dd846-0f64-4139-8c11-8954775d0ecc.
