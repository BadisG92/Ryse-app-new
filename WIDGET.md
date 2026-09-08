# Les widgets Ryze

Trois widgets iOS et deux widgets Android, dessinés sur le design system
(`DESIGN.md`) et pilotés par l'app. Ce document remplace les dix-sept notes
de débogage qui vivaient à la racine.

## Ce qu'ils montrent

| Widget | Où | Montre | Un tap |
|---|---|---|---|
| **Eau** (`RyzeWaterWidget`, systemSmall) | iOS, accueil | Les verres du jour (250 ml chacun, quatre à douze selon l'objectif), le prochain porte le « + ». Objectif atteint : la tuile passe en encre. | « + 1 verre » et « + 2 » écrivent sans ouvrir l'app (App Intent). Le reste ouvre le home. |
| **Repas** (`RyseMealWidget`, systemMedium) | iOS, accueil | Ce qu'il reste en Archivo, la jauge ambre, les cinq créneaux du jour dans leurs trois états (libre, prévu, fait). La séance est une pilule. | Un créneau ouvre la feuille d'ajout de ce repas, la séance ouvre Sport. |
| **Aujourd'hui** (`RyseCoachWidget`, écran verrouillé) | iOS, rectangulaire, circulaire, inline | Le reste, la jauge, et la phrase du coach du home pour cette heure. Rendu monochrome par le système. | Ouvre le home. |
| **Repas** (`RyseMealWidget.kt`, 4×2) | Android | Le même que le medium iOS. | Idem. |
| **Eau** (`RyseWaterWidget.kt`, 2×2) | Android | Le même que le small iOS. | Les boutons ouvrent l'app avec la quantité, qui l'écrit à l'arrivée. |

Les identifiants (`RyseMealWidget`, `RyseCoachWidget`, le schéma `ryse://`)
gardent l'orthographe du premier widget : les changer orphelinerait tout
widget déjà posé. Tout ce que l'utilisateur lit dit « Ryze ».

## Le contrat de données (v2)

L'app écrit un seul JSON sous la clé `widget_meal_data`, dans l'App Group
`group.com.ryze.app` sur iOS et dans les préférences de `home_widget` sur
Android. Il est construit par `MealWidgetDataProvider.buildPayload()`.

```json
{
  "v": 2,
  "day": "2026-09-08",
  "lang": "fr",
  "kcal":  { "eaten": 1240, "goal": 2100 },
  "water": { "ml": 1250, "goalMl": 2000, "glassMl": 250 },
  "slots": [
    { "slot": "breakfast", "state": "done",    "label": "Petit-déj", "word": "Fait" },
    { "slot": "lunch",     "state": "done",    "label": "Déjeuner",  "word": "Fait" },
    { "slot": "snack",     "state": "free",    "label": "Collation", "word": "Libre" },
    { "slot": "dinner",    "state": "planned", "label": "Dîner",     "word": "Prévu" },
    { "slot": "sport",     "state": "planned", "label": "Séance",    "word": "Prévu", "kind": "strength" }
  ],
  "lines": [ { "from": 0, "text": "…" }, { "from": 5, "text": "…" }, { "from": 11, "text": "…" } ],
  "strings": { "lead_remaining": "Il te reste", "unit": "kcal", "eaten_tpl": "{n} kcal mangées", "…": "…" },
  "theme": { "key": "theme_nuit", "ink": "#0B132B", "ink2": "#1B2A5B", "acc": "#F2A93B", "accInk": "#9A5F0C" }
}
```

Les règles qui font tenir l'ensemble :

- **L'app décide, le widget pose.** Les états des créneaux viennent de
  `HomeSlots.ofDay`, la source de la rangée du jour ; les phrases du coach de
  `HomeSuggestion.build`, appelée une fois par tranche horaire (0, 5, 11, 14,
  18, 22 h). Le widget et le home ne peuvent pas se contredire.
- **Les nombres voyagent bruts**, le widget les formate pour `lang` avec le
  formateur du système. C'est ce qui permet à l'intent iOS de redessiner un
  verre de plus sans réveiller l'app.
- **Le jour est une chaîne**, comparée telle quelle. Un widget ne parse jamais
  de date : les données d'un autre jour gardent les objectifs et les libellés
  et remettent à zéro tout ce qui a été mangé, bu ou prévu.
- **Chaque mot vient du dictionnaire** (`translations.dart`, FR/EN/DE), par
  `strings`. Le natif ne porte que les noms de la galerie et l'état vide dont
  il a besoin avant la première écriture : `WidgetFallback` en Swift,
  `values/`, `values-fr/`, `values-de/` sur Android.
- **La palette suit.** L'encre et l'accent sont ceux que l'utilisateur a
  choisis dans Réglages → Couleurs (`RyzeColors.palette`), envoyés dans
  `theme` et réécrits à la seconde du choix. Le papier, les gris et le
  remplissage libre ne bougent pas. Avant la première écriture, le widget
  porte la palette d'origine (`RyzePalette.nuit` en Swift, `colors_ryze.xml`
  sur Android). Sur Android, les fonds et les bords des créneaux sont des
  `ImageView` teintées, seule couleur que `RemoteViews` sait changer sur une
  forme ; la jauge suit l'accent à partir d'Android 12 et garde l'ambre
  d'origine avant.
