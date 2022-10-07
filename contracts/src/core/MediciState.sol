// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import "../MediciStructs.sol";
import {IWormhole} from "../wormhole/IWormhole.sol";

contract MediciStorage {
    struct Provider {
        uint16 chainId;
        address payable wormhole;
        address tokenBridge;
        uint8 consistencyLevel;
    }

    struct State {
        Provider provider;
        uint32 nonce;
        address owner;
        mapping(uint16 => bytes32) peripheryContracts;
        mapping(uint256 => Loan) loans;
        mapping(uint256 => RiskProfile) riskProfiles;
        mapping(bytes32 => bool) messageHashes;
        uint256 loanID;
        uint256 maxTenor;
    }
}

contract MediciState is MediciStructs{
    MediciStorage.State _state;

    event LoanCreated(uint256 loanId);

    // @dev individual wormhole addresses for each chain
    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.provider.wormhole);
    }

    function owner() public view returns (address) {
        return _state.owner;
    }

    function nonce() public view returns (uint32) {
        return _state.nonce;
    }

    function incrementNonce() public {
        _state.nonce++;
    }

    function consistencyLevel() public view returns (uint8) {
        return _state.provider.consistencyLevel;
    }

    function getLoanID() public view returns (uint256) {
        return _state.loanID;
    }

    function getBorrower(uint256 loanId) public view returns (uint16 chainId, address borrower) {
        bytes memory wb = _state.loans[loanId].borrower;
        (uint16 chainId, address borrower ) = decodeWAddress(wb);
    }

    function getPeripheryContract(uint16 chainId) public view returns (bytes32) {
        return _state.peripheryContracts[chainId];
    }

    function getMessageHashes(bytes32 messageHash) public view returns (bool) {
        return _state.messageHashes[messageHash];
    }

    function getRiskProfile(uint256 worldID) public view returns (RiskProfile memory) {
        return _state.riskProfiles[worldID];
    }

    function setPeripheryContract(uint16 chainId, bytes32 contractAddress) public {
        _state.peripheryContracts[chainId] = contractAddress;
    }

    function setNextLoan(Loan memory loan) public {
        _state.loans[getLoanID()] = loan;
        _state.loanID += 1;
    }

    function addLoanToProfile(uint256 worldID, uint256 loanId) public {
        _state.riskProfiles[worldID].loans.push();
    }

    function updateRiskDAG(
        uint256 loanId_,
        address lender_,
        uint256 amount_
    ) public {
        uint256 worldID = _state.loans[loanId_].worldID;

        // _state.riskProfiles[worldID].lenders.lender =
        //     MediciStructs.encodeWAddress(lender_);
        // _state.riskProfiles[worldID].lenders.amount = amount_;
    }

    function updateLoan(uint256 loanId_, uint256 amount_) public {
        _state.loans[loanId_].pending += amount_;
    }

    function processMessageHash(bytes32 hash) internal {
        _state.messageHashes[hash] = true;
    }

}
