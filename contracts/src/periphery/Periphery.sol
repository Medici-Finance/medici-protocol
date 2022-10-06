// periphery/Periphery.sol
// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../helpers/BytesLib.sol";

import "../MediciStructs.sol";

import "../wormhole/IWormhole.sol";

import "./PeripheryGov.sol";



contract Periphery is PeripheryGov {
    using BytesLib for bytes;

    constructor(
        address wormholeContractAddress_,
        uint8 consistencyLevel_,
        uint16 coreChainID_,
        bytes32 coreContractAddress_,
        address collateralTokenAddress_
    ) {
        setMaxTenor(90 days);

        _state.provider.wormhole = payable(wormholeContractAddress_);
        _state.provider.consistencyLevel = consistencyLevel_;
        _state.provider.coreChainID = coreChainID_;

        require(coreContractAddress_ != bytes32(0), "Periphery: coreContractAddress cannot be 0");
        _state.provider.coreContract = coreContractAddress_;

        _state.collateralTokenAddress = collateralTokenAddress_;

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


        incrementNonce();
        // TODO: pls fix this
        // wormholeSeq = wormhole().publishMessage{value: 0}
        // (
        //     nonce(),
        //     MediciStructs.encodeLoan(loanReq),
        //     consistencyLevel()
        // );

        wormholeSeq = 0;


        emit PeripheryLoanRequest(nonce());
    }

    function initLend(uint256 loanId, address dtAddress, uint256 amount) external returns (uint256 wormholeSeq) {
        // TODO: transfer token

        SafeERC20.safeTransferFrom(
            collateralToken(),
            msg.sender,
            address(this),
            amount
        );

        // TODO: wormhole msg risk profile and add loans


        // TODO: token transfer
        wormholeSeq = 0;
    }

    function completeLend() external {

    }


    function approve(uint256 _loanId) external {}
}
