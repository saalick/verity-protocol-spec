# Message spec

Every on-registry action on Verity Protocol requires a wallet to sign a
canonical string. This spec documents every message shape so any indexer,
verifier, or downstream service can independently reproduce and validate
signatures without touching Verity's servers.

All messages use `personal_sign` semantics — i.e. verified with
[`viem.verifyMessage`](https://viem.sh/docs/utilities/verifyMessage.html)
or equivalent Ethereum tooling.

Two hard rules:

- **Wallet addresses are lower-cased** before being interpolated into a
  message. Any signature over a mixed-case address will fail verification.
- **Timestamps use ISO-8601** in UTC, e.g. `2026-07-04T18:23:11.514Z`. The
  server enforces a `±10 minute` freshness window.

---

## Asset registration

Signed by the registrant when creating a new listing.

```
Verity Protocol Registry — asset registration

Wallet: <wallet lowercased>
Asset type: <one of: land | real_estate | crop | livestock | equipment | commodity | collectible | ip | other>
Name: <asset name>
Location: <location or empty string>
Description: <description>
Documentation: <https URL or empty string>
Issued at: <ISO-8601>
Nonce: <UUID or 16–64 hex chars>

By signing this message you attest that you own or manage the asset described above and that the details are accurate to the best of your knowledge. Verity Protocol does not verify or back this claim.
```

## B20 deploy-error mark

Signed when the register form catches a classified revert during the
on-chain B20 mint (e.g. `FEATURE_NOT_ACTIVATED`) and needs to persist
the reason server-side.

```
Verity Protocol Registry — deploy gate

Wallet: <wallet lowercased>
Asset id: <UUID>
Error: <FEATURE_NOT_ACTIVATED | POLICY_FORBIDS>
Issued at: <ISO-8601>
Nonce: <nonce>
```

## Post-mint finalize

Signed by the registrant after a successful B20 mint to attach the
deployed token address to the registry row.

```
Verity Protocol Registry — token attachment

Wallet: <wallet lowercased>
Asset id: <UUID>
B20 token: <address lowercased>
Issued at: <ISO-8601>
Nonce: <nonce>
```

## Status update

Signed by the current holder when appending a status update to the
listing's update log.

```
Verity Protocol Registry — status update

Wallet: <wallet lowercased>
Asset id: <UUID>
Content: <update body>
Issued at: <ISO-8601>
Nonce: <nonce>
```

## Endorsement

Signed by any wallet other than the registrant to publicly vouch for a
listing.

```
Verity Protocol Registry — endorsement

Wallet: <wallet lowercased>
Asset id: <UUID>
Note: <optional short note or empty string>
Issued at: <ISO-8601>
Nonce: <nonce>

By signing this message you publicly endorse the asset above. You are not the registrant. Verity Protocol does not verify or back this endorsement.
```

## Dispute

Signed by any wallet other than the registrant to publicly contest a
listing.

```
Verity Protocol Registry — dispute

Wallet: <wallet lowercased>
Asset id: <UUID>
Reason: <reason, minimum 8 chars>
Issued at: <ISO-8601>
Nonce: <nonce>

By signing this message you publicly contest the asset above. You are not the registrant. Verity Protocol does not adjudicate disputes — they are recorded and made visible.
```

## Verifier declaration

Signed by a wallet declaring itself as a professional verifier.

```
Verity Protocol Registry — verifier declaration

Wallet: <wallet lowercased>
Category: <one of: appraiser | surveyor | notary | inspector | auditor | legal | other>
Display name: <display name>
Proof URL: <https URL>
Issued at: <ISO-8601>
Nonce: <nonce>

By signing this message you publicly declare yourself as a professional verifier on Verity Protocol. This declaration is not vetted by the platform — buyers evaluate the proof URL you supply.
```

## Transfer — initiate

Signed by the current holder to begin a claim transfer. The transfer is
not effective until the destination wallet countersigns.

```
Verity Protocol Registry — transfer claim

From wallet: <current holder lowercased>
Asset id: <UUID>
To wallet: <destination lowercased>
Note: <optional note or empty string>
Issued at: <ISO-8601>
Nonce: <nonce>

By signing this message you initiate a transfer of the operational claim of the asset above to the destination wallet. The on-chain B20 token remains bound to the original registrant. The transfer is not final until the destination wallet countersigns.
```

## Transfer — accept

Signed by the destination wallet to accept a pending transfer.

```
Verity Protocol Registry — accept transfer

Wallet: <destination lowercased>
Asset id: <UUID>
Transfer id: <UUID of the transfer row>
Note: <optional note or empty string>
Issued at: <ISO-8601>
Nonce: <nonce>

By signing this message you accept the operational claim of the asset above. The current-holder pointer will move to your wallet; the bound B20 token stays with the original registrant.
```

## Transfer — reject / cancel

Signed by the destination wallet (to reject) or the outgoing wallet (to
cancel).

```
Verity Protocol Registry — <cancel|decline> transfer

Wallet: <lowercased>
Asset id: <UUID>
Transfer id: <UUID>
Action: <rejected | cancelled>
Issued at: <ISO-8601>
Nonce: <nonce>
```

`Action: cancelled` is signed by the outgoing wallet; `Action: rejected`
is signed by the destination wallet. The verb in the header (`cancel` vs
`decline`) matches accordingly.

---

## Verifying a signature

```ts
import { verifyMessage } from "viem";

const ok = await verifyMessage({
  address: signerWallet,
  message: buildEndorsementMessage({ /* … */ }),
  signature,
});
```

Any of the message shapes above can be reproduced string-for-string by
concatenating the lines with `\n`. Trailing whitespace matters; ordering
matters. If verification is failing, re-check:

- Wallet address is lower-cased **in the message** (not just for
  storage).
- The `Issued at` timestamp is the exact string that was signed.
- The `Nonce` is the exact string that was signed.
- No extra trailing newline.

The reference implementations live in `spec/messages.ts` (in Verity's
private app repo). This document is the source of truth — the code is
the implementation.
