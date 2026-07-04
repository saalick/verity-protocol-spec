// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VerityAnchor
 * @notice Public bulletin board that anchors Verity Protocol claim
 *         transfers on-chain. The B20 Asset token stays bound to its
 *         original registrant forever; this contract records the hash
 *         of each accepted transfer so the chain of custody is
 *         independently verifiable without trusting Verity's database.
 *
 * @dev    Anyone can call recordTransfer — the caller is captured in
 *         the event and can be cross-checked against the wallet that
 *         initiated or accepted the transfer off-chain. No token
 *         movement, no supply changes; this contract only stores
 *         (assetId → transferHash[]) mappings.
 *
 * Off-chain hash format (must match the client library):
 *   transferHash = keccak256(concat(outgoingSignature, incomingSignature))
 * where both signatures are the exact bytes signed via viem's
 * personal_sign flow on the outgoing and incoming Verity messages.
 *
 * Off-chain assetId format:
 *   assetId = right-pad the UUID hex (32 chars, dashes removed) to 32 bytes.
 *   e.g. UUID 358e7767-0230-43d7-b97c-dd04b1336688 becomes
 *   0x358e7767023043d7b97cdd04b133668800000000000000000000000000000000
 */
contract VerityAnchor {
    event TransferAnchored(
        bytes32 indexed assetId,
        bytes32 indexed transferHash,
        address indexed recorder,
        uint256 timestamp
    );

    // assetId => transfer hashes in insertion order.
    mapping(bytes32 => bytes32[]) private _transferHashes;

    /**
     * @notice Record a transfer hash under the given asset id.
     * @dev    No auth — anyone can anchor a transfer they can prove
     *         happened. Verifiers cross-check the hash against the
     *         underlying signatures in Verity's registry.
     */
    function recordTransfer(bytes32 assetId, bytes32 transferHash) external {
        _transferHashes[assetId].push(transferHash);
        emit TransferAnchored(
            assetId,
            transferHash,
            msg.sender,
            block.timestamp
        );
    }

    /// @notice Number of anchored transfers for an asset.
    function transferHashCount(bytes32 assetId) external view returns (uint256) {
        return _transferHashes[assetId].length;
    }

    /// @notice Fetch a specific anchored transfer hash by index.
    function transferHashAt(bytes32 assetId, uint256 index)
        external
        view
        returns (bytes32)
    {
        require(index < _transferHashes[assetId].length, "OUT_OF_BOUNDS");
        return _transferHashes[assetId][index];
    }

    /// @notice Fetch every anchored transfer hash for an asset.
    function transferHashes(bytes32 assetId)
        external
        view
        returns (bytes32[] memory)
    {
        return _transferHashes[assetId];
    }
}
