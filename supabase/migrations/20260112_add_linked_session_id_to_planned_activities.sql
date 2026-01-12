-- Ajouter la colonne linked_session_id à planned_activities si elle n'existe pas
ALTER TABLE planned_activities
ADD COLUMN IF NOT EXISTS linked_session_id UUID REFERENCES workout_session_summaries(id) ON DELETE SET NULL;

-- Créer un index pour la recherche par linked_session_id
CREATE INDEX IF NOT EXISTS idx_planned_activities_linked_session_id
ON planned_activities(linked_session_id)
WHERE linked_session_id IS NOT NULL;

-- Créer un index unique pour éviter les doublons de linked_session_id dans planned_workouts
-- D'abord supprimer les doublons existants (garder le plus ancien)
DELETE FROM planned_workouts a
USING planned_workouts b
WHERE a.linked_session_id = b.linked_session_id
  AND a.linked_session_id IS NOT NULL
  AND a.created_at > b.created_at;

-- Maintenant ajouter la contrainte unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_planned_workouts_linked_session_unique
ON planned_workouts(linked_session_id)
WHERE linked_session_id IS NOT NULL;
