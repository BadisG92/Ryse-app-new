-- L'eau notée par Ryze était refusée par la base.
--
-- La contrainte n'acceptait que les gestes de l'écran : un verre, une
-- bouteille, une gourde, une tasse, une saisie manuelle. L'outil de la
-- conversation envoie « coach », donc chaque insertion était rejetée. Comme
-- l'écriture est volontairement non bloquante, l'application annonçait
-- « 0,5 L notés » et la ligne n'existait pas.
--
-- « widget » est ajouté au passage : la même contrainte l'attend au tournant
-- le jour où l'eau ajoutée depuis l'écran verrouillé écrira sous son nom.
ALTER TABLE public.water_entries DROP CONSTRAINT IF EXISTS water_entries_source_valid;

ALTER TABLE public.water_entries ADD CONSTRAINT water_entries_source_valid
  CHECK (source_type = ANY (ARRAY[
    'manual'::text,
    'bottle'::text,
    'glass'::text,
    'sports_bottle'::text,
    'cup'::text,
    'coach'::text,
    'widget'::text
  ]));
