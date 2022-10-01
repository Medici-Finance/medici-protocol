// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import {MediciStructs} from "../MediciStructs.sol";
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
        address owner;
        mapping(uint16 => bytes32) peripheryContracts;
        mapping(uint256 => MediciStructs.Loan) loans;
        uint256 nextLoanID;
        uint256 maxTenor;
    }
}

contract MediciState {
    MediciStorage.State _state;

    event LoanCreated(uint256 loanId);

    // @dev individual wormhole addresses for each chain
    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.provider.wormhole);
    }

    function owner() public view returns (address) {
        return _state.owner;
    }

    function getNextLoanID() public view returns (uint256) {
        return _state.nextLoanID;
    }

    function getPeripheryContract(uint16 chainId) public view returns (bytes32) {
        return _state.peripheryContracts[chainId];
    }

    function setPeripheryContract(uint16 chainId, bytes32 contractAddress) public {
        _state.peripheryContracts[chainId] = contractAddress;
    }

    function setLoan(MediciStructs.Loan memory loan) public {
        _state.loans[getNextLoanID()] = loan;
        _state.nextLoanID += 1;
    }
}
