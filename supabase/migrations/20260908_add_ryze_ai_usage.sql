-- Ce que chaque tour de génération a coûté.
--
-- Rien ne mesurait l'IA : les jetons étaient estimés à la louche côté
-- application et jamais agrégés. La fonction serveur, qui voit passer le flux,
-- écrit ici ce que le modèle a réellement consommé.
create table if not exists public.ryze_ai_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  -- 'coach' ou 'planner' : d'où venait la demande.
  surface text not null,
  model text not null,

  prompt_tokens integer not null default 0,
  output_tokens integer not null default 0,

  created_at timestamptz not null default now()
);

create index if not exists ryze_ai_usage_user_day_idx
  on public.ryze_ai_usage (user_id, created_at desc);

alter table public.ryze_ai_usage enable row level security;

-- Chacun voit sa propre consommation, personne n'écrit depuis l'application :
-- seule la fonction serveur, avec la clé de service, ajoute des lignes.
drop policy if exists ryze_ai_usage_select_own on public.ryze_ai_usage;
create policy ryze_ai_usage_select_own
  on public.ryze_ai_usage for select
  using (auth.uid() = user_id);

comment on table public.ryze_ai_usage is
  'Jetons consommés par tour de génération, écrits par la fonction ryze-ai.';
