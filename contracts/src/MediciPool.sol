// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.15;

// import { Approver, Borrower, Loan } from "./interfaces/IMediciPool.sol";
// import { IMediciPool } from "./interfaces/IMediciPool.sol";
// import { BasePool } from "./BasePool.sol";
// import { RiskManager } from "./RiskManager.sol";
// import { Counters } from '@openzeppelin/contracts/utils/Counters.sol';
// import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import { ERC20Upgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
// import 'forge-std/console.sol';
// import 'forge-std/Vm.sol';

// import './helpers/Math.sol';
// import './core/Personhood.sol';

// contract MediciPool is BasePool, IMediciPool, ERC20Upgradeable {
//     using Counters for Counters.Counter;
//     ERC20 public poolToken;
//     Personhood ph;
//     address rManager;

//     uint256 public lendingRateAPR; // per 10^18
//     Counters.Counter currentId;

//     /**************************************************************************
//      * Events
//      *************************************************************************/

//     event DepositMade(address indexed poolProvider, uint256 amount, uint256 shares);
//     event WithdrawalMade(address indexed poolProvider, uint256 amount, uint256 shares);
//     event NewLoanRequest(address indexed borrower, uint256 loanId, uint256 amount);
//     event LoanApproved(
//         address indexed approver,
//         address indexed borrower,
//         uint256 loanId,
//         uint256 amount
//     );

//     /**************************************************************************
//      * Constructor
//      *************************************************************************/

//     constructor(address _poolToken, address _phAddr, address _rm, uint256 _maxDuration, uint256 _lendingRate) public {
//         poolToken = ERC20(_poolToken);
//         ph = Personhood(_phAddr);
//         rManager = _rm;
//         initialize(_lendingRate, _maxDuration );
//     }

//     function initialize(uint256 _lendingRate, uint256 _maxDuration) public {
//         lendingRateAPR = _lendingRate;
//         maxTimePeriod = _maxDuration;
//         minPoolAllocation = 10e15;
//         currentId.increment();
//     }

//     /**************************************************************************
//      * Modifiers
//      *************************************************************************/

//     modifier onlyApprover() {
//         require(approvers[msg.sender].balance > 0, 'Must be an approver');
//         _;
//     }

//     modifier uniqueBorrower(address borrower) {
//         // require(ph.checkAlreadyVerified(borrower), 'ERROR: invalid worldID');

//         _;
//     }

//     /**************************************************************************
//      * Getter Functions
//      *************************************************************************/

//     function getApprovers(address _addr) public view returns (Approver memory) {
//         return approvers[_addr];
//     }

//     function getBorrowers(address _addr) public view returns (Borrower memory) {
//         return borrowers[_addr];
//     }

//     function getLoans(uint256 _loanId) public view returns (Loan memory) {
//         return loans[_loanId];
//     }

//     /**************************************************************************
//      * Utility Functions
//      *************************************************************************/

//     function setLendingRate(uint256 _lendingRateAPR) public {
//         lendingRateAPR = _lendingRateAPR;
//     }

//     function getRepayAmount(address _borrower) public view returns (uint256) {
//         // TODO
//         // require(loans[_borrower].approved, "Loan not approved");
//         // return loans[_borrower].amount + Math.calculateInterest(loans[_borrower], lendingRateAPR, 1);
//     }

//     function calcInterest(Loan memory _loan) public view returns (uint256) {
//         uint _timePeriod = getTimePeriodDays(_loan.repaymentTime - _loan.duration);
//         return Math.calculateInterest(_loan.principal - _loan.principal, lendingRateAPR, _timePeriod);
//     }

//     function totalLoanValue() public view returns (uint256) {
//         uint _total = 0;
//         // console.log()
//         for (uint256 i = 0; i < currentLoans.length; i++) {
//             Loan memory curr = loans[currentLoans[i]];
//             if (curr.repaymentTime > block.timestamp && curr.amountRepaid < curr.principal) {
//                 _total += curr.principal + calcInterest(curr) - curr.amountRepaid;
//             }
//         }
//         return _total;
//     }

