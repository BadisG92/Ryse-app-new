# Refonte de l'onglet Sport

Ce qui a été fait, et pourquoi. Jumeau de `NUTRITION_REDESIGN.md`, écrit après
coup : la refonte est en place dans `lib/sport/`, ce document dit ce qu'elle
décide, pour que la prochaine session n'ait pas à relire six mille lignes.
Les règles générales sont dans `DESIGN.md`, le code du système dans
`lib/design/`.

Rien n'est livré tant que Nutrition, Sport et l'accueil ne sont pas tous faits.

## 1. Vision

L'onglet Sport est la semaine de l'utilisateur, lue comme une seule chose :
un instrument (les séances de la semaine face à l'objectif de l'onboarding),
la séance du jour dans l'un de quatre états, les dernières séances sur un
rail. Cardio et musculation ne se distinguent pas par un onglet mais par la
forme — le sport est un anneau, plein en navy pour la musculation, bordé
d'ambre pour le cardio.

Deux priorités, nommées par Badis :

1. **La séance de musculation en cours.** L'utilisateur a les mains occupées,
   il transpire, il regarde son téléphone entre deux séries : chaque tap
   compte.
2. **Le hors ligne.** Une salle a souvent peu de signal. C'est le cas normal,
   pas le cas dégradé.

## 2. Ce que l'audit avait trouvé

Quarante fichiers d'interface, ~35 900 lignes, **un seul** sur le système de
design. Trois écrans de bienvenue tutoriels, huit chemins pour démarrer une
séance, cinq fins de séance qui refaisaient la même queue à la main.

Et surtout, vérifié pas à pas : **une séance de musculation terminée sans
réseau était perdue, et l'app la célébrait quand même.** `generateUniqueSessionName`
levait avant le `try`, dans un `async void` non attendu ; ni Supabase, ni la
file locale, ni un message. Le service hors-ligne, lui, supprimait une séance
en attente après trois échecs, comptait un portail captif comme « en ligne »,
et perdait toute la file au moindre changement de langue.

## 3. La séance de musculation — `lib/sport/session/`

Un dossier où chaque fichier possède une chose. `session_models` (le modèle
vivant + le pont vers `WorkoutSession`), `rest_timer` (heure murale),
`session_controller` (le seul état mutable), `session_history` (les valeurs
fantômes), `session_voice` (la dictée par série), `session_screen`, six
widgets, quatre feuilles.

**Le geste qui compte.** Chaque cellule montre soit sa valeur, soit un
fantôme : la série précédente si elle est faite, sinon la même série de la
dernière fois, sinon la fourchette du programme. Répéter la série d'avant est
**un tap** sur la coche. Un nouveau poids : tap, deux chiffres, *Suivant*,
*Valider* — six taps, **zéro fermeture de clavier**, parce que le pavé
numérique est dessiné dans l'écran (`resizeToAvoidBottomInset: false`).

L'ancien écran demandait deux taps de champ plus un pour fermer le clavier,
par série, sans jamais rien préremplir.

**Le repos** existe (il n'existait pas) : ligne ambre, décompte, ±15 s,
*Passer*, haptique à zéro, et une notification locale si l'app est fermée.
`endsAt` est une heure murale : un téléphone verrouillé deux minutes revient
sur « repos terminé », pas sur un décompte figé.

**Rien ne se perd.** Chaque mutation appelle `_touch()` : notifier + écrire le
brouillon (débounce 400 ms), et `flushDraft()` sur pause/inactive/hidden. Une
app tuée par iOS rouvre sur « Reprendre la séance de mardi ? ».

**Quitter** passe par une feuille : *Continuer* · *Mettre en pause* ·
*Terminer* · *Abandonner*. Plus de croix silencieuse, plus de geste retour qui
jette la séance.

**Terminer** est **une** feuille au lieu de quatre dialogues, puis la pilule
d'accusé. Pas de célébration plein écran (décision de Badis, même principe que
la nourriture).

## 4. Le hors ligne

**`RyzeConnectivity`** — une seule souscription pour toute l'app, un
`ValueNotifier<bool>` qui rejoue sa valeur, et une sonde `reachable()` qui
tape `/auth/v1/health` et exige `"GoTrue"` dans le corps : un portail captif
répond 200 avec du HTML et échoue ce test. Après trois échecs consécutifs, la
sonde est sautée et l'écriture elle-même fait foi — une sonde bloquée ne peut
jamais figer la file.

**`WorkoutSessionStore`** — le brouillon, la file durable, la fin, le rejeu.
L'ordre de `finish()` est celui qui ne peut pas perdre de données :

1. construire tout le payload (aucun réseau) ;
2. **mettre en file** (prefs écrites) → effacer le brouillon → mises à jour
   locales (état global, notifications, analytics) ;
3. **puis** le réseau, sans sonde : `syncPending(onlyId:)`.

Hors ligne et « en ligne mais ça échoue » sont donc le même chemin. Une entrée
en échec repart avec `nextAttemptAt = now + min(2^n, 60) min` et **n'est
jamais supprimée**.

Le rejeu est idempotent : `persistCompletedWorkoutAsHistory` reçoit le
`history_session_id` généré au départ de la séance et retourne tout de suite
si la ligne existe. Une app tuée entre l'insertion et le retrait de la file ne
duplique rien.

La migration lit l'ancienne clé `offline_pending_sessions` : un utilisateur
avec une séance coincée ne la perd pas. Et `clearAllCache()` ne touche plus
aucune clé de file — changer de langue ne détruit plus rien.

