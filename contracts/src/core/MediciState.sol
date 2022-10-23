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
        uint256[] open;
        uint256[] fulfilled;
        uint256[] overdue;

        mapping(uint256 => RiskProfile) riskProfiles;

        mapping(bytes32 => bool) payloadHashes;
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

    // get all open loans - with time left or amount repaid < principal
    function getOpenLoans() public view returns (Loan[] memory) {
        // TODO - cleaner implementation
        uint256 openLoansLength = _state.open.length + _state.overdue.length + _state.fulfilled.length;
        uint256 index;
        Loan[] memory loans = new Loan[](openLoansLength);

        for (uint256 i = 0;i < _state.open.length; i++) {
            loans[index++] = _state.loans[_state.open[i]];
        }

        for (uint256 j = 0;j < _state.fulfilled.length; j++) {
            loans[index++] = _state.loans[_state.overdue[j]];
        }

        for (uint256 k = 0;k < _state.fulfilled.length; k++) {
            loans[index++] = _state.loans[_state.overdue[k]];
        }

        return loans;
    }

    function getBorrower(uint256 loanId) public returns (uint16 chainId, address borrower) {
        bytes memory wb = _state.loans[loanId].borrower;
        (chainId, borrower ) = decodeWAddress(wb);
    }

    function getPeripheryContract(uint16 chainId) public view returns (bytes32) {
        return _state.peripheryContracts[chainId];
    }

    function getPayloadHashes(bytes32 payloadHash) public view returns (bool) {
        return _state.payloadHashes[payloadHash];
    }

    function getRiskProfile(uint256 worldID) public view returns (RiskProfile memory) {
        return _state.riskProfiles[worldID];
    }

    function setPeripheryContract(uint16 chainId, bytes32 contractAddress) public {
        _state.peripheryContracts[chainId] = contractAddress;
    }

    function setNextLoan(Loan memory loan) public {
        _state.open.push(getLoanID());
        _state.loans[getLoanID()] = loan;
        _state.loanID += 1;
    }

    function addLoanToProfile(uint256 worldID, uint256 loanId) public {
        _state.riskProfiles[worldID].loans.push(loanId);
    }

    function updateRiskDAG(
        uint256 loanId_,
        address lender_,
        uint256 amount_
    ) public {
        uint256 worldID = _state.loans[loanId_].worldID;

        // _state.riskProfiles[worldID].lenders.lender =
            // MediciStructs.encodeWAddress(lender_);
        // _state.riskProfiles[worldID].lenders.amount = amount_;
    }

    function updateLoan(uint256 loanId_, uint256 amount_) public {
        _state.loans[loanId_].pending += amount_;
    }

    function processPayloadHash(bytes32 hash) internal {
        _state.payloadHashes[hash] = true;
    }

}
