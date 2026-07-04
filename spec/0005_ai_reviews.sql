-- Verity Protocol — AI plausibility reviews
--
-- Automatic (or on-demand) review of a listing by an LLM. Emphatically
-- NOT verification of the underlying asset — the model can't check
-- whether the field actually exists. It checks whether the listing is
-- internally consistent, plausible, non-spammy, and well-formed.
--
-- We keep at most a small number of historical rows per asset (via app
-- logic) so users can see previous reviews if the listing has been
-- edited. Latest review wins on the UI.

do $$ begin
  create type public.ai_review_verdict as enum ('green', 'yellow', 'red');
exception when duplicate_object then null; end $$;

create table if not exists public.asset_ai_reviews (
  id           uuid primary key default gen_random_uuid(),
  asset_id     uuid not null references public.assets (id) on delete cascade,
  verdict      public.ai_review_verdict not null,
  summary      text not null default '',
  flags        jsonb not null default '[]'::jsonb,
  model        text,
  created_at   timestamptz not null default now()
);

create index if not exists asset_ai_reviews_asset_id_created_at_idx
  on public.asset_ai_reviews (asset_id, created_at desc);

alter table public.asset_ai_reviews enable row level security;

do $$ begin
  create policy "asset_ai_reviews_public_read"
    on public.asset_ai_reviews for select
    to anon, authenticated
    using (true);
exception when duplicate_object then null; end $$;
