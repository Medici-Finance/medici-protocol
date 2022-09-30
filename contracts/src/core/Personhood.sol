// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ByteHasher } from "../helpers/ByteHasher.sol";
import { IWorldID } from "../interfaces/IWorldID.sol";

contract Personhood {
    using ByteHasher for bytes;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The World ID group ID (always 1)
    uint256 internal immutable groupId = 1;

    string private _actionID;

    /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
    mapping(bytes32 => uint256) internal wAddressesVerified;

    /// @param _worldId The WorldID instance that will verify the proofs
    constructor(IWorldID _worldId) {
        worldId = _worldId;
    }

    function setActionId(string memory _id) public {
        _actionID = _id;
    }

    /// @param wBorrower Wormhole address as an arbitrary input as signal from the user
    /// @param root The root of the Merkle tree (returned by the JS widget).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demostrates the claimer is registered with World ID (returned by the JS widget).
    function authenicate(
        bytes32 wBorrower,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public returns (bool) {
        // make sure person hasn't already signed up using a different address
        require(
            wAddressesVerified[wBorrower] == 0,
            "Personhood: borrower already verified"
        );

        // We now verify the provided proof is valid and the user is verified by World ID
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(wBorrower).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this)).hashToField(),
            proof
        );

        // recording new user signup
        wAddressesVerified[wBorrower] = nullifierHash;
        return true;
    }

    function deauthenicate(
        bytes32 wBorrower,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public returns (bool) {
        // make sure person hasn't already signed up using a different address
        require(
            wAddressesVerified[wBorrower] == nullifierHash,
            "Personhood: borrower not verified"
        );

        // We now verify the provided proof is valid and the user is verified by World ID
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(wBorrower).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this)).hashToField(),
            proof
        );

        // recording new user signup
        wAddressesVerified[wBorrower] = 0;
        return true;
    }

    function checkAlreadyVerified(
        bytes32 borrower
    ) public view returns (bool) {
        return wAddressesVerified[borrower] != 0;
    }
}
