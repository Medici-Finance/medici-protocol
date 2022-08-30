// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/console.sol';
import 'forge-std/vm.sol';

import { InteractsWithWorldID } from "../src/helpers/InteractsWithWorldID.sol";
import { ERC20Mintable } from './helpers/ERC20Mintable.sol';
import { Borrower } from '../src/interfaces/IMediciPool.sol';
import { MediciPool } from '../src/MediciPool.sol';
import { RiskManager } from '../src/RiskManager.sol';
import { Personhood } from '../src/Personhood.sol';
import { BaseTest } from '../src/helpers/BaseTest.sol';


contract MediciPoolTest is BaseTest, InteractsWithWorldID {
    Personhood internal ph;
    Vm internal hevm = Vm(HEVM_ADDRESS);

    MediciPool internal pool;
    RiskManager internal riskManager;
    ERC20Mintable internal usdc;

    function verifyBorrower(address borrower) internal returns (bool){
        registerIdentity(); // this simulates a World ID "verified" identity

        (uint256 nullifierHash, uint256[8] memory proof) = getProof(
            address(ph),
            borrower
        );

        return ph.checkNewBorrower(
            borrower,
            getRoot(),
            nullifierHash,
            proof
        );
    }

    function setUp() public {
        usdc = new ERC20Mintable('USDC', 'USDC');
        usdc.mint(address(this), 1000e18);
        usdc.mint(adele, 1000e18);
        usdc.mint(bob, 1000e18);

        setUpWorldID();
        ph = new Personhood(worldID);

        riskManager = new RiskManager();
        pool = new MediciPool(address(usdc), address(ph), address(riskManager), 90, 2e17);
        usdc.approve(address(pool), type(uint256).max);
        vm.prank(adele);
        usdc.approve(address(pool), type(uint256).max);
        vm.prank(bob);
        usdc.approve(address(pool), type(uint256).max);
    }

    function testInitPool() public {
        assertEq(pool.lendingRateAPR(), 2e17);
        assertEq(pool.maxTimePeriod(), 90);
        pool.getPoolShare(1000);
    }

    function testDeposit() public {
        pool.deposit(1e18);
        ( uint256 balance, , , uint256 currentlyApproved) = pool.approvers(address(this));
        assertEq(balance, 1e18);
        assertEq(currentlyApproved, 0);
    }

    // TODO: poolshare
    function testDeposit_poolShare() public {
        pool.deposit(1e18);
        assertEq(pool.balanceOf(address(this)), 1e18);

        vm.prank(adele);
        pool.deposit(1e18);
        assertEq(pool.balanceOf(adele), 1e18);
    }

    function testCheckNewBorrower() public {
        registerIdentity(); // this simulates a World ID "verified" identity

        (uint256 nullifierHash, uint256[8] memory proof) = getProof(
            address(ph),
            adele
        );

        ph.checkNewBorrower(
            adele,
            getRoot(),
            nullifierHash,
            proof
        );
        assertTrue(ph.checkAlreadyVerified(adele));
        assertTrue(true);
    }

    function testDuplicateBorrower_Revert() public {
        verifyBorrower(adele);

        (uint256 nullifierHash, uint256[8] memory proof) = getProof(
            address(ph),
            adele
        );
        uint256 root = getRoot();
        vm.expectRevert(abi.encodeWithSignature("InvalidNullifier()"));
        ph.checkNewBorrower(
            bob,
            root,
            nullifierHash,
            proof
        );
    }

    function testRequest() public {

        verifyBorrower(adele);
        vm.startPrank(adele);
        pool.request(10e18, 30);
        (
            address _borrower,
            uint256 _principal,
            uint256 _amountRepaid,
            address _approver,
            uint256 _durationDays,
            uint256 _repaymentTime
        ) = pool.loans(1);
        assertEq(_borrower, adele);
        assertEq(_principal, 10e18);
        assertEq(_approver, address(0));
        assertEq(_durationDays, 2_592_000);
        assertEq(_repaymentTime, 0);
        vm.stopPrank();
    }

    function testRequestUnverified_Revert() public {
        vm.startPrank(adele);
        vm.expectRevert('ERROR: invalid worldID');
        pool.request(10e18, 10e6);
        (
            address _borrower,
            uint256 _principal,
            uint256 _amountRepaid,
            address _approver,
            uint256 _durationDays,
            uint256 _repaymentTime
        ) = pool.loans(1);
        vm.stopPrank();
    }

    function testApprove() public {
        // sanity
        pool.deposit(1000e18);
        (, , uint256 approvalLimit, uint256 currentlyApproved) = pool.approvers(address(this));
        assertEq(approvalLimit, 1000e18);
        assertEq(currentlyApproved, 0);

        verifyBorrower(adele);
        vm.prank(adele);
        pool.request(10e18, 30);

        pool.approve(1);

        (, , , address _approver, , uint256 _repayTime) = pool.loans(1);
        assertEq(_approver, address(this));
        assertEq(_repayTime, block.timestamp + 2_592_000);

        ( , uint256 currentlyBorrowed,  ) = pool.borrowers(adele);
        assertEq(currentlyBorrowed, 10e18);
        assertEq(pool.getBorrowerLoan(adele, 0), 1);

        ( ,,, currentlyApproved ) = pool.approvers(address(this));
        assertEq(currentlyApproved, 10e18);

    }

    function testApprove_poolShare() public {
        // sanity
        pool.deposit(1000e18);

        verifyBorrower(adele);
        vm.prank(adele);
        pool.request(10e18, 30);

        pool.approve(1);

        vm.prank(bob);
        pool.deposit(500e18);
        assertEq(pool.balanceOf(bob), 500e18);
    }

    function testRepay() public {
        // sanity
        pool.deposit(1000e18);

        verifyBorrower(adele);
        vm.prank(adele);
        pool.request(10e18, 30);

        pool.approve(1);

        vm.warp(block.timestamp + 15 * 24 * 60 * 60);
        vm.prank(adele);
        pool.repay(1, 10e18);

        assertEq(pool.getBorrowerLoan(adele, 0), 0);
        ( , uint256 currentlyBorrowed,  ) = pool.borrowers(adele);
        assertEq(currentlyBorrowed, 0);

        ( ,,, uint256 currentlyApproved ) = pool.approvers(address(this));
        assertEq(currentlyApproved, 0);
    }

    function testWithdraw() public {
        pool.deposit(1000e18);

        verifyBorrower(adele);
        vm.prank(adele);
        pool.request(10e18, 30);

        pool.approve(1);
        pool.withdraw(900e18);
        ( uint balance , , ,  ) = pool.approvers(address(this));

        assertEq(usdc.balanceOf(address(this)), 900e18);
        assertEq(balance, 100e18);
    }

    function testWithdraw_poolShare() public {
        pool.deposit(1000e18);
        assertEq(pool.balanceOf(address(this)), 1000e18);

        verifyBorrower(adele);
        vm.prank(adele);
        pool.request(10e18, 30);

        pool.approve(1);
        pool.withdraw(900e18);
        ( uint balance , , ,  ) = pool.approvers(address(this));
        assertEq(balance, 100e18);
        assertEq(pool.balanceOf(address(this)), 90909090909090909091);
    }
}
