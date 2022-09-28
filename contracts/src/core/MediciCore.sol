// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import "../helpers/BytesLib.sol";

contract MediciCore is CoreGov, CoreEvents {
    using Loan for MediciStructs.Loan;
    using BytesLib for bytes;

    function initLoan(bytes memory loanReqVaa) external {
        /// @dev confirms that the message is from the Conductor and valid
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(saleInitVaa);

        require(valid, reason);
        require(verifyEmitterVM(vm), "Invalid emitter");

        Loan memory loanReq = MediciLoans.parseLoan(vm.payload);
        required(!s)

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
}