**L'état visible est honnête** : `PendingSyncLine` dit « Hors ligne · les
séances sont gardées sur le téléphone », « 1 séance à synchroniser ·
Réessayer », ou « Synchronisation… ». **Jamais de rouge pour une séance en
file : ce n'est pas un échec.**

## 5. Les trois pages — `lib/sport/`

Le calque exact de Nutrition : la date, `RyzeSegmented`, un `PageView`.

- **Aujourd'hui** : la semaine (le compte, sept anneaux lundi → dimanche,
  navy musculation / ambre cardio, aujourd'hui cerclé), la ligne de
  synchronisation, puis la séance du jour (en cours / prévue / faite / rien)
  avec **un seul bouton** — le « + » du titre sert à commencer autre chose.
  Rien d'autre : les séances passées sont l'affaire de l'Historique.
  **L'objectif hebdomadaire n'existe que si l'utilisateur l'a fixé.** La
  question d'onboarding « combien de fois par semaine tu bouges ? » décrit
  une habitude, pas une visée ; elle ne sert qu'à pré-sélectionner la
  feuille de choix (`SportGoal`, sur le téléphone). Sans objectif : les
  faits, pas de jauge, pas de « restantes ».
- **Historique** : douze semaines de jours, chaque jour portant son anneau ;
  les séances du jour ; **« Tes exercices »**, la porte de l'analyse.
- **Programmes** : les tiens puis ceux de Ryze, en cartes, avec repli sur le
  cache puis sur les programmes de départ quand il n'y a pas de réseau.

**`StartSessionSheet`** ramène les huit anciens chemins à une feuille, avec
*Refaire* en tête (les trois derniers programmes en puces).

## 6. L'analyse des performances

Elle n'a pas disparu, elle a changé de porte — trois, dont deux nouvelles :

- **en séance**, le nom d'un exercice ouvre sa page de progression, au moment
  où l'analyse guide vraiment ;
- **dans l'historique**, « Tes exercices » liste les plus travaillés avec leur
  meilleure charge ;
- **le résumé hebdomadaire** est devenu l'instrument d'Aujourd'hui.

La page de progression suit **la meilleure série de chaque séance**, pas le
volume — le volume monte quand on ajoute des séries même sans progresser.

## 7. Cardio et HIIT

Une activité en direct occupe tout l'écran sur l'encre, comme le viseur des
caméras. Trois choses changent :

- **la pause ne coupe plus le GPS** : le flux continue, la distance dérivée
  pendant l'arrêt est retranchée à la reprise, qui n'attend donc aucune
  réacquisition ;
- **le simulateur à nombres aléatoires a disparu** : sans GPS l'écran le dit
  et compte le temps, il n'invente pas de kilomètres ;
- **le HIIT change de fond** — encre pour l'effort, papier pour le repos : le
  fond *est* le signal, lisible sans regarder.

Deux bugs de données corrigés au passage : les calories du HIIT étaient
`minutes × 12`, et sa durée enregistrée traitait des minutes comme des
secondes — un HIIT de quinze minutes s'enregistrait à 0 min et 0 kcal.

`SportSessionFlow.finishCardio` est le seul chemin d'écriture cardio :
sauvegarde → invalidations → rafraîchissement → **une seule** synchronisation
planificateur, à partir de `startTime` et non de `DateTime.now()`.

## 8. Ce qui a été supprimé

L'ancien écran de séance (5 270 lignes) et sa sauvegarde, les quatre écrans
cardio/HIIT, l'ancien onglet et son tableau de bord, les deux hybrides, le
calendrier et sa feuille de jour, `workout_actions`, la feuille de choix de
programme, le sélecteur d'exercices (825 lignes), les quatre visites guidées
que plus rien n'ouvrait, les presets HIIT français en dur, et une douzaine
d'orphelins. Les trois `celebrate*Completion` du sport sont des no-op
documentés, comme celui de la nourriture.

## 9. Vérification

`flutter analyze --no-pub` : **1 281** (référence 1 750 au début du chantier).
L'audit d'imports depuis `SportPage`
(`scratchpad/audit_sport.py`) ne remonte plus aucun écran de l'onglet avec
couleur codée, taille littérale, `AppBar`, `showDialog`, `SnackBar`,
`showModalBottomSheet` brut ou ternaire de langue. Restent hors périmètre : le
paywall (sa propre passe), deux widgets du planificateur/accueil, et des
modèles partagés qui portent des constantes de couleur.

Les scénarios à passer sur iPhone, en mode avion, sont dans le plan
(`~/.claude/plans/foamy-wishing-rabin.md`, section « Vérification ») : terminer
hors ligne, lancement à froid hors ligne, app tuée en pleine séance, repos en
arrière-plan, portail captif, changement de langue, app tuée pendant
l'écriture, deux séances prévues le même jour, Coach Ryze, cardio avec et sans
GPS, HIIT mené au bout.

## 10. Ce qui reste ouvert

- La note par exercice ou par série : `workout_set_history` n'a pas de
  colonne. Une interface qui jetterait la note à la fin mentirait.
- Le tracé GPS sur une carte : aucun paquet de cartes dans `pubspec`.
- Garder l'écran allumé pendant une séance (`wakelock`) : à trancher après un
  vrai test en salle.
- `paywall_screen.dart` (1 427 lignes, ancien design) sert à toute l'app :
  passe à part.
- La série avance le jour du rejeu, pas le jour de la séance, si l'app reste
  hors ligne jusqu'au lendemain. `notifyActivity({DateTime? on})` est une
  ligne, à décider.
