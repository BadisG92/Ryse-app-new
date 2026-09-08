-- Une séance réalisée ne doit apparaître qu'une fois dans le plan.
--
-- L'index côté musculation était écrit dans une migration de janvier qui n'a
-- jamais atteint la production, et le côté cardio n'en a jamais eu. Rien
-- n'empêchait donc deux lignes planifiées de pointer vers la même séance
-- d'historique, et le planificateur pouvait la compter deux fois.
--
-- Le plus ancien gagne : c'est celui auquel la synchronisation s'est rattachée.
DELETE FROM planned_workouts a
USING planned_workouts b
WHERE a.linked_session_id = b.linked_session_id
  AND a.linked_session_id IS NOT NULL
  AND a.created_at > b.created_at;

CREATE UNIQUE INDEX IF NOT EXISTS idx_planned_workouts_linked_session_unique
ON planned_workouts(linked_session_id)
WHERE linked_session_id IS NOT NULL;

DELETE FROM planned_activities a
USING planned_activities b
WHERE a.linked_session_id = b.linked_session_id
  AND a.linked_session_id IS NOT NULL
  AND a.created_at > b.created_at;

CREATE UNIQUE INDEX IF NOT EXISTS idx_planned_activities_linked_session_unique
ON planned_activities(linked_session_id)
WHERE linked_session_id IS NOT NULL;
