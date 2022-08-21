// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Borrower {
    uint256 borrowLimit;
    uint256 currentlyBorrowed;
    uint256 reputation;
    uint256[] loans;
}

struct Loan {
    address borrower;
    uint256 principal;
    uint256 amountRepaid;
    address approver;
    uint256 duration;
    uint256 repaymentTime;
}

struct Approver {
    uint256 balance;
    uint256 reputation;
    uint256 approvalLimit;
    uint256 currentlyApproved;
}

interface IMediciPool {
    function initialize() external;
    function deposit(uint256 _amt) external;
    function withdraw(uint256 _amt) external;
    function request(uint256 _amt, uint256 duration) external;
    function approve(uint256 _loanId) external;
    function repay(uint256 _loanId, uint256 _amt) external;
    function getBadLoans() external returns (uint256[] memory);
}
