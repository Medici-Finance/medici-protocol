
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Vm.sol";
import "forge-std/console.sol";

import {IWormhole} from "../../src/wormhole/IWormhole.sol";
import "../../src/helpers/BytesLib.sol";

contract WormholeSimulator {
    using BytesLib for bytes;

    // Taken from forge-std/Script.sol
    address private constant VM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm public constant vm = Vm(VM_ADDRESS);

    // Allow access to Wormhole
    IWormhole public wormhole;

    // Save the guardian PK to sign messages with
    uint256 private devnetGuardianPK;

    constructor(address wormhole_, uint256 devnetGuardian) {
        wormhole = IWormhole(wormhole_);
        devnetGuardianPK = devnetGuardian;
        overrideToDevnetGuardian(vm.addr(devnetGuardian));
    }

    function overrideToDevnetGuardian(address devnetGuardian) internal {
        {
            bytes32 data = vm.load(address(this), bytes32(uint256(2)));
            require(data == bytes32(0), "incorrect slot");

            // Get slot for Guardian Set at the current index
            uint32 guardianSetIndex = wormhole.getCurrentGuardianSetIndex();
            bytes32 guardianSetSlot = keccak256(abi.encode(guardianSetIndex, 2));
        }

    }
}




