# Verity Protocol — Public Spec

**Verity Protocol** is a public, permissionless registry for real-world
assets on Base. Anyone with a wallet can register any real-world thing
they own — land, real estate, crops, livestock, equipment, IP,
collectibles — signed by the wallet, endorsed by peers, and durable.

Live at **[verityprotocol.xyz](https://verityprotocol.xyz)**.

This repository is the **public specification** of the protocol —
enough for any indexer, verifier, or downstream service to build
against Verity's data without needing to inspect the application code.
The application itself lives in a separate private repository.

## Contents

```
contracts/
  VerityAnchor.sol             Side-car anchor contract on Base
scripts/
  deploy-anchor.mjs            One-shot deploy script (ephemeral wallet)
spec/
  0001_init.sql                Assets + updates tables
  0002_endorsements.sql        Endorsement table + policy
  0003_disputes.sql            Dispute table + policy
  0004_verifiers.sql           Verifier profiles + category enum
  0005_ai_reviews.sql          AI plausibility review rows
  0006_transfers.sql           Signed claim transfers
  0007_transfer_anchors.sql    On-chain anchor tx tracking
  hash.ts                      Canonical transfer-hash algorithm + ABI
  messages.md                  Every canonical wallet-signed message
  tiers.md                     Evidence tier ladder (L0–L4)
  reputation.md                Reputation scoring formula
docs/
  docs.md                      Product docs (mirror of /docs)
  terms.md                     Terms and disclaimers (mirror of /terms)
whitepaper.md                  Short technical whitepaper
LICENSE                        MIT (spec) / All Rights Reserved (prose)
```

## Deployed addresses

| Network | Contract | Address |
|---|---|---|
| Base Sepolia | VerityAnchor | `0x983d151ad0a51de8ddea56abc0461b52f1ce7cbe` |

## Independently verifying an anchored transfer

Anyone with an outgoing and incoming Verity signature can verify the
transfer was recorded on-chain:

```ts
import { keccak256, createPublicClient, http } from "viem";
import { baseSepolia } from "viem/chains";
import { assetIdToBytes32, computeTransferHash, VERITY_ANCHOR_ABI } from "./spec/hash";

const ANCHOR = "0x983d151ad0a51de8ddea56abc0461b52f1ce7cbe";

const assetId = assetIdToBytes32("358e7767-0230-43d7-b97c-dd04b1336688");
const hash = computeTransferHash({
  outgoingSignature: "0x…",
  incomingSignature: "0x…",
});

const client = createPublicClient({ chain: baseSepolia, transport: http() });
const stored = await client.readContract({
  address: ANCHOR,
  abi: VERITY_ANCHOR_ABI,
  functionName: "transferHashes",
  args: [assetId],
});

console.log("verified:", stored.includes(hash));
```

## Deploying the anchor contract yourself

```bash
node scripts/deploy-anchor.mjs
# Send ≥ 0.0005 Base Sepolia ETH to the printed address.
# Deploy completes automatically; contract address is printed.
```

The script generates a fresh ephemeral private key in-memory, never
writes it to disk, and discards it on exit. See the script for details.

## License

- **Code** (contracts, scripts, `hash.ts`) — MIT.
- **Prose** (docs, whitepaper, spec markdown) — All Rights Reserved.
  Reproduction of substantial passages requires permission; short
  quotations for review, integration guides, or academic purposes are
  encouraged.

## Contact

- Site — [verityprotocol.xyz](https://verityprotocol.xyz)
- Docs — [verityprotocol.xyz/docs](https://verityprotocol.xyz/docs)
- Partnerships — [verityprotocol.xyz/partners](https://verityprotocol.xyz/partners)
- Email — hi@verityprotocol.xyz
