# Verity Protocol · Product docs

This document mirrors [verityprotocol.xyz/docs](https://verityprotocol.xyz/docs).
The live page is authoritative; the version here is included so this
spec repository is self-contained.

For every feature described below, canonical message strings live in
[`spec/messages.md`](../spec/messages.md), evidence tier rules in
[`spec/tiers.md`](../spec/tiers.md), reputation formulas in
[`spec/reputation.md`](../spec/reputation.md), and the SQL data model
in [`spec/*.sql`](../spec/).

## Overview

Verity Protocol is a public, permissionless registry for real-world
assets. Anyone with a wallet can register any real-world thing they
own — a plot of land, a rental unit, a herd of livestock, a combine
harvester, a copyright, a signed guitar — and get a bound,
non-transferable claim record on Base.

Every listing is a signed statement. Verity does not verify or
underwrite anything. The value comes from what other wallets do with
your listing — endorsements, verifier attestations, disputes,
transfers — and from the composable, public nature of the registry
itself.

Think of it as WHOIS for real-world assets, or GitHub for signed
provenance claims, or the base layer that other RWA services —
insurers, lenders, marketplaces — will eventually read from.

## Nine asset types

Land, real estate, crop, livestock, equipment, commodity, collectible,
IP, or other. The `asset_type` enum is documented in
[`spec/0001_init.sql`](../spec/0001_init.sql).

## Trust layer

- **Endorsements** — signed vouches from any wallet other than the
  registrant. Endorsements accumulate on the asset (not the holder) so
  trust survives ownership changes. Verifier endorsements weigh double.
- **Disputes** — symmetric to endorsements. Any wallet can publicly
  contest a listing with a signed reason (minimum 8 characters). Verity
  does not adjudicate; disputes weigh −12 in the registrant's
  reputation.
- **Verifier declarations** — wallets can self-declare as professional
  verifiers (appraiser, surveyor, notary, inspector, auditor, legal)
  with a public proof URL. Not vetted by the platform.

## Evidence tiers (L0–L4)

Monotonic. Advance only when every prior condition is met.

| Tier | Requirement |
|---|---|
| L0 | Self-attested — wallet signed a registration. |
| L1 | Documented — public documentation URL attached. |
| L2 | Endorsed — 3+ distinct wallet endorsers. |
| L3 | Verifier-endorsed — at least one badged verifier has endorsed. |
| L4 | Anchored — B20 issued on-chain + (for transferred assets) current transfer anchored on Base. |

Full rules in [`spec/tiers.md`](../spec/tiers.md).

## Conflict detection

Every listing is checked against every other listing of the same type
for collisions:

- Same normalized location string (case-folded, punctuation stripped).
- Same normalized name within the same asset type.

Conflicts appear as a "Potential conflicts" panel on each competing
listing's dashboard. Verity does not judge; the flag makes silent
duplicate registration impossible.

## AI plausibility review

- **Pre-flight** — runs on the draft before the wallet signature. Red
  verdicts block signing until the registrant explicitly overrides.
- **Post-registration** — runs automatically after the row lands. Verdict
  (green/yellow/red) + summary + flags attached to the dashboard.

The AI is instructed to check plausibility, not verify existence. See
`docs/terms.md` for the full disclaimer.

## Claim transfers

The B20 token can't move (bound at mint). But the registry's
current-holder pointer can — via a two-party signed handoff:

1. Current holder signs `Verity Protocol Registry — transfer claim`.
2. Destination wallet signs `Verity Protocol Registry — accept transfer`.
3. Server verifies both signatures. `current_holder_wallet` updates.
4. A status update is appended.
5. Optionally, either party anchors the transfer on-chain.

Canonical messages in [`spec/messages.md`](../spec/messages.md).

## On-chain anchoring

The VerityAnchor contract on Base records the hash of every accepted
transfer's signatures so anyone can verify the handoff independently
of Verity's database.

```
transferHash = keccak256(concat(outgoingSignature, incomingSignature))
```

Contract source: [`contracts/VerityAnchor.sol`](../contracts/VerityAnchor.sol).
Verifier code: [`spec/hash.ts`](../spec/hash.ts).

## Registry agent

A tool-calling LLM with read-only access to the entire registry. Ask
in plain English:

- *"How many crop assets are registered?"*
- *"Who has endorsed asset 8c0…f3d?"*
- *"Give me a full profile of this listing — credible or anomalous?"*

Available at [verityprotocol.xyz/agent](https://verityprotocol.xyz/agent).

## Farcaster Frames

Every asset dashboard URL renders as an interactive Frame in Warpcast.
Two buttons: **View listing** and **Endorse** (Neynar-validated). Wallet
profiles also render as Frames.
