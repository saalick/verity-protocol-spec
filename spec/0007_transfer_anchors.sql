-- Verity Protocol — on-chain transfer anchors
--
-- Records the Base transaction hash that anchored a completed transfer
-- to the VerityAnchor contract. Anchoring is optional and typically
-- performed by the accepting wallet immediately after acceptance, but
-- can be triggered later by anyone with access to both signatures.

alter table public.asset_transfers
  add column if not exists anchor_tx_hash text,
  add column if not exists anchor_chain_id integer,
  add column if not exists anchored_at timestamptz;

create index if not exists asset_transfers_anchor_tx_hash_idx
  on public.asset_transfers (anchor_tx_hash)
 where anchor_tx_hash is not null;
