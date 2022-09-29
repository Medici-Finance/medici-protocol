pragma solidity 0.8.15;

import { MediciState } from "./MediciState.sol";

contract MediciGetters is MediciState {
    function getNextLoanId() external {
        return _state.nextLoanId;
    }
}
