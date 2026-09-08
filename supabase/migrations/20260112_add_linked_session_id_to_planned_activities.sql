-- Une séance réalisée ne doit apparaître qu'une fois dans le plan.
--
-- Ce fichier ajoutait aussi `planned_activities.linked_session_id`, en le
-- faisant pointer vers `workout_session_summaries`. C'était la mauvaise cible :
-- cette table ne porte que du cardio, et la migration du lendemain ajoute la
-- même colonne vers `cardio_sessions`. Les deux étant en `IF NOT EXISTS`, la
-- première passée gagnait : la production a la bonne, mais une base neuve
-- aurait pris celle-ci et tous les liens cardio auraient été refusés.
--
-- La colonne appartient donc à 20260113 seul. Ne reste ici que ce qui concerne
-- les séances de musculation.

-- Un doublon existant empêcherait l'index unique de se créer : le plus ancien
-- gagne, c'est celui qui a servi à la synchronisation.
DELETE FROM planned_workouts a
USING planned_workouts b
WHERE a.linked_session_id = b.linked_session_id
  AND a.linked_session_id IS NOT NULL
  AND a.created_at > b.created_at;

CREATE UNIQUE INDEX IF NOT EXISTS idx_planned_workouts_linked_session_unique
ON planned_workouts(linked_session_id)
WHERE linked_session_id IS NOT NULL;
