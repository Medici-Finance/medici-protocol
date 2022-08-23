// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Vm.sol";
import { IWorldID } from "../interfaces/IWorldID.sol";
import { Semaphore } from "world-id-contracts/Semaphore.sol";
import { TypeConverter } from "./TypeConverter.sol";

contract InteractsWithWorldID {
    using TypeConverter for address;

    Vm public wldVM =
        Vm(address(bytes20(uint160(uint(keccak256("hevm cheat code"))))));
    Semaphore internal semaphore;
    IWorldID internal worldID;

    function setUpWorldID() public {
        semaphore = new Semaphore();
        semaphore.createGroup(1, 20, 0);

        worldID = IWorldID(address(semaphore));

        wldVM.label(address(worldID), "WorldID");
    }

    function registerIdentity() public {
        semaphore.addMember(1, _genIdentityCommitment());
    }

    function registerInvalidIdentity() public {
        semaphore.addMember(1, 1);
    }

    function getRoot() public view returns (uint) {
        return semaphore.getRoot(1);
    }

    function _genIdentityCommitment() internal returns (uint) {
        string[] memory ffiArgs = new string[](3);
        ffiArgs[0] = "node";
        ffiArgs[1] = "test/scripts/generate-commitment.js";

        bytes memory returnData = wldVM.ffi(ffiArgs);
        return abi.decode(returnData, (uint));
    }

    function getProof(address externalNullifier, address signal)
        internal
        returns (uint, uint[8] memory proof)
    {
        // increase the length of the array if you have multiple parameters as signal
        string[] memory ffiArgs = new string[](6);
        ffiArgs[0] = "node";
        ffiArgs[1] = "--no-warnings";
        ffiArgs[2] = "test/scripts/generate-proof.js";

        // duplicate (and update) this line for each parameter on your signal
        // make sure to update the array index for everything after too!
        ffiArgs[3] = address(signal).toString();

        // update your external nullifier here
        ffiArgs[4] = address(externalNullifier).toString();

        bytes memory returnData = wldVM.ffi(ffiArgs);

        return abi.decode(returnData, (uint, uint[8]));
    }
}
