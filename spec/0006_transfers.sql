-- Verity Protocol — asset transfers
--
-- B20 tokens are bound-at-mint and never move. Real-world ownership
-- does. A transfer is a two-party signed handoff of the *registry
-- claim* (the current-holder pointer) — the original token stays with
-- the registrant as an immutable origin record; the chain of holders
-- is appended below.
--
-- Endorsements and disputes remain attached to the asset, not the
-- holder — matches "reputation of the asset", which is what buyers
-- actually care about.

do $$ begin
  create type public.transfer_status as enum (
    'pending',
    'accepted',
    'rejected',
    'cancelled'
  );
exception when duplicate_object then null; end $$;

create table if not exists public.asset_transfers (
  id                    uuid primary key default gen_random_uuid(),
  asset_id              uuid not null references public.assets (id) on delete cascade,
  from_wallet           text not null,
  to_wallet             text not null,
  outgoing_note         text,
  outgoing_signature    text not null,
  outgoing_nonce        text not null,
  outgoing_issued_at    timestamptz not null,
  incoming_note         text,
  incoming_signature    text,
  incoming_nonce        text,
  incoming_issued_at    timestamptz,
  status                public.transfer_status not null default 'pending',
  responded_at          timestamptz,
  created_at            timestamptz not null default now()
);

create index if not exists asset_transfers_asset_id_created_at_idx
  on public.asset_transfers (asset_id, created_at desc);
create index if not exists asset_transfers_from_wallet_idx
  on public.asset_transfers (lower(from_wallet));
create index if not exists asset_transfers_to_wallet_idx
  on public.asset_transfers (lower(to_wallet));
create index if not exists asset_transfers_status_idx
  on public.asset_transfers (status);

-- Guarantee at most one pending transfer per asset. Multiple accepted
-- transfers over time are expected (a chain of holders).
create unique index if not exists asset_transfers_one_pending_per_asset
  on public.asset_transfers (asset_id) where status = 'pending';

alter table public.asset_transfers enable row level security;

do $$ begin
  create policy "asset_transfers_public_read"
    on public.asset_transfers for select
    to anon, authenticated
    using (true);
exception when duplicate_object then null; end $$;

-- Current holder — a pointer that starts as the registrant and moves
-- with each accepted transfer. Backfilled for existing rows.
alter table public.assets
  add column if not exists current_holder_wallet text;

update public.assets
   set current_holder_wallet = registrant_wallet
 where current_holder_wallet is null;

alter table public.assets
  alter column current_holder_wallet set not null;

create index if not exists assets_current_holder_idx
  on public.assets (lower(current_holder_wallet));
