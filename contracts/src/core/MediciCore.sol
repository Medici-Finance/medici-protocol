pragma solidity 0.8.15;

import "../helpers/BytesLib.sol";
import {IWormhole} from "../wormhole/IWormhole.sol";

import {MediciGov} from "./MediciGov.sol";
import "../MediciStructs.sol";

import {Personhood} from "./Personhood.sol";

contract MediciCore is MediciGov {
    using BytesLib for bytes;

    Personhood ph;

    constructor(address wormholeContractAddress_, uint8 consistencyLevel_, address ph_) {
        _state.provider.wormhole = payable(wormholeContractAddress_);
        _state.provider.consistencyLevel = consistencyLevel_;

        ph = Personhood(ph_);
        _state.owner = msg.sender;
    }

    function initLoan(bytes calldata encodedVm) external {
        /// @dev confirms that the message is from Periphery and valid
        // parse and verify the wormhole BorrowMessage
        (IWormhole.VM memory parsed, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedVm);
        require(valid, reason);

        require(valid, reason);
        require(verifyEmitterVM(parsed), "Invalid emitter");

        require(!getMessageHashes(parsed.hash), "Message already processed");
        processMessageHash(parsed.hash);

        BorrowRequestMessage memory params = decodeBorrowRequestMessage(parsed.payload);
        bytes memory wBorrower = encodeWAddress(parsed.emitterChainId, params.header.sender);
        uint256 worldID = ph.getPerson(wBorrower);

        Loan memory loan = Loan({
            borrower: wBorrower,
            worldID: worldID,
            principal: params.borrowAmount,
            pending: 0,
            tenor: params.tenor,
            apr: params.apr,
            // TODO: fix this
            repaymentTime: block.timestamp + params.tenor,
            collateral: params.header.collateralAddress,
            collateralAmt: 0
        });
        setNextLoan(loan);

        RiskProfile memory profile = getRiskProfile(worldID);
        addLoanToProfile(worldID, getLoanID() - 1);

        emit LoanCreated(getLoanID() - 1);
    }

    function updateLoanReceipt(bytes memory encodedVm) external returns (uint256 wormholeSeq){
        // parse and verify the wormhole BorrowMessage
        (
            IWormhole.VM memory parsed,
            bool valid,
            string memory reason
        ) = wormhole().parseAndVerifyVM(encodedVm);
        require(valid, reason);

        // verify emitter
        require(verifyEmitterVM(parsed), "invalid emitter");

        // TODO: check header for token
        // TODO: check target liquidity

        BorrowApproveMessage memory params = decodeBorrowApproveMessage(parsed.payload);
        uint256 loanId = params.loanId;
        address lender = params.header.sender;
        uint256 amount = params.approveAmount;

        updateRiskDAG(loanId, lender, amount);
        updateLoan(loanId, amount);

        MessageHeader memory header = MessageHeader({
            payloadID: uint8(3),
            sender: msg.sender,
            // TODO: look at this
            collateralAddress: address(0),
            borrowAddress: address(0)
        });

        (uint16 chainId, address borrower) = getBorrower(loanId);

        wormholeSeq = sendWormholeMessage(
            encodeBorrowReceiptMessage(
                BorrowReceiptMessage({
                    header: header,
                    chainId: chainId,
                    loanId: loanId,
                    recipient: borrower,
                    amount: amount
                })
            )
        );
    }

    // @dev verifyConductorVM serves to validate VMs by checking against the known Periphery contract
    function verifyEmitterVM(IWormhole.VM memory vm) internal view returns (bool) {
        return getPeripheryContract(vm.emitterChainId) == vm.emitterAddress;
    }

    function sendWormholeMessage(bytes memory payload) internal returns (uint64 sequence) {
        sequence = IWormhole(_state.provider.wormhole).publishMessage(
            nonce(), // nonce
            payload,
            consistencyLevel()
        );
        incrementNonce();
    }

    // necessary for receiving native assets
    receive() external payable {}
}
