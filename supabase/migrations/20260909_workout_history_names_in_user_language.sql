-- L'historique des séries affichait des noms d'exercices dans la mauvaise
-- langue.
--
-- Le cache hors ligne des exercices ne retenait pas la langue dans laquelle il
-- avait été rempli : une fois écrit, il resservait les mêmes noms, et ces noms
-- partaient dans l'historique à chaque séance enregistrée. Un compte français
-- se retrouvait avec « Bench Press » à côté de « Développé couché », donc le
-- même mouvement sous deux noms, et deux moyennes de charge au lieu d'une.
--
-- Le nom se relit ici depuis le catalogue, dans la langue du compte. Seules
-- les lignes rattachées à un exercice du catalogue sont touchées : celles qui
-- pointent vers un exercice sur mesure gardent le nom que l'utilisateur a
-- choisi.
UPDATE workout_set_history h
SET exercise_name = CASE u.language
                      WHEN 'fr' THEN e.name_fr
                      WHEN 'de' THEN e.name_de
                      ELSE e.name_en
                    END
FROM exercises e, users u
WHERE e.id = h.exercise_id
  AND u.id = h.user_id
  AND h.exercise_name IS DISTINCT FROM CASE u.language
                                         WHEN 'fr' THEN e.name_fr
                                         WHEN 'de' THEN e.name_de
                                         ELSE e.name_en
                                       END
  AND COALESCE(NULLIF(TRIM(CASE u.language
                             WHEN 'fr' THEN e.name_fr
                             WHEN 'de' THEN e.name_de
                             ELSE e.name_en
                           END), ''), NULL) IS NOT NULL;
