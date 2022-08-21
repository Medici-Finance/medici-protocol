// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


import { KeeperCompatibleInterface } from "./interfaces/KeeperCompatibleInterface.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Approver, Loan } from "./interfaces/IMediciPool.sol";
import { IMediciPool } from "./interfaces/IMediciPool.sol";

contract Liquidation is KeeperCompatibleInterface {
    IMediciPool public pool;
    uint256[] public badLoans;
    address private _keeperRegistryAddress;

    // TODO: checkUpkeep - check for loan deadline and default
    // TODO: performUpkeep - slash deposit from approver
    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
    event NewLoanApproved(address borrower, address approver, uint256 amount, uint256 repaymentTime);
    event LoanDefault(address indexed borrower, address indexed approver, uint256 indexed amount);
    event ApproverSlashed(address indexed approver, uint256 indexed amount);

    constructor(IMediciPool _pool, address keeperRegistryAddress) public {
        pool = _pool;
        setKeeperRegistryAddress(keeperRegistryAddress);
    }

    /**
     * @notice Sets the keeper registry address
     */
    function setKeeperRegistryAddress(address keeperRegistryAddress) public {
        require(keeperRegistryAddress != address(0));
        emit KeeperRegistryAddressUpdated(_keeperRegistryAddress, keeperRegistryAddress);
        _keeperRegistryAddress = keeperRegistryAddress;
    }


    function _slash(uint256 _loanId) internal {

    }

    /**
     * @notice Get list of unpaid loans
     * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoded list of loans defaulted
     */
    function checkUpkeep(bytes calldata)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        badLoans = pool.getBadLoans();
        return (badLoans.length != 0, abi.encode(badLoans));
    }

    /**
     * @notice Called by keeper to send funds to underfunded addresses
     * @param performData The abi encoded list of addresses to fund
     */
  function performUpkeep(bytes calldata performData) external override {
    uint256[] memory _underLoans = abi.decode(performData, (uint256[]));
    for (uint256 i = 0; i < _underLoans.length; i++) {
        _slash(_underLoans[i]);
    }
  }
}
