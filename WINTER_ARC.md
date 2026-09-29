# Winter Arc 2026

Une série de 90 jours, du 1er octobre à la fin de l'hiver. Qui la tient gagne
un an d'abonnement. Décidé avec Badis le 28 et le 29 septembre 2026.

## Les règles

- **Une journée est validée** quand elle a au moins **2 repas notés** (deux moments
  différents : petit-déjeuner, déjeuner, dîner ou collation) **et l'objectif d'eau
  atteint**. Une journée validée avec une séance (musculation, cardio ou HIIT
  terminés) donne un carré plus foncé ; la séance n'est pas exigée.
- **Délai de grâce** : ce qui est noté pour une journée compte jusqu'au
  **lendemain midi**, heure locale. Passé ce délai la journée est figée.
- **La série part du premier jour validé**, à partir du 1er octobre 2026. Pas
  d'inscription, pas de date à choisir : la série est l'arc. Tous les abonnés
  participent (le paywall est dur, il n'y a pas d'autre utilisateur).
- **Jokers** : un joker est gagné à 30 et à 60 jours de série (2 au plus). Une
  journée ratée consomme un joker automatiquement : le carré devient un jour de
  gel et compte dans les 90. Sans joker, la série repart de zéro et les jokers
  sont perdus.
- **Le prix** : une série commencée **au plus tard le 21 décembre 2026** qui
  atteint 90 jours gagne **un an d'abonnement**. Elle finit donc au plus tard le
  **20 mars 2027**, la fin de l'hiver. Un prix par compte, non cumulable, non
  échangeable contre de l'argent. Premier gagnant possible : le 29 décembre.
