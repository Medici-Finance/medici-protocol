// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import "../helpers/BytesLib.sol";

contract MediciCore is CoreGov, CoreEvents {
    using Loan for MediciStructs.Loan;
    using BytesLib for bytes;

    function initLoan(bytes memory loanReqVaa) external {
        /// @dev confirms that the message is from the Conductor and valid
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(loanReqVaa);

        require(valid, reason);
        require(verifyEmitterVM(vm), "Invalid emitter");

        Loan memory loanReq = MediciLoans.parseLoan(vm.payload);
        required(!loanAlreadyExists(loanReq.loanId));

        require(MediciStructs.verifySignature(vm.payload), "Unauthorized");
        setLoan(loanReq);

        emit LoanCreated(loanReq.loanId);
    }

    // @dev verifyConductorVM serves to validate VMs by checking against the known Conductor contract
    // TODO - for each chain
    function verifyEmitterVM(IWormhole.VM memory vm) internal view returns (bool) {
        // TODO: error
        if (conductorContract() == vm.emitterAddress && conductorChainId() == vm.emitterChainId) {
            return true;
        }

        return false;
    }

    function loanAlreadyExists(uint256 loanId) public view returns (bool) {
        return loans[loanId] != bytes32(0);
    }

     // necessary for receiving native assets
    receive() external payable {}

}
