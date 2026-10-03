# Le dossier

Ce que Ryze a retenu de quelqu'un, écrit dans sa voix, avec un tampon rouge
qui tombe dessus. C'est la première chose de l'application faite pour sortir
d'elle. Construit le 3 octobre 2026 à partir du conseil des cinq (note du
vault growth, dossier 06 Expériences) et du prototype validé par Badis.

## Ce que l'utilisateur vit

1. **Trois portes.** La puce « Qu'est-ce que tu as retenu de moi ? » sur une
   conversation vide ; le bouton document dans l'en-tête du chat, toujours
   visible ; la ligne « Mon dossier » en tête de la feuille Mémoire du coach
   (Réglages, Coach), qui ouvre la conversation avec la question déjà envoyée.
   Une phrase libre marche aussi : « balance tout ce que tu sais sur moi »,
   « pourquoi je n'avance pas ».
2. **La carte** arrive dans le fil, pas en bulle : papier quadrillé, le titre
   « Ce que Ryze a retenu de Badis », quatre à huit faits à puce ambre, un
   seul grand nombre (« 23 faits retenus. »), la phrase du coach signée de son
   ton, et le tampon qui claque en travers sept dixièmes de seconde après la
   carte, avec un coup haptique et un léger choc de la carte.
3. **Partager** rend la même carte en 9:16 (1080 × 1920) et ouvre la feuille
   de partage du téléphone. **Corriger** ouvre la feuille Mémoire, où un tap
   sur une ligne la fait oublier.
4. Le dossier reste dans l'historique tel qu'il a été compilé, se relit en
   carte (sans retomber) et se repartage.

## Les règles

- **Les faits viennent de ce que le coach a déjà sous les yeux** : sa mémoire
  (sept tiroirs : allergies, contraintes physiques, promesses, régime, goûts,
  horaires, notes), les réponses de l'onboarding, les dernières séances et
  les records, la tendance du poids, la semaine prévue et faite, l'arc. Le
  modèle choisit et formule ; l'outil ne va rien chercher de plus.
- **Rien de médical, jamais.** Allergies, régimes et blessures sont exclus
  d'office : l'outil retire toute ligne qui reprend un mot d'un fait de ces
  tiroirs ou qui porte une racine médicale (`DossierTools.sanitize`). Si moins
  de trois lignes survivent, il n'y a pas de dossier et le modèle le sait.
- **Le tampon est un vocabulaire fermé** (`DossierStamps`, deux mots par ton,
  FR/EN/DE, seize caractères au plus). Le modèle reçoit la liste entière en
  `enum`, l'outil ramène le mot à son identité et le réécrit dans la langue du
  compte ; un mot hors liste devient « VU. ». Chaque ton sait dire quelque
  chose de bon et quelque chose à corriger : un tampon qui ne sait que punir
  ne se poste pas un mauvais dimanche.
- **Le nombre est vrai** : les lignes de la mémoire plus celles de
  l'onboarding, jamais les faits mesurés, jamais inventé. Le premier jour il
  vaut six ou sept ; c'est ce qui donne envie de redemander plus tard.
- **Les faits sont datés** depuis ce chantier (`fact_dates` dans le document
  `preferences`, par forme normalisée du fait). Le prompt porte la date en ISO
  (« Promesse : plus de tacos après minuit (2026-09-12) »), la feuille Mémoire
  l'affiche en clair. Les faits d'avant n'ont pas de date.
- **Les records** entrent dans le contexte du coach (bloc des dernières
  séances, quatre plus lourds, dans l'unité de l'utilisateur), lus dans
  `workout_set_history`.
- **Le rouge** est la deuxième exception assumée au système de couleurs, après
  la flamme de glace (`RyzeColors.stamp`, voir DESIGN.md).

## Les fichiers

| Rôle | Fichier |
|---|---|
| Le tampon et sa chute | `lib/design/stamp.dart` (`RyzeStamp`, `RyzeStampSlam`) |
| Le rendu hors écran et le partage, le sol d'une carte | `lib/design/share_card.dart` (`RyzeShare`, `RyzeShareFrame`, `RyzeGridPainter`, `RyzeShareText`) |
| La carte du fil et la carte 9:16 | `lib/design/dossier_card.dart` (`RyzeDossierCard`, `RyzeDossierPoster`) |
| Le modèle et le vocabulaire | `lib/ai/dossier.dart` (`RyzeDossier`, `DossierStamps`) |
| L'outil `memory.dossier` | `lib/ai/ryze_tools/dossier_tools.dart` |
| Le tiroir promesses, les dates | `lib/ai/ryze_memory.dart`, `lib/models/coach_chat_models.dart`, `lib/services/coach_preference_extractor.dart`, `lib/ai/ryze_tools/memory_tools.dart` |
| La persistance en carte | `coach_messages.metadata` `{kind: 'dossier', lines, stamp_id, stamp, verdict, count, persona, lang, at}` écrit par `CoachChatService._saveAction` |
| Les portes | `lib/screens/coach_chat_screen.dart` (`CoachChatScreen.open`, en-tête, puce), `lib/settings/sheets/coach_memory_sheet.dart` |
| Les consignes du coach | `lib/ai/prompts/persona_{fr,en,de}.dart` (section AGIR), intitulé `record` |
| Les textes | `translations.dart`, clés `dossier_*`, `coach_chat_suggestion_dossier`, `coach_memory_cat_promises`, `coach_memory_since` |
| Les tests | `test/ai/dossier_test.dart` |

Analytics : `dossier_compiled` (lignes, tampon) et `dossier_shared`.

## À vérifier sur appareil

Rien de ce chantier n'a tourné sur un téléphone.

1. Demander le dossier par les trois portes ; vérifier que le modèle appelle
   bien l'outil (ligne « Dossier compilé », puis la carte, puis une seule
   phrase du coach qui ne redit pas les lignes).
2. Le tampon : la chute, la vibration, le choc de la carte ; sur une édition
   sombre, l'encre doit rester lisible.
3. Un mot long (« PEUT MIEUX FAIRE », « COULD DO BETTER ») doit tenir sur deux
   lignes sans sortir de la carte.
4. Partager : l'image 1080 × 1920 doit porter les polices Archivo et
   Instrument Sans (pas de repli système), la grille, l'auréole, la marque et
   `coach-ryze.com` ; sur iPad la feuille doit s'ancrer au bouton.
5. Avec une allergie en mémoire, demander le dossier et vérifier qu'elle n'y
   figure pas.
6. Fermer et rouvrir la conversation : la carte se relit sans retomber, et
   Partager marche encore.
7. Dire « je te promets, plus de tacos après minuit » : la ligne « Retenu »
   doit viser le tiroir Promesses, et la feuille Mémoire doit afficher la date.
