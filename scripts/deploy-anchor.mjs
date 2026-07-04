import { readFileSync } from "node:fs";
import { generatePrivateKey, privateKeyToAccount } from "viem/accounts";
import {
  createPublicClient,
  createWalletClient,
  formatEther,
  http,
  parseEther,
} from "viem";
import { baseSepolia } from "viem/chains";

const RPC = "https://sepolia.base.org";
const MIN_FUND = parseEther("0.0005"); // Enough for deploy + headroom.

// 1. Ephemeral key. Never touches disk.
const pk = generatePrivateKey();
const account = privateKeyToAccount(pk);
console.log(`DEPLOYER_ADDRESS ${account.address}`);
console.log(`Send ≥ 0.0005 Base Sepolia ETH to ${account.address} to trigger the deploy.`);

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http(RPC),
});

// 2. Load bytecode from the compiled artifact.
const artifactSrc = readFileSync(
  new URL("../src/lib/verity-anchor-artifact.ts", import.meta.url),
  "utf8",
);
const bytecodeMatch = artifactSrc.match(
  /VERITY_ANCHOR_BYTECODE\s*=\s*"(0x[0-9a-fA-F]+)"/,
);
if (!bytecodeMatch) {
  throw new Error("Could not extract bytecode from artifact file.");
}
const bytecode = bytecodeMatch[1];
console.log(`BYTECODE_LEN ${bytecode.length}`);

// 3. Poll for funding. Emit on balance change only, plus periodic heartbeats.
let last = -1n;
let ticks = 0;
while (true) {
  const balance = await publicClient.getBalance({ address: account.address });
  if (balance !== last) {
    console.log(`BALANCE ${formatEther(balance)} ETH`);
    last = balance;
  }
  if (balance >= MIN_FUND) break;
  ticks++;
  if (ticks % 12 === 0) {
    console.log(`HEARTBEAT still waiting for funds, elapsed=${ticks * 5}s`);
  }
  await new Promise((r) => setTimeout(r, 5000));
}

// 4. Deploy.
console.log("DEPLOYING");
const walletClient = createWalletClient({
  account,
  chain: baseSepolia,
  transport: http(RPC),
});
const txHash = await walletClient.sendTransaction({
  data: bytecode,
});
console.log(`TX_HASH ${txHash}`);
console.log(`TX_URL https://sepolia.basescan.org/tx/${txHash}`);

const receipt = await publicClient.waitForTransactionReceipt({
  hash: txHash,
  timeout: 120_000,
});
console.log(`CONTRACT_ADDRESS ${receipt.contractAddress}`);
console.log(
  `CONTRACT_URL https://sepolia.basescan.org/address/${receipt.contractAddress}`,
);
console.log("DONE");
