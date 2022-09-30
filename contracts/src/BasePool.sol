// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Approver, Borrower, Loan } from "./interfaces/IMediciPool.sol";

abstract contract BasePool {
    mapping(address => Approver) public approvers;
    mapping(address => Borrower) public borrowers;
    mapping(uint256 => Loan) public loans;
    uint256[] public currentLoans;
    uint256[] public bLoans;

    uint256 public poolDeposits;
    uint256 public maxTimePeriod; //in days
    uint256 public minPoolAllocation; // per 10^18
}
