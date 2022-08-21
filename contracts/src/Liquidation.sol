// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


import { KeeperCompatibleInterface } from "./interfaces/KeeperCompatibleInterface.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Approver, Loan } from "./interfaces/IMediciPool.sol";
import { IMediciPool } from "./interfaces/IMediciPool.sol";

contract Liquidation is KeeperCompatibleInterface {
    // TODO: checkUpkeep - check for loan deadline and default
    // TODO: performUpkeep - slash deposit from approver
    event NewLoanApproved(address borrower, address approver, uint256 amount, uint256 repaymentTime);
    event LoanDefault(address indexed borrower, address indexed approver, uint256 indexed amount);
    event ApproverSlashed(address indexed approver, uint256 indexed amount);

    constructor(address keeperRegistryAddress) public {
        super(keeperRegistryAddress);
    }


    function _slash(uint256 _loanId) internal {
        Loan memory _loan = loans[_loanId];
        require(_loan.approver != address(0), "Invalid loan");
        Approver storage _approver = approvers[_loan.approver];

        _approver.currentlyApproved -= _loan.principal;
        _approver.balance -= _loan.principal;
        _approver.approvalLimit -= _loan.principal;
        updateApproverReputation(_loan.approver);
    }
}
