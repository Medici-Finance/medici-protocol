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

    constructor() {
        setMaxTenor(90 days);
    }

    function request(uint256 loanAmt, uint256 tenor, address coll, uint256 collAmt)
        external
        returns (uint256 wormholeSeq)
    {
        require(tenor <= maxTenor(), "Loan tenor too long");

        // TODO: check if coll token has a wrapped version on core chain
        // if yes, then approve and transfer the coll token to the core chain

        MediciStructs.Loan memory loanReq = MediciStructs.Loan({
            borrower: MediciStructs.encodeWAddress(chainID(), msg.sender),
            worldID: 0,
            principal: loanAmt,
            tenor: tenor,
            repaymentTime: 0,
            collateral: coll,
            collateralAmt: collAmt
        });



        // TODO: pls fix this
        // wormholeSeq = wormhole().publishMessage{value: 0}
        // (
        //     nonce(),
        //     MediciStructs.encodeLoan(loanReq),
        //     consistencyLevel()
        // );
        incrementNonce();
        wormholeSeq = 0;


        emit PeripheryLoanRequest(nonce() - 1);
    }

    function lend(uint256 loanId, address dtAddress, address amount) external returns (uint256 wormholeSeq) {
        // TODO: issue dToken


        // TODO: wormhole msg risk profile and add loans

        // TODO: token transfer
        wormholeSeq = 0;
    }

    function approve(uint256 _loanId) external {}
}
