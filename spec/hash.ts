/**
 * Verity Anchor — deterministic hash helpers.
 *
 * The VerityAnchor contract on Base records the hash of each accepted
 * transfer's signatures under a bytes32 asset id. This module provides
 * the exact algorithm any indexer, verifier, or downstream service
 * needs to reproduce those values off-chain and check them against the
 * on-chain events.
 *
 * Runtime: standard viem. Zero platform dependencies.
 */
import { keccak256, type Hex } from "viem";

/**
 * Convert a UUID (with or without dashes) to bytes32 by right-padding.
 * The `asset_id` column in Verity's registry is a Postgres UUID
 * (128 bits). To index events on it as bytes32 (256 bits) we pad the
 * hex with zeroes.
 *
 * Example
 *   UUID  358e7767-0230-43d7-b97c-dd04b1336688
 *   → 0x358e7767023043d7b97cdd04b133668800000000000000000000000000000000
 */
export function assetIdToBytes32(uuid: string): Hex {
  const hex = uuid.replace(/-/g, "").toLowerCase();
  if (!/^[0-9a-f]{32}$/.test(hex)) {
    throw new Error("Invalid UUID for assetIdToBytes32.");
  }
  return `0x${hex}${"0".repeat(32)}` as Hex;
}

/**
 * Deterministic hash committed to on-chain, computed from the two
 * wallet signatures involved in a completed transfer. Anyone with
 * both signatures can reproduce this value and check it matches
 * whatever is stored under `transferHashes(assetId)` on the contract.
 *
 * transferHash = keccak256(concat(outgoingSignature, incomingSignature))
 */
export function computeTransferHash(input: {
  outgoingSignature: string;
  incomingSignature: string;
}): Hex {
  const outgoing = stripHexPrefix(input.outgoingSignature);
  const incoming = stripHexPrefix(input.incomingSignature);
  const packed = `0x${outgoing}${incoming}` as Hex;
  return keccak256(packed);
}

function stripHexPrefix(raw: string): string {
  const trimmed = raw.trim();
  if (trimmed.startsWith("0x") || trimmed.startsWith("0X")) {
    return trimmed.slice(2).toLowerCase();
  }
  return trimmed.toLowerCase();
}

// -----------------------------------------------------------------
// Contract ABI — for readers who want to call the anchor directly.
// -----------------------------------------------------------------
export const VERITY_ANCHOR_ABI = [
  {
    type: "event",
    name: "TransferAnchored",
    inputs: [
      { indexed: true, name: "assetId", type: "bytes32" },
      { indexed: true, name: "transferHash", type: "bytes32" },
      { indexed: true, name: "recorder", type: "address" },
      { indexed: false, name: "timestamp", type: "uint256" },
    ],
  },
  {
    type: "function",
    name: "recordTransfer",
    stateMutability: "nonpayable",
    inputs: [
      { name: "assetId", type: "bytes32" },
      { name: "transferHash", type: "bytes32" },
    ],
    outputs: [],
  },
  {
    type: "function",
    name: "transferHashCount",
    stateMutability: "view",
    inputs: [{ name: "assetId", type: "bytes32" }],
    outputs: [{ type: "uint256" }],
  },
  {
    type: "function",
    name: "transferHashAt",
    stateMutability: "view",
    inputs: [
      { name: "assetId", type: "bytes32" },
      { name: "index", type: "uint256" },
    ],
    outputs: [{ type: "bytes32" }],
  },
  {
    type: "function",
    name: "transferHashes",
    stateMutability: "view",
    inputs: [{ name: "assetId", type: "bytes32" }],
    outputs: [{ type: "bytes32[]" }],
  },
] as const;
