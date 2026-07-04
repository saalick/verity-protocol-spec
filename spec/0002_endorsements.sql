-- Verity Protocol — asset endorsements
--
-- Endorsements let any connected wallet (except the registrant) attach a
-- signed vouch record to an asset. The signature is verified server-side
-- against the canonical endorsement message; only the resulting row is
-- persisted. UNIQUE (asset_id, endorser_wallet) prevents double-endorse.

create table if not exists public.asset_endorsements (
  id             uuid primary key default gen_random_uuid(),
  asset_id       uuid not null references public.assets (id) on delete cascade,
  endorser_wallet text not null,
  note           text,
  created_at     timestamptz not null default now(),
  unique (asset_id, endorser_wallet)
);

create index if not exists asset_endorsements_asset_id_created_at_idx
  on public.asset_endorsements (asset_id, created_at desc);
create index if not exists asset_endorsements_endorser_idx
  on public.asset_endorsements (lower(endorser_wallet));

alter table public.asset_endorsements enable row level security;

do $$ begin
  create policy "asset_endorsements_public_read"
    on public.asset_endorsements for select
    to anon, authenticated
    using (true);
exception when duplicate_object then null; end $$;
