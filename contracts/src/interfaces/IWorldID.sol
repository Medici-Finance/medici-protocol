//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWorldID {
    /// @notice Reverts if the zero-knowledge proof is invalid.
    /// @param root The of the Merkle tree
    /// @param groupId The id of the Semaphore group
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    /// @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
    function verifyProof(
        uint root,
        uint groupId,
        uint signalHash,
        uint nullifierHash,
        uint externalNullifierHash,
        uint[8] calldata proof
    ) external view;
}
