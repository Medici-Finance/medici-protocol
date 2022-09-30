pragma solidity 0.8.15;

import "../MediciStructs.sol";
import "../wormhole/IWormhole.sol";

contract PeripheryStorage {
    struct Provider {
        uint16 chainID;
        uint16 coreChainID;
        bytes32 coreContract;
        address payable wormhole;
        address tokenBridge;
        uint8 consistencyLevel;
    }

    struct State {
        Provider provider;

        address owner;

        uint32 nonce;

        uint256 maxTenor;
    }
}

contract PeripheryState {
    PeripheryStorage.State _state;

    event PeripheryLoanRequest(uint32 nonce);

    function consistencyLevel() public returns (uint8) {
        return _state.provider.consistencyLevel;
    }

    function wormhole() public returns (IWormhole) {
        return IWormhole(_state.provider.wormhole);
    }

    function owner() public returns (address) {
        return _state.owner;
    }

    function maxTenor() public returns (uint256) {
        return _state.maxTenor;
    }

    function nonce() public returns (uint32) {
        return _state.nonce;
    }

    function incrementNonce() public {
        _state.nonce++;
    }
}