# Verity Protocol — Whitepaper

*Version 0.1 · 2026*

## Abstract

Verity Protocol is a public, permissionless registry for real-world
assets. Anyone with an Ethereum wallet can register any real-world
thing they own — land, real estate, crops, livestock, equipment,
intellectual property, or otherwise — as a bound B20 Asset token on
Base. Every listing is a wallet-signed claim; trust accumulates
around each listing through community endorsements, professional
verifier declarations, and disputes.

Verity's positioning is intentional: **not a marketplace, not a
custodian, not an underwriter.** Verity is the platform layer.

## Problem

Existing real-world-asset platforms are vertically integrated —
issuer, custodian, and marketplace bundled together — and target
institutional yield products (tokenized T-bills, private credit).
None of them provide the underlying infrastructure that anyone,
anywhere, could use to record the existence and provenance of an
asset they own.

There is no permissionless equivalent of WHOIS for real-world assets.
Verity fills that gap.

## Design

### Registration

A user connects an Ethereum wallet and signs a canonical registration
message (see `spec/messages.md`). The signed message + metadata are
stored in a public Postgres registry, and a **B20 Asset variant token**
with a bound transfer policy is minted to the registrant on Base. The
token cannot be transferred, sold, or fractionally split. It is an
immutable origin record.

The registry entry is editable via signed status updates from the
current holder; the token is not.

### Trust layer

Endorsements, disputes, and verifier declarations accumulate on each
listing:

- **Endorsement** — any wallet other than the registrant can sign a
  public vouch (see `spec/messages.md#endorsement`). Endorsements are
  permanent.
- **Dispute** — symmetric to endorsements, but public disagreement.
- **Verifier declaration** — a wallet publicly self-declares as an
  appraiser, surveyor, notary, inspector, auditor, or lawyer with a
  proof URL. The declaration is not vetted by the platform; buyers
  evaluate the proof. Endorsements from a badged verifier weigh double
  in reputation.

### Evidence tiers

Every listing carries a monotonic evidence tier (L0–L4) computed from
its state. See `spec/tiers.md` for the exact rules.

### Reputation

Every wallet carries a public reputation score derived from its
registry activity. See `spec/reputation.md` for the formula.

### Ownership transfers

B20 tokens are bound and never move. When real-world ownership changes
hands, Verity supports a **two-party signed claim transfer**: the
current holder signs a handoff naming the destination wallet; the
destination wallet countersigns. The registry's `current_holder_wallet`
pointer updates; the token stays. See `spec/messages.md#transfer`
for canonical strings.

### On-chain anchoring

Accepted transfers can optionally be anchored on-chain via the
**VerityAnchor** contract (see `contracts/VerityAnchor.sol`). The
contract exposes a single write function:

```solidity
function recordTransfer(bytes32 assetId, bytes32 transferHash) external;
```

Where:

- `assetId` is the UUID of the asset right-padded to 32 bytes.
- `transferHash = keccak256(concat(outgoingSignature, incomingSignature))`.

The contract has no owner, admin, upgrade path, or fee collection. It
is a pure append-only bulletin board. Any indexer with both signatures
can reproduce the hash and verify it matches on-chain.

Reference address on Base Sepolia:
`0x983d151ad0a51de8ddea56abc0461b52f1ce7cbe`.

### Data model

Every table backing the registry is documented in `spec/*.sql`. Nothing
about the schema is hidden — publishing it lets any indexer or
downstream service build against a stable contract.

## Positioning

| Project | Model | Verity vs |
|---------|-------|-----------|
| Ondo, Superstate | Vertically integrated | Not permissionless |
| Centrifuge, Maple | Structured credit pools | Not for individuals |
| RealT, Backed | Whitelisted fractionalization | KYC-gated |
| Story Protocol | IP registry with licensing | Different vertical |
| **Verity** | **Permissionless self-attestation** | **The registry layer** |

## Non-goals

- Verity is not a security. Bound tokens are not tradeable.
- Verity is not verification. Endorsements and verifier badges are
  informational aids, not proof of truth.
- Verity is not custody. The underlying asset remains outside the
  platform.
- Verity is not a marketplace. Claim transfers move the registry
  pointer, not funds.
- Verity is not legal advice. A registration does not replace a deed,
  contract, or license.

See `docs/terms.md` for the full disclaimer.

## Composition

Any application can build on Verity registry data:

- Insurers can price policies against tier, dispute history, and
  verifier endorsements.
- Lenders can underwrite loans against provenance-anchored assets.
- Marketplaces can list transferable claims (though Verity itself
  never matches buyers with sellers).
- Indexers can subscribe to on-chain events from VerityAnchor.

The `spec/hash.ts` module gives any TypeScript project the exact
algorithm to verify anchored transfers without any Verity-specific
dependency.

## Roadmap

- Q3 2026 — Seed: first 50 registrations, 10 verifiers, GitHub public
  spec, legal opinion.
- Q4 2026 — Trust: structured metadata per asset type, verifier
  inbox / direct-hire flow, Farcaster Frame anchoring.
- Q1 2027 — Money: verifier subscription live, institutional API v1,
  first on-chain reputation staking.
- Q2 2027 — Scale: cross-listing dedup via geohash, insurance market
  layer, EAS interop, mobile-first flow.

## Contact

- Site — [verityprotocol.xyz](https://verityprotocol.xyz)
- Docs — [verityprotocol.xyz/docs](https://verityprotocol.xyz/docs)
- Email — hi@verityprotocol.xyz