- **Pas de rachat payant.**
- **Deux flammes** (décidé le 29 septembre) : la flamme normale garde sa règle
  (une activité par jour, `users.streak_count`, écrit par l'app) ; la flamme de
  glace est la série de l'arc. Pendant la saison, la pastille montre la flamme
  de glace, et la flamme normale à côté seulement si elle brûlait déjà avant le
  1er octobre. La base n'écrit plus `streak_count`
  (`20260929_winter_arc_two_flames.sql`, appliquée).

## La base (fait, migration `20260929_winter_arc.sql`, appliquée)

| Objet | Rôle |
|---|---|
| `arc_members` | le fuseau IANA de l'utilisateur (le jour se calcule à son heure) |
| `arc_days` | les journées figées après le délai de grâce : statut, repas, eau, objectif, séance |
| `arc_rewards` | les gagnants, avec `delivered_at` pour la remise du prix |
| `arc_walk(from, codes, last_start)` | la marche pure, une lettre par jour : `h` validée, `t` validée avec séance, `m` ratée, `p` en cours |
| `arc_compute(user, tz, now, persist)` | le calcul complet ; interne, révoqué pour les clients |
| `arc_state(tz)` | ce que le téléphone appelle ; fige les journées échues, inscrit un gagnant |

Les trois tables sont en lecture seule pour leur propriétaire ; seules les
fonctions écrivent. Le téléphone ne décide de rien.

`arc_state()` rend :

```json
{
  "phase": "open",              // soon | open | ended
  "today": "2026-10-06", "tz": "Europe/Paris",
  "opens": "2026-10-01", "last_start": "2026-12-21", "ends": "2027-03-20",
  "streak": 1,                  // cases validées (h, t, j)
  "streak_start": "2026-10-04",
  "cells": "hpp",               // la série case par case, aujourd'hui compris s'il y a une série
  "jokers": 0, "best": 2,
  "won_on": null, "eligible": true,
  "last_valid": "2026-10-04",
  "last_break": {"day": "2026-10-03", "lost": 2},
  "last_joker": null,
  "today_status": {"held": false, "meals": 1, "water_ml": 1000, "water_goal": 2000, "trained": false},
  "grace": {"day": "2026-10-05", "meals": 1, "water_ml": 2000, "water_goal": 2000, "deadline": "2026-10-06T10:00:00+00:00"}
}
```

Vérifié sur la base : dix séquences synthétiques pour la marche (jokers à 30 et
60, plafond à 2, coupure, grâce, victoire au 90e jour, départ le 21 contre le 22
décembre) et deux scénarios réels joués dans une transaction annulée (repas noté
le lendemain matin compté, repas noté le lendemain à 13 h refusé, séance).

**Limite connue** : `created_at` peut être forcé par un client qui appelle l'API
à la main. Les gagnants sont peu nombreux et le prix est remis à la main cette
saison : on regarde leurs entrées avant de l'envoyer.

## L'app

### Lot 1 : le cœur (fait le 29 septembre, rien de vérifié sur appareil)

| Fichier | Rôle |
|---|---|
| `lib/arc/arc_state.dart` | le modèle, `ArcSeason` (les dates côté app) ; en jours de calendrier, pas en durées (le passage à l'heure d'hiver du 25 octobre décalait la fin d'un jour) |
| `lib/arc/arc_service.dart` | appelle `arc_state(tz)`, garde la réponse par compte (`arc_state_v1_<uid>`), redemande 1,5 s après un repas, de l'eau ou une séance, prévient le coach, réécrit le widget, repose les rappels |
| `lib/arc/arc_grid.dart` | les 90 carrés (ambre validé, ambre foncé avec séance, gel pour un joker, bord d'encre pour aujourd'hui) |
| `lib/arc/arc_page.dart` | l'écran, `ArcPageBody` testable, le règlement en feuille |
| `lib/arc/arc_home_card.dart` | la carte de l'accueil, entre la phrase du coach et la semaine ; la flamme de l'accueil ouvre aussi l'arc |
| `lib/arc/arc_daily.dart` | la feuille du matin, une par jour (`ArcDaily.pick` est pur et testé) |
| `lib/arc/arc_words.dart` | « 1 repas et 0,5 L d'eau », dates, litres |

Branché dans : `MainApp` (démarrage, feuille après celle de la séance interrompue, retour au premier plan), `StreakService` (redemande l'arc après chaque activité ; la flamme normale garde sa règle), le coach (bloc `arc` après `profile`, labels FR/EN/DE), `NotificationService.scheduleArcReminders` (ids 100 à 103, remplacent le 20 h « protège ta série » pendant la saison, le tap ouvre l'arc), le paywall d'onboarding (`arc_offer`, jusqu'au 21 décembre).

Rattraper hier : les repas s'ajoutaient déjà à un jour passé (Nutrition, Historique), l'eau non, et la grâce promettait donc un rattrapage impossible. Les verres de l'historique s'éditent maintenant (`nutrition_history_page.dart`, `WaterService.getWaterEntriesOn`) et un verre noté pour un autre jour ne touche plus au compteur du jour ni aux rappels du jour. « Compléter hier » (feuille du matin et écran de l'arc) ouvre Nutrition directement sur l'historique, qui s'ouvre sur hier (`AppNavigator.requestNutritionHistory`).

La flamme de glace (choisie par Badis le 29 septembre, version « glace profonde ») : `lib/arc/winter_flame.dart`, dessinée en trois couches qui dansent de gauche à droite depuis la base, l'une après l'autre (boucle de 2,4 s), avec de petites étincelles de glace qui montent de la pointe à partir de 24 points (pas d'étoile, retirée à la demande de Badis), immobile si le téléphone réduit les animations. Exception assumée à « l'ambre est ce que Ryze rend » : la série du Winter Arc est froide (`ArcIce`), les carrés validés restent ambre. En haut à droite de l'accueil et de la Progression (`lib/arc/streak_pill.dart`, `StreakPills`), pendant la saison : la flamme de glace et le jour de l'arc, qui ouvrent l'arc, et la flamme ambre à côté si la série normale a commencé avant le 1er octobre (`GlobalStateManager.streakStart`) ; côte à côte, chacune ne montre que son nombre. Aussi dans l'en-tête de l'écran et de la carte. Aperçu : `Socials/panda winter arc/flamme_glace_animee.gif`.

L'écran de l'arc montre, à droite du titre, le panda en capuche en buste (`assets/images/coach_ryze_winter_arc_bust.webp`, 640 x 599, détouré, fondu vers le bas) à la place de la grande flamme. Les textes poussent vers la suite : « Encore 12 jours et ton année est offerte. Rendez-vous le 29 décembre. », « Encore 1 repas. Tu peux le faire. », « Ton record : 9 jours. À battre. », « Journée validée. Bien joué. ».

La feuille d'introduction (`lib/arc/arc_intro_sheet.dart`), refaite le 29 septembre après un conseil de quatre avis (texte, design, psychologie, voix de la tendance), parce que Badis n'aimait pas le texte et n'avait pas compris « tu as déjà 5 jours » :
- En haut, la nuit bord à bord : la vraie scène du panda en capuche (`assets/images/coach_ryze_winter_arc.webp`, recadrée à la taille depuis la 9:16, 47 Ko), la flamme de glace et « WINTER ARC », et le titre qui porte toute l'offre : « 90 jours d'affilée. Un an de Ryze offert. » (« Tiens l'hiver. » quand la série ne peut plus gagner).
- En bas, la bande des 90 cases telle que l'accueil la montrera : « Jour N » à gauche, « Jour 90 · date de fin » et le cadeau à droite. Les jours déjà validés s'y allument en ambre : c'est la preuve, la phrase dessous ne fait que la nommer (« Tu as déjà validé 5 jours. Sans le savoir. »). Quatre cas : nouveau (« Ton jour 1, c'est aujourd'hui », plus « Dernier départ le 21 décembre » en décembre), déjà commencé, série cassée avant de voir la feuille (« Tu avais déjà validé N jours sans le savoir. Maintenant, tu sais. »), hier encore rattrapable (« Hier compte encore jusqu'à midi : il manque… », et le geste ouvre ensuite l'historique sur hier).
- Deux règles : « 2 repas notés, bons ou pas, et ton objectif d'eau » (le « bons ou pas » répond à ceux qui arrêtent de noter les jours où ils mangent mal), puis midi le lendemain et les jokers avec leurs dates.
- Où et quand : pas dans l'onboarding (déjà long, et saisonnier), mais à la première entrée dans l'app, une fois par compte. **Avant l'ouverture aussi** (ajouté le 29 septembre pour tester et profiter de l'attente des vidéos) : l'intro s'ouvre une fois avant le 1er octobre, « Ton jour 1 : jeudi 1 octobre. », la bande finit le 29 décembre, et on s'engage déjà (« Rendez-vous jeudi 1 octobre. » après le geste ; clé `arc_intro_soon_<uid>`). Le 1er octobre, l'intro revient une dernière fois pour dire « Ton jour 1, c'est aujourd'hui » : avec un simple bouton si le geste a été fait avant (`arc_pact_<uid>`, source `preseason`), sinon avec le geste. Qui sort de l'onboarding vient de signer son pacte en maintenant un bouton : pour lui, un simple bouton « C'est parti » (`ArcDaily.pactJustSigned`, posé par `RyzeApp._goToApp`). Les abonnés existants ont le geste.
- Un seul geste : « Maintiens pour tenir l'hiver » (`HoldToSign` de l'onboarding). À la fin : étincelles, l'événement `arc_pact_signed`, la demande de notifications si elle n'a jamais été faite, et la légende passe à « Demain matin, on regarde ensemble le carré d'aujourd'hui ». Fermer sans le faire envoie `arc_intro_closed_unsigned` ; la participation reste automatique.
- L'entrée en une horloge de 1,9 s : le panda sort du noir avec un léger zoom, la flamme s'allume, le titre monte ligne par ligne, un front de givre traverse la bande, puis les jours validés s'allument un à un. Un tap saute l'entrée ; tout est immédiat si le téléphone réduit les animations.
- Corrigé en même temps : afficher l'intro marque comme vues la dernière coupure et le dernier joker (le lendemain matin n'annonce plus une perte jamais connue).
- Les mots, réécrits le 29 septembre parce que « tenu » ne se dit nulle part : en français « validé » (« Journée validée », « Jour 12 validé », « 90 jours d'affilée et ton année est offerte »), jamais « tenu » ni « tiens » ; en anglais « locked in » (la tendance), « streak freeze » au lieu de « joker » ; en allemand « geschafft », « damit dein Tag zählt », « Schaff 90 Tage am Stück ». Le coach reçoit les mêmes mots (`persona_*.dart`), le paywall aussi (`arc_offer`).
Aperçus : `Socials/panda winter arc/feuille_intro_3_cas.png` et `feuille_intro_animee.gif`.

Tests : `test/arc/arc_state_test.dart` (modèle, saison, mots, feuille du matin, bloc du coach) et `test/arc/arc_render_test.dart` (écran et carte, 320 et 430 pt, FR/EN/DE, quatre états, aucun débordement).

À vérifier sur appareil : la feuille du matin (et qu'elle ne s'empile pas avec celle de la séance), le remplissage animé, les rappels de 20 h 30 et 10 h, le tap sur un rappel, la ligne du paywall. Le règlement est un premier jet à relire.

- `ArcService` : appelle `arc_state(tz)` (fuseau par `flutter_timezone`), garde le
  dernier état, le rafraîchit après chaque repas, eau ou séance notés.
- L'écran de l'arc : la grille de 90 carrés, le jour X/90, ce qui manque
  aujourd'hui, les jokers, le règlement.
- La feuille de première ouverture du jour : le carré d'hier qui se remplit,
  « complète hier avant midi », un joker utilisé, ou une série perdue.
- La carte de l'accueil, et la flamme partout branchée sur l'arc.
- Le coach : un bloc de contexte borné (jour, ce qui manque, grâce, jokers).
- Les rappels : 20 h 30 si la journée n'est pas validée, 10 h si hier est encore
  rattrapable.
- Le paywall : « Tiens 90 jours, ton année suivante est offerte ».
- Tous les textes en FR, EN et DE dans `translations.dart`.

### Lot 2 : le widget (fait le 29 septembre, rien de vérifié sur appareil)

Dessiné avec Badis sur la page https://claude.ai/artifact/4bEZh6MoEUCJwB9A55Mhoj.
La nuit de la saison, de la neige qui tombe lentement, la flamme de glace qui
dérive doucement, et à sa gauche le mot d'ordre en lettres épaisses :
« FOCUS. » dans les trois langues tant que la journée reste à valider, puis
en ambre « VALIDÉ. » / « LOCKED IN. » / « GESCHAFFT. ». Dessous, le jour sur 90
et ce qui manque ; dans le moyen, la grille de 10 x 9. Le texte ne bouge
jamais : seules la neige et la flamme vivent. Un tap ouvre l'écran de l'arc
(`ryse://arc`).

- **Les données** : le bloc `arc` du contrat v2 (`lib/arc/arc_widget_data.dart`,
  écrit par `MealWidgetDataProvider`, réécrit à chaque réponse de la base). Tous
  les mots arrivent écrits dans la langue de l'app. Le lendemain, tant que l'app
  n'a pas réécrit, le widget ne devine pas : il reprend le mot d'ordre et dit
  « Ouvre Ryze pour ta journée ». Un état gardé d'un autre jour est traité de même.
- **iPhone** (`ios/RyseMealWidget/RyzeArcWidget.swift`) : petit, moyen, et écran
  verrouillé (monochrome : « Jour 34 / 90 » et une jauge). La neige tombe et la
  flamme dérive avec la rotation d'aiguille que WidgetKit dessine lui-même :
  chaque flocon est au bord d'une roue immense centrée hors du widget (six par
  roue, environ 35 points par seconde), chaque couche de la flamme décrit un
  petit cercle sans pencher (5,2 s, 3,7 s, 2,9 s). Cet effet est privé : Xcode 26
  ne l'expose plus (`_clockHandRotationEffect`, le build #118 a échoué dessus),
  il est donc retrouvé à l'exécution par son nom et construit depuis sa forme
  Codable (`ClockHand`, la technique de ClockHandKit, MIT). Si iOS le renomme,
  ou avec « Réduire les animations », le widget reste immobile, neige éparpillée.
  Risque assumé : une API privée peut valoir un refus à la revue d'Apple.
  Vérifié sur l'iPhone de Badis avec le build #120 (29 septembre) : ça tourne.
- **Android** (`RyzeArcWidget.kt`, `widget_arc_small.xml`, `widget_arc_medium.xml`,
  `widget_arc_flame.xml` généré) : la flamme en trois calques PNG
  (`drawable-nodpi/arc_flame_*.png`), chacun dans un `ViewFlipper` d'images
  décalées le long de son cercle, une image par dixième de seconde, un seul
  bitmap par calque ; la neige en deux nappes du même carreau
  (`drawable-xxhdpi/arc_snow_tile.png`) qui se suivent vers le bas par les
  animations d'entrée et de sortie du `ViewFlipper` (`res/anim/arc_snow_*`), 4,5 s
  par nappe. Le moyen (à partir de 250 dp) dessine la grille en bitmap. Avec les
  animations coupées dans les réglages, la neige et la flamme restent fixes.
  Le mot allemand porte un trait d'union conditionnel (`GE\u00ADSCHAFFT.`) : les
  deux widgets coupent là, un mot par ligne, jamais au milieu d'un mot.

À vérifier sur appareil : que la neige Android défile
sans à-coup à chaque nappe (sinon passer à des images fixes), le rendu du mot
d'ordre dans les trois langues, le tap qui ouvre l'arc app fermée.

### Le moment où la journée est validée (29 septembre)

`lib/arc/arc_banner.dart`. Quand la réponse de la base fait passer aujourd'hui à
validé (ou rattrape hier avant midi), un bandeau glisse en bas de l'écran, où
qu'on soit : la nuit de la saison, la flamme de glace et ses étincelles,
« Jour 12 validé » et « Plus que 78 jours. » (« Hier validé » / « Ta série
continue : 12 jours. »), la vibration de réussite. Un tap ouvre l'arc. Il attend
que « Repas ajouté · Annuler » soit parti (`RyzeUndo.visible`) et se pousse
au-dessus si une autre écriture en affiche un. Une fois par jour et par journée
(`arc_banner_today_<uid>`, `arc_banner_yesterday_<uid>`). Au retour sur
l'accueil, la case se remplit sous les yeux comme le matin
(`ArcService.takeReveal`, posée avant de prévenir l'accueil).

### Les images de l'App Store (30 septembre, version 2.0.4)

Huit planches dans `RYZE/planches-appstore/v4/<langue>/` (outils :
`_outils/serie.py`, `winter.py`, `widgets.py`) : le Winter Arc en tête
(« Lance ton Winter Arc. 90 jours = 1 an offert. », pastille « Départ jusqu'au
21 décembre », le vrai écran de l'arc au jour 34), puis le scan, le
planificateur, les widgets, et les autres planches v3. **À retirer vers le 21
décembre** : après, plus aucune série ne peut gagner et la promesse ne tient plus.

### Lot 2 bis

- La carte à partager au format story, proposée aux jours 1, 7, 30, 60 et 90.

### Lot 3 (avant le 29 décembre)

- La remise du prix : code d'offre Apple d'un an (à vérifier : pour un abonné
  actif, l'offre démarrerait au prochain renouvellement), code promo Google Play,
  ou droit offert par RevenueCat.
