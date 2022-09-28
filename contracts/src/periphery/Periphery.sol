// periphery/Periphery.sol
// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../MediciStructs";

import "../interfaces/IMediciPool.sol";



contract Periphery is PeripheryGov, PeripheryEvents {
    using Loan for MediciStructs.Loan;
    using BytesLib for bytes;

    function request(
        uint256 loanAmt,
        uint256 tenor,
        address coll,
        uint256 collAmt
    ) external returns (
        uint256 loanID,
        uint256 wormholeSeq,
        uint256 wormholeSeq2
    ) {
        require(tenor <= maxTimePeriod, "Loan tenor too long");

        // TODO: check if coll token has a wrapped version on core chain
        // if yes, then approve and transfer the coll token to the core chain

        Loan memory loanReq = Loan({
            borrower: msg.sender,
            principal: loanAmt,
            tenor: tenor,
            repaymentTime: 0
            collateral: coll,
            collateralAmt: collAmt
        });

        wormholeSeq = wormhole.publishMessage{value: 0}(
            nonce,
                MediciStructs.encodeLoan(loanReq),
            consistencyLevel()
        );
    }

    function approve(uint256 _loanId) {}


    function verifySignature(
        bytes memory encodedHashData,
        bytes memory sig,
        address authority
    ) internal pure returns (bool) {

    }
}
