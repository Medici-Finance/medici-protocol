pragma solidity 0.8.15;

import {ByteHasher} from "../helpers/ByteHasher.sol";
import {IWorldID} from "../interfaces/IWorldID.sol";

contract Personhood {
    using ByteHasher for bytes;

    ////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                              ///
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The World ID group ID (always 1)
    uint256 internal immutable groupId = 1;

    string private _actionID;

    /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
    mapping(bytes => uint256) internal wAddressesVerified;

    /// @param _worldId The WorldID instance that will verify the proofs
    constructor(IWorldID _worldId) {
        worldId = _worldId;
    }

    function setActionId(string memory _id) public {
        _actionID = _id;
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                       EXTERNAL FUNCTIONS                             ///
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Public function encoding EVM addresses to 34 byte Wormhole addresses and verifying proof to authenicate address
     * @param chainId wormhole chain ID
     * @param account EVM address
     * See _authenicate for the rest of the params
     */
    function authenicate(
        uint16 chainId,
        address account,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public returns (bool) {
        bytes memory wBorrower = _encodeWAddress(chainId, account);
        return _authenicate(wBorrower, root, nullifierHash, proof);
    }

    /**
     * @notice Public function encoding EVM addresses to 34 byte Wormhole addresses and verifying proof to deauthenicate addreees
     * @param chainId wormhole chain ID
     * @param account EVM address
     * See _deauthenicate for the rest of the params
     */
    function deuathenicate(
        uint16 chainId,
        address account,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public returns (bool) {
        bytes memory wBorrower = _encodeWAddress(chainId, account);
        return _deauthenicate(wBorrower, root, nullifierHash, proof);
    }


    function getPerson(bytes memory wBorrower) public view returns (uint256 nullifierHash) {
        require(wAddressesVerified[wBorrower] != 0, "Personhood: borrower not verified");
        return wAddressesVerified[wBorrower];
    }


    ////////////////////////////////////////////////////////////////////////////
    ///                       INTERNAL FUNCTIONS                             ///
    ////////////////////////////////////////////////////////////////////////////

    /// @param wBorrower Wormhole address as an arbitrary input as signal from the user
    /// @param root The root of the Merkle tree (returned by the JS widget).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demostrates the claimer is registered with World ID (returned by the JS widget).
    function _authenicate(bytes memory wBorrower, uint256 root, uint256 nullifierHash, uint256[8] calldata proof)
        private
        returns (bool)
    {
        // make sure person hasn't already signed up using a different address
        require(wAddressesVerified[wBorrower] == 0, "Personhood: borrower already verified");

        // We now verify the provided proof is valid and the user is verified by World ID
        worldId.verifyProof(
            root,
            groupId,
            // TDOD: fix if unique signal needed
            abi.encodePacked(wBorrower).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this)).hashToField(),
            proof
        );

        // recording new user signup
        wAddressesVerified[wBorrower] = nullifierHash;
        return true;
    }

    function toBytes(uint16 x) public returns (bytes memory c) {
        bytes2 b = bytes2(x);
        c = new bytes(2);
        for (uint256 i = 0; i < 2; i++) {
            c[i] = b[i];
        }
    }

    function _encodeWAddress(uint16 _chainId, address _address) internal  returns (bytes memory) {
        bytes memory addy = new bytes(32);
        assembly {
            mstore(add(addy, 32), _address)
        }
        return bytes.concat(toBytes(_chainId), addy);
    }

    function _deauthenicate(bytes memory wBorrower, uint256 root, uint256 nullifierHash, uint256[8] calldata proof)
        public
        returns (bool)
    {
        // make sure person hasn't already signed up using a different address
        require(wAddressesVerified[wBorrower] == nullifierHash, "Personhood: borrower not verified");

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
}
