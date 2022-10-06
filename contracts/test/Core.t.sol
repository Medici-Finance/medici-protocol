// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import 'forge-std/console.sol';
import 'forge-std/Vm.sol';

import { BaseTest } from '../src/helpers/BaseTest.sol';
import { MediciCore } from '../src/core/MediciCore.sol';
import { LocalConfig } from './LocalConfig.sol';

contract CoreTest is BaseTest {
    LocalConfig config;
    MediciCore core;

    function setUp() public {
        config = new LocalConfig();
        core = new MediciCore(config.getPersonhoodAddress());
    }

    function testOwner() public {
        assertEq(core.owner(), address(this));
    }
}
