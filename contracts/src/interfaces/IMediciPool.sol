// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

struct Borrower {
    uint borrowLimit;
    uint currentlyBorrowed;
    uint reputation;
    uint[] loans;
}

struct Loan {
    address borrower;
    uint principal;
    uint amountRepaid;
    address approver;
    uint duration;
    uint repaymentTime;
}

struct Approver {
    uint balance;
    uint reputation;
    uint approvalLimit;
    uint currentlyApproved;
}

interface IMediciPool {
    function deposit(uint _amt) external;
    function withdraw(uint _amt) external;
    function request(uint _amt, uint duration) external;
    function approve(uint _loanId) external;
    function repay(uint _loanId, uint _amt) external;
    function getBadLoans() external returns (uint[] memory);
}
