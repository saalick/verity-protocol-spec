# Evidence tiers · L0 through L4

Every listing on Verity Protocol carries a monotonic evidence tier
between **L0** (self-attested) and **L4** (anchored). A listing advances
one rung when every rung below it has been satisfied.

## Definitions

| Tier | Label | Requirement |
|------|-------|-------------|
| L0 | Self-attested | Wallet signed a registration. |
| L1 | Documented | `documentation_url` is non-empty. |
| L2 | Endorsed | ≥ 3 distinct endorsers on `asset_endorsements` for this asset. |
| L3 | Verifier-endorsed | ≥ 1 endorser has a row in `verifier_profiles`. |
| L4 | Anchored | B20 token has been issued on-chain, and (for transferred assets) the current transfer has a non-null `anchor_tx_hash` in `asset_transfers`. |

## Monotonic rules

- L1 requires L0. L2 requires L1. And so on.
- Missing any prior rung caps the tier at the highest-satisfied one.
- Verifier endorsements count as ordinary endorsements *and* satisfy L3.
- Disputes do **not** lower the tier. They are surfaced separately as a
  `contested_count` on the same listing.

## Reference implementation

```ts
type Tier = 0 | 1 | 2 | 3 | 4;

function computeTier(input: {
  documentation_url: string | null;
  endorsement_count: number;
  verifier_endorsement_count: number;
  b20_issued: boolean;
  transfer_anchored: boolean;
  ever_transferred: boolean;
}): Tier {
  if (!input.documentation_url) return 0;
  if (input.endorsement_count < 3) return 1;
  if (input.verifier_endorsement_count < 1) return 2;
  if (!input.b20_issued) return 3;
  if (input.ever_transferred && !input.transfer_anchored) return 3;
  return 4;
}
```

Any indexer or downstream service can compute tiers from public data —
the migrations in `spec/*.sql` document every table and column
involved.
