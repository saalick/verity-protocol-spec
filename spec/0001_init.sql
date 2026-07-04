-- Verity Protocol initial schema
--
-- Apply either via the Supabase SQL editor (paste this file) or via the
-- Supabase CLI: `supabase db push` after linking a project.
--
-- Design notes:
--   - Verity Protocol does not authenticate users via Supabase auth; identity is
--     the connected wallet. Writes are performed through server actions
--     using the service-role key after a signature check, so RLS on these
--     tables only needs to expose a public read surface.
--   - Enums are stored as Postgres enums for referential safety; add new
--     variants with `ALTER TYPE`.
--   - Documentation files live in the `asset-docs` storage bucket (created
--     separately — see note at the bottom of this file).

create extension if not exists "pgcrypto";

do $$ begin
  create type public.asset_type as enum ('land', 'crop', 'livestock');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.asset_status as enum ('pending', 'active', 'flagged');
exception when duplicate_object then null; end $$;

create table if not exists public.assets (
  id                 uuid primary key default gen_random_uuid(),
  registrant_wallet  text not null,
  asset_type         public.asset_type not null,
  name               text not null,
  location           text,
  description        text not null default '',
  documentation_url  text,
  b20_token_address  text,
  status             public.asset_status not null default 'pending',
  created_at         timestamptz not null default now()
);

create index if not exists assets_status_idx           on public.assets (status);
create index if not exists assets_asset_type_idx       on public.assets (asset_type);
create index if not exists assets_registrant_wallet_idx on public.assets (lower(registrant_wallet));
create index if not exists assets_created_at_idx       on public.assets (created_at desc);

create table if not exists public.asset_updates (
  id         uuid primary key default gen_random_uuid(),
  asset_id   uuid not null references public.assets (id) on delete cascade,
  content    text not null,
  created_at timestamptz not null default now()
);

create index if not exists asset_updates_asset_id_created_at_idx
  on public.asset_updates (asset_id, created_at desc);

-- Row Level Security --------------------------------------------------------
-- Public read; no anon write. Service-role key bypasses RLS for server-side
-- inserts/updates performed after wallet-signature verification.

alter table public.assets enable row level security;
alter table public.asset_updates enable row level security;

do $$ begin
  create policy "assets_public_read"
    on public.assets for select
    to anon, authenticated
    using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy "asset_updates_public_read"
    on public.asset_updates for select
    to anon, authenticated
    using (true);
exception when duplicate_object then null; end $$;

-- Storage bucket ------------------------------------------------------------
-- Uncomment the block below OR create the bucket manually in the Supabase
-- dashboard (Storage → New bucket → name: asset-docs, public read).
--
-- insert into storage.buckets (id, name, public)
--   values ('asset-docs', 'asset-docs', true)
--   on conflict (id) do nothing;
--
-- create policy "asset_docs_public_read"
--   on storage.objects for select
--   to anon, authenticated
--   using (bucket_id = 'asset-docs');
