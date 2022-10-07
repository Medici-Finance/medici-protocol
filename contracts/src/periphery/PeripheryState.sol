pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../MediciStructs.sol";
import "../wormhole/IWormhole.sol";
import "../helpers/MToken.sol";

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
        address collateralAssetAddress;
        address borrowingAssetAddress;
        address mTokenAddress;
        mapping(bytes32 => bool) messageHashes;
    }
}

contract PeripheryState {
    PeripheryStorage.State _state;

    event PeripheryLoanRequest(uint32 indexed nonce);
    event LendSuccess(uint256 indexed loanId, uint256 indexed amount);

    function chainID() public view returns (uint16) {
        return _state.provider.chainID;
    }

    function consistencyLevel() public view returns (uint8) {
        return _state.provider.consistencyLevel;
    }

    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.provider.wormhole);
    }

    function owner() public view returns (address) {
        return _state.owner;
    }

    function maxTenor() public view returns (uint256) {
        return _state.maxTenor;
    }

    function nonce() public view returns (uint32) {
        return _state.nonce;
    }

    function incrementNonce() public {
        _state.nonce++;
    }

    function setMaxTenor(uint256 _maxTenor) public {
        _state.maxTenor = _maxTenor;
    }

    function setCoreContract(uint16 coreChainID, bytes32 coreContract) public {
        _state.provider.coreChainID = coreChainID;
        _state.provider.coreContract = coreContract;
    }

    function setMToken(address mTokenAddress) public {
        _state.mTokenAddress = mTokenAddress;
    }

    function getMessageHashes(bytes32 messageHash) public view returns (bool) {
        return _state.messageHashes[messageHash];
    }

    function collateralToken() internal view returns (IERC20) {
        return IERC20(_state.collateralAssetAddress);
    }

    function mToken() internal view returns (MToken) {
        return MToken(_state.mTokenAddress);
    }

    function processMessageHash(bytes32 hash) internal {
        _state.messageHashes[hash] = true;
    }
}
