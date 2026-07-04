# Reputation formula

Every wallet on Verity carries a portable reputation score, derived
from its on-registry activity. The score is not stored — it is computed
on read from the tables documented in `spec/*.sql`.

## Inputs

| Signal | Column source | Weight |
|--------|---------------|--------|
| Assets registered | `count(assets) WHERE registrant_wallet = w` | +4 per, capped at 25 |
| Plain endorsements received | endorsers on listings owned by `w`, minus verifier endorsements | +6 per |
| Verifier endorsements received | endorsers who have a `verifier_profiles` row | +12 per |
| Endorsements given | `count(asset_endorsements) WHERE endorser_wallet = w` | +2 per, capped at 50 |
| Disputes filed | `count(asset_disputes) WHERE disputer_wallet = w` | +1 per, capped at 20 |
| Disputes received | disputes on listings owned by `w` | −12 per (uncapped) |
| Wallet age | seconds since earliest `assets.created_at WHERE registrant_wallet = w` | log-decayed bonus, capped at 30 |
| Verifier badge | presence in `verifier_profiles` | +20 flat |

## Formula

```
raw =
    min(assets_registered, 25) * 4
  + min(endorsements_received - verifier_endorsements_received, 50) * 6
  + verifier_endorsements_received * 12
  + min(endorsements_given, 50) * 2
  + min(disputes_filed, 20) * 1
  - disputes_received * 12
  + age_bonus
  + (is_verifier ? 20 : 0)

age_bonus = min(30, round(log10(1 + days_since_first_seen) * 12))

score = max(0, round(raw))
```

## Tier mapping

Human-readable band based on the score and whether any dispute has been
received:

| Range | Label |
|-------|-------|
| score ≥ 240 | Reputable |
| score ≥ 120 | Trusted |
| score ≥ 40 | Established |
| score < 40 | Newcomer |
| disputes_received > 0 AND score < 60 | Contested |

`Contested` overrides the normal band when the score is low and the
wallet has any disputes against it.

## Notes

- The score is *not* an economic instrument. There is no on-chain claim,
  no token, no yield.
- Every input is public. Any indexer can reproduce the score exactly.
- Weights are subject to change as the network grows. Changes will be
  reflected in this document and the `computeReputation()` implementation
  in the app repo.
