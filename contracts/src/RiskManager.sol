// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Approver, Borrower, Loan } from "./interfaces/IMediciPool.sol";
import { IMediciPool } from "./interfaces/IMediciPool.sol";

contract RiskManager {
    function updateOnDeposit(uint256 _amt) external {
        // approvers[msg.sender].balance += _amt;
        // approvers[msg.sender].approvalLimit += _amt;
        // approvers[msg.sender].reputation = 200;
    }

}
