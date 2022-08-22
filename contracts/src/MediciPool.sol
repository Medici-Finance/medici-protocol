// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Approver, Borrower, Loan } from "./interfaces/IMediciPool.sol";
import { IMediciPool } from "./interfaces/IMediciPool.sol";
import { Counters } from '@openzeppelin/contracts/utils/Counters.sol';
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { ERC20Upgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import 'forge-std/console.sol';
import 'forge-std/Vm.sol';

import './helpers/Math.sol';
import './Personhood.sol';

contract MediciPool is ERC20Upgradeable, IMediciPool {
    using Counters for Counters.Counter;
    ERC20 public poolToken;
    Personhood ph;
    address USDCAddress = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;

    uint256 public lendingRateAPR; // per 10^18
    Counters.Counter currentId;

    mapping(address => Approver) public approvers;
    mapping(address => Borrower) public borrowers;
    mapping(uint256 => Loan) public loans;
    uint256[] public currentLoans;
    uint256[] public bLoans;

    uint256 public poolDeposits;
    uint256 public maxLoanAmount;
    uint256 public maxTimePeriod; //in days
    uint256 public minPoolAllocation; // per 10^18

    /**************************************************************************
     * Events
     *************************************************************************/

    event DepositMade(address indexed poolProvider, uint256 amount, uint256 shares);
    event WithdrawalMade(address indexed poolProvider, uint256 amount, uint256 shares);
    event NewLoanRequest(address indexed borrower, uint256 loanId, uint256 amount);
    event LoanApproved(
        address indexed approver,
        address indexed borrower,
        uint256 loanId,
        uint256 amount
    );

    /**************************************************************************
     * Constructor
     *************************************************************************/

    constructor(ERC20 _poolToken, address _phAddr, uint256 _maxDuration, uint256 _lendingRate) public {
        poolToken = _poolToken;
        ph = Personhood(_phAddr);
        initialize(_lendingRate, _maxDuration );
    }

    function initialize(uint256 _lendingRate, uint256 _maxDuration) public {
        lendingRateAPR = _lendingRate;
        maxTimePeriod = _maxDuration;
        minPoolAllocation = 10e15;
        currentId.increment();
    }

    /**************************************************************************
     * Modifiers
     *************************************************************************/

    modifier onlyApprover() {
        require(approvers[msg.sender].balance > 0, 'Must be an approver');
        _;
    }

    // TODO: fix worldID testing error
    modifier uniqueBorrower(address borrower) {
        // require(ph.checkAlreadyVerified(borrower), 'ERROR: invalid worldID');
        require(true);
        _;
    }

    /**************************************************************************
     * Getter Functions
     *************************************************************************/

    function getApprovers(address _addr) public view returns (Approver memory) {
        return approvers[_addr];
    }

    function getBorrowers(address _addr) public view returns (Borrower memory) {
        return borrowers[_addr];
    }

    function getLoans(uint256 _loanId) public view returns (Loan memory) {
        return loans[_loanId];
    }

    /**************************************************************************
     * Utility Functions
     *************************************************************************/

    function setLendingRate(uint256 _lendingRateAPR) public {
        lendingRateAPR = _lendingRateAPR;
    }

    function getRepayAmount(address _borrower) public view returns (uint256) {
        // TODO
        // require(loans[_borrower].approved, "Loan not approved");
        // return loans[_borrower].amount + Math.calculateInterest(loans[_borrower], lendingRateAPR, 1);
    }

    function calcInterest(Loan memory _loan) public view returns (uint256) {
        // (
        //     ,
        //     uint256 principal,
        //     uint256 amountRepaid, ,
        //     uint256 duration,
        //     uint256 repaymentDate ) = _loan;
        uint _timePeriod = getTimePeriodDays(_loan.repaymentTime - _loan.duration);
        return Math.calculateInterest(_loan.principal - _loan.principal, lendingRateAPR, _timePeriod);
    }

    function totalLoanValue() public view returns (uint256) {
        uint _total = 0;
        // console.log()
        for (uint256 i = 0; i < currentLoans.length; i++) {
            Loan memory curr = loans[currentLoans[i]];
            if (curr.repaymentTime > block.timestamp && curr.amountRepaid < curr.principal) {
                _total += curr.principal + calcInterest(curr) - curr.amountRepaid;
            }
        }
        return _total;
    }

    function getPoolShare(uint256 _amt) public view returns (uint256) {
        uint dTokenSupply = totalSupply();

        if (dTokenSupply == 0) {
            return ((_amt * 10 ** decimals()) / 10**poolToken.decimals());
        } else {
            return _amt * dTokenSupply / (poolToken.balanceOf(address(this)) + totalLoanValue() - _amt);
        }
    }

    function getPoolReserves() public view returns (uint256) {
        return poolToken.balanceOf(address(this));
    }

    function doUSDCTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(to != address(0), "Can't send to zero address");
        if (from ==  address(this)) {
            return poolToken.transfer(to, amount);
        }
        return poolToken.transferFrom(from, to, amount);
    }

    function getInitialBorrowLimit() public view returns (uint256) {
        return Math.mulDiv(getPoolReserves(), minPoolAllocation, 10**18);
    }

    function getTimePeriodDays(uint256 startTime) internal view returns (uint256) {
        return (block.timestamp - startTime) / (24 * 60 * 60);
    }

    function daysToSeconds(uint256 _days) internal returns (uint256) {
        return _days * 24 * 60 * 60;
    }


    function getBorrowerLoan(address _borrower, uint256 _index) public view returns (uint256) {
        if (_index >= borrowers[_borrower].loans.length) {
            return 0;
        }
        return borrowers[_borrower].loans[_index];
    }


    function getBadLoans() public returns (uint256[] memory) {

        for (uint256 i = 0; i < currentLoans.length; i++) {
            if (checkDefault(currentLoans[i])) {
                bLoans.push(currentLoans[i]);
            }
        }
        // TODO: do better that this
        uint256[] memory cpyLoans = bLoans;
        return cpyLoans;
    }

    /**************************************************************************
     * Core Functions
     *************************************************************************/

    function deposit(uint256 _amt) external {
        require(_amt > 0, 'Must deposit more than zero');

        bool success = doUSDCTransfer(msg.sender, address(this), _amt);
        require(success, 'Failed to transfer for deposit');

        uint256 rep = getReputation();

        if (approvers[msg.sender].balance == 0) {
            approvers[msg.sender] = Approver(_amt, rep, _amt, 0);
        } else {
            approvers[msg.sender].balance += _amt;
            approvers[msg.sender].approvalLimit += _amt;
            approvers[msg.sender].reputation = rep;
        }

        uint dToken = getPoolShare(_amt);
        _mint(msg.sender, dToken);
        emit DepositMade(msg.sender, _amt, dToken);
    }

    function withdraw(uint256 _amt) external {
        require(_amt > 0, 'Must withdraw more than zero');

        Approver storage _approver = approvers[msg.sender];
        uint256 withdrawable = _approver.balance - _approver.currentlyApproved;
        require(withdrawable >= _amt, 'Not enough balance');
        uint256 withdrawShare = getPoolShare(_amt);

        _approver.balance -= _amt;
        updateApproverReputation(msg.sender);

        doUSDCTransfer(address(this), msg.sender, _amt);
        emit WithdrawalMade(msg.sender, _amt, withdrawShare);
    }

    function approve(uint256 _loanId) public onlyApprover {
        Loan storage loan = loans[_loanId];
        require(loan.principal > 0, 'Invalid loan');
        require(loan.approver == address(0), 'Loan already approved');

        require(
            approvers[msg.sender].approvalLimit >
                loan.principal + approvers[msg.sender].currentlyApproved,
            'Going over your approval limit'
        );

        Borrower storage borrower = borrowers[loan.borrower];
        require(borrower.reputation > 0, "Borrower doesn't exist");
        require(!loanAlreadyExists(loan.borrower, _loanId), 'Loan already exists');

        borrower.loans.push(_loanId);
        borrower.currentlyBorrowed += loan.principal;
        loan.approver = msg.sender;
        loan.repaymentTime = block.timestamp + loan.duration;
        currentLoans.push(_loanId);

        approvers[msg.sender].currentlyApproved += loan.principal;

        bool success = doUSDCTransfer(address(this), msg.sender, loan.principal);
        require(success, 'Failed to transfer for borrow');

        emit LoanApproved(msg.sender, msg.sender, _loanId, loan.principal);
    }

    function request(uint256 _amt, uint256 durationDays) external uniqueBorrower(msg.sender) {
        require(_amt > 0, 'Must borrow more than zero');
        require(durationDays > 0 && durationDays <= maxTimePeriod, "ERROR: invalid time period for the loan request");

        Borrower storage borrower = borrowers[msg.sender];

        if (borrower.loans.length == 0) {
            updateBorrowerReputation(msg.sender);
        }
        require(
            _amt + borrower.currentlyBorrowed < borrower.borrowLimit,
            'Going over your borrow limit'
        );

        uint256 loanId = currentId.current();
        loans[loanId] = Loan(msg.sender, _amt, 0, address(0), daysToSeconds(durationDays), 0);
        currentId.increment();
        updateBorrowerReputation(msg.sender);

        emit NewLoanRequest(msg.sender, loanId, _amt);
    }

    function repay(uint256 _loanId, uint256 _amt) external {
        require(_amt > 0, 'Must borrow more than zero');

        Loan storage loan = loans[_loanId];
        Borrower storage borrower = borrowers[msg.sender];
        Approver storage approver = approvers[loan.approver];

        require(!checkDefault(_loanId), 'Passed the deadline');
        require(_amt <= borrower.currentlyBorrowed, "Can't repay more than you owe");
        uint256 repayAmt = _amt + calcInterest(loan);

        bool success = doUSDCTransfer(address(this), msg.sender, _amt);
        require(success, 'Failed to transfer for repay');

        loan.principal = 0;
        removeLoan(_loanId, loan.borrower);
        borrower.currentlyBorrowed -= _amt;
        approver.currentlyApproved -= _amt;

        updateBorrowerReputation(msg.sender);
        updateApproverReputation(loan.approver);
    }

    /**************************************************************************
     * Internal Functions
     *************************************************************************/

    function getReputation() public view returns (uint256) {
        return 200;
    }

    function getBorrowLimit(uint256 _reputation) public view returns (uint256) {
        return 1000e18;
    }

    function getApprovalLimit(uint256 _reputation) public view returns (uint256) {
        return 1000e18;
    }

    function updateBorrowerReputation(address _ba) public {
        Borrower storage _borrower = borrowers[_ba];
        uint256 _rep = getReputation();
        _borrower.reputation = _rep;
        _borrower.borrowLimit = getBorrowLimit(_rep);
    }

    function updateApproverReputation(address _aa) public {
        Approver storage _approver = approvers[_aa];
        uint256 _rep = getReputation();
        _approver.reputation = _rep;
        _approver.approvalLimit = getApprovalLimit(_rep);
    }

    function loanAlreadyExists(address _bAddr, uint256 _loanId) public view returns (bool) {
        Borrower memory borrower = borrowers[_bAddr];
        for (uint256 i = 0; i < borrower.loans.length; i++) {
            if (borrower.loans[i] == _loanId) {
                return true;
            }
        }
        return false;
    }

    function checkDefault(uint256 _loanId) public view returns (bool) {
        Loan memory _loan = loans[_loanId];
        if (_loan.repaymentTime < block.timestamp && _loan.principal > _loan.amountRepaid) {
            return true;
        } else {
            return false;
        }
    }

    function removeLoan(uint256 _loanId, address _borrower) internal {
        uint256[] storage borrowerLoans = borrowers[_borrower].loans;
        uint256 index;
        for (uint256 i = 0; i < borrowerLoans.length; i++) {
            if (borrowerLoans[i] == _loanId) {
                index = i;
                break;
            }
        }

        borrowerLoans[index] = borrowerLoans[borrowerLoans.length - 1];
        borrowerLoans.pop();
    }
}
