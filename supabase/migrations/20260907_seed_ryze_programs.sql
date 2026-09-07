-- Programmes préremplis Ryze — 16 séances, tous niveaux, tous groupes.
--
-- À exécuter dans l'éditeur SQL de Supabase (la clé anonyme ne peut pas
-- écrire dans workout_templates : la RLS le refuse, et c'est très bien).
--
-- Le script est idempotent : les identifiants sont dérivés du nom du
-- programme, et un ON CONFLICT met à jour au lieu de dupliquer. Le rollback
-- est en bas du fichier.
--
-- Contraintes respectées, toutes vérifiées dans le code de l'app :
--   * name_fr <> name_en, sinon getWorkoutTemplates classe le programme
--     comme « créé par toi » (il déduit isCustom de nameEn == nameFr).
--   * is_custom = false et user_id = null : c'est ce que l'app lit pour
--     les programmes publics.
--   * target_muscle_groups et equipment_needed sont des tableaux.
--   * order_index commence à 1.
--   * suggested_reps_* sont des répétitions : aucun gainage chronométré,
--     la table n'a pas de champ de durée.

BEGIN;

-- 1. Vérification préalable : les 38 exercices distincts existent-ils ?
--    Si ce SELECT renvoie autre chose que 0, arrêter et corriger.
SELECT count(*) AS exercices_manquants
FROM (VALUES
  ('01f539da-0679-475d-8cdd-8db6864d3981'::uuid),
  ('03aa2521-4aa5-428a-ad26-1c20ab9a05e7'::uuid),
  ('082efe4a-c290-4701-99bf-023ad364c618'::uuid),
  ('0c5ba191-8238-4257-9bfc-eadd1ede44fe'::uuid),
  ('117a6828-b503-431d-b53e-d4a5a0bd49e2'::uuid),
  ('1bfbc465-1d9e-4008-9434-1e61590b7786'::uuid),
  ('2b0c7270-1847-4117-a5b0-fd630dc56cd7'::uuid),
  ('2f5dc0de-8030-470b-8348-09d806d070fd'::uuid),
  ('34c290a8-33bc-4dc6-997d-56769dbf8339'::uuid),
  ('3617568c-7209-4c6e-9623-8a6a5652a08b'::uuid),
  ('412918c1-f509-49db-8c5b-0fd60c28f433'::uuid),
  ('4fd6e517-678d-403b-8a2f-0466d1436ef6'::uuid),
  ('5572f829-6649-437e-9763-aa7143214102'::uuid),
  ('65dba642-044f-4a88-9cd4-e9b57a7f6c80'::uuid),
  ('66010524-fa6c-4956-b11e-99d47284b56b'::uuid),
  ('7b908cbc-60e5-4fd9-ad36-162d664f9845'::uuid),
  ('7d360077-d233-4642-a73f-b9b3578acc6a'::uuid),
  ('7f95deb6-f91f-4c0e-999e-3af919807347'::uuid),
  ('8fb248c2-dda5-46e1-ac33-062b582403dd'::uuid),
  ('920f5e10-257c-4387-823a-e172846fa3af'::uuid),
  ('92854f01-1c31-4d84-8be5-9cd677e699e0'::uuid),
  ('a2d71c48-6f32-4113-91c0-40aba8fb11a3'::uuid),
  ('a53236fc-4f5b-4da4-b809-526682c3fd1e'::uuid),
  ('a569f281-dc9e-431e-9bbd-895cdc991b67'::uuid),
  ('ac315b27-cbee-41c6-90d0-7ff462b1e00c'::uuid),
  ('aee22256-f236-467d-b3ff-544db82d4497'::uuid),
  ('b1638e88-f6f9-4f29-aaed-e2cee78e8351'::uuid),
  ('b313a1ac-8377-42b6-8483-392d5b5816b4'::uuid),
  ('c07a0cf9-78a5-471f-b9ee-de0c785d6dfa'::uuid),
  ('c3d4e5f6-a7b8-4901-c2d3-e4f5a6b7c8d9'::uuid),
  ('c3f21f19-7c2a-47b9-a225-e72d9c968dd8'::uuid),
  ('c7277e64-ca3a-4dc2-ac83-dedb38935ff1'::uuid),
  ('c767496f-39c4-409f-ad6d-979916f49ad9'::uuid),
  ('e0f20ec7-4bc9-4d37-a254-d0269bdaa8d8'::uuid),
  ('e6eda087-2e35-4dd2-83c4-e584322041d7'::uuid),
  ('e90f1801-3362-4b96-b345-6b8f7c4e3138'::uuid),
  ('f0b7e1ea-0c52-4231-9feb-4ac64aa12222'::uuid),
  ('f370d97c-4876-41d9-86f5-59fced0c4b53'::uuid)
) AS v(id)
WHERE NOT EXISTS (SELECT 1 FROM exercises e WHERE e.id = v.id);