//     function getPoolShare(uint256 _amt) public view returns (uint256) {
//         uint dTokenSupply = totalSupply();

//         if (dTokenSupply == 0) {
//             return ((_amt * 10 ** decimals()) / 10**poolToken.decimals());
//         } else {
//             return _amt * dTokenSupply / (poolToken.balanceOf(address(this)) + totalLoanValue() - _amt);
//         }
//     }

//     function getPoolReserves() public view returns (uint256) {
//         return poolToken.balanceOf(address(this));
//     }

//     function doUSDCTransfer(
//         address from,
//         address to,
//         uint256 amount
//     ) internal returns (bool) {
//         require(to != address(0), "Can't send to zero address");
//         if (from ==  address(this)) {
//             return poolToken.transfer(to, amount);
//         }
//         return poolToken.transferFrom(from, to, amount);
//     }

//     function getInitialBorrowLimit() public view returns (uint256) {
//         return Math.mulDiv(getPoolReserves(), minPoolAllocation, 10**18);
//     }

//     function getTimePeriodDays(uint256 startTime) internal view returns (uint256) {
//         return (block.timestamp - startTime) / (24 * 60 * 60);
//     }

//     function daysToSeconds(uint256 _days) internal returns (uint256) {
//         return _days * 24 * 60 * 60;
//     }


//     function getBorrowerLoan(address _borrower, uint256 _index) public view returns (uint256) {
//         if (_index >= borrowers[_borrower].loans.length) {
//             return 0;
//         }
//         return borrowers[_borrower].loans[_index];
//     }


//     function getBadLoans() override public returns (uint256[] memory) {

//         for (uint256 i = 0; i < currentLoans.length; i++) {
//             if (checkDefault(currentLoans[i])) {
//                 bLoans.push(currentLoans[i]);
//             }
//         }
//         // TODO: do better that this
//         uint256[] memory cpyLoans = bLoans;
//         return cpyLoans;
//     }

//     /**************************************************************************
//      * Core Functions
//      *************************************************************************/

//     function deposit(uint256 _amt) external override {
//         require(_amt > 0, 'Must deposit more than zero');

//         bool success = doUSDCTransfer(msg.sender, address(this), _amt);
//         require(success, 'Failed to transfer for deposit');

//         (bool update, bytes memory result) = rManager.delegatecall(abi.encodeWithSignature("updateOnDeposit(uint256)", _amt));

//         uint dToken = getPoolShare(_amt);
//         _mint(msg.sender, dToken);
//         emit DepositMade(msg.sender, _amt, dToken);
//     }

//     function withdraw(uint256 amount) external override {
//         require(amount > 0, 'Must withdraw more than zero');

//         uint256 sharesToWithdraw = (amount * totalSupply()) / poolToken.balanceOf(address(this));
//         Approver storage _approver = approvers[msg.sender];
//         uint256 withdrawable = _approver.balance - _approver.currentlyApproved;
//         require(withdrawable >= amount, 'Not enough balance');

//         _approver.balance -= amount;
//         updateApproverReputation(msg.sender);

//         doUSDCTransfer(address(this), msg.sender, amount);

//         if (balanceOf(msg.sender) >= sharesToWithdraw) {
//             _burn(msg.sender, sharesToWithdraw);
//         } else {
//             _burn(msg.sender, balanceOf(msg.sender));
//         }
//         emit WithdrawalMade(msg.sender, amount, sharesToWithdraw);
//     }

//     function approve(uint256 _loanId) external override onlyApprover {
//         Loan storage loan = loans[_loanId];
//         require(loan.principal > 0, 'Invalid loan');
//         require(loan.approver == address(0), 'Loan already approved');

//         require(
//             approvers[msg.sender].approvalLimit >
//                 loan.principal + approvers[msg.sender].currentlyApproved,
//             'Going over your approval limit'
//         );

//         Borrower storage borrower = borrowers[loan.borrower];
//         require(borrower.reputation > 0, "Borrower doesn't exist");
//         require(!loanAlreadyExists(loan.borrower, _loanId), 'Loan already exists');

