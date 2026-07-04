-- Verity Protocol — asset disputes
--
-- Symmetric to endorsements. Any wallet other than the registrant can
-- signal that a listing is contested, with a short reason. The registry
-- doesn't judge disputes — it just makes them visible so buyers can
-- factor them in and registrants can respond via status updates.

create table if not exists public.asset_disputes (
  id             uuid primary key default gen_random_uuid(),
  asset_id       uuid not null references public.assets (id) on delete cascade,
  disputer_wallet text not null,
  reason         text not null,
  created_at     timestamptz not null default now(),
  unique (asset_id, disputer_wallet)
);

create index if not exists asset_disputes_asset_id_created_at_idx
  on public.asset_disputes (asset_id, created_at desc);
create index if not exists asset_disputes_disputer_idx
  on public.asset_disputes (lower(disputer_wallet));

alter table public.asset_disputes enable row level security;

do $$ begin
  create policy "asset_disputes_public_read"
    on public.asset_disputes for select
    to anon, authenticated
    using (true);
exception when duplicate_object then null; end $$;
