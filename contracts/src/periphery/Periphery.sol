// periphery/Periphery.sol
// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../helpers/BytesLib.sol";

import "../MediciStructs.sol";

import "../wormhole/IWormhole.sol";

import "./PeripheryGov.sol";

contract Periphery is PeripheryGov {
    using BytesLib for bytes;

    function request(uint256 loanAmt, uint256 tenor, address coll, uint256 collAmt)
        external
        returns (uint256 wormholeSeq)
    {
        require(tenor <= maxTenor(), "Loan tenor too long");

        // TODO: check if coll token has a wrapped version on core chain
        // if yes, then approve and transfer the coll token to the core chain

        MediciStructs.Loan memory loanReq = MediciStructs.Loan({
            borrower: msg.sender,
            principal: loanAmt,
            tenor: tenor,
            repaymentTime: 0,
            collateral: coll,
            collateralAmt: collAmt
        });

        IWormhole wormhole = wormhole();

        wormholeSeq = wormhole.publishMessage{value: 0}(nonce(), MediciStructs.encodeLoan(loanReq), consistencyLevel());
        incrementNonce();

        emit PeripheryLoanRequest(nonce() - 1);
    }

    function approve(uint256 _loanId) external {}
}