-- 2. Les en-têtes.
INSERT INTO workout_templates (
  id, name_fr, name_en, name_de, description_fr, description_en, description_de,
  difficulty_level, estimated_duration_minutes, target_muscle_groups,
  equipment_needed, calories_burned_estimate, is_custom, is_public, user_id
) VALUES
  ('39b62e9f-0c6f-5040-b856-e40b13985afd', 'Débutant — Haut du corps', 'Beginner — Upper Body', 'Anfänger — Oberkörper',
   'Cinq mouvements guidés pour apprendre le haut du corps sans se mettre en danger.', 'Five guided movements to learn the upper body safely.', 'Fünf geführte Übungen, um den Oberkörper sicher zu lernen.',
   'beginner', 40, ARRAY['Chest', 'Back', 'Shoulder', 'Bicep', 'Triceps']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('5cc808e1-220b-564c-9038-dee6b9334c36', 'Débutant — Bas du corps', 'Beginner — Lower Body', 'Anfänger — Unterkörper',
   'Les jambes en cinq exercices, charge légère et amplitude complète.', 'Legs in five exercises, light load and full range.', 'Beine in fünf Übungen, leichte Last und volle Bewegung.',
   'beginner', 40, ARRAY['Leg', 'Glute', 'Calves']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2', 'Débutant — Corps entier', 'Beginner — Full Body', 'Anfänger — Ganzkörper',
   'Une séance complète en cinq mouvements : la meilleure façon de commencer.', 'A complete session in five movements: the best way to start.', 'Eine komplette Einheit in fünf Übungen: der beste Einstieg.',
   'beginner', 35, ARRAY['Leg', 'Chest', 'Back', 'Glute']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('60467b43-a099-508c-87ec-06fcf71abb45', 'Débutant — Abdos', 'Beginner — Abs', 'Anfänger — Bauch',
   'Quatre exercices au sol, sans matériel, à faire n''importe où.', 'Four floor exercises, no equipment, anywhere.', 'Vier Bodenübungen, ohne Geräte, überall machbar.',
   'beginner', 25, ARRAY['Ab']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('95f40040-a99b-5cf7-b6cc-f6a1e8765303', 'Débutant — Fessiers', 'Beginner — Glutes', 'Anfänger — Gesäß',
   'Cinq exercices ciblés, du pont fessier au hip thrust.', 'Five targeted exercises, from glute bridge to hip thrust.', 'Fünf gezielte Übungen, von der Brücke bis zum Hip Thrust.',
   'beginner', 35, ARRAY['Glute', 'Leg']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('ee13cc9f-e6a5-5376-9b59-466830b3515b', 'Intermédiaire — Poussée', 'Intermediate — Push', 'Fortgeschritten — Drücken',
   'Pectoraux, épaules et triceps : la moitié poussée d''un programme en deux temps.', 'Chest, shoulders and triceps: the push half of a two-way split.', 'Brust, Schultern und Trizeps: die Druckhälfte eines Zweier-Splits.',
   'intermediate', 45, ARRAY['Chest', 'Shoulder', 'Triceps']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('4351d081-4692-5ff3-ad2b-84ec1cf0b431', 'Intermédiaire — Tirage', 'Intermediate — Pull', 'Fortgeschritten — Ziehen',
   'Dos et biceps : la moitié tirage d''un programme en deux temps.', 'Back and biceps: the pull half of a two-way split.', 'Rücken und Bizeps: die Zughälfte eines Zweier-Splits.',
   'intermediate', 45, ARRAY['Back', 'Bicep', 'Shoulder']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('3522c39c-7ae7-5dca-94e6-2328794b85ed', 'Intermédiaire — Jambes', 'Intermediate — Legs', 'Fortgeschritten — Beine',
   'Squat lourd, chaîne postérieure, mollets. La séance qui fatigue le plus.', 'Heavy squat, posterior chain, calves. The session that costs the most.', 'Schwere Kniebeuge, hintere Kette, Waden. Die anstrengendste Einheit.',
   'intermediate', 45, ARRAY['Leg', 'Glute', 'Calves']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a', 'Intermédiaire — Haut du corps', 'Intermediate — Upper Body', 'Fortgeschritten — Oberkörper',
   'Six mouvements aux barres et haltères, poussée et tirage dans la même séance.', 'Six barbell and dumbbell movements, push and pull in one session.', 'Sechs Übungen mit Lang- und Kurzhantel, Drücken und Ziehen in einer Einheit.',
   'intermediate', 50, ARRAY['Chest', 'Back', 'Shoulder', 'Bicep', 'Triceps']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('ea178f21-20e3-5db2-b8a6-40b09322ad8f', 'Intermédiaire — Corps entier', 'Intermediate — Full Body', 'Fortgeschritten — Ganzkörper',
   'Les cinq mouvements de base, une fois chacun. Idéal à trois séances par semaine.', 'The five basic lifts, once each. Ideal at three sessions a week.', 'Die fünf Grundübungen, je einmal. Ideal bei drei Einheiten pro Woche.',
   'intermediate', 50, ARRAY['Leg', 'Chest', 'Back', 'Shoulder']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('f5495f3d-ae14-59dc-a07a-0171134d03db', 'Intermédiaire — Abdos', 'Intermediate — Abs', 'Fortgeschritten — Bauch',
   'Cinq exercices dont le relevé de jambes suspendu, avec charge à la poulie.', 'Five exercises including hanging leg raises, with cable resistance.', 'Fünf Übungen samt hängendem Beinheben, mit Kabelwiderstand.',
   'intermediate', 35, ARRAY['Ab']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('b34e162c-bab2-5ef4-8e23-5d12fff83acf', 'Avancé — Poussée', 'Advanced — Push', 'Profi — Drücken',
   'Force en début de séance, volume ensuite. Six exercices, repos longs.', 'Strength first, volume after. Six exercises, long rests.', 'Kraft zuerst, dann Volumen. Sechs Übungen, lange Pausen.',
   'advanced', 60, ARRAY['Chest', 'Shoulder', 'Triceps']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('65d989d0-0db1-5df5-ad91-a89833c8b72c', 'Avancé — Tirage', 'Advanced — Pull', 'Profi — Ziehen',
   'Soulevé de terre lourd puis tout le dos. À ne pas mettre la veille d''une séance de jambes.', 'Heavy deadlift then the whole back. Not the day before a leg session.', 'Schweres Kreuzheben, dann der ganze Rücken. Nicht am Tag vor dem Beintraining.',
   'advanced', 60, ARRAY['Back', 'Bicep', 'Shoulder']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('cd18a75f-0463-56e4-b5a0-f7d82f57f075', 'Avancé — Jambes et fessiers', 'Advanced — Legs and Glutes', 'Profi — Beine und Gesäß',
   'Squat lourd, unilatéral, hip thrust. La séance la plus exigeante du lot.', 'Heavy squat, single-leg work, hip thrust. The most demanding of the set.', 'Schwere Kniebeuge, einbeinig, Hip Thrust. Die anspruchsvollste Einheit.',
   'advanced', 60, ARRAY['Leg', 'Glute', 'Calves']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('de7c2dfc-28ef-599f-ab31-d99ca23495eb', 'Avancé — Corps entier', 'Advanced — Full Body', 'Profi — Ganzkörper',
   'Les grands mouvements dans une seule séance, pour qui s''entraîne deux fois par semaine.', 'The big lifts in one session, for training twice a week.', 'Die großen Übungen in einer Einheit, für zweimal pro Woche.',
   'advanced', 60, ARRAY['Leg', 'Chest', 'Back', 'Shoulder']::text[], ARRAY[]::text[], 0, false, true, NULL),
  ('335317e8-3f86-51a9-8a80-5b37646e45cf', 'Express — 30 minutes', 'Express — 30 Minutes', 'Express — 30 Minuten',
   'Quatre mouvements, repos courts, tout le corps. Pour les jours sans temps.', 'Four movements, short rests, whole body. For days with no time.', 'Vier Übungen, kurze Pausen, ganzer Körper. Für Tage ohne Zeit.',
   'beginner', 25, ARRAY['Leg', 'Chest', 'Back', 'Ab']::text[], ARRAY[]::text[], 0, false, true, NULL)
ON CONFLICT (id) DO UPDATE SET
  name_fr = EXCLUDED.name_fr, name_en = EXCLUDED.name_en, name_de = EXCLUDED.name_de,
  description_fr = EXCLUDED.description_fr, description_en = EXCLUDED.description_en,
  description_de = EXCLUDED.description_de, difficulty_level = EXCLUDED.difficulty_level,
  estimated_duration_minutes = EXCLUDED.estimated_duration_minutes,
  target_muscle_groups = EXCLUDED.target_muscle_groups, updated_at = now();

-- 3. Les exercices. On repart de zéro pour ces 16 programmes, pour que
--    rejouer le script ne laisse pas d'anciennes lignes derrière.
DELETE FROM workout_template_exercises WHERE template_id IN (
  '39b62e9f-0c6f-5040-b856-e40b13985afd',
  '5cc808e1-220b-564c-9038-dee6b9334c36',
  '2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2',
  '60467b43-a099-508c-87ec-06fcf71abb45',
  '95f40040-a99b-5cf7-b6cc-f6a1e8765303',
  'ee13cc9f-e6a5-5376-9b59-466830b3515b',
  '4351d081-4692-5ff3-ad2b-84ec1cf0b431',
  '3522c39c-7ae7-5dca-94e6-2328794b85ed',
  'a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a',
  'ea178f21-20e3-5db2-b8a6-40b09322ad8f',
  'f5495f3d-ae14-59dc-a07a-0171134d03db',
  'b34e162c-bab2-5ef4-8e23-5d12fff83acf',
  '65d989d0-0db1-5df5-ad91-a89833c8b72c',
  'cd18a75f-0463-56e4-b5a0-f7d82f57f075',
  'de7c2dfc-28ef-599f-ab31-d99ca23495eb',
  '335317e8-3f86-51a9-8a80-5b37646e45cf'
);

INSERT INTO workout_template_exercises (
  template_id, exercise_id, order_index, suggested_sets,
  suggested_reps_min, suggested_reps_max, suggested_rest_seconds
) VALUES
  -- Débutant — Haut du corps : 5 exercices, 15 séries, 40 min
  ('39b62e9f-0c6f-5040-b856-e40b13985afd', 'b1638e88-f6f9-4f29-aaed-e2cee78e8351', 1, 3, 10, 12, 90),  -- Développé à la machine
  ('39b62e9f-0c6f-5040-b856-e40b13985afd', '1bfbc465-1d9e-4008-9434-1e61590b7786', 2, 3, 10, 12, 90),  -- Tirage vertical
  ('39b62e9f-0c6f-5040-b856-e40b13985afd', '3617568c-7209-4c6e-9623-8a6a5652a08b', 3, 3, 10, 12, 90),  -- Développé militaire avec haltères
  ('39b62e9f-0c6f-5040-b856-e40b13985afd', '01f539da-0679-475d-8cdd-8db6864d3981', 4, 3, 10, 12, 60),  -- Curl à la barre
  ('39b62e9f-0c6f-5040-b856-e40b13985afd', '92854f01-1c31-4d84-8be5-9cd677e699e0', 5, 3, 12, 15, 60),  -- Pushdown triceps corde
  -- Débutant — Bas du corps : 5 exercices, 15 séries, 40 min
  ('5cc808e1-220b-564c-9038-dee6b9334c36', '082efe4a-c290-4701-99bf-023ad364c618', 1, 3, 10, 12, 90),  -- Goblet squat
  ('5cc808e1-220b-564c-9038-dee6b9334c36', '920f5e10-257c-4387-823a-e172846fa3af', 2, 3, 10, 12, 90),  -- Presse à cuisses
  ('5cc808e1-220b-564c-9038-dee6b9334c36', 'f370d97c-4876-41d9-86f5-59fced0c4b53', 3, 3, 10, 12, 90),  -- Soulevé de terre roumain
  ('5cc808e1-220b-564c-9038-dee6b9334c36', 'c767496f-39c4-409f-ad6d-979916f49ad9', 4, 3, 12, 15, 60),  -- Leg curl assis
  ('5cc808e1-220b-564c-9038-dee6b9334c36', 'c07a0cf9-78a5-471f-b9ee-de0c785d6dfa', 5, 3, 12, 15, 60),  -- Élévation mollets debout
  -- Débutant — Corps entier : 5 exercices, 15 séries, 35 min
  ('2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2', '082efe4a-c290-4701-99bf-023ad364c618', 1, 3, 10, 12, 90),  -- Goblet squat
  ('2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2', 'b1638e88-f6f9-4f29-aaed-e2cee78e8351', 2, 3, 10, 12, 90),  -- Développé à la machine
  ('2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2', '1bfbc465-1d9e-4008-9434-1e61590b7786', 3, 3, 10, 12, 90),  -- Tirage vertical
  ('2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2', '7f95deb6-f91f-4c0e-999e-3af919807347', 4, 3, 12, 15, 60),  -- Pont fessier
  ('2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2', '0c5ba191-8238-4257-9bfc-eadd1ede44fe', 5, 3, 12, 15, 45),  -- Crunch
  -- Débutant — Abdos : 4 exercices, 13 séries, 25 min
  ('60467b43-a099-508c-87ec-06fcf71abb45', '0c5ba191-8238-4257-9bfc-eadd1ede44fe', 1, 4, 12, 15, 45),  -- Crunch
  ('60467b43-a099-508c-87ec-06fcf71abb45', 'b313a1ac-8377-42b6-8483-392d5b5816b4', 2, 3, 10, 15, 45),  -- Relevé de jambes couché
  ('60467b43-a099-508c-87ec-06fcf71abb45', 'e90f1801-3362-4b96-b345-6b8f7c4e3138', 3, 3, 12, 15, 45),  -- Crunch oblique
  ('60467b43-a099-508c-87ec-06fcf71abb45', '5572f829-6649-437e-9763-aa7143214102', 4, 3, 20, 30, 45),  -- Mountain climbers
  -- Débutant — Fessiers : 5 exercices, 15 séries, 35 min
  ('95f40040-a99b-5cf7-b6cc-f6a1e8765303', '7f95deb6-f91f-4c0e-999e-3af919807347', 1, 3, 12, 15, 60),  -- Pont fessier
  ('95f40040-a99b-5cf7-b6cc-f6a1e8765303', 'a53236fc-4f5b-4da4-b809-526682c3fd1e', 2, 4, 10, 12, 90),  -- Hip Thrust
  ('95f40040-a99b-5cf7-b6cc-f6a1e8765303', 'a569f281-dc9e-431e-9bbd-895cdc991b67', 3, 3, 10, 12, 60),  -- Fente poids du corps
  ('95f40040-a99b-5cf7-b6cc-f6a1e8765303', 'c7277e64-ca3a-4dc2-ac83-dedb38935ff1', 4, 3, 15, 20, 45),  -- Abduction de hanche à la machine
  ('95f40040-a99b-5cf7-b6cc-f6a1e8765303', 'f370d97c-4876-41d9-86f5-59fced0c4b53', 5, 2, 10, 12, 90),  -- Soulevé de terre roumain
  -- Intermédiaire — Poussée : 5 exercices, 18 séries, 45 min
  ('ee13cc9f-e6a5-5376-9b59-466830b3515b', '65dba642-044f-4a88-9cd4-e9b57a7f6c80', 1, 4, 6, 10, 120),  -- Développé couché
  ('ee13cc9f-e6a5-5376-9b59-466830b3515b', '412918c1-f509-49db-8c5b-0fd60c28f433', 2, 3, 8, 10, 90),  -- Développé militaire
  ('ee13cc9f-e6a5-5376-9b59-466830b3515b', 'ac315b27-cbee-41c6-90d0-7ff462b1e00c', 3, 3, 8, 12, 90),  -- Développé incliné avec haltères
  ('ee13cc9f-e6a5-5376-9b59-466830b3515b', '7d360077-d233-4642-a73f-b9b3578acc6a', 4, 4, 12, 15, 60),  -- Élévation latérale avec haltères
  ('ee13cc9f-e6a5-5376-9b59-466830b3515b', '92854f01-1c31-4d84-8be5-9cd677e699e0', 5, 4, 10, 15, 60),  -- Pushdown triceps corde
  -- Intermédiaire — Tirage : 5 exercices, 18 séries, 45 min
  ('4351d081-4692-5ff3-ad2b-84ec1cf0b431', 'e6eda087-2e35-4dd2-83c4-e584322041d7', 1, 4, 5, 10, 120),  -- Traction pronation
  ('4351d081-4692-5ff3-ad2b-84ec1cf0b431', '8fb248c2-dda5-46e1-ac33-062b582403dd', 2, 4, 8, 10, 90),  -- Rowing à la barre
  ('4351d081-4692-5ff3-ad2b-84ec1cf0b431', '1bfbc465-1d9e-4008-9434-1e61590b7786', 3, 3, 10, 12, 90),  -- Tirage vertical
  ('4351d081-4692-5ff3-ad2b-84ec1cf0b431', 'c3f21f19-7c2a-47b9-a225-e72d9c968dd8', 4, 4, 12, 15, 60),  -- Face pull
  ('4351d081-4692-5ff3-ad2b-84ec1cf0b431', '01f539da-0679-475d-8cdd-8db6864d3981', 5, 3, 8, 12, 60),  -- Curl à la barre
  -- Intermédiaire — Jambes : 5 exercices, 18 séries, 45 min
  ('3522c39c-7ae7-5dca-94e6-2328794b85ed', '03aa2521-4aa5-428a-ad26-1c20ab9a05e7', 1, 4, 6, 10, 120),  -- Squat
  ('3522c39c-7ae7-5dca-94e6-2328794b85ed', 'f370d97c-4876-41d9-86f5-59fced0c4b53', 2, 3, 8, 10, 90),  -- Soulevé de terre roumain
  ('3522c39c-7ae7-5dca-94e6-2328794b85ed', '920f5e10-257c-4387-823a-e172846fa3af', 3, 3, 10, 12, 90),  -- Presse à cuisses
  ('3522c39c-7ae7-5dca-94e6-2328794b85ed', 'c767496f-39c4-409f-ad6d-979916f49ad9', 4, 3, 10, 12, 60),  -- Leg curl assis
  ('3522c39c-7ae7-5dca-94e6-2328794b85ed', 'c07a0cf9-78a5-471f-b9ee-de0c785d6dfa', 5, 5, 12, 15, 45),  -- Élévation mollets debout
  -- Intermédiaire — Haut du corps : 6 exercices, 19 séries, 50 min
  ('a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a', '65dba642-044f-4a88-9cd4-e9b57a7f6c80', 1, 4, 6, 10, 120),  -- Développé couché
  ('a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a', '8fb248c2-dda5-46e1-ac33-062b582403dd', 2, 4, 8, 10, 90),  -- Rowing à la barre
  ('a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a', '412918c1-f509-49db-8c5b-0fd60c28f433', 3, 3, 8, 10, 90),  -- Développé militaire
  ('a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a', '1bfbc465-1d9e-4008-9434-1e61590b7786', 4, 3, 10, 12, 90),  -- Tirage vertical
  ('a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a', '01f539da-0679-475d-8cdd-8db6864d3981', 5, 3, 8, 12, 60),  -- Curl à la barre
  ('a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a', '92854f01-1c31-4d84-8be5-9cd677e699e0', 6, 2, 12, 15, 60),  -- Pushdown triceps corde
  -- Intermédiaire — Corps entier : 5 exercices, 17 séries, 50 min
  ('ea178f21-20e3-5db2-b8a6-40b09322ad8f', '03aa2521-4aa5-428a-ad26-1c20ab9a05e7', 1, 4, 6, 10, 120),  -- Squat
  ('ea178f21-20e3-5db2-b8a6-40b09322ad8f', '65dba642-044f-4a88-9cd4-e9b57a7f6c80', 2, 4, 6, 10, 120),  -- Développé couché
  ('ea178f21-20e3-5db2-b8a6-40b09322ad8f', '8fb248c2-dda5-46e1-ac33-062b582403dd', 3, 4, 8, 10, 90),  -- Rowing à la barre
  ('ea178f21-20e3-5db2-b8a6-40b09322ad8f', 'f370d97c-4876-41d9-86f5-59fced0c4b53', 4, 3, 8, 10, 90),  -- Soulevé de terre roumain
  ('ea178f21-20e3-5db2-b8a6-40b09322ad8f', '7d360077-d233-4642-a73f-b9b3578acc6a', 5, 2, 12, 15, 60),  -- Élévation latérale avec haltères
  -- Intermédiaire — Abdos : 5 exercices, 16 séries, 35 min
  ('f5495f3d-ae14-59dc-a07a-0171134d03db', '66010524-fa6c-4956-b11e-99d47284b56b', 1, 4, 8, 12, 60),  -- Relevé de jambes suspendu
  ('f5495f3d-ae14-59dc-a07a-0171134d03db', 'aee22256-f236-467d-b3ff-544db82d4497', 2, 4, 12, 15, 60),  -- Crunch à la poulie
  ('f5495f3d-ae14-59dc-a07a-0171134d03db', '2b0c7270-1847-4117-a5b0-fd630dc56cd7', 3, 3, 15, 20, 45),  -- Crunch vélo
  ('f5495f3d-ae14-59dc-a07a-0171134d03db', 'c3d4e5f6-a7b8-4901-c2d3-e4f5a6b7c8d9', 4, 3, 20, 30, 45),  -- Russian twist
  ('f5495f3d-ae14-59dc-a07a-0171134d03db', '5572f829-6649-437e-9763-aa7143214102', 5, 2, 30, 40, 45),  -- Mountain climbers
  -- Avancé — Poussée : 6 exercices, 22 séries, 60 min
  ('b34e162c-bab2-5ef4-8e23-5d12fff83acf', '65dba642-044f-4a88-9cd4-e9b57a7f6c80', 1, 5, 4, 6, 150),  -- Développé couché
  ('b34e162c-bab2-5ef4-8e23-5d12fff83acf', '412918c1-f509-49db-8c5b-0fd60c28f433', 2, 4, 6, 8, 120),  -- Développé militaire
  ('b34e162c-bab2-5ef4-8e23-5d12fff83acf', 'ac315b27-cbee-41c6-90d0-7ff462b1e00c', 3, 4, 8, 10, 90),  -- Développé incliné avec haltères
  ('b34e162c-bab2-5ef4-8e23-5d12fff83acf', '4fd6e517-678d-403b-8a2f-0466d1436ef6', 4, 3, 8, 12, 90),  -- Dips
  ('b34e162c-bab2-5ef4-8e23-5d12fff83acf', '7d360077-d233-4642-a73f-b9b3578acc6a', 5, 4, 12, 15, 60),  -- Élévation latérale avec haltères
  ('b34e162c-bab2-5ef4-8e23-5d12fff83acf', '34c290a8-33bc-4dc6-997d-56769dbf8339', 6, 2, 12, 15, 60),  -- Extension triceps au-dessus de la tête à la poulie
  -- Avancé — Tirage : 6 exercices, 22 séries, 60 min
  ('65d989d0-0db1-5df5-ad91-a89833c8b72c', 'f0b7e1ea-0c52-4231-9feb-4ac64aa12222', 1, 4, 3, 5, 180),  -- Soulevé de terre
  ('65d989d0-0db1-5df5-ad91-a89833c8b72c', 'e6eda087-2e35-4dd2-83c4-e584322041d7', 2, 4, 6, 10, 120),  -- Traction pronation
  ('65d989d0-0db1-5df5-ad91-a89833c8b72c', '8fb248c2-dda5-46e1-ac33-062b582403dd', 3, 4, 6, 8, 120),  -- Rowing à la barre
  ('65d989d0-0db1-5df5-ad91-a89833c8b72c', 'e0f20ec7-4bc9-4d37-a254-d0269bdaa8d8', 4, 3, 10, 12, 90),  -- Tirage horizontal assis à la machine
  ('65d989d0-0db1-5df5-ad91-a89833c8b72c', 'c3f21f19-7c2a-47b9-a225-e72d9c968dd8', 5, 4, 15, 20, 60),  -- Face pull
  ('65d989d0-0db1-5df5-ad91-a89833c8b72c', '117a6828-b503-431d-b53e-d4a5a0bd49e2', 6, 3, 10, 12, 60),  -- Curl incliné avec haltères
  -- Avancé — Jambes et fessiers : 6 exercices, 22 séries, 60 min
  ('cd18a75f-0463-56e4-b5a0-f7d82f57f075', '03aa2521-4aa5-428a-ad26-1c20ab9a05e7', 1, 5, 4, 6, 180),  -- Squat
  ('cd18a75f-0463-56e4-b5a0-f7d82f57f075', 'f370d97c-4876-41d9-86f5-59fced0c4b53', 2, 4, 6, 8, 120),  -- Soulevé de terre roumain
  ('cd18a75f-0463-56e4-b5a0-f7d82f57f075', 'a2d71c48-6f32-4113-91c0-40aba8fb11a3', 3, 3, 8, 10, 90),  -- Fente bulgare
  ('cd18a75f-0463-56e4-b5a0-f7d82f57f075', 'a53236fc-4f5b-4da4-b809-526682c3fd1e', 4, 4, 8, 10, 90),  -- Hip Thrust
  ('cd18a75f-0463-56e4-b5a0-f7d82f57f075', 'c767496f-39c4-409f-ad6d-979916f49ad9', 5, 3, 10, 12, 60),  -- Leg curl assis
  ('cd18a75f-0463-56e4-b5a0-f7d82f57f075', 'c07a0cf9-78a5-471f-b9ee-de0c785d6dfa', 6, 3, 12, 15, 45),  -- Élévation mollets debout
  -- Avancé — Corps entier : 6 exercices, 21 séries, 60 min
  ('de7c2dfc-28ef-599f-ab31-d99ca23495eb', '03aa2521-4aa5-428a-ad26-1c20ab9a05e7', 1, 4, 5, 8, 150),  -- Squat
  ('de7c2dfc-28ef-599f-ab31-d99ca23495eb', '65dba642-044f-4a88-9cd4-e9b57a7f6c80', 2, 4, 5, 8, 150),  -- Développé couché
  ('de7c2dfc-28ef-599f-ab31-d99ca23495eb', 'e6eda087-2e35-4dd2-83c4-e584322041d7', 3, 4, 6, 10, 120),  -- Traction pronation
  ('de7c2dfc-28ef-599f-ab31-d99ca23495eb', 'f370d97c-4876-41d9-86f5-59fced0c4b53', 4, 3, 8, 10, 90),  -- Soulevé de terre roumain
  ('de7c2dfc-28ef-599f-ab31-d99ca23495eb', '412918c1-f509-49db-8c5b-0fd60c28f433', 5, 3, 8, 10, 90),  -- Développé militaire
  ('de7c2dfc-28ef-599f-ab31-d99ca23495eb', 'c3f21f19-7c2a-47b9-a225-e72d9c968dd8', 6, 3, 15, 20, 60),  -- Face pull
  -- Express — 30 minutes : 4 exercices, 12 séries, 25 min
  ('335317e8-3f86-51a9-8a80-5b37646e45cf', '082efe4a-c290-4701-99bf-023ad364c618', 1, 3, 10, 12, 60),  -- Goblet squat
  ('335317e8-3f86-51a9-8a80-5b37646e45cf', '2f5dc0de-8030-470b-8348-09d806d070fd', 2, 3, 8, 12, 60),  -- Développé couché avec haltères
  ('335317e8-3f86-51a9-8a80-5b37646e45cf', '7b908cbc-60e5-4fd9-ad36-162d664f9845', 3, 3, 10, 12, 60),  -- Rowing à un bras avec haltère
  ('335317e8-3f86-51a9-8a80-5b37646e45cf', '5572f829-6649-437e-9763-aa7143214102', 4, 3, 20, 30, 45)  -- Mountain climbers
;

-- 4. Contrôle : 16 lignes, et le compte d'exercices de chacune.
SELECT t.name_fr, t.difficulty_level, t.estimated_duration_minutes AS minutes,
       count(e.*) AS exercices, sum(e.suggested_sets) AS series
FROM workout_templates t
JOIN workout_template_exercises e ON e.template_id = t.id
WHERE t.id IN ('39b62e9f-0c6f-5040-b856-e40b13985afd', '5cc808e1-220b-564c-9038-dee6b9334c36', '2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2', '60467b43-a099-508c-87ec-06fcf71abb45', '95f40040-a99b-5cf7-b6cc-f6a1e8765303', 'ee13cc9f-e6a5-5376-9b59-466830b3515b', '4351d081-4692-5ff3-ad2b-84ec1cf0b431', '3522c39c-7ae7-5dca-94e6-2328794b85ed', 'a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a', 'ea178f21-20e3-5db2-b8a6-40b09322ad8f', 'f5495f3d-ae14-59dc-a07a-0171134d03db', 'b34e162c-bab2-5ef4-8e23-5d12fff83acf', '65d989d0-0db1-5df5-ad91-a89833c8b72c', 'cd18a75f-0463-56e4-b5a0-f7d82f57f075', 'de7c2dfc-28ef-599f-ab31-d99ca23495eb', '335317e8-3f86-51a9-8a80-5b37646e45cf')
GROUP BY t.id, t.name_fr, t.difficulty_level, t.estimated_duration_minutes
ORDER BY t.difficulty_level, t.name_fr;

COMMIT;

-- ---------------------------------------------------------------------
-- ROLLBACK — supprime exactement ces 16 programmes, rien d'autre.
--
-- BEGIN;
-- DELETE FROM workout_template_exercises WHERE template_id IN (
--   '39b62e9f-0c6f-5040-b856-e40b13985afd',  -- Débutant — Haut du corps
--   '5cc808e1-220b-564c-9038-dee6b9334c36',  -- Débutant — Bas du corps
--   '2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2',  -- Débutant — Corps entier
--   '60467b43-a099-508c-87ec-06fcf71abb45',  -- Débutant — Abdos
--   '95f40040-a99b-5cf7-b6cc-f6a1e8765303',  -- Débutant — Fessiers
--   'ee13cc9f-e6a5-5376-9b59-466830b3515b',  -- Intermédiaire — Poussée
--   '4351d081-4692-5ff3-ad2b-84ec1cf0b431',  -- Intermédiaire — Tirage
--   '3522c39c-7ae7-5dca-94e6-2328794b85ed',  -- Intermédiaire — Jambes
--   'a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a',  -- Intermédiaire — Haut du corps
--   'ea178f21-20e3-5db2-b8a6-40b09322ad8f',  -- Intermédiaire — Corps entier
--   'f5495f3d-ae14-59dc-a07a-0171134d03db',  -- Intermédiaire — Abdos
--   'b34e162c-bab2-5ef4-8e23-5d12fff83acf',  -- Avancé — Poussée
--   '65d989d0-0db1-5df5-ad91-a89833c8b72c',  -- Avancé — Tirage
--   'cd18a75f-0463-56e4-b5a0-f7d82f57f075',  -- Avancé — Jambes et fessiers
--   'de7c2dfc-28ef-599f-ab31-d99ca23495eb',  -- Avancé — Corps entier
--   '335317e8-3f86-51a9-8a80-5b37646e45cf',  -- Express — 30 minutes
--   NULL);
-- DELETE FROM workout_templates WHERE id IN (
--   '39b62e9f-0c6f-5040-b856-e40b13985afd',
--   '5cc808e1-220b-564c-9038-dee6b9334c36',
--   '2a3f5a22-21a5-5c23-8d79-79a7e94fc9d2',
--   '60467b43-a099-508c-87ec-06fcf71abb45',
--   '95f40040-a99b-5cf7-b6cc-f6a1e8765303',
--   'ee13cc9f-e6a5-5376-9b59-466830b3515b',
--   '4351d081-4692-5ff3-ad2b-84ec1cf0b431',
--   '3522c39c-7ae7-5dca-94e6-2328794b85ed',
--   'a907ef7f-7e52-572b-ab8f-e3dbc37d4d0a',
--   'ea178f21-20e3-5db2-b8a6-40b09322ad8f',
--   'f5495f3d-ae14-59dc-a07a-0171134d03db',
--   'b34e162c-bab2-5ef4-8e23-5d12fff83acf',
--   '65d989d0-0db1-5df5-ad91-a89833c8b72c',
--   'cd18a75f-0463-56e4-b5a0-f7d82f57f075',
--   'de7c2dfc-28ef-599f-ab31-d99ca23495eb',
--   '335317e8-3f86-51a9-8a80-5b37646e45cf',
--   NULL);
-- COMMIT;

-- ---------------------------------------------------------------------
-- OPTIONNEL — retirer les 7 anciens programmes, qui font double emploi
-- avec ceux-ci et dont « Séance fessiers » tient 11 exercices et 55 séries
-- pour 60 min annoncées. Réversible : la ligne reste, elle sort seulement
-- de la liste publique (l'app ne lit que is_custom = false).
--
-- UPDATE workout_templates SET is_custom = true, updated_at = now()
-- WHERE is_custom = false AND user_id IS NULL
--   AND name_fr IN ('Séance bas du corps', 'Séance corps complet', 'Séance fessiers',
--                   'Séance haut du corps', 'Séance jambes', 'Séance poussée', 'Séance tirage');
--
-- Pour les remettre : la même requête avec is_custom = false.
