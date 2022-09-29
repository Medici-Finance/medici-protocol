// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

contract MediciStorage {
    struct Provider {
        uint16 chainId;
        address payable wormhole;
        address tokenBridge;
    }

    struct State {
        Provider provider;

        adddress owner;

        uint16 consistencyLevel;

        mapping(uint256 => MediciStructs.Loan) loans;

        uint256 nextLoanId;

    }
}

contract MediciState {
    MediciStorage.State _state;
}
