// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

import "../helpers/BytesLib.sol";
import {IWormhole} from "../wormhole/IWormhole.sol";

import {MediciGov} from "./MediciGov.sol";
import {MediciStructs} from "../MediciStructs.sol";

import {Personhood} from "./Personhood.sol";

contract MediciCore is MediciGov {
    using BytesLib for bytes;

    Personhood ph;

    constructor(address _ph) {
        ph = Personhood(_ph);
    }

    function initLoan(bytes memory loanReqVaa) external {
        /// @dev confirms that the message is from the Conductor and valid
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(loanReqVaa);

        require(valid, reason);
        require(verifyEmitterVM(vm), "Invalid emitter");

        MediciStructs.Loan memory loanReq = MediciStructs.parseLoan(vm.payload);
        // require(!loanAlreadyExists(loanReq.loanId));

        loanReq.worldID = ph.getPerson(loanReq.borrower);

        // require(MediciStructs.verifySignature(vm.payload), "Unauthorized");
        setLoan(loanReq);

        emit LoanCreated(getNextLoanID() - 1);
    }

    // @dev verifyConductorVM serves to validate VMs by checking against the known Conductor contract
    // TODO - for each chain
    function verifyEmitterVM(IWormhole.VM memory vm) internal view returns (bool) {
        // TODO: error
        if (getPeripheryContract(vm.emitterChainId) == vm.emitterAddress) {
            return true;
        }

        return false;
    }

    function loanAlreadyExists(uint256 loanId) public view returns (bool) {
        return loanId < getNextLoanID();
    }

    // necessary for receiving native assets
    receive() external payable {}
}
