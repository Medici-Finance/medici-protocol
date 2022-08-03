// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Test } from 'forge-std/Test.sol';
import 'forge-std/console.sol';
import 'forge-std/vm.sol';

import { InteractsWithWorldID } from "../src/helpers/InteractsWithWorldID.sol";
import { ERC20Mintable } from '../src/helpers/ERC20Mintable.sol';
import { Borrower } from '../src/MediciPool.sol';
import { MediciToken } from '../src/MediciToken.sol';
import { MediciPool } from '../src/MediciPool.sol';
import { Personhood } from '../src/Personhood.sol';



contract MediciPoolTest is Test, InteractsWithWorldID {
    Personhood internal ph;
    Vm internal hevm = Vm(HEVM_ADDRESS);

    MediciPool internal pool;
    MediciToken internal mici;
    ERC20Mintable internal usdc;



    function setUp() public {
        mici = new MediciToken();
        usdc = new ERC20Mintable('USDC', 'USDC');
        usdc.mint(address(this), 1000e18);
        usdc.mint(address(1), 1000e18);

        setUpWorldID();
        ph = new Personhood(worldID);

        pool = new MediciPool(address(mici), address(ph));
        pool.setUSDCAddress(address(usdc));
        usdc.approve(address(pool), type(uint256).max);
    }

    function testInitPool() public {
        assertEq(pool.lendingRateAPR(), 2e17);
        assertEq(pool.maxTimePeriod(), 30);
    }

    function testDeposit() public {
        pool.deposit(1e18);
        ( uint256 balance, , , uint256 currentlyApproved) = pool.approvers(address(this));
        assertEq(balance, 1e18);
        assertEq(currentlyApproved, 0);
    }

    function testCheckNewBorrower() public {
        registerIdentity(); // this simulates a World ID "verified" identity

        console.log("woRKS1");
        (uint256 nullifierHash, uint256[8] memory proof) = getProof(
            address(ph),
            address(this)
        );
        ph.checkNewBorrower(
            address(this),
            getRoot(),
            nullifierHash,
            proof
        );
        assertTrue(ph.checkAlreadyVerified(address(1)));
    }

    function Request() public {
        vm.startPrank(address(1));
        pool.request(10e18);
        (
            address _borrower,
            uint256 _amount,
            address _approver,
            uint256 _startTime
        ) = pool.loans(1);
        assertEq(_borrower, address(1));
        assertEq(_amount, 10e18);
        assertEq(_approver, address(0));
        assertEq(_startTime, 0);
        vm.stopPrank();
    }

    function Approve() public {
        // sanity
        pool.deposit(1000e18);
        (, , uint256 approvalLimit, uint256 currentlyApproved) = pool.approvers(address(this));
        assertEq(approvalLimit, 1000e18);
        assertEq(currentlyApproved, 0);

        vm.prank(address(1));
        pool.request(10e18);

        pool.approve(1);

        (, , address _approver, uint256 _startTime) = pool.loans(1);
        assertEq(_approver, address(this));
        assertEq(_startTime, block.timestamp);

        ( , uint256 currentlyBorrowed,  ) = pool.borrowers(address(1));
        assertEq(currentlyBorrowed, 10e18);
        assertEq(pool.getBorrowerLoan(address(1), 0), 1);

        ( ,,, currentlyApproved ) = pool.approvers(address(this));
        assertEq(currentlyApproved, 10e18);

    }

    function Repay() public {
        // sanity
        pool.deposit(1000e18);
        vm.prank(address(1));
        pool.request(10e18);
        pool.approve(1);

        vm.warp(block.timestamp + 15 * 24 * 60 * 60);
        vm.prank(address(1));
        pool.repay(1, 10e18);

        assertEq(pool.getBorrowerLoan(address(1), 0), 0);
        ( , uint256 currentlyBorrowed,  ) = pool.borrowers(address(1));
        assertEq(currentlyBorrowed, 0);

        ( ,,, uint256 currentlyApproved ) = pool.approvers(address(this));
        assertEq(currentlyApproved, 0);
    }

    function Withdraw() public {
        pool.deposit(1000e18);

        vm.prank(address(1));
        pool.request(10e18);

        pool.approve(1);
        pool.withdraw(900e18);
        ( uint balance , , uint256 approvalLimit,  ) = pool.approvers(address(this));
        assertEq(balance, 100e18);
    }
}
