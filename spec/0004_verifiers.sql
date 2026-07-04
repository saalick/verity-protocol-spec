-- Verity Protocol — verifier profiles
--
-- A wallet can self-declare as a professional verifier (appraiser,
-- surveyor, notary, physical inspector, etc.) by signing a canonical
-- message. Verifier status is public and permissionless — the registry
-- does not vet the claim; buyers judge the proof URL and reputation.
-- Endorsements from a badged verifier weigh more in reputation scoring
-- and unlock a higher verification tier for the endorsed listing.

do $$ begin
  create type public.verifier_category as enum (
    'appraiser',
    'surveyor',
    'notary',
    'inspector',
    'auditor',
    'legal',
    'other'
  );
exception when duplicate_object then null; end $$;

create table if not exists public.verifier_profiles (
  wallet         text primary key,
  category       public.verifier_category not null,
  display_name   text not null,
  bio            text not null default '',
  proof_url      text not null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists verifier_profiles_category_idx
  on public.verifier_profiles (category);

alter table public.verifier_profiles enable row level security;

do $$ begin
  create policy "verifier_profiles_public_read"
    on public.verifier_profiles for select
    to anon, authenticated
    using (true);
exception when duplicate_object then null; end $$;
