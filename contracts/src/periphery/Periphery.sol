// periphery/Periphery.sol
// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../helpers/BytesLib.sol";

import "../MediciStructs.sol";

import "../wormhole/IWormhole.sol";
import "../helpers/MToken.sol";

import "./PeripheryGov.sol";

contract Periphery is PeripheryGov, MediciStructs {
    using BytesLib for bytes;

    constructor(
        address wormholeContractAddress_,
        uint8 consistencyLevel_,
        address collateralAssetAddress_,
        address mTokenAddress_
    ) {
        setMaxTenor(90 days);

        _state.provider.wormhole = payable(wormholeContractAddress_);
        _state.provider.consistencyLevel = consistencyLevel_;

        _state.collateralAssetAddress = collateralAssetAddress_;
        _state.mTokenAddress = mTokenAddress_;

        _state.owner = payable(msg.sender);
    }

    function request(uint256 loanAmt, uint256 tenor) external returns (uint256 wormholeSeq) {
        require(tenor <= maxTenor(), "Loan tenor too long");
        require(loanAmt > 0, "Loan amount must be greater than 0");

        MessageHeader memory header = MessageHeader({
            payloadID: uint8(1),
            sender: msg.sender,
            collateralAddress: _state.collateralAssetAddress,
            borrowAddress: _state.borrowingAssetAddress
        });

        wormholeSeq = sendWormholeMessage(
            encodeBorrowRequestMessage(
                BorrowRequestMessage({
                    header: header,
                    borrowAmount: loanAmt,
                    totalNormalizedBorrowAmount: loanAmt,
                    tenor: tenor
                })
            )
        );
        emit PeripheryLoanRequest(nonce());
    }

    function initLend(uint256 loanId, uint256 amount) external returns (uint256 wormholeSeq) {
        SafeERC20.safeTransferFrom(collateralToken(), msg.sender, address(this), amount);

        mToken().mint(msg.sender, amount);

        MessageHeader memory header = MessageHeader({
            payloadID: uint8(2),
            sender: msg.sender,
            collateralAddress: _state.collateralAssetAddress,
            borrowAddress: _state.borrowingAssetAddress
        });

        wormholeSeq = sendWormholeMessage(
            encodeBorrowApproveMessage(
                BorrowApproveMessage({
                    header: header,
                    loanId: loanId,
                    approveAmount: amount,
                    totalNormalizedApproveAmount: amount
                })
            )
        );

        emit LendSuccess(loanId, amount);
    }

    function receiveLoan(bytes calldata encodedVm) external {
        /// @dev confirms that the message is from Core and valid
        // parse and verify the wormhole BorrowMessage
        (
            IWormhole.VM memory parsed,
            bool valid,
            string memory reason
        ) = wormhole().parseAndVerifyVM(encodedVm);
        require(valid, reason);

        // verify emitter
        require(verifyEmitterVM(parsed), "Invalid emitter");

        require(!getMessageHashes(parsed.hash), "Message already processed");
        processMessageHash(parsed.hash);

        // parse the payload
        BorrowReceiptMessage memory receipt = decodeBorrowReceiptMessage(parsed.payload);

        SafeERC20.safeTransferFrom(collateralToken(), address(this), receipt.recipient, parsed.sender, parsed.amount);
    }

    function sendWormholeMessage(bytes memory payload) internal returns (uint64 sequence) {
        sequence = IWormhole(_state.provider.wormhole).publishMessage(
            nonce(), // nonce
            payload,
            consistencyLevel()
        );
        incrementNonce();
    }

    // @dev verifyConductorVM serves to validate VMs by checking against the known Core contract
    function verifyEmitterVM(IWormhole.VM memory vm) internal view returns (bool) {
        return vm.emitterChainId == _state.provider.coreChainID &&
            vm.emitterAddress == _state.provider.coreContracte;
    }
}
