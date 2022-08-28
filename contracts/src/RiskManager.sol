// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import 'forge-std/console.sol';
import { BasePool } from "./BasePool.sol";

contract RiskManager is BasePool {
    function updateOnDeposit(uint256 _amt) external {
        approvers[msg.sender].balance += _amt;
        approvers[msg.sender].approvalLimit += _amt;
        approvers[msg.sender].reputation = getReputation();
    }

    function getReputation() public returns (uint256){
        return 200;
    }

}