//         borrower.loans.push(_loanId);
//         borrower.currentlyBorrowed += loan.principal;
//         loan.approver = msg.sender;
//         loan.repaymentTime = block.timestamp + loan.duration;
//         currentLoans.push(_loanId);

//         approvers[msg.sender].currentlyApproved += loan.principal;

//         bool success = doUSDCTransfer(address(this), loan.borrower, loan.principal);
//         require(success, 'Failed to transfer for borrow');

//         emit LoanApproved(msg.sender, msg.sender, _loanId, loan.principal);
//     }

//     function request(uint256 _amt, uint256 durationDays) external override uniqueBorrower(msg.sender) {
//         require(_amt > 0, 'Must borrow more than zero');
//         require(durationDays > 0 && durationDays <= maxTimePeriod, "ERROR: invalid time period for the loan request");

//         Borrower storage borrower = borrowers[msg.sender];

//         if (borrower.loans.length == 0) {
//             updateBorrowerReputation(msg.sender);
//         }
//         require(
//             _amt + borrower.currentlyBorrowed < borrower.borrowLimit,
//             'Going over your borrow limit'
//         );

//         uint256 loanId = currentId.current();
//         loans[loanId] = Loan(msg.sender, _amt, 0, address(0), daysToSeconds(durationDays), 0);
//         currentId.increment();
//         updateBorrowerReputation(msg.sender);

//         emit NewLoanRequest(msg.sender, loanId, _amt);
//     }

//     function repay(uint256 _loanId, uint256 _amt) external override {
//         require(_amt > 0, 'Must borrow more than zero');

//         Loan storage loan = loans[_loanId];
//         Borrower storage borrower = borrowers[msg.sender];
//         Approver storage approver = approvers[loan.approver];

//         require(!checkDefault(_loanId), 'Passed the deadline');
//         require(_amt <= borrower.currentlyBorrowed, "Can't repay more than you owe");
//         uint256 repayAmt = _amt + calcInterest(loan);

//         bool success = doUSDCTransfer(address(this), msg.sender, _amt);
//         require(success, 'Failed to transfer for repay');

//         loan.principal = 0;
//         removeLoan(_loanId, loan.borrower);
//         borrower.currentlyBorrowed -= _amt;
//         approver.currentlyApproved -= _amt;

//         updateBorrowerReputation(msg.sender);
//         updateApproverReputation(loan.approver);
//     }

//     /**************************************************************************
//      * Internal Functions
//      *************************************************************************/

//     function updateBorrowerReputation(address _ba) public {
//         Borrower storage _borrower = borrowers[_ba];
//         _borrower.reputation = 200;
//         _borrower.borrowLimit = 1000e18;
//     }

//     function updateApproverReputation(address _aa) public {
//         Approver storage _approver = approvers[_aa];
//         _approver.reputation = 200;
//         _approver.approvalLimit = 1000e18;
//     }

//     function loanAlreadyExists(address _bAddr, uint256 _loanId) public view returns (bool) {
//         Borrower memory borrower = borrowers[_bAddr];
//         for (uint256 i = 0; i < borrower.loans.length; i++) {
//             if (borrower.loans[i] == _loanId) {
//                 return true;
//             }
//         }
//         return false;
//     }

//     function checkDefault(uint256 _loanId) public view returns (bool) {
//         Loan memory _loan = loans[_loanId];
//         if (_loan.repaymentTime < block.timestamp && _loan.principal > _loan.amountRepaid) {
//             return true;
//         } else {
//             return false;
//         }
//     }

//     function removeLoan(uint256 _loanId, address _borrower) internal {
//         uint256[] storage borrowerLoans = borrowers[_borrower].loans;
//         uint256 index;
//         for (uint256 i = 0; i < borrowerLoans.length; i++) {
//             if (borrowerLoans[i] == _loanId) {
//                 index = i;
//                 break;
//             }
//         }

//         borrowerLoans[index] = borrowerLoans[borrowerLoans.length - 1];
//         borrowerLoans.pop();
//     }
// }