- **Pas de mode démo** : le provider n'écrit rien quand
  `WeeklyPlannerService.isDemoMode` est vrai.

## Dans les deux sens

**App → widget.** `MealWidgetDataProvider.updateWidgetData()` reconstruit le
JSON et demande le rechargement. Il est appelé après chaque aliment ajouté,
modifié ou retiré, chaque verre d'eau, un changement de langue, une connexion,
une déconnexion et le démarrage ; et par `WidgetSyncService`, qui écoute les
événements de l'état global (plan, séance, sport, minuit, objectifs, série)
pour ce qui change les créneaux sans passer par un repas. Les appels
simultanés sont fusionnés : une rafale coûte deux synchros, pas dix.

**Widget → app.** Deux voies :

- Les liens `ryse://`, reçus par `app_links` et traités par
  `WidgetDeepLinkHandler` : `add-food?meal=<slot>[&mode=]` ouvre la feuille
  d'ajout (`AddFoodSheet`) ou un outil (`FoodAddFlow`) ; `add-water?amount=`
  écrit par `WaterService.addWaterEntry` et répond par la barre du home ;
  `sport`, `nutrition`, `progress`, `dashboard` demandent un onglet à la barre
  par `AppNavigator.requestTab`.
- L'App Intent iOS (`AddWaterIntent`) : il redessine les verres tout de suite,
  et laisse la quantité dans l'App Group, **ajoutée** à ce qui attend déjà.
  `WidgetWaterHandler` la lit au démarrage et à chaque retour au premier plan,
  l'écrit dans le journal, et la resynchronise. Tant qu'elle attend, le
  provider l'ajoute à ce qu'il écrit, pour que le widget ne recule jamais.

## Où est le code

```
lib/services/meal_widget_data_provider.dart   le contrat, la synchro
lib/services/widget_deep_link_handler.dart    ce qu'un tap ouvre
lib/services/widget_water_handler.dart        l'eau ajoutée app fermée
lib/services/widget_sync_service.dart         les événements qui resynchronisent
ios/RyseMealWidget/RyzeTokens.swift           couleurs, rayons, polices
ios/RyseMealWidget/WidgetData.swift           lecture du contrat, timeline, repli
ios/RyseMealWidget/RyzeWaterWidget.swift      Eau
ios/RyseMealWidget/RyzeMealsWidget.swift      Repas
ios/RyseMealWidget/RyzeTodayWidget.swift      Aujourd'hui (écran verrouillé)
ios/RyseMealWidget/AddWaterIntent.swift       + 1 verre sans ouvrir l'app
android/.../widget/RyzeWidgetData.kt          lecture du contrat
android/.../widget/RyseMealWidget.kt          Repas
android/.../widget/RyseWaterWidget.kt         Eau
android/.../res/values/colors_ryze.xml        les jetons
android/.../res/font/                         Archivo, Instrument Sans
```

## Vérifier sur un appareil

1. Se connecter, ajouter un aliment : le widget Repas passe le créneau en
   « Fait » et le reste baisse, sans rouvrir le widget.
2. Fermer l'app, taper « + 1 verre » sur le widget Eau : un verre se remplit.
   Rouvrir l'app : « Un verre ajouté » en bas, et le journal l'a.
3. Deux taps rapides app fermée : deux verres sur le widget, deux dans le
   journal.
4. Changer la langue de l'app : les widgets changent de langue.
5. Passer minuit sans ouvrir l'app : les widgets se remettent à zéro et
   gardent l'objectif.
6. Se déconnecter : les widgets montrent « Ouvre Ryze ».

Ce qui ne se vérifie que sur le Mac : la compilation Swift, le poids 800
d'Archivo (axe `wght` via `UIFontDescriptor`), le rendu vibrant de l'écran
verrouillé. Sur Android, la cible d'extension n'existe pas ; l'émulateur
suffit.
